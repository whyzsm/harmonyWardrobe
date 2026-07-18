import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');

for (const needle of [
  'ClothingRepository',
  'filterClothingItems',
  'onChange',
  'ForEach',
  'WardrobeSearchHeader',
  'displayItemMeta',
  '暂无照片',
  'YibuqueColor.borderMedium',
  'WardrobeSearchTabs',
  'CategoryFilterIcon',
  'WardrobeSearchResultCard',
  'OutfitRepository',
  'onNestedPageVisibilityChange',
  'WardrobeWaterFlow',
  'WaterFlow()',
  'LazyForEach(this.clothingDataSource',
  'FlowItem()',
  ".columnsTemplate('1fr 1fr')",
  '.columnsGap(16)',
  '.rowsGap(15)',
  "placeholder: '搜索衣服、裤子、裙子'",
  "'全部'",
  "'上衣'",
  "'裤装'",
  "'裙装'",
  "SymbolGlyph($r('sys.symbol.square_grid_2x2'))",
  "SymbolGlyph($r('sys.symbol.shirt'))",
  "SymbolGlyph($r('sys.symbol.clothing'))",
  "SymbolGlyph($r('sys.symbol.hanger_and_towels'))",
  'Text(this.displayItemTitle(item))',
  'Text(this.displayItemMeta(item))',
  'CardCategoryIcon(item.category)',
  'CardCategoryIcon(category: ClothingCategory)',
  '.fontSize(14)',
  '.lineHeight(20)',
  '.maxLines(1)',
  '.borderRadius(YibuqueRadius.xxl)',
  'Column({ space: 14 })',
  '.padding({ left: 20, right: 20, top: 14, bottom: 0 })',
  '.enterKeyType(EnterKeyType.Search)',
  '.height(48)',
  '.borderRadius(YibuqueRadius.md)',
  'Row({ space: 10 })',
  '.constraintSize({ minWidth: 76, minHeight: 44 })',
  '点底部相机，选择照片后归类为衣柜',
  ".height('100%')",
  '.scrollable(ScrollDirection.Horizontal)',
  '.scrollBar(BarState.Off)'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WardrobePage missing ${needle}`);
  }
}

if (!/WardrobeWaterFlow\(\)[\s\S]*?WaterFlow\(\)[\s\S]*?LazyForEach\(this\.clothingDataSource[\s\S]*?FlowItem\(\)[\s\S]*?this\.WardrobeSearchResultCard\(item, index\)/.test(text)) {
  throw new Error('Wardrobe waterfall should render clothing cards as lazy native FlowItems');
}

if (!/Text\('先放入第一件衣服'\)[\s\S]*?\.backgroundColor\(YibuqueColor\.cardSoftGray\)[\s\S]*?\.borderRadius\(YibuqueRadius\.xxl\)[\s\S]*?\.border\(\{ width: 1, color: YibuqueColor\.borderMedium \}\)/.test(text)) {
  throw new Error('WardrobePage empty panel must match the store-visit empty-state surface');
}

if (!/WardrobeSearchTabs\(\)[\s\S]*?Scroll\(\)[\s\S]*?Row\(\{ space: 10 \}\)[\s\S]*?ForEach\(this\.categoryLabels\(\)/.test(text)) {
  throw new Error('Wardrobe search tabs must be wrapped in a horizontal Scroll');
}

if (/WardrobeSearchTabs\(\)[\s\S]*?\.width\(76\)/.test(text)) {
  throw new Error('Wardrobe category chips must not use fixed 76vp width');
}

if (!/selectedCategoryLabel === category \? YibuqueColor\.textInverse[\s\S]*?selectedCategoryLabel === category \? YibuqueColor\.actionBlack[\s\S]*?selectedCategoryLabel === category \? YibuqueColor\.actionBlack/.test(text)) {
  throw new Error('Wardrobe category selection must use the black pill and white foreground style');
}

for (const forbidden of [
  'SearchBar',
  'CategoryTabs',
  '添加衣服',
  "Text('衣橱')",
  "Text('search')",
  "Text('搜索')",
  "'loading /",
  "'error /",
  "Button('retry')",
  '`NO. ${index + 1}`',
  'OPEN_DESIGN_',
  'SCREENSHOT_NAV_GRAY',
  "'包袋'",
  "'待同步'",
  'selectedWardrobeTab',
  'initialWardrobeTab',
  "'衣裤'",
  "'美搭'",
  "'日历'",
  'WearLogRepository',
  'MonthCalendar',
  'CalendarTab',
  'WardrobePrimaryTabs',
  'WearLogEditPage',
  'listWearLogDatesForMonth',
  'listWearLogsByDate',
  '今天穿了什么',
  'visibleOutfits',
  'OutfitEditPage',
  'OutfitResultCard'
]) {
  if (text.includes(forbidden)) {
    throw new Error(`WardrobePage should be clothing-only and omit ${forbidden}`);
  }
}

for (const forbiddenPattern of [
  /import\s+\{\s*ClothingCard\s*\}/,
  /ClothingCard\(\{/
]) {
  if (forbiddenPattern.test(text)) {
    throw new Error(`WardrobePage should follow the search result layout and omit ${forbiddenPattern}`);
  }
}

for (const legacySelectionColor of ['SCREENSHOT_BLUE', '#8ABBEA', '#82B3EA', '#A8C9ED']) {
  if (text.includes(legacySelectionColor)) {
    throw new Error(`WardrobePage should not use the legacy blue selection color ${legacySelectionColor}`);
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

for (const fakeCard of ['shouldShowWardrobeDemoCards', 'wardrobeDemoIndexes', 'WardrobeDemoResultCard']) {
  if (text.includes(fakeCard)) {
    throw new Error(`WardrobePage should only render persisted clothing cards, not ${fakeCard}`);
  }
}

if (!/displayItemTitle\(item: ClothingItem\)[\s\S]*?autoNamePattern[\s\S]*?autoNamePattern\.test\(item\.name\)[\s\S]*?categoryLabel/.test(text)) {
  throw new Error('Wardrobe card title must hide timestamps from generated clothing names');
}

if (!/displayItemMeta\(item: ClothingItem\)[\s\S]*?item\.note[\s\S]*?displayItemTitle\(item\) === categoryLabel \? '' : categoryLabel/.test(text)) {
  throw new Error('Wardrobe card meta must prefer notes and avoid repeating an auto-generated category title');
}

if (!/WardrobeSearchResultCard\(item: ClothingItem, index: number\)[\s\S]*?CardCategoryIcon\(item\.category\)[\s\S]*?Row\(\{ space: 8 \}\)[\s\S]*?Text\(this\.displayItemTitle\(item\)\)[\s\S]*?\.layoutWeight\(1\)[\s\S]*?Text\(this\.displayItemMeta\(item\)\)[\s\S]*?\.maxLines\(1\)/.test(text)) {
  throw new Error('Wardrobe card should render title and secondary text in one compact row');
}

for (const forbidden of ['wardrobe_demo_', 'designDemoResource', 'DEMO_META', 'debug://']) {
  if (text.includes(forbidden)) {
    throw new Error(`WardrobePage must not include test data fallback ${forbidden}`);
  }
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
