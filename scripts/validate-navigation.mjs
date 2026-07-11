import fs from 'node:fs';

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const navPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const sheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';

const index = fs.readFileSync(indexPath, 'utf8');
const nav = fs.readFileSync(navPath, 'utf8');
const sheet = fs.readFileSync(sheetPath, 'utf8');

for (const needle of [
  'WardrobePage',
  'StoreVisitPage',
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

for (const action of ['拍照', '从相册选择']) {
  if (!sheet.includes(action)) {
    throw new Error(`QuickCaptureSheet missing ${action}`);
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

if (!nav.includes('onSelectOutfit') || !nav.includes('onOpenProfile')) {
  throw new Error('BottomNavigationBar missing screenshot navigation actions');
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
  throw new Error('BottomNavigationBar should use photo-first onOpenCapture');
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
  'ShoppingPage({',
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
