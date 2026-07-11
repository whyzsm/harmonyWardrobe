import fs from 'node:fs';

const seedPath = 'entry/src/main/ets/data/debug/SeedData.ets';
const qaPath = 'docs/qa/manual-test-script.md';

const seed = fs.readFileSync(seedPath, 'utf8');
for (const needle of [
  'seedClothing',
  'seedOutfits',
  'seedWearLogs',
  'seedWishlist',
  'ClothingRepository',
  'OutfitRepository',
  'WearLogRepository',
  'WishlistRepository'
]) {
  if (!seed.includes(needle)) {
    throw new Error(`SeedData missing ${needle}`);
  }
}

const qa = fs.readFileSync(qaPath, 'utf8');
for (const needle of [
  '衣不缺',
  '衣柜 / 逛店 / 相机 / 套装 / 我的',
  '拍照',
  '从相册选择',
  '归类为 `衣橱`',
  '归类为 `美搭`',
  '归类为 `店铺`',
  '全宽搜索框',
  '双列原生瀑布流',
  '图片左上角显示分类图标',
  '逛店',
  '我的',
  '身高',
  '体重',
  '腰围',
  '离线'
]) {
  if (!qa.includes(needle)) {
    throw new Error(`QA script missing ${needle}`);
  }
}

for (const removedHomeChrome of ['`我的衣柜` 标题', '黑色筛选按钮', '`一眼看衣服` 标题']) {
  if (qa.includes(removedHomeChrome)) {
    throw new Error(`QA script should not describe removed wardrobe chrome: ${removedHomeChrome}`);
  }
}

console.log('PASS');
