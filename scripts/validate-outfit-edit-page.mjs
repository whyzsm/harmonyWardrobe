import fs from 'node:fs';

const editPagePath = 'entry/src/main/ets/pages/OutfitEditPage.ets';
const pickerPath = 'entry/src/main/ets/components/ClothingPicker.ets';

if (!fs.existsSync(editPagePath)) {
  throw new Error(`${editPagePath} does not exist`);
}

if (!fs.existsSync(pickerPath)) {
  throw new Error(`${pickerPath} does not exist`);
}

const editPage = fs.readFileSync(editPagePath, 'utf8');
const picker = fs.readFileSync(pickerPath, 'utf8');

function readPrivateMethod(source, signature) {
  const start = source.indexOf(signature);
  if (start < 0) {
    throw new Error(`OutfitEditPage missing ${signature}`);
  }
  const end = source.indexOf('\n  private ', start + 1);
  return source.slice(start, end < 0 ? source.length : end);
}

for (const needle of [
  'PhotoPickerAdapter',
  'PhotoStorage',
  'OutfitRepository',
  'ClothingPicker',
  'title',
  'clothingItemIds',
  'note',
  'isSaving',
  'canSave',
  'saveOutfit',
  'PhotoSelector',
  'hasSelectedPhoto',
  'hasDisplayPhoto',
  'hasRequiredSourcePhoto',
  'normalizedTitle',
  'displaySource',
  'selectedPhotoIndex',
  'removePhoto',
  '已选照片',
  '删除第 ${index + 1} 张照片',
  'OutfitDisplaySource',
  'OUTFIT_DISPLAY_SOURCE_PHOTO',
  'OUTFIT_DISPLAY_SOURCE_WARDROBE',
  'DisplaySourceSelector',
  'DisplaySourceTab',
  '展示内容',
  '上传照片',
  '选衣柜单品',
  'linkedClothingPhotoUris',
  'displayPhotoUris',
  'formatTimeForTitle',
  'pickGalleryPhotos',
  'capturePhoto',
  'copyToAppStorage',
  'createOutfit',
  'updateOutfit',
  'YibuqueColor',
  'YibuqueRadius',
  'YibuqueShadow',
  'YibuqueColor.actionBlack',
  'PhotoCarousel',
  'MAX_USER_PHOTOS',
  'remainingPhotoSlots',
  'appendPhotoUris',
  '上传这套穿搭照片',
  '整体、细节或上身效果都可以',
  '补充穿搭照片（选填）',
  '.aspectRatio(530 / 386)',
  'CameraAction',
  'GalleryAction',
  "SymbolGlyph($r('sys.symbol.camera_fill'))",
  "SymbolGlyph($r('sys.symbol.picture'))",
  '穿搭信息（选填）',
  '穿搭名称，可不填',
  '小记（选填）',
  'TextArea({ text: this.note',
  '记录场景、试穿感受或搭配想法',
  '保存穿搭',
  '先添加照片',
  '先选有照片的衣物',
  '照片选择能力不可用',
  '照片保存失败'
]) {
  if (!editPage.includes(needle)) {
    throw new Error(`OutfitEditPage missing ${needle}`);
  }
}

if (!/canSave\(\)\s*:\s*boolean\s*{[\s\S]*?return\s+!this\.isSaving\s*&&\s*!this\.isChoosingPhotos\s*&&\s*this\.hasRequiredSourcePhoto\(\)/.test(editPage)) {
  throw new Error('OutfitEditPage save gate must require the active source mode');
}

if (!/private hasRequiredSourcePhoto\(\): boolean \{[\s\S]*?this\.displaySource === OUTFIT_DISPLAY_SOURCE_WARDROBE[\s\S]*?return this\.linkedClothingPhotoUris\(\)\.length > 0;[\s\S]*?return this\.hasSelectedPhoto\(\);/.test(editPage)) {
  throw new Error('OutfitEditPage must validate required photos by the selected source mode');
}

if (!/this\.clothingItemIds\s*=\s*\[\s*\.\.\.this\.initialOutfit\.clothingItemIds\s*\]/.test(editPage)) {
  throw new Error('OutfitEditPage must clone initial clothingItemIds before assigning to state');
}

if (!editPage.includes('[...this.initialOutfit.photoUris]')) {
  throw new Error('OutfitEditPage must clone initial uploaded photoUris without deriving them from wardrobe items');
}

if (/firstPhotoUrisForClothingItemIds|selectedPhotoUris/.test(editPage)) {
  throw new Error('OutfitEditPage must not derive uploaded outfit photos from selected clothing items');
}

if (!/private displayPhotoUris\(\): string\[\] \{[\s\S]*?this\.displaySource === OUTFIT_DISPLAY_SOURCE_WARDROBE[\s\S]*?return clothingPhotoUris\.length > 0 \? clothingPhotoUris : this\.photoUris;[\s\S]*?return this\.photoUris\.length > 0 \? this\.photoUris : clothingPhotoUris;/.test(editPage)) {
  throw new Error('OutfitEditPage must derive display photos from the persisted display source with fallback');
}

if (!/ForEach\(this\.photoUris[\s\S]*?this\.removePhoto\(index\)[\s\S]*?this\.selectPhoto\(index\)/.test(editPage)) {
  throw new Error('OutfitEditPage must expose a selectable uploaded-photo list with per-photo removal');
}

const toggleClothingItemMethod = readPrivateMethod(editPage, 'private toggleClothingItem(id: string): void {');
if (/this\.photoUris\s*=/.test(toggleClothingItemMethod)) {
  throw new Error('OutfitEditPage must not overwrite uploaded photos when wardrobe selection changes');
}

if (editPage.includes('this.title.trim().length > 0 &&')) {
  throw new Error('OutfitEditPage must not require a title to save');
}

if (!/title:\s*this\.normalizedTitle\(\)/.test(editPage)) {
  throw new Error('OutfitEditPage must save a normalized/generated title');
}

for (const needle of [
  'ClothingPicker',
  'ClothingItem',
  '@Prop title: string',
  '@Prop description: string',
  'selectedIds',
  'onToggle',
  'ForEach',
  'includes',
  'photoUris',
  'Image(',
  'coverPhotoUri',
  'clothingCategoryLabel',
  'ArrayDataSource',
  'LazyForEach(this.itemDataSource',
  'borderRadius(YibuqueRadius.xs)',
  "SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))",
  'YibuqueColor.actionBlack'
]) {
  if (!picker.includes(needle)) {
    throw new Error(`ClothingPicker missing ${needle}`);
  }
}

if (/ForEach\(this\.items/.test(picker)) {
  throw new Error('ClothingPicker must use LazyForEach for the item list');
}

for (const forbidden of [
  'title / 美搭名称',
  'note / 备注',
  'PhotoGrid',
  "Button('拍照')",
  'AppTheme.color.primary'
]) {
  if (editPage.includes(forbidden)) {
    throw new Error(`OutfitEditPage must not include ${forbidden}`);
  }
  if (picker.includes(forbidden)) {
    throw new Error(`ClothingPicker must not include ${forbidden}`);
  }
}

if (!/PhotoSelector\(title: string, description: string\)[\s\S]*?PhotoCarousel\(\{[\s\S]*?photoUris: this\.photoUris[\s\S]*?\}\)[\s\S]*?\.aspectRatio\(530 \/ 386\)[\s\S]*?\.borderRadius\(YibuqueRadius\.sheet\)/.test(editPage)) {
  throw new Error('OutfitEditPage photo area must match the store editor hero layout');
}

if (!/DisplaySourceSelector\(\)[\s\S]*?this\.DisplaySourceTab\('上传照片'[\s\S]*?this\.DisplaySourceTab\('选衣柜单品'/.test(editPage)) {
  throw new Error('OutfitEditPage must expose uploaded-photo and wardrobe-item display choices');
}

if (!/this\.displaySource === OUTFIT_DISPLAY_SOURCE_PHOTO[\s\S]*?this\.PhotoSelector\('上传这套穿搭照片'[\s\S]*?this\.OutfitInfoCard\('关联衣柜单品（选填）'[\s\S]*?else[\s\S]*?this\.OutfitInfoCard\('选择衣柜单品'[\s\S]*?this\.PhotoSelector\('补充穿搭照片（选填）'/.test(editPage)) {
  throw new Error('OutfitEditPage display choices must reorder photo and wardrobe sections');
}

if (!/Scroll\(\) \{\s*Column\(\{ space: YibuqueSpacing\.lg \}\) \{[\s\S]*?this\.DisplaySourceSelector\(\)[\s\S]*?\.padding\(\{ left: YibuqueSpacing\.pageX, right: YibuqueSpacing\.pageX, top: YibuqueSpacing\.lg, bottom: YibuqueSpacing\.xxl \}\)/.test(editPage)) {
  throw new Error('OutfitEditPage editor content must be wrapped in the padded scroll column');
}

if (!/Column\(\{ space: 8 \}\)[\s\S]*?\.width\('100%'\)[\s\S]*?\.padding\(\{ left: 24, right: 24, bottom: 24 \}\)/.test(editPage)) {
  throw new Error('OutfitEditPage photo overlay must be pinned to the image left edge');
}

if (!/@State private isChoosingPhotos: boolean = false;/.test(editPage)) {
  throw new Error('OutfitEditPage must track photo picker re-entry while choosing photos');
}

function readAsyncMethod(source, name) {
  const start = source.indexOf(`private async ${name}(): Promise<void> {`);
  if (start < 0) {
    throw new Error(`OutfitEditPage missing ${name}`);
  }
  const end = source.indexOf('\n  private ', start + 1);
  return source.slice(start, end < 0 ? source.length : end);
}

for (const [name, fallbackMessage] of [
  ['pickGalleryPhotos', '选择照片失败'],
  ['capturePhoto', '拍照失败']
]) {
  const method = readAsyncMethod(editPage, name);
  if (!method.includes('this.photoPickerAdapter === undefined || this.isChoosingPhotos || this.isSaving')) {
    throw new Error(`OutfitEditPage ${name} must reject concurrent photo operations and saves`);
  }
  for (const needle of [
    'this.isChoosingPhotos = true;',
    'try {',
    'catch (error) {',
    '照片保存失败',
    `this.errorMessage = userFacingError(error, '${fallbackMessage}')`,
    'finally {',
    'this.isChoosingPhotos = false;'
  ]) {
    if (!method.includes(needle)) {
      throw new Error(`OutfitEditPage ${name} must use try/catch/finally for photo errors`);
    }
  }
}

if ((editPage.match(/\.enabled\(!this\.isChoosingPhotos && !this\.isSaving\)/g) ?? []).length < 2) {
  throw new Error('OutfitEditPage camera and gallery actions must be disabled during photo selection or save');
}

for (const forbidden of ['onDelete:', 'isDeleting', 'DeleteAction', 'confirmDeleteOutfit', '删除穿搭']) {
  if (editPage.includes(forbidden)) {
    throw new Error(`OutfitEditPage must move deletion to the detail page: ${forbidden}`);
  }
}

console.log('PASS');
