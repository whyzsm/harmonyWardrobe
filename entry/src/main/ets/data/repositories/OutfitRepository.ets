import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { DeleteCleanupService } from './DeleteCleanupService';
import { SearchRepository } from './SearchRepository';
import { SearchIndexMode } from '../searchIndex/SearchCapability';
import { PhotoStorage } from '../../media/PhotoStorage';
import {
  OUTFIT_CATEGORY_MAX_LENGTH,
  OutfitCategory,
  OutfitDisplaySource,
  OutfitTemplate
} from '../../domain/outfit/OutfitModels';
import { WearLog } from '../../domain/wearLog/WearLogModels';
import { buildOutfitSearchDocument } from '../../domain/search/SearchDocumentBuilder';
import { SearchEntityType } from '../../domain/search/SearchModels';
import { createId } from '../../utils/id';
import { toIsoDateTime } from '../../utils/date';
import { normalizeSearchText } from '../../utils/text';

const INSERT_OUTFIT_SQL = `
  INSERT INTO outfit_templates (
    id,
    title,
    category_id,
    note,
    display_source,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?)
`;

const UPDATE_OUTFIT_SQL = `
  UPDATE outfit_templates
  SET
    title = ?,
    category_id = ?,
    note = ?,
    display_source = ?,
    updated_at = ?
  WHERE id = ?
`;

const DELETE_OUTFIT_SQL = 'DELETE FROM outfit_templates WHERE id = ?';
const DELETE_OUTFIT_PHOTOS_SQL = 'DELETE FROM outfit_photos WHERE outfit_id = ?';
const DELETE_OUTFIT_ITEMS_SQL = 'DELETE FROM outfit_items WHERE outfit_id = ?';
const DELETE_OUTFIT_CATEGORY_RELATIONS_SQL = 'DELETE FROM outfit_template_categories WHERE outfit_id = ?';
const COUNT_OUTFITS_SQL = 'SELECT COUNT(*) AS total_count FROM outfit_templates';
const DELETE_OUTFIT_CATEGORY_SQL = 'DELETE FROM outfit_categories WHERE id = ?';
const DELETE_CATEGORY_RELATIONS_SQL = 'DELETE FROM outfit_template_categories WHERE category_id = ?';
const UPDATE_LEGACY_OUTFIT_CATEGORY_SQL = 'UPDATE outfit_templates SET category_id = ? WHERE id = ?';

const INSERT_OUTFIT_CATEGORY_SQL = `
  INSERT INTO outfit_categories (
    id,
    name,
    normalized_name,
    sort_order,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, 1000, ?, ?)
`;

const LIST_OUTFIT_CATEGORIES_SQL = `
  SELECT
    categories.id,
    categories.name,
    COUNT(DISTINCT relations.outfit_id) AS usage_count
  FROM outfit_categories AS categories
  LEFT JOIN outfit_template_categories AS relations ON relations.category_id = categories.id
  GROUP BY categories.id, categories.name, categories.sort_order, categories.created_at
  ORDER BY categories.sort_order ASC, categories.created_at ASC, categories.name ASC
`;

const SELECT_OUTFIT_CATEGORY_BY_NORMALIZED_NAME_SQL = `
  SELECT
    categories.id,
    categories.name,
    COUNT(DISTINCT relations.outfit_id) AS usage_count
  FROM outfit_categories AS categories
  LEFT JOIN outfit_template_categories AS relations ON relations.category_id = categories.id
  WHERE categories.normalized_name = ?
  GROUP BY categories.id, categories.name
`;

const SELECT_OUTFIT_IDS_BY_CATEGORY_SQL = `
  SELECT outfit_id
  FROM outfit_template_categories
  WHERE category_id = ?
  ORDER BY outfit_id ASC
`;

const INSERT_OUTFIT_CATEGORY_RELATION_SQL = `
  INSERT INTO outfit_template_categories (
    outfit_id,
    category_id,
    sort_order
  )
  VALUES (?, ?, ?)
`;

const SELECT_OUTFIT_CATEGORY_RELATIONS_SQL = `
  SELECT
    relations.category_id,
    categories.name AS category_name
  FROM outfit_template_categories AS relations
  INNER JOIN outfit_categories AS categories ON categories.id = relations.category_id
  WHERE relations.outfit_id = ?
  ORDER BY relations.sort_order ASC, categories.sort_order ASC, categories.created_at ASC
`;

const INSERT_OUTFIT_PHOTO_SQL = `
  INSERT INTO outfit_photos (
    id,
    outfit_id,
    local_uri,
    sort_order
  )
  VALUES (?, ?, ?, ?)
`;

const INSERT_OUTFIT_ITEM_SQL = `
  INSERT INTO outfit_items (
    outfit_id,
    clothing_id,
    sort_order
  )
  VALUES (?, ?, ?)
`;

const SELECT_OUTFIT_BY_ID_SQL = `
  SELECT
    outfits.id,
    outfits.title,
    COALESCE(outfits.note, '') AS note,
    COALESCE(outfits.display_source, 'photo') AS display_source,
    outfits.created_at,
    outfits.updated_at
  FROM outfit_templates AS outfits
  WHERE outfits.id = ?
`;

const BASE_LIST_OUTFITS_SQL = `
  SELECT
    outfits.id,
    outfits.title,
    COALESCE(outfits.note, '') AS note,
    COALESCE(outfits.display_source, 'photo') AS display_source,
    outfits.created_at,
    outfits.updated_at
  FROM outfit_templates AS outfits
`;

const SELECT_OUTFIT_PHOTOS_SQL = `
  SELECT local_uri
  FROM outfit_photos
  WHERE outfit_id = ?
  ORDER BY sort_order ASC
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

const SELECT_RECENT_WEAR_LOGS_SQL = `
  SELECT
    id,
    COALESCE(outfit_id, '') AS outfit_id,
    outfit_title_snapshot,
    clothing_item_ids_snapshot,
    worn_date,
    COALESCE(place_text, '') AS place_text,
    COALESCE(note, '') AS note,
    created_at,
    updated_at
  FROM wear_logs
  WHERE outfit_id = ?
  ORDER BY worn_date DESC, updated_at DESC
  LIMIT ?
`;

const SELECT_WEAR_LOG_PHOTOS_SQL = `
  SELECT local_uri
  FROM wear_log_photos
  WHERE wear_log_id = ?
  ORDER BY sort_order ASC
`;

interface OutfitRow {
  id: string;
  title: string;
  note?: string;
  displaySource: OutfitDisplaySource;
  createdAt: string;
  updatedAt: string;
}

interface OutfitCategorySelection {
  ids: string[];
  names: string[];
}

interface WearLogRow {
  id: string;
  outfitTemplateId?: string;
  outfitTitleSnapshot: string;
  clothingItemIdsSnapshot: string[];
  wornDate: string;
  placeText?: string;
  note?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateOutfitInput {
  title: string;
  categoryNames?: string[];
  photoUris?: string[];
  clothingItemIds?: string[];
  displaySource?: OutfitDisplaySource;
  note?: string;
}

export interface UpdateOutfitInput {
  id: string;
  title: string;
  categoryNames?: string[];
  photoUris?: string[];
  clothingItemIds?: string[];
  displaySource?: OutfitDisplaySource;
  note?: string;
}

export interface OutfitWithRecentWearLogs {
  outfit: OutfitTemplate;
  recentWearLogs: WearLog[];
}

function optionalString(value: string): string | undefined {
  return value.length > 0 ? value : undefined;
}

function toSqlNullableText(value?: string): string | null {
  if (value === undefined) {
    return null;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function normalizeOutfitCategoryName(value?: string): string | undefined {
  if (value === undefined) {
    return undefined;
  }

  const name = value.normalize('NFKC').trim().replace(/\s+/g, ' ');
  if (name.length === 0) {
    return undefined;
  }
  if (name.length > OUTFIT_CATEGORY_MAX_LENGTH) {
    throw new Error(`分类名称最多 ${OUTFIT_CATEGORY_MAX_LENGTH} 个字符`);
  }

  const normalizedName = normalizeSearchText(name);
  if (normalizedName === normalizeSearchText('全部') || normalizedName === normalizeSearchText('未分类')) {
    throw new Error('“全部”和“未分类”不能作为自定义分类');
  }

  return name;
}

function normalizeOutfitCategoryNames(categoryNames?: string[]): string[] {
  if (categoryNames === undefined) {
    return [];
  }

  const names: string[] = [];
  const seen = new Set<string>();
  for (const categoryName of categoryNames) {
    const name = normalizeOutfitCategoryName(categoryName);
    if (name === undefined) {
      continue;
    }

    const normalizedName = normalizeSearchText(name);
    if (!seen.has(normalizedName)) {
      seen.add(normalizedName);
      names.push(name);
    }
  }

  return names;
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

function normalizeClothingItemIds(clothingItemIds?: string[]): string[] {
  if (clothingItemIds === undefined) {
    return [];
  }

  const normalized: string[] = [];
  const seen = new Set<string>();
  for (const clothingItemId of clothingItemIds) {
    const trimmed = clothingItemId.trim();
    if (trimmed.length > 0 && !seen.has(trimmed)) {
      seen.add(trimmed);
      normalized.push(trimmed);
    }
  }

  return normalized;
}

function normalizeDisplaySource(displaySource?: OutfitDisplaySource): OutfitDisplaySource {
  return displaySource === OutfitDisplaySource.Wardrobe
    ? OutfitDisplaySource.Wardrobe
    : OutfitDisplaySource.Photo;
}

function parseDisplaySource(value: string): OutfitDisplaySource {
  return value === OutfitDisplaySource.Wardrobe
    ? OutfitDisplaySource.Wardrobe
    : OutfitDisplaySource.Photo;
}

function decodeClothingItemIdsSnapshot(value: string): string[] {
  try {
    const parsed = JSON.parse(value) as string[];
    if (Array.isArray(parsed)) {
      const ids: string[] = [];
      for (const id of parsed) {
        if (typeof id === 'string' && id.trim().length > 0) {
          ids.push(id.trim());
        }
      }
      return ids;
    }
  } catch (error) {
    return decodeLegacyClothingItemIdsSnapshot(value);
  }

  return decodeLegacyClothingItemIdsSnapshot(value);
}

function decodeLegacyClothingItemIdsSnapshot(value: string): string[] {
  const ids: string[] = [];
  for (const id of value.split(',')) {
    const trimmed = id.trim();
    if (trimmed.length > 0) {
      ids.push(trimmed);
    }
  }

  return ids;
}

function normalizeLimit(limit: number = 5): number {
  if (!Number.isFinite(limit) || limit <= 0) {
    return 5;
  }

  return Math.min(20, Math.max(1, Math.floor(limit)));
}

export class OutfitRepository {
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

  async createOutfit(input: CreateOutfitInput): Promise<OutfitTemplate> {
    return this.database.transaction(async () => {
      const now = toIsoDateTime(new Date());
      const categories = await this.resolveOutfitCategories(input.categoryNames, now);
      const categoryIds = categories.map((category: OutfitCategory) => category.id);
      const categoryNames = categories.map((category: OutfitCategory) => category.name);
      const item: OutfitTemplate = {
        id: createId('outfit'),
        title: input.title.trim(),
        photoUris: normalizePhotoUris(input.photoUris),
        clothingItemIds: normalizeClothingItemIds(input.clothingItemIds),
        displaySource: normalizeDisplaySource(input.displaySource),
        categoryIds,
        categoryNames,
        categoryId: categoryIds[0],
        categoryName: categoryNames[0],
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: now,
        updatedAt: now
      };

      await this.database.executeSql(INSERT_OUTFIT_SQL, this.outfitBindArgs(item));
      await this.replaceCategoryRows(item.id, item.categoryIds);
      await this.replacePhotoRows(item.id, item.photoUris);
      await this.replaceClothingRows(item.id, item.clothingItemIds);
      await this.upsertSearchDocument(item);

      return item;
    });
  }

  async updateOutfit(input: UpdateOutfitInput): Promise<OutfitTemplate> {
    return this.database.transaction(async () => {
      const existing = await this.getOutfitByIdInTransaction(input.id);
      if (existing === undefined) {
        throw new Error(`Outfit not found: ${input.id}`);
      }

      const now = toIsoDateTime(new Date());
      const categories = await this.resolveOutfitCategories(input.categoryNames, now);
      const categoryIds = categories.map((category: OutfitCategory) => category.id);
      const categoryNames = categories.map((category: OutfitCategory) => category.name);
      const item: OutfitTemplate = {
        id: input.id,
        title: input.title.trim(),
        photoUris: normalizePhotoUris(input.photoUris),
        clothingItemIds: normalizeClothingItemIds(input.clothingItemIds),
        displaySource: normalizeDisplaySource(input.displaySource ?? existing.displaySource),
        categoryIds,
        categoryNames,
        categoryId: categoryIds[0],
        categoryName: categoryNames[0],
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: existing.createdAt,
        updatedAt: now
      };

      await this.database.executeSql(UPDATE_OUTFIT_SQL, [
        item.title,
        item.categoryId ?? null,
        item.note ?? null,
        item.displaySource,
        item.updatedAt,
        item.id
      ]);

      await this.replaceCategoryRows(item.id, item.categoryIds);
      await this.replacePhotoRows(item.id, item.photoUris);
      await this.replaceClothingRows(item.id, item.clothingItemIds);
      await this.upsertSearchDocument(item);

      return item;
    });
  }

  async deleteOutfit(id: string): Promise<void> {
    await this.database.transaction(async () => {
      await this.deleteCleanupService.deleteObjectPhotos('outfit_photos', 'outfit_id', id);
      await this.database.executeSql(DELETE_OUTFIT_ITEMS_SQL, [id]);
      await this.database.executeSql(DELETE_OUTFIT_CATEGORY_RELATIONS_SQL, [id]);
      await this.database.executeSql(DELETE_OUTFIT_SQL, [id]);
      await this.searchRepository.deleteDocumentInTransaction(SearchEntityType.Outfit, id);
    });
  }

  async listOutfits(): Promise<OutfitTemplate[]> {
    const rows = await this.readOutfitRows(`${BASE_LIST_OUTFITS_SQL} ORDER BY outfits.updated_at DESC`);
    return this.hydrateOutfits(rows);
  }

  async listOutfitCategories(): Promise<OutfitCategory[]> {
    const resultSet = await this.database.querySql(LIST_OUTFIT_CATEGORIES_SQL);
    const categories: OutfitCategory[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        categories.push(this.readOutfitCategoryRow(resultSet));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return categories;
  }

  async deleteOutfitCategory(id: string): Promise<number> {
    return this.database.transaction(async () => {
      const outfitIds = await this.readOutfitIdsByCategory(id);
      await this.database.executeSql(DELETE_CATEGORY_RELATIONS_SQL, [id]);
      await this.database.executeSql(DELETE_OUTFIT_CATEGORY_SQL, [id]);

      for (const outfitId of outfitIds) {
        const outfit = await this.getOutfitByIdInTransaction(outfitId);
        if (outfit === undefined) {
          continue;
        }

        await this.database.executeSql(UPDATE_LEGACY_OUTFIT_CATEGORY_SQL, [outfit.categoryIds[0] ?? null, outfit.id]);
        await this.upsertSearchDocument(outfit);
      }

      return outfitIds.length;
    });
  }

  async getOutfitCount(): Promise<number> {
    const resultSet = await this.database.querySql(COUNT_OUTFITS_SQL);

    try {
      return resultSet.goToFirstRow() ? resultSet.getNumber('total_count') : 0;
    } finally {
      resultSet.close();
    }
  }

  async getOutfitById(id: string): Promise<OutfitTemplate | undefined> {
    return this.getOutfitByIdInTransaction(id);
  }

  async loadRecentWearLogs(outfitId: string, limit: number = 5): Promise<WearLog[]> {
    const resultSet = await this.database.querySql(SELECT_RECENT_WEAR_LOGS_SQL, [outfitId, normalizeLimit(limit)]);
    const rows: WearLogRow[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        rows.push(this.readWearLogRow(resultSet));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return this.hydrateWearLogs(rows);
  }

  async getOutfitWithRecentWearLogs(id: string, limit: number = 5): Promise<OutfitWithRecentWearLogs | undefined> {
    const outfit = await this.getOutfitById(id);
    if (outfit === undefined) {
      return undefined;
    }

    return {
      outfit,
      recentWearLogs: await this.loadRecentWearLogs(id, limit)
    };
  }

  private async getOutfitByIdInTransaction(id: string): Promise<OutfitTemplate | undefined> {
    const rows = await this.readOutfitRows(SELECT_OUTFIT_BY_ID_SQL, [id]);
    if (rows.length === 0) {
      return undefined;
    }

    const items = await this.hydrateOutfits(rows);
    return items[0];
  }

  private createDeleteCleanupService(): DeleteCleanupService {
    return new DeleteCleanupService(this.database, this.searchRepository, this.photoStorage);
  }

  private outfitBindArgs(item: OutfitTemplate): MigrationSqlValue[] {
    return [
      item.id,
      item.title,
      item.categoryId ?? null,
      item.note ?? null,
      item.displaySource,
      item.createdAt,
      item.updatedAt
    ];
  }

  private async resolveOutfitCategories(categoryNames: string[] | undefined, now: string): Promise<OutfitCategory[]> {
    const categories: OutfitCategory[] = [];
    for (const name of normalizeOutfitCategoryNames(categoryNames)) {
      const normalizedName = normalizeSearchText(name);
      const existing = await this.findOutfitCategoryByNormalizedName(normalizedName);
      if (existing !== undefined) {
        categories.push(existing);
        continue;
      }

      const category: OutfitCategory = {
        id: createId('outfit_category'),
        name,
        usageCount: 0
      };
      await this.database.executeSql(INSERT_OUTFIT_CATEGORY_SQL, [
        category.id,
        category.name,
        normalizedName,
        now,
        now
      ]);
      categories.push(category);
    }

    return categories;
  }

  private async findOutfitCategoryByNormalizedName(normalizedName: string): Promise<OutfitCategory | undefined> {
    const resultSet = await this.database.querySql(SELECT_OUTFIT_CATEGORY_BY_NORMALIZED_NAME_SQL, [normalizedName]);
    try {
      if (!resultSet.goToFirstRow()) {
        return undefined;
      }

      return this.readOutfitCategoryRow(resultSet);
    } finally {
      resultSet.close();
    }
  }

  private readOutfitCategoryRow(resultSet: MigrationResultSet): OutfitCategory {
    return {
      id: resultSet.getString('id'),
      name: resultSet.getString('name'),
      usageCount: resultSet.getNumber('usage_count')
    };
  }

  private async readOutfitIdsByCategory(categoryId: string): Promise<string[]> {
    const resultSet = await this.database.querySql(SELECT_OUTFIT_IDS_BY_CATEGORY_SQL, [categoryId]);
    const outfitIds: string[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        outfitIds.push(resultSet.getString('outfit_id'));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return outfitIds;
  }

  private async replaceCategoryRows(outfitId: string, categoryIds: string[]): Promise<void> {
    await this.database.executeSql(DELETE_OUTFIT_CATEGORY_RELATIONS_SQL, [outfitId]);

    for (let index = 0; index < categoryIds.length; index += 1) {
      await this.database.executeSql(INSERT_OUTFIT_CATEGORY_RELATION_SQL, [
        outfitId,
        categoryIds[index],
        index
      ]);
    }
  }

  private async replacePhotoRows(outfitId: string, photoUris: string[]): Promise<void> {
    const existingPhotoUris = await this.deleteCleanupService.readObjectPhotoUris(
      'outfit_photos',
      'outfit_id',
      outfitId
    );
    await this.database.executeSql(DELETE_OUTFIT_PHOTOS_SQL, [outfitId]);
    await this.deleteCleanupService.cleanupReplacedPhotos(
      'outfit_photos',
      'outfit_id',
      outfitId,
      existingPhotoUris,
      photoUris
    );

    for (let index = 0; index < photoUris.length; index += 1) {
      await this.database.executeSql(INSERT_OUTFIT_PHOTO_SQL, [
        createId('outfit_photo'),
        outfitId,
        photoUris[index],
        index
      ]);
    }
  }

  private async replaceClothingRows(outfitId: string, clothingItemIds: string[]): Promise<void> {
    await this.database.executeSql(DELETE_OUTFIT_ITEMS_SQL, [outfitId]);

    for (let index = 0; index < clothingItemIds.length; index += 1) {
      await this.database.executeSql(INSERT_OUTFIT_ITEM_SQL, [
        outfitId,
        clothingItemIds[index],
        index
      ]);
    }
  }

  private async upsertSearchDocument(item: OutfitTemplate): Promise<void> {
    const clothingNames = await this.loadClothingNames(item.clothingItemIds);
    await this.searchRepository.upsertDocumentInTransaction(buildOutfitSearchDocument(item, clothingNames));
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

  private async hydrateOutfits(rows: OutfitRow[]): Promise<OutfitTemplate[]> {
    const items: OutfitTemplate[] = [];

    for (const row of rows) {
      const categories = await this.readOutfitCategorySelection(row.id);
      items.push({
        id: row.id,
        title: row.title,
        photoUris: await this.readPhotoUris(row.id),
        clothingItemIds: await this.readClothingItemIds(row.id),
        displaySource: row.displaySource,
        categoryIds: categories.ids,
        categoryNames: categories.names,
        categoryId: categories.ids[0],
        categoryName: categories.names[0],
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt
      });
    }

    return items;
  }

  private async readOutfitRows(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<OutfitRow[]> {
    const resultSet = await this.database.querySql(sql, bindArgs);
    const rows: OutfitRow[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        rows.push(this.readOutfitRow(resultSet));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return rows;
  }

  private readOutfitRow(resultSet: MigrationResultSet): OutfitRow {
    return {
      id: resultSet.getString('id'),
      title: resultSet.getString('title'),
      note: optionalString(resultSet.getString('note')),
      displaySource: parseDisplaySource(resultSet.getString('display_source')),
      createdAt: resultSet.getString('created_at'),
      updatedAt: resultSet.getString('updated_at')
    };
  }

  private async readOutfitCategorySelection(outfitId: string): Promise<OutfitCategorySelection> {
    const resultSet = await this.database.querySql(SELECT_OUTFIT_CATEGORY_RELATIONS_SQL, [outfitId]);
    const ids: string[] = [];
    const names: string[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        ids.push(resultSet.getString('category_id'));
        names.push(resultSet.getString('category_name'));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return { ids, names };
  }

  private async readPhotoUris(outfitId: string): Promise<string[]> {
    const resultSet = await this.database.querySql(SELECT_OUTFIT_PHOTOS_SQL, [outfitId]);
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

  private async readClothingItemIds(outfitId: string): Promise<string[]> {
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

  private readWearLogRow(resultSet: MigrationResultSet): WearLogRow {
    return {
      id: resultSet.getString('id'),
      outfitTemplateId: optionalString(resultSet.getString('outfit_id')),
      outfitTitleSnapshot: resultSet.getString('outfit_title_snapshot'),
      clothingItemIdsSnapshot: decodeClothingItemIdsSnapshot(resultSet.getString('clothing_item_ids_snapshot')),
      wornDate: resultSet.getString('worn_date'),
      placeText: optionalString(resultSet.getString('place_text')),
      note: optionalString(resultSet.getString('note')),
      createdAt: resultSet.getString('created_at'),
      updatedAt: resultSet.getString('updated_at')
    };
  }

  private async hydrateWearLogs(rows: WearLogRow[]): Promise<WearLog[]> {
    const wearLogs: WearLog[] = [];

    for (const row of rows) {
      wearLogs.push({
        id: row.id,
        outfitTemplateId: row.outfitTemplateId,
        outfitTitleSnapshot: row.outfitTitleSnapshot,
        clothingItemIdsSnapshot: row.clothingItemIdsSnapshot,
        wornDate: row.wornDate,
        photoUris: await this.readWearLogPhotoUris(row.id),
        placeText: row.placeText,
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt
      });
    }

    return wearLogs;
  }

  private async readWearLogPhotoUris(wearLogId: string): Promise<string[]> {
    const resultSet = await this.database.querySql(SELECT_WEAR_LOG_PHOTOS_SQL, [wearLogId]);
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
