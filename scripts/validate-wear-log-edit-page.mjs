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
  'PhotoCarousel',
  'MAX_USER_PHOTOS',
  'remainingPhotoSlots',
  'appendPhotoUris',
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
  'updateWearLog',
  '每日穿搭',
  '小记',
  'YibuqueColor.actionBlack'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`WearLogEditPage missing ${needle}`);
  }
}

if (/canSave\(\)\s*:\s*boolean\s*{[\s\S]*?outfitTemplateId\.length\s*>\s*0/.test(editPage)) {
  throw new Error('WearLogEditPage must not require an outfit to save a daily wear log');
}

if (!/this\.photoUris\s*=\s*\[\s*\.\.\.this\.initialWearLog\.photoUris\s*\]/.test(editPage)) {
  throw new Error('WearLogEditPage must clone initial wear log photoUris before assigning to state');
}

if (!/canSave\(\)\s*:\s*boolean\s*{[\s\S]*?wornDate\.trim\(\)\.length\s*>\s*0[\s\S]*?\(this\.photoUris\.length\s*>\s*0\s*\|\|[\s\S]*?this\.note\.trim\(\)\.length\s*>\s*0/.test(editPage)) {
  throw new Error('WearLogEditPage save gate must require a date and either a photo or note');
}

if (!/canSave\(\)\s*:\s*boolean\s*{[\s\S]*?return\s+!this\.isSaving\s*&&\s*!this\.isChoosingPhotos\s*&&\s*!this\.isDeleting/.test(editPage)) {
  throw new Error('WearLogEditPage save gate must block concurrent photo selection');
}

for (const forbidden of [
  '记录穿着，补充日期、地点、照片和备注。',
  'AppTheme.color.primary',
  'wornDate /',
  'placeText /',
  '选择美搭',
  '暂无美搭'
]) {
  if (editPage.includes(forbidden) || picker.includes(forbidden)) {
    throw new Error(`WearLog flow should use Yibuque photo-first copy and tokens, not ${forbidden}`);
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

if (!/@State private isChoosingPhotos: boolean = false;/.test(editPage)) {
  throw new Error('WearLogEditPage must track photo picker re-entry while choosing photos');
}

function readAsyncMethod(source, name) {
  const start = source.indexOf(`private async ${name}(): Promise<void> {`);
  if (start < 0) {
    throw new Error(`WearLogEditPage missing ${name}`);
  }
  const end = source.indexOf('\n  private ', start + 1);
  return source.slice(start, end < 0 ? source.length : end);
}

for (const [name, fallbackMessage] of [
  ['pickGalleryPhotos', '选择照片失败'],
  ['capturePhoto', '拍照失败']
]) {
  const method = readAsyncMethod(editPage, name);
  if (!method.includes('this.photoPickerAdapter === undefined || this.isChoosingPhotos || this.isSaving || this.isDeleting')) {
    throw new Error(`WearLogEditPage ${name} must reject concurrent photo operations and saves`);
  }
  for (const needle of [
    'this.isChoosingPhotos = true;',
    'try {',
    'catch (error) {',
    `this.errorMessage = userFacingError(error, '${fallbackMessage}')`,
    'finally {',
    'this.isChoosingPhotos = false;'
  ]) {
    if (!method.includes(needle)) {
      throw new Error(`WearLogEditPage ${name} must use try/catch/finally for photo errors`);
    }
  }
}

if ((editPage.match(/\.enabled\(!this\.isChoosingPhotos && !this\.isSaving && !this\.isDeleting\)/g) ?? []).length < 2) {
  throw new Error('WearLogEditPage camera and gallery actions must be disabled during photo selection or save');
}

console.log('PASS');
