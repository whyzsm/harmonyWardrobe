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

if (!/const\s+SELECT_STORE_BY_NAME_SQL\s*=\s*`[\s\S]*?WHERE\s+normalized_name\s*=\s*\?[\s\S]*?LIMIT\s+1[\s\S]*?`/.test(text)) {
  throw new Error(`${file} must define a parameterized indexed normalized-name query`);
}

const findStoreByNameBody = text.match(/private\s+async\s+findStoreByNameInTransaction[\s\S]*?\n\s*}\n\n\s*private\s+async\s+getStoreByIdInTransaction/);
if (!findStoreByNameBody) {
  throw new Error(`${file} missing findStoreByNameInTransaction body`);
}

if (findStoreByNameBody[0].includes('BASE_LIST_STORES_SQL') || /for\s*\(\s*const\s+store\s+of\s+stores/.test(findStoreByNameBody[0])) {
  throw new Error(`${file} findStoreByNameInTransaction must not load and filter all stores in JavaScript`);
}

if (!/readStoreRows\(SELECT_STORE_BY_NAME_SQL\s*,\s*\[\s*normalized\s*\]\)/.test(findStoreByNameBody[0])) {
  throw new Error(`${file} findStoreByNameInTransaction must bind the normalized name as a SQL parameter`);
}

if (!/WHERE normalized_name = \?/.test(text)) {
  throw new Error(`${file} findStoreByNameInTransaction must query the indexed normalized_name column`);
}

if (!/normalized_name/.test(text) || !/normalizeSearchText\(store\.name\)/.test(text)) {
  throw new Error(`${file} stores must persist normalized_name from normalizeSearchText(store.name)`);
}

if (!/hydrateStores\(rows\)/.test(findStoreByNameBody[0])) {
  throw new Error(`${file} findStoreByNameInTransaction must hydrate the matched store`);
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
