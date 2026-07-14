import fs from 'node:fs';

function readRequired(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }

  return fs.readFileSync(path, 'utf8');
}

function mustInclude(source, file, needle) {
  if (!source.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustNotInclude(source, file, needle) {
  if (source.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

function mustMatch(source, file, pattern, message) {
  if (!pattern.test(source)) {
    throw new Error(`${file} ${message}`);
  }
}

function mustOrder(source, file, first, second, message) {
  const firstIndex = source.indexOf(first);
  const secondIndex = source.indexOf(second);
  if (firstIndex < 0 || secondIndex < 0 || firstIndex >= secondIndex) {
    throw new Error(`${file} ${message}`);
  }
}

function methodBody(source, file, methodName) {
  const start = source.indexOf(methodName);
  if (start < 0) {
    throw new Error(`${file} missing ${methodName}`);
  }

  const nextMethod = source.indexOf('\n  private ', start + methodName.length);
  return nextMethod < 0 ? source.substring(start) : source.substring(start, nextMethod);
}

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const navPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const quickSheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';

const index = readRequired(indexPath);
const nav = readRequired(navPath);
const quickSheet = readRequired(quickSheetPath);

mustInclude(nav, navPath, 'onOpenCapture');
mustNotInclude(nav, navPath, 'onOpenQuickActions');
mustNotInclude(nav, navPath, "Text('+')");
mustNotInclude(nav, navPath, "Text('拍照')");
mustMatch(nav, navPath, /SymbolGlyph\(\$r\('sys\.symbol\.camera_fill'\)\)|相机|拍照|PhotoIcon|CameraButton/, 'must render a camera/photo center action');

for (const needle of ['拍一张', '从相册选择', 'onTakePhoto', 'onPickGallery']) {
  mustInclude(quickSheet, quickSheetPath, needle);
}

for (const forbidden of ['拍衣服', '拍搭配', '拍店铺']) {
  mustNotInclude(quickSheet, quickSheetPath, forbidden);
}

mustInclude(index, indexPath, 'CaptureEditPage');
mustInclude(index, indexPath, 'photoPickerAdapter.captureFromCamera');
mustInclude(index, indexPath, 'photoPickerAdapter.pickFromGallery');
mustInclude(index, indexPath, 'photoStorage.copyToAppStorage');
mustInclude(index, indexPath, 'showCaptureEditor');
mustInclude(index, indexPath, 'showQuickStoreEditor');
mustInclude(index, indexPath, 'capturePhotoUris');
mustInclude(index, indexPath, 'captureCapturedAt');
mustInclude(index, indexPath, "target === '店铺'");
mustInclude(index, indexPath, "target === '美搭'");
mustInclude(index, indexPath, "this.selectedMainTab = 'store'");
mustInclude(index, indexPath, "this.selectedMainTab = 'outfit'");
mustInclude(index, indexPath, "this.selectedMainTab = 'wardrobe'");
mustInclude(index, indexPath, 'OutfitsPage({');
mustInclude(index, indexPath, 'StoreVisitEditPage({');

const cameraCaptureBody = methodBody(index, indexPath, 'startCameraCapture');
const galleryCaptureBody = methodBody(index, indexPath, 'startGalleryCapture');
const copySourcesBody = methodBody(index, indexPath, 'copySourcesToLocalUris');
const openEditorBody = methodBody(index, indexPath, 'openCaptureEditor');

mustOrder(cameraCaptureBody, indexPath, 'photoPickerAdapter.captureFromCamera', 'copySourcesToLocalUris', 'camera capture should happen before local photo storage');
mustOrder(galleryCaptureBody, indexPath, 'photoPickerAdapter.pickFromGallery', 'copySourcesToLocalUris', 'gallery pick should happen before local photo storage');
mustOrder(copySourcesBody, indexPath, 'photoStorage.copyToAppStorage', 'localUris.push', 'photos should be copied before they are passed to CaptureEditPage');
mustOrder(openEditorBody, indexPath, 'capturePhotoUris = photoUris', 'showCaptureEditor = true', 'photos should be set before opening CaptureEditPage');
mustMatch(index, indexPath, /target\s*===\s*['"`]店铺['"`][\s\S]*?selectedMainTab\s*=\s*['"`]store['"`]/, 'must route store captures back to the store tab');
mustMatch(index, indexPath, /target\s*===\s*['"`]美搭['"`][\s\S]*?selectedMainTab\s*=\s*['"`]outfit['"`]/, 'must route outfit captures back to the independent outfit tab');
mustMatch(index, indexPath, /else[\s\S]*?initialWardrobeTab\s*=\s*['"`]衣裤['"`][\s\S]*?selectedMainTab\s*=\s*['"`]wardrobe['"`]/, 'must route wardrobe captures back to the wardrobe tab');

for (const forbidden of [
  'openAddClothing',
  'openCreateOutfit',
  'openCreateStoreVisit',
  'onCaptureClothing',
  'onCaptureOutfit',
  'onCaptureStore'
]) {
  mustNotInclude(index, indexPath, forbidden);
}

console.log('PASS');
