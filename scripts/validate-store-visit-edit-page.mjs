import fs from 'node:fs';

const file = 'entry/src/main/ets/pages/StoreVisitEditPage.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

for (const needle of [
  '记录逛店',
  '编辑逛店',
  'StoreRepository',
  'PhotoStorage',
  'pickGalleryPhotos',
  'storeName',
  'visitDate',
  'note',
  'photoUris',
  'createStoreVisit',
  'updateStoreVisit',
  'createStore',
  '保存逛店',
  'storeNameSnapshot'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

if (text.includes('WishlistRepository')) {
  throw new Error(`${file} must not import WishlistRepository`);
}

console.log('PASS');
