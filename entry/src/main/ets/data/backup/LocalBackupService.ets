import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { fileIo, hash, picker } from '@kit.CoreFileKit';
import { DatabaseProvider } from '../database/DatabaseProvider';
import {
  LocalBackupExportResult,
  LocalBackupLifecycle,
  LocalBackupRestoreResult
} from './LocalBackupModels';

const ARCHIVE_MAGIC = 'YIBUQUE_BACKUP_V2\n';
const LEGACY_ARCHIVE_MAGIC = 'YIBUQUE_BACKUP_V1\n';
const ARCHIVE_FORMAT_VERSION = 2;
const LEGACY_ARCHIVE_FORMAT_VERSION = 1;
const ARCHIVE_EXTENSION = 'yibuque-backup';
const ARCHIVE_SUFFIX = `.${ARCHIVE_EXTENSION}`;
const PHOTOS_DIRECTORY_NAME = 'photos';
const DATABASE_ENTRY_NAME = 'database.sqlite';
const PREVIOUS_DATABASE_ENTRY_NAME = 'previous-database.sqlite';
const PREVIOUS_PHOTOS_DIRECTORY_NAME = 'previous-photos';
const FAILED_PHOTOS_DIRECTORY_NAME = 'failed-photos';
const SHA256_ALGORITHM = 'sha256';
const FILE_CHUNK_BYTES = 256 * 1024;
const HEADER_SCAN_BYTES = 512;
const MAX_MANIFEST_BYTES = 1024 * 1024;
const MAX_PHOTO_COUNT = 10000;
const PHOTO_TABLE_NAMES: string[] = [
  'clothing_photos',
  'outfit_photos',
  'wear_log_photos',
  'wishlist_photos',
  'store_photos',
  'store_visit_photos'
];

interface BackupDatabaseEntry {
  fileName: string;
  size: number;
  checksum?: string;
}

interface BackupPhotoEntry {
  fileName: string;
  localUri: string;
  size: number;
  checksum?: string;
}

interface BackupManifest {
  formatVersion: number;
  exportedAt: string;
  database: BackupDatabaseEntry;
  photos: BackupPhotoEntry[];
}

interface ArchiveHeader {
  magic: string;
  headerBytes: number;
  manifestBytes: number;
}

interface ArchiveInfo {
  headerBytes: number;
  manifestBytes: number;
  manifest: BackupManifest;
}

interface RuntimeErrorLike {
  message?: string;
  code?: string | number;
}

function trimTrailingSlashes(path: string): string {
  return path.replace(/[\\/]+$/g, '');
}

function joinPath(parent: string, child: string): string {
  const normalizedParent = trimTrailingSlashes(parent);
  const normalizedChild = child.replace(/^[\\/]+/g, '');
  return `${normalizedParent}/${normalizedChild}`;
}

function fileUri(path: string): string {
  return path.startsWith('file://') ? path : `file://${path}`;
}

function leafName(path: string): string {
  const normalizedPath = path.replace(/\\/g, '/');
  const separatorIndex = normalizedPath.lastIndexOf('/');
  return separatorIndex >= 0 ? normalizedPath.substring(separatorIndex + 1) : normalizedPath;
}

function isSafeFileName(fileName: string): boolean {
  return /^[A-Za-z0-9][A-Za-z0-9._-]{0,180}$/.test(fileName) && fileName !== '.' && fileName !== '..';
}

function isPositiveInteger(value: number): boolean {
  return Number.isInteger(value) && value > 0 && Number.isSafeInteger(value);
}

function isNonNegativeInteger(value: number): boolean {
  return Number.isInteger(value) && value >= 0 && Number.isSafeInteger(value);
}

function isSha256Checksum(value: string): boolean {
  return /^[a-f0-9]{64}$/.test(value);
}

function archiveMagicForFormatVersion(formatVersion: number): string | undefined {
  if (formatVersion === ARCHIVE_FORMAT_VERSION) {
    return ARCHIVE_MAGIC;
  }
  if (formatVersion === LEGACY_ARCHIVE_FORMAT_VERSION) {
    return LEGACY_ARCHIVE_MAGIC;
  }
  return undefined;
}

function isChecksumRequired(formatVersion: number): boolean {
  return formatVersion === ARCHIVE_FORMAT_VERSION;
}

function errorText(error: Error | string | RuntimeErrorLike | undefined): string {
  if (error instanceof Error && error.message.length > 0) {
    return error.message;
  }
  if (typeof error === 'string' && error.length > 0) {
    return error;
  }
  if (typeof error === 'object' && error !== undefined) {
    const detail = error as RuntimeErrorLike;
    if (detail.message !== undefined && detail.message.length > 0) {
      return detail.message;
    }
    if (detail.code !== undefined) {
      return String(detail.code);
    }
  }
  return '未知错误';
}

function isMissingFileError(error: Error | string | RuntimeErrorLike | undefined): boolean {
  const message = errorText(error).toLowerCase();
  return message.includes('no such file') || message.includes('not found') || message.includes('13900002');
}

function isAlreadyExistingPathError(error: Error | string | RuntimeErrorLike | undefined): boolean {
  const message = errorText(error).toLowerCase();
  return message.includes('file exists') || message.includes('already exists') || message.includes('13900015');
}

function formatBackupFileName(): string {
  const now = new Date();
  const year = `${now.getFullYear()}`;
  const month = `${now.getMonth() + 1}`.padStart(2, '0');
  const day = `${now.getDate()}`.padStart(2, '0');
  const hour = `${now.getHours()}`.padStart(2, '0');
  const minute = `${now.getMinutes()}`.padStart(2, '0');
  return `yibuque-backup-${year}${month}${day}-${hour}${minute}.${ARCHIVE_EXTENSION}`;
}

function utf8Buffer(value: string): ArrayBuffer {
  const encoded = util.TextEncoder.create('utf-8').encodeInto(value);
  const copy = new Uint8Array(encoded.byteLength);
  copy.set(encoded);
  return copy.buffer as ArrayBuffer;
}

function utf8Text(buffer: ArrayBuffer): string {
  return util.TextDecoder.create('utf-8').decodeToString(new Uint8Array(buffer));
}

function totalArchivePayloadBytes(manifest: BackupManifest): number {
  let total = manifest.database.size;
  for (const photo of manifest.photos) {
    total += photo.size;
  }
  return total;
}

export class LocalBackupService {
  private readonly context: common.Context;
  private readonly database: DatabaseProvider;
  private readonly lifecycle: LocalBackupLifecycle;

  constructor(context: common.Context, database: DatabaseProvider, lifecycle: LocalBackupLifecycle) {
    this.context = context;
    this.database = database;
    this.lifecycle = lifecycle;
  }

  async exportToDocument(): Promise<LocalBackupExportResult | undefined> {
    const destinationUri = await this.selectExportDestination();
    if (destinationUri === undefined) {
      return undefined;
    }

    const operationDirectory = this.operationDirectory('export');
    const databaseSnapshotPath = joinPath(operationDirectory, DATABASE_ENTRY_NAME);
    let destinationFile: fileIo.File | undefined;

    try {
      await fileIo.mkdir(operationDirectory, true);
      const store = await this.database.getStore();
      await store.backup(databaseSnapshotPath);

      const manifest = await this.createManifest(databaseSnapshotPath);
      const manifestBuffer = utf8Buffer(JSON.stringify(manifest));
      const headerBuffer = utf8Buffer(`${ARCHIVE_MAGIC}${manifestBuffer.byteLength}\n`);

      destinationFile = await fileIo.open(
        destinationUri,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC
      );
      await this.writeFully(destinationFile.fd, headerBuffer);
      await this.writeFully(destinationFile.fd, manifestBuffer);
      await this.appendFile(
        destinationFile.fd,
        databaseSnapshotPath,
        manifest.database.size,
        manifest.database.checksum
      );

      for (const photo of manifest.photos) {
        await this.appendFile(destinationFile.fd, this.photoPath(photo.fileName), photo.size, photo.checksum);
      }
      await fileIo.fsync(destinationFile.fd);

      const totalBytes = headerBuffer.byteLength + manifestBuffer.byteLength + totalArchivePayloadBytes(manifest);
      return { photoCount: manifest.photos.length, totalBytes };
    } catch (error) {
      await this.removeIfPresent(destinationUri);
      throw new Error(`导出本地备份失败：${errorText(error as Error)}`);
    } finally {
      if (destinationFile !== undefined) {
        await this.closeQuietly(destinationFile);
      }
      await this.cleanupExportDirectory(operationDirectory, databaseSnapshotPath);
    }
  }

  async importFromDocument(): Promise<LocalBackupRestoreResult | undefined> {
    const sourceUri = await this.selectImportSource();
    if (sourceUri === undefined) {
      return undefined;
    }

    const operationDirectory = this.operationDirectory('import');
    const stagedPhotosDirectory = joinPath(operationDirectory, PHOTOS_DIRECTORY_NAME);
    const stagedDatabasePath = joinPath(operationDirectory, DATABASE_ENTRY_NAME);
    const previousDatabasePath = joinPath(operationDirectory, PREVIOUS_DATABASE_ENTRY_NAME);
    const previousPhotosDirectory = joinPath(operationDirectory, PREVIOUS_PHOTOS_DIRECTORY_NAME);
    const failedPhotosDirectory = joinPath(operationDirectory, FAILED_PHOTOS_DIRECTORY_NAME);
    let photosReplaced = false;
    let databaseBackedUp = false;
    let restoreCompleted = false;
    let preserveOperationDirectory = false;

    try {
      const archive = await this.readArchiveInfo(sourceUri);
      await this.ensureDirectory(stagedPhotosDirectory);
      await this.stageArchive(sourceUri, archive, stagedDatabasePath, stagedPhotosDirectory);
      await this.verifyStagedArchive(stagedDatabasePath, stagedPhotosDirectory, archive.manifest);

      const store = await this.database.getStore();
      await store.backup(previousDatabasePath);
      databaseBackedUp = true;
      await this.replacePhotoStorage(stagedPhotosDirectory, previousPhotosDirectory);
      photosReplaced = true;
      await store.restore(stagedDatabasePath);
      await this.lifecycle.afterDatabaseRestored();
      await this.remapPhotoUris(archive.manifest.photos);
      await this.lifecycle.afterPhotoUrisRemapped();
      restoreCompleted = true;
      await this.removeDirectoryRecursively(previousPhotosDirectory);

      return { photoCount: archive.manifest.photos.length };
    } catch (error) {
      if (photosReplaced && !restoreCompleted) {
        const rollbackError = await this.rollbackImport(
          previousDatabasePath,
          previousPhotosDirectory,
          failedPhotosDirectory,
          databaseBackedUp
        );
        if (rollbackError !== undefined) {
          preserveOperationDirectory = true;
          throw new Error(`${errorText(error as Error)}；恢复原有本地数据失败：${rollbackError}`);
        }
      }
      throw new Error(`导入本地备份失败：${errorText(error as Error)}`);
    } finally {
      if (!preserveOperationDirectory) {
        await this.cleanupImportDirectory(operationDirectory);
      }
    }
  }

  private async selectExportDestination(): Promise<string | undefined> {
    const documentPicker = new picker.DocumentViewPicker(this.context);
    const selectedUris = await documentPicker.save({
      newFileNames: [formatBackupFileName()],
      fileSuffixChoices: [`衣不缺备份|${ARCHIVE_SUFFIX}`],
      autoCreateEmptyFile: true
    });
    return selectedUris.length > 0 ? selectedUris[0] : undefined;
  }

  private async selectImportSource(): Promise<string | undefined> {
    const documentPicker = new picker.DocumentViewPicker(this.context);
    const selectedUris = await documentPicker.select({
      fileSuffixFilters: [`衣不缺备份|${ARCHIVE_SUFFIX}`],
      maxSelectNumber: 1
    });
    return selectedUris.length > 0 ? selectedUris[0] : undefined;
  }

  private async createManifest(databaseSnapshotPath: string): Promise<BackupManifest> {
    const databaseStat = await fileIo.stat(databaseSnapshotPath);
    if (!isPositiveInteger(databaseStat.size)) {
      throw new Error('数据库快照为空或无效。');
    }

    const photos = await this.listStoredPhotos();
    return {
      formatVersion: ARCHIVE_FORMAT_VERSION,
      exportedAt: new Date().toISOString(),
      database: {
        fileName: DATABASE_ENTRY_NAME,
        size: databaseStat.size,
        checksum: await this.fileChecksum(databaseSnapshotPath)
      },
      photos
    };
  }

  private async listStoredPhotos(): Promise<BackupPhotoEntry[]> {
    const directory = this.photosDirectory();
    let entries: string[] = [];
    try {
      entries = await fileIo.listFile(directory);
    } catch (error) {
      if (isMissingFileError(error as Error)) {
        return [];
      }
      throw new Error(errorText(error as Error));
    }

    const photos: BackupPhotoEntry[] = [];
    const seenNames = new Set<string>();
    for (const entry of entries) {
      const fileName = leafName(entry);
      if (!isSafeFileName(fileName) || seenNames.has(fileName)) {
        continue;
      }

      const photoPath = this.photoPath(fileName);
      const stat = await fileIo.stat(photoPath);
      if (!isPositiveInteger(stat.size)) {
        continue;
      }

      seenNames.add(fileName);
      photos.push({
        fileName,
        localUri: fileUri(photoPath),
        size: stat.size,
        checksum: await this.fileChecksum(photoPath)
      });
    }
    return photos;
  }

  private async readArchiveInfo(sourceUri: string): Promise<ArchiveInfo> {
    const header = await this.readArchiveHeader(sourceUri);
    const archiveSize = await this.fileSize(sourceUri);
    if (header.headerBytes + header.manifestBytes > archiveSize) {
      throw new Error('备份文件内容不完整。');
    }

    let sourceFile: fileIo.File | undefined;
    try {
      sourceFile = await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY);
      await this.discardBytes(sourceFile.fd, header.headerBytes);
      const manifestBuffer = await this.readExact(sourceFile.fd, header.manifestBytes);
      const manifest = this.parseManifest(utf8Text(manifestBuffer));
      if (header.magic !== archiveMagicForFormatVersion(manifest.formatVersion)) {
        throw new Error('备份文件头与清单版本不一致。');
      }
      const expectedSize = header.headerBytes + header.manifestBytes + totalArchivePayloadBytes(manifest);
      if (expectedSize !== archiveSize) {
        throw new Error('备份文件大小校验失败。');
      }
      return {
        headerBytes: header.headerBytes,
        manifestBytes: header.manifestBytes,
        manifest
      };
    } finally {
      if (sourceFile !== undefined) {
        await this.closeQuietly(sourceFile);
      }
    }
  }

  private async readArchiveHeader(sourceUri: string): Promise<ArchiveHeader> {
    let sourceFile: fileIo.File | undefined;
    try {
      sourceFile = await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY);
      const buffer = new ArrayBuffer(HEADER_SCAN_BYTES);
      const bytesRead = await fileIo.read(sourceFile.fd, buffer);
      const headerText = utf8Text(buffer.slice(0, bytesRead));
      const magic = headerText.startsWith(ARCHIVE_MAGIC)
        ? ARCHIVE_MAGIC
        : headerText.startsWith(LEGACY_ARCHIVE_MAGIC)
          ? LEGACY_ARCHIVE_MAGIC
          : undefined;
      if (magic === undefined) {
        throw new Error('不是衣不缺备份文件。');
      }

      const lengthLineEnd = headerText.indexOf('\n', magic.length);
      if (lengthLineEnd < 0) {
        throw new Error('备份文件头损坏。');
      }

      const sizeText = headerText.substring(magic.length, lengthLineEnd);
      if (!/^\d+$/.test(sizeText)) {
        throw new Error('备份文件清单无效。');
      }

      const manifestBytes = Number(sizeText);
      if (!isPositiveInteger(manifestBytes) || manifestBytes > MAX_MANIFEST_BYTES) {
        throw new Error('备份文件清单过大或无效。');
      }

      return { magic, headerBytes: lengthLineEnd + 1, manifestBytes };
    } finally {
      if (sourceFile !== undefined) {
        await this.closeQuietly(sourceFile);
      }
    }
  }

  private parseManifest(text: string): BackupManifest {
    const manifest = JSON.parse(text) as BackupManifest;
    const checksumRequired = isChecksumRequired(manifest.formatVersion);
    if (archiveMagicForFormatVersion(manifest.formatVersion) === undefined || manifest.exportedAt.length === 0) {
      throw new Error('备份文件版本不受支持。');
    }
    if (
      manifest.database.fileName !== DATABASE_ENTRY_NAME ||
      !isPositiveInteger(manifest.database.size) ||
      (checksumRequired && !isSha256Checksum(manifest.database.checksum ?? ''))
    ) {
      throw new Error('备份数据库信息无效。');
    }
    if (manifest.photos.length > MAX_PHOTO_COUNT) {
      throw new Error('备份照片数量超出支持范围。');
    }

    const seenNames = new Set<string>();
    for (const photo of manifest.photos) {
      if (
        !isSafeFileName(photo.fileName) ||
        !isNonNegativeInteger(photo.size) ||
        photo.localUri.length === 0 ||
        (checksumRequired && !isSha256Checksum(photo.checksum ?? ''))
      ) {
        throw new Error('备份照片信息无效。');
      }
      if (seenNames.has(photo.fileName)) {
        throw new Error('备份文件包含重复照片。');
      }
      seenNames.add(photo.fileName);
    }
    return manifest;
  }

  private async stageArchive(
    sourceUri: string,
    archive: ArchiveInfo,
    stagedDatabasePath: string,
    stagedPhotosDirectory: string
  ): Promise<void> {
    let sourceFile: fileIo.File | undefined;
    try {
      sourceFile = await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY);
      await this.discardBytes(sourceFile.fd, archive.headerBytes + archive.manifestBytes);
      await this.copyExactBytes(sourceFile.fd, archive.manifest.database.size, stagedDatabasePath);
      for (const photo of archive.manifest.photos) {
        await this.copyExactBytes(sourceFile.fd, photo.size, joinPath(stagedPhotosDirectory, photo.fileName));
      }
    } finally {
      if (sourceFile !== undefined) {
        await this.closeQuietly(sourceFile);
      }
    }
  }

  private async verifyStagedArchive(
    stagedDatabasePath: string,
    stagedPhotosDirectory: string,
    manifest: BackupManifest
  ): Promise<void> {
    if (!isChecksumRequired(manifest.formatVersion)) {
      return;
    }
    await this.verifyFileChecksum(stagedDatabasePath, '备份数据库', manifest.database.checksum);
    for (const photo of manifest.photos) {
      const stagedPath = joinPath(stagedPhotosDirectory, photo.fileName);
      await this.verifyFileChecksum(stagedPath, `照片“${photo.fileName}”`, photo.checksum);
    }
  }

  private async verifyFileChecksum(path: string, displayName: string, expectedChecksum?: string): Promise<void> {
    const expected = expectedChecksum;
    if (expected === undefined) {
      throw new Error(`${displayName}缺少完整性校验信息。`);
    }
    if (await this.fileChecksum(path) !== expected) {
      throw new Error(`${displayName}完整性校验失败。`);
    }
  }

  private async replacePhotoStorage(stagedPhotosDirectory: string, previousPhotosDirectory: string): Promise<void> {
    const activePhotosDirectory = this.photosDirectory();
    const hadActivePhotos = await this.fileExists(activePhotosDirectory);
    if (hadActivePhotos) {
      await fileIo.moveDir(activePhotosDirectory, previousPhotosDirectory);
    }

    try {
      await fileIo.moveDir(stagedPhotosDirectory, activePhotosDirectory);
    } catch (error) {
      if (hadActivePhotos && await this.fileExists(previousPhotosDirectory)) {
        try {
          await fileIo.moveDir(previousPhotosDirectory, activePhotosDirectory);
        } catch (rollbackError) {
          throw new Error(`${errorText(error as Error)}；恢复原有照片失败：${errorText(rollbackError as Error)}`);
        }
      }
      throw new Error(errorText(error as Error));
    }
  }

  private async rollbackImport(
    previousDatabasePath: string,
    previousPhotosDirectory: string,
    failedPhotosDirectory: string,
    databaseBackedUp: boolean
  ): Promise<string | undefined> {
    let rollbackFailure: string | undefined;
    if (databaseBackedUp) {
      try {
        const store = await this.database.getStore();
        await store.restore(previousDatabasePath);
      } catch (error) {
        rollbackFailure = `数据库：${errorText(error as Error)}`;
      }
    }

    try {
      const activePhotosDirectory = this.photosDirectory();
      if (await this.fileExists(activePhotosDirectory)) {
        await fileIo.moveDir(activePhotosDirectory, failedPhotosDirectory);
      }
      if (await this.fileExists(previousPhotosDirectory)) {
        await fileIo.moveDir(previousPhotosDirectory, activePhotosDirectory);
      }
      await this.removeDirectoryRecursively(failedPhotosDirectory);
    } catch (error) {
      const photoFailure = `照片：${errorText(error as Error)}`;
      rollbackFailure = rollbackFailure === undefined ? photoFailure : `${rollbackFailure}；${photoFailure}`;
    }
    return rollbackFailure;
  }

  private async remapPhotoUris(photos: BackupPhotoEntry[]): Promise<void> {
    await this.database.transaction(async () => {
      for (const photo of photos) {
        const destinationUri = fileUri(this.photoPath(photo.fileName));
        for (const tableName of PHOTO_TABLE_NAMES) {
          await this.database.executeSql(
            `UPDATE ${tableName} SET local_uri = ? WHERE local_uri = ?`,
            [destinationUri, photo.localUri]
          );
        }
      }
    });
  }

  private async appendFile(
    destinationFd: number,
    sourcePath: string,
    expectedSize: number,
    expectedChecksum?: string
  ): Promise<void> {
    let sourceFile: fileIo.File | undefined;
    try {
      if (expectedChecksum === undefined) {
        throw new Error(`文件“${leafName(sourcePath)}”缺少完整性校验信息。`);
      }
      sourceFile = await fileIo.open(sourcePath, fileIo.OpenMode.READ_ONLY);
      const currentSize = await this.fileSizeFromFd(sourceFile.fd);
      if (currentSize !== expectedSize) {
        throw new Error(`文件“${leafName(sourcePath)}”在导出时发生变化。`);
      }
      await this.copyExactBytesToFd(sourceFile.fd, expectedSize, destinationFd);
      if (await this.fileChecksum(sourcePath) !== expectedChecksum) {
        throw new Error(`文件“${leafName(sourcePath)}”在导出时发生变化。`);
      }
    } finally {
      if (sourceFile !== undefined) {
        await this.closeQuietly(sourceFile);
      }
    }
  }

  private async copyExactBytes(sourceFd: number, byteCount: number, destinationPath: string): Promise<void> {
    let destinationFile: fileIo.File | undefined;
    try {
      destinationFile = await fileIo.open(
        destinationPath,
        fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC
      );
      await this.copyExactBytesToFd(sourceFd, byteCount, destinationFile.fd);
    } finally {
      if (destinationFile !== undefined) {
        await this.closeQuietly(destinationFile);
      }
    }
  }

  private async copyExactBytesToFd(sourceFd: number, byteCount: number, destinationFd: number): Promise<void> {
    let remaining = byteCount;
    while (remaining > 0) {
      const buffer = new ArrayBuffer(Math.min(FILE_CHUNK_BYTES, remaining));
      const bytesRead = await fileIo.read(sourceFd, buffer);
      if (bytesRead <= 0) {
        throw new Error('备份文件内容不完整。');
      }
      await this.writeFully(destinationFd, buffer.slice(0, bytesRead));
      remaining -= bytesRead;
    }
  }

  private async discardBytes(sourceFd: number, byteCount: number): Promise<void> {
    let remaining = byteCount;
    while (remaining > 0) {
      const buffer = new ArrayBuffer(Math.min(FILE_CHUNK_BYTES, remaining));
      const bytesRead = await fileIo.read(sourceFd, buffer);
      if (bytesRead <= 0) {
        throw new Error('备份文件内容不完整。');
      }
      remaining -= bytesRead;
    }
  }

  private async readExact(sourceFd: number, byteCount: number): Promise<ArrayBuffer> {
    const target = new ArrayBuffer(byteCount);
    const targetBytes = new Uint8Array(target);
    let offset = 0;
    while (offset < byteCount) {
      const buffer = new ArrayBuffer(Math.min(FILE_CHUNK_BYTES, byteCount - offset));
      const bytesRead = await fileIo.read(sourceFd, buffer);
      if (bytesRead <= 0) {
        throw new Error('备份文件内容不完整。');
      }
      targetBytes.set(new Uint8Array(buffer, 0, bytesRead), offset);
      offset += bytesRead;
    }
    return target;
  }

  private async writeFully(destinationFd: number, buffer: ArrayBuffer): Promise<void> {
    let offset = 0;
    while (offset < buffer.byteLength) {
      const bytesWritten = await fileIo.write(destinationFd, buffer.slice(offset));
      if (bytesWritten <= 0) {
        throw new Error('备份文件写入失败。');
      }
      offset += bytesWritten;
    }
  }

  private async fileSize(path: string): Promise<number> {
    let file: fileIo.File | undefined;
    try {
      file = await fileIo.open(path, fileIo.OpenMode.READ_ONLY);
      return await this.fileSizeFromFd(file.fd);
    } finally {
      if (file !== undefined) {
        await this.closeQuietly(file);
      }
    }
  }

  private async fileSizeFromFd(fd: number): Promise<number> {
    const stat = await fileIo.stat(fd);
    if (!isNonNegativeInteger(stat.size)) {
      throw new Error('文件大小无效。');
    }
    return stat.size;
  }

  private async fileChecksum(path: string): Promise<string> {
    const checksum = (await hash.hash(path, SHA256_ALGORITHM)).toLowerCase();
    if (!isSha256Checksum(checksum)) {
      throw new Error(`文件“${leafName(path)}”完整性校验失败。`);
    }
    return checksum;
  }

  private async fileExists(path: string): Promise<boolean> {
    try {
      await fileIo.access(path);
      return true;
    } catch (error) {
      if (isMissingFileError(error as Error)) {
        return false;
      }
      throw new Error(errorText(error as Error));
    }
  }

  private async ensureDirectory(path: string): Promise<void> {
    try {
      await fileIo.mkdir(path, true);
    } catch (error) {
      if (!isAlreadyExistingPathError(error as Error)) {
        throw new Error(errorText(error as Error));
      }
    }
  }

  private photosDirectory(): string {
    return joinPath(this.context.filesDir, PHOTOS_DIRECTORY_NAME);
  }

  private photoPath(fileName: string): string {
    return joinPath(this.photosDirectory(), fileName);
  }

  private operationDirectory(type: string): string {
    return joinPath(
      this.context.filesDir,
      `backup-transfer/${type}-${Date.now()}-${Math.random().toString(36).substring(2, 10)}`
    );
  }

  private async cleanupExportDirectory(operationDirectory: string, databaseSnapshotPath: string): Promise<void> {
    await this.removeIfPresent(databaseSnapshotPath);
    await this.removeDirectoryIfPresent(operationDirectory);
  }

  private async cleanupImportDirectory(operationDirectory: string): Promise<void> {
    await this.removeDirectoryRecursively(operationDirectory);
  }

  private async removeDirectoryRecursively(path: string): Promise<void> {
    try {
      const entries = await fileIo.listFile(path);
      for (const entry of entries) {
        const childPath = joinPath(path, leafName(entry));
        try {
          await fileIo.unlink(childPath);
        } catch (_error) {
          await this.removeDirectoryRecursively(childPath);
        }
      }
    } catch (_error) {
    }
    await this.removeDirectoryIfPresent(path);
  }

  private async removeIfPresent(path: string): Promise<void> {
    try {
      await fileIo.unlink(path);
    } catch (_error) {
    }
  }

  private async removeDirectoryIfPresent(path: string): Promise<void> {
    try {
      await fileIo.rmdir(path);
    } catch (_error) {
    }
  }

  private async closeQuietly(file: fileIo.File): Promise<void> {
    try {
      await fileIo.close(file);
    } catch (_error) {
    }
  }
}
