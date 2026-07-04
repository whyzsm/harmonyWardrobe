import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const adapterPath = 'entry/src/main/ets/media/PhotoPickerAdapter.ets';

function readRequired(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }

  return fs.readFileSync(path, 'utf8');
}

function assertIncludes(source, needle, message = `Missing ${needle}`) {
  if (!source.includes(needle)) {
    throw new Error(message);
  }
}

function assertMatches(source, pattern, message) {
  if (!pattern.test(source)) {
    throw new Error(message);
  }
}

function assertNoUnsafeTypes(path, source) {
  const unsafeType = source.match(/(?:^|[\s<(:,=|&])(?:unknown|any)(?=\b|[>\s,;)|&])/m);
  if (unsafeType) {
    throw new Error(`${path} must not use unsafe type ${unsafeType[0].trim()}`);
  }
}

function assertRejectsUnsafeType(source, expectedUnsafeType) {
  try {
    assertNoUnsafeTypes('negative-self-check.ets', source);
  } catch (error) {
    if (!String(error.message).includes(expectedUnsafeType)) {
      throw new Error(`Unsafe type self-check rejected for the wrong reason: ${error.message}`);
    }
    return;
  }

  throw new Error(`Unsafe type self-check must reject ${expectedUnsafeType}`);
}

function assertNoForbiddenNeedles(source) {
  for (const forbiddenNeedle of [
    'PhotoStorage',
    'abilityAccessCtrl',
    'requestPermissionsFromUser',
    '@ohos.router',
    'router',
    '@ohos.promptAction',
    'promptAction',
    'startAbility',
    'Repository',
    'data/repositories',
    '@kit.CoreFileKit',
    'fileIo',
    'fileUri',
    'saveUri',
    '@ohos.net',
    '@ohos.request',
    '@ohos.net.http',
    'fetch(',
    'axios',
    'http://',
    'https://'
  ]) {
    if (source.includes(forbiddenNeedle)) {
      throw new Error(`PhotoPickerAdapter must not import or call ${forbiddenNeedle}`);
    }
  }
}

function assertRejectsForbiddenNeedle(source, expectedNeedle) {
  try {
    assertNoForbiddenNeedles(source);
  } catch (error) {
    if (!String(error.message).includes(expectedNeedle)) {
      throw new Error(`Forbidden needle self-check rejected for the wrong reason: ${error.message}`);
    }
    return;
  }

  throw new Error(`Forbidden needle self-check must reject ${expectedNeedle}`);
}

function plain(value) {
  return JSON.parse(JSON.stringify(value));
}

function stripTypeBlock(source, keyword) {
  return source.replace(new RegExp(`${keyword}\\s+\\w+\\s*{[\\s\\S]*?\\n}\\n`, 'g'), '');
}

function createRunnableAdapterSource(source) {
  let runnable = source
    .replace(/^import[\s\S]*?;\n/gm, '')
    .replace(/\bexport\s+/g, '')
    .replace(/private\s+readonly\s+/g, '')
    .replace(/\bprivate\s+/g, '')
    .replace(/readonly\s+/g, '')
    .replace(/\s+as\s+string\b/g, '')
    .replace(/\s+as\s+Error\b/g, '');

  runnable = stripTypeBlock(runnable, 'interface');
  runnable = stripTypeBlock(runnable, 'type');

  return runnable
    .replace(/\s+implements\s+[A-Za-z_$][\w$.]*/g, '')
    .replace(/([A-Za-z_$][\w$]*)\?\s*:/g, '$1:')
    .replace(/([A-Za-z_$][\w$]*)\?:/g, '$1:')
    .replace(/:\s*cameraPicker\.PickerProfile/g, '')
    .replace(/:\s*GalleryPickerProvider/g, '')
    .replace(/:\s*CameraCaptureProvider/g, '')
    .replace(/:\s*GalleryPickOptions/g, '')
    .replace(/:\s*CameraCaptureOptions/g, '')
    .replace(/:\s*PhotoPickerAdapter/g, '')
    .replace(/:\s*PhotoSource\[\]/g, '')
    .replace(/:\s*PhotoSource/g, '')
    .replace(/:\s*camera\.CameraPosition/g, '')
    .replace(/:\s*Promise<PhotoSource\[\]>/g, '')
    .replace(/:\s*Promise<PhotoSource>/g, '')
    .replace(/:\s*Promise<Array<string>>/g, '')
    .replace(/:\s*Promise<string\[\]>/g, '')
    .replace(/:\s*Promise<string>/g, '')
    .replace(/:\s*Array<string>/g, '')
    .replace(/:\s*common\.Context/g, '')
    .replace(/:\s*boolean/g, '')
    .replace(/:\s*number/g, '')
    .replace(/:\s*string/g, '');
}

assertRejectsUnsafeType('function bad(value: any): string { return String(value); }', 'any');
assertRejectsUnsafeType('const bad = value as any;', 'any');
assertRejectsUnsafeType('const values: Array<any> = [];', 'any');
assertRejectsUnsafeType('const values: Record<string, unknown> = {};', 'unknown');
assertRejectsUnsafeType('type Bad = unknown;', 'unknown');
assertRejectsForbiddenNeedle('const bad = PhotoStorage;', 'PhotoStorage');
assertRejectsForbiddenNeedle('requestPermissionsFromUser();', 'requestPermissionsFromUser');
assertRejectsForbiddenNeedle("import router from '@ohos.router';", '@ohos.router');
assertRejectsForbiddenNeedle('promptAction.showToast({ message: "bad" });', 'promptAction');
assertRejectsForbiddenNeedle('context.startAbility({});', 'startAbility');
assertRejectsForbiddenNeedle("import { SearchRepository } from '../data/repositories/SearchRepository';", 'Repository');
assertRejectsForbiddenNeedle("import repo from '../data/repositories/photo-adapter-store';", 'data/repositories');
assertRejectsForbiddenNeedle("import { fileIo } from '@kit.CoreFileKit';", '@kit.CoreFileKit');
assertRejectsForbiddenNeedle('profile.saveUri = saveUri;', 'saveUri');
assertRejectsForbiddenNeedle('fetch("https://example.com");', 'fetch(');

const adapter = readRequired(adapterPath);

assertNoUnsafeTypes(adapterPath, adapter);
assertNoForbiddenNeedles(adapter);

assertMatches(adapter, /import\s+{\s*PhotoSource\s*}\s+from\s+['"]\.\/PhotoModels['"]/, 'PhotoPickerAdapter must import PhotoSource from PhotoModels');
assertMatches(adapter, /import\s+{\s*cameraPicker\s*}\s+from\s+['"]@kit\.CameraKit['"]/, 'PhotoPickerAdapter must import cameraPicker from CameraKit');
assertMatches(adapter, /export\s+interface\s+GalleryPickOptions\b/, 'PhotoPickerAdapter must export GalleryPickOptions');
assertMatches(adapter, /export\s+interface\s+CameraCaptureOptions\b/, 'PhotoPickerAdapter must export CameraCaptureOptions');
assertMatches(adapter, /export\s+interface\s+GalleryPickerProvider\b/, 'PhotoPickerAdapter must export GalleryPickerProvider');
assertMatches(adapter, /pickImages\s*\(\s*maxSelectNumber:\s*number\s*\)\s*:\s*Promise<Array<string>>/, 'GalleryPickerProvider must expose pickImages(maxSelectNumber)');
assertMatches(adapter, /export\s+interface\s+CameraCaptureProvider\b/, 'PhotoPickerAdapter must export CameraCaptureProvider');
assertMatches(adapter, /capturePhoto\s*\(\s*options\??:\s*CameraCaptureOptions\s*\)\s*:\s*Promise<string>/, 'CameraCaptureProvider must expose capturePhoto(options?)');
assertMatches(adapter, /export\s+class\s+PhotoPickerAdapter\b/, 'PhotoPickerAdapter must export class PhotoPickerAdapter');
assertMatches(adapter, /constructor\s*\([^)]*galleryProvider\??:\s*GalleryPickerProvider[^)]*cameraProvider\??:\s*CameraCaptureProvider/s, 'PhotoPickerAdapter constructor must support provider injection');
assertMatches(adapter, /pickFromGallery\s*\(\s*options\??:\s*GalleryPickOptions\s*\)\s*:\s*Promise<PhotoSource\[\]>/, 'pickFromGallery must return Promise<PhotoSource[]>');
assertMatches(adapter, /captureFromCamera\s*\(\s*options\??:\s*CameraCaptureOptions\s*\)\s*:\s*Promise<PhotoSource>/, 'captureFromCamera must return Promise<PhotoSource>');

for (const needle of [
  '@kit.MediaLibraryKit',
  'photoAccessHelper',
  'PhotoViewPicker',
  'PhotoSelectOptions',
  'PhotoViewMIMETypes.IMAGE_TYPE',
  'select(options)',
  'photoUris',
  '@kit.CameraKit',
  'cameraPicker',
  'cameraPicker.pick',
  'PickerMediaType.PHOTO',
  'new cameraPicker.PickerProfile()',
  'resultUri',
  '@ohos.app.ability.common'
]) {
  assertIncludes(adapter, needle, `PhotoPickerAdapter missing HarmonyOS API usage: ${needle}`);
}

assertMatches(adapter, /Number\.isFinite|isFinite/, 'Gallery maxSelectNumber must reject non-finite values');
assertMatches(adapter, /DEFAULT_MAX_SELECT_NUMBER\s*=\s*20/, 'Gallery default maxSelectNumber should be 20');
if (/cameraPosition\s*=/.test(adapter)) {
  throw new Error('Default camera profile must not assign cameraPosition; PickerProfile.cameraPosition is read-only on some HarmonyOS devices');
}
assertMatches(adapter, /Math\.floor/, 'Gallery maxSelectNumber must be floored before use');
assertMatches(adapter, /\.filter\s*\([^)]*uri[\s\S]*\.length\s*>\s*0/, 'Gallery URIs must filter empty values');
assertMatches(adapter, /IMAGE_MIME_TYPE\s*=\s*['"]image\/\*['"]/, 'PhotoPickerAdapter must define image/* mime type');
assertMatches(adapter, /mimeType\s*:\s*(?:IMAGE_MIME_TYPE|['"]image\/\*['"])/, 'PhotoSource should use image/* mimeType');
assertMatches(adapter, /throw\s+new\s+Error\s*\([^)]*camera[^)]*URI/i, 'Camera empty resultUri must throw');

const harmonyContext = { ability: 'context' };
const photoSelectOptions = [];
const photoPickerSelectCalls = [];
const cameraPickCalls = [];
let cameraPickerResultUri = 'camera://native-photo';
const context = {
  photoAccessHelper: {
    PhotoViewMIMETypes: {
      IMAGE_TYPE: 'image/*'
    },
    PhotoViewPicker: class {
      async select(options) {
        photoPickerSelectCalls.push(options);
        return { photoUris: ['photo://gallery-one'] };
      }
    },
    PhotoSelectOptions: class {
      constructor() {
        photoSelectOptions.push(this);
      }
    }
  },
  camera: {
    CameraPosition: {
      CAMERA_POSITION_BACK: 'back',
      CAMERA_POSITION_FRONT: 'front',
      CAMERA_POSITION_UNSPECIFIED: 'unspecified'
    }
  },
  cameraPicker: {
    PickerMediaType: {
      PHOTO: 'photo'
    },
    PickerProfile: class {
      constructor() {
        this.createdBy = 'PickerProfile';
        Object.defineProperty(this, 'cameraPosition', {
          value: 'read-only-back',
          writable: false
        });
      }
    },
    async pick(cameraContext, mediaTypes, profile) {
      cameraPickCalls.push({
        context: cameraContext,
        mediaTypes: [...mediaTypes],
        profile
      });
      return { resultUri: cameraPickerResultUri };
    }
  }
};
vm.createContext(context);
vm.runInContext(`
${createRunnableAdapterSource(adapter)}
this.HarmonyGalleryPickerProvider = HarmonyGalleryPickerProvider;
this.HarmonyCameraCaptureProvider = HarmonyCameraCaptureProvider;
this.PhotoPickerAdapter = PhotoPickerAdapter;
`, context);

const harmonyGalleryProvider = new context.HarmonyGalleryPickerProvider();
const providerGalleryUris = await harmonyGalleryProvider.pickImages(7);
assert.deepEqual(providerGalleryUris, ['photo://gallery-one']);
assert.equal(photoSelectOptions.length, 1);
assert.equal(photoSelectOptions[0].MIMEType, 'image/*');
assert.equal(photoSelectOptions[0].maxSelectNumber, 7);
assert.equal(photoPickerSelectCalls.length, 1);
assert.strictEqual(photoPickerSelectCalls[0], photoSelectOptions[0]);

const harmonyCameraProvider = new context.HarmonyCameraCaptureProvider(harmonyContext);
const providerCameraUri = await harmonyCameraProvider.capturePhoto();
assert.equal(providerCameraUri, 'camera://native-photo');
assert.equal(cameraPickCalls.length, 1);
assert.strictEqual(cameraPickCalls[0].context, harmonyContext);
assert.deepEqual(cameraPickCalls[0].mediaTypes, ['photo']);
assert.equal(cameraPickCalls[0].profile.createdBy, 'PickerProfile');
assert.equal(cameraPickCalls[0].profile.cameraPosition, 'read-only-back');

cameraPickerResultUri = '   ';
await assert.rejects(() => harmonyCameraProvider.capturePhoto(), /camera.*URI/i);

const defaultAdapter = new context.PhotoPickerAdapter();
const defaultGallerySources = await defaultAdapter.pickFromGallery({ maxSelectNumber: 3 });
assert.deepEqual(plain(defaultGallerySources), [
  { uri: 'photo://gallery-one', mimeType: 'image/*' }
]);
assert.equal(photoSelectOptions.length, 2);
assert.equal(photoSelectOptions[1].MIMEType, 'image/*');
assert.equal(photoSelectOptions[1].maxSelectNumber, 3);
assert.strictEqual(photoPickerSelectCalls[1], photoSelectOptions[1]);
await assert.rejects(() => defaultAdapter.captureFromCamera(), /Camera provider is required/i);

cameraPickerResultUri = 'camera://factory-photo';
const factoryAdapter = context.PhotoPickerAdapter.withHarmonyProviders(harmonyContext);
const factoryGallerySources = await factoryAdapter.pickFromGallery({ maxSelectNumber: 5 });
assert.deepEqual(plain(factoryGallerySources), [
  { uri: 'photo://gallery-one', mimeType: 'image/*' }
]);
assert.equal(photoSelectOptions.length, 3);
assert.equal(photoSelectOptions[2].MIMEType, 'image/*');
assert.equal(photoSelectOptions[2].maxSelectNumber, 5);
assert.strictEqual(photoPickerSelectCalls[2], photoSelectOptions[2]);

const factoryCameraSource = await factoryAdapter.captureFromCamera();
assert.deepEqual(plain(factoryCameraSource), {
  uri: 'camera://factory-photo',
  mimeType: 'image/*'
});
assert.equal(cameraPickCalls.length, 3);
assert.strictEqual(cameraPickCalls[2].context, harmonyContext);
assert.deepEqual(cameraPickCalls[2].mediaTypes, ['photo']);
assert.equal(cameraPickCalls[2].profile.createdBy, 'PickerProfile');
assert.equal(cameraPickCalls[2].profile.cameraPosition, 'read-only-back');

cameraPickerResultUri = '   ';
await assert.rejects(() => factoryAdapter.captureFromCamera(), /camera.*URI/i);

const galleryCalls = [];
const cameraCalls = [];
const picker = new context.PhotoPickerAdapter(
  {
    async pickImages(maxSelectNumber) {
      galleryCalls.push(maxSelectNumber);
      return ['file:///tmp/one.jpg', '', '   ', 'photo://two'];
    }
  },
  {
    async capturePhoto(options) {
      cameraCalls.push(options);
      return 'file:///tmp/camera.jpg';
    }
  }
);

const gallerySources = await picker.pickFromGallery({ maxSelectNumber: 2 });
assert.deepEqual(galleryCalls, [2]);
assert.deepEqual(plain(gallerySources), [
  { uri: 'file:///tmp/one.jpg', mimeType: 'image/*' },
  { uri: 'photo://two', mimeType: 'image/*' }
]);

await picker.pickFromGallery({ maxSelectNumber: Number.NaN });
await picker.pickFromGallery({ maxSelectNumber: 0 });
await picker.pickFromGallery({ maxSelectNumber: -3 });
await picker.pickFromGallery({ maxSelectNumber: 0.5 });
await picker.pickFromGallery({ maxSelectNumber: 2000 });
await picker.pickFromGallery();
assert.deepEqual(galleryCalls.slice(1), [20, 1, 1, 1, 20, 20]);

const cameraSource = await picker.captureFromCamera({ fileName: 'capture.jpg', mimeType: 'image/jpeg' });
assert.deepEqual(cameraCalls, [{ fileName: 'capture.jpg', mimeType: 'image/jpeg' }]);
assert.deepEqual(plain(cameraSource), {
  uri: 'file:///tmp/camera.jpg',
  fileName: 'capture.jpg',
  mimeType: 'image/jpeg'
});

const emptyCamera = new context.PhotoPickerAdapter(
  {
    async pickImages() {
      return [];
    }
  },
  {
    async capturePhoto() {
      return '   ';
    }
  }
);
await assert.rejects(() => emptyCamera.captureFromCamera(), /camera.*URI/i);

console.log('PASS');
