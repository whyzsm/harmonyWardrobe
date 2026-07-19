import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { DeleteCleanupService } from './DeleteCleanupService';
import { SearchRepository } from './SearchRepository';
import { SearchIndexMode } from '../searchIndex/SearchCapability';
import { PhotoStorage } from '../../media/PhotoStorage';
import { ClothingCategory } from '../../domain/clothing/ClothingCategory';
import { ClothingItem, PurchaseInfo } from '../../domain/clothing/ClothingModels';
import { OutfitDisplaySource } from '../../domain/outfit/OutfitModels';
import {
  buildClothingSearchDocument,
  buildOutfitSearchDocument
} from '../../domain/search/SearchDocumentBuilder';
import { SearchEntityType } from '../../domain/search/SearchModels';
import { createId } from '../../utils/id';
import { toIsoDateTime } from '../../utils/date';
import { normalizeSearchText } from '../../utils/text';

const INSERT_CLOTHING_SQL = `
  INSERT INTO clothing_items (
    id,
    name,
    category,
    note,
    purchase_store_name,
    purchase_price,
    purchase_date,
    purchase_note,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`;

const UPDATE_CLOTHING_SQL = `
  UPDATE clothing_items
  SET
    name = ?,
    category = ?,
    note = ?,
    purchase_store_name = ?,
    purchase_price = ?,
    purchase_date = ?,
    purchase_note = ?,
    updated_at = ?
  WHERE id = ?
`;

const DELETE_CLOTHING_SQL = 'DELETE FROM clothing_items WHERE id = ?';
const DELETE_CLOTHING_PHOTOS_SQL = 'DELETE FROM clothing_photos WHERE clothing_id = ?';
const DELETE_OUTFIT_ITEMS_BY_CLOTHING_ID_SQL = 'DELETE FROM outfit_items WHERE clothing_id = ?';

const INSERT_CLOTHING_PHOTO_SQL = `
  INSERT INTO clothing_photos (
    id,
    clothing_id,
    local_uri,
    sort_order
  )
  VALUES (?, ?, ?, ?)
`;

const SELECT_CLOTHING_BY_ID_SQL = `
  SELECT
    id,
    name,
    category,
    COALESCE(note, '') AS note,
    COALESCE(purchase_store_name, '') AS purchase_store_name,
    purchase_price,
    COALESCE(purchase_price, -1) AS purchase_price_value,
    COALESCE(purchase_date, '') AS purchase_date,
    COALESCE(purchase_note, '') AS purchase_note,
    created_at,
    updated_at
  FROM clothing_items
  WHERE id = ?
`;

const SELECT_CLOTHING_PHOTOS_SQL = `
  SELECT local_uri
  FROM clothing_photos
  WHERE clothing_id = ?
  ORDER BY sort_order ASC
`;

const SELECT_OUTFIT_IDS_BY_CLOTHING_ID_SQL = `
  SELECT outfit_id
  FROM outfit_items
  WHERE clothing_id = ?
  ORDER BY outfit_id ASC
`;

const SELECT_OUTFIT_BY_ID_FOR_SEARCH_SQL = `
  SELECT
    id,
    title,
    COALESCE(note, '') AS note,
    COALESCE(display_source, 'photo') AS display_source,
    created_at,
    updated_at
  FROM outfit_templates
  WHERE id = ?
`;

const SELECT_OUTFIT_CLOTHING_IDS_SQL = `
  SELECT clothing_id
  FROM outfit_items
  WHERE outfit_id = ?
  ORDER BY sort_order ASC
`;

const SELECT_CLOTHING_NAMES_SQL = `
  SELECT id, name
  FROM clothing_items
  WHERE id IN ({placeholders})
`;

const BASE_LIST_CLOTHING_SQL = `
  SELECT
    id,
    name,
    category,
    COALESCE(note, '') AS note,
    COALESCE(purchase_store_name, '') AS purchase_store_name,
    purchase_price,
    COALESCE(purchase_price, -1) AS purchase_price_value,
    COALESCE(purchase_date, '') AS purchase_date,
    COALESCE(purchase_note, '') AS purchase_note,
    created_at,
    updated_at
  FROM clothing_items
`;

const CLOTHING_TEXT_SEARCH_CONDITION =
  "(LOWER(name) LIKE ? ESCAPE '\\' OR LOWER(COALESCE(note, '')) LIKE ? ESCAPE '\\')";

interface ClothingRow {
  id: string;
  name: string;
  category: ClothingCategory;
  note?: string;
  purchaseStoreName?: string;
  purchasePrice?: number;
  purchaseDate?: string;
  purchaseNote?: string;
  createdAt: string;
  updatedAt: string;
}

interface OutfitSearchRow {
  id: string;
  title: string;
  note?: string;
  displaySource: OutfitDisplaySource;
  createdAt: string;
  updatedAt: string;
}

export interface CreateClothingInput {
  name: string;
  category: ClothingCategory;
  photoUris?: string[];
  note?: string;
  purchaseInfo?: PurchaseInfo;
}

export interface UpdateClothingInput {
  id: string;
  name: string;
  category: ClothingCategory;
  photoUris?: string[];
  note?: string;
  purchaseInfo?: PurchaseInfo;
}

export interface ListClothingOptions {
  category?: ClothingCategory;
  query?: string;
}

function optionalString(value: string): string | undefined {
  return value.length > 0 ? value : undefined;
}

function optionalPurchasePrice(value: number): number | undefined {
  return Number.isFinite(value) && value >= 0 ? value / 100 : undefined;
}

function normalizeDomainPrice(value?: number): number | undefined {
  if (value === undefined || !Number.isFinite(value) || value < 0) {
    return undefined;
  }

  return Math.round(value * 100) / 100;
}

function toSqlNullableText(value?: string): string | null {
  if (value === undefined) {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function priceToStoredCents(value?: number): number | null {
  if (value === undefined || !Number.isFinite(value) || value < 0) {
    return null;
  }

  return Math.round(value * 100);
}

function escapeLikeLiteral(value: string): string {
  return value
    .replace(/\\/g, '\\\\')
    .replace(/%/g, '\\%')
    .replace(/_/g, '\\_');
}

function normalizePhotoUris(photoUris?: string[]): string[] {
  if (photoUris === undefined) {
    return [];
  }

  const normalized: string[] = [];
  for (const photoUri of photoUris) {
    const trimmed = photoUri.trim();
    if (trimmed.length > 0) {
      normalized.push(trimmed);
    }
  }

  return normalized;
}

function normalizeClothingCategory(category: string): ClothingCategory {
  const normalized = category.trim();
  return normalized.length > 0 ? normalized as ClothingCategory : ClothingCategory.Top;
}

function categoryFilterValues(category: ClothingCategory): string[] {
  if (category === ClothingCategory.Top) {
    return [category, 'Outerwear', 'Shoes', 'Bag', 'Accessory', 'Other'];
  }

  return [category];
}

export class ClothingRepository {
  private readonly database: MigrationDatabase;
  private readonly searchRepository: SearchRepository;
  private readonly deleteCleanupService: DeleteCleanupService;
  private readonly photoStorage?: PhotoStorage;

  constructor(database: MigrationDatabase, searchIndexMode: SearchIndexMode, photoStorage?: PhotoStorage) {
    this.database = database;
    this.photoStorage = photoStorage;
    this.searchRepository = new SearchRepository(database, searchIndexMode);
    this.deleteCleanupService = this.createDeleteCleanupService();
  }

  async createClothing(input: CreateClothingInput): Promise<ClothingItem> {
    return this.database.transaction(async () => {
      const now = toIsoDateTime(new Date());
      const item: ClothingItem = {
        id: createId('clothing'),
        name: input.name.trim(),
        category: input.category,
        photoUris: normalizePhotoUris(input.photoUris),
        note: toSqlNullableText(input.note) ?? undefined,
        purchaseInfo: this.normalizePurchaseInfo(input.purchaseInfo),
        createdAt: now,
        updatedAt: now
      };

      await this.database.executeSql(INSERT_CLOTHING_SQL, this.clothingBindArgs(item));
      await this.replacePhotoRows(item.id, item.photoUris);
      await this.searchRepository.upsertDocumentInTransaction(buildClothingSearchDocument(item));

      return item;
    });
  }

  async updateClothing(input: UpdateClothingInput): Promise<ClothingItem> {
    return this.database.transaction(async () => {
      const existing = await this.getClothingByIdInTransaction(input.id);
      if (existing === undefined) {
        throw new Error(`Clothing item not found: ${input.id}`);
      }

      const item: ClothingItem = {
        id: input.id,
        name: input.name.trim(),
        category: input.category,
        photoUris: normalizePhotoUris(input.photoUris),
        note: toSqlNullableText(input.note) ?? undefined,
        purchaseInfo: this.normalizePurchaseInfo(input.purchaseInfo),
        createdAt: existing.createdAt,
        updatedAt: toIsoDateTime(new Date())
      };

      await this.database.executeSql(UPDATE_CLOTHING_SQL, [
        item.name,
        item.category,
        item.note ?? null,
        item.purchaseInfo?.storeName ?? null,
        priceToStoredCents(item.purchaseInfo?.price),
        item.purchaseInfo?.purchaseDate ?? null,
        item.purchaseInfo?.note ?? null,
        item.updatedAt,
        item.id
      ]);

      await this.replacePhotoRows(item.id, item.photoUris);
      await this.searchRepository.upsertDocumentInTransaction(buildClothingSearchDocument(item));
      await this.rebuildOutfitSearchDocumentsForClothing(item.id);

      return item;
    });
  }

  async deleteClothing(id: string): Promise<void> {
    await this.database.transaction(async () => {
      const affectedOutfitIds = await this.readOutfitIdsByClothingId(id);
      await this.deleteCleanupService.deleteObjectPhotos('clothing_photos', 'clothing_id', id);
      await this.database.executeSql(DELETE_OUTFIT_ITEMS_BY_CLOTHING_ID_SQL, [id]);
      await this.database.executeSql(DELETE_CLOTHING_SQL, [id]);
      await this.searchRepository.deleteDocumentInTransaction(SearchEntityType.Clothing, id);
      await this.rebuildOutfitSearchDocuments(affectedOutfitIds);
    });
  }

  async listClothing(options: ListClothingOptions = {}): Promise<ClothingItem[]> {
    const whereClauses: string[] = [];
    const bindArgs: MigrationSqlValue[] = [];

    if (options.category !== undefined) {
      const categoryValues = categoryFilterValues(options.category);
      whereClauses.push(`category IN (${categoryValues.map(() => '?').join(', ')})`);
      bindArgs.push(...categoryValues);
    }

    const normalizedQuery = normalizeSearchText(options.query ?? '');
    if (normalizedQuery.length > 0) {
      whereClauses.push(CLOTHING_TEXT_SEARCH_CONDITION);
      const likeQuery = `%${escapeLikeLiteral(normalizedQuery)}%`;
      bindArgs.push(likeQuery, likeQuery);
    }

    const whereSql = whereClauses.length > 0 ? ` WHERE ${whereClauses.join(' AND ')}` : '';
    const rows = await this.readClothingRows(`${BASE_LIST_CLOTHING_SQL}${whereSql} ORDER BY updated_at DESC`, bindArgs);
    return this.hydrateClothingItems(rows);
  }

  async getClothingById(id: string): Promise<ClothingItem | undefined> {
    return this.getClothingByIdInTransaction(id);
  }

  private async getClothingByIdInTransaction(id: string): Promise<ClothingItem | undefined> {
    const rows = await this.readClothingRows(SELECT_CLOTHING_BY_ID_SQL, [id]);
    if (rows.length === 0) {
      return undefined;
    }

    const items = await this.hydrateClothingItems(rows);
    return items[0];
  }

  private createDeleteCleanupService(): DeleteCleanupService {
    return new DeleteCleanupService(this.database, this.searchRepository, this.photoStorage);
  }

  private clothingBindArgs(item: ClothingItem): MigrationSqlValue[] {
    return [
      item.id,
      item.name,
      item.category,
      item.note ?? null,
      item.purchaseInfo?.storeName ?? null,
      priceToStoredCents(item.purchaseInfo?.price),
      item.purchaseInfo?.purchaseDate ?? null,
      item.purchaseInfo?.note ?? null,
      item.createdAt,
      item.updatedAt
    ];
  }

  private async replacePhotoRows(clothingId: string, photoUris: string[]): Promise<void> {
    const existingPhotoUris = await this.deleteCleanupService.readObjectPhotoUris(
      'clothing_photos',
      'clothing_id',
      clothingId
    );
    await this.database.executeSql(DELETE_CLOTHING_PHOTOS_SQL, [clothingId]);
    await this.deleteCleanupService.cleanupReplacedPhotos(
      'clothing_photos',
      'clothing_id',
      clothingId,
      existingPhotoUris,
      photoUris
    );

    for (let index = 0; index < photoUris.length; index += 1) {
      await this.database.executeSql(INSERT_CLOTHING_PHOTO_SQL, [
        createId('clothing_photo'),
        clothingId,
        photoUris[index],
        index
      ]);
    }
  }

  private async hydrateClothingItems(rows: ClothingRow[]): Promise<ClothingItem[]> {
    const items: ClothingItem[] = [];

    for (const row of rows) {
      items.push({
        id: row.id,
        name: row.name,
        category: row.category,
        photoUris: await this.readPhotoUris(row.id),
        note: row.note,
        purchaseInfo: this.purchaseInfoFromRow(row),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt
      });
    }

    return items;
  }

  private async readClothingRows(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<ClothingRow[]> {
    const resultSet = await this.database.querySql(sql, bindArgs);
    const rows: ClothingRow[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        rows.push(this.readClothingRow(resultSet));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return rows;
  }

  private async rebuildOutfitSearchDocumentsForClothing(clothingId: string): Promise<void> {
    await this.rebuildOutfitSearchDocuments(await this.readOutfitIdsByClothingId(clothingId));
  }

  private async rebuildOutfitSearchDocuments(outfitIds: string[]): Promise<void> {
    for (const outfitId of outfitIds) {
      const outfit = await this.readOutfitForSearch(outfitId);
      if (outfit === undefined) {
        await this.searchRepository.deleteDocumentInTransaction(SearchEntityType.Outfit, outfitId);
        continue;
      }

      const clothingItemIds = await this.readOutfitClothingItemIds(outfitId);
      const clothingNames = await this.loadClothingNames(clothingItemIds);
      await this.searchRepository.upsertDocumentInTransaction(buildOutfitSearchDocument({
        id: outfit.id,
        title: outfit.title,
        photoUris: [],
        clothingItemIds,
        displaySource: outfit.displaySource,
        note: outfit.note,
        createdAt: outfit.createdAt,
        updatedAt: outfit.updatedAt
      }, clothingNames));
    }
  }

  private async readOutfitIdsByClothingId(clothingId: string): Promise<string[]> {
    const resultSet = await this.database.querySql(SELECT_OUTFIT_IDS_BY_CLOTHING_ID_SQL, [clothingId]);
    const outfitIds: string[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        const outfitId = resultSet.getString('outfit_id');
        if (outfitId.length > 0) {
          outfitIds.push(outfitId);
        }
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return outfitIds;
  }

  private async readOutfitForSearch(outfitId: string): Promise<OutfitSearchRow | undefined> {
    const resultSet = await this.database.querySql(SELECT_OUTFIT_BY_ID_FOR_SEARCH_SQL, [outfitId]);

    try {
      if (!resultSet.goToFirstRow()) {
        return undefined;
      }

      return {
        id: resultSet.getString('id'),
        title: resultSet.getString('title'),
        note: optionalString(resultSet.getString('note')),
        displaySource: resultSet.getString('display_source') === OutfitDisplaySource.Wardrobe
          ? OutfitDisplaySource.Wardrobe
          : OutfitDisplaySource.Photo,
        createdAt: resultSet.getString('created_at'),
        updatedAt: resultSet.getString('updated_at')
      };
    } finally {
      resultSet.close();
    }
  }

  private async readOutfitClothingItemIds(outfitId: string): Promise<string[]> {
    const resultSet = await this.database.querySql(SELECT_OUTFIT_CLOTHING_IDS_SQL, [outfitId]);
    const clothingItemIds: string[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        const clothingItemId = resultSet.getString('clothing_id');
        if (clothingItemId.length > 0) {
          clothingItemIds.push(clothingItemId);
        }
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return clothingItemIds;
  }

  private async loadClothingNames(clothingItemIds: string[]): Promise<string[]> {
    if (clothingItemIds.length === 0) {
      return [];
    }

    const placeholders = clothingItemIds.map(() => '?').join(', ');
    const resultSet = await this.database.querySql(
      SELECT_CLOTHING_NAMES_SQL.replace('{placeholders}', placeholders),
      clothingItemIds
    );
    const namesById = new Map<string, string>();

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        namesById.set(resultSet.getString('id'), resultSet.getString('name'));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    const clothingNames: string[] = [];
    for (const clothingItemId of clothingItemIds) {
      const clothingName = namesById.get(clothingItemId);
      if (clothingName !== undefined) {
        clothingNames.push(clothingName);
      }
    }

    return clothingNames;
  }

  private readClothingRow(resultSet: MigrationResultSet): ClothingRow {
    return {
      id: resultSet.getString('id'),
      name: resultSet.getString('name'),
      category: normalizeClothingCategory(resultSet.getString('category')),
      note: optionalString(resultSet.getString('note')),
      purchaseStoreName: optionalString(resultSet.getString('purchase_store_name')),
      purchasePrice: optionalPurchasePrice(resultSet.getNumber('purchase_price_value')),
      purchaseDate: optionalString(resultSet.getString('purchase_date')),
      purchaseNote: optionalString(resultSet.getString('purchase_note')),
      createdAt: resultSet.getString('created_at'),
      updatedAt: resultSet.getString('updated_at')
    };
  }

  private async readPhotoUris(clothingId: string): Promise<string[]> {
    const resultSet = await this.database.querySql(SELECT_CLOTHING_PHOTOS_SQL, [clothingId]);
    const photoUris: string[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        const photoUri = resultSet.getString('local_uri');
        if (photoUri.length > 0) {
          photoUris.push(photoUri);
        }
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return photoUris;
  }

  private normalizePurchaseInfo(purchaseInfo?: PurchaseInfo): PurchaseInfo | undefined {
    if (purchaseInfo === undefined) {
      return undefined;
    }

    const normalized: PurchaseInfo = {};
    const storeName = toSqlNullableText(purchaseInfo.storeName);
    const purchaseDate = toSqlNullableText(purchaseInfo.purchaseDate);
    const note = toSqlNullableText(purchaseInfo.note);
    const price = normalizeDomainPrice(purchaseInfo.price);

    if (storeName !== null) {
      normalized.storeName = storeName;
    }
    if (price !== undefined) {
      normalized.price = price;
    }
    if (purchaseDate !== null) {
      normalized.purchaseDate = purchaseDate;
    }
    if (note !== null) {
      normalized.note = note;
    }

    if (
      normalized.storeName === undefined &&
      normalized.price === undefined &&
      normalized.purchaseDate === undefined &&
      normalized.note === undefined
    ) {
      return undefined;
    }

    return normalized;
  }

  private purchaseInfoFromRow(row: ClothingRow): PurchaseInfo | undefined {
    const purchaseInfo: PurchaseInfo = {};

    if (row.purchaseStoreName !== undefined) {
      purchaseInfo.storeName = row.purchaseStoreName;
    }
    if (row.purchasePrice !== undefined) {
      purchaseInfo.price = row.purchasePrice;
    }
    if (row.purchaseDate !== undefined) {
      purchaseInfo.purchaseDate = row.purchaseDate;
    }
    if (row.purchaseNote !== undefined) {
      purchaseInfo.note = row.purchaseNote;
    }

    if (
      purchaseInfo.storeName === undefined &&
      purchaseInfo.price === undefined &&
      purchaseInfo.purchaseDate === undefined &&
      purchaseInfo.note === undefined
    ) {
      return undefined;
    }

    return purchaseInfo;
  }
}
