import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/OutfitsPage.ets', 'utf8');

for (const needle of [
  'SearchBar',
  'OutfitCard',
  'EmptyState',
  'OutfitRepository',
  'OutfitTemplate',
  '创建套装',
  '记录一次穿着',
  'filterOutfits',
  'onCreateOutfit',
  'onRecordWear',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`OutfitsPage missing ${needle}`);
  }
}

console.log('PASS');
