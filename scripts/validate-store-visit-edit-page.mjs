import fs from 'node:fs';

const file = 'entry/src/main/ets/pages/StoreVisitEditPage.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

for (const needle of [
  '记录逛店',
  '编辑逛店',
  'StoreRepository',
  'PhotoStorage',
  'pickGalleryPhotos',
  'storeName',
  'visitDate',
  'note',
  'photoUris',
  'createStoreVisit',
  'updateStoreVisit',
  'createStore',
  '保存逛店',
  'storeNameSnapshot',
  'YibuqueColor',
  'YibuqueRadius',
  'YibuqueShadow',
  'YibuqueColor.actionBlack',
  '小记',
  '写一点小记',
  '选填信息',
  '地址或商圈'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

if (/canSave\(\)\s*:\s*boolean\s*{[\s\S]*?storeName\.trim\(\)\.length\s*>\s*0/.test(text)) {
  throw new Error(`${file} must not require storeName to save`);
}

if (!/generatedStore|fallbackStore|逛店\s+\$\{|未命名店铺/.test(text)) {
  throw new Error(`${file} must provide a default store visit name`);
}

for (const forbidden of [
  'WishlistRepository',
  'note / 备注',
  '试穿备注',
  'AppTheme.color.primary'
]) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

console.log('PASS');
