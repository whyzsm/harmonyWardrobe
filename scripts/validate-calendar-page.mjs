import fs from 'node:fs';

const pagePath = 'entry/src/main/ets/pages/CalendarPage.ets';
const calendarPath = 'entry/src/main/ets/components/MonthCalendar.ets';

if (!fs.existsSync(calendarPath)) {
  throw new Error(`${calendarPath} does not exist`);
}

const text = fs.readFileSync(pagePath, 'utf8');
const calendar = fs.readFileSync(calendarPath, 'utf8');

for (const needle of [
  'MonthCalendar',
  'WearLogRepository',
  'listWearLogDatesForMonth',
  'listWearLogsByDate',
  '补录穿着',
  'selectedDate',
  'selectedDateLogs',
  'markedDates',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`CalendarPage missing ${needle}`);
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
