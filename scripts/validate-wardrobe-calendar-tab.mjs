import fs from 'node:fs';

function readRequired(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }

  return fs.readFileSync(path, 'utf8');
}

const wardrobePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const appRoutePath = 'entry/src/main/ets/app/AppRoute.ets';
const wardrobe = readRequired(wardrobePath);
const index = readRequired(indexPath);
const appRoute = readRequired(appRoutePath);

for (const removedFile of [
  'entry/src/main/ets/pages/CalendarPage.ets',
  'entry/src/main/ets/components/MonthCalendar.ets'
]) {
  if (fs.existsSync(removedFile)) {
    throw new Error(`${removedFile} should be removed with the old wardrobe calendar tab`);
  }
}

for (const [file, source] of [
  [wardrobePath, wardrobe],
  [indexPath, index],
  [appRoutePath, appRoute]
]) {
  for (const forbidden of [
    'wardrobeTab',
    'selectedWardrobeTab',
    'initialWardrobeTab',
    'WardrobePrimaryTabs',
    'CalendarTab',
    'MonthCalendar',
    'CalendarPage({',
    "params.wardrobeTab = '日历'",
    "'日历'"
  ]) {
    if (source.includes(forbidden)) {
      throw new Error(`${file} must not keep old wardrobe calendar tab concept ${forbidden}`);
    }
  }
}

if (!/SearchEntityType\.WearLog[\s\S]*?params\.wearLogId = id[\s\S]*?this\.showMainRoute\(AppMainTab\.Outfit, params\)/.test(index)) {
  throw new Error('Wear-log search results should open through OutfitsPage, not the removed Wardrobe calendar tab');
}

console.log('PASS');
