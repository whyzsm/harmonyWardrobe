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
  '今天穿什么？',
  '从最近套装里挑一套',
  '记录一次今日搭配',
  '最近穿过',
  'Row({ space: 6 })',
  'Column({ space: 10 })',
  'AppTheme.color.primary',
  'AppTheme.color.primarySoft',
  'AppTheme.color.surface',
  'borderRadius(8)',
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
forbidIncludes('Grid()');
forbidIncludes(".columnsTemplate('1fr 1fr')");
forbidIncludes('.columnsGap(');
forbidIncludes('.rowsGap(');

if (/Text\s*\(\s*this\.todayIsoDate\s*\)/.test(text)) {
  throw new Error(`${file} must not render the date in the top-left home header`);
}

if (!/Text\s*\(\s*'⌕'\s*\)[\s\S]*?\.fontSize\(34\)/.test(text)) {
  throw new Error(`${file} search icon should be larger, matching the Xiaohongshu header treatment`);
}

if (!/Row\s*\(\s*\)\s*\{[\s\S]*?Text\s*\(\s*'☰'\s*\)[\s\S]*?Row\s*\(\s*\{\s*space:\s*26\s*\}\s*\)[\s\S]*?Text\s*\(\s*'⌕'\s*\)/.test(text)) {
  throw new Error(`${file} should keep menu, discovery tabs, and search in one Xiaohongshu-style header row`);
}

console.log('PASS');
