import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');

for (const needle of [
  'SearchBar',
  'CategoryTabs',
  'ClothingCard',
  '点中间 + 添加第一件衣服',
  'ClothingRepository',
  '添加衣服',
  'filterClothingItems',
  'onChange',
  'onSelect',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WardrobePage missing ${needle}`);
  }
}

console.log('PASS');
