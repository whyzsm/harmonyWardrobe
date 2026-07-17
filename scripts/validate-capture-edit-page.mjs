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
  '先添加照片',
  '保存衣服',
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
  'ClothingPicker',
  'createClothing',
  'createOutfit',
  'createStoreVisit',
  'createStoreVisitWithOptionalStore',
  'SecondaryPageHeader',
  'onCancel',
  "Text('单品名称')",
  "Text('备注')",
  "Text('购买店铺')",
  "Text('价格')",
  "Text('购买日期')",
  "Text('购买备注')",
  "Text('美搭名称')",
  "Text('店铺名')",
  "Text('地点')",
  "Text('逛店日期')"
]) {
  mustInclude(text, needle);
}

for (const legacySelectionColor of ['#8ABBEA', '#82B3EA', '#A8C9ED']) {
  mustNotInclude(text, legacySelectionColor);
}

mustMatch(text, /generated(?:Wardrobe|Clothing|Name)|wardrobeGeneratedName|generatedClothingName/, 'must generate a wardrobe/clothing fallback name');
mustMatch(text, /generatedOutfit|outfitGeneratedName|generatedOutfitTitle/, 'must generate an outfit fallback title');
mustMatch(text, /generatedStore|storeGeneratedName|generatedStoreVisitName/, 'must generate a store fallback name');
mustMatch(text, /canSave\(\)\s*:\s*boolean\s*{[\s\S]*?photoUris\.length\s*>\s*0/, 'save gate must require selected photos');
mustMatch(text, /this\.photoUris\.length\s*>\s*0\s*\?\s*'保存衣服'\s*:\s*'先添加照片'/, 'wardrobe save button must guide users to add a photo before saving');
mustMatch(text, /this\.photoUris\s*=\s*\[\s*\.\.\.this\.initialPhotoUris\s*\]/, 'must clone initialPhotoUris before assigning to state');
mustMatch(text, /private async choosePhotos\(\): Promise<void> {[\s\S]*?if \(this\.isSaving \|\| this\.isChoosingPhotos\)/, 'photo chooser must guard saving and choosing states');
mustMatch(text, /\.enabled\(!this\.isSaving && !this\.isChoosingPhotos\)/, 'photo chooser entry must be disabled while saving or choosing photos');
mustMatch(text, /clothingRepository\??:\s*ClothingRepository/, 'must expose ClothingRepository dependency');
mustMatch(text, /outfitRepository\??:\s*OutfitRepository/, 'must expose OutfitRepository dependency');
mustMatch(text, /storeRepository\??:\s*StoreRepository/, 'must expose StoreRepository dependency');

for (const forbidden of [
  'AppTheme.color.primary',
  'wardrobe_look_',
  'WearLogRepository',
  'createWearLog',
  'syncWearLog',
  '同步到穿搭日历',
  "@State private note: string = '亮色外套，适合周末出门。'",
  "@State private name: string = '牛仔短外套'",
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

for (const emptyDefault of [
  "@State private note: string = ''",
  "@State private name: string = ''"
]) {
  mustInclude(text, emptyDefault);
}

console.log('PASS');
