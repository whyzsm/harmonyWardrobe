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

function mustMatch(text, file, pattern, message) {
  if (!pattern.test(text)) {
    throw new Error(`${file} ${message}`);
  }
}

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const quickSheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';
const wardrobePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const searchPath = 'entry/src/main/ets/pages/SearchResultsPage.ets';
const outfitsPath = 'entry/src/main/ets/pages/OutfitsPage.ets';
const storePath = 'entry/src/main/ets/pages/StoreVisitPage.ets';
const profilePath = 'entry/src/main/ets/pages/ProfilePage.ets';
const clothingEditPath = 'entry/src/main/ets/pages/ClothingEditPage.ets';

const index = read(indexPath);
const quickSheet = read(quickSheetPath);
const wardrobe = read(wardrobePath);
const search = read(searchPath);
const outfits = read(outfitsPath);
const store = read(storePath);
const profile = read(profilePath);
const clothingEdit = read(clothingEditPath);

for (const needle of ['衣柜', '逛店', '穿搭', 'onOpenWardrobe', 'onOpenStoreVisit', 'onOpenOutfit']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}
for (const needle of ['新增衣物', '新增逛店记录', '新增穿搭']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}
for (const forbidden of ['onTakePhoto', 'onPickGallery']) {
  mustNotInclude(quickSheet, quickSheetPath, forbidden);
}
mustMatch(index, indexPath, /QuickCaptureSheet\(\{[\s\S]*?onOpenWardrobe:\s*\(\) => \{[\s\S]*?this\.openQuickClothingEditor\(\);[\s\S]*?onOpenStoreVisit:\s*\(\) => \{[\s\S]*?this\.openQuickStoreEditor\(\);[\s\S]*?onOpenOutfit:\s*\(\) => \{[\s\S]*?this\.openQuickOutfitEditor\(\);/, 'must wire quick capture sheet to the three create editors');
mustInclude(index, indexPath, 'this.activeRoute.kind === AppRouteKind.Main && !this.featureNestedContentVisible');

mustNotInclude(wardrobe, wardrobePath, 'CardHeart()');
mustNotInclude(wardrobe, wardrobePath, "SymbolGlyph($r('sys.symbol.heart'))");
for (const removedFile of [
  'entry/src/main/ets/components/ClothingCard.ets',
  'entry/src/main/ets/components/OutfitCard.ets',
  'entry/src/main/ets/components/StoreVisitCard.ets',
  'entry/src/main/ets/pages/CalendarPage.ets',
  'entry/src/main/ets/components/MonthCalendar.ets'
]) {
  if (fs.existsSync(removedFile)) {
    throw new Error(`${removedFile} should be removed instead of maintained as an inactive surface`);
  }
}

mustInclude(wardrobe, wardrobePath, 'LazyForEach(this.clothingDataSource');
mustInclude(outfits, outfitsPath, 'LazyForEach(this.outfitDataSource');
mustInclude(store, storePath, 'LazyForEach(this.storeVisitDataSource');

mustMatch(search, searchPath, /\.width\(44\)[\s\S]*?\.height\(44\)[\s\S]*?\.accessibilityText\('清空搜索'\)/, 'must give the clear-search control a 44px touch target');
mustMatch(search, searchPath, /\.width\(44\)[\s\S]*?\.height\(44\)[\s\S]*?\.accessibilityText\('拍照搜索'\)/, 'must give the camera-search control a 44px touch target');
mustMatch(search, searchPath, /SearchTabs\(\)[\s\S]*?\.constraintSize\(\{ minHeight: 44 \}\)/, 'must give search tabs a minimum 44px touch target');
mustMatch(search, searchPath, /SearchChip\(term: string[\s\S]*?\.constraintSize\(\{ minHeight: 44 \}\)[\s\S]*?\.padding\(\{ left: 15, right: 15 \}\)/, 'must give search chips a minimum 44px touch target');
mustInclude(profile, profilePath, '.constraintSize({ minHeight: 44 })');
mustMatch(clothingEdit, clothingEditPath, /\.width\(44\)[\s\S]*?\.height\(44\)[\s\S]*?\.accessibilityText\('清除日期'\)/, 'must give clear-date control a 44px touch target');

for (const file of [
  'entry/src/main/ets/pages/CaptureEditPage.ets',
  'entry/src/main/ets/pages/ClothingEditPage.ets',
  'entry/src/main/ets/pages/OutfitEditPage.ets',
  'entry/src/main/ets/pages/StoreVisitEditPage.ets',
  'entry/src/main/ets/pages/WearLogEditPage.ets',
  'entry/src/main/ets/pages/WishlistEditPage.ets',
  'entry/src/main/ets/pages/ProfilePage.ets'
]) {
  mustInclude(read(file), file, 'LoadingProgress()');
}

console.log('PASS');
