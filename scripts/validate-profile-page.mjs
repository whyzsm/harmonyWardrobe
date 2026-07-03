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
  '我的',
  '身高',
  '体重',
  '腰围',
  '设置',
  'ProfileRepository',
  'getProfile',
  'saveProfile',
  'isSaving',
  '保存中',
  '已保存个人信息',
  'hasInvalidMeasurements',
  'measurementError',
  '请输入数字',
  'bgBlueGray',
  '112'
]) {
  if (!page.includes(needle)) {
    throw new Error(`ProfilePage missing ${needle}`);
  }
}

for (const needle of ['ProfilePage({', 'profileRepository: this.runtime.profileRepository']) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing ${needle}`);
  }
}

console.log('PASS');
