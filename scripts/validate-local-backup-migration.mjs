import fs from 'node:fs';

function read(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }
  return fs.readFileSync(path, 'utf8');
}

function mustInclude(source, path, fragment) {
  if (!source.includes(fragment)) {
    throw new Error(`${path} missing local backup migration behavior: ${fragment}`);
  }
}

function mustNotInclude(source, path, fragment) {
  if (source.includes(fragment)) {
    throw new Error(`${path} must not include ${fragment}`);
  }
}

const servicePath = 'entry/src/main/ets/data/backup/LocalBackupService.ets';
const modelsPath = 'entry/src/main/ets/data/backup/LocalBackupModels.ets';
const factoryPath = 'entry/src/main/ets/app/WardrobeRuntimeFactory.ets';
const runtimePath = 'entry/src/main/ets/app/WardrobeRuntime.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const profilePath = 'entry/src/main/ets/pages/ProfilePage.ets';
const qaPath = 'docs/qa/manual-test-script.md';
const service = read(servicePath);
const models = read(modelsPath);
const factory = read(factoryPath);
const runtime = read(runtimePath);
const index = read(indexPath);
const profile = read(profilePath);
const qa = read(qaPath);

for (const fragment of [
  "ARCHIVE_MAGIC = 'YIBUQUE_BACKUP_V1",
  "ARCHIVE_EXTENSION = 'yibuque-backup'",
  "import { fileIo, picker } from '@kit.CoreFileKit'",
  'new picker.DocumentViewPicker(this.context)',
  'documentPicker.save',
  'documentPicker.select',
  'await store.backup(databaseSnapshotPath)',
  'await store.restore(stagedDatabasePath)',
  'copyExactBytesToFd',
  'parseManifest',
  'copyStagedPhotosToAppStorage',
  'remapPhotoUris',
  'PHOTO_TABLE_NAMES',
  'fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC',
  'fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC',
  'MAX_MANIFEST_BYTES',
  'MAX_PHOTO_COUNT'
]) {
  mustInclude(service, servicePath, fragment);
}

for (const fragment of [
  'LocalBackupExportResult',
  'LocalBackupRestoreResult',
  'LocalBackupLifecycle'
]) {
  mustInclude(models, modelsPath, fragment);
}

for (const fragment of [
  'LocalBackupService',
  'backupService: LocalBackupService',
  'afterDatabaseRestored',
  'afterPhotoUrisRemapped',
  'SearchIndexBootstrap.refresh'
]) {
  mustInclude(factory, factoryPath, fragment);
}

mustInclude(runtime, runtimePath, 'readonly backupService: LocalBackupService;');
mustInclude(index, indexPath, 'backupService: this.runtime.backupService');

for (const fragment of [
  'backupService?: LocalBackupService',
  'exportLocalBackup',
  'confirmImportLocalBackup',
  'importLocalBackup',
  "title: '导入本地备份'",
  'DataMigrationSection()',
  "'导出本地备份'",
  "'导入本地备份'",
  'isMigratingData'
]) {
  mustInclude(profile, profilePath, fragment);
}

for (const source of [service, factory, runtime, index, profile]) {
  for (const forbidden of ['@kit.NetworkKit', '@ohos.net', 'ohos.permission.INTERNET']) {
    mustNotInclude(source, 'local backup migration source', forbidden);
  }
}

for (const fragment of [
  '数据迁移',
  '导出本地备份',
  '导入本地备份',
  '应用商店版本',
  '照片缩略图'
]) {
  mustInclude(qa, qaPath, fragment);
}

console.log('PASS');
