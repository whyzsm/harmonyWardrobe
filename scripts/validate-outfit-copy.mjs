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

function readPrivateMethod(source, file, signature) {
  const start = source.indexOf(signature);
  if (start < 0) {
    throw new Error(`${file} missing ${signature}`);
  }
  const end = source.indexOf('\n  private ', start + 1);
  return source.slice(start, end < 0 ? source.length : end);
}

const pagePath = 'entry/src/main/ets/pages/OutfitEditPage.ets';
const outfitsPath = 'entry/src/main/ets/pages/OutfitsPage.ets';
const page = read(pagePath);
const outfits = read(outfitsPath);

for (const needle of [
  '创建穿搭',
  '编辑穿搭',
  '保存穿搭',
  '穿搭名称',
  '穿搭名称，可不填',
  '展示内容',
  '上传照片',
  '选衣柜单品',
  '小记（选填）',
  'TextArea({ text: this.note',
  'hasDisplayPhoto',
  'hasRequiredSourcePhoto',
  'displayPhotoUris',
  'linkedClothingPhotoUris',
  'displaySource',
  'OutfitDisplaySource'
]) {
  mustInclude(page, pagePath, needle);
}

mustInclude(page, pagePath, 'this.photoUris.length > 0');
mustInclude(page, pagePath, 'this.hasRequiredSourcePhoto()');
mustInclude(page, pagePath, 'normalizedTitle');
mustInclude(outfits, outfitsPath, 'OutfitWallCard');

if (!/private hasRequiredSourcePhoto\(\): boolean \{[\s\S]*?this\.displaySource === OUTFIT_DISPLAY_SOURCE_WARDROBE[\s\S]*?return this\.linkedClothingPhotoUris\(\)\.length > 0;[\s\S]*?return this\.hasSelectedPhoto\(\);/.test(page)) {
  throw new Error(`${pagePath} must validate save readiness by the selected display source`);
}

if (!/private displayPhotoUris\(\): string\[\] \{[\s\S]*?this\.displaySource === OUTFIT_DISPLAY_SOURCE_WARDROBE[\s\S]*?clothingPhotoUris[\s\S]*?return this\.photoUris\.length > 0 \? this\.photoUris : clothingPhotoUris;/.test(page)) {
  throw new Error(`${pagePath} must select display photos by displaySource with fallback`);
}

const toggleClothingItemMethod = readPrivateMethod(page, pagePath, 'private toggleClothingItem(id: string): void {');
if (/this\.photoUris\s*=/.test(toggleClothingItemMethod)) {
  throw new Error(`${pagePath} must not replace uploaded outfit photos while selecting wardrobe items`);
}

for (const forbidden of ['创建美搭', '编辑美搭', '保存美搭', '美搭名称', "Text('穿搭')", "Text('美搭')"]) {
  mustNotInclude(page, pagePath, forbidden);
}

if (fs.existsSync('entry/src/main/ets/components/OutfitCard.ets')) {
  throw new Error('entry/src/main/ets/components/OutfitCard.ets should be removed as dead code');
}

console.log('PASS');
