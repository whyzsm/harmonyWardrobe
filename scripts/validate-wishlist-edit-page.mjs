import fs from 'node:fs';

const editPagePath = 'entry/src/main/ets/pages/WishlistEditPage.ets';

if (!fs.existsSync(editPagePath)) {
  throw new Error(`${editPagePath} does not exist`);
}

const text = fs.readFileSync(editPagePath, 'utf8');

for (const needle of [
  'PhotoPickerAdapter',
  'PhotoStorage',
  'WishlistRepository',
  'PhotoGrid',
  'WishlistItem',
  'title',
  'storeName',
  'price',
  'note',
  'isSaving',
  'canSave',
  'saveWishlistItem',
  'pickGalleryPhotos',
  'capturePhoto',
  'copyToAppStorage',
  'createWishlistItem',
  'updateWishlistItem'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WishlistEditPage missing ${needle}`);
  }
}

console.log('PASS');
