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
  '穿搭灵感',
  '衣橱灵感',
  '今日记录',
  'Row({ space: 8 })',
  'Column({ space: 14 })',
  'Divider()',
  '.backgroundColor(AppTheme.color.surface)',
  '.borderRadius(14)',
  '.borderRadius(10)',
  ".border({ width: 1, color: '#1A000000' })",
  ".shadow({ radius: 10, color: '#0D000000', offsetX: 0, offsetY: 2 })",
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
