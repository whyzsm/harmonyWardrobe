import fs from 'node:fs';

const wardrobe = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');

for (const needle of [
  '衣裤',
  '美搭',
  '搜索衣服、裤子、裙子',
  '全部',
  '上衣',
  '裤装',
  '裙装',
  '包袋',
  '待同步',
  'CategoryFilterIcon',
  'designDemoResource',
  "sys.symbol.clothing",
  "sys.symbol.hanger_and_towels",
  'WardrobeWaterFlow',
  'WaterFlow()',
  'FlowItem()',
  ".columnsTemplate('1fr 1fr')",
  '.columnsGap(16)',
  '.rowsGap(15)',
  'visibleOutfits'
]) {
  if (!wardrobe.includes(needle)) {
    throw new Error(`WardrobePage missing ${needle}`);
  }
}

for (const forbidden of [
  '搜索衣服、套装、备注',
  "Text('我的衣柜')",
  'FilterSlidersIcon',
  '一眼看衣服',
  '添加衣服',
  'GridItem() should use WaterFlow',
  'WardrobeTwoColumnWaterfall',
  'WardrobeWaterfallColumn',
  'wardrobeCardOffset',
  'wardrobeDemoIndexes',
  'WardrobeDemoResultCard',
  'sys.symbol.list_bullet',
  'sys.symbol.figure_figure_dress'
]) {
  if (wardrobe.includes(forbidden)) {
    throw new Error(`WardrobePage still contains old wardrobe feed concept ${forbidden}`);
  }
}

for (const forbidden of ['WardrobeMockStatusBar', "Text('9:41')", "Text('⌘')"]) {
  if (wardrobe.includes(forbidden)) {
    throw new Error(`WardrobePage should not keep phone model artifacts ${forbidden}`);
  }
}

console.log('PASS');
