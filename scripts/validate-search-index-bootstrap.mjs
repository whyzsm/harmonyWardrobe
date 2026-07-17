import fs from 'node:fs';

const factoryPath = 'entry/src/main/ets/app/WardrobeRuntimeFactory.ets';
const bootstrapPath = 'entry/src/main/ets/data/searchIndex/SearchIndexBootstrap.ets';
const wardrobePagePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const wishlistPagePath = 'entry/src/main/ets/pages/WishlistPage.ets';
const searchBarPath = 'entry/src/main/ets/components/SearchBar.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';

function read(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }

  return fs.readFileSync(path, 'utf8');
}

function assertIncludes(source, sourceName, needle) {
  if (!source.includes(needle)) {
    throw new Error(`${sourceName} missing ${needle}`);
  }
}

function assertOmits(source, sourceName, needle) {
  if (source.includes(needle)) {
    throw new Error(`${sourceName} must not contain ${needle}`);
  }
}

function findMatchingBrace(source, openBraceIndex) {
  let depth = 0;

  for (let index = openBraceIndex; index < source.length; index += 1) {
    if (source[index] === '{') {
      depth += 1;
    } else if (source[index] === '}') {
      depth -= 1;
      if (depth === 0) {
        return index;
      }
    }
  }

  throw new Error(`Could not find matching brace at ${openBraceIndex}`);
}

function extractMethodBody(source, methodName) {
  const methodIndex = source.indexOf(`${methodName}(`);
  if (methodIndex === -1) {
    throw new Error(`Missing method ${methodName}`);
  }

  const openBraceIndex = source.indexOf('{', methodIndex);
  const closeBraceIndex = findMatchingBrace(source, openBraceIndex);
  return source.slice(openBraceIndex + 1, closeBraceIndex);
}

const factory = read(factoryPath);
const bootstrap = read(bootstrapPath);
const wardrobePage = read(wardrobePagePath);
const wishlistPage = read(wishlistPagePath);
const searchBar = read(searchBarPath);
const index = read(indexPath);

assertIncludes(factory, factoryPath, 'SearchIndexBootstrap.ensureReady');
assertOmits(factory, factoryPath, 'SearchIndexBootstrap.rebuild');

for (const needle of [
  'SEARCH_INDEX_STATE_VERSION',
  'search_index_state',
  'schema_migrations',
  'CREATE TABLE IF NOT EXISTS',
  'schema_version',
  'database_schema_version',
  'mode',
  'ensureReady',
  'shouldRebuild',
  'expectedDocumentCount',
  'search_index_documents',
  'search_index_fts',
  'search_index_ngrams',
  'dependencies.searchRepository.rebuildSearchIndex(documents)',
  'listClothing()',
  'listOutfits()',
  'listWearLogs()',
  'listWishlistItems()',
  'listStores()',
  'listStoreVisits()'
]) {
  assertIncludes(bootstrap, bootstrapPath, needle);
}

const ensureReadyBody = extractMethodBody(bootstrap, 'ensureReady');
if (!/if\s*\(\s*await\s+shouldRebuild[\s\S]*?await\s+(?:[A-Za-z_$][\w$]*\.)?rebuild/.test(ensureReadyBody)) {
  throw new Error('ensureReady must rebuild only after the persisted index state check');
}

for (const table of ['clothing_items', 'outfit_templates', 'wear_logs', 'wishlist_items', 'stores', 'store_visits']) {
  assertIncludes(bootstrap, bootstrapPath, `COUNT(*) FROM ${table}`);
}

assertIncludes(bootstrap, bootstrapPath, 'SEARCH_INDEX_STATE_VERSION');
assertIncludes(bootstrap, bootstrapPath, 'searchIndexMode');
assertIncludes(bootstrap, bootstrapPath, 'schemaVersion');
assertIncludes(bootstrap, bootstrapPath, 'databaseSchemaVersion');
assertIncludes(bootstrap, bootstrapPath, 'documentCount');

if (fs.existsSync('entry/src/main/ets/pages/ShoppingPage.ets')) {
  throw new Error('ShoppingPage must remain absent from the current product flow');
}

for (const needle of [
  'SearchResultsPage',
  'openUnifiedSearch',
  'this.openSearch()',
  'searchQuery',
  'searchRepository'
]) {
  assertIncludes(wardrobePage, wardrobePagePath, needle);
}

const searchInputStart = wardrobePage.indexOf("TextInput({ text: this.searchQuery");
const searchInputEnd = wardrobePage.indexOf('\n  @Builder\n  WardrobeSearchTabs', searchInputStart);
if (searchInputStart === -1 || searchInputEnd === -1) {
  throw new Error(`${wardrobePagePath} search input block is not locatable`);
}

const searchInput = wardrobePage.slice(searchInputStart, searchInputEnd);
const onChangeStart = searchInput.indexOf('.onChange(');
const onClickStart = searchInput.indexOf('.onClick(', onChangeStart);
const onSubmitStart = searchInput.indexOf('.onSubmit(');
if (onChangeStart === -1 || onClickStart === -1 || onSubmitStart === -1) {
  throw new Error(`${wardrobePagePath} search input must expose change, click, and submit handlers`);
}

if (searchInput.slice(onChangeStart, onClickStart).includes('openSearch')) {
  throw new Error(`${wardrobePagePath} must not navigate to unified search on every keystroke`);
}

if (!searchInput.slice(onClickStart).includes('this.openSearch()')) {
  throw new Error(`${wardrobePagePath} search click must open unified search`);
}

if (!searchInput.slice(onSubmitStart).includes('this.openSearch()')) {
  throw new Error(`${wardrobePagePath} search submit must open unified search`);
}

assertIncludes(searchBar, searchBarPath, 'onSubmit: () => void');
assertIncludes(searchBar, searchBarPath, '.onSubmit(() =>');

const wishlistSearchStart = wishlistPage.indexOf('SearchBar({');
const wishlistSearchEnd = wishlistPage.indexOf('\n\n      if (this.filterWishlistItems', wishlistSearchStart);
if (wishlistSearchStart === -1 || wishlistSearchEnd === -1) {
  throw new Error(`${wishlistPagePath} search bar block is not locatable`);
}

const wishlistSearch = wishlistPage.slice(wishlistSearchStart, wishlistSearchEnd);
const wishlistOnChangeStart = wishlistSearch.indexOf('onChange:');
const wishlistOnSubmitStart = wishlistSearch.indexOf('onSubmit:');
if (wishlistOnChangeStart === -1 || wishlistOnSubmitStart === -1) {
  throw new Error(`${wishlistPagePath} search must expose change and submit handlers`);
}

if (wishlistSearch.slice(wishlistOnChangeStart, wishlistOnSubmitStart).includes('openUnifiedSearch')) {
  throw new Error(`${wishlistPagePath} must not navigate to unified search on every keystroke`);
}

if (!wishlistSearch.slice(wishlistOnSubmitStart).includes('this.openUnifiedSearch(this.searchQuery)')) {
  throw new Error(`${wishlistPagePath} search submit must open unified search`);
}

assertOmits(index, indexPath, 'ShoppingPage');
assertIncludes(index, indexPath, 'WardrobePage');

console.log('PASS');
