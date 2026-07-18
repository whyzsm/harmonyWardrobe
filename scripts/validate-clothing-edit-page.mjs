import fs from 'node:fs';

const editPagePath = 'entry/src/main/ets/pages/ClothingEditPage.ets';
const wardrobePagePath = 'entry/src/main/ets/pages/WardrobePage.ets';

if (!fs.existsSync(editPagePath)) {
  throw new Error(`${editPagePath} does not exist`);
}

const editPage = fs.readFileSync(editPagePath, 'utf8');
const wardrobePage = fs.readFileSync(wardrobePagePath, 'utf8');

function bracedBlock(source, marker) {
  const markerIndex = source.indexOf(marker);
  if (markerIndex < 0) {
    throw new Error(`ClothingEditPage missing block marker ${marker}`);
  }

  const openIndex = source.indexOf('{', markerIndex + marker.length);
  if (openIndex < 0) {
    throw new Error(`ClothingEditPage missing opening brace after ${marker}`);
  }

  let depth = 0;
  for (let index = openIndex; index < source.length; index += 1) {
    if (source[index] === '{') {
      depth += 1;
    } else if (source[index] === '}') {
      depth -= 1;
      if (depth === 0) {
        return { body: source.slice(openIndex + 1, index), endIndex: index + 1 };
      }
    }
  }

  throw new Error(`ClothingEditPage has an unterminated block after ${marker}`);
}

for (const needle of [
  'PhotoPickerAdapter',
  'PhotoStorage',
  'ClothingRepository',
  'name',
  'category',
  'PhotoCarousel',
  'PhotoHero',
  'ItemDetailCard',
  'CategorySection',
  'NoteSection',
  'PurchaseSection',
  'SaveAction',
  'purchase',
  'storeName',
  'price',
  'purchaseDate',
  'note',
  'isSaving',
  'isChoosingPhotos',
  'canSave',
  'saveClothing',
  'generatedName',
  'normalizedName',
  'formatTimeForName',
  'pickGalleryPhotos',
  'MAX_USER_PHOTOS',
  'remainingPhotoSlots',
  'appendPhotoUris',
  'copyToAppStorage',
  'createClothing',
  'updateClothing',
  'YibuqueColor',
  'YibuqueRadius',
  'YibuqueShadow',
  'YibuqueColor.actionBlack',
  'YibuqueColor.danger',
  '选择照片',
  '项目详情',
  '已选：',
  '输入关于这件衣服的描述...',
  '分类',
  '备注',
  '购买信息',
  '购买门店',
  '价格',
  '购买备注',
  '保存衣物'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`ClothingEditPage missing ${needle}`);
  }
}

for (const layoutNeedle of [
  '.aspectRatio(1)',
  "Row({ space: 12 })",
  '.layoutWeight(1)',
  "TextArea({ text: this.note, placeholder: '输入关于这件衣服的描述...' })",
  "$r('sys.symbol.picture')",
  "$r('sys.symbol.store_fill')",
  "$r('sys.symbol.creditcard')",
  "$r('sys.symbol.calendar')",
  "$r('sys.symbol.list_bullet')",
  'this.SaveAction()',
  'bottom: 32',
  '.enabled(!this.isSaving && !this.isChoosingPhotos)'
]) {
  if (!editPage.includes(layoutNeedle)) {
    throw new Error(`ClothingEditPage screenshot structure missing ${layoutNeedle}`);
  }
}

const scrollBlock = bracedBlock(editPage, 'Scroll()');
if (scrollBlock.body.includes('this.SaveAction()') || editPage.indexOf('this.SaveAction()', scrollBlock.endIndex) < 0) {
  throw new Error('ClothingEditPage must keep SaveAction outside the scrolling content');
}

if (!/const DISPLAY_CATEGORY_OPTIONS[\s\S]*?上衣[\s\S]*?裤子[\s\S]*?短裤[\s\S]*?长裙/.test(editPage)) {
  throw new Error('ClothingEditPage must expose the four screenshot category choices');
}

if (!/visibleCategoryOptions\(\)[\s\S]*?ClothingCategory\.HalfSkirt[\s\S]*?LEGACY_HALF_SKIRT_OPTION/.test(editPage)) {
  throw new Error('ClothingEditPage must preserve and display legacy HalfSkirt values');
}

for (const marker of ['private createInput()', 'private updateInput(']) {
  const inputBlock = bracedBlock(editPage, marker).body;
  for (const field of ['name:', 'category:', 'photoUris:', 'note:', 'purchaseInfo:']) {
    if (!inputBlock.includes(field)) {
      throw new Error(`ClothingEditPage ${marker} missing persisted field ${field}`);
    }
  }
}

for (const forbidden of [
  "Button('拍照')",
  'capturePhoto()',
  'PhotoViewPicker',
  'maxSelectNumber = 1',
  'name / 衣物名称',
  'category / 分类',
  'note / 备注',
  'purchase / 购买信息',
  'storeName / 门店',
  'price / 价格',
  'purchase note / 购买备注',
  'AppTheme.color.primary',
  'fallbackUris',
  'PhotoPickerAdapter.copy failed'
]) {
  if (editPage.includes(forbidden)) {
    throw new Error(`ClothingEditPage must not include ${forbidden}`);
  }
}

if (!/hasSelectedPhoto\(\)\s*:\s*boolean\s*{[\s\S]*?return\s+this\.photoUris\.length\s*>\s*0/.test(editPage)) {
  throw new Error('ClothingEditPage selected photo state must be based on full photoUris');
}

if (!/this\.photoUris\s*=\s*\[\s*\.\.\.this\.initialItem\.photoUris\s*\]/.test(editPage)) {
  throw new Error('ClothingEditPage must clone initial item photoUris before assigning to state');
}

if (!/this\.name\s*=\s*this\.generatedName\(\)/.test(editPage)) {
  throw new Error('ClothingEditPage must auto-fill a generated name after photo selection');
}

if (!/name:\s*this\.normalizedName\(\)/.test(editPage)) {
  throw new Error('ClothingEditPage must save a normalized/generated name');
}

const pickGalleryPhotosBody = bracedBlock(editPage, 'private async pickGalleryPhotos()').body;
if (!/this\.photoPickerAdapter === undefined \|\| this\.isSaving \|\| this\.isChoosingPhotos/.test(pickGalleryPhotosBody)) {
  throw new Error('ClothingEditPage gallery pick must guard photo picker, save, and active picking state');
}

if (!/this\.isChoosingPhotos\s*=\s*true[\s\S]*?finally\s*{[\s\S]*?this\.isChoosingPhotos\s*=\s*false/.test(pickGalleryPhotosBody)) {
  throw new Error('ClothingEditPage gallery pick must reset isChoosingPhotos in finally');
}

if (!/const availableSlots = remainingPhotoSlots\(this\.photoUris\)[\s\S]*?pickFromGallery\(\{ maxSelectNumber: availableSlots \}\)[\s\S]*?const localUris = await this\.copySourcesToLocalUris\(sources\)[\s\S]*?this\.photoUris = appendPhotoUris\(this\.photoUris, localUris\)/.test(pickGalleryPhotosBody)) {
  throw new Error('ClothingEditPage must append successful local photo URIs within the shared limit');
}

if (!/catch\s*\(\s*copyError\s*\)[\s\S]*?照片保存失败/.test(pickGalleryPhotosBody)) {
  throw new Error('ClothingEditPage copy failure must show a visible error');
}

for (const needle of [
  'ClothingEditPage',
  'showEditor',
  'editingClothingId',
  'openCreateEditor',
  'onClothingEditorVisibilityChange',
  'onEdit',
  'onCancel'
]) {
  if (!wardrobePage.includes(needle)) {
    throw new Error(`WardrobePage missing clothing edit integration: ${needle}`);
  }
}

console.log('PASS');
