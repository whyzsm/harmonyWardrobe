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
  'PreferenceSection',
  '我的偏好',
  '常用尺码',
  '常逛商圈',
  '管理常逛商圈',
  '常逛地点',
  '补充地点',
  'DistrictSheet',
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

for (const forbidden of [
  'ProfileSearch',
  'hasSearchResult',
  'searchQuery',
  '没找到这项设置',
  '试穿偏好',
  'StyleTags',
  'StyleTag',
  'fittingPreferenceEnabled',
  'styleTags',
  'commuteSelected',
  'casualSelected',
  'datingSelected',
  'walkingSelected'
]) {
  if (page.includes(forbidden)) {
    throw new Error(`ProfilePage must not include removed settings search logic: ${forbidden}`);
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

if (!/\.enabled\(!this\.isSaving && \(action !== 'size' \|\| !this\.isLoading\)\)/.test(page)) {
  throw new Error('ProfilePage measurement action must be disabled while preferences are saving');
}

if (!/DistrictChip\(label: string, selected: boolean\)[\s\S]*?\.enabled\(!this\.isSaving\)/.test(page)) {
  throw new Error('ProfilePage district chips must be disabled while districts are saving');
}

if (!/ToggleRow\(title: string, subtitle: string, enabled: boolean, action: string\)[\s\S]*?\.enabled\(!this\.isSaving\)/.test(page)) {
  throw new Error('ProfilePage privacy toggle must be disabled while preferences are saving');
}

if (!/DistrictChip\(label: string, selected: boolean\)[\s\S]*?this\.toggleDistrict\(label\)/.test(page)) {
  throw new Error('ProfilePage district chips must toggle saved locations');
}

if (!/ToggleRow\(title: string, subtitle: string, enabled: boolean, action: string\)[\s\S]*?if \(this\.isSaving\) \{[\s\S]*?return;/.test(page)) {
  throw new Error('ProfilePage privacy handler must guard rapid clicks while saving');
}

console.log('PASS');
