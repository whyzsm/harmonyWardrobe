import fs from 'node:fs';

const migration = fs.readFileSync('entry/src/main/ets/data/migrations/Migration.ets', 'utf8');
const runner = fs.readFileSync('entry/src/main/ets/data/migrations/MigrationRunner.ets', 'utf8');
const runtime = fs.readFileSync('entry/src/main/ets/app/WardrobeRuntimeFactory.ets', 'utf8');
const storeNormalizedName = fs.readFileSync('entry/src/main/ets/data/migrations/V6StoreNormalizedName.ets', 'utf8');
const profileSizes = fs.readFileSync('entry/src/main/ets/data/migrations/V8ProfileSizes.ets', 'utf8');
const outfitDisplaySource = fs.readFileSync('entry/src/main/ets/data/migrations/V9OutfitDisplaySource.ets', 'utf8');

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
