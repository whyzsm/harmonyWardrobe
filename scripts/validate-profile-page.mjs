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
  'TX 淮海',
  '补充地点',
  'DistrictSheet',
  'BudgetSection',
  '本月逛店预算',
  'BudgetSheet',
  'BudgetChip',
  '调整本月预算',
  'openBudgetEditor',
  'saveBudget',
  'commonBudgets',
  'removeBudget',
  'MAX_COMMON_ITEMS',
  'monthlySpent',
  'budgetProgressPercent',
  'WishlistSection',
  '我的清单',
  '心愿清单',
  '计划购买',
  'LocalStorageSection',
  '本地存储',
  '本地照片与记录',
  "SymbolGlyph($r('sys.symbol.xmark'))",
  'ProfileRepository',
  'getProfile',
  'saveProfile',
  'ClothingRepository',
  'ClothingSummary',
  'getClothingSummary',
  'StoreRepository',
  'getStoreVisitCount',
  'OutfitRepository',
  'getOutfitCount',
  'wardrobeItemCount',
  'storeVisitCount',
  'outfitCount',
  '本月 ${formatBudgetAmount(this.monthlyBudget)}',
  'formatBudgetAmount(this.budgetRemaining())',
  '本月剩余预算',
  '身高',
  '体重',
  '腰围',
  '常用衣物尺码',
  '上衣',
  '裤装',
  '鞋',
  'upperSize',
  'lowerSize',
  'shoeSize',
  'SizeField',
  '保存后会显示在“我的偏好”的常用尺码中。',
  'isSaving',
  'LoadingProgress()',
  'hasInvalidMeasurements',
  'measurementError',
  '请输入数字',
  'PROFILE_HEIGHT_MIN_CM',
  'PROFILE_HEIGHT_MAX_CM',
  'PROFILE_WEIGHT_MIN_KG',
  'PROFILE_WEIGHT_MAX_KG',
  'PROFILE_WAIST_MIN_CM',
  'PROFILE_WAIST_MAX_CM',
  'parseHeightCm',
  'parseWeightKg',
  'parseWaistCm',
  '填写合理数字',
  '.margin({ top: 14, bottom: 14 })',
  'bottom: 132'
]) {
  if (!page.includes(needle)) {
    throw new Error(`ProfilePage missing ${needle}`);
  }
}

for (const forbidden of [
  'loadWardrobeSummary',
  'listClothing()',
  'listStoreVisits()',
  'listOutfits()'
]) {
  if (page.includes(forbidden)) {
    throw new Error(`ProfilePage activity summary must not use full-list loading: ${forbidden}`);
  }
}

if (!/getClothingSummary\(currentYearMonth\(\)\)/.test(page)) {
  throw new Error('ProfilePage must request the lightweight clothing summary for the current month');
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
  '今天常用',
  '新增逛店',
  '拍照录入',
  '穿搭清单',
  '消费记录暂未接入预算统计',
  '导出清单',
  '备份衣柜数据',
  'wardrobePhotoUris',
  'HeroPhoto'
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
  'walkingSelected',
  '隐私模式',
  'privacyModeEnabled',
  'WeatherService',
  'weatherService',
  'TemperatureControl',
  'temperatureText',
  '实时温度',
  '天气服务不可用'
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
  'onOpenWishlist',
  'onNestedPageVisibilityChange'
]) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing ${needle}`);
  }
}

if (index.includes('weatherService') || index.includes('WeatherService')) {
  throw new Error('Index must not wire the removed weather service');
}

if (!/\.enabled\(!this\.isSaving && \(action !== 'size' \|\| !this\.isLoading\)\)/.test(page)) {
  throw new Error('ProfilePage measurement action must be disabled while preferences are saving');
}

if (!/DistrictChip\(label: string, selected: boolean\)[\s\S]*?\.enabled\(!this\.isSaving\)/.test(page)) {
  throw new Error('ProfilePage district chips must be disabled while districts are saving');
}

if (!/DistrictChip\(label: string, selected: boolean\)[\s\S]*?this\.toggleDistrict\(label\)/.test(page)) {
  throw new Error('ProfilePage district chips must toggle saved locations');
}

for (const [field, minName, maxName] of [
  ['heightCm', 'PROFILE_HEIGHT_MIN_CM', 'PROFILE_HEIGHT_MAX_CM'],
  ['weightKg', 'PROFILE_WEIGHT_MIN_KG', 'PROFILE_WEIGHT_MAX_KG'],
  ['waistCm', 'PROFILE_WAIST_MIN_CM', 'PROFILE_WAIST_MAX_CM']
]) {
  const pattern = new RegExp(`isInvalidOptionalNumber\\(this\\.${field},\\s*${minName},\\s*${maxName}\\)`);
  if (!pattern.test(page)) {
    throw new Error(`ProfilePage must validate ${field} with domain measurement bounds`);
  }
}

console.log('PASS');
