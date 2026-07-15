import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { DeleteCleanupService } from './DeleteCleanupService';
import { SearchRepository } from './SearchRepository';
import { SearchIndexMode } from '../searchIndex/SearchCapability';
import { PhotoStorage } from '../../media/PhotoStorage';
import { buildStoreSearchDocument, buildStoreVisitSearchDocument } from '../../domain/search/SearchDocumentBuilder';
import { SearchEntityType } from '../../domain/search/SearchModels';
import { Store, StoreVisit, StoreVisitStatus } from '../../domain/store/StoreModels';
import { toIsoDate, toIsoDateTime } from '../../utils/date';
import { createId } from '../../utils/id';
import { normalizeSearchText } from '../../utils/text';

const INSERT_STORE_SQL = `
  INSERT INTO stores (
    id,
    name,
    district_or_address,
    note,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?)
`;

const UPDATE_STORE_SQL = `
  UPDATE stores
  SET
    name = ?,
    district_or_address = ?,
    note = ?,
    updated_at = ?
  WHERE id = ?
`;

const DELETE_STORE_SQL = 'DELETE FROM stores WHERE id = ?';
const DETACH_STORE_VISITS_SQL = 'UPDATE store_visits SET store_id = NULL WHERE store_id = ?';

const INSERT_STORE_PHOTO_SQL = `
  INSERT INTO store_photos (
    id,
    store_id,
    local_uri,
    sort_order
  )
  VALUES (?, ?, ?, ?)
`;

const DELETE_STORE_PHOTOS_SQL = 'DELETE FROM store_photos WHERE store_id = ?';

const SELECT_STORE_BY_ID_SQL = `
  SELECT
    id,
    name,
    COALESCE(district_or_address, '') AS district_or_address,
    COALESCE(note, '') AS note,
    created_at,
    updated_at
  FROM stores
  WHERE id = ?
`;

const BASE_LIST_STORES_SQL = `
  SELECT
    id,
    name,
    COALESCE(district_or_address, '') AS district_or_address,
    COALESCE(note, '') AS note,
    created_at,
    updated_at
  FROM stores
`;

const SELECT_STORE_PHOTOS_SQL = `
  SELECT local_uri
  FROM store_photos
  WHERE store_id = ?
  ORDER BY sort_order ASC
`;

const INSERT_STORE_VISIT_SQL = `
  INSERT INTO store_visits (
    id,
    store_id,
    store_name_snapshot,
    district_or_address,
    visit_date,
    status,
    focus_tags,
    note,
    created_at,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`;

const UPDATE_STORE_VISIT_SQL = `
  UPDATE store_visits
  SET
    store_id = ?,
    store_name_snapshot = ?,
    district_or_address = ?,
    visit_date = ?,
    status = ?,
    focus_tags = ?,
    note = ?,
    updated_at = ?
  WHERE id = ?
`;

const DELETE_STORE_VISIT_SQL = 'DELETE FROM store_visits WHERE id = ?';
const DELETE_STORE_VISIT_PHOTOS_SQL = 'DELETE FROM store_visit_photos WHERE store_visit_id = ?';

const INSERT_STORE_VISIT_PHOTO_SQL = `
  INSERT INTO store_visit_photos (
    id,
    store_visit_id,
    local_uri,
    sort_order
  )
  VALUES (?, ?, ?, ?)
`;

const SELECT_STORE_VISIT_BY_ID_SQL = `
  SELECT
    id,
    COALESCE(store_id, '') AS store_id,
    store_name_snapshot,
    COALESCE(district_or_address, '') AS district_or_address,
    visit_date,
    status,
    COALESCE(focus_tags, '') AS focus_tags,
    COALESCE(note, '') AS note,
    created_at,
    updated_at
  FROM store_visits
  WHERE id = ?
`;

const BASE_LIST_STORE_VISITS_SQL = `
  SELECT
    id,
    COALESCE(store_id, '') AS store_id,
    store_name_snapshot,
    COALESCE(district_or_address, '') AS district_or_address,
    visit_date,
    status,
    COALESCE(focus_tags, '') AS focus_tags,
    COALESCE(note, '') AS note,
    created_at,
    updated_at
  FROM store_visits
`;

const SELECT_STORE_VISIT_PHOTOS_SQL = `
  SELECT local_uri
  FROM store_visit_photos
  WHERE store_visit_id = ?
  ORDER BY sort_order ASC
`;

interface StoreRow {
  id: string;
  name: string;
  districtOrAddress?: string;
  note?: string;
  createdAt: string;
  updatedAt: string;
}

interface StoreVisitRow {
  id: string;
  storeId?: string;
  storeNameSnapshot: string;
  districtOrAddress?: string;
  visitDate: string;
  status: StoreVisitStatus;
  focusTags: string[];
  note?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreateStoreInput {
  name: string;
  districtOrAddress?: string;
  photoUris?: string[];
  note?: string;
}

export interface UpdateStoreInput {
  id: string;
  name: string;
  districtOrAddress?: string;
  photoUris?: string[];
  note?: string;
}

export interface CreateStoreVisitInput {
  storeId?: string;
  storeNameSnapshot: string;
  districtOrAddress?: string;
  visitDate?: string;
  photoUris?: string[];
  status?: StoreVisitStatus;
  focusTags?: string[];
  note?: string;
}

export interface CreateStoreVisitWithOptionalStoreInput {
  storeName?: string;
  storeNameSnapshot: string;
  districtOrAddress?: string;
  visitDate?: string;
  photoUris?: string[];
  status?: StoreVisitStatus;
  focusTags?: string[];
  note?: string;
}

export interface UpdateStoreVisitInput {
  id: string;
  storeId?: string;
  storeNameSnapshot: string;
  districtOrAddress?: string;
  visitDate?: string;
  photoUris?: string[];
  status?: StoreVisitStatus;
  focusTags?: string[];
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

function requiredText(value: string, fallback: string): string {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : fallback;
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

function normalizeStoreVisitStatus(status?: StoreVisitStatus): StoreVisitStatus {
  return status ?? StoreVisitStatus.Visited;
}

function normalizeFocusTags(tags?: string[]): string[] {
  if (tags === undefined) {
    return [];
  }

  const normalized: string[] = [];
  for (const tag of tags) {
    const trimmed = tag.trim();
    if (trimmed.length > 0 && !normalized.includes(trimmed)) {
      normalized.push(trimmed);
    }
  }
  return normalized;
}

function encodeFocusTags(tags?: string[]): string {
  return normalizeFocusTags(tags).join('|');
}

function decodeFocusTags(value: string): string[] {
  return normalizeFocusTags(value.split('|'));
}

function normalizeVisitDate(value?: string): string {
  const trimmed = value?.trim() ?? '';
  return trimmed.length > 0 ? trimmed : toIsoDate(new Date());
}

export class StoreRepository {
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

  async createStore(input: CreateStoreInput): Promise<Store> {
    return this.database.transaction(async () => {
      return this.createStoreInTransaction(input);
    });
  }

  async updateStore(input: UpdateStoreInput): Promise<Store> {
    return this.database.transaction(async () => {
      const existing = await this.getStoreByIdInTransaction(input.id);
      if (existing === undefined) {
        throw new Error(`Store not found: ${input.id}`);
      }

      const store: Store = {
        id: input.id,
        name: requiredText(input.name, existing.name),
        districtOrAddress: toSqlNullableText(input.districtOrAddress) ?? undefined,
        photoUris: normalizePhotoUris(input.photoUris),
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: existing.createdAt,
        updatedAt: toIsoDateTime(new Date())
      };

      await this.database.executeSql(UPDATE_STORE_SQL, [
        store.name,
        store.districtOrAddress ?? null,
        store.note ?? null,
        store.updatedAt,
        store.id
      ]);
      await this.replaceStorePhotoRows(store.id, store.photoUris);
      await this.searchRepository.upsertDocumentInTransaction(buildStoreSearchDocument(store));
      return store;
    });
  }

  async listStores(): Promise<Store[]> {
    const rows = await this.readStoreRows(`${BASE_LIST_STORES_SQL} ORDER BY updated_at DESC`);
    return this.hydrateStores(rows);
  }

  async getStoreById(id: string): Promise<Store | undefined> {
    return this.getStoreByIdInTransaction(id);
  }

  async deleteStore(id: string): Promise<void> {
    await this.database.transaction(async () => {
      await this.deleteCleanupService.deleteObjectPhotos('store_photos', 'store_id', id);
      await this.database.executeSql(DETACH_STORE_VISITS_SQL, [id]);
      await this.database.executeSql(DELETE_STORE_SQL, [id]);
      await this.searchRepository.deleteDocumentInTransaction(SearchEntityType.Store, id);
    });
  }

  async createStoreVisit(input: CreateStoreVisitInput): Promise<StoreVisit> {
    return this.database.transaction(async () => {
      return this.createStoreVisitInTransaction(input);
    });
  }

  async createStoreVisitWithOptionalStore(input: CreateStoreVisitWithOptionalStoreInput): Promise<StoreVisit> {
    return this.database.transaction(async () => {
      const normalizedStoreName = toSqlNullableText(input.storeName);
      let storeId: string | undefined = undefined;

      if (normalizedStoreName !== null) {
        const existingStore = await this.findStoreByNameInTransaction(normalizedStoreName);
        if (existingStore !== undefined) {
          storeId = existingStore.id;
        } else {
          const store = await this.createStoreInTransaction({
            name: normalizedStoreName,
            districtOrAddress: input.districtOrAddress,
            photoUris: normalizePhotoUris(input.photoUris).slice(0, 1),
            note: input.note
          });
          storeId = store.id;
        }
      }

      return this.createStoreVisitInTransaction({
        storeId,
        storeNameSnapshot: input.storeNameSnapshot,
        districtOrAddress: input.districtOrAddress,
        visitDate: input.visitDate,
        photoUris: input.photoUris,
        status: input.status,
        focusTags: input.focusTags,
        note: input.note
      });
    });
  }

  async updateStoreVisit(input: UpdateStoreVisitInput): Promise<StoreVisit> {
    return this.database.transaction(async () => {
      const existing = await this.getStoreVisitByIdInTransaction(input.id);
      if (existing === undefined) {
        throw new Error(`Store visit not found: ${input.id}`);
      }

      const visit: StoreVisit = {
        id: input.id,
        storeId: toSqlNullableText(input.storeId) ?? undefined,
        storeNameSnapshot: requiredText(input.storeNameSnapshot, existing.storeNameSnapshot),
        districtOrAddress: toSqlNullableText(input.districtOrAddress) ?? undefined,
        visitDate: normalizeVisitDate(input.visitDate),
        photoUris: normalizePhotoUris(input.photoUris),
        status: normalizeStoreVisitStatus(input.status ?? existing.status),
        focusTags: normalizeFocusTags(input.focusTags ?? existing.focusTags),
        note: toSqlNullableText(input.note) ?? undefined,
        createdAt: existing.createdAt,
        updatedAt: toIsoDateTime(new Date())
      };

      await this.database.executeSql(UPDATE_STORE_VISIT_SQL, [
        visit.storeId ?? null,
        visit.storeNameSnapshot,
        visit.districtOrAddress ?? null,
        visit.visitDate,
        visit.status ?? StoreVisitStatus.Visited,
        encodeFocusTags(visit.focusTags),
        visit.note ?? null,
        visit.updatedAt,
        visit.id
      ]);
      await this.replaceStoreVisitPhotoRows(visit.id, visit.photoUris);
      await this.searchRepository.upsertDocumentInTransaction(buildStoreVisitSearchDocument(visit));
      return visit;
    });
  }

  async listStoreVisits(): Promise<StoreVisit[]> {
    const rows = await this.readStoreVisitRows(`${BASE_LIST_STORE_VISITS_SQL} ORDER BY visit_date DESC, updated_at DESC`);
    return this.hydrateStoreVisits(rows);
  }

  async getStoreVisitById(id: string): Promise<StoreVisit | undefined> {
    return this.getStoreVisitByIdInTransaction(id);
  }

  async deleteStoreVisit(id: string): Promise<void> {
    await this.database.transaction(async () => {
      await this.deleteCleanupService.deleteObjectPhotos('store_visit_photos', 'store_visit_id', id);
      await this.database.executeSql(DELETE_STORE_VISIT_SQL, [id]);
      await this.searchRepository.deleteDocumentInTransaction(SearchEntityType.StoreVisit, id);
    });
  }

  async findStoreByName(name: string): Promise<Store | undefined> {
    return this.findStoreByNameInTransaction(name);
  }

  private createDeleteCleanupService(): DeleteCleanupService {
    return new DeleteCleanupService(this.database, this.searchRepository, this.photoStorage);
  }

  private async createStoreInTransaction(input: CreateStoreInput): Promise<Store> {
    const now = toIsoDateTime(new Date());
    const store: Store = {
      id: createId('store'),
      name: requiredText(input.name, '未命名店铺'),
      districtOrAddress: toSqlNullableText(input.districtOrAddress) ?? undefined,
      photoUris: normalizePhotoUris(input.photoUris),
      note: toSqlNullableText(input.note) ?? undefined,
      createdAt: now,
      updatedAt: now
    };

    await this.database.executeSql(INSERT_STORE_SQL, this.storeBindArgs(store));
    await this.replaceStorePhotoRows(store.id, store.photoUris);
    await this.searchRepository.upsertDocumentInTransaction(buildStoreSearchDocument(store));
    return store;
  }

  private async createStoreVisitInTransaction(input: CreateStoreVisitInput): Promise<StoreVisit> {
    const now = toIsoDateTime(new Date());
    const visit: StoreVisit = {
      id: createId('store_visit'),
      storeId: toSqlNullableText(input.storeId) ?? undefined,
      storeNameSnapshot: requiredText(input.storeNameSnapshot, '未命名店铺'),
      districtOrAddress: toSqlNullableText(input.districtOrAddress) ?? undefined,
      visitDate: normalizeVisitDate(input.visitDate),
      photoUris: normalizePhotoUris(input.photoUris),
      status: normalizeStoreVisitStatus(input.status),
      focusTags: normalizeFocusTags(input.focusTags),
      note: toSqlNullableText(input.note) ?? undefined,
      createdAt: now,
      updatedAt: now
    };

    await this.database.executeSql(INSERT_STORE_VISIT_SQL, this.storeVisitBindArgs(visit));
    await this.replaceStoreVisitPhotoRows(visit.id, visit.photoUris);
    await this.searchRepository.upsertDocumentInTransaction(buildStoreVisitSearchDocument(visit));
    return visit;
  }

  private async findStoreByNameInTransaction(name: string): Promise<Store | undefined> {
    const normalized = normalizeSearchText(name);
    if (normalized.length === 0) {
      return undefined;
    }

    const rows = await this.readStoreRows(BASE_LIST_STORES_SQL);
    const stores = await this.hydrateStores(rows);
    for (const store of stores) {
      if (normalizeSearchText(store.name) === normalized) {
        return store;
      }
    }

    return undefined;
  }

  private async getStoreByIdInTransaction(id: string): Promise<Store | undefined> {
    const rows = await this.readStoreRows(SELECT_STORE_BY_ID_SQL, [id]);
    const stores = await this.hydrateStores(rows);
    return stores[0];
  }

  private async getStoreVisitByIdInTransaction(id: string): Promise<StoreVisit | undefined> {
    const rows = await this.readStoreVisitRows(SELECT_STORE_VISIT_BY_ID_SQL, [id]);
    const visits = await this.hydrateStoreVisits(rows);
    return visits[0];
  }

  private storeBindArgs(store: Store): MigrationSqlValue[] {
    return [
      store.id,
      store.name,
      store.districtOrAddress ?? null,
      store.note ?? null,
      store.createdAt,
      store.updatedAt
    ];
  }

  private storeVisitBindArgs(visit: StoreVisit): MigrationSqlValue[] {
    return [
      visit.id,
      visit.storeId ?? null,
      visit.storeNameSnapshot,
      visit.districtOrAddress ?? null,
      visit.visitDate,
      visit.status ?? StoreVisitStatus.Visited,
      encodeFocusTags(visit.focusTags),
      visit.note ?? null,
      visit.createdAt,
      visit.updatedAt
    ];
  }

  private async replaceStorePhotoRows(storeId: string, photoUris: string[]): Promise<void> {
    const existingPhotoUris = await this.deleteCleanupService.readObjectPhotoUris(
      'store_photos',
      'store_id',
      storeId
    );
    await this.database.executeSql(DELETE_STORE_PHOTOS_SQL, [storeId]);
    await this.deleteCleanupService.cleanupReplacedPhotos(
      'store_photos',
      'store_id',
      storeId,
      existingPhotoUris,
      photoUris
    );
    for (let index = 0; index < photoUris.length; index += 1) {
      await this.database.executeSql(INSERT_STORE_PHOTO_SQL, [createId('store_photo'), storeId, photoUris[index], index]);
    }
  }

  private async replaceStoreVisitPhotoRows(visitId: string, photoUris: string[]): Promise<void> {
    const existingPhotoUris = await this.deleteCleanupService.readObjectPhotoUris(
      'store_visit_photos',
      'store_visit_id',
      visitId
    );
    await this.database.executeSql(DELETE_STORE_VISIT_PHOTOS_SQL, [visitId]);
    await this.deleteCleanupService.cleanupReplacedPhotos(
      'store_visit_photos',
      'store_visit_id',
      visitId,
      existingPhotoUris,
      photoUris
    );
    for (let index = 0; index < photoUris.length; index += 1) {
      await this.database.executeSql(INSERT_STORE_VISIT_PHOTO_SQL, [createId('store_visit_photo'), visitId, photoUris[index], index]);
    }
  }

  private async hydrateStores(rows: StoreRow[]): Promise<Store[]> {
    const stores: Store[] = [];
    for (const row of rows) {
      stores.push({
        id: row.id,
        name: row.name,
        districtOrAddress: row.districtOrAddress,
        photoUris: await this.readPhotoUris(SELECT_STORE_PHOTOS_SQL, row.id),
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt
      });
    }
    return stores;
  }

  private async hydrateStoreVisits(rows: StoreVisitRow[]): Promise<StoreVisit[]> {
    const visits: StoreVisit[] = [];
    for (const row of rows) {
      visits.push({
        id: row.id,
        storeId: row.storeId,
        storeNameSnapshot: row.storeNameSnapshot,
        districtOrAddress: row.districtOrAddress,
        visitDate: row.visitDate,
        photoUris: await this.readPhotoUris(SELECT_STORE_VISIT_PHOTOS_SQL, row.id),
        status: row.status,
        focusTags: row.focusTags,
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt
      });
    }
    return visits;
  }

  private async readPhotoUris(sql: string, id: string): Promise<string[]> {
    const resultSet = await this.database.querySql(sql, [id]);
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

  private async readStoreRows(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<StoreRow[]> {
    const resultSet = await this.database.querySql(sql, bindArgs);
    const rows: StoreRow[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        rows.push({
          id: resultSet.getString('id'),
          name: resultSet.getString('name'),
          districtOrAddress: optionalString(resultSet.getString('district_or_address')),
          note: optionalString(resultSet.getString('note')),
          createdAt: resultSet.getString('created_at'),
          updatedAt: resultSet.getString('updated_at')
        });
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return rows;
  }

  private async readStoreVisitRows(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<StoreVisitRow[]> {
    const resultSet = await this.database.querySql(sql, bindArgs);
    const rows: StoreVisitRow[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        rows.push({
          id: resultSet.getString('id'),
          storeId: optionalString(resultSet.getString('store_id')),
          storeNameSnapshot: resultSet.getString('store_name_snapshot'),
          districtOrAddress: optionalString(resultSet.getString('district_or_address')),
          visitDate: resultSet.getString('visit_date'),
          status: normalizeStoreVisitStatus(resultSet.getString('status') as StoreVisitStatus),
          focusTags: decodeFocusTags(resultSet.getString('focus_tags')),
          note: optionalString(resultSet.getString('note')),
          createdAt: resultSet.getString('created_at'),
          updatedAt: resultSet.getString('updated_at')
        });
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return rows;
  }
}
