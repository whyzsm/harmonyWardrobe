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
  '拍店铺',
  'filterStoreVisits',
  'visitSummaryText',
  '重试',
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

console.log('PASS');
