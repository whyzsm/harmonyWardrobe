import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }
  return fs.readFileSync(file, 'utf8');
}

const page = read('entry/src/main/ets/pages/StoreVisitPage.ets');
const index = read('entry/src/main/ets/pages/Index.ets');
const quickSheet = read('entry/src/main/ets/components/QuickCaptureSheet.ets');

for (const needle of [
  '@State private showEditor: boolean = false',
  '搜索商场、品牌、试穿记录',
  "{ label: '全部'",
  "{ label: '去过'",
  "{ label: '想去'",
  '今天路线',
  '最近路线',
  '家去过',
  '家想去',
  'StoreRepository',
  'listStoreVisits',
  'filterStoreVisits',
  'isSearching',
  'routeVisits',
  'hasTodayRoute',
  'toIsoDate',
  '重试',
  '没有找到相关逛店记录',
  '拍照或从相册选图后，按状态收进逛店。',
  '点底部相机，打开快捷录入里的新增逛店。',
  '逛店会按图片记录流排在这里。',
  'storeNameSnapshot',
  'districtOrAddress',
  'note',
  'StoreVisitWaterFlow',
  '暂无照片',
  "columnsTemplate('1fr 1fr')",
  "borderRadius(18)",
  'this.coverPhotoUri(visit).length > 0'
]) {
  if (!page.includes(needle)) {
    throw new Error(`StoreVisitPage missing ${needle}`);
  }
}

for (const needle of ['StoreVisitPage({', 'storeRepository: this.runtime.storeRepository']) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing ${needle}`);
  }
}

for (const needle of ['衣柜', '逛店', '穿搭', 'onOpenWardrobe', 'onOpenStoreVisit', 'onOpenOutfit']) {
  if (!quickSheet.includes(needle)) {
    throw new Error(`QuickCaptureSheet missing category quick action ${needle}`);
  }
}

for (const needle of ['StoreVisitEditPage({', 'AppRouteKind.StoreEditor', 'openQuickStoreEditor']) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing quick store editor flow ${needle}`);
  }
}

if (!page.includes('StoreVisitEditPage({')) {
  throw new Error('StoreVisitPage must keep the real edit record flow');
}

for (const needle of ['StoreVisitStatus', 'focusTags', 'onEditorVisibilityChange']) {
  if (!page.includes(needle)) {
    throw new Error(`StoreVisitPage missing functional ${needle}`);
  }
}

if (page.includes('onSaveAndCapture') || page.includes('onOpenCapture')) {
  throw new Error('StoreVisitPage must not keep the removed save-and-capture flow');
}

if (page.includes('WishlistRepository')) {
  throw new Error('Store visit UI must not import WishlistRepository');
}

if (page.includes("Button('拍店铺')") || page.includes('点右上角')) {
  throw new Error('Store visit UI should guide users through the bottom camera flow');
}

if (page.includes("Text('新增')") || page.includes('openNewVisitEditor')) {
  throw new Error('Store visit add entry must stay photo-first, not the store page header');
}

for (const forbidden of ["{ label: '本地重读'", "value: 'refresh'", '本地重读']) {
  if (page.includes(forbidden)) {
    throw new Error(`StoreVisitPage must not expose local reload filter ${forbidden}`);
  }
}

if (!/EmptyState\(\) \{[\s\S]*?Column\(\{ space: 10 \}\)[\s\S]*?Column\(\{ space: 8 \}\)[\s\S]*?\.fontSize\(36\)[\s\S]*?\.height\(190\)[\s\S]*?\.backgroundColor\(SURFACE_WARM\)[\s\S]*?\.borderRadius\(18\)[\s\S]*?\.border\(\{ width: 1, color: BORDER \}\)[\s\S]*?点底部相机，打开快捷录入里的新增逛店。[\s\S]*?\.fontSize\(15\)[\s\S]*?逛店会按图片记录流排在这里。[\s\S]*?\.fontSize\(12\)[\s\S]*?\.backgroundColor\(PAGE_BACKGROUND\)/.test(page)) {
  throw new Error('StoreVisitPage empty state must match the wardrobe empty layout');
}

for (const forbidden of ['wardrobe_look_', 'designFallbackPhoto', 'debug://']) {
  if (page.includes(forbidden)) {
    throw new Error(`StoreVisitPage must not include test data fallback ${forbidden}`);
  }
}

if (!/visitStatus\(visit: StoreVisit\)[\s\S]*?visit\.status !== undefined[\s\S]*?return visit\.status[\s\S]*?legacyWantToVisitRecord/.test(page)) {
  throw new Error('StoreVisitPage must prefer the saved status before legacy note inference');
}

for (const forbidden of ['家已试穿', '家想回头看']) {
  if (page.includes(forbidden)) {
    throw new Error(`StoreVisitPage route summary must not mix status with focus tag copy: ${forbidden}`);
  }
}

console.log('PASS');
