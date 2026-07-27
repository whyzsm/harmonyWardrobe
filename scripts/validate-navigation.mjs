import fs from 'node:fs';

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const appRoutePath = 'entry/src/main/ets/app/AppRoute.ets';
const navPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const sheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';

const index = fs.readFileSync(indexPath, 'utf8');
const appRoute = fs.readFileSync(appRoutePath, 'utf8');
const nav = fs.readFileSync(navPath, 'utf8');
const sheet = fs.readFileSync(sheetPath, 'utf8');
const outfitsPage = fs.readFileSync('entry/src/main/ets/pages/OutfitsPage.ets', 'utf8');
const wardrobePage = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');
const storePage = fs.readFileSync('entry/src/main/ets/pages/StoreVisitPage.ets', 'utf8');
const wishlistPage = fs.readFileSync('entry/src/main/ets/pages/WishlistPage.ets', 'utf8');

if (!/createInitialAppRoute\(\): AppRoute \{[\s\S]*?AppMainTab\.Outfit/.test(appRoute)) {
  throw new Error('AppRoute must open the outfit tab by default');
}

if (!nav.includes("@Prop selected: string = 'outfit'")) {
  throw new Error('BottomNavigationBar default selection must match the initial outfit tab');
}

function flatCallbackBody(text, callbackName) {
  const match = text.match(new RegExp(`${callbackName}: \\(\\) => \\{([^{}]*)\\}`));
  if (match === null) {
    throw new Error(`Index missing flat callback ${callbackName}`);
  }
  return match[1];
}

for (const needle of [
  'WardrobePage',
  'StoreVisitPage',
  'OutfitsPage',
  'ProfilePage',
  'CaptureEditPage'
]) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing ${needle}`);
  }
}

const navigationItemsInOrder = [
  "this.NavItem('outfit', '穿搭')",
  "this.NavItem('wardrobe', '衣柜')",
  'this.CameraIcon()',
  "this.NavItem('store', '逛街')",
  "this.NavItem('profile', '我的')"
];
let previousNavigationItemIndex = -1;
for (const navigationItem of navigationItemsInOrder) {
  const navigationItemIndex = nav.indexOf(navigationItem);
  if (navigationItemIndex <= previousNavigationItemIndex) {
    throw new Error(`BottomNavigationBar missing or out of order: ${navigationItem}`);
  }
  previousNavigationItemIndex = navigationItemIndex;
}

for (const action of ['衣柜', '逛店', '穿搭']) {
  if (!sheet.includes(action)) {
    throw new Error(`QuickCaptureSheet missing ${action}`);
  }
}

const quickCaptureActionsInOrder = [
  "this.ActionCard('穿搭', '新增穿搭', 'outfit'",
  "this.ActionCard('逛店', '新增逛店记录', 'store'",
  "this.ActionCard('衣柜', '新增衣物', 'wardrobe'"
];
let previousQuickCaptureActionIndex = -1;
for (const quickCaptureAction of quickCaptureActionsInOrder) {
  const quickCaptureActionIndex = sheet.indexOf(quickCaptureAction);
  if (quickCaptureActionIndex <= previousQuickCaptureActionIndex) {
    throw new Error(`QuickCaptureSheet missing or out of order: ${quickCaptureAction}`);
  }
  previousQuickCaptureActionIndex = quickCaptureActionIndex;
}

for (const copy of ['新增衣物', '新增逛店记录', '新增穿搭']) {
  if (!sheet.includes(copy)) {
    throw new Error(`QuickCaptureSheet missing create copy ${copy}`);
  }
}

for (const callback of ['onOpenWardrobe', 'onOpenStoreVisit', 'onOpenOutfit']) {
  if (!sheet.includes(callback)) {
    throw new Error(`QuickCaptureSheet missing ${callback}`);
  }
}

for (const forbiddenAction of ['拍衣服', '拍搭配', '拍店铺']) {
  if (sheet.includes(forbiddenAction)) {
    throw new Error(`QuickCaptureSheet should not branch by business type: ${forbiddenAction}`);
  }
}

if (!nav.includes('onOpenCapture')) {
  throw new Error('BottomNavigationBar missing onOpenCapture');
}

if (!nav.includes(".width('90%')")) {
  throw new Error('BottomNavigationBar should use 90% floating capsule width');
}

for (const layoutNeedle of ['Column({ space: 4 })', '.height(22)', '.lineHeight(15)']) {
  if (!nav.includes(layoutNeedle)) {
    throw new Error(`BottomNavigationBar missing aligned icon-label spacing: ${layoutNeedle}`);
  }
}

if (nav.includes("Text('拍照')")) {
  throw new Error('BottomNavigationBar center camera should not render a text label');
}

if (!nav.includes('onSelectOutfit') || !nav.includes('onOpenProfile')) {
  throw new Error('BottomNavigationBar missing screenshot navigation actions');
}

for (const route of [
  'this.resetMainRoute(AppMainTab.Store)',
  'this.resetMainRoute(AppMainTab.Outfit)',
  'this.resetMainRoute(AppMainTab.Profile)'
]) {
  if (!index.includes(route)) {
    throw new Error(`Index missing independent main-tab route ${route}`);
  }
}

if (!/private openStoreVisitList\(\): void \{[\s\S]*?this\.resetMainRoute\(AppMainTab\.Store\);[\s\S]*?\}/.test(index)) {
  throw new Error('Store tab must close the quick store editor before opening the store visit list');
}

const selectStoreBody = flatCallbackBody(index, 'onSelectStore');
if (!selectStoreBody.includes('this.openStoreVisitList();') || selectStoreBody.includes('this.openQuickStoreEditor();')) {
  throw new Error('Bottom store navigation must open the store visit list');
}

if (!/QuickCaptureSheet\(\{[\s\S]*?onOpenWardrobe:\s*\(\) => \{[\s\S]*?this\.openQuickClothingEditor\(\);[\s\S]*?onOpenStoreVisit:\s*\(\) => \{[\s\S]*?this\.openQuickStoreEditor\(\);[\s\S]*?onOpenOutfit:\s*\(\) => \{[\s\S]*?this\.openQuickOutfitEditor\(\);/.test(index)) {
  throw new Error('Quick shortcut actions must open the three create editors');
}

if (!sheet.includes('@Prop selectedCategory: string') || !sheet.includes('isSelectedCategory')) {
  throw new Error('QuickCaptureSheet must derive the selected action from the active main tab');
}

if (!/QuickCaptureSheet\(\{[\s\S]*?selectedCategory:\s*this\.activeRoute\.mainTab/.test(index)) {
  throw new Error('Index must pass the active main tab to QuickCaptureSheet');
}

for (const needle of [
  '@State private activeRoute: AppRoute = createInitialAppRoute()',
  'AppRouteKind.StoreEditor',
  'AppRouteKind.ClothingEditor',
  'AppRouteKind.OutfitEditor',
  'AppRouteKind.Wishlist',
  'AppRouteKind.CaptureEditor',
  'featureNestedContentVisible',
  'onEditorVisibilityChange',
  'onClothingEditorVisibilityChange',
  'onNestedPageVisibilityChange',
  'private shouldShowBottomNavigation(): boolean',
  'return this.activeRoute.kind === AppRouteKind.Main && !this.featureNestedContentVisible',
  'if (this.shouldShowBottomNavigation())',
  'BottomNavigationBar({'
]) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing store editor navigation visibility behavior: ${needle}`);
  }
}

for (const editor of ['ClothingEditPage({', 'StoreVisitEditPage({', 'OutfitEditPage({']) {
  if (!index.includes(editor)) {
    throw new Error(`Index missing create editor ${editor}`);
  }
}

if (index.includes("this.initialWardrobeTab = '美搭'")) {
  throw new Error('Outfit navigation must not route through WardrobePage internal tabs');
}

for (const needle of [
  'private replaceCurrentRouteParams',
  'private consumeOutfitRoute',
  'private consumeWearLogRoute',
  'private consumeStoreVisitRoute',
  'private consumeWishlistRoute',
  'onInitialOutfitConsumed',
  'onInitialWearLogConsumed',
  'onInitialVisitConsumed',
  'onInitialWishlistItemConsumed'
]) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing one-time detail route cleanup: ${needle}`);
  }
}

for (const [page, callback] of [
  [outfitsPage, 'onInitialOutfitConsumed'],
  [outfitsPage, 'onInitialWearLogConsumed'],
  [storePage, 'onInitialVisitConsumed'],
  [wishlistPage, 'onInitialWishlistItemConsumed']
]) {
  if (!page.includes(callback)) {
    throw new Error(`Page missing one-time route callback: ${callback}`);
  }
}

for (const page of [outfitsPage, wardrobePage]) {
  if (!page.includes('this.onOpenSearchTarget(')) {
    throw new Error('Search result navigation must forward external results to the parent route');
  }
  if (page.includes('this.closeUnifiedSearch();\n          this.onOpenSearchTarget')) {
    throw new Error('Search result navigation must not start a nested close animation before parent routing');
  }
}

for (const page of [outfitsPage, wardrobePage]) {
  if (!/private close(?:Outfit|Clothing)Detail\(\): void[\s\S]*?showUnifiedSearch = false;/.test(page)) {
    throw new Error('Detail back navigation must clear stale unified search state');
  }
}

for (const symbol of [
  "SymbolGlyph($r('sys.symbol.shirt'))",
  "SymbolGlyph($r('sys.symbol.store_fill'))",
  "SymbolGlyph($r('sys.symbol.hanger_and_towels'))",
  "SymbolGlyph($r('sys.symbol.person'))"
]) {
  if (!nav.includes(symbol)) {
    throw new Error(`BottomNavigationBar missing system icon ${symbol}`);
  }
}

if (nav.includes('onOpenQuickActions')) {
  throw new Error('BottomNavigationBar should use the shared onOpenCapture entry');
}

for (const legacyIcon of ["'⌂'", "'▤'", "'▢'", "'○'"]) {
  if (nav.includes(legacyIcon)) {
    throw new Error(`BottomNavigationBar should not use text icon ${legacyIcon}`);
  }
}

for (const forbidden of [
  'openAddClothing',
  'openCreateOutfit',
  'openCreateStoreVisit',
  'onCaptureClothing',
  'onCaptureOutfit',
  'onCaptureStore'
]) {
  if (index.includes(forbidden)) {
    throw new Error(`Index should not keep old direct quick editor routing: ${forbidden}`);
  }
}

for (const forbidden of [
  'TodayPage({',
  'CalendarPage({',
  "BottomTabItem(0, '首页')",
  "BottomTabItem(2, '日历')",
  "BottomTabItem(3, '逛街')",
  '创建穿搭',
  '记录今日'
]) {
  if (index.includes(forbidden)) {
    throw new Error(`Index still contains old navigation concept ${forbidden}`);
  }
}

console.log('PASS');
