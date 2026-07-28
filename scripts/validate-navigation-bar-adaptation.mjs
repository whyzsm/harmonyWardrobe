import fs from 'node:fs';

function read(path) {
  return fs.readFileSync(path, 'utf8');
}

function mustInclude(source, path, fragment) {
  if (!source.includes(fragment)) {
    throw new Error(`${path} missing navigation-bar adaptation: ${fragment}`);
  }
}

const abilityPath = 'entry/src/main/ets/entryability/EntryAbility.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const bottomNavPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const quickCapturePath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';
const ability = read(abilityPath);
const index = read(indexPath);
const bottomNav = read(bottomNavPath);
const quickCapture = read(quickCapturePath);

for (const fragment of [
  'window.AvoidAreaType.TYPE_SYSTEM',
  'window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR',
  'Math.max(',
  'YibuqueSpacing.bottomSafe',
  "AppStorage.setOrCreate('windowBottomInsetVp'"
]) {
  mustInclude(ability, abilityPath, fragment);
}

for (const fragment of [
  "@StorageProp('windowBottomInsetVp')",
  '.padding({ top: this.windowTopInsetVp })',
  'bottomInsetVp: this.windowBottomInsetVp'
]) {
  mustInclude(index, indexPath, fragment);
}

for (const [path, source] of [
  [bottomNavPath, bottomNav],
  [quickCapturePath, quickCapture]
]) {
  mustInclude(source, path, '@Prop bottomInsetVp: number = 0;');
}
mustInclude(bottomNav, bottomNavPath, '.margin({ bottom: this.bottomInsetVp })');
mustInclude(quickCapture, quickCapturePath, 'bottom: YibuqueSpacing.bottomSafe + this.bottomInsetVp');

for (const path of [
  'entry/src/main/ets/pages/WardrobePage.ets',
  'entry/src/main/ets/pages/OutfitsPage.ets',
  'entry/src/main/ets/pages/StoreVisitPage.ets',
  'entry/src/main/ets/pages/ProfilePage.ets',
  'entry/src/main/ets/pages/SearchResultsPage.ets',
  'entry/src/main/ets/pages/CaptureEditPage.ets',
  'entry/src/main/ets/pages/ClothingEditPage.ets',
  'entry/src/main/ets/pages/OutfitEditPage.ets',
  'entry/src/main/ets/pages/StoreVisitEditPage.ets',
  'entry/src/main/ets/pages/WearLogEditPage.ets',
  'entry/src/main/ets/pages/WishlistEditPage.ets',
  'entry/src/main/ets/pages/ClothingDetailPage.ets',
  'entry/src/main/ets/pages/OutfitDetailPage.ets',
  'entry/src/main/ets/pages/StoreVisitDetailPage.ets',
  'entry/src/main/ets/pages/WishlistPage.ets'
]) {
  const source = read(path);
  mustInclude(source, path, "@StorageProp('windowBottomInsetVp')");
  if (!source.includes('this.windowBottomInsetVp')) {
    throw new Error(`${path} must apply its bottom navigation inset to content or controls`);
  }
}

for (const path of [
  'entry/src/main/ets/components/CategoryTabs.ets',
  'entry/src/main/ets/pages/CaptureEditPage.ets',
  'entry/src/main/ets/pages/ClothingDetailPage.ets',
  'entry/src/main/ets/pages/ClothingEditPage.ets',
  'entry/src/main/ets/pages/OutfitDetailPage.ets',
  'entry/src/main/ets/pages/OutfitEditPage.ets',
  'entry/src/main/ets/pages/OutfitsPage.ets',
  'entry/src/main/ets/pages/ProfilePage.ets',
  'entry/src/main/ets/pages/SearchResultsPage.ets',
  'entry/src/main/ets/pages/StoreVisitDetailPage.ets',
  'entry/src/main/ets/pages/StoreVisitEditPage.ets',
  'entry/src/main/ets/pages/StoreVisitPage.ets',
  'entry/src/main/ets/pages/WardrobePage.ets',
  'entry/src/main/ets/pages/WearLogEditPage.ets',
  'entry/src/main/ets/pages/WishlistEditPage.ets',
  'entry/src/main/ets/pages/WishlistPage.ets'
]) {
  mustInclude(read(path), path, '.edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })');
}

console.log('PASS');
