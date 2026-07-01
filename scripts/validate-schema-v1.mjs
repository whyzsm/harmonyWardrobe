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

if (!/purchase_price INTEGER/.test(text)) {
  console.error('Clothing purchase_price must be stored as INTEGER cents to avoid decimal truncation.');
  process.exit(1);
}

if (!/wishlist_items[\s\S]*price INTEGER/.test(text)) {
  console.error('Wishlist price must be stored as INTEGER cents to avoid decimal truncation.');
  process.exit(1);
}

const repairCallIndex = text.indexOf('await ensureClothingPurchaseColumns(database)');
const indexLoopIndex = text.indexOf('for (const sql of CREATE_INDEX_SQLS)');
if (repairCallIndex < 0 || indexLoopIndex < 0 || repairCallIndex > indexLoopIndex) {
  console.error('V1 schema must repair clothing purchase columns before creating purchase indexes.');
  process.exit(1);
}

const v2File = 'entry/src/main/ets/data/migrations/V2ClothingPurchaseColumns.ets';
const runtimeFile = 'entry/src/main/ets/app/WardrobeRuntime.ets';
if (!fs.existsSync(v2File)) {
  console.error(`${v2File} must exist to repair old installed databases missing purchase columns.`);
  process.exit(1);
}

const v2Text = fs.readFileSync(v2File, 'utf8');
for (const needle of [
  'V2ClothingPurchaseColumns',
  'version: number = 2',
  'clothing_purchase_columns',
  'PRAGMA table_info(clothing_items)',
  'SELECT ${columnName} FROM clothing_items LIMIT 0',
  'columnExistsInReadableSchema',
  'if (await columnExists(database, columnPatch.name))',
  'purchase_store_name',
  'purchase_price',
  'purchase_date',
  'purchase_note',
  'ALTER TABLE clothing_items ADD COLUMN',
  'hasColumn'
]) {
  if (!v2Text.includes(needle)) {
    console.error(`V2 clothing purchase migration missing ${needle}`);
    process.exit(1);
  }
}

if (/catch\s*\(\s*error\s*\)[\s\S]*?throw\s+error/.test(v2Text)) {
  console.error('V2 clothing purchase migration must not rethrow arbitrary catch values in ArkTS.');
  process.exit(1);
}

const runtimeText = fs.readFileSync(runtimeFile, 'utf8');
if (!runtimeText.includes('v2ClothingPurchaseColumns') || !runtimeText.includes('[v1InitialSchema, v2ClothingPurchaseColumns]')) {
  console.error('WardrobeRuntime must run the V2 clothing purchase migration after V1.');
  process.exit(1);
}
