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
  "{ label: '刷新'",
  '今天路线：',
  '家去过',
  '家想去',
  'StoreRepository',
  'listStoreVisits',
  'filterStoreVisits',
  'isSearching',
  '重试',
  '没有找到相关逛店记录',
  '点底部相机，打开快捷录入里的新增逛店。',
  '也可以选择照片后归类为店铺',
  '底部相机会把照片保存到这里',
  'storeNameSnapshot',
  'districtOrAddress',
  'note',
  'StoreVisitWaterFlow',
  '暂无照片',
  "columnsTemplate('1fr 1fr')",
  "borderRadius(18)",
  'wardrobe_look_shirt'
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

for (const needle of ['逛店', 'onOpenStoreVisit']) {
  if (!quickSheet.includes(needle)) {
    throw new Error(`QuickCaptureSheet missing store visit quick action ${needle}`);
  }
}

for (const needle of ['StoreVisitEditPage({', 'showQuickStoreEditor', 'openQuickStoreEditor']) {
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
  throw new Error('Store visit add entry must live in QuickCaptureSheet, not the store page header');
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
