import fs from 'node:fs';

const pagePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const calendarPath = 'entry/src/main/ets/components/MonthCalendar.ets';

if (!fs.existsSync(calendarPath)) {
  throw new Error(`${calendarPath} does not exist`);
}

if (fs.existsSync('entry/src/main/ets/pages/CalendarPage.ets')) {
  throw new Error('CalendarPage.ets should be removed; calendar UI is embedded in WardrobePage');
}

const text = fs.readFileSync(pagePath, 'utf8');
const calendar = fs.readFileSync(calendarPath, 'utf8');

for (const needle of [
  'MonthCalendar',
  'WearLogRepository',
  'listWearLogDatesForMonth',
  'listWearLogsByDate',
  '今天穿了什么？',
  'openWearLogEditor',
  'selectedDate',
  'selectedDateLogs',
  'markedDates',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WardrobePage calendar tab missing ${needle}`);
  }
}

for (const needle of [
  'MonthCalendar',
  'month',
  'markedDates',
  'selectedDate',
  'onSelectDate',
  'buildCalendarDays',
  'ForEach'
]) {
  if (!calendar.includes(needle)) {
    throw new Error(`MonthCalendar missing ${needle}`);
  }
}

console.log('PASS');
