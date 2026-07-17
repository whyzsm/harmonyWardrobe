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

if (text.includes('ensureClothingPurchaseColumns')) {
  console.error('V1 schema must not call the V2 purchase-column migration helper.');
  process.exit(1);
}

const v2File = 'entry/src/main/ets/data/migrations/V2ClothingPurchaseColumns.ets';
const runtimeFile = 'entry/src/main/ets/app/WardrobeRuntimeFactory.ets';
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
if (!runtimeText.includes('MigrationRunner') || !runtimeText.includes('runMigrations()')) {
  console.error('WardrobeRuntimeFactory must execute MigrationRunner.');
  process.exit(1);
}

for (const migration of [
  'v1InitialSchema',
  'v2ClothingPurchaseColumns',
  'v3StoreVisitSchema',
  'v4StoreVisitDetails',
  'v5ProfilePreferences'
]) {
  if (!runtimeText.includes(migration)) {
    console.error(`WardrobeRuntimeFactory must register ${migration}.`);
    process.exit(1);
  }
}

if (runtimeText.includes('ensureBaseSchema') || runtimeText.includes('.up(database)')) {
  console.error('WardrobeRuntimeFactory must not duplicate registered migrations.');
  process.exit(1);
}

const v3File = 'entry/src/main/ets/data/migrations/V3StoreVisitSchema.ets';
if (!fs.existsSync(v3File)) {
  console.error(`${v3File} must exist for store visit and profile schema.`);
  process.exit(1);
}

const v3Text = fs.readFileSync(v3File, 'utf8');
for (const needle of [
  'version: number = 3',
  'stores',
  'store_photos',
  'store_visits',
  'store_visit_photos',
  'user_profile',
  'idx_store_visits_visit_date',
  'idx_store_visits_store_id'
]) {
  if (!v3Text.includes(needle)) {
    console.error(`V3 store visit migration missing ${needle}`);
    process.exit(1);
  }
}

if (/DROP\s+TABLE/i.test(v3Text)) {
  console.error('V3 migration must not drop old tables.');
  process.exit(1);
}

const v4File = 'entry/src/main/ets/data/migrations/V4StoreVisitDetails.ets';
if (!fs.existsSync(v4File)) {
  console.error(`${v4File} must exist for store visit status and focus tags.`);
  process.exit(1);
}

const v4Text = fs.readFileSync(v4File, 'utf8');
for (const needle of [
  'version: number = 4',
  'PRAGMA table_info(store_visits)',
  'status',
  'focus_tags',
  'ALTER TABLE store_visits ADD COLUMN'
]) {
  if (!v4Text.includes(needle)) {
    console.error(`V4 store visit details migration missing ${needle}`);
    process.exit(1);
  }
}
