import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WishlistPage.ets', 'utf8');
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const index = fs.readFileSync(indexPath, 'utf8');
const routePath = 'entry/src/main/ets/app/AppRoute.ets';
const route = fs.readFileSync(routePath, 'utf8');

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
  'onOpenCapture',
  'onOpenCameraSearch',
  'initialScope: SearchEntityType.Wishlist',
  'ForEach'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WishlistPage missing ${needle}`);
  }
}

for (const needle of [
  'onBack();',
  'this.onOpenCapture();',
  "accessibilityText('返回我的')"
]) {
  if (!text.includes(needle)) {
    throw new Error(`WishlistPage missing navigation callback ${needle}`);
  }
}

if (!/onClose:\s*\(\) => \{[\s\S]*?this\.showUnifiedSearch = false;[\s\S]*?\}/.test(text)) {
  throw new Error('WishlistPage search close must return to the wishlist list');
}

if (/onClose:\s*\(\) => \{[\s\S]*?this\.onClose\(\);/.test(text)) {
  throw new Error('WishlistPage search close must not invoke the parent close callback');
}

if (!/SearchResultsPage\(\{[\s\S]*?onOpenCameraSearch:\s*\(\) => \{[\s\S]*?this\.onOpenCapture\(\);/.test(text)) {
  throw new Error('WishlistPage must forward camera search to the parent capture flow');
}

for (const needle of [
  'onClose: () => {',
  'onBack: () => {',
  'onOpenCapture: () => {',
  'this.resetMainRoute(AppMainTab.Profile);',
  'this.openQuickActions();',
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
