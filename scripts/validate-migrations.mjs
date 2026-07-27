import fs from 'node:fs';

const migration = fs.readFileSync('entry/src/main/ets/data/migrations/Migration.ets', 'utf8');
const runner = fs.readFileSync('entry/src/main/ets/data/migrations/MigrationRunner.ets', 'utf8');
const runtime = fs.readFileSync('entry/src/main/ets/app/WardrobeRuntimeFactory.ets', 'utf8');
const storeNormalizedName = fs.readFileSync('entry/src/main/ets/data/migrations/V6StoreNormalizedName.ets', 'utf8');
const profileSizes = fs.readFileSync('entry/src/main/ets/data/migrations/V8ProfileSizes.ets', 'utf8');
const outfitDisplaySource = fs.readFileSync('entry/src/main/ets/data/migrations/V9OutfitDisplaySource.ets', 'utf8');
const outfitCategories = fs.readFileSync('entry/src/main/ets/data/migrations/V10OutfitCategories.ets', 'utf8');
const outfitCategoryRelations = fs.readFileSync('entry/src/main/ets/data/migrations/V11OutfitCategoryRelations.ets', 'utf8');

for (const needle of ['Migration', 'version', 'up', 'transaction', 'getString']) {
  if (!migration.includes(needle)) throw new Error(`Migration.ets missing ${needle}`);
}
for (const needle of ['MigrationRunner', 'schema_migrations', 'runMigrations', 'validateAndSortMigrations', 'Duplicate migration version', 'Invalid migration version', 'transaction']) {
  if (!runner.includes(needle)) throw new Error(`MigrationRunner.ets missing ${needle}`);
}
for (const needle of ['V6StoreNormalizedName', 'version: number = 6', 'normalized_name', 'normalizeSearchText', 'idx_stores_normalized_name']) {
  if (!storeNormalizedName.includes(needle)) throw new Error(`V6StoreNormalizedName.ets missing ${needle}`);
}
for (const needle of ['v6StoreNormalizedName', 'V6StoreNormalizedName']) {
  if (!runtime.includes(needle)) throw new Error(`WardrobeRuntimeFactory.ets missing ${needle}`);
}
for (const needle of ['V8ProfileSizes', 'version: number = 8', 'upper_size', 'lower_size', 'shoe_size']) {
  if (!profileSizes.includes(needle)) throw new Error(`V8ProfileSizes.ets missing ${needle}`);
}
for (const needle of ['v8ProfileSizes', 'V8ProfileSizes']) {
  if (!runtime.includes(needle)) throw new Error(`WardrobeRuntimeFactory.ets missing ${needle}`);
}
for (const needle of ['V9OutfitDisplaySource', 'version: number = 9', 'display_source', 'outfit_templates']) {
  if (!outfitDisplaySource.includes(needle)) throw new Error(`V9OutfitDisplaySource.ets missing ${needle}`);
}
for (const needle of ['v9OutfitDisplaySource', 'V9OutfitDisplaySource']) {
  if (!runtime.includes(needle)) throw new Error(`WardrobeRuntimeFactory.ets missing ${needle}`);
}
for (const needle of [
  'V10OutfitCategories',
  'version: number = 10',
  'outfit_categories',
  'normalized_name',
  'category_id',
  'idx_outfit_templates_category_id',
  "'周末'",
  "'通勤'"
]) {
  if (!outfitCategories.includes(needle)) throw new Error(`V10OutfitCategories.ets missing ${needle}`);
}
if (outfitCategories.includes("'逛店'")) {
  throw new Error('V10OutfitCategories.ets must not seed the removed 逛店 category');
}
for (const needle of ['v10OutfitCategories', 'V10OutfitCategories']) {
  if (!runtime.includes(needle)) throw new Error(`WardrobeRuntimeFactory.ets missing ${needle}`);
}
for (const needle of [
  'V11OutfitCategoryRelations',
  'version: number = 11',
  'outfit_template_categories',
  'PRIMARY KEY (outfit_id, category_id)',
  'FOREIGN KEY (outfit_id)',
  'FOREIGN KEY (category_id)',
  'idx_outfit_template_categories_category_id',
  'INSERT OR IGNORE INTO outfit_template_categories',
  'outfits.category_id'
]) {
  if (!outfitCategoryRelations.includes(needle)) throw new Error(`V11OutfitCategoryRelations.ets missing ${needle}`);
}
for (const needle of ['v11OutfitCategoryRelations', 'V11OutfitCategoryRelations']) {
  if (!runtime.includes(needle)) throw new Error(`WardrobeRuntimeFactory.ets missing ${needle}`);
}
