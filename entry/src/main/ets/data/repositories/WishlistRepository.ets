import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { DeleteCleanupService } from './DeleteCleanupService';
import { SearchRepository } from './SearchRepository';
import { SearchIndexMode } from '../searchIndex/SearchCapability';
import { PhotoStorage } from '../../media/PhotoStorage';
import { WishlistItem } from '../../domain/wishlist/WishlistModels';
import { buildWishlistSearchDocument } from '../../domain/search/SearchDocumentBuilder';
import { SearchEntityType } from '../../domain/search/SearchModels';
import { createId } from '../../utils/id';
import { toIsoDateTime } from '../../utils/date';
import { normalizeSearchText } from '../../utils/text';

const INSERT_WISHLIST_SQL = `
  INSERT INTO wishlist_items (
    id,
    title,
    store_name,
    price,
    note,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?)
`;

const UPDATE_WISHLIST_SQL = `
  UPDATE wishlist_items
  SET
    title = ?,
    store_name = ?,
    price = ?,
    note = ?,
    updated_at = ?
  WHERE id = ?
`;

const DELETE_WISHLIST_SQL = 'DELETE FROM wishlist_items WHERE id = ?';
const DELETE_WISHLIST_PHOTOS_SQL = 'DELETE FROM wishlist_photos WHERE wishlist_id = ?';

const INSERT_WISHLIST_PHOTO_SQL = `
  INSERT INTO wishlist_photos (
    id,
    wishlist_id,
    local_uri,
    sort_order
  )
  VALUES (?, ?, ?, ?)
`;

const SELECT_WISHLIST_BY_ID_SQL = `
  SELECT
    id,
    title,
    COALESCE(store_name, '') AS store_name,
    price,
    COALESCE(price, -1) AS price_value,
    COALESCE(note, '') AS note,
    created_at,
    updated_at
  FROM wishlist_items
  WHERE id = ?
`;

const BASE_LIST_WISHLIST_SQL = `
  SELECT
    id,
    title,
    COALESCE(store_name, '') AS store_name,
    price,
    COALESCE(price, -1) AS price_value,
    COALESCE(note, '') AS note,
    created_at,
    updated_at
  FROM wishlist_items
`;

const SELECT_WISHLIST_PHOTOS_SQL = `
  SELECT local_uri
  FROM wishlist_photos
  WHERE wishlist_id = ?
  ORDER BY sort_order ASC
`;

const WISHLIST_TEXT_SEARCH_CONDITION =
  "(LOWER(title) LIKE ? ESCAPE '\\' OR LOWER(COALESCE(store_name, '')) LIKE ? ESCAPE '\\' OR LOWER(COALESCE(note, '')) LIKE ? ESCAPE '\\')";

interface WishlistRow {
  id: string;
  title: string;
  storeName?: string;
  price?: number;
  note?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateWishlistItemInput {
  title: string;
  photoUris?: string[];
  storeName?: string;
  price?: number;
  note?: string;
}

export interface UpdateWishlistItemInput {
  id: string;
  title: string;
  photoUris?: string[];
  storeName?: string;
  price?: number;
  note?: string;
}

export interface ListWishlistItemsOptions {
  query?: string;
  storeName?: string;
}

function optionalString(value: string): string | undefined {
  return value.length > 0 ? value : undefined;
}

function optionalPrice(value: number): number | undefined {
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

export class WishlistRepository {
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

  async createWishlistItem(input: CreateWishlistItemInput): Promise<WishlistItem> {
    return this.database.transaction(async () => {
      const now = toIsoDateTime(new Date());
      const item: WishlistItem = {
        id: createId('wishlist'),
        title: input.title.trim(),
        photoUris: normalizePhotoUris(input.photoUris),
        storeName: toSqlNullableText(input.storeName) ?? undefined,
        price: normalizeDomainPrice(input.price),
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: now,
        updatedAt: now
      };

      await this.database.executeSql(INSERT_WISHLIST_SQL, this.wishlistBindArgs(item));
      await this.replacePhotoRows(item.id, item.photoUris);
      await this.searchRepository.upsertDocumentInTransaction(buildWishlistSearchDocument(item));

      return item;
    });
  }

  async updateWishlistItem(input: UpdateWishlistItemInput): Promise<WishlistItem> {
    return this.database.transaction(async () => {
      const existing = await this.getWishlistItemByIdInTransaction(input.id);
      if (existing === undefined) {
        throw new Error(`Wishlist item not found: ${input.id}`);
      }

      const item: WishlistItem = {
        id: input.id,
        title: input.title.trim(),
        photoUris: normalizePhotoUris(input.photoUris),
        storeName: toSqlNullableText(input.storeName) ?? undefined,
        price: normalizeDomainPrice(input.price),
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: existing.createdAt,
        updatedAt: toIsoDateTime(new Date())
      };

      await this.database.executeSql(UPDATE_WISHLIST_SQL, [
        item.title,
        item.storeName ?? null,
        priceToStoredCents(item.price),
        item.note ?? null,
        item.updatedAt,
        item.id
      ]);

      await this.replacePhotoRows(item.id, item.photoUris);
      await this.searchRepository.upsertDocumentInTransaction(buildWishlistSearchDocument(item));

      return item;
    });
  }

  async deleteWishlistItem(id: string): Promise<void> {
    await this.database.transaction(async () => {
      await this.deleteCleanupService.deleteObjectPhotos('wishlist_photos', 'wishlist_id', id);
      await this.database.executeSql(DELETE_WISHLIST_SQL, [id]);
      await this.searchRepository.deleteDocumentInTransaction(SearchEntityType.Wishlist, id);
    });
  }

  async listWishlistItems(options: ListWishlistItemsOptions = {}): Promise<WishlistItem[]> {
    const whereClauses: string[] = [];
    const bindArgs: MigrationSqlValue[] = [];

    const storeName = toSqlNullableText(options.storeName);
    if (storeName !== null) {
      whereClauses.push('store_name = ?');
      bindArgs.push(storeName);
    }

    const normalizedQuery = normalizeSearchText(options.query ?? '');
    if (normalizedQuery.length > 0) {
      whereClauses.push(WISHLIST_TEXT_SEARCH_CONDITION);
      const likeQuery = `%${escapeLikeLiteral(normalizedQuery)}%`;
      bindArgs.push(likeQuery, likeQuery, likeQuery);
    }

    const whereSql = whereClauses.length > 0 ? ` WHERE ${whereClauses.join(' AND ')}` : '';
    const rows = await this.readWishlistRows(`${BASE_LIST_WISHLIST_SQL}${whereSql} ORDER BY updated_at DESC`, bindArgs);
    return this.hydrateWishlistItems(rows);
  }

  async getWishlistItemById(id: string): Promise<WishlistItem | undefined> {
    return this.getWishlistItemByIdInTransaction(id);
  }

  private async getWishlistItemByIdInTransaction(id: string): Promise<WishlistItem | undefined> {
    const rows = await this.readWishlistRows(SELECT_WISHLIST_BY_ID_SQL, [id]);
    if (rows.length === 0) {
      return undefined;
    }

    const items = await this.hydrateWishlistItems(rows);
    return items[0];
  }

  private createDeleteCleanupService(): DeleteCleanupService {
    return new DeleteCleanupService(this.database, this.searchRepository, this.photoStorage);
  }

  private wishlistBindArgs(item: WishlistItem): MigrationSqlValue[] {
    return [
      item.id,
      item.title,
      item.storeName ?? null,
      priceToStoredCents(item.price),
      item.note ?? null,
      item.createdAt,
      item.updatedAt
    ];
  }

  private async replacePhotoRows(wishlistId: string, photoUris: string[]): Promise<void> {
    await this.database.executeSql(DELETE_WISHLIST_PHOTOS_SQL, [wishlistId]);

    for (let index = 0; index < photoUris.length; index += 1) {
      await this.database.executeSql(INSERT_WISHLIST_PHOTO_SQL, [
        createId('wishlist_photo'),
        wishlistId,
        photoUris[index],
        index
      ]);
    }
  }

  private async hydrateWishlistItems(rows: WishlistRow[]): Promise<WishlistItem[]> {
    const items: WishlistItem[] = [];

    for (const row of rows) {
      items.push({
        id: row.id,
        title: row.title,
        photoUris: await this.readPhotoUris(row.id),
        storeName: row.storeName,
        price: row.price,
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt
      });
    }

    return items;
  }

  private async readWishlistRows(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<WishlistRow[]> {
    const resultSet = await this.database.querySql(sql, bindArgs);
    const rows: WishlistRow[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        rows.push(this.readWishlistRow(resultSet));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return rows;
  }

  private readWishlistRow(resultSet: MigrationResultSet): WishlistRow {
    return {
      id: resultSet.getString('id'),
      title: resultSet.getString('title'),
      storeName: optionalString(resultSet.getString('store_name')),
      price: optionalPrice(resultSet.getNumber('price_value')),
      note: optionalString(resultSet.getString('note')),
      createdAt: resultSet.getString('created_at'),
      updatedAt: resultSet.getString('updated_at')
    };
  }

  private async readPhotoUris(wishlistId: string): Promise<string[]> {
    const resultSet = await this.database.querySql(SELECT_WISHLIST_PHOTOS_SQL, [wishlistId]);
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
}
