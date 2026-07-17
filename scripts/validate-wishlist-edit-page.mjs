import fs from 'node:fs';

const editPagePath = 'entry/src/main/ets/pages/WishlistEditPage.ets';

if (!fs.existsSync(editPagePath)) {
  throw new Error(`${editPagePath} does not exist`);
}

const text = fs.readFileSync(editPagePath, 'utf8');

for (const needle of [
  'PhotoPickerAdapter',
  'PhotoStorage',
  'WishlistRepository',
  'PhotoGrid',
  'WishlistItem',
  'title',
  'storeName',
  'price',
  'note',
  'isSaving',
  'canSave',
  'saveWishlistItem',
  'pickGalleryPhotos',
  'capturePhoto',
  'copyToAppStorage',
  'createWishlistItem',
  'updateWishlistItem'
]) {
  if (!text.includes(needle)) {
    throw new Error(`WishlistEditPage missing ${needle}`);
  }
}

if (!/this\.photoUris\s*=\s*\[\s*\.\.\.this\.initialItem\.photoUris\s*\]/.test(text)) {
  throw new Error('WishlistEditPage must clone initial item photoUris before assigning to state');
}

if (!/canSave\(\)\s*:\s*boolean\s*{[\s\S]*?return\s+!this\.isSaving\s*&&\s*!this\.isChoosingPhotos\s*&&\s*!this\.isDeleting/.test(text)) {
  throw new Error('WishlistEditPage save gate must block concurrent photo selection');
}

if (!/@State private isChoosingPhotos: boolean = false;/.test(text)) {
  throw new Error('WishlistEditPage must track photo picker re-entry while choosing photos');
}

function readAsyncMethod(source, name) {
  const start = source.indexOf(`private async ${name}(): Promise<void> {`);
  if (start < 0) {
    throw new Error(`WishlistEditPage missing ${name}`);
  }
  const end = source.indexOf('\n  private ', start + 1);
  return source.slice(start, end < 0 ? source.length : end);
}

for (const [name, fallbackMessage] of [
  ['pickGalleryPhotos', '选择照片失败'],
  ['capturePhoto', '拍照失败']
]) {
  const method = readAsyncMethod(text, name);
  if (!method.includes('this.photoPickerAdapter === undefined || this.isChoosingPhotos || this.isSaving || this.isDeleting')) {
    throw new Error(`WishlistEditPage ${name} must reject concurrent photo operations and saves`);
  }
  for (const needle of [
    'this.isChoosingPhotos = true;',
    'try {',
    'catch (error) {',
    `error instanceof Error ? error.message : '${fallbackMessage}'`,
    'finally {',
    'this.isChoosingPhotos = false;'
  ]) {
    if (!method.includes(needle)) {
      throw new Error(`WishlistEditPage ${name} must use try/catch/finally for photo errors`);
    }
  }
}

if ((text.match(/\.enabled\(!this\.isChoosingPhotos && !this\.isSaving && !this\.isDeleting\)/g) ?? []).length < 2) {
  throw new Error('WishlistEditPage camera and gallery actions must be disabled during photo selection or save');
}

console.log('PASS');
