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
const relationMigration = read('entry/src/main/ets/data/migrations/V11OutfitCategoryRelations.ets');
const models = read('entry/src/main/ets/domain/outfit/OutfitModels.ets');
const repository = read('entry/src/main/ets/data/repositories/OutfitRepository.ets');
const editor = read('entry/src/main/ets/pages/OutfitEditPage.ets');
const outfits = read('entry/src/main/ets/pages/OutfitsPage.ets');
const searchBuilder = read('entry/src/main/ets/domain/search/SearchDocumentBuilder.ets');
const managerPath = 'entry/src/main/ets/components/OutfitCategoryManagerSheet.ets';

if (fs.existsSync(managerPath)) {
  throw new Error('Outfit category deletion must be inline on editor chips, not in a separate manager sheet');
}

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
  'CREATE TABLE IF NOT EXISTS outfit_template_categories',
  'PRIMARY KEY (outfit_id, category_id)',
  'idx_outfit_template_categories_category_id',
  'INSERT OR IGNORE INTO outfit_template_categories',
  'outfits.category_id'
]) {
  requireText(relationMigration, needle, 'V11OutfitCategoryRelations');
}

for (const needle of [
  'export interface OutfitCategory',
  'usageCount: number',
  'categoryIds: string[]',
  'categoryNames: string[]',
  'categoryId?: string',
  'categoryName?: string'
]) {
  requireText(models, needle, 'OutfitModels');
}

for (const needle of [
  'categoryNames?: string[]',
  'resolveOutfitCategories(input.categoryNames, now)',
  'INSERT INTO outfit_categories',
  'INSERT INTO outfit_template_categories',
  'replaceCategoryRows',
  'readOutfitCategorySelection',
  'listOutfitCategories',
  'deleteOutfitCategory',
  'DELETE_CATEGORY_RELATIONS_SQL',
  'await this.upsertSearchDocument(outfit)'
]) {
  requireText(repository, needle, 'OutfitRepository');
}

if (!/async createOutfit[\s\S]*?this\.database\.transaction[\s\S]*?resolveOutfitCategories[\s\S]*?executeSql\(INSERT_OUTFIT_SQL[\s\S]*?replaceCategoryRows/.test(repository)) {
  throw new Error('OutfitRepository must create custom categories and relations inside the outfit transaction');
}

if (!/const category: OutfitCategory[\s\S]*?executeSql\(INSERT_OUTFIT_CATEGORY_SQL[\s\S]*?categories\.push\(category\)[\s\S]*?return categories;/.test(repository)) {
  throw new Error('OutfitRepository must collect inserted categories without a transaction-local readback');
}

if (!/deleteOutfitCategory[\s\S]*?DELETE_CATEGORY_RELATIONS_SQL[\s\S]*?DELETE_OUTFIT_CATEGORY_SQL[\s\S]*?getOutfitByIdInTransaction[\s\S]*?upsertSearchDocument\(outfit\)/.test(repository)) {
  throw new Error('OutfitRepository must rehydrate remaining categories and rebuild affected search documents');
}

for (const needle of [
  'OutfitCategoryField',
  "Text('分类（选填）')",
  "Button('自定义分类')",
  "placeholder: '输入分类名称'",
  '@State private categoryNames: string[] = []',
  'categoryNames: this.categoryNamesForSave()',
  "normalizeSearchText('通勤')",
  'this.categoryNames = [category.name]',
  'confirmDeleteOutfitCategory',
  'deletingCategoryId',
  "SymbolGlyph($r('sys.symbol.xmark'))",
  'category.usageCount',
  'await this.onCategoriesChange()',
  'accessibilityText(`删除分类 ${category.name}`)',
  '.constraintSize({ minWidth: 0, maxWidth: 168 })',
  '.width(24)',
  '.offset({ x: -8 })',
  '.responseRegion({ x: -8, y: 0, width: 44, height: 44 })'
]) {
  requireText(editor, needle, 'OutfitEditPage');
}

if (!/CategoryChip\(category: OutfitCategory\)[\s\S]*?Row\(\)[\s\S]*?this\.selectCategory\(category\)[\s\S]*?this\.confirmDeleteOutfitCategory\(category\)/.test(editor)) {
  throw new Error('OutfitEditPage category chips must provide separate select and inline delete targets');
}

for (const needle of [
  'listOutfitCategories',
  'selectedCategoryId',
  "this.CategoryFilterChip('', '全部', true)",
  'ForEach(this.categories',
  'outfit.categoryIds.includes(this.selectedCategoryId)',
  "outfit.categoryNames.join('、')",
  'onCategoriesChange',
  'refreshOutfitsAfterCategoryChange'
]) {
  requireText(outfits, needle, 'OutfitsPage');
}

for (const forbidden of [
  'OUTFIT_SCENE_FILTERS',
  'OutfitSceneFilter',
  "{ label: '逛店'",
  "CategoryFilterChip('', '未分类'",
  'OutfitCategoryManagerSheet',
  'showCategoryManager',
  "sys.symbol.list_bullet"
]) {
  if (outfits.includes(forbidden)) {
    throw new Error(`OutfitsPage must not include ${forbidden}`);
  }
}

for (const forbidden of ['OutfitCategoryManagerSheet', 'showCategoryManager', "sys.symbol.list_bullet"]) {
  if (editor.includes(forbidden)) {
    throw new Error(`OutfitEditPage must keep category deletion inline and omit ${forbidden}`);
  }
}

for (const needle of ['outfit.categoryNames', '...outfit.categoryNames', 'category,', 'buildSearchNgramText([title, body, category])']) {
  requireText(searchBuilder, needle, 'SearchDocumentBuilder');
}

console.log('PASS');
