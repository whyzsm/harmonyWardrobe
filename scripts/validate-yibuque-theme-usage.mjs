import fs from 'node:fs';

const activeFiles = [
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
    throw new Error(`${removedFile} should be deleted instead of theme-maintained as inactive UI`);
  }
}

for (const file of activeFiles) {
  const text = fs.readFileSync(file, 'utf8');
  if (text.includes('AppTheme')) {
    throw new Error(`${file} must use Yibuque tokens on active surfaces`);
  }
}

console.log('PASS');
