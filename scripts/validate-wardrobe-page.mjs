import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');

for (const needle of [
  'ClothingRepository',
  'filterClothingItems',
  'onChange',
  'ForEach',
  'WardrobeSearchHeader',
  'WardrobeHomeHero',
  'HeroMetric',
  'homeHeroOpacity',
  'homeHeroTranslateY',
  'homeHeroPressed',
  'WARDROBE_HERO_PREVIEW_COUNT',
  'heroPreviewPhotoUris',
  'wardrobeHeroText',
  "Text('今日衣橱')",
  "Text('轻整理')",
  '点底部相机，先保存照片再归类',
  '.opacity(this.homeHeroOpacity)',
  '.translate({ y: this.homeHeroTranslateY })',
  '.scale({ x: this.homeHeroPressed ? 0.98 : 1.0',
  'WardrobeSearchTabs',
  'WardrobeSearchResultCard',
  'selectedWardrobeTab',
  'initialWardrobeTab',
  "'衣橱'",
  "'衣裤'",
  "'美搭'",
  "'日历'",
  'WearLogRepository',
  'MonthCalendar',
  'WearLogEditPage',
  'listWearLogDatesForMonth',
  'listWearLogsByDate',
  '今天穿了什么',
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
  '点底部相机，选择照片后归类为衣橱',
  '点底部相机，选择照片后归类为美搭',
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

if (!/initialWardrobeTab[\s\S]*?selectedWardrobeTab\s*=\s*this\.initialWardrobeTab/.test(text)) {
  throw new Error('WardrobePage must honor the initial tab after capture save');
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
