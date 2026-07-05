import fs from 'node:fs';

const resultPagePath = 'entry/src/main/ets/pages/SearchResultsPage.ets';
if (!fs.existsSync(resultPagePath)) {
  throw new Error(`${resultPagePath} does not exist`);
}

const resultPage = fs.readFileSync(resultPagePath, 'utf8');
for (const needle of [
  'SearchRepository',
  'ClothingRepository',
  'OutfitRepository',
  'SearchResult',
  'SearchEntityType',
  '美搭',
  '逛店记录',
  '店铺',
  'query',
  'searchResults',
  'performSearch',
  'entityTypeLabel(result.entityType).length > 0',
  'ForEach'
]) {
  if (!resultPage.includes(needle)) {
    throw new Error(`SearchResultsPage missing ${needle}`);
  }
}

for (const forbidden of [
  'WishlistRepository',
  '旧心愿',
  "return '穿着记录';",
  'entity_type',
  'entity_id',
  '`query:'
]) {
  if (resultPage.includes(forbidden)) {
    throw new Error(`SearchResultsPage must not expose old search concept: ${forbidden}`);
  }
}

for (const pagePath of [
  'entry/src/main/ets/pages/WardrobePage.ets'
]) {
  const page = fs.readFileSync(pagePath, 'utf8');
  for (const needle of ['SearchResultsPage', 'openUnifiedSearch', 'unifiedSearchQuery']) {
    if (!page.includes(needle)) {
      throw new Error(`${pagePath} missing unified search integration: ${needle}`);
    }
  }
}

console.log('PASS');
