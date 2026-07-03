import fs from 'node:fs';

const pageStateExpectations = [
  {
    page: 'WardrobePage',
    needles: ['loading', 'error', '衣服会按图片检索流排在这里', 'retry']
  },
  {
    page: 'StoreVisitPage',
    needles: ['loading', 'error', '还没有逛店记录', 'retry']
  },
  {
    page: 'ProfilePage',
    needles: ['loading', 'errorMessage', '保存中...', 'saveProfile']
  }
];

for (const expectation of pageStateExpectations) {
  const text = fs.readFileSync(`entry/src/main/ets/pages/${expectation.page}.ets`, 'utf8');
  for (const needle of expectation.needles) {
    if (!text.includes(needle)) {
      throw new Error(`${expectation.page} missing ${needle} state`);
    }
  }
}

for (const page of ['ClothingEditPage', 'OutfitEditPage', 'StoreVisitEditPage']) {
  const text = fs.readFileSync(`entry/src/main/ets/pages/${page}.ets`, 'utf8');
  for (const needle of ['isSaving', 'errorMessage', 'enabled(this.canSave())']) {
    if (!text.includes(needle)) {
      throw new Error(`${page} missing save state ${needle}`);
    }
  }
}

console.log('PASS');
