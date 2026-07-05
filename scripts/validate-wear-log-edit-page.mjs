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

for (const forbidden of [
  '选择套装，补充日期、地点、照片和备注。',
  'AppTheme.color.primary',
  'wornDate /',
  'placeText /',
  '选择套装',
  '暂无套装'
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

console.log('PASS');
