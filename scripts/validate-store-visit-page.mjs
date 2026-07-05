import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }
  return fs.readFileSync(file, 'utf8');
}

const page = read('entry/src/main/ets/pages/StoreVisitPage.ets');
const card = read('entry/src/main/ets/components/StoreVisitCard.ets');
const index = read('entry/src/main/ets/pages/Index.ets');

for (const needle of [
  '逛店',
  'StoreRepository',
  'listStoreVisits',
  'StoreVisitCard',
  '相机记录',
  'filterStoreVisits',
  'visitSummaryText',
  'isSearching',
  '重试',
  '没有找到相关逛店记录',
  '点底部相机，选择照片后归类为店铺',
  '底部相机会把照片保存到这里',
  'storeNameSnapshot',
  'districtOrAddress',
  'note'
]) {
  if (!page.includes(needle)) {
    throw new Error(`StoreVisitPage missing ${needle}`);
  }
}

for (const needle of ['店', 'storeNameSnapshot', 'visitDate', 'borderRadius', 'maxLines(2)']) {
  if (!card.includes(needle)) {
    throw new Error(`StoreVisitCard missing ${needle}`);
  }
}

for (const needle of ['StoreVisitPage({', 'storeRepository: this.runtime.storeRepository', 'StoreVisitEditPage({']) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing ${needle}`);
  }
}

if (page.includes('WishlistRepository') || card.includes('WishlistRepository')) {
  throw new Error('Store visit UI must not import WishlistRepository');
}

if (page.includes("Button('拍店铺')") || page.includes('点右上角')) {
  throw new Error('Store visit UI should guide users through the bottom camera flow');
}

console.log('PASS');
