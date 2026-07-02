import fs from 'node:fs';

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const index = fs.readFileSync(indexPath, 'utf8');

for (const tab of ['TodayPage', 'WardrobePage', 'CalendarPage', 'ShoppingPage']) {
  if (!index.includes(tab)) {
    throw new Error(`Index missing ${tab}`);
  }
}

for (const label of ['首页', '衣橱', '日历', '逛街']) {
  if (!index.includes(label)) {
    throw new Error(`Index missing nav label ${label}`);
  }
}

if (!index.includes("Image($r('app.media.activePlus'))")) {
  throw new Error('Index missing center plus action image');
}

for (const forbidden of [".tabBar('今日')", ".tabBar('套装')"]) {
  if (index.includes(forbidden)) {
    throw new Error(`Index still contains forbidden nav tab ${forbidden}`);
  }
}

for (const action of ['添加衣服', '创建套装', '记录今日']) {
  if (!index.includes(action)) {
    throw new Error(`Index missing quick action ${action}`);
  }
}

for (const editor of ['ClothingEditPage', 'OutfitEditPage', 'WearLogEditPage']) {
  if (!index.includes(editor)) {
    throw new Error(`Index missing quick action editor ${editor}`);
  }
}

for (const styleNeedle of ['AppTheme.color.primary', 'AppTheme.color.surface', '.width(44)', '.height(40)', '.height(64)']) {
  if (!index.includes(styleNeedle)) {
    throw new Error(`Index missing center plus style ${styleNeedle}`);
  }
}

for (const forbidden of [
  '.margin({ bottom: 30 })',
  '.height(78)',
  'Column()\n          .layoutWeight(1)',
  'bottom: 92',
  'bottom: 66'
]) {
  if (index.includes(forbidden)) {
    throw new Error(`Index still contains floating bottom nav pattern ${forbidden}`);
  }
}

for (const page of ['TodayPage', 'WardrobePage', 'OutfitsPage', 'CalendarPage', 'ShoppingPage']) {
  const pagePath = `entry/src/main/ets/pages/${page}.ets`;
  if (!fs.existsSync(pagePath)) {
    throw new Error(`Missing ${pagePath}`);
  }

  const pageText = fs.readFileSync(pagePath, 'utf8');
  if (!pageText.includes('@Component')) {
    throw new Error(`${page} must be an ArkUI component`);
  }
}

console.log('PASS');
