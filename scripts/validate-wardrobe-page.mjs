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
  'selectedWardrobeTab',
  "'衣裤'",
  "'美搭'",
  'visibleOutfits',
  'OutfitRepository',
  'OutfitEditPage',
  'WaterFlow()',
  'FlowItem()',
  'WARDROBE_TOP_RESULT_COUNT',
  'slice(0, WARDROBE_TOP_RESULT_COUNT)',
  'slice(WARDROBE_TOP_RESULT_COUNT)',
  "Text('搜索')",
  "'上衣'",
  "'裤子'",
  "'短裤'",
  "'长裙'",
  "'半裙'",
  'Text(item.name)',
  'Text(categoryLabel(item.category))',
  '点击底部 + 的拍衣服',
  '点击底部 + 的拍搭配',
  '.cachedCount(8)',
  ".height('100%')",
  '.scrollable(ScrollDirection.Horizontal)',
  '.scrollBar(BarState.Off)'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WardrobePage missing ${needle}`);
  }
}

if (!/this\.selectedWardrobeTab === '衣裤'[\s\S]*?WaterFlow\(\)/.test(text)) {
  throw new Error('WardrobePage clothing tab should keep the WaterFlow search layout');
}

if (!/this\.selectedWardrobeTab === '美搭'[\s\S]*?Grid\(\)/.test(text)) {
  throw new Error('WardrobePage outfit tab should render a beauty-match grid');
}

if (!/WardrobeSearchTabs\(\)[\s\S]*?Scroll\(\)[\s\S]*?Row\(\{ space: 10 \}\)[\s\S]*?ForEach\(this\.categoryLabels\(\)/.test(text)) {
  throw new Error('Wardrobe search tabs must be wrapped in a horizontal Scroll');
}

for (const forbidden of ['SearchBar', 'CategoryTabs', 'ClothingCard', '添加衣服', '套装', "Text('衣橱')", "Text('search')", "'loading /", "'error /", "Button('retry')", '`NO. ${index + 1}`']) {
  if (text.includes(forbidden)) {
    throw new Error(`WardrobePage should follow the search result layout and omit ${forbidden}`);
  }
}

console.log('PASS');
