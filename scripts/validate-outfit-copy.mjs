import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }

  return fs.readFileSync(file, 'utf8');
}

function mustInclude(text, file, needle) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustNotInclude(text, file, needle) {
  if (text.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

const pagePath = 'entry/src/main/ets/pages/OutfitEditPage.ets';
const cardPath = 'entry/src/main/ets/components/OutfitCard.ets';
const page = read(pagePath);
const card = read(cardPath);

for (const needle of ['创建美搭', '编辑美搭', '保存美搭', '美搭名称']) {
  mustInclude(page, pagePath, needle);
}

mustInclude(page, pagePath, 'this.clothingItemIds.length > 0 || this.photoUris.length > 0');
mustInclude(card, cardPath, '美搭');

for (const forbidden of ['创建套装', '编辑套装', '保存套装', '套装名称', "Text('套装')"]) {
  mustNotInclude(page, pagePath, forbidden);
  mustNotInclude(card, cardPath, forbidden);
}

console.log('PASS');
