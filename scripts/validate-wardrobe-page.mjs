import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');

for (const needle of [
  'ClothingRepository',
  'filterClothingItems',
  'onChange',
  'ForEach',
  'WardrobeSearchHeader',
  'WardrobeSearchTabs',
  'WardrobeSearchResultCard',
  'WaterFlow()',
  'FlowItem()',
  'WARDROBE_TOP_RESULT_COUNT',
  'slice(0, WARDROBE_TOP_RESULT_COUNT)',
  'slice(WARDROBE_TOP_RESULT_COUNT)',
  "Text('search')",
  "'上衣'",
  "'裤子'",
  "'短裤'",
  "'长裙'",
  "'半裙'",
  '`NO. ${index + 1}`',
  '.cachedCount(8)',
  ".height('100%')",
  '.scrollable(ScrollDirection.Horizontal)',
  '.scrollBar(BarState.Off)'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WardrobePage missing ${needle}`);
  }
}

if (text.includes('GridItem()')) {
  throw new Error('WardrobePage should use WaterFlow FlowItem instead of GridItem');
}

if (!/WardrobeSearchTabs\(\)[\s\S]*?Scroll\(\)[\s\S]*?Row\(\{ space: 10 \}\)[\s\S]*?ForEach\(this\.categoryLabels\(\)/.test(text)) {
  throw new Error('Wardrobe search tabs must be wrapped in a horizontal Scroll');
}

for (const forbidden of ['SearchBar', 'CategoryTabs', 'ClothingCard', '添加衣服', "Text('衣橱')"]) {
  if (text.includes(forbidden)) {
    throw new Error(`WardrobePage should follow the search result layout and omit ${forbidden}`);
  }
}

console.log('PASS');
