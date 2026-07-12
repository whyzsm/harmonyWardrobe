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
  '记录这套美搭的第一眼',
  '整体、细节或上身效果都可以',
  '.aspectRatio(530 / 386)',
  'CameraAction',
  'GalleryAction',
  "SymbolGlyph($r('sys.symbol.camera_fill'))",
  "SymbolGlyph($r('sys.symbol.picture'))",
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

if (!/this\.clothingItemIds\s*=\s*\[\s*\.\.\.this\.initialOutfit\.clothingItemIds\s*\]/.test(editPage)) {
  throw new Error('OutfitEditPage must clone initial clothingItemIds before assigning to state');
}

if (!/this\.photoUris\s*=\s*\[\s*\.\.\.this\.initialOutfit\.photoUris\s*\]/.test(editPage)) {
  throw new Error('OutfitEditPage must clone initial photoUris before assigning to state');
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
  'photoUris',
  'Image(',
  'coverPhotoUri',
  'clothingCategoryLabel',
  "borderRadius(5)",
  "SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))",
  'YibuqueColor.brandCyan'
]) {
  if (!picker.includes(needle)) {
    throw new Error(`ClothingPicker missing ${needle}`);
  }
}

for (const forbidden of [
  'title / 美搭名称',
  'note / 备注',
  'PhotoGrid',
  "Button('拍照')",
  'AppTheme.color.primary'
]) {
  if (editPage.includes(forbidden)) {
    throw new Error(`OutfitEditPage must not include ${forbidden}`);
  }
  if (picker.includes(forbidden)) {
    throw new Error(`ClothingPicker must not include ${forbidden}`);
  }
}

if (!/PhotoSelector\(\)[\s\S]*?Image\(this\.photoUris\[0\]\)[\s\S]*?\.aspectRatio\(530 \/ 386\)[\s\S]*?\.borderRadius\(24\)/.test(editPage)) {
  throw new Error('OutfitEditPage photo area must match the store editor hero layout');
}

if (!/Column\(\{ space: 8 \}\)[\s\S]*?\.width\('100%'\)[\s\S]*?\.padding\(\{ left: 24, right: 24, bottom: 24 \}\)/.test(editPage)) {
  throw new Error('OutfitEditPage photo overlay must be pinned to the image left edge');
}

console.log('PASS');
