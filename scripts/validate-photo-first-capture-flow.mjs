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

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const navPath = 'entry/src/main/ets/components/BottomNavigationBar.ets';
const quickSheetPath = 'entry/src/main/ets/components/QuickCaptureSheet.ets';

const index = readRequired(indexPath);
const nav = readRequired(navPath);
const quickSheet = readRequired(quickSheetPath);

mustInclude(nav, navPath, 'onOpenCapture');
mustNotInclude(nav, navPath, 'onOpenQuickActions');
mustNotInclude(nav, navPath, "Text('+')");
mustMatch(nav, navPath, /相机|拍照|CameraIcon|PhotoIcon|CameraButton/, 'must render a camera/photo center action');

for (const needle of ['拍照', '从相册选择']) {
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
mustInclude(index, indexPath, 'capturePhotoUris');
mustInclude(index, indexPath, 'captureCapturedAt');
mustInclude(index, indexPath, "target === '店铺'");
mustInclude(index, indexPath, "this.selectedMainTab = 'store'");
mustInclude(index, indexPath, "this.selectedMainTab = 'wardrobe'");

console.log('PASS');
