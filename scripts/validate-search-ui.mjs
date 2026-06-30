import fs from 'node:fs';

const resultPagePath = 'entry/src/main/ets/pages/SearchResultsPage.ets';
if (!fs.existsSync(resultPagePath)) {
  throw new Error(`${resultPagePath} does not exist`);
}

const resultPage = fs.readFileSync(resultPagePath, 'utf8');
for (const needle of [
  'SearchRepository',
  'entity_type',
  'entity_id',
  'ClothingRepository',
  'OutfitRepository',
  'WishlistRepository',
  'SearchResult',
  'SearchEntityType',
  'query',
  'searchResults',
  'performSearch',
  'ForEach'
]) {
  if (!resultPage.includes(needle)) {
    throw new Error(`SearchResultsPage missing ${needle}`);
  }
}

for (const pagePath of [
  'entry/src/main/ets/pages/WardrobePage.ets',
  'entry/src/main/ets/pages/OutfitsPage.ets',
  'entry/src/main/ets/pages/ShoppingPage.ets'
]) {
  const page = fs.readFileSync(pagePath, 'utf8');
  for (const needle of ['SearchResultsPage', 'openUnifiedSearch', 'unifiedSearchQuery']) {
    if (!page.includes(needle)) {
      throw new Error(`${pagePath} missing unified search integration: ${needle}`);
    }
  }
}

console.log('PASS');
