import fs from 'node:fs';

const overlayPath = 'entry/src/main/ets/components/DeleteImageOverlay.ets';
const legacyMenuPath = 'entry/src/main/ets/components/DeleteContextMenu.ets';
const overlay = fs.readFileSync(overlayPath, 'utf8');

if (fs.existsSync(legacyMenuPath)) {
  throw new Error(`${legacyMenuPath} must be replaced by the image overlay`);
}

for (const needle of [
  'export struct DeleteImageOverlay',
  'YibuqueColor.overlayDark',
  'Button()',
  "SymbolGlyph($r('sys.symbol.trash'))",
  'YibuqueColor.danger',
  '.height(48)',
  '.enabled(!this.deleting)',
  '.hitTestBehavior(HitTestMode.Default)',
  'this.onDelete()',
  'this.onDismiss()'
]) {
  if (!overlay.includes(needle)) {
    throw new Error(`${overlayPath} missing ${needle}`);
  }
}

if (overlay.includes('Menu()') || overlay.includes('MenuItem(')) {
  throw new Error(`${overlayPath} must render over the card image, not as a context menu`);
}

const pageChecks = [
  {
    path: 'entry/src/main/ets/pages/WardrobePage.ets',
    state: 'deletingClothingId',
    overlayState: 'deleteOverlayClothingId',
    clickBlock: 'clothingCardClickBlockedUntil',
    showOverlay: 'showClothingDeleteOverlay',
    handleClick: 'handleClothingCardClick',
    confirm: 'confirmDeleteClothingFromList',
    listDelete: 'deleteClothingFromList',
    baseDelete: 'deleteClothingItem',
    repositoryDelete: 'this.clothingRepository.deleteClothing(item.id)',
    detailClose: 'this.closeClothingDetail()',
    title: "title: '删除衣物'",
    overlayLabel: "label: '删除衣物'",
    toast: '衣物已删除',
    cardBuilder: 'WardrobeSearchResultCard',
    imageAspectRatio: 'this.wardrobeCardAspectRatio(index)'
  },
  {
    path: 'entry/src/main/ets/pages/OutfitsPage.ets',
    state: 'deletingOutfitId',
    overlayState: 'deleteOverlayOutfitId',
    clickBlock: 'outfitCardClickBlockedUntil',
    showOverlay: 'showOutfitDeleteOverlay',
    handleClick: 'handleOutfitCardClick',
    confirm: 'confirmDeleteOutfitFromList',
    listDelete: 'deleteOutfitFromList',
    baseDelete: 'deleteOutfit',
    repositoryDelete: 'this.outfitRepository.deleteOutfit(outfit.id)',
    detailClose: 'this.closeOutfitDetail()',
    title: "title: '删除穿搭'",
    overlayLabel: "label: '删除穿搭'",
    toast: '穿搭已删除',
    cardBuilder: 'OutfitWallCard',
    imageAspectRatio: 'this.outfitStackAspectRatio(index)'
  },
  {
    path: 'entry/src/main/ets/pages/StoreVisitPage.ets',
    state: 'deletingVisitId',
    overlayState: 'deleteOverlayVisitId',
    clickBlock: 'visitCardClickBlockedUntil',
    showOverlay: 'showVisitDeleteOverlay',
    handleClick: 'handleVisitCardClick',
    confirm: 'confirmDeleteVisitFromList',
    listDelete: 'deleteVisitFromList',
    baseDelete: 'deleteStoreVisit',
    repositoryDelete: 'this.storeRepository.deleteStoreVisit(visit.id)',
    detailClose: 'this.closeDetail()',
    title: "title: '删除逛店记录'",
    overlayLabel: "label: '删除逛店记录'",
    toast: '逛店记录已删除',
    cardBuilder: 'StoreVisitResultCard',
    imageAspectRatio: 'this.cardAspectRatio(index)'
  }
];

function methodBody(source, methodName) {
  const asyncStart = source.indexOf(`private async ${methodName}`);
  const syncStart = source.indexOf(`private ${methodName}`);
  const start = asyncStart >= 0 ? asyncStart : syncStart;
  if (start < 0) {
    return '';
  }
  const nextMethod = source.indexOf('\n  private ', start + methodName.length);
  return nextMethod < 0 ? source.substring(start) : source.substring(start, nextMethod);
}

for (const check of pageChecks) {
  const page = fs.readFileSync(check.path, 'utf8');
  for (const needle of [
    "import { DeleteImageOverlay } from '../components/DeleteImageOverlay'",
    check.state,
    check.overlayState,
    check.clickBlock,
    check.showOverlay,
    check.handleClick,
    check.confirm,
    check.listDelete,
    check.repositoryDelete,
    check.detailClose,
    check.title,
    check.overlayLabel,
    check.toast,
    'AlertDialog.show',
    'DeleteImageOverlay({',
    'LongPressGesture({ repeat: false, duration: 500 })',
    '.onAction(() => {',
    '.onActionEnd(() => {',
    'Date.now()',
    'Date.now() + 300',
    'Date.now() + 60000',
    ".accessibilityTextHint('长按图片可显示删除操作')"
  ]) {
    if (!page.includes(needle)) {
      throw new Error(`${check.path} missing image-overlay long-press delete behavior ${needle}`);
    }
  }

  for (const forbidden of [
    'DeleteContextMenu',
    '.bindContextMenu(',
    'ResponseType.LongPress'
  ]) {
    if (page.includes(forbidden)) {
      throw new Error(`${check.path} must not use legacy context-menu behavior ${forbidden}`);
    }
  }

  const touchReleasePattern = new RegExp(
    `TouchType\\.Up[\\s\\S]{0,180}this\\.${check.overlayState}\\s*=\\s*''`
  );
  if (touchReleasePattern.test(page)) {
    throw new Error(`${check.path} must keep the delete overlay visible after touch release`);
  }

  const actionEndPattern = new RegExp(
    `\\.onActionEnd\\(\\(\\) => \\{[\\s\\S]{0,180}this\\.${check.overlayState}\\s*=\\s*''`
  );
  if (actionEndPattern.test(page)) {
    throw new Error(`${check.path} must not clear the delete overlay when long press ends`);
  }

  const baseDeleteBody = methodBody(page, check.baseDelete);
  if (baseDeleteBody.includes(check.detailClose)) {
    throw new Error(`${check.path} base delete method must not own detail navigation`);
  }

  const listDeleteBody = methodBody(page, check.listDelete);
  if (!listDeleteBody.includes(`this.${check.overlayState} = '';`)) {
    throw new Error(`${check.path} must clear the image overlay after list deletion finishes`);
  }

  const confirmBody = methodBody(page, check.confirm);
  if (!confirmBody.includes(`this.${check.overlayState} = '';`)) {
    throw new Error(`${check.path} must clear the image overlay when confirmation is cancelled`);
  }

  const detailDeletePattern = new RegExp(
    `onDelete: async \\([^)]*\\): Promise<void> => \\{[\\s\\S]*?await this\\.${check.baseDelete}\\([^)]*\\);[\\s\\S]*?${check.detailClose.replace(/[.*+?^${}()|[\\]\\]/g, '\\$&')}`
  );
  if (!detailDeletePattern.test(page)) {
    throw new Error(`${check.path} detail deletion must close the detail page after repository success`);
  }

  const priorityLongPressPattern = new RegExp(
    `${check.cardBuilder}\\([^)]*\\)[\\s\\S]*?\\.priorityGesture\\(\\s*LongPressGesture\\(\\{ repeat: false, duration: 500 \\}\\)`
  );
  if (!priorityLongPressPattern.test(page)) {
    throw new Error(`${check.path} image long press must take priority over WaterFlow scrolling on real devices`);
  }

  const cardStart = page.indexOf(`  ${check.cardBuilder}(`);
  const nextBuilder = page.indexOf('\n  @Builder', cardStart + check.cardBuilder.length);
  const cardBody = nextBuilder < 0 ? page.substring(cardStart) : page.substring(cardStart, nextBuilder);
  const overlayStart = cardBody.indexOf('DeleteImageOverlay({');
  const fixedImageContainer = `\n      .width('100%')\n      .aspectRatio(${check.imageAspectRatio})`;
  if (cardStart < 0 || overlayStart < 0 || cardBody.indexOf(fixedImageContainer, overlayStart) < 0) {
    throw new Error(`${check.path} delete overlay container must use the same aspect ratio as its card image`);
  }
}

console.log('PASS');
