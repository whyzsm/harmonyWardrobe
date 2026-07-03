import fs from 'node:fs';

const wardrobe = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');

for (const needle of [
  '衣裤',
  '美搭',
  '搜索衣服、美搭、备注',
  '上衣',
  '裤子',
  '短裤',
  '长裙',
  '半裙',
  'WaterFlow()',
  'FlowItem()',
  'visibleOutfits'
]) {
  if (!wardrobe.includes(needle)) {
    throw new Error(`WardrobePage missing ${needle}`);
  }
}

for (const forbidden of [
  '搜索衣服、套装、备注',
  '添加衣服',
  '套装',
  'GridItem() should use WaterFlow'
]) {
  if (wardrobe.includes(forbidden)) {
    throw new Error(`WardrobePage still contains old wardrobe feed concept ${forbidden}`);
  }
}

console.log('PASS');
