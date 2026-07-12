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
  '今天适合轻外套',
  "Text('22°')",
  'WeatherCard',
  '.padding({ left: 20, right: 20, bottom: 16 })',
  '创建套装',
  '记录一次穿着',
  'filterOutfits',
  'onCreateOutfit',
  'onRecordWear',
  'onNestedPageVisibilityChange',
  "columnsTemplate('1fr 1fr')",
  'OutfitWallCard',
  'wardrobe_look_shirt',
  'wardrobe_look_dress',
  "borderRadius(5)",
  '正在加载套装',
  '重试'
]) {
  if (!text.includes(needle)) {
    throw new Error(`OutfitsPage missing ${needle}`);
  }
}

if (/WeatherCard\(\)[\s\S]*?\.margin\(\{ left: 20, right: 20, bottom: 16 \}\)/.test(text)) {
  throw new Error('OutfitsPage weather card must use container padding instead of overflowing full-width margins');
}

if (!/WeatherCard\(\)[\s\S]*?Row\(\)\s*\{[\s\S]*?Row\(\{ space: 12 \}\)[\s\S]*?\.padding\(\{ left: 20, right: 20, bottom: 16 \}\)/.test(text)) {
  throw new Error('OutfitsPage weather card must align to the waterfall grid horizontal padding');
}

console.log('PASS');
