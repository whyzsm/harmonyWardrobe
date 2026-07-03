import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }

  return fs.readFileSync(file, 'utf8');
}

function mustInclude(text, file, needle) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustNotInclude(text, file, needle) {
  if (text.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const wardrobePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const quickSheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';
const index = read(indexPath);
const wardrobe = read(wardrobePath);
const quickSheet = read(quickSheetPath);

for (const needle of [
  '衣不缺',
  '衣橱',
  '逛店',
  'AppTopBar',
  'BottomNavigationBar',
  'QuickCaptureSheet'
]) {
  mustInclude(index, indexPath, needle);
}

for (const needle of ['衣裤', '美搭']) {
  mustInclude(wardrobe, wardrobePath, needle);
}

for (const needle of ['拍衣服', '拍搭配', '拍店铺']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}

for (const forbidden of [
  "BottomTabItem(0, '首页')",
  "BottomTabItem(2, '日历')",
  "BottomTabItem(3, '逛街')",
  'ShoppingPage({',
  'CalendarPage({',
  'TodayPage({',
  'WishlistRepository',
  '心愿单',
  '点赞',
  '收藏',
  '评论',
  '关注'
]) {
  mustNotInclude(index, indexPath, forbidden);
}

console.log('PASS');
