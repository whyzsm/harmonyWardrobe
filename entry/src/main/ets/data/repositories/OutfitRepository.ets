import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { DeleteCleanupService } from './DeleteCleanupService';
import { SearchRepository } from './SearchRepository';
import { SearchIndexMode } from '../searchIndex/SearchCapability';
import { PhotoStorage } from '../../media/PhotoStorage';
import { OutfitDisplaySource, OutfitTemplate } from '../../domain/outfit/OutfitModels';
import { WearLog } from '../../domain/wearLog/WearLogModels';
import { buildOutfitSearchDocument } from '../../domain/search/SearchDocumentBuilder';
import { SearchEntityType } from '../../domain/search/SearchModels';
import { createId } from '../../utils/id';
import { toIsoDateTime } from '../../utils/date';

const INSERT_OUTFIT_SQL = `
  INSERT INTO outfit_templates (
    id,
    title,
    note,
    display_source,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?)
`;

const UPDATE_OUTFIT_SQL = `
  UPDATE outfit_templates
  SET
    title = ?,
    note = ?,
    display_source = ?,
    updated_at = ?
  WHERE id = ?
`;

const DELETE_OUTFIT_SQL = 'DELETE FROM outfit_templates WHERE id = ?';
const DELETE_OUTFIT_PHOTOS_SQL = 'DELETE FROM outfit_photos WHERE outfit_id = ?';
const DELETE_OUTFIT_ITEMS_SQL = 'DELETE FROM outfit_items WHERE outfit_id = ?';

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
    id,
    title,
    COALESCE(note, '') AS note,
    COALESCE(display_source, 'photo') AS display_source,
    created_at,
    updated_at
  FROM outfit_templates
  WHERE id = ?
`;

const BASE_LIST_OUTFITS_SQL = `
  SELECT
    id,
    title,
    COALESCE(note, '') AS note,
    COALESCE(display_source, 'photo') AS display_source,
    created_at,
    updated_at
  FROM outfit_templates
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
  photoUris?: string[];
  clothingItemIds?: string[];
  displaySource?: OutfitDisplaySource;
  note?: string;
}

export interface UpdateOutfitInput {
  id: string;
  title: string;
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
      const item: OutfitTemplate = {
        id: createId('outfit'),
        title: input.title.trim(),
        photoUris: normalizePhotoUris(input.photoUris),
        clothingItemIds: normalizeClothingItemIds(input.clothingItemIds),
        displaySource: normalizeDisplaySource(input.displaySource),
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: now,
        updatedAt: now
      };

      await this.database.executeSql(INSERT_OUTFIT_SQL, this.outfitBindArgs(item));
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

      const item: OutfitTemplate = {
        id: input.id,
        title: input.title.trim(),
        photoUris: normalizePhotoUris(input.photoUris),
        clothingItemIds: normalizeClothingItemIds(input.clothingItemIds),
        displaySource: normalizeDisplaySource(input.displaySource ?? existing.displaySource),
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: existing.createdAt,
        updatedAt: toIsoDateTime(new Date())
      };

      await this.database.executeSql(UPDATE_OUTFIT_SQL, [
        item.title,
        item.note ?? null,
        item.displaySource,
        item.updatedAt,
        item.id
      ]);

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
      await this.database.executeSql(DELETE_OUTFIT_SQL, [id]);
      await this.searchRepository.deleteDocumentInTransaction(SearchEntityType.Outfit, id);
    });
  }

  async listOutfits(): Promise<OutfitTemplate[]> {
    const rows = await this.readOutfitRows(`${BASE_LIST_OUTFITS_SQL} ORDER BY updated_at DESC`);
    return this.hydrateOutfits(rows);
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
      item.note ?? null,
      item.displaySource,
      item.createdAt,
      item.updatedAt
    ];
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
      items.push({
        id: row.id,
        title: row.title,
        photoUris: await this.readPhotoUris(row.id),
        clothingItemIds: await this.readClothingItemIds(row.id),
        displaySource: row.displaySource,
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
