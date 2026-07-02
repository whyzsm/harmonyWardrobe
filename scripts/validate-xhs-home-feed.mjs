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
  '今日灵感',
  '今天穿什么？',
  '看看推荐穿搭灵感',
  '推荐穿搭',
  '通勤清爽蓝白穿搭',
  '雨天轻便出行穿搭',
  'HomeRecommendation',
  'onOpenRecommendation',
  'openRecommendation',
  'WaterFlow()',
  'FlowItem()',
  ".width('100%')",
  ".height('100%')",
  '.layoutWeight(1)',
  ".columnsTemplate('1fr 1fr')",
  '.columnsGap(8)',
  '.rowsGap(8)',
  '.scrollBar(BarState.Off)',
  'Stack({ alignContent: Alignment.Center })',
  'Circle({ width: 18, height: 18 })',
  'Line()',
  'AppTheme.color.primary',
  'AppTheme.color.primarySoft',
  'AppTheme.color.surface',
  'AppTheme.color.surfaceMuted',
  'borderRadius(10)',
  "shadow({ radius: 8, color: '#0D000000', offsetX: 0, offsetY: 2 })",
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
forbidIncludes("Text('⌕')");
forbidIncludes('Column({ space: 14 })');
forbidIncludes('GridItem()');
forbidIncludes('.scrollable(ScrollDirection.Vertical)');
forbidIncludes('WearLogEditPage');
forbidIncludes('showWearLogEditor');
forbidIncludes('recordToday(');
forbidIncludes('选择套装记录今天');

if (/Text\s*\(\s*this\.todayIsoDate\s*\)/.test(text)) {
  throw new Error(`${file} must not render the date in the top-left home header`);
}

if (text.includes('bottom: 92') || text.includes('bottom: 66')) {
  throw new Error(`${file} should not reserve floating bottom nav whitespace`);
}

if (!/Stack\s*\(\s*\{\s*alignContent:\s*Alignment\.Center\s*\}\s*\)[\s\S]*?Circle\s*\([\s\S]*?Line\s*\(/.test(text)) {
  throw new Error(`${file} search icon should be centered with shapes instead of a baseline-shifted text glyph`);
}

if (!/Row\s*\(\s*\)\s*\{[\s\S]*?Text\s*\(\s*'☰'\s*\)[\s\S]*?HomeTopTab\s*\(\s*0\s*,\s*'推荐'\s*\)[\s\S]*?HomeTopTab\s*\(\s*1\s*,\s*'今日'\s*\)[\s\S]*?HomeTopTab\s*\(\s*2\s*,\s*'灵感'\s*\)[\s\S]*?Stack\s*\(\s*\{\s*alignContent:\s*Alignment\.Center\s*\}\s*\)[\s\S]*?\}\s*\.width\('100%'\)[\s\S]*?\.height\(56\)/.test(text)) {
  throw new Error(`${file} should keep menu, recommendation tabs, and search in one Xiaohongshu-style header row`);
}

if (!/Refresh\s*\(\s*\{\s*refreshing:\s*this\.isRefreshing\s*\}\s*\)[\s\S]*?\.layoutWeight\(1\)[\s\S]*?\.width\('100%'\)/.test(text)) {
  throw new Error(`${file} Refresh container should fill the feed width and remaining height`);
}

if (!/FlowItem\s*\(\s*\)\s*\{[\s\S]*?this\.CardView\(item\)[\s\S]*?\}\s*\.width\('100%'\)/.test(text)) {
  throw new Error(`${file} FlowItem should explicitly fill its WaterFlow column width`);
}

if (!/WaterFlow\s*\(\s*\)[\s\S]*?\.columnsTemplate\('1fr 1fr'\)[\s\S]*?\.columnsGap\(8\)[\s\S]*?\.rowsGap\(8\)[\s\S]*?\.width\('100%'\)[\s\S]*?\.height\('100%'\)[\s\S]*?\.layoutWeight\(1\)/.test(text)) {
  throw new Error(`${file} WaterFlow should follow the HarmonyOS sample sizing pattern`);
}

if (/Text\s*\(\s*item\.placeholder\s*\)[\s\S]*?Text\s*\(\s*item\.title\s*\)[\s\S]*?\.aspectRatio\(item\.aspectRatio\)/.test(text)) {
  throw new Error(`${file} placeholder image area should not render long titles that can widen the column`);
}

if (/\.onClick\s*\(\s*\(\)\s*=>\s*\{[\s\S]*?recordToday/.test(text)) {
  throw new Error(`${file} feed cards should open recommendation detail, not the wear-log editor`);
}

if (!/\.onClick\s*\(\s*\(\)\s*=>\s*\{[\s\S]*?this\.openRecommendation\(item\)/.test(text)) {
  throw new Error(`${file} feed cards should open recommendation detail`);
}

console.log('PASS');
