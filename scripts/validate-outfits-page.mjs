import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/OutfitsPage.ets', 'utf8');

for (const needle of [
  'OutfitEmptyState',
  'OutfitRepository',
  'OutfitTemplate',
  "{ label: '全部' }",
  "{ label: '逛街'",
  "{ label: '周末'",
  "{ label: '通勤'",
  '从已有单品开始搭配',
  '先添加衣物再创建套装',
  'OutfitGuideCard',
  'this.clothingItems.length',
  '.padding({ left: 20, right: 20, bottom: 16 })',
  '记录一次穿着',
  'filterOutfits',
  'onRecordWear',
  'onNestedPageVisibilityChange',
  "columnsTemplate('1fr 1fr')",
  'OutfitWallCard',
  '暂无照片',
  "borderRadius(5)",
  '正在加载套装',
  '重试',
  '拍照或从相册选图后，按分类收进套装。',
  '点底部相机，选择照片后归类为套装',
  '套装会按图片组合流排在这里。'
]) {
  if (!text.includes(needle)) {
    throw new Error(`OutfitsPage missing ${needle}`);
  }
}

if (/OutfitGuideCard\(\)[\s\S]*?\.margin\(\{ left: 20, right: 20, bottom: 16 \}\)/.test(text)) {
  throw new Error('OutfitsPage guide card must use container padding instead of overflowing full-width margins');
}

if (!/OutfitGuideCard\(\)[\s\S]*?Row\(\)\s*\{[\s\S]*?Row\(\{ space: 12 \}\)[\s\S]*?\.padding\(\{ left: 20, right: 20, bottom: 16 \}\)/.test(text)) {
  throw new Error('OutfitsPage guide card must align to the waterfall grid horizontal padding');
}

if (/wardrobe_look_|debug:\/\/|Text\('22°'\)/.test(text)) {
  throw new Error('OutfitsPage must not render sample outfits or hard-coded weather data');
}

if (/Button\('创建套装'\)/.test(text)) {
  throw new Error('OutfitsPage empty state must not render a create-outfit button');
}

if (!/else if \(this\.outfits\.length === 0\) \{[\s\S]*?\.justifyContent\(FlexAlign\.Start\)/.test(text)) {
  throw new Error('OutfitsPage empty state must align below the weather card instead of centering vertically');
}

const emptyStateBuilder = text.match(/OutfitEmptyState\(title: string, description: string, guideTitle: string, guideDescription: string\) \{([\s\S]*?)\n  \}\n\n  @Builder\n  FilterStrip/)?.[1] ?? '';

if (!/Column\(\{ space: 10 \}\)[\s\S]*?Column\(\{ space: 8 \}\)[\s\S]*?\.fontSize\(36\)[\s\S]*?\.height\(190\)[\s\S]*?\.backgroundColor\(SURFACE_WARM\)[\s\S]*?\.borderRadius\(18\)[\s\S]*?\.border\(\{ width: 1, color: BORDER \}\)[\s\S]*?Text\(guideTitle\)[\s\S]*?\.fontSize\(15\)[\s\S]*?Text\(guideDescription\)[\s\S]*?\.fontSize\(12\)[\s\S]*?\.backgroundColor\(PAGE_BG\)/.test(emptyStateBuilder)) {
  throw new Error('OutfitsPage empty state must match the wardrobe empty layout');
}

console.log('PASS');
