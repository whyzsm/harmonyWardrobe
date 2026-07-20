import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WishlistPage.ets', 'utf8');
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const index = fs.readFileSync(indexPath, 'utf8');
const routePath = 'entry/src/main/ets/app/AppRoute.ets';
const route = fs.readFileSync(routePath, 'utf8');
const wishlistRouteStart = index.indexOf('WishlistPage({');
const wishlistRouteEnd = index.indexOf('})\n              .layoutWeight', wishlistRouteStart);
const wishlistRoute = wishlistRouteStart >= 0 && wishlistRouteEnd > wishlistRouteStart ?
  index.slice(wishlistRouteStart, wishlistRouteEnd) :
  '';

for (const needle of [
  'SearchBar',
  'WishlistCard',
  'EmptyState',
  'WishlistRepository',
  'WishlistItem',
  '心仪单品',
  '门店',
  '添加心愿',
  'filterWishlistItems',
  'selectedWishlistItemId',
  'onCreateWishlistItem',
  'onOpenWishlistItem',
  'onClose',
  'onBack',
  'initialScope: SearchEntityType.Wishlist',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WishlistPage missing ${needle}`);
  }
}

for (const needle of [
  'onBack();',
  "accessibilityText('返回我的')"
]) {
  if (!text.includes(needle)) {
    throw new Error(`WishlistPage missing navigation callback ${needle}`);
  }
}

if (!/onClose:\s*\(\) => \{\s*this\.closeUnifiedSearch\(\);\s*\}/.test(text) ||
  !/private closeUnifiedSearch\(\): void \{\s*this\.animateNestedPageChange\(\(\) => \{\s*this\.showUnifiedSearch = false;\s*\}\);\s*\}/.test(text)) {
  throw new Error('WishlistPage search close must return to the wishlist list');
}

if (/onClose:\s*\(\) => \{[\s\S]*?this\.onClose\(\);/.test(text)) {
  throw new Error('WishlistPage search close must not invoke the parent close callback');
}

if (/SearchResultsPage\(\{[\s\S]*?onOpenCameraSearch:/.test(text)) {
  throw new Error('WishlistPage must not expose camera search from wishlist search');
}

if (wishlistRoute.includes('onOpenCapture:')) {
  throw new Error('Index must not wire wishlist search to quick capture');
}

for (const needle of [
  'onClose: () => {',
  'onBack: () => {',
  'this.resetMainRoute(AppMainTab.Profile);',
  'returnToCaptureSource',
  'params.quickCaptureSourceRouteKind = this.activeRoute.kind'
]) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing wishlist route callback ${needle}`);
  }
}

for (const needle of [
  'quickCaptureSourceRouteKind: AppRouteKind;',
  'quickCaptureSourceRouteKind: AppRouteKind.Main'
]) {
  if (!route.includes(needle)) {
    throw new Error(`AppRoute missing capture source state ${needle}`);
  }
}

console.log('PASS');
