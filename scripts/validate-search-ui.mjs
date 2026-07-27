import fs from 'node:fs';

const resultPagePath = 'entry/src/main/ets/pages/SearchResultsPage.ets';
const wishlistPagePath = 'entry/src/main/ets/pages/WishlistPage.ets';
const wardrobePagePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const storePagePath = 'entry/src/main/ets/pages/StoreVisitPage.ets';
const indexPagePath = 'entry/src/main/ets/pages/Index.ets';

for (const file of [resultPagePath, wishlistPagePath, wardrobePagePath, storePagePath, indexPagePath]) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }
}

const resultPage = fs.readFileSync(resultPagePath, 'utf8');
const wishlistPage = fs.readFileSync(wishlistPagePath, 'utf8');
const wardrobePage = fs.readFileSync(wardrobePagePath, 'utf8');
const storePage = fs.readFileSync(storePagePath, 'utf8');
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
  'DEFAULT_SEARCH_TERM',
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
  'searchRequestVersion',
  'inputErrorMessage',
  "import { window } from '@kit.ArkUI'",
  'getLastWindow',
  'setWindowSystemBarProperties',
  'searchHeaderSurface',
  'aboutToDisappear',
  'SearchEntityType.WearLog',
  'SearchEntityType.Wishlist',
  'initialScope',
  'matchesInitialScope',
  'availableScopes',
  'search(searchQuery, 100)',
  "placeholder: '搜索衣服、商场、穿搭'",
  "Text('搜索')",
  "Text('历史记录')",
  "Text('猜你想搜')",
  "'全部'",
  "'衣柜'",
  "'逛店'",
  "'穿搭'",
  "SymbolGlyph($r('sys.symbol.arrow_left'))",
  "SymbolGlyph($r('sys.symbol.trash'))",
  'List()',
  'ListItem()',
  '.width(48)',
  '.constraintSize({ minHeight: 44 })'
]) {
  if (!resultPage.includes(needle)) {
    throw new Error(`SearchResultsPage missing ${needle}`);
  }
}

if (!resultPage.includes("{ key: 'clothes', label: '衣柜' }")) {
  throw new Error('SearchResultsPage must label the clothing scope as 衣柜');
}

if (resultPage.includes("{ key: 'profile', label: '我的' }") || /selectedScope === 'profile'/.test(resultPage)) {
  throw new Error('SearchResultsPage must remove the 我的 search scope');
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
  'entity_id',
  'onOpenCameraSearch',
  '拍照搜索',
  '拍照录入',
  '购买记录'
]) {
  if (resultPage.includes(forbidden)) {
    throw new Error(`SearchResultsPage must not expose old search UI: ${forbidden}`);
  }
}

if (!/const DEFAULT_SEARCH_TERM = '上衣'/.test(resultPage)) {
  throw new Error('SearchResultsPage must default empty searches to 上衣');
}

if (!/aboutToAppear\(\)[\s\S]*?const initialQuery = this\.query\.trim\(\)[\s\S]*?this\.searchText = initialQuery\.length > 0 \? this\.query : ''[\s\S]*?this\.activeQuery = initialQuery/.test(resultPage)) {
  throw new Error('SearchResultsPage must keep the input empty until the user submits an empty search');
}

if (!/private async applySearchStatusBarColor\(\)[\s\S]*?window\.getLastWindow\([\s\S]*?statusBarColor: YibuqueColor\.searchHeaderSurface[\s\S]*?isStatusBarLightIcon: true/.test(resultPage) ||
  !/aboutToDisappear\(\)[\s\S]*?this\.restoreSearchStatusBarColor\(\)/.test(resultPage) ||
  !/private async restoreSearchStatusBarColor\(\)[\s\S]*?this\.previousStatusBarColor[\s\S]*?this\.previousStatusBarLightIcon/.test(resultPage)) {
  throw new Error('SearchResultsPage status bar must match the search header surface and restore on exit');
}

if (!/submitSearch\(term: string = ''\)[\s\S]*?const trimmedQuery = this\.searchText\.trim\(\)[\s\S]*?const nextQuery = trimmedQuery\.length > 0 \? trimmedQuery : DEFAULT_SEARCH_TERM[\s\S]*?this\.searchText = nextQuery/.test(resultPage)) {
  throw new Error('SearchResultsPage must submit the default clothing term when the input is empty');
}

if (!/SearchHeader\(\)[\s\S]*?TextInput\(\{ text: this\.searchText, placeholder: '搜索衣服、商场、穿搭' \}\)[\s\S]*?this\.clearSearch\(\)[\s\S]*?this\.submitSearch\(\)/.test(resultPage)) {
  throw new Error('SearchResultsPage must implement the designed search controls');
}

if (!/TextInput\(\{ text: this\.searchText, placeholder: '搜索衣服、商场、穿搭' \}\)[\s\S]*?\.fontColor\(YibuqueColor\.textPrimary\)[\s\S]*?\.placeholderColor\(YibuqueColor\.textTertiary\)/.test(resultPage)) {
  throw new Error('SearchResultsPage search input must keep actual input and placeholder colors separate');
}

if (/SearchHeader\(\)[\s\S]*?sys\.symbol\.(camera_fill|picture)/.test(resultPage)) {
  throw new Error('SearchResultsPage must not expose unavailable camera/gallery search icons');
}

if (!/IdlePanel\(\)[\s\S]*?historyTerms[\s\S]*?SEARCH_SUGGESTIONS[\s\S]*?this\.submitSearch\(term\)/.test(resultPage)) {
  throw new Error('SearchResultsPage must render interactive history and suggestion chips');
}

if (!/ResultsPanel\(\)[\s\S]*?List\(\)[\s\S]*?LazyForEach\(this\.visualResultDataSource[\s\S]*?ListItem\(\)[\s\S]*?this\.ResultCard\(result/.test(resultPage)) {
  throw new Error('SearchResultsPage must render results as the designed single-column list');
}

if (!/visualResultDataSource:\s*ArrayDataSource<SearchVisualResult>/.test(resultPage) ||
  !/refreshVisualResultDataSource\(\)[\s\S]*?this\.visualResultDataSource\.setData\(this\.filteredVisualResults\(\)\)/.test(resultPage)) {
  throw new Error('SearchResultsPage must back result rendering with ArrayDataSource');
}

if (!/const requestVersion = \+\+this\.searchRequestVersion[\s\S]*?requestVersion !== this\.searchRequestVersion[\s\S]*?requestVersion === this\.searchRequestVersion/.test(resultPage)) {
  throw new Error('SearchResultsPage must ignore stale asynchronous search responses');
}

if (!/SearchEntityType\.WearLog[\s\S]*?SearchEntityType\.Wishlist/.test(resultPage)) {
  throw new Error('SearchResultsPage must retain indexed personal results in the all scope');
}

if (!/@Prop initialScope\?: SearchEntityType = undefined/.test(resultPage)) {
  throw new Error('SearchResultsPage must support an optional initial search scope');
}

if (!/this\.selectedScope = this\.initialScope \?\? 'all'/.test(resultPage)) {
  throw new Error('SearchResultsPage must preserve all-results behavior by default');
}

if (!/matchesInitialScope[\s\S]*?this\.initialScope === undefined[\s\S]*?entityType === this\.initialScope/.test(resultPage)) {
  throw new Error('SearchResultsPage must filter constrained search results by entity type');
}

if (!/availableScopes[\s\S]*?this\.initialScope !== undefined[\s\S]*?entityTypeLabel\(this\.initialScope\)/.test(resultPage)) {
  throw new Error('SearchResultsPage must expose only the constrained scope when provided');
}

if (!/SearchResultsPage\(\{[\s\S]*?initialScope: SearchEntityType\.Wishlist[\s\S]*?onOpenWishlistResult/.test(wishlistPage)) {
  throw new Error('WishlistPage must constrain unified search to wishlist results');
}

for (const needle of [
  'SearchResultsPage',
  'openUnifiedSearch',
  'unifiedSearchQuery',
  'this.showUnifiedSearch = true',
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

for (const needle of [
  'SearchResultsPage',
  'openUnifiedSearch',
  'unifiedSearchQuery',
  'this.showUnifiedSearch = true',
  'onOpenSearchTarget',
  'openStoreVisitSearchResult',
  'SearchEntityType.Store',
  'SearchEntityType.StoreVisit',
  ".accessibilityText('执行搜索')"
]) {
  if (!storePage.includes(needle)) {
    throw new Error(`StoreVisitPage missing unified search integration: ${needle}`);
  }
}

if (!/TextInput\(\{ text: this\.searchQuery[\s\S]*?\.onClick\(\(\) => \{[\s\S]*?this\.openSearch\(\)[\s\S]*?\.onSubmit\(\(\) => \{[\s\S]*?this\.openSearch\(\)/.test(storePage)) {
  throw new Error('StoreVisitPage search field must open the unified search page when tapped or submitted');
}

if (/SearchResultsPage\(\{[\s\S]*?onOpenCameraSearch:/.test(storePage)) {
  throw new Error('StoreVisitPage must not expose camera search from unified search');
}

if (!/WardrobePage\(\{[\s\S]*?onOpenCapture: \(\) => \{[\s\S]*?this\.startCameraCapture\(\)/.test(indexPage)) {
  throw new Error('Index must keep the main wardrobe capture flow connected');
}

if (!/StoreVisitPage\(\{[\s\S]*?searchRepository: this\.runtime\.searchRepository[\s\S]*?clothingRepository: this\.runtime\.clothingRepository[\s\S]*?outfitRepository: this\.runtime\.outfitRepository[\s\S]*?onOpenSearchTarget/.test(indexPage)) {
  throw new Error('Index must connect the store page to unified search routing');
}

if (!/SearchEntityType\.Store[\s\S]*?SearchEntityType\.StoreVisit[\s\S]*?AppMainTab\.Store[\s\S]*?AppMainTab\.Profile/.test(indexPage)) {
  throw new Error('Index must route store and personal search results to their target pages');
}

console.log('PASS');
