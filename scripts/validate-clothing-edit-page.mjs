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
  'generatedName',
  'normalizedName',
  'formatTimeForName',
  'pickGalleryPhotos',
  'PhotoViewPicker',
  'maxSelectNumber = 1',
  'copyToAppStorage',
  'createClothing',
  'updateClothing',
  'YibuqueColor',
  'YibuqueRadius',
  'YibuqueShadow',
  'YibuqueColor.actionBlack',
  '添加衣服照片',
  '基础信息（选填）',
  '自动生成衣物名称，可修改',
  '分类',
  '备注',
  '购买信息',
  '购买门店',
  '价格',
  '购买备注',
  '保存衣服'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`ClothingEditPage missing ${needle}`);
  }
}

for (const forbidden of [
  "Button('拍照')",
  'capturePhoto()',
  'name / 衣物名称',
  'category / 分类',
  'note / 备注',
  'purchase / 购买信息',
  'storeName / 门店',
  'price / 价格',
  'purchase note / 购买备注',
  'AppTheme.color.primary'
]) {
  if (editPage.includes(forbidden)) {
    throw new Error(`ClothingEditPage must not include ${forbidden}`);
  }
}

if (!/canSave\(\)\s*:\s*boolean\s*{[\s\S]*?return\s+!this\.isSaving\s*&&\s*this\.hasSelectedPhoto\(\)/.test(editPage)) {
  throw new Error('ClothingEditPage save gate must only require a selected photo');
}

if (!/this\.name\s*=\s*this\.generatedName\(\)/.test(editPage)) {
  throw new Error('ClothingEditPage must auto-fill a generated name after photo selection');
}

if (!/name:\s*this\.normalizedName\(\)/.test(editPage)) {
  throw new Error('ClothingEditPage must save a normalized/generated name');
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
