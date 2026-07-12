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

for (const pattern of [
  /import\s*{[^}]*ClothingRepository[^}]*}\s*from\s*['"][^'"]*ClothingRepository['"]/s,
  /import\s*{[^}]*OutfitRepository[^}]*}\s*from\s*['"][^'"]*OutfitRepository['"]/s,
  /import\s*{[^}]*StoreRepository[^}]*}\s*from\s*['"][^'"]*StoreRepository['"]/s,
  /import\s*{[^}]*WearLogRepository[^}]*}\s*from\s*['"][^'"]*WearLogRepository['"]/s,
  /import\s*{[^}]*ClothingPicker[^}]*}\s*from\s*['"][^'"]*ClothingPicker['"]/s
]) {
  mustMatch(text, pattern, 'must import repositories and shared components explicitly');
}

for (const needle of [
  '衣橱',
  '美搭',
  '店铺',
  '单品',
  '试穿',
  '吊牌',
  '选择照片',
  '存入衣柜',
  '自动识别',
  '刚录入',
  'this.photoUris.slice(0, 3)',
  'TextArea',
  'photoUris',
  'capturedAt',
  'captureDate',
  'ClothingRepository',
  'OutfitRepository',
  'StoreRepository',
  'WearLogRepository',
  'ClothingPicker',
  'createClothing',
  'createOutfit',
  'createStoreVisit',
  'createStoreVisitWithOptionalStore',
  'createWearLog',
  'CAPTURE_ACCENT',
  'SecondaryPageHeader',
  'onCancel'
]) {
  mustInclude(text, needle);
}

mustMatch(text, /generated(?:Wardrobe|Clothing|Name)|wardrobeGeneratedName|generatedClothingName/, 'must generate a wardrobe/clothing fallback name');
mustMatch(text, /generatedOutfit|outfitGeneratedName|generatedOutfitTitle/, 'must generate an outfit fallback title');
mustMatch(text, /generatedStore|storeGeneratedName|generatedStoreVisitName/, 'must generate a store fallback name');
mustMatch(text, /canSave\(\)\s*:\s*boolean\s*{[\s\S]*?photoUris\.length\s*>\s*0/, 'save gate must require selected photos');
mustMatch(text, /this\.photoUris\s*=\s*\[\s*\.\.\.this\.initialPhotoUris\s*\]/, 'must clone initialPhotoUris before assigning to state');
mustMatch(text, /clothingRepository\??:\s*ClothingRepository/, 'must expose ClothingRepository dependency');
mustMatch(text, /outfitRepository\??:\s*OutfitRepository/, 'must expose OutfitRepository dependency');
mustMatch(text, /storeRepository\??:\s*StoreRepository/, 'must expose StoreRepository dependency');
mustMatch(text, /wearLogRepository\??:\s*WearLogRepository/, 'must expose WearLogRepository dependency');

for (const forbidden of [
  'AppTheme.color.primary',
  'wardrobe_look_',
  'findStoreByName(this.storeName)',
  'createStore({',
  'this.storeName.trim().length > 0 &&',
  'this.outfitTitle.trim().length > 0 &&',
  'this.name.trim().length > 0 &&',
  'this.category !==',
  'this.category === undefined',
  'selectedClothingItemIds.length > 0 &&'
]) {
  mustNotInclude(text, forbidden);
}

console.log('PASS');
