import fs from 'node:fs';

const wardrobePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const removedFiles = [
  'entry/src/main/ets/pages/CalendarPage.ets',
  'entry/src/main/ets/components/MonthCalendar.ets'
];

for (const removedFile of removedFiles) {
  if (fs.existsSync(removedFile)) {
    throw new Error(`${removedFile} should be removed; calendar UI is no longer part of the product surface`);
  }
}

const wardrobe = fs.readFileSync(wardrobePath, 'utf8');
for (const forbidden of [
  'MonthCalendar',
  'CalendarTab',
  'WardrobePrimaryTabs',
  'selectedWardrobeTab',
  'initialWardrobeTab',
  'currentMonth',
  'selectedDate',
  'selectedDateLogs',
  'markedDates',
  'listWearLogDatesForMonth',
  'listWearLogsByDate',
  "'日历'",
  '今天穿了什么'
]) {
  if (wardrobe.includes(forbidden)) {
    throw new Error(`${wardrobePath} should not contain removed calendar surface ${forbidden}`);
  }
}

console.log('PASS');
