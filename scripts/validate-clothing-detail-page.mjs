import fs from 'node:fs';

const detailPath = 'entry/src/main/ets/pages/ClothingDetailPage.ets';
const wardrobePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';

if (!fs.existsSync(detailPath)) {
  throw new Error('ClothingDetailPage.ets does not exist');
}

const detail = fs.readFileSync(detailPath, 'utf8');
const wardrobe = fs.readFileSync(wardrobePath, 'utf8');
const index = fs.readFileSync(indexPath, 'utf8');

for (const needle of [
  'export struct ClothingDetailPage',
  '@Prop item',
  'ClothingItem',
  'onBack',
  'onEdit',
  "Text('衣物详情')",
  'visibleItemName',
  'autoNamePattern',
  'autoNamePattern.test(item.name) ? categoryLabel : item.name',
  'DetailTopBar',
  'BackIcon',
  'EditIcon',
  "SymbolGlyph($r('sys.symbol.arrow_left'))",
  "SymbolGlyph($r('sys.symbol.square_and_pencil'))",
  "'#E6FFF2F8'",
  "'#E6F8D4EF'",
  'YibuqueColor.actionBlack',
  'YibuqueShadow.card',
  '购买信息',
  '记录信息',
  'createdAt',
  'updatedAt'
]) {
  if (!detail.includes(needle)) {
    throw new Error(`ClothingDetailPage missing ${needle}`);
  }
}

for (const needle of [
  'showPhotoPreview',
  'selectedPhotoIndex',
  'photoUris()',
  'photoCount()',
  'normalizePhotoIndex',
  'photoUriAt',
  'currentPhotoIndex',
  'selectPhoto',
  'openPhotoPreview',
  'closePhotoPreview',
  'Swiper()',
  'PreviewPhotoSwiper',
  'PhotoPreviewOverlay',
  "Text('关闭')",
  '.objectFit(ImageFit.Contain)',
  '.indicator(false)',
  '.loop(this.photoCount() > 1)',
  '.onChange((index: number) => {',
  'this.selectPhoto(index)',
  'this.openPhotoPreview(index)',
  '左右滑动'
]) {
  if (!detail.includes(needle)) {
    throw new Error(`ClothingDetailPage missing photo preview flow ${needle}`);
  }
}

if ((detail.match(/Swiper\(\)/g) ?? []).length < 2) {
  throw new Error('ClothingDetailPage should use Swiper for both hero and full-screen preview');
}

if (/Image\(this\.firstPhotoUri\(\)\)/.test(detail)) {
  throw new Error('ClothingDetailPage should not render only the first photo in detail or preview');
}

const heroPhotoMatch = detail.match(/@Builder\s+HeroPhoto\(\)\s*\{[\s\S]*?\n  \}\n\n  @Builder\s+PreviewPhotoSwiper/);
if (!heroPhotoMatch) {
  throw new Error('ClothingDetailPage HeroPhoto builder not found');
}

const heroPhoto = heroPhotoMatch[0];
const heroPhotoWithImageMatch = heroPhoto.match(/if \(this\.photoCount\(\) > 0\) \{[\s\S]*?\n      \} else \{/);
if (!heroPhotoWithImageMatch) {
  throw new Error('ClothingDetailPage HeroPhoto image branch not found');
}

const heroPhotoWithImage = heroPhotoWithImageMatch[0];
if (/Text\(|linearGradient/.test(heroPhotoWithImage)) {
  throw new Error('ClothingDetailPage hero photo must not overlay text, counters, or gradient on the image');
}

if (!/WardrobeSearchResultCard\(item: ClothingItem[\s\S]*?this\.openClothingDetail\(item\)/.test(wardrobe)) {
  throw new Error('WardrobeSearchResultCard should open the clothing detail page');
}

for (const needle of [
  'ClothingDetailPage',
  'showClothingDetail',
  'detailClothingId',
  'detailItem()',
  'openClothingDetail',
  'closeClothingDetail',
  'editFromDetail',
  'onDetailModeChange: (showDetailTopBar: boolean) => void',
  'this.onDetailModeChange(true)',
  'this.onDetailModeChange(false)'
]) {
  if (!wardrobe.includes(needle)) {
    throw new Error(`WardrobePage missing detail flow ${needle}`);
  }
}

for (const needle of [
  'showWardrobeDetailTopBar',
  'onDetailModeChange: (showDetailTopBar: boolean) => {',
  'this.showWardrobeDetailTopBar = showDetailTopBar'
]) {
  if (!index.includes(needle)) {
    throw new Error(`Index missing detail top bar flow ${needle}`);
  }
}

if (!/DetailTopBar\(\)[\s\S]*?linearGradient\([\s\S]*?'#E6FFF2F8'[\s\S]*?'#E6F8D4EF'/.test(detail)) {
  throw new Error('ClothingDetailPage detail top bar must keep the home-style translucent rose background');
}

const detailTopBarMatch = detail.match(/@Builder\s+DetailTopBar\(\)\s*\{[\s\S]*?\n  \}\n\n  @Builder\s+DetailRow/);
if (!detailTopBarMatch) {
  throw new Error('ClothingDetailPage DetailTopBar builder not found');
}

const detailTopBar = detailTopBarMatch[0];
for (const forbidden of ["TopAction('返回'", "TopAction('编辑'", "Text('返回')", "Text('编辑')"]) {
  if (detailTopBar.includes(forbidden)) {
    throw new Error(`ClothingDetailPage detail top bar should use icon navigation, not text action ${forbidden}`);
  }
}

const topIconMatch = detail.match(/@Builder\s+BackIcon\(\)[\s\S]*?@Builder\s+DetailTopBar/);
if (!topIconMatch) {
  throw new Error('ClothingDetailPage top icon builders not found');
}

const topIcons = topIconMatch[0];
for (const needle of [
  "SymbolGlyph($r('sys.symbol.arrow_left'))",
  "SymbolGlyph($r('sys.symbol.square_and_pencil'))"
]) {
  if (!topIcons.includes(needle)) {
    throw new Error(`ClothingDetailPage top icon builders should use system icon ${needle}`);
  }
}

for (const forbidden of ['Line()', 'Circle({']) {
  if (topIcons.includes(forbidden)) {
    throw new Error(`ClothingDetailPage top icon builders should use system icons, not custom shape ${forbidden}`);
  }
}

if (/WardrobeSearchResultCard\(item: ClothingItem[\s\S]*?this\.onEdit\(item\)/.test(wardrobe)) {
  throw new Error('WardrobeSearchResultCard must not open the edit page directly');
}

console.log('PASS');
