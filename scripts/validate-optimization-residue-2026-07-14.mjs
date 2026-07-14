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
const clothingCardPath = 'entry/src/main/ets/components/ClothingCard.ets';
const searchPath = 'entry/src/main/ets/pages/SearchResultsPage.ets';
const outfitsPath = 'entry/src/main/ets/pages/OutfitsPage.ets';
const storePath = 'entry/src/main/ets/pages/StoreVisitPage.ets';
const profilePath = 'entry/src/main/ets/pages/ProfilePage.ets';
const clothingEditPath = 'entry/src/main/ets/pages/ClothingEditPage.ets';

const index = read(indexPath);
const quickSheet = read(quickSheetPath);
const wardrobe = read(wardrobePath);
const clothingCard = read(clothingCardPath);
const search = read(searchPath);
const outfits = read(outfitsPath);
const store = read(storePath);
const profile = read(profilePath);
const clothingEdit = read(clothingEditPath);

for (const needle of ['拍一张', '从相册选择', 'onTakePhoto', 'onPickGallery']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}
for (const forbidden of ['onOpenWardrobe', 'onOpenStoreVisit', 'onOpenOutfit']) {
  mustNotInclude(quickSheet, quickSheetPath, forbidden);
}
mustMatch(index, indexPath, /QuickCaptureSheet\(\{[\s\S]*?onTakePhoto:\s*\(\) => \{[\s\S]*?this\.startCameraCapture\(\);[\s\S]*?onPickGallery:\s*\(\) => \{[\s\S]*?this\.startGalleryCapture\(\);/, 'must wire quick capture sheet to camera and gallery capture');
mustInclude(index, indexPath, '!this.showQuickActions && !this.showWishlistPage');

mustNotInclude(wardrobe, wardrobePath, 'CardHeart()');
mustNotInclude(wardrobe, wardrobePath, "SymbolGlyph($r('sys.symbol.heart'))");
mustNotInclude(clothingCard, clothingCardPath, 'setTimeout');
mustInclude(clothingCard, clothingCardPath, 'animateTo');

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
