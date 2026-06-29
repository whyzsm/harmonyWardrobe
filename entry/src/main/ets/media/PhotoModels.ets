export interface PhotoSource {
  uri: string;
  fileName?: string;
  mimeType?: string;
}

export interface StoredPhoto {
  localUri: string;
  fileName: string;
  createdAt: string;
}

export interface PhotoDeleteResult {
  localUri: string;
  deleted: boolean;
  error?: string;
  retryable: boolean;
}

export interface PhotoFileSystem {
  ensureDirectory(path: string): Promise<void>;
  copyFile(sourceUri: string, destinationUri: string): Promise<void>;
  deleteFile(localUri: string): Promise<void>;
}
