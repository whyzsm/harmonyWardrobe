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
  '衣橱 / + / 逛店',
  '拍衣服',
  '拍搭配',
  '拍店铺',
  '衣裤 / 美搭',
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

console.log('PASS');
