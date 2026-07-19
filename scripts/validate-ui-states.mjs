import fs from 'node:fs';

const pageStateExpectations = [
  {
    page: 'WardrobePage',
    needles: ['loading', 'error', '衣服会按图片检索流排在这里', '重试']
  },
  {
    page: 'StoreVisitPage',
    needles: ['loading', 'error', '还没有逛店记录', '重试']
  },
  {
    page: 'ProfilePage',
    needles: ['isLoading', 'errorMessage', 'LoadingProgress()', 'saveProfile', '已保存个人信息', '请输入数字']
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

for (const [page, saveControl] of [
  ['ClothingEditPage', 'else if (this.canSave())'],
  ['OutfitEditPage', 'else if (this.canSave())'],
  ['StoreVisitEditPage', 'enabled(this.canSave())']
]) {
  const text = fs.readFileSync(`entry/src/main/ets/pages/${page}.ets`, 'utf8');
  for (const needle of ['isSaving', 'errorMessage', saveControl]) {
    if (!text.includes(needle)) {
      throw new Error(`${page} missing save state ${needle}`);
    }
  }
}

console.log('PASS');
