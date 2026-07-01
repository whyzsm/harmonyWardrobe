import fs from 'node:fs';

const file = 'entry/src/main/ets/pages/TodayPage.ets';
const text = fs.readFileSync(file, 'utf8');

function requireIncludes(needle) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function forbidIncludes(needle) {
  if (text.includes(needle)) {
    throw new Error(`${file} still contains ${needle}`);
  }
}

for (const needle of [
  '推荐',
  '今日',
  '灵感',
  "Text('☰')",
  '.width(44)',
  '.height(44)',
  '.height(56)',
  'Divider()',
  '.textAlign(TextAlign.Center)',
  '穿搭灵感',
  '衣橱灵感',
  '今日记录',
  '今天穿什么？',
  '从最近套装里挑一套',
  '记录一次今日搭配',
  '最近穿过',
  'Scroll()',
  'Grid()',
  'GridItem()',
  ".columnsTemplate('1fr 1fr')",
  '.columnsGap(8)',
  '.rowsGap(12)',
  '.scrollBar(BarState.Off)',
  'AppTheme.color.primary',
  'AppTheme.color.primarySoft',
  'AppTheme.color.surface',
  'AppTheme.color.surfaceMuted',
  'borderRadius(10)',
  ".border({ width: 1, color: '#1A000000' })",
  '♡',
  'ImageFit.Cover'
]) {
  requireIncludes(needle);
}

forbidIncludes('今天还没有穿搭记录');
forbidIncludes('暂无最近套装');
forbidIncludes('暂无穿着记录');
forbidIncludes('选择套装记录今天');
forbidIncludes("Text('首页')");
forbidIncludes('Column({ space: 14 })');
forbidIncludes('.scrollable(ScrollDirection.Vertical)');

if (/Text\s*\(\s*this\.todayIsoDate\s*\)/.test(text)) {
  throw new Error(`${file} must not render the date in the top-left home header`);
}

if (!/Text\s*\(\s*'⌕'\s*\)[\s\S]*?\.fontSize\(34\)/.test(text)) {
  throw new Error(`${file} search icon should be larger, matching the Xiaohongshu header treatment`);
}

if (!/Row\s*\(\s*\)\s*\{[\s\S]*?Text\s*\(\s*'☰'\s*\)[\s\S]*?Text\s*\(\s*'推荐'\s*\)[\s\S]*?Text\s*\(\s*'⌕'\s*\)[\s\S]*?\}\s*\.width\('100%'\)[\s\S]*?\.height\(56\)/.test(text)) {
  throw new Error(`${file} should keep menu, recommendation tabs, and search in one Xiaohongshu-style header row`);
}

console.log('PASS');
