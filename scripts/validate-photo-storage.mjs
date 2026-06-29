import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';

const modelsPath = 'entry/src/main/ets/media/PhotoModels.ets';
const storagePath = 'entry/src/main/ets/media/PhotoStorage.ets';

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

function findMatchingBrace(source, openBraceIndex) {
  let depth = 0;

  for (let index = openBraceIndex; index < source.length; index += 1) {
    const char = source[index];

    if (char === '{') {
      depth += 1;
    } else if (char === '}') {
      depth -= 1;

      if (depth === 0) {
        return index;
      }
    }
  }

  throw new Error(`Could not find matching brace at ${openBraceIndex}`);
}

function extractMethodBody(source, methodName) {
  const match = new RegExp(`(?:^|\\n)\\s*(?:private\\s+)?(?:async\\s+)?${methodName}\\s*\\(`).exec(source);
  if (!match) {
    throw new Error(`PhotoStorage missing method ${methodName}`);
  }

  const openBraceIndex = source.indexOf('{', match.index);
  if (openBraceIndex === -1) {
    throw new Error(`PhotoStorage missing method body for ${methodName}`);
  }

  const closeBraceIndex = findMatchingBrace(source, openBraceIndex);
  return source.slice(openBraceIndex + 1, closeBraceIndex);
}

function assertInterfaceFields(source, interfaceName, fields) {
  const match = source.match(new RegExp(`export\\s+interface\\s+${interfaceName}\\s*{([\\s\\S]*?)\\n}`));
  if (!match) {
    throw new Error(`Missing exported interface ${interfaceName}`);
  }

  for (const field of fields) {
    if (!new RegExp(`\\b${field}\\??\\s*(?::|\\()`).test(match[1])) {
      throw new Error(`${interfaceName} missing field ${field}`);
    }
  }
}

function createRunnableStorageSource(source) {
  return source
    .replace(/^import[\s\S]*?;\n/gm, '')
    .replace(/\bexport\s+/g, '')
    .replace(/interface\s+\w+\s*{[\s\S]*?\n}\n/g, '')
    .replace(/private\s+readonly\s+/g, '')
    .replace(/private\s+/g, '')
    .replace(/readonly\s+/g, '')
    .replace(/\s+as\s+string\b/g, '')
    .replace(/\s+as\s+Error\b/g, '')
    .replace(/([A-Za-z_$][\w$]*)\?\s*:/g, '$1:')
    .replace(/:\s*\(\)\s*=>\s*string/g, '')
    .replace(/:\s*PhotoFileSystem/g, '')
    .replace(/:\s*PhotoStorageOptions/g, '')
    .replace(/:\s*PhotoSource/g, '')
    .replace(/:\s*StoredPhoto/g, '')
    .replace(/:\s*PhotoDeleteResult/g, '')
    .replace(/:\s*Promise<[^>]+>/g, '')
    .replace(/:\s*Array<[^>]+>/g, '')
    .replace(/:\s*string\[\]/g, '')
    .replace(/:\s*Error\s*\|\s*string\s*\|\s*null\s*\|\s*undefined/g, '')
    .replace(/:\s*string\s*\|\s*undefined/g, '')
    .replace(/:\s*Error\s*\|\s*undefined/g, '')
    .replace(/:\s*Error/g, '')
    .replace(/:\s*boolean/g, '')
    .replace(/:\s*number/g, '')
    .replace(/:\s*string/g, '');
}

assertRejectsUnsafeType('function bad(value: any): string { return String(value); }', 'any');
assertRejectsUnsafeType('const bad = value as any;', 'any');
assertRejectsUnsafeType('const values: Array<any> = [];', 'any');
assertRejectsUnsafeType('const values: Record<string, unknown> = {};', 'unknown');
assertRejectsUnsafeType('type Bad = unknown;', 'unknown');

const models = readRequired(modelsPath);
const storage = readRequired(storagePath);

assertNoUnsafeTypes(modelsPath, models);
assertNoUnsafeTypes(storagePath, storage);

assertInterfaceFields(models, 'PhotoSource', ['uri', 'fileName', 'mimeType']);
assertInterfaceFields(models, 'StoredPhoto', ['localUri', 'fileName', 'createdAt']);
assertInterfaceFields(models, 'PhotoDeleteResult', ['localUri', 'deleted', 'error', 'retryable']);
assertInterfaceFields(models, 'PhotoFileSystem', ['ensureDirectory', 'copyFile', 'deleteFile']);
assertMatches(models, /ensureDirectory\s*\(\s*path:\s*string\s*\)\s*:\s*Promise<void>/, 'PhotoFileSystem.ensureDirectory must be async');
assertMatches(models, /copyFile\s*\(\s*sourceUri:\s*string\s*,\s*destinationUri:\s*string\s*\)\s*:\s*Promise<void>/, 'PhotoFileSystem.copyFile must be async');
assertMatches(models, /deleteFile\s*\(\s*localUri:\s*string\s*\)\s*:\s*Promise<void>/, 'PhotoFileSystem.deleteFile must be async');

assertMatches(storage, /export\s+class\s+PhotoStorage\b/, 'PhotoStorage must export class PhotoStorage');
assertMatches(storage, /constructor\s*\(\s*rootDir:\s*string\s*,\s*fileSystem:\s*PhotoFileSystem/, 'PhotoStorage constructor must accept rootDir and PhotoFileSystem');
for (const needle of [
  'PhotoSource',
  'StoredPhoto',
  'PhotoDeleteResult',
  'PhotoFileSystem',
  'copyToAppStorage',
  'deleteLocalPhoto',
  'photos',
  'ensureDirectory',
  'copyFile',
  'deleteFile'
]) {
  assertIncludes(storage, needle, `PhotoStorage missing ${needle}`);
}

assertMatches(storage, /const\s+PHOTOS_DIR_NAME\s*=\s*['"`]photos['"`]/, 'PhotoStorage must centralize the photos directory name');
assertMatches(storage, /sanitize|safeFileName|safeExtension/, 'PhotoStorage must sanitize file names or extensions');
assertMatches(storage, /Date\.now|new Date\(\)\.getTime|clock/, 'PhotoStorage must use time for uniqueness or createdAt');
assertMatches(storage, /idFactory|createId|random|sequence/, 'PhotoStorage must use an id/sequence dependency for unique names');

const copyBody = extractMethodBody(storage, 'copyToAppStorage');
const deleteBody = extractMethodBody(storage, 'deleteLocalPhoto');
assertMatches(copyBody, /await\s+this\.fileSystem\.ensureDirectory/, 'copyToAppStorage must ensure the photos directory exists');
assertMatches(copyBody, /await\s+this\.fileSystem\.copyFile/, 'copyToAppStorage must copy through PhotoFileSystem.copyFile');
if (/catch\s*\(/.test(copyBody) && !/throw/.test(copyBody)) {
  throw new Error('copyToAppStorage must not swallow copy failures');
}
assertMatches(deleteBody, /try\s*{[\s\S]*await\s+this\.fileSystem\.deleteFile/, 'deleteLocalPhoto must try to delete through PhotoFileSystem.deleteFile');
assertMatches(deleteBody, /catch\s*\(/, 'deleteLocalPhoto must catch delete failures');
assertMatches(deleteBody, /deleted\s*:\s*false/, 'deleteLocalPhoto must return deleted false on failure');
assertMatches(deleteBody, /retryable\s*:\s*true/, 'deleteLocalPhoto failures must be retryable');
assertMatches(deleteBody, /deleted\s*:\s*true/, 'deleteLocalPhoto must return deleted true on success');

for (const networkNeedle of [
  '@ohos.net',
  '@ohos.request',
  '@ohos.net.http',
  'fetch(',
  'axios',
  'http://',
  'https://'
]) {
  if (storage.includes(networkNeedle) || models.includes(networkNeedle)) {
    throw new Error(`Photo storage must not import or call network APIs: ${networkNeedle}`);
  }
}

const context = {};
vm.createContext(context);
vm.runInContext(`
${createRunnableStorageSource(storage)}
this.PhotoStorage = PhotoStorage;
`, context);

const operations = [];
const fileSystem = {
  async ensureDirectory(path) {
    operations.push(['ensureDirectory', path]);
  },
  async copyFile(sourceUri, destinationUri) {
    operations.push(['copyFile', sourceUri, destinationUri]);
  },
  async deleteFile(localUri) {
    operations.push(['deleteFile', localUri]);
  }
};
const storageService = new context.PhotoStorage('/sandbox/root/', fileSystem, {
  clock: () => '2026-06-29T01:02:03.000Z',
  idFactory: () => 'id-001'
});

const storedPhoto = await storageService.copyToAppStorage({
  uri: 'file:///tmp/source/photo.png',
  fileName: '../bad/name.png',
  mimeType: 'image/png'
});
assert.equal(storedPhoto.createdAt, '2026-06-29T01:02:03.000Z');
assert.equal(storedPhoto.fileName, '2026-06-29T01-02-03-000Z-id-001-name.png');
assert.equal(storedPhoto.localUri, '/sandbox/root/photos/2026-06-29T01-02-03-000Z-id-001-name.png');
assert.deepEqual(operations[0], ['ensureDirectory', '/sandbox/root/photos']);
assert.deepEqual(operations[1], ['copyFile', 'file:///tmp/source/photo.png', storedPhoto.localUri]);

const deleteSuccess = await storageService.deleteLocalPhoto(storedPhoto.localUri);
assert.equal(deleteSuccess.localUri, storedPhoto.localUri);
assert.equal(deleteSuccess.deleted, true);
assert.equal(deleteSuccess.retryable, false);

const failingCopy = new context.PhotoStorage('/sandbox/root', {
  async ensureDirectory() {},
  async copyFile() {
    throw new Error('copy failed');
  },
  async deleteFile() {}
}, {
  clock: () => '2026-06-29T01:02:03.000Z',
  idFactory: () => 'id-002'
});
await assert.rejects(
  () => failingCopy.copyToAppStorage({ uri: 'file:///tmp/source/fail.jpg', fileName: 'fail.jpg' }),
  /copy failed/
);

const failingEnsureDirectory = new context.PhotoStorage('/sandbox/root', {
  async ensureDirectory() {
    throw new Error('mkdir failed');
  },
  async copyFile() {},
  async deleteFile() {}
}, {
  clock: () => '2026-06-29T01:02:03.000Z',
  idFactory: () => 'id-003'
});
await assert.rejects(
  () => failingEnsureDirectory.copyToAppStorage({ uri: 'file:///tmp/source/fail.jpg', fileName: 'fail.jpg' }),
  /mkdir failed/
);

const failingDelete = new context.PhotoStorage('/sandbox/root', {
  async ensureDirectory() {},
  async copyFile() {},
  async deleteFile() {
    throw new Error('delete failed');
  }
});
const deleteFailure = await failingDelete.deleteLocalPhoto('/sandbox/root/photos/missing.jpg');
assert.equal(deleteFailure.localUri, '/sandbox/root/photos/missing.jpg');
assert.equal(deleteFailure.deleted, false);
assert.equal(deleteFailure.retryable, true);
assert.match(deleteFailure.error, /delete failed/);

for (const thrownValue of [undefined, null, 'delete failed']) {
  const failingDeleteWithUnknownError = new context.PhotoStorage('/sandbox/root', {
    async ensureDirectory() {},
    async copyFile() {},
    async deleteFile() {
      throw thrownValue;
    }
  });
  const failure = await failingDeleteWithUnknownError.deleteLocalPhoto('/sandbox/root/photos/missing.jpg');

  assert.equal(failure.localUri, '/sandbox/root/photos/missing.jpg');
  assert.equal(failure.deleted, false);
  assert.equal(failure.retryable, true);
  assert.equal(failure.error, String(thrownValue ?? 'Delete failed'));
}

const rootOperations = [];
const rootStorage = new context.PhotoStorage('/', {
  async ensureDirectory(path) {
    rootOperations.push(['ensureDirectory', path]);
  },
  async copyFile(sourceUri, destinationUri) {
    rootOperations.push(['copyFile', sourceUri, destinationUri]);
  },
  async deleteFile() {}
}, {
  clock: () => '2026-06-29T01:02:03.000Z',
  idFactory: () => 'id-004'
});
const rootStoredPhoto = await rootStorage.copyToAppStorage({
  uri: 'file:///tmp/source/photo.jpg',
  fileName: 'photo.jpg',
  mimeType: 'image/jpeg'
});
assert.equal(rootStoredPhoto.localUri, '/photos/2026-06-29T01-02-03-000Z-id-004-photo.jpg');
assert.deepEqual(rootOperations[0], ['ensureDirectory', '/photos']);

const pngFromMimeStorage = new context.PhotoStorage('/sandbox/root', {
  async ensureDirectory() {},
  async copyFile() {},
  async deleteFile() {}
}, {
  clock: () => '2026-06-29T01:02:03.000Z',
  idFactory: () => 'id-005'
});
const pngFromMime = await pngFromMimeStorage.copyToAppStorage({
  uri: 'file:///tmp/source/cache.tmp',
  fileName: 'cache.tmp',
  mimeType: 'image/png'
});
assert.equal(pngFromMime.fileName, '2026-06-29T01-02-03-000Z-id-005-cache.tmp.png');

const defaultJpgStorage = new context.PhotoStorage('/sandbox/root', {
  async ensureDirectory() {},
  async copyFile() {},
  async deleteFile() {}
}, {
  clock: () => '2026-06-29T01:02:03.000Z',
  idFactory: () => 'id-006'
});
const jpgFromDangerousExtension = await defaultJpgStorage.copyToAppStorage({
  uri: 'file:///tmp/source/malware.exe',
  fileName: 'malware.exe'
});
assert.equal(jpgFromDangerousExtension.fileName, '2026-06-29T01-02-03-000Z-id-006-malware.exe.jpg');

console.log('PASS');
