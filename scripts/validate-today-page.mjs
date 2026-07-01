import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/TodayPage.ets', 'utf8');

for (const needle of [
  'WearLogRepository',
  'OutfitRepository',
  'WearLog',
  'OutfitTemplate',
  "Text('☰')",
  '推荐',
  '今日',
  '灵感',
  '从最近套装里挑一套',
  '最近穿过',
  '记录一次今日搭配',
  'Row({ space: 6 })',
  'Column({ space: 10 })',
  'Divider()',
  '.backgroundColor(AppTheme.color.surface)',
  'todayIsoDate',
  'todaysWearLog',
  'recentOutfits',
  'recentWearLogs',
  'recordToday',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`TodayPage missing ${needle}`);
  }
}

for (const forbidden of [
  "Text('首页')",
  'Grid()',
  ".columnsTemplate('1fr 1fr')",
  '.columnsGap(',
  '.rowsGap('
]) {
  if (text.includes(forbidden)) {
    throw new Error(`TodayPage still contains ${forbidden}`);
  }
}

if (/Text\s*\(\s*this\.todayIsoDate\s*\)/.test(text)) {
  throw new Error('TodayPage must keep the date out of the home header');
}

console.log('PASS');
