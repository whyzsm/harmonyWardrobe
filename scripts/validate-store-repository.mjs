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
  'ORDER BY visit_date DESC, updated_at DESC',
  'buildStoreSearchDocument',
  'buildStoreVisitSearchDocument',
  'this.database.transaction'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

if (!/createStoreVisitWithOptionalStore[\s\S]*?this\.database\.transaction[\s\S]*?findStoreByNameInTransaction[\s\S]*?createStoreInTransaction[\s\S]*?createStoreVisitInTransaction/.test(text)) {
  throw new Error(`${file} must create optional store and store visit in one transaction`);
}

for (const forbidden of ['PhotoStorage', ': any', ': unknown']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

console.log('PASS');
