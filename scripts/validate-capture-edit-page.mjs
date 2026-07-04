import fs from 'node:fs';

const file = 'entry/src/main/ets/pages/CaptureEditPage.ets';

function readRequired(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }

  return fs.readFileSync(path, 'utf8');
}

function mustInclude(source, needle) {
  if (!source.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustNotInclude(source, needle) {
  if (source.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

function mustMatch(source, pattern, message) {
  if (!pattern.test(source)) {
    throw new Error(`${file} ${message}`);
  }
}

const text = readRequired(file);

for (const needle of [
  '衣橱',
  '美搭',
  '店铺',
  '小记',
  'TextArea',
  'photoUris',
  'capturedAt',
  'captureDate',
  'ClothingRepository',
  'OutfitRepository',
  'StoreRepository',
  'WearLogRepository',
  'ClothingPicker',
  'PhotoGrid',
  'createClothing',
  'createOutfit',
  'createStoreVisit',
  'createWearLog',
  'YibuqueColor.actionBlack'
]) {
  mustInclude(text, needle);
}

mustMatch(text, /generated(?:Wardrobe|Clothing|Name)|wardrobeGeneratedName|generatedClothingName/, 'must generate a wardrobe/clothing fallback name');
mustMatch(text, /generatedOutfit|outfitGeneratedName|generatedOutfitTitle/, 'must generate an outfit fallback title');
mustMatch(text, /generatedStore|storeGeneratedName|generatedStoreVisitName/, 'must generate a store fallback name');
mustMatch(text, /canSave\(\)\s*:\s*boolean\s*{[\s\S]*?photoUris\.length\s*>\s*0/, 'save gate must require selected photos');

for (const forbidden of [
  'AppTheme.color.primary',
  'this.storeName.trim().length > 0 &&',
  'this.outfitTitle.trim().length > 0 &&',
  'this.name.trim().length > 0 &&'
]) {
  mustNotInclude(text, forbidden);
}

console.log('PASS');
