import fs from 'node:fs';

const editPagePath = 'entry/src/main/ets/pages/OutfitEditPage.ets';
const pickerPath = 'entry/src/main/ets/components/ClothingPicker.ets';

if (!fs.existsSync(editPagePath)) {
  throw new Error(`${editPagePath} does not exist`);
}

if (!fs.existsSync(pickerPath)) {
  throw new Error(`${pickerPath} does not exist`);
}

const editPage = fs.readFileSync(editPagePath, 'utf8');
const picker = fs.readFileSync(pickerPath, 'utf8');

for (const needle of [
  'PhotoPickerAdapter',
  'PhotoStorage',
  'OutfitRepository',
  'ClothingPicker',
  'PhotoGrid',
  'title',
  'clothingItemIds',
  'note',
  'isSaving',
  'canSave',
  'saveOutfit',
  'pickGalleryPhotos',
  'capturePhoto',
  'copyToAppStorage',
  'createOutfit',
  'updateOutfit'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`OutfitEditPage missing ${needle}`);
  }
}

for (const needle of [
  'ClothingPicker',
  'ClothingItem',
  'selectedIds',
  'onToggle',
  'ForEach',
  'includes'
]) {
  if (!picker.includes(needle)) {
    throw new Error(`ClothingPicker missing ${needle}`);
  }
}

console.log('PASS');
