import { MigrationDatabase, MigrationResultSet } from '../migrations/Migration';
import { ClothingRepository } from '../repositories/ClothingRepository';
import { OutfitRepository } from '../repositories/OutfitRepository';
import { SearchRepository } from '../repositories/SearchRepository';
import { StoreRepository } from '../repositories/StoreRepository';
import { WearLogRepository } from '../repositories/WearLogRepository';
import { WishlistRepository } from '../repositories/WishlistRepository';
import {
  buildClothingSearchDocument,
  buildOutfitSearchDocument,
  buildStoreSearchDocument,
  buildStoreVisitSearchDocument,
  buildWearLogSearchDocument,
  buildWishlistSearchDocument,
  SearchDocument
} from '../../domain/search/SearchDocumentBuilder';
import { ClothingItem } from '../../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../../domain/outfit/OutfitModels';
import { SearchIndexMode } from './SearchCapability';

// Bump when the indexed document shape, tokenizer, or index tables change.
const SEARCH_INDEX_STATE_VERSION = 1;
const SEARCH_INDEX_STATE_ID = 1;

const CREATE_SEARCH_INDEX_STATE_SQL = `
  CREATE TABLE IF NOT EXISTS search_index_state (
    id INTEGER PRIMARY KEY NOT NULL CHECK (id = 1),
    schema_version INTEGER NOT NULL,
    database_schema_version INTEGER NOT NULL,
    mode TEXT NOT NULL
  )
`;

const SELECT_SEARCH_INDEX_STATE_SQL = `
  SELECT schema_version, database_schema_version, mode
  FROM search_index_state
  WHERE id = ?
`;

const UPSERT_SEARCH_INDEX_STATE_SQL = `
  INSERT OR REPLACE INTO search_index_state (id, schema_version, database_schema_version, mode)
  VALUES (?, ?, ?, ?)
`;

const CURRENT_DATABASE_SCHEMA_VERSION_SQL = `
  SELECT COALESCE(MAX(version), 0) AS schema_version
  FROM schema_migrations
`;

const EXPECTED_DOCUMENT_COUNT_SQL = `
  SELECT
    (SELECT COUNT(*) FROM clothing_items) +
    (SELECT COUNT(*) FROM outfit_templates) +
    (SELECT COUNT(*) FROM wear_logs) +
    (SELECT COUNT(*) FROM wishlist_items) +
    (SELECT COUNT(*) FROM stores) +
    (SELECT COUNT(*) FROM store_visits) AS expected_count
`;

const SEARCH_DOCUMENT_COUNT_SQL = `
  SELECT COUNT(*) AS document_count
  FROM search_index_documents
`;

const FTS_DOCUMENT_COUNT_SQL = `
  SELECT COUNT(*) AS document_count
  FROM search_index_fts
`;

const SEARCH_DOCUMENTS_WITH_NGRAMS_COUNT_SQL = `
  SELECT COUNT(*) AS document_count
  FROM search_index_documents
  WHERE LENGTH(TRIM(ngrams)) > 0
`;

const FALLBACK_NGRAM_DOCUMENT_COUNT_SQL = `
  SELECT COUNT(DISTINCT ngrams.document_id) AS document_count
  FROM search_index_ngrams AS ngrams
  INNER JOIN search_index_documents AS documents
    ON documents.id = ngrams.document_id
  WHERE LENGTH(TRIM(documents.ngrams)) > 0
`;

interface SearchIndexState {
  schemaVersion: number;
  databaseSchemaVersion: number;
  mode: SearchIndexMode;
}

export interface SearchIndexBootstrapDependencies {
  database: MigrationDatabase;
  searchIndexMode: SearchIndexMode;
  searchRepository: SearchRepository;
  clothingRepository: ClothingRepository;
  outfitRepository: OutfitRepository;
  wearLogRepository: WearLogRepository;
  wishlistRepository: WishlistRepository;
  storeRepository: StoreRepository;
}

export class SearchIndexBootstrap {
  static async ensureReady(dependencies: SearchIndexBootstrapDependencies): Promise<void> {
    await ensureSearchIndexStateTable(dependencies.database);
    const databaseSchemaVersion = await readNumber(
      dependencies.database,
      CURRENT_DATABASE_SCHEMA_VERSION_SQL,
      'schema_version'
    );

    if (await shouldRebuild(dependencies.database, dependencies.searchIndexMode, databaseSchemaVersion)) {
      await SearchIndexBootstrap.rebuild(dependencies);
      await recordReadyState(dependencies.database, dependencies.searchIndexMode, databaseSchemaVersion);
    }
  }

  static async rebuild(dependencies: SearchIndexBootstrapDependencies): Promise<void> {
    const documents = await buildDocuments(dependencies);
    await dependencies.searchRepository.rebuildSearchIndex(documents);
  }

  static async refresh(dependencies: SearchIndexBootstrapDependencies): Promise<void> {
    await SearchIndexBootstrap.ensureReady(dependencies);
    await SearchIndexBootstrap.rebuild(dependencies);
  }
}

async function ensureSearchIndexStateTable(database: MigrationDatabase): Promise<void> {
  await database.executeSql(CREATE_SEARCH_INDEX_STATE_SQL);
}

async function shouldRebuild(
  database: MigrationDatabase,
  searchIndexMode: SearchIndexMode,
  databaseSchemaVersion: number
): Promise<boolean> {
  const state = await readSearchIndexState(database);
  if (state === undefined) {
    return true;
  }

  if (
    state.schemaVersion !== SEARCH_INDEX_STATE_VERSION ||
    state.databaseSchemaVersion !== databaseSchemaVersion ||
    state.mode !== searchIndexMode
  ) {
    return true;
  }

  const expectedDocumentCount = await readNumber(database, EXPECTED_DOCUMENT_COUNT_SQL, 'expected_count');
  const documentCount = await readNumber(database, SEARCH_DOCUMENT_COUNT_SQL, 'document_count');
  if (documentCount !== expectedDocumentCount) {
    return true;
  }

  if (searchIndexMode === 'fts5') {
    const ftsDocumentCount = await readNumber(database, FTS_DOCUMENT_COUNT_SQL, 'document_count');
    return ftsDocumentCount !== documentCount;
  }

  const documentsWithNgramsCount = await readNumber(
    database,
    SEARCH_DOCUMENTS_WITH_NGRAMS_COUNT_SQL,
    'document_count'
  );
  const fallbackNgramDocumentCount = await readNumber(
    database,
    FALLBACK_NGRAM_DOCUMENT_COUNT_SQL,
    'document_count'
  );
  return fallbackNgramDocumentCount !== documentsWithNgramsCount;
}

async function readSearchIndexState(database: MigrationDatabase): Promise<SearchIndexState | undefined> {
  const resultSet = await database.querySql(SELECT_SEARCH_INDEX_STATE_SQL, [SEARCH_INDEX_STATE_ID]);

  try {
    if (!resultSet.goToFirstRow()) {
      return undefined;
    }

    const mode = resultSet.getString('mode');
    if (mode !== 'fts5' && mode !== 'fallback') {
      return undefined;
    }

    return {
      schemaVersion: resultSet.getNumber('schema_version'),
      databaseSchemaVersion: resultSet.getNumber('database_schema_version'),
      mode: mode as SearchIndexMode
    };
  } finally {
    resultSet.close();
  }
}

async function readNumber(database: MigrationDatabase, sql: string, columnName: string): Promise<number> {
  const resultSet = await database.querySql(sql);

  try {
    if (!resultSet.goToFirstRow()) {
      return 0;
    }

    return resultSet.getNumber(columnName);
  } finally {
    resultSet.close();
  }
}

async function recordReadyState(
  database: MigrationDatabase,
  searchIndexMode: SearchIndexMode,
  databaseSchemaVersion: number
): Promise<void> {
  await database.transaction(async () => {
    await database.executeSql(UPSERT_SEARCH_INDEX_STATE_SQL, [
      SEARCH_INDEX_STATE_ID,
      SEARCH_INDEX_STATE_VERSION,
      databaseSchemaVersion,
      searchIndexMode
    ]);
  });
}

async function buildDocuments(dependencies: SearchIndexBootstrapDependencies): Promise<SearchDocument[]> {
  const clothingItems = await dependencies.clothingRepository.listClothing();
  const outfits = await dependencies.outfitRepository.listOutfits();
  const wearLogs = await dependencies.wearLogRepository.listWearLogs();
  const wishlistItems = await dependencies.wishlistRepository.listWishlistItems();
  const stores = await dependencies.storeRepository.listStores();
  const storeVisits = await dependencies.storeRepository.listStoreVisits();
  const clothingNameById = buildClothingNameById(clothingItems);
  const documents: SearchDocument[] = [];

  for (const item of clothingItems) {
    documents.push(buildClothingSearchDocument(item));
  }

  for (const outfit of outfits) {
    documents.push(buildOutfitSearchDocument(outfit, clothingNamesForOutfit(outfit, clothingNameById)));
  }

  for (const wearLog of wearLogs) {
    documents.push(buildWearLogSearchDocument(wearLog));
  }

  for (const item of wishlistItems) {
    documents.push(buildWishlistSearchDocument(item));
  }

  for (const store of stores) {
    documents.push(buildStoreSearchDocument(store));
  }

  for (const visit of storeVisits) {
    documents.push(buildStoreVisitSearchDocument(visit));
  }

  return documents;
}

function buildClothingNameById(clothingItems: ClothingItem[]): Map<string, string> {
  const clothingNameById = new Map<string, string>();
  for (const item of clothingItems) {
    clothingNameById.set(item.id, item.name);
  }
  return clothingNameById;
}

function clothingNamesForOutfit(outfit: OutfitTemplate, clothingNameById: Map<string, string>): string[] {
  const names: string[] = [];
  for (const itemId of outfit.clothingItemIds) {
    const name = clothingNameById.get(itemId);
    if (name !== undefined) {
      names.push(name);
    }
  }
  return names;
}
