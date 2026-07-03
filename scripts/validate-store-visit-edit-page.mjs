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
  '店铺信息',
  '地址或商圈',
  '试穿备注'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

for (const forbidden of [
  'WishlistRepository',
  'note / 备注',
  'AppTheme.color.primary'
]) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

console.log('PASS');
