import fs from 'node:fs';

const file = 'entry/src/main/ets/pages/ClothingEditPage.ets';
const text = fs.readFileSync(file, 'utf8');

function requireIncludes(needle) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function forbidIncludes(needle) {
  if (text.includes(needle)) {
    throw new Error(`${file} still contains ${needle}`);
  }
}

for (const needle of [
  'DatePickerDialog.show',
  'onDateAccept',
  'formatDateForStorage',
  'dateFromStorage',
  'openPurchaseDatePicker',
  '选择购买日期',
  '购买日期',
  '清除日期'
]) {
  requireIncludes(needle);
}

forbidIncludes("TextInput({ text: this.purchaseDate, placeholder: 'purchaseDate / 购买日期 YYYY-MM-DD' })");
forbidIncludes("placeholder: 'purchaseDate / 购买日期 YYYY-MM-DD'");

console.log('PASS');
