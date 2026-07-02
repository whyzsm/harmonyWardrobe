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
  'WaterFlow()',
  'FlowItem()',
  ".columnsTemplate('1fr 1fr')",
  '.columnsGap(8)',
  '.rowsGap(8)',
  'Divider()',
  '.backgroundColor(AppTheme.color.surface)',
  "shadow({ radius: 8, color: '#0D000000', offsetX: 0, offsetY: 2 })",
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
  "Text('⌕')",
  'Column({ space: 14 })',
  'GridItem()',
  '.scrollable(ScrollDirection.Vertical)'
]) {
  if (text.includes(forbidden)) {
    throw new Error(`TodayPage still contains ${forbidden}`);
  }
}

if (/Text\s*\(\s*this\.todayIsoDate\s*\)/.test(text)) {
  throw new Error('TodayPage must keep the date out of the home header');
}

if (!/Stack\s*\(\s*\{\s*alignContent:\s*Alignment\.Center\s*\}\s*\)[\s\S]*?Circle\s*\([\s\S]*?Line\s*\(/.test(text)) {
  throw new Error('TodayPage should use a centered shape-based search icon, not a text glyph');
}

if (text.includes('bottom: 92') || text.includes('bottom: 66')) {
  throw new Error('TodayPage should not reserve floating bottom nav whitespace');
}

console.log('PASS');
