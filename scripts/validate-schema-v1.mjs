import fs from 'node:fs';

const file = 'entry/src/main/ets/data/migrations/V1InitialSchema.ets';
const text = fs.readFileSync(file, 'utf8');
const tables = [
  'clothing_items',
  'clothing_photos',
  'outfit_templates',
  'outfit_photos',
  'outfit_items',
  'wear_logs',
  'wear_log_photos',
  'wishlist_items',
  'wishlist_photos'
];

for (const table of tables) {
  if (!text.includes(`CREATE TABLE`) || !text.includes(table)) {
    console.error(`Missing table ${table}`);
    process.exit(1);
  }
}

const tableMatches = [...text.matchAll(/CREATE TABLE IF NOT EXISTS\s+([a-z_]+)/g)].map((match) => match[1]);
const unexpectedTables = tableMatches.filter((table) => !tables.includes(table));
const missingTables = tables.filter((table) => !tableMatches.includes(table));

if (unexpectedTables.length > 0 || missingTables.length > 0 || tableMatches.length !== tables.length) {
  console.error(`Expected exactly approved business tables. Found: ${tableMatches.join(', ')}`);
  process.exit(1);
}

for (const forbidden of ['CREATE VIRTUAL TABLE', 'search_index_fts', 'fts5', 'ngrams']) {
  if (text.includes(forbidden)) {
    console.error(`V1 schema must not include search schema: ${forbidden}`);
    process.exit(1);
  }
}

if (text.includes('PRAGMA foreign_keys')) {
  console.error('Foreign keys must be enabled when opening the database, not inside the V1 migration transaction.');
  process.exit(1);
}

for (const needle of [
  'outfit_title_snapshot',
  'clothing_item_ids_snapshot',
  'idx_clothing_items_category',
  'idx_clothing_items_store_name',
  'idx_wear_logs_worn_date',
  'idx_wishlist_items_store_name'
]) {
  if (!text.includes(needle)) {
    console.error(`Missing schema detail ${needle}`);
    process.exit(1);
  }
}

if (!/outfit_id TEXT,\s+outfit_title_snapshot/s.test(text) || !text.includes('ON DELETE SET NULL')) {
  console.error('Wear logs must keep snapshots while allowing outfit template deletion.');
  process.exit(1);
}
