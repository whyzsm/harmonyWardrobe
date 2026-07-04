import {
  PhotoDeleteResult,
  PhotoFileSystem,
  PhotoSource,
  StoredPhoto
} from './PhotoModels';

const PHOTOS_DIR_NAME = 'photos';
const DEFAULT_PHOTO_EXTENSION = 'jpg';
const ALLOWED_PHOTO_EXTENSIONS: string[] = ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'];
const LOCAL_FILE_URI_PREFIX = 'file://';
const MAX_COPY_ATTEMPTS = 3;

interface ErrorLike {
  message?: string;
  code?: string | number;
}

type ThrowableError = Error | string | ErrorLike;

export interface PhotoStorageOptions {
  clock?: () => string;
  idFactory?: () => string;
}

function defaultClock(): string {
  return new Date().toISOString();
}

function defaultIdFactory(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).substring(2, 10)}`;
}

function trimTrailingSlashes(path: string): string {
  return path.replace(/[\/\\]+$/g, '');
}

function trimLeadingSlashes(path: string): string {
  return path.replace(/^[\/\\]+/g, '');
}

function joinPath(parent: string, child: string): string {
  const cleanParent = trimTrailingSlashes(parent);
  const cleanChild = trimLeadingSlashes(child);

  if (parent === '/') {
    return `/${cleanChild}`;
  }

  if (cleanParent.length === 0) {
    return cleanChild;
  }

  return `${cleanParent}/${cleanChild}`;
}

function localPathFromUri(localUri: string): string {
  if (localUri.startsWith(LOCAL_FILE_URI_PREFIX)) {
    return localUri.substring(LOCAL_FILE_URI_PREFIX.length);
  }

  return localUri;
}

function displayUriFromLocalPath(localPath: string): string {
  if (localPath.startsWith(LOCAL_FILE_URI_PREFIX)) {
    return localPath;
  }

  return `${LOCAL_FILE_URI_PREFIX}${localPath}`;
}

function sourceNameFromUri(uri: string): string {
  const withoutQuery = uri.split('?')[0].split('#')[0];
  const parts = withoutQuery.split(/[\/\\]/);

  return parts.length > 0 ? parts[parts.length - 1] : '';
}

function sanitizeNamePart(value: string): string {
  const sanitized = value
    .normalize('NFKC')
    .replace(/[\/\\]+/g, '-')
    .replace(/[^A-Za-z0-9._-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/\.+/g, '.');

  return sanitized.length > 0 ? sanitized : 'photo';
}

function sanitizeExtension(extension: string | undefined, mimeType: string | undefined): string {
  const extensionFromName = extension ?? '';
  const cleanExtension = extensionFromName
    .normalize('NFKC')
    .replace(/[^A-Za-z0-9]+/g, '')
    .toLowerCase();

  if (ALLOWED_PHOTO_EXTENSIONS.includes(cleanExtension)) {
    return cleanExtension;
  }

  const cleanMimeType = (mimeType ?? '').split(';')[0].trim().toLowerCase();

  if (cleanMimeType === 'image/png') {
    return 'png';
  }

  if (cleanMimeType === 'image/webp') {
    return 'webp';
  }

  if (cleanMimeType === 'image/heic') {
    return 'heic';
  }

  if (cleanMimeType === 'image/heif') {
    return 'heif';
  }

  if (cleanMimeType === 'image/jpeg' || cleanMimeType === 'image/jpg') {
    return 'jpg';
  }

  return DEFAULT_PHOTO_EXTENSION;
}

function sanitizeBaseName(rawFileName: string, extension: string | undefined): string {
  const safeWholeName = sanitizeNamePart(rawFileName);
  if (extension === undefined || extension.length === 0) {
    return safeWholeName;
  }

  const suffix = `.${extension}`;
  if (safeWholeName.toLowerCase().endsWith(suffix.toLowerCase())) {
    const withoutExtension = safeWholeName.substring(0, safeWholeName.length - suffix.length);
    return withoutExtension.length > 0 ? withoutExtension : 'photo';
  }

  return safeWholeName;
}

function buildSafeOriginalName(source: PhotoSource): string {
  const explicitName = sourceNameFromUri(source.fileName ?? '');
  const fallbackName = sourceNameFromUri(source.uri);
  const candidate = explicitName.length > 0 ? explicitName : fallbackName;

  return candidate.length > 0 ? candidate : 'photo';
}

function splitExtension(rawFileName: string): string | undefined {
  const normalizedName = rawFileName.replace(/[\/\\]+/g, '/');
  const leafName = sourceNameFromUri(normalizedName);
  const dotIndex = leafName.lastIndexOf('.');

  if (dotIndex <= 0 || dotIndex === leafName.length - 1) {
    return undefined;
  }

  return leafName.substring(dotIndex + 1);
}

function sanitizeTimestamp(timestamp: string): string {
  return timestamp.replace(/[^A-Za-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}

function hasParentPathSegment(path: string): boolean {
  return path.split(/[\/\\]/).includes('..');
}

function errorMessage(error: Error | string | null | undefined): string {
  return error instanceof Error ? error.message : String(error ?? 'Delete failed');
}

function errorText(error: ThrowableError | null | undefined): string {
  if (error instanceof Error) {
    return errorMessage(error);
  }

  if (typeof error === 'string') {
    return error;
  }

  if (error === null || error === undefined) {
    return 'Delete failed';
  }

  if (error.message !== undefined && error.message.length > 0) {
    return error.message;
  }

  if (error.code !== undefined) {
    return String(error.code);
  }

  return 'Delete failed';
}

function isFileExistsError(error: ThrowableError | null | undefined): boolean {
  const message = errorText(error).toLowerCase();
  return message.includes('file exists') || message.includes('eexist');
}

function copyErrorText(error: ThrowableError | null | undefined): string {
  return errorText(error).replace(/^Delete failed$/, 'Photo copy failed');
}

export class PhotoStorage {
  private readonly rootDir: string;
  private readonly fileSystem: PhotoFileSystem;
  private readonly clock: () => string;
  private readonly idFactory: () => string;

  constructor(rootDir: string, fileSystem: PhotoFileSystem, options?: PhotoStorageOptions) {
    this.rootDir = rootDir;
    this.fileSystem = fileSystem;
    this.clock = options?.clock ?? defaultClock;
    this.idFactory = options?.idFactory ?? defaultIdFactory;
  }

  async copyToAppStorage(source: PhotoSource): Promise<StoredPhoto> {
    const photosDir = this.photosDir();
    const createdAt = this.clock();
    const safeOriginalName = buildSafeOriginalName(source);
    const safeExtension = sanitizeExtension(splitExtension(safeOriginalName), source.mimeType);
    const safeBaseName = sanitizeBaseName(safeOriginalName, safeExtension);

    try {
      await this.fileSystem.ensureDirectory(photosDir);
    } catch (error) {
      const caughtError = error as ThrowableError;
      if (!isFileExistsError(caughtError)) {
        throw new Error(copyErrorText(caughtError));
      }
    }

    for (let attempt = 0; attempt < MAX_COPY_ATTEMPTS; attempt += 1) {
      const fileName = `${sanitizeTimestamp(createdAt)}-${sanitizeNamePart(this.idFactory())}-${safeBaseName}.${safeExtension}`;
      const localPath = joinPath(photosDir, fileName);

      try {
        await this.fileSystem.copyFile(source.uri, localPath);

        return {
          localUri: displayUriFromLocalPath(localPath),
          fileName,
          createdAt
        };
      } catch (error) {
        const caughtError = error as ThrowableError;
        if (!isFileExistsError(caughtError) || attempt === MAX_COPY_ATTEMPTS - 1) {
          throw new Error(copyErrorText(caughtError));
        }
      }
    }

    throw new Error('Photo copy failed after retrying existing destination names.');
  }

  async deleteLocalPhoto(localUri: string): Promise<PhotoDeleteResult> {
    if (!this.isManagedPhotoUri(localUri)) {
      return {
        localUri,
        deleted: false,
        error: 'Photo path is outside managed storage.',
        retryable: true
      };
    }

    try {
      await this.fileSystem.deleteFile(localPathFromUri(localUri));

      return {
        localUri,
        deleted: true,
        retryable: false
      };
    } catch (error) {
      const caughtError = error as ThrowableError;
      return {
        localUri,
        deleted: false,
        error: errorText(caughtError),
        retryable: true
      };
    }
  }

  private photosDir(): string {
    return joinPath(this.rootDir, PHOTOS_DIR_NAME);
  }

  private isManagedPhotoUri(localUri: string): boolean {
    const localPath = localPathFromUri(localUri);
    const photosDir = this.photosDir();
    return !hasParentPathSegment(localPath) && localPath.startsWith(`${photosDir}/`);
  }
}
