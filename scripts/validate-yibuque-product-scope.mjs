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
const navPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const index = read(indexPath);
const wardrobe = read(wardrobePath);
const quickSheet = read(quickSheetPath);
const nav = read(navPath);

for (const needle of [
  '衣不缺',
  'BottomNavigationBar',
  'QuickCaptureSheet',
  'WishlistPage',
  'AppRouteKind.Wishlist'
]) {
  mustInclude(index, indexPath, needle);
}

for (const needle of ['衣橱', '美搭', '日历']) {
  mustInclude(wardrobe, wardrobePath, needle);
}

for (const needle of ['衣柜', '逛店', '套装', '我的']) {
  mustInclude(nav, navPath, needle);
}

for (const needle of ['衣柜', '逛店', '穿搭', 'onOpenWardrobe', 'onOpenStoreVisit', 'onOpenOutfit']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}

for (const forbidden of ['拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(quickSheet, quickSheetPath, forbidden);
}

for (const forbidden of [
  "BottomTabItem(0, '首页')",
  "BottomTabItem(2, '日历')",
  "BottomTabItem(3, '逛街')",
  'CalendarPage({',
  'TodayPage({',
  '点赞',
  '收藏',
  '评论',
  '关注'
]) {
  mustNotInclude(index, indexPath, forbidden);
}

console.log('PASS');
