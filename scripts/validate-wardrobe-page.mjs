import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');

for (const needle of [
  'ClothingRepository',
  'filterClothingItems',
  'onChange',
  'ForEach',
  'WardrobeSearchHeader',
  'designDemoResource',
  'wardrobe_demo_1',
  'OPEN_DESIGN_BLACK',
  'OPEN_DESIGN_SURFACE',
  'OPEN_DESIGN_BORDER',
  'SCREENSHOT_BLUE',
  'WardrobeSearchTabs',
  'CategoryFilterIcon',
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
  'onNestedPageVisibilityChange',
  'WardrobeWaterFlow',
  'WaterFlow()',
  'FlowItem()',
  ".columnsTemplate('1fr 1fr')",
  '.columnsGap(16)',
  '.rowsGap(20)',
  "placeholder: '搜索衣服、裤子、裙子'",
  "'全部'",
  "'上衣'",
  "'裤装'",
  "'裙装'",
  "'包袋'",
  "'待同步'",
  "SymbolGlyph($r('sys.symbol.square_grid_2x2'))",
  "SymbolGlyph($r('sys.symbol.shirt'))",
  "SymbolGlyph($r('sys.symbol.clothing'))",
  "SymbolGlyph($r('sys.symbol.hanger_and_towels'))",
  "SymbolGlyph($r('sys.symbol.bag'))",
  "SymbolGlyph($r('sys.symbol.arrow_left_arrow_right'))",
  'Text(this.displayItemTitle(item, index))',
  'CardCategoryIcon(item.category)',
  'CardCategoryIcon(category: ClothingCategory)',
  '.fontSize(14)',
  '.lineHeight(20)',
  '.maxLines(2)',
  '.borderRadius(5)',
  'Column({ space: 14 })',
  '.padding({ left: 20, right: 20, top: 14, bottom: 0 })',
  '.enterKeyType(EnterKeyType.Search)',
  '.height(48)',
  '.borderRadius(12)',
  'Row({ space: 10 })',
  '.width(76)',
  '.height(42)',
  '点底部相机，选择照片后归类为衣橱',
  '点底部相机，选择照片后归类为美搭',
  ".height('100%')",
  '.scrollable(ScrollDirection.Horizontal)',
  '.scrollBar(BarState.Off)'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WardrobePage missing ${needle}`);
  }
}

if (!/this\.selectedWardrobeTab === '衣裤'[\s\S]*?this\.WardrobeWaterFlow\(\)/.test(text)) {
  throw new Error('WardrobePage clothing tab should use the native WaterFlow layout');
}

if (!/WardrobeWaterFlow\(\)[\s\S]*?WaterFlow\(\)[\s\S]*?ForEach\(this\.visibleClothingItems\(\)[\s\S]*?FlowItem\(\)[\s\S]*?this\.WardrobeSearchResultCard\(item, index\)/.test(text)) {
  throw new Error('Wardrobe waterfall should render clothing cards as native FlowItems');
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

for (const forbidden of ['SearchBar', 'CategoryTabs', 'ClothingCard', '添加衣服', "Text('衣橱')", "Text('search')", "Text('搜索')", "'loading /", "'error /", "Button('retry')", '`NO. ${index + 1}`']) {
  if (text.includes(forbidden)) {
    throw new Error(`WardrobePage should follow the search result layout and omit ${forbidden}`);
  }
}

for (const removedHeader of [
  'homeHeroPressed',
  'openDesignWeekdayLabel',
  'wardrobeCountText',
  "Text('我的衣柜')",
  "Text('一眼看衣服')",
  "SymbolGlyph($r('sys.symbol.camera'))",
  'FilterSlidersIcon'
]) {
  if (text.includes(removedHeader)) {
    throw new Error(`WardrobePage should remove the marked header/category chrome: ${removedHeader}`);
  }
}

for (const legacyCategoryIcon of ["'▦'", "'♙'", "'▥'", "'▱'", 'categoryIcon']) {
  if (text.includes(legacyCategoryIcon)) {
    throw new Error(`Wardrobe category chips should use system SymbolGlyph icons, not ${legacyCategoryIcon}`);
  }
}

for (const oldWaterfall of ['WardrobeTwoColumnWaterfall', 'WardrobeWaterfallColumn', 'wardrobeCardOffset', '.cachedCount(8)', '.rowsGap(24)']) {
  if (text.includes(oldWaterfall)) {
    throw new Error(`WardrobePage should use the native WaterFlow implementation, not ${oldWaterfall}`);
  }
}

for (const fakeCard of ['shouldShowWardrobeDemoCards', 'wardrobeDemoIndexes', 'WardrobeDemoResultCard', 'this.onOpenCapture()']) {
  if (text.includes(fakeCard)) {
    throw new Error(`WardrobePage should only render persisted clothing cards, not ${fakeCard}`);
  }
}

for (const oldCardMeta of ['displayItemMeta', 'designDemoMeta', 'DEMO_META', 'Text(this.displayItemMeta(item, index))']) {
  if (text.includes(oldCardMeta)) {
    throw new Error(`Wardrobe card category should be an image overlay icon, not ${oldCardMeta}`);
  }
}

if (!/WardrobeSearchResultCard\(item: ClothingItem, index: number\)[\s\S]*?CardCategoryIcon\(item\.category\)[\s\S]*?Text\(this\.displayItemTitle\(item, index\)\)[\s\S]*?\.fontSize\(14\)[\s\S]*?\.maxLines\(2\)/.test(text)) {
  throw new Error('Wardrobe card should overlay the category icon and render a compact two-line title');
}

for (const wrongCategoryIcon of ["sys.symbol.list_bullet", "sys.symbol.figure_figure_dress"]) {
  if (text.includes(wrongCategoryIcon)) {
    throw new Error(`Wardrobe category should not use the unrelated system icon ${wrongCategoryIcon}`);
  }
}

for (const forbidden of ['WardrobeMockStatusBar', "Text('9:41')", "Text('⌘')"]) {
  if (text.includes(forbidden)) {
    throw new Error(`WardrobePage should not draw phone status/model artifacts: ${forbidden}`);
  }
}

console.log('PASS');
