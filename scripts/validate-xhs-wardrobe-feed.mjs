import fs from 'node:fs';

const wardrobePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const clothingCardPath = 'entry/src/main/ets/components/ClothingCard.ets';
const outfitCardPath = 'entry/src/main/ets/components/OutfitCard.ets';

const wardrobe = fs.readFileSync(wardrobePath, 'utf8');
const clothingCard = fs.readFileSync(clothingCardPath, 'utf8');
const outfitCard = fs.readFileSync(outfitCardPath, 'utf8');

function requireIncludes(source, label, needle) {
  if (!source.includes(needle)) {
    throw new Error(`${label} missing ${needle}`);
  }
}

function forbidIncludes(source, label, needle) {
  if (source.includes(needle)) {
    throw new Error(`${label} still contains ${needle}`);
  }
}

for (const needle of [
  '搜索衣服、套装、备注',
  '上衣',
  '裤子',
  '短裤',
  '长裙',
  '半裙',
  '先放入第一件衣服',
  'backgroundColor(AppTheme.color.primarySoft)',
  'fontColor(AppTheme.color.primary)',
  'WardrobeSearchHeader',
  'WardrobeSearchTabs',
  'WardrobeSearchResultCard',
  'WaterFlow()',
  'slice(0, WARDROBE_TOP_RESULT_COUNT)',
  'slice(WARDROBE_TOP_RESULT_COUNT)',
  'FlowItem()',
  '.cachedCount(8)',
  '.columnsTemplate(\'1fr 1fr\')',
  '.columnsGap(8)',
  '.rowsGap(8)',
  '.scrollBar(BarState.Off)',
  '.padding({ left: 12, right: 12, top: 28, bottom: 14 })',
  '`NO. ${index + 1}`'
]) {
  requireIncludes(wardrobe, wardrobePath, needle);
}

forbidIncludes(wardrobe, wardrobePath, '管理上衣、裤装、裙装、外套、鞋包和配饰。');
forbidIncludes(wardrobe, wardrobePath, '还没有衣物');
forbidIncludes(wardrobe, wardrobePath, 'GridItem()');
forbidIncludes(wardrobe, wardrobePath, 'SearchBar');
forbidIncludes(wardrobe, wardrobePath, 'CategoryTabs');
forbidIncludes(wardrobe, wardrobePath, 'ClothingCard');
forbidIncludes(wardrobe, wardrobePath, "Text('衣橱')");
forbidIncludes(wardrobe, wardrobePath, '添加衣服');

if (!/FlowItem\s*\(\s*\)\s*\{[\s\S]*?this\.WardrobeSearchResultCard\(item, index \+ WARDROBE_TOP_RESULT_COUNT\)[\s\S]*?\}\s*\.width\('100%'\)/.test(wardrobe)) {
  throw new Error(`${wardrobePath} FlowItem should fill the column and render the search result card`);
}

if (!/ForEach\(this\.visibleClothingItems\(\)\.slice\(0, WARDROBE_TOP_RESULT_COUNT\)[\s\S]*?this\.WardrobeSearchResultCard\(item, index\)/.test(wardrobe)) {
  throw new Error(`${wardrobePath} should render the first results as full-width search cards`);
}

if (!/WaterFlow\s*\(\s*\)[\s\S]*?slice\(WARDROBE_TOP_RESULT_COUNT\)[\s\S]*?\.cachedCount\(8\)[\s\S]*?\.columnsTemplate\('1fr 1fr'\)[\s\S]*?\.columnsGap\(8\)[\s\S]*?\.rowsGap\(8\)[\s\S]*?\.width\('100%'\)/.test(wardrobe)) {
  throw new Error(`${wardrobePath} WaterFlow should render the remaining results as the two-column section`);
}

for (const [file, source] of [
  [clothingCardPath, clothingCard],
  [outfitCardPath, outfitCard]
]) {
  requireIncludes(source, file, 'ImageFit.Cover');
  requireIncludes(source, file, 'borderRadius(8)');
  requireIncludes(source, file, 'AppTheme.color.primarySoft');
  requireIncludes(source, file, 'shadow({');
  forbidIncludes(source, file, '.border({ width: 1, color: AppTheme.color.border })');
  forbidIncludes(source, file, '.padding(12)');
}

console.log('PASS');
