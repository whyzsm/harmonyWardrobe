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
  'PhotoSelector',
  'hasSelectedPhoto',
  'normalizedTitle',
  'formatTimeForTitle',
  'pickGalleryPhotos',
  'capturePhoto',
  'copyToAppStorage',
  'createOutfit',
  'updateOutfit',
  'YibuqueColor',
  'YibuqueRadius',
  'YibuqueShadow',
  'YibuqueColor.actionBlack',
  '添加搭配照片',
  '图片必填，其余信息都可选填',
  '美搭信息（选填）',
  '美搭名称，可不填',
  '备注',
  '保存美搭',
  '先添加照片'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`OutfitEditPage missing ${needle}`);
  }
}

if (!/canSave\(\)\s*:\s*boolean\s*{[\s\S]*?return\s+!this\.isSaving\s*&&\s*this\.photoUris\.length\s*>\s*0/.test(editPage)) {
  throw new Error('OutfitEditPage save gate must only require at least one photo');
}

if (editPage.includes('this.title.trim().length > 0 &&')) {
  throw new Error('OutfitEditPage must not require a title to save');
}

if (!/title:\s*this\.normalizedTitle\(\)/.test(editPage)) {
  throw new Error('OutfitEditPage must save a normalized/generated title');
}

for (const needle of [
  'ClothingPicker',
  'ClothingItem',
  'selectedIds',
  'onToggle',
  'ForEach',
  'includes',
  'YibuqueColor.actionBlack'
]) {
  if (!picker.includes(needle)) {
    throw new Error(`ClothingPicker missing ${needle}`);
  }
}

for (const forbidden of [
  'title / 美搭名称',
  'note / 备注',
  'AppTheme.color.primary'
]) {
  if (editPage.includes(forbidden)) {
    throw new Error(`OutfitEditPage must not include ${forbidden}`);
  }
  if (picker.includes(forbidden)) {
    throw new Error(`ClothingPicker must not include ${forbidden}`);
  }
}

console.log('PASS');
