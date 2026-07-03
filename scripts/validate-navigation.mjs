import fs from 'node:fs';

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const navPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const sheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';

const index = fs.readFileSync(indexPath, 'utf8');
const nav = fs.readFileSync(navPath, 'utf8');
const sheet = fs.readFileSync(sheetPath, 'utf8');

for (const needle of [
  'AppTopBar',
  'WardrobePage',
  'StoreVisitPage',
  'ProfilePage',
  'ClothingEditPage',
  'OutfitEditPage',
  'StoreVisitEditPage'
]) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing ${needle}`);
  }
}

for (const label of ['衣橱', '逛店']) {
  if (!nav.includes(label)) {
    throw new Error(`BottomNavigationBar missing ${label}`);
  }
}

for (const action of ['拍衣服', '拍搭配', '拍店铺']) {
  if (!sheet.includes(action)) {
    throw new Error(`QuickCaptureSheet missing ${action}`);
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
