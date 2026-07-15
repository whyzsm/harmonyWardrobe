import fs from 'node:fs';

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const navPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const sheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';

const index = fs.readFileSync(indexPath, 'utf8');
const nav = fs.readFileSync(navPath, 'utf8');
const sheet = fs.readFileSync(sheetPath, 'utf8');

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

for (const label of ['衣柜', '逛店', '套装', '我的']) {
  if (!nav.includes(label)) {
    throw new Error(`BottomNavigationBar missing ${label}`);
  }
}

for (const action of ['衣柜', '逛店', '穿搭']) {
  if (!sheet.includes(action)) {
    throw new Error(`QuickCaptureSheet missing ${action}`);
  }
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
  'if (this.activeRoute.kind === AppRouteKind.Main && !this.featureNestedContentVisible)',
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
  '创建套装',
  '记录今日'
]) {
  if (index.includes(forbidden)) {
    throw new Error(`Index still contains old navigation concept ${forbidden}`);
  }
}

console.log('PASS');
