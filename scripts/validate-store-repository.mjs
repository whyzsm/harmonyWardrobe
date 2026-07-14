import fs from 'node:fs';

const file = 'entry/src/main/ets/data/repositories/StoreRepository.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

for (const needle of [
  'export class StoreRepository',
  'export interface CreateStoreInput',
  'export interface UpdateStoreInput',
  'export interface CreateStoreVisitInput',
  'export interface UpdateStoreVisitInput',
  'createStore',
  'updateStore',
  'listStores',
  'getStoreById',
  'deleteStore',
  'createStoreVisit',
  'createStoreVisitWithOptionalStore',
  'CreateStoreVisitWithOptionalStoreInput',
  'updateStoreVisit',
  'listStoreVisits',
  'getStoreVisitById',
  'deleteStoreVisit',
  'store_photos',
  'store_visit_photos',
  'storeNameSnapshot',
  'StoreVisitStatus',
  'focus_tags',
  'focusTags',
  'ORDER BY visit_date DESC, updated_at DESC',
  'buildStoreSearchDocument',
  'buildStoreVisitSearchDocument',
  'PhotoStorage',
  'DeleteCleanupService',
  'this.database.transaction'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

if (!/createStoreVisitWithOptionalStore[\s\S]*?this\.database\.transaction[\s\S]*?findStoreByNameInTransaction[\s\S]*?createStoreInTransaction[\s\S]*?createStoreVisitInTransaction/.test(text)) {
  throw new Error(`${file} must create optional store and store visit in one transaction`);
}

if (!/constructor\s*\(\s*database:\s*MigrationDatabase\s*,\s*searchIndexMode:\s*SearchIndexMode\s*,\s*photoStorage\?:\s*PhotoStorage\s*\)/.test(text)) {
  throw new Error(`${file} constructor must accept optional PhotoStorage`);
}

if (!/new\s+DeleteCleanupService\s*\([\s\S]*photoStorage\s*\)/.test(text)) {
  throw new Error(`${file} must pass PhotoStorage to DeleteCleanupService`);
}

if (!/deleteDocumentInTransaction\s*\(\s*SearchEntityType\.Store/.test(text)) {
  throw new Error(`${file} deleteStore must remove the Store search document`);
}

if (/photoStorage\.(copy|save|persist|import|write|ensure)/.test(text)) {
  throw new Error(`${file} must not copy or write photo files directly`);
}

for (const forbidden of [': any', ': unknown']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

console.log('PASS');
