import fs from 'node:fs';

const editPagePath = 'entry/src/main/ets/pages/WearLogEditPage.ets';
const pickerPath = 'entry/src/main/ets/components/OutfitPicker.ets';

if (!fs.existsSync(editPagePath)) {
  throw new Error(`${editPagePath} does not exist`);
}

if (!fs.existsSync(pickerPath)) {
  throw new Error(`${pickerPath} does not exist`);
}

const editPage = fs.readFileSync(editPagePath, 'utf8');
const picker = fs.readFileSync(pickerPath, 'utf8');

for (const needle of [
  'OutfitPicker',
  'PhotoPickerAdapter',
  'PhotoStorage',
  'WearLogRepository',
  'PhotoGrid',
  'wornDate',
  'placeText',
  'note',
  'outfitTemplateId',
  'isSaving',
  'canSave',
  'saveWearLog',
  'pickGalleryPhotos',
  'capturePhoto',
  'copyToAppStorage',
  'createWearLog',
  'updateWearLog'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`WearLogEditPage missing ${needle}`);
  }
}

for (const needle of [
  'OutfitPicker',
  'OutfitTemplate',
  'selectedOutfitId',
  'onSelect',
  'ForEach'
]) {
  if (!picker.includes(needle)) {
    throw new Error(`OutfitPicker missing ${needle}`);
  }
}

console.log('PASS');
