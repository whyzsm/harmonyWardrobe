import fs from 'node:fs';

const file = 'entry/src/main/ets/domain/store/StoreModels.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

function mustInclude(needle) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

for (const needle of [
  'export interface Store',
  'id: string',
  'name: string',
  'districtOrAddress?: string',
  'photoUris: string[]',
  'note?: string',
  'createdAt: string',
  'updatedAt: string',
  'export interface StoreVisit',
  'export enum StoreVisitStatus',
  'storeId?: string',
  'storeNameSnapshot: string',
  'visitDate: string',
  'status?: StoreVisitStatus',
  'focusTags?: string[]'
]) {
  mustInclude(needle);
}

for (const forbidden of [': any', ': unknown', 'ArkUI', 'MigrationDatabase']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

console.log('PASS');
