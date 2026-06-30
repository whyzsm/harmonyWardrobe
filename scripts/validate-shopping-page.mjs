import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/ShoppingPage.ets', 'utf8');

for (const needle of [
  'SearchBar',
  'WishlistCard',
  'EmptyState',
  'WishlistRepository',
  'WishlistItem',
  '心仪单品',
  '门店',
  '添加心愿',
  'filterWishlistItems',
  'selectedWishlistItemId',
  'onCreateWishlistItem',
  'onOpenWishlistItem',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`ShoppingPage missing ${needle}`);
  }
}

console.log('PASS');
