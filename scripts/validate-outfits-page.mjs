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

console.log('PASS');
