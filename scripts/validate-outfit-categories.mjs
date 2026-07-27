import fs from 'node:fs';

function read(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }
  return fs.readFileSync(path, 'utf8');
}

function requireText(source, needle, owner) {
  if (!source.includes(needle)) {
    throw new Error(`${owner} missing ${needle}`);
  }
}

const migration = read('entry/src/main/ets/data/migrations/V10OutfitCategories.ets');
const models = read('entry/src/main/ets/domain/outfit/OutfitModels.ets');
const repository = read('entry/src/main/ets/data/repositories/OutfitRepository.ets');
const editor = read('entry/src/main/ets/pages/OutfitEditPage.ets');
const outfits = read('entry/src/main/ets/pages/OutfitsPage.ets');
const manager = read('entry/src/main/ets/components/OutfitCategoryManagerSheet.ets');
const searchBuilder = read('entry/src/main/ets/domain/search/SearchDocumentBuilder.ets');

for (const needle of [
  'CREATE TABLE IF NOT EXISTS outfit_categories',
  'normalized_name TEXT NOT NULL UNIQUE',
  'ALTER TABLE outfit_templates ADD COLUMN category_id TEXT',
  'idx_outfit_templates_category_id',
  "'周末'",
  "'通勤'"
]) {
  requireText(migration, needle, 'V10OutfitCategories');
}
if (migration.includes("'逛店'")) {
  throw new Error('V10OutfitCategories must not seed 逛店');
}

for (const needle of [
  'export interface OutfitCategory',
  'usageCount: number',
  'categoryId?: string',
  'categoryName?: string'
]) {
  requireText(models, needle, 'OutfitModels');
}

for (const needle of [
  'categoryName?: string',
  'resolveOutfitCategory(input.categoryName, now)',
  'INSERT INTO outfit_categories',
  'listOutfitCategories',
  'deleteOutfitCategory',
  'CLEAR_OUTFIT_CATEGORY_SQL',
  'await this.upsertSearchDocument(clearedOutfit)'
]) {
  requireText(repository, needle, 'OutfitRepository');
}

if (!/async createOutfit[\s\S]*?this\.database\.transaction[\s\S]*?resolveOutfitCategory[\s\S]*?executeSql\(INSERT_OUTFIT_SQL/.test(repository)) {
  throw new Error('OutfitRepository must create a custom category inside the outfit transaction');
}

if (!/const category: OutfitCategory[\s\S]*?executeSql\(INSERT_OUTFIT_CATEGORY_SQL[\s\S]*?return category;/.test(repository)) {
  throw new Error('OutfitRepository must return the inserted category without a transaction-local readback');
}

if (!/const affectedOutfits: OutfitTemplate\[\][\s\S]*?CLEAR_OUTFIT_CATEGORY_SQL[\s\S]*?const clearedOutfit: OutfitTemplate[\s\S]*?upsertSearchDocument\(clearedOutfit\)/.test(repository)) {
  throw new Error('OutfitRepository must rebuild deleted-category search documents without a transaction-local readback');
}

for (const needle of [
  'OutfitCategoryField',
  "Text('分类（选填）')",
  "Button('自定义分类')",
  "placeholder: '输入分类名称'",
  'categoryName: optionalText(this.categoryName)',
  'OutfitCategoryManagerSheet'
]) {
  requireText(editor, needle, 'OutfitEditPage');
}

for (const needle of [
  'listOutfitCategories',
  'selectedCategoryId',
  "this.CategoryFilterChip('', '全部', true)",
  'ForEach(this.categories',
  'outfit.categoryId === this.selectedCategoryId',
  "outfit.categoryName ?? '未分类'",
  'OutfitCategoryManagerSheet'
]) {
  requireText(outfits, needle, 'OutfitsPage');
}

for (const forbidden of ['OUTFIT_SCENE_FILTERS', 'OutfitSceneFilter', "{ label: '逛店'", "CategoryFilterChip('', '未分类'"]) {
  if (outfits.includes(forbidden)) {
    throw new Error(`OutfitsPage must not include ${forbidden}`);
  }
}

for (const needle of ['删除分类', '归入全部', 'category.usageCount', 'sys.symbol.trash']) {
  requireText(manager, needle, 'OutfitCategoryManagerSheet');
}

for (const needle of ['outfit.categoryName', 'category,', 'buildSearchNgramText([title, body, category])']) {
  requireText(searchBuilder, needle, 'SearchDocumentBuilder');
}

console.log('PASS');
