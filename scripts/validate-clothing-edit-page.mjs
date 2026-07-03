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
  'name',
  'category',
  'previewPhotoUri',
  'PhotoSelector',
  "Text('封面')",
  'purchase',
  'storeName',
  'price',
  'purchaseDate',
  'note',
  'isSaving',
  'canSave',
  'saveClothing',
  'pickGalleryPhotos',
  'PhotoViewPicker',
  'maxSelectNumber = 1',
  'copyToAppStorage',
  'createClothing',
  'updateClothing'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`ClothingEditPage missing ${needle}`);
  }
}

for (const forbidden of [
  "Button('拍照')",
  'capturePhoto()'
]) {
  if (editPage.includes(forbidden)) {
    throw new Error(`ClothingEditPage must not include ${forbidden}`);
  }
}

if (!/this\.previewPhotoUri\s*=\s*selectedUri;[\s\S]*?this\.photoUris\s*=\s*\[\s*selectedUri\s*\];[\s\S]*?try\s*{[\s\S]*?copySourcesToLocalUris/.test(editPage)) {
  throw new Error('ClothingEditPage must keep the selected gallery URI before attempting local copy');
}

if (!/catch\s*\(\s*copyError\s*\)[\s\S]*?PhotoViewPicker\.copy failed/.test(editPage)) {
  throw new Error('ClothingEditPage must not clear selected photos when local copy fails');
}

for (const needle of [
  'ClothingEditPage',
  'showEditor',
  'editingClothingId',
  'openCreateEditor',
  'onEdit',
  'onCancel'
]) {
  if (!wardrobePage.includes(needle)) {
    throw new Error(`WardrobePage missing clothing edit integration: ${needle}`);
  }
}

console.log('PASS');
