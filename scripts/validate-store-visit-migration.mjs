import fs from 'node:fs';

const file = 'entry/src/main/ets/data/migrations/V3StoreVisitSchema.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

for (const needle of [
  'export class V3StoreVisitSchema',
  'export const v3StoreVisitSchema',
  'version: number = 3',
  'stores',
  'store_photos',
  'store_visits',
  'store_visit_photos',
  'user_profile',
  'CREATE TABLE IF NOT EXISTS',
  'CREATE INDEX IF NOT EXISTS idx_store_visits_visit_date',
  'CREATE INDEX IF NOT EXISTS idx_store_visits_store_id',
  'CREATE INDEX IF NOT EXISTS idx_store_photos_store_id',
  'CREATE INDEX IF NOT EXISTS idx_store_visit_photos_store_visit_id'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

if (/DROP\s+TABLE/i.test(text) || /wishlist_items|wishlist_photos/.test(text)) {
  throw new Error(`${file} must not drop or modify old wishlist tables`);
}

console.log('PASS');
