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
  '我的衣橱内容流',
  '搜索衣服、套装、备注',
  '鞋包',
  '点中间 + 添加第一件衣服',
  '先放入第一件衣服',
  'backgroundColor(AppTheme.color.primarySoft)',
  'fontColor(AppTheme.color.primary)',
  '.columnsTemplate(\'1fr 1fr\')',
  '.padding({ left: 14, right: 14, top: 18, bottom: 14 })'
]) {
  requireIncludes(wardrobe, wardrobePath, needle);
}

forbidIncludes(wardrobe, wardrobePath, '管理上衣、裤装、裙装、外套、鞋包和配饰。');
forbidIncludes(wardrobe, wardrobePath, '还没有衣物');

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
