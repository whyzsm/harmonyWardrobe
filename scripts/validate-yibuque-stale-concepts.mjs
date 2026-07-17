import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }

  return fs.readFileSync(file, 'utf8');
}

function mustNotInclude(text, file, needle) {
  if (text.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

const userFacingFiles = [
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/ets/pages/WardrobePage.ets',
  'entry/src/main/ets/pages/CaptureEditPage.ets',
  'entry/src/main/ets/pages/StoreVisitPage.ets',
  'entry/src/main/ets/pages/StoreVisitEditPage.ets',
  'entry/src/main/ets/pages/ProfilePage.ets',
  'entry/src/main/ets/pages/SearchResultsPage.ets',
  'entry/src/main/ets/pages/WearLogEditPage.ets',
  'entry/src/main/ets/components/AppTopBar.ets',
  'entry/src/main/ets/components/BottomNavigationBar.ets',
  'entry/src/main/ets/components/QuickCaptureSheet.ets',
  'entry/src/main/ets/components/OutfitPicker.ets',
  'entry/src/main/ets/components/EmptyState.ets',
  'entry/src/main/ets/components/PhotoGrid.ets',
  'entry/src/main/ets/components/MonthCalendar.ets'
];

for (const removedFile of [
  'entry/src/main/ets/components/ClothingCard.ets',
  'entry/src/main/ets/components/OutfitCard.ets',
  'entry/src/main/ets/components/StoreVisitCard.ets',
  'entry/src/main/ets/pages/CalendarPage.ets'
]) {
  if (fs.existsSync(removedFile)) {
    throw new Error(`${removedFile} should be removed as dead code`);
  }
}

for (const file of userFacingFiles) {
  const text = read(file);
  const forbiddenConcepts = file.endsWith('/ProfilePage.ets')
    ? ['首页', '心愿单', '点赞', '收藏', '评论', '关注']
    : ['首页', '逛街', '心愿单', '点赞', '收藏', '评论', '关注'];
  for (const forbidden of forbiddenConcepts) {
    mustNotInclude(text, file, forbidden);
  }
  for (const forbidden of ['`query:', "'query:", '"query:', 'entity_type', 'entity_id', 'wornDate /', 'placeText /']) {
    mustNotInclude(text, file, forbidden);
  }
}

const quickSheet = read('entry/src/main/ets/components/QuickCaptureSheet.ets');
for (const forbidden of ['拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(quickSheet, 'entry/src/main/ets/components/QuickCaptureSheet.ets', forbidden);
}

console.log('PASS');
