import fs from 'node:fs';

const resultPagePath = 'entry/src/main/ets/pages/SearchResultsPage.ets';
const wardrobePagePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const indexPagePath = 'entry/src/main/ets/pages/Index.ets';

for (const file of [resultPagePath, wardrobePagePath, indexPagePath]) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }
}

const resultPage = fs.readFileSync(resultPagePath, 'utf8');
const wardrobePage = fs.readFileSync(wardrobePagePath, 'utf8');
const indexPage = fs.readFileSync(indexPagePath, 'utf8');

for (const needle of [
  'SearchRepository',
  'ClothingRepository',
  'OutfitRepository',
  'SearchResult',
  'SearchEntityType',
  'SearchHeader',
  'SearchTabs',
  'IdlePanel',
  'ResultsPanel',
  'ResultCard',
  'LoadingList',
  'searchText',
  'activeQuery',
  'selectedScope',
  'historyTerms',
  'SEARCH_SUGGESTIONS',
  'submitSearch',
  'clearSearch',
  'clearHistory',
  'filteredVisualResults',
  'visualResults',
  'loadClothingItems',
  'loadOutfits',
  'clothingCategoryLabel',
  'autoNamePattern',
  'photoUri',
  'onOpenClothingResult',
  'onOpenOutfitResult',
  'onOpenStoreResult',
  'onOpenProfileResult',
  'onOpenCameraSearch',
  'searchRequestVersion',
  'inputErrorMessage',
  'SearchEntityType.WearLog',
  'SearchEntityType.Wishlist',
  'search(searchQuery, 100)',
  "placeholder: '搜索衣服、商场、套装'",
  "Text('搜索')",
  "Text('历史记录')",
  "Text('猜你想搜')",
  "'全部'",
  "'衣物'",
  "'逛店'",
  "'套装'",
  "'我的'",
  "SymbolGlyph($r('sys.symbol.arrow_left'))",
  "SymbolGlyph($r('sys.symbol.camera_fill'))",
  "SymbolGlyph($r('sys.symbol.trash'))",
  'List()',
  'ListItem()',
  '.width(48)',
  '.height(36)'
]) {
  if (!resultPage.includes(needle)) {
    throw new Error(`SearchResultsPage missing ${needle}`);
  }
}

for (const forbidden of [
  'SecondaryPageHeader',
  "columnsTemplate('1fr 1fr')",
  'LoadingGrid',
  "Text(`正在找「${this.query}」`)",
  '.padding(YibuqueSpacing.md)',
  'WishlistRepository',
  '旧心愿',
  'entity_type',
  'entity_id'
]) {
  if (resultPage.includes(forbidden)) {
    throw new Error(`SearchResultsPage must not expose old search UI: ${forbidden}`);
  }
}

if (!/aboutToAppear\(\)[\s\S]*?this\.searchText = this\.query[\s\S]*?this\.activeQuery = this\.query\.trim\(\)/.test(resultPage)) {
  throw new Error('SearchResultsPage must initialize idle/results state from the incoming query');
}

if (!/SearchHeader\(\)[\s\S]*?TextInput\(\{ text: this\.searchText, placeholder: '搜索衣服、商场、套装' \}\)[\s\S]*?this\.clearSearch\(\)[\s\S]*?this\.onOpenCameraSearch\(\)[\s\S]*?this\.submitSearch\(\)/.test(resultPage)) {
  throw new Error('SearchResultsPage must implement the designed search controls');
}

if (!/IdlePanel\(\)[\s\S]*?historyTerms[\s\S]*?SEARCH_SUGGESTIONS[\s\S]*?this\.submitSearch\(term\)/.test(resultPage)) {
  throw new Error('SearchResultsPage must render interactive history and suggestion chips');
}

if (!/ResultsPanel\(\)[\s\S]*?List\(\)[\s\S]*?ForEach\(this\.filteredVisualResults\(\)[\s\S]*?ListItem\(\)[\s\S]*?this\.ResultCard\(result/.test(resultPage)) {
  throw new Error('SearchResultsPage must render results as the designed single-column list');
}

if (!/const requestVersion = \+\+this\.searchRequestVersion[\s\S]*?requestVersion !== this\.searchRequestVersion[\s\S]*?requestVersion === this\.searchRequestVersion/.test(resultPage)) {
  throw new Error('SearchResultsPage must ignore stale asynchronous search responses');
}

if (!/selectedScope === 'profile'[\s\S]*?SearchEntityType\.WearLog[\s\S]*?SearchEntityType\.Wishlist/.test(resultPage)) {
  throw new Error('SearchResultsPage profile scope must expose indexed personal results');
}

for (const needle of [
  'SearchResultsPage',
  'openUnifiedSearch',
  'unifiedSearchQuery',
  'this.showUnifiedSearch = true',
  'onOpenCameraSearch',
  'onOpenCapture',
  'getClothingById',
  'onOpenProfileResult',
  ".accessibilityText('执行搜索')"
]) {
  if (!wardrobePage.includes(needle)) {
    throw new Error(`WardrobePage missing search integration: ${needle}`);
  }
}

if (!/TextInput\(\{ text: this\.searchQuery[\s\S]*?\.onClick\(\(\) => \{[\s\S]*?this\.openSearch\(\)/.test(wardrobePage)) {
  throw new Error('WardrobePage search field must open the idle search page when tapped');
}

if (!/WardrobePage\(\{[\s\S]*?onOpenCapture: \(\) => \{[\s\S]*?this\.startCameraCapture\(\)/.test(indexPage)) {
  throw new Error('Index must connect search camera action directly to the camera flow');
}

if (!/SearchEntityType\.Store[\s\S]*?SearchEntityType\.StoreVisit[\s\S]*?selectedMainTab = 'store'[\s\S]*?selectedMainTab = 'profile'/.test(indexPage)) {
  throw new Error('Index must route store and personal search results to their target pages');
}

console.log('PASS');
