import fs from 'node:fs';

const editPagePath = 'entry/src/main/ets/pages/ClothingEditPage.ets';
const wardrobePagePath = 'entry/src/main/ets/pages/WardrobePage.ets';

if (!fs.existsSync(editPagePath)) {
  throw new Error(`${editPagePath} does not exist`);
}

const editPage = fs.readFileSync(editPagePath, 'utf8');
const wardrobePage = fs.readFileSync(wardrobePagePath, 'utf8');

for (const needle of [
  'PhotoPickerAdapter',
  'PhotoStorage',
  'ClothingRepository',
  'PhotoGrid',
  'name',
  'category',
  'purchase',
  'storeName',
  'price',
  'purchaseDate',
  'note',
  'isSaving',
  'canSave',
  'saveClothing',
  'pickGalleryPhotos',
  'capturePhoto',
  'copyToAppStorage',
  'createClothing',
  'updateClothing'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`ClothingEditPage missing ${needle}`);
  }
}

for (const needle of [
  'ClothingEditPage',
  'showEditor',
  'editingClothingId',
  '添加衣服',
  'onEdit',
  'onCancel'
]) {
  if (!wardrobePage.includes(needle)) {
    throw new Error(`WardrobePage missing clothing edit integration: ${needle}`);
  }
}

console.log('PASS');
