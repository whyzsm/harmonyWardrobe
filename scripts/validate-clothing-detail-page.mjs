import fs from 'node:fs';

const detailPath = 'entry/src/main/ets/pages/ClothingDetailPage.ets';
const headerPath = 'entry/src/main/ets/components/SecondaryPageHeader.ets';
const wardrobePath = 'entry/src/main/ets/pages/WardrobePage.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';

if (!fs.existsSync(detailPath)) {
  throw new Error('ClothingDetailPage.ets does not exist');
}

const detail = fs.readFileSync(detailPath, 'utf8');
const header = fs.readFileSync(headerPath, 'utf8');
const wardrobe = fs.readFileSync(wardrobePath, 'utf8');
const index = fs.readFileSync(indexPath, 'utf8');

for (const needle of [
  'export struct ClothingDetailPage',
  '@Prop item',
  'ClothingItem',
  'onBack',
  'onEdit',
  "title: '衣物详情'",
  'visibleItemName',
  'autoNamePattern',
  'autoNamePattern.test(item.name) ? categoryLabel : item.name',
  'DetailTopBar',
  'SecondaryPageHeader',
  'showEditAction: true',
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
  '.loop(true)',
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

if (!/if \(this\.photoCount\(\) === 1\)[\s\S]*?Image\(this\.photoUriAt\(0\)\)/.test(detail)) {
  throw new Error('ClothingDetailPage must render a static image when only one photo exists');
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

if (!/WardrobeSearchResultCard\(item: ClothingItem[\s\S]*?this\.handleClothingCardClick\(item\)/.test(wardrobe) ||
  !/private handleClothingCardClick\(item: ClothingItem\): void[\s\S]*?this\.openClothingDetail\(item\)/.test(wardrobe)) {
  throw new Error('WardrobeSearchResultCard should open the clothing detail page');
}

if (!/Text\(this\.itemCategoryLabel\(\)\)[\s\S]*?\.fontColor\(YibuqueColor\.iconAccent\)[\s\S]*?\.backgroundColor\(YibuqueColor\.iconAccentSurface\)[\s\S]*?\.border\(\{ width: 1, color: YibuqueColor\.iconAccentSurface \}\)/.test(detail)) {
  throw new Error('ClothingDetailPage category badge must match the profile blue icon accent style');
}

if (detail.includes('暂未填写备注') || !/private hasItemNote\(\): boolean[\s\S]*?if \(this\.hasItemNote\(\)\)[\s\S]*?Text\(this\.itemNote\(\)\)/.test(detail)) {
  throw new Error('ClothingDetailPage must hide the note block when no note exists');
}

if (detail.includes("this.DetailRow('备注', this.purchaseInfo()?.note ?? '未记录')")) {
  throw new Error('ClothingDetailPage must hide an empty purchase note row');
}

if (detail.includes('暂未填写购买信息') || !/PurchaseCard\(\)[\s\S]*?if \(purchaseInfoHasContent\(this\.purchaseInfo\(\)\)\)[\s\S]*?Text\('购买信息'\)/.test(detail)) {
  throw new Error('ClothingDetailPage must hide the purchase card when no purchase data exists');
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
  'export struct SecondaryPageHeader',
  "SymbolGlyph($r('sys.symbol.arrow_left'))",
  "SymbolGlyph($r('sys.symbol.square_and_pencil'))",
  'backgroundColor(YibuqueColor.glassStrong)',
  'YibuqueColor.borderLight',
  '.fontSize(20)',
  '.fontWeight(FontWeight.Regular)'
]) {
  if (!header.includes(needle)) {
    throw new Error(`SecondaryPageHeader missing ${needle}`);
  }
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

const topIcons = header;
for (const needle of [
  "SymbolGlyph($r('sys.symbol.arrow_left'))",
  "SymbolGlyph($r('sys.symbol.square_and_pencil'))"
]) {
  if (!topIcons.includes(needle)) {
    throw new Error(`SecondaryPageHeader should use system icon ${needle}`);
  }
}

for (const forbidden of ['Line()', 'Circle({']) {
  if (topIcons.includes(forbidden)) {
    throw new Error(`SecondaryPageHeader should use system icons, not custom shape ${forbidden}`);
  }
}

if (/WardrobeSearchResultCard\(item: ClothingItem[\s\S]*?this\.onEdit\(item\)/.test(wardrobe)) {
  throw new Error('WardrobeSearchResultCard must not open the edit page directly');
}

console.log('PASS');
