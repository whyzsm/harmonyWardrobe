import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { SearchRepository } from './SearchRepository';
import { SearchIndexMode } from '../searchIndex/SearchCapability';
import { WearLog } from '../../domain/wearLog/WearLogModels';
import { buildWearLogSearchDocument } from '../../domain/search/SearchDocumentBuilder';
import { SearchEntityType } from '../../domain/search/SearchModels';
import { createId } from '../../utils/id';
import { toIsoDateTime } from '../../utils/date';

const INSERT_WEAR_LOG_SQL = `
  INSERT INTO wear_logs (
    id,
    outfit_id,
    outfit_title_snapshot,
    clothing_item_ids_snapshot,
    worn_date,
    place_text,
    note,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
`;

const UPDATE_WEAR_LOG_SQL = `
  UPDATE wear_logs
  SET
    outfit_id = ?,
    outfit_title_snapshot = ?,
    clothing_item_ids_snapshot = ?,
    worn_date = ?,
    place_text = ?,
    note = ?,
    updated_at = ?
  WHERE id = ?
`;

const DELETE_WEAR_LOG_SQL = 'DELETE FROM wear_logs WHERE id = ?';
const DELETE_WEAR_LOG_PHOTOS_SQL = 'DELETE FROM wear_log_photos WHERE wear_log_id = ?';

const INSERT_WEAR_LOG_PHOTO_SQL = `
  INSERT INTO wear_log_photos (
    id,
    wear_log_id,
    local_uri,
    sort_order
  )
  VALUES (?, ?, ?, ?)
`;

const SELECT_WEAR_LOG_BY_ID_SQL = `
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
  WHERE id = ?
`;

const BASE_SELECT_WEAR_LOGS_SQL = `
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
`;

const SELECT_WEAR_LOG_PHOTOS_SQL = `
  SELECT local_uri
  FROM wear_log_photos
  WHERE wear_log_id = ?
  ORDER BY sort_order ASC
`;

const SELECT_OUTFIT_SNAPSHOT_SQL = `
  SELECT
    outfits.title,
    COALESCE(items.clothing_id, '') AS clothing_id
  FROM outfit_templates outfits
  LEFT JOIN outfit_items items ON items.outfit_id = outfits.id
  WHERE outfits.id = ?
  ORDER BY items.sort_order ASC
`;

const SELECT_WEAR_LOG_DATES_FOR_MONTH_SQL = `
  SELECT DISTINCT worn_date
  FROM wear_logs
  WHERE worn_date >= ? AND worn_date < ?
  ORDER BY worn_date ASC
`;

interface OutfitSnapshot {
  title: string;
  clothingItemIds: string[];
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

export interface CreateWearLogInput {
  outfitTemplateId: string;
  wornDate: string;
  photoUris?: string[];
  placeText?: string;
  note?: string;
}

export interface UpdateWearLogInput {
  id: string;
  outfitTemplateId: string;
  wornDate: string;
  photoUris?: string[];
  placeText?: string;
  note?: string;
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

function encodeClothingItemIdsSnapshot(clothingItemIds: string[]): string {
  return JSON.stringify(clothingItemIds);
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

function parseMonthRange(month: string): string[] | undefined {
  const normalized = month.trim();
  const match = /^(\d{4})-(\d{2})$/.exec(normalized);
  if (match === null) {
    return undefined;
  }

  const year = Number(match[1]);
  const monthNumber = Number(match[2]);
  if (monthNumber < 1 || monthNumber > 12) {
    return undefined;
  }

  const start = `${match[1]}-${match[2]}-01`;
  const nextYear = monthNumber === 12 ? year + 1 : year;
  const nextMonth = monthNumber === 12 ? 1 : monthNumber + 1;
  const end = `${nextYear}-${`${nextMonth}`.padStart(2, '0')}-01`;

  return [start, end];
}

export class WearLogRepository {
  private readonly database: MigrationDatabase;
  private readonly searchRepository: SearchRepository;

  constructor(database: MigrationDatabase, searchIndexMode: SearchIndexMode) {
    this.database = database;
    this.searchRepository = new SearchRepository(database, searchIndexMode);
  }

  async createWearLog(input: CreateWearLogInput): Promise<WearLog> {
    return this.database.transaction(async () => {
      const now = toIsoDateTime(new Date());
      const snapshot = await this.requireOutfitSnapshot(input.outfitTemplateId);
      const wearLog: WearLog = {
        id: createId('wear_log'),
        outfitTemplateId: input.outfitTemplateId,
        outfitTitleSnapshot: snapshot.title,
        clothingItemIdsSnapshot: snapshot.clothingItemIds,
        wornDate: input.wornDate,
        photoUris: normalizePhotoUris(input.photoUris),
        placeText: toSqlNullableText(input.placeText) ?? undefined,
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: now,
        updatedAt: now
      };

      await this.database.executeSql(INSERT_WEAR_LOG_SQL, this.wearLogBindArgs(wearLog, input.outfitTemplateId));
      await this.replacePhotoRows(wearLog.id, wearLog.photoUris);
      await this.searchRepository.upsertDocumentInTransaction(buildWearLogSearchDocument(wearLog));

      return wearLog;
    });
  }

  async updateWearLog(input: UpdateWearLogInput): Promise<WearLog> {
    return this.database.transaction(async () => {
      const existing = await this.getWearLogByIdInTransaction(input.id);
      if (existing === undefined) {
        throw new Error(`Wear log not found: ${input.id}`);
      }

      const snapshot = await this.requireOutfitSnapshot(input.outfitTemplateId);
      const wearLog: WearLog = {
        id: input.id,
        outfitTemplateId: input.outfitTemplateId,
        outfitTitleSnapshot: snapshot.title,
        clothingItemIdsSnapshot: snapshot.clothingItemIds,
        wornDate: input.wornDate,
        photoUris: normalizePhotoUris(input.photoUris),
        placeText: toSqlNullableText(input.placeText) ?? undefined,
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: existing.createdAt,
        updatedAt: toIsoDateTime(new Date())
      };

      await this.database.executeSql(UPDATE_WEAR_LOG_SQL, [
        input.outfitTemplateId,
        wearLog.outfitTitleSnapshot,
        encodeClothingItemIdsSnapshot(wearLog.clothingItemIdsSnapshot),
        wearLog.wornDate,
        wearLog.placeText ?? null,
        wearLog.note ?? null,
        wearLog.updatedAt,
        wearLog.id
      ]);

      await this.replacePhotoRows(wearLog.id, wearLog.photoUris);
      await this.searchRepository.upsertDocumentInTransaction(buildWearLogSearchDocument(wearLog));

      return wearLog;
    });
  }

  async deleteWearLog(id: string): Promise<void> {
    await this.database.transaction(async () => {
      await this.database.executeSql(DELETE_WEAR_LOG_PHOTOS_SQL, [id]);
      await this.database.executeSql(DELETE_WEAR_LOG_SQL, [id]);
      await this.searchRepository.deleteDocumentInTransaction(SearchEntityType.WearLog, id);
    });
  }

  async getWearLogById(id: string): Promise<WearLog | undefined> {
    return this.getWearLogByIdInTransaction(id);
  }

  async listWearLogsByDate(wornDate: string): Promise<WearLog[]> {
    const rows = await this.readWearLogRows(
      `${BASE_SELECT_WEAR_LOGS_SQL} WHERE worn_date = ? ORDER BY updated_at DESC`,
      [wornDate]
    );
    return this.hydrateWearLogs(rows);
  }

  async listWearLogDatesForMonth(month: string): Promise<string[]> {
    const range = parseMonthRange(month);
    if (range === undefined) {
      return [];
    }

    const resultSet = await this.database.querySql(SELECT_WEAR_LOG_DATES_FOR_MONTH_SQL, range);
    const dates: string[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        dates.push(resultSet.getString('worn_date'));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return dates;
  }

  private async getWearLogByIdInTransaction(id: string): Promise<WearLog | undefined> {
    const rows = await this.readWearLogRows(SELECT_WEAR_LOG_BY_ID_SQL, [id]);
    if (rows.length === 0) {
      return undefined;
    }

    const wearLogs = await this.hydrateWearLogs(rows);
    return wearLogs[0];
  }

  private wearLogBindArgs(wearLog: WearLog, outfitTemplateId: string): MigrationSqlValue[] {
    return [
      wearLog.id,
      outfitTemplateId,
      wearLog.outfitTitleSnapshot,
      encodeClothingItemIdsSnapshot(wearLog.clothingItemIdsSnapshot),
      wearLog.wornDate,
      wearLog.placeText ?? null,
      wearLog.note ?? null,
      wearLog.createdAt,
      wearLog.updatedAt
    ];
  }

  private async replacePhotoRows(wearLogId: string, photoUris: string[]): Promise<void> {
    await this.database.executeSql(DELETE_WEAR_LOG_PHOTOS_SQL, [wearLogId]);

    for (let index = 0; index < photoUris.length; index += 1) {
      await this.database.executeSql(INSERT_WEAR_LOG_PHOTO_SQL, [
        createId('wear_log_photo'),
        wearLogId,
        photoUris[index],
        index
      ]);
    }
  }

  private async requireOutfitSnapshot(outfitId: string): Promise<OutfitSnapshot> {
    const resultSet = await this.database.querySql(SELECT_OUTFIT_SNAPSHOT_SQL, [outfitId]);
    const clothingItemIds: string[] = [];
    let title: string | undefined;

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        title = resultSet.getString('title');
        const clothingItemId = resultSet.getString('clothing_id');
        if (clothingItemId.length > 0) {
          clothingItemIds.push(clothingItemId);
        }
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    if (title === undefined) {
      throw new Error(`Outfit not found: ${outfitId}`);
    }

    return {
      title,
      clothingItemIds
    };
  }

  private async readWearLogRows(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<WearLogRow[]> {
    const resultSet = await this.database.querySql(sql, bindArgs);
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

    return rows;
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
        photoUris: await this.readPhotoUris(row.id),
        placeText: row.placeText,
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt
      });
    }

    return wearLogs;
  }

  private async readPhotoUris(wearLogId: string): Promise<string[]> {
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
