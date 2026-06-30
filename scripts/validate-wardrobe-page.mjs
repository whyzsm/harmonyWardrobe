import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');

for (const needle of [
  'SearchBar',
  'CategoryTabs',
  'ClothingCard',
  'EmptyState',
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
