import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/TodayPage.ets', 'utf8');

for (const needle of [
  'ClothingRepository',
  'ClothingItem',
  'WearLogRepository',
  'OutfitRepository',
  'WearLog',
  'OutfitTemplate',
  "SymbolGlyph($r('sys.symbol.list_bullet'))",
  "SymbolGlyph($r('sys.symbol.magnifyingglass'))",
  'CardPlaceholderIcon',
  'CardTypeIcon',
  '推荐',
  '今日',
  '灵感',
  '看看推荐穿搭灵感',
  '推荐穿搭',
  '通勤清爽蓝白穿搭',
  '雨天轻便出行穿搭',
  '穿搭灵感',
  '衣橱灵感',
  '今日灵感',
  'HomeRecommendation',
  'imageUris',
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
  'Divider()',
  '.backgroundColor(AppTheme.color.surface)',
  "shadow({ radius: 8, color: '#0D000000', offsetX: 0, offsetY: 2 })",
  'todayIsoDate',
  'todaysWearLog',
  'recentClothingItems',
  'recentOutfits',
  'recentWearLogs',
  'clothingRepository.listClothing()',
  "type: 'clothing'",
  '衣橱单品',
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
  '.scrollable(ScrollDirection.Vertical)',
  'WearLogEditPage',
  'showWearLogEditor',
  'recordToday(',
  '选择套装记录今天'
]) {
  if (text.includes(forbidden)) {
    throw new Error(`TodayPage still contains ${forbidden}`);
  }
}

if (/Text\s*\(\s*this\.todayIsoDate\s*\)/.test(text)) {
  throw new Error('TodayPage must keep the date out of the home header');
}

if (!/Stack\s*\(\s*\{\s*alignContent:\s*Alignment\.Center\s*\}\s*\)[\s\S]*?SymbolGlyph\(\$r\('sys\.symbol\.magnifyingglass'\)\)/.test(text)) {
  throw new Error('TodayPage should use the system search icon');
}

for (const forbidden of ["Text('☰')", 'Circle({', 'Line()']) {
  if (text.includes(forbidden)) {
    throw new Error(`TodayPage should use system icons instead of ${forbidden}`);
  }
}

if (text.includes('bottom: 92') || text.includes('bottom: 66')) {
  throw new Error('TodayPage should not reserve floating bottom nav whitespace');
}

if (!/Refresh\s*\(\s*\{\s*refreshing:\s*this\.isRefreshing\s*\}\s*\)[\s\S]*?\.layoutWeight\(1\)[\s\S]*?\.width\('100%'\)/.test(text)) {
  throw new Error('TodayPage Refresh should fill the feed width and remaining height');
}

if (!/FlowItem\s*\(\s*\)\s*\{[\s\S]*?this\.CardView\(item\)[\s\S]*?\}\s*\.width\('100%'\)/.test(text)) {
  throw new Error('TodayPage FlowItem should explicitly fill its WaterFlow column width');
}

if (!/WaterFlow\s*\(\s*\)[\s\S]*?\.columnsTemplate\('1fr 1fr'\)[\s\S]*?\.columnsGap\(8\)[\s\S]*?\.rowsGap\(8\)[\s\S]*?\.width\('100%'\)[\s\S]*?\.height\('100%'\)[\s\S]*?\.layoutWeight\(1\)/.test(text)) {
  throw new Error('TodayPage WaterFlow should follow the HarmonyOS sample sizing pattern');
}

if (/Text\s*\(\s*item\.placeholder\s*\)[\s\S]*?Text\s*\(\s*item\.title\s*\)[\s\S]*?\.aspectRatio\(item\.aspectRatio\)/.test(text)) {
  throw new Error('TodayPage placeholder image area should not render long titles that can widen the column');
}

if (/\.onClick\s*\(\s*\(\)\s*=>\s*\{[\s\S]*?recordToday/.test(text)) {
  throw new Error('TodayPage feed cards should open recommendation detail, not the wear-log editor');
}

if (!/\.onClick\s*\(\s*\(\)\s*=>\s*\{[\s\S]*?this\.openRecommendation\(item\)/.test(text)) {
  throw new Error('TodayPage feed cards should open recommendation detail');
}

console.log('PASS');
