import fs from 'node:fs';

const file = 'entry/src/main/ets/pages/StoreVisitEditPage.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

function blockAfter(source, marker, fromIndex = 0) {
  const markerIndex = source.indexOf(marker, fromIndex);
  if (markerIndex < 0) {
    throw new Error(`${file} missing block ${marker}`);
  }
  const openIndex = source.indexOf('{', markerIndex + marker.length);
  let depth = 0;
  for (let index = openIndex; index < source.length; index += 1) {
    if (source[index] === '{') {
      depth += 1;
    } else if (source[index] === '}') {
      depth -= 1;
      if (depth === 0) {
        return { body: source.slice(openIndex + 1, index), endIndex: index, markerIndex };
      }
    }
  }
  throw new Error(`${file} missing closing brace for ${marker}`);
}

for (const needle of [
  '新增逛店',
  '编辑逛店',
  'StoreRepository',
  'PhotoStorage',
  'pickGalleryPhotos',
  'storeName',
  'visitDate',
  'note',
  'photoUris',
  'createStoreVisit',
  'updateStoreVisit',
  'createStore',
  '保存记录',
  'storeNameSnapshot',
  'YibuqueColor',
  'YibuqueColor.danger',
  'YibuqueRadius',
  'SecondaryPageHeader',
  'isChoosingPhotos',
  'default_store_cover',
  '拍下这家店的第一眼',
  '选择照片',
  '店名 / 品牌',
  '商圈 / 地址',
  '逛店状态',
  '这次要记什么',
  '已去',
  '想去',
  '回购',
  '试穿',
  '想回看',
  '需比价',
  '已购买',
  'captureStorePhoto',
  '.aspectRatio(530 / 386)',
  "SymbolGlyph($r('sys.symbol.shirt'))",
  "SymbolGlyph($r('sys.symbol.eye'))",
  "SymbolGlyph($r('sys.symbol.creditcard'))",
  "SymbolGlyph($r('sys.symbol.bag'))",
  'validateForm',
  'status: this.selectedStatus',
  'focusTags: this.selectedTags',
  'UpdateStoreVisitWithOptionalStoreInput',
  'updateStoreVisitWithOptionalStore'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

for (const forbidden of ['保存并拍照', 'captureAndSaveStoreVisit']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

for (const forbidden of ['onDelete:', 'isDeleting', 'DeleteAction', 'confirmDeleteStoreVisit', '删除逛店记录']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must move deletion to the detail page: ${forbidden}`);
  }
}

for (const forbidden of ['store_visit_cover', 'debug://']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include test photo ${forbidden}`);
  }
}

if (!/ActionRow\(\)[\s\S]*?保存记录[\s\S]*?width\('100%'\)[\s\S]*?padding\(\{ left: 20, right: 20, top: 20, bottom: 16 \+ this\.windowBottomInsetVp \}\)[\s\S]*?shadow\(YibuqueShadow\.editorSheet\)/.test(text)) {
  throw new Error(`${file} must use the fixed single-save action area`);
}

if (!/validateForm\(\)\s*:\s*boolean\s*{[\s\S]*?storeName\.trim\(\)\.length\s*>\s*0[\s\S]*?districtOrAddress\.trim\(\)\.length\s*>\s*0/.test(text)) {
  throw new Error(`${file} must require store name and district/address like shop-add.html`);
}

if (!/this\.photoUris\s*=\s*\[\s*\.\.\.this\.initialVisit\.photoUris\s*\]/.test(text)) {
  throw new Error(`${file} must clone initial visit photoUris before assigning to state`);
}

if (!/private updateInput\(id: string\): UpdateStoreVisitWithOptionalStoreInput[\s\S]*?storeName: this\.storeName\.trim\(\)/.test(text)) {
  throw new Error(`${file} edit save input must carry storeName for relinking`);
}

if (!/this\.initialVisit === undefined[\s\S]*?createStoreVisitWithOptionalStore[\s\S]*?updateStoreVisitWithOptionalStore\(this\.updateInput\(this\.initialVisit\.id\)\)/.test(text)) {
  throw new Error(`${file} must relink store entity when editing store name`);
}

const captureBody = blockAfter(text, 'private async captureStorePhoto()').body;
if (!captureBody.includes('captureFromCamera()') || !captureBody.includes('copySourcesToLocalUris([source])') ||
  !captureBody.includes('localUris.length === 0') || captureBody.includes('[source.uri]') ||
  captureBody.includes('pickFromGallery')) {
  throw new Error(`${file} camera action must capture and persist a camera photo`);
}
if (!/this\.photoPickerAdapter === undefined \|\| this\.isSaving \|\| this\.isChoosingPhotos/.test(captureBody) ||
  !/this\.isChoosingPhotos\s*=\s*true[\s\S]*?finally\s*{[\s\S]*?this\.isChoosingPhotos\s*=\s*false/.test(captureBody)) {
  throw new Error(`${file} camera action must guard and reset isChoosingPhotos`);
}

const galleryBody = blockAfter(text, 'private async pickGalleryPhotos()').body;
if (!/this\.photoPickerAdapter === undefined \|\| this\.isSaving \|\| this\.isChoosingPhotos/.test(galleryBody) ||
  !/this\.isChoosingPhotos\s*=\s*true[\s\S]*?finally\s*{[\s\S]*?this\.isChoosingPhotos\s*=\s*false/.test(galleryBody)) {
  throw new Error(`${file} gallery action must guard and reset isChoosingPhotos`);
}

const cameraActionBody = blockAfter(text, '\n  CameraAction()').body;
if (!cameraActionBody.includes("SymbolGlyph($r('sys.symbol.camera_fill'))") ||
  !cameraActionBody.includes(".accessibilityText('拍照')") ||
  !cameraActionBody.includes('this.captureStorePhoto();') ||
  !cameraActionBody.includes('.enabled(!this.isSaving && !this.isChoosingPhotos)') ||
  cameraActionBody.includes('pickGalleryPhotos')) {
  throw new Error(`${file} camera icon must exclusively invoke captureStorePhoto`);
}

const galleryActionBody = blockAfter(text, '\n  GalleryAction()').body;
if (!galleryActionBody.includes("SymbolGlyph($r('sys.symbol.picture'))") ||
  !galleryActionBody.includes(".accessibilityText('选择照片')") ||
  !galleryActionBody.includes('this.pickGalleryPhotos();') ||
  !galleryActionBody.includes('.enabled(!this.isSaving && !this.isChoosingPhotos)') ||
  galleryActionBody.includes('captureStorePhoto')) {
  throw new Error(`${file} gallery action must exclusively invoke pickGalleryPhotos`);
}

const uploaderBody = blockAfter(text, '\n  PhotoUploader()').body;
if (!/if \(this\.photoUris\.length > 0\)[\s\S]*?Column\(\{ space: 8 \}\)[\s\S]*?\.width\('100%'\)[\s\S]*?\.padding\(\{ left: 24, right: 24, bottom: 24 \}\)/.test(uploaderBody)) {
  throw new Error(`${file} selected-photo overlay must be pinned to the image left edge`);
}
if (uploaderBody.includes('.margin({ left: 24, bottom: 24 })')) {
  throw new Error(`${file} selected-photo overlay must not center an intrinsic-width column with margin`);
}
const emptyBranch = blockAfter(uploaderBody, 'if (this.photoUris.length === 0)');
const photoBranch = blockAfter(uploaderBody, 'else', emptyBranch.endIndex + 1);
const populatedVisualBranch = blockAfter(uploaderBody, 'if (this.photoUris.length > 0)', photoBranch.endIndex + 1);
const populatedControlBranch = blockAfter(uploaderBody, 'if (this.photoUris.length > 0)', populatedVisualBranch.endIndex + 1);
const emptyControlBranch = blockAfter(uploaderBody, 'else', populatedControlBranch.endIndex + 1);
const cameraActionIndex = uploaderBody.indexOf('this.CameraAction()');
if (cameraActionIndex < populatedVisualBranch.endIndex || cameraActionIndex > populatedControlBranch.markerIndex ||
  /\bif\s*\(/.test(uploaderBody.slice(populatedVisualBranch.endIndex + 1, cameraActionIndex)) ||
  uploaderBody.match(/this\.CameraAction\(\)/g)?.length !== 1 ||
  uploaderBody.includes('.onClick(')) {
  throw new Error(`${file} camera action must live in the shared non-clickable photo overlay`);
}
if (populatedControlBranch.body.match(/this\.GalleryAction\(\)/g)?.length !== 1 ||
  emptyControlBranch.body.match(/this\.GalleryAction\(\)/g)?.length !== 1) {
  throw new Error(`${file} both empty and populated photo states must expose the gallery action`);
}

for (const forbidden of [
  'WishlistRepository',
  'note / 备注',
  '试穿备注',
  '照片和小记优先',
  '选填信息',
  'onSaveAndCapture',
  'NoteCard',
  'ContentHeading',
  '记录店铺、试穿和回看理由',
  'AppTheme.color.primary'
]) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

for (const forbidden of ['#FFF7F7', '#F3B8B8', '#FFF0F0', '#F5F3F3', '#FBF9F9', '#BA1A1A', '#DC2626']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must use Yibuque tokens instead of hard-coded error/warm-gray color ${forbidden}`);
  }
}

console.log('PASS');
