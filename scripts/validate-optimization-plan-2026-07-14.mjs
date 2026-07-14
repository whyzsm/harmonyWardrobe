import fs from 'node:fs';

function readFile(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }
  return fs.readFileSync(path, 'utf8');
}

function requireIncludes(source, needle, label) {
  if (!source.includes(needle)) {
    throw new Error(`${label} missing ${needle}`);
  }
}

function requireNotIncludes(source, needle, label) {
  if (source.includes(needle)) {
    throw new Error(`${label} must not include ${needle}`);
  }
}

const tokens = readFile('entry/src/main/ets/theme/Tokens.ets');
const searchResultsPage = readFile('entry/src/main/ets/pages/SearchResultsPage.ets');
const indexPage = readFile('entry/src/main/ets/pages/Index.ets');
const shoppingPage = readFile('entry/src/main/ets/pages/ShoppingPage.ets');
const clothingDetailPage = readFile('entry/src/main/ets/pages/ClothingDetailPage.ets');
const wardrobePage = readFile('entry/src/main/ets/pages/WardrobePage.ets');

if (fs.existsSync('entry/src/main/ets/pages/TodayPage.ets')) {
  throw new Error('TodayPage should be removed because it contains fictional social/feed data');
}

for (const needle of [
  'danger: string;',
  "danger: '#DC2626'"
]) {
  requireIncludes(tokens, needle, 'Tokens');
}

for (const needle of [
  'onOpenWishlistResult: (id: string) => void',
  'onOpenWearLogResult: (id: string) => void',
  'this.onOpenWishlistResult(result.entityId)',
  'this.onOpenWearLogResult(result.entityId)',
  'YibuqueColor.danger'
]) {
  requireIncludes(searchResultsPage, needle, 'SearchResultsPage');
}

if (!/SearchEntityType\.Wishlist[\s\S]*?this\.onOpenWishlistResult\(result\.entityId\)/.test(searchResultsPage)) {
  throw new Error('SearchResultsPage must route wishlist results to the wishlist callback');
}

if (!/SearchEntityType\.WearLog[\s\S]*?this\.onOpenWearLogResult\(result\.entityId\)/.test(searchResultsPage)) {
  throw new Error('SearchResultsPage must route wear-log results to the wear-log callback');
}

if (/SearchResultsPage\(\{[\s\S]*?wishlistRepository: this\.wishlistRepository/.test(shoppingPage)) {
  throw new Error('ShoppingPage must not pass wishlistRepository to SearchResultsPage');
}

for (const needle of [
  'showWishlistPage',
  'ShoppingPage',
  'SearchEntityType.Wishlist',
  "this.showWishlistPage = true",
  'SearchEntityType.WearLog',
  "this.initialWardrobeTab = '日历'",
  "this.selectedMainTab = 'wardrobe'"
]) {
  requireIncludes(indexPage, needle, 'Index');
}

for (const needle of [
  'onDelete: (item: ClothingItem) => Promise<void>',
  '@State private showDeleteConfirm: boolean = false',
  '@State private isDeleting: boolean = false',
  'AlertDialog.show',
  '确定要删除这件衣物吗',
  "Text('删除衣物')"
]) {
  requireIncludes(clothingDetailPage, needle, 'ClothingDetailPage');
}

for (const needle of [
  'private async deleteClothingItem(item: ClothingItem): Promise<void>',
  'this.clothingRepository.deleteClothing(item.id)',
  'this.clothingItems = this.clothingItems.filter',
  'onDelete: async (item: ClothingItem): Promise<void>'
]) {
  requireIncludes(wardrobePage, needle, 'WardrobePage');
}

console.log('PASS');
