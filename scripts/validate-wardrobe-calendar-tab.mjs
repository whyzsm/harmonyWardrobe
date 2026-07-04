import fs from 'node:fs';

function readRequired(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }

  return fs.readFileSync(path, 'utf8');
}

function mustInclude(source, file, needle) {
  if (!source.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustNotInclude(source, file, needle) {
  if (source.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

const wardrobePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const wardrobe = readRequired(wardrobePath);
const index = readRequired(indexPath);

for (const needle of [
  'WearLogRepository',
  'WearLog',
  'MonthCalendar',
  'WearLogEditPage',
  'selectedWardrobeTab',
  '衣橱',
  '美搭',
  '日历',
  'listWearLogDatesForMonth',
  'listWearLogsByDate',
  'MonthCalendar({',
  '今天穿了什么'
]) {
  mustInclude(wardrobe, wardrobePath, needle);
}

for (const forbidden of [
  "import { CalendarPage }",
  'CalendarPage({'
]) {
  mustNotInclude(index, indexPath, forbidden);
}

console.log('PASS');
