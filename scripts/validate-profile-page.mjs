import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }
  return fs.readFileSync(file, 'utf8');
}

const page = read('entry/src/main/ets/pages/ProfilePage.ets');
const index = read('entry/src/main/ets/pages/Index.ets');

for (const needle of [
  'ProfileHero',
  '我的衣柜档案',
  '周末逛店计划',
  'ProfileStats',
  '件单品',
  '次逛店',
  '套搭配',
  '找尺码、预算、商场、提醒',
  'PreferenceSection',
  '我的偏好',
  '常用尺码',
  '试穿偏好',
  '常逛商圈',
  'BudgetSection',
  '本月逛街预算',
  'ToolSection',
  '新增逛店',
  '拍照录入',
  '套装清单',
  'ReminderSection',
  '本地与隐私',
  '本地照片与记录',
  'ProfileRepository',
  'getProfile',
  'saveProfile',
  'ClothingRepository',
  'listClothing',
  'StoreRepository',
  'listStoreVisits',
  'OutfitRepository',
  'listOutfits',
  'wardrobePhotoUris',
  'wardrobeItemCount',
  'storeVisitCount',
  'outfitCount',
  '身高',
  '体重',
  '腰围',
  'isSaving',
  'LoadingProgress()',
  'hasInvalidMeasurements',
  'measurementError',
  '请输入数字',
  'bottom: 132'
]) {
  if (!page.includes(needle)) {
    throw new Error(`ProfilePage missing ${needle}`);
  }
}

for (const forbidden of [
  '联网后自动同步',
  '常逛商场会同步到逛店记录',
  "Text('36')",
  "Text('12')",
  "Text('8')",
  '2,050',
  '3,200',
  '64%',
  '导出清单',
  '备份衣柜数据'
]) {
  if (page.includes(forbidden)) {
    throw new Error(`ProfilePage must not include ${forbidden}`);
  }
}

for (const needle of [
  'ProfilePage({',
  'profileRepository: this.runtime.profileRepository',
  'clothingRepository: this.runtime.clothingRepository',
  'storeRepository: this.runtime.storeRepository',
  'outfitRepository: this.runtime.outfitRepository',
  'onOpenStoreEditor',
  'onOpenCapture',
  'onOpenOutfits',
  'onNestedPageVisibilityChange'
]) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing ${needle}`);
  }
}

console.log('PASS');
