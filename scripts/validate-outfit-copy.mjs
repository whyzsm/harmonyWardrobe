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
const outfitsPath = 'entry/src/main/ets/pages/OutfitsPage.ets';
const page = read(pagePath);
const outfits = read(outfitsPath);

for (const needle of ['创建美搭', '编辑美搭', '保存美搭', '美搭名称', '美搭名称，可不填']) {
  mustInclude(page, pagePath, needle);
}

mustInclude(page, pagePath, 'this.photoUris.length > 0');
mustInclude(page, pagePath, 'normalizedTitle');
mustInclude(outfits, outfitsPath, 'OutfitWallCard');

for (const forbidden of ['创建套装', '编辑套装', '保存套装', '套装名称', "Text('套装')", "Text('美搭')"]) {
  mustNotInclude(page, pagePath, forbidden);
}

if (fs.existsSync('entry/src/main/ets/components/OutfitCard.ets')) {
  throw new Error('entry/src/main/ets/components/OutfitCard.ets should be removed as dead code');
}

console.log('PASS');
