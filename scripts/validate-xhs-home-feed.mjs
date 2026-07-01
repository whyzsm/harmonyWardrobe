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
  '首页',
  '推荐',
  '今日',
  '灵感',
  '.width(44)',
  '.height(44)',
  '.textAlign(TextAlign.Center)',
  '今天穿什么？',
  '从最近套装里挑一套',
  '记录一次今日搭配',
  '最近穿过',
  'Grid()',
  ".columnsTemplate('1fr 1fr')",
  'AppTheme.color.primary',
  'AppTheme.color.primarySoft',
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

if (/Text\s*\(\s*this\.todayIsoDate\s*\)/.test(text)) {
  throw new Error(`${file} must not render the date in the top-left home header`);
}

if (!/Text\s*\(\s*'⌕'\s*\)[\s\S]*?\.fontSize\(32\)/.test(text)) {
  throw new Error(`${file} search icon should be larger, matching the Xiaohongshu header treatment`);
}

console.log('PASS');
