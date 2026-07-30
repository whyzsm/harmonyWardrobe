export interface LocalBackupExportResult {
  photoCount: number;
  totalBytes: number;
}

export interface LocalBackupRestoreResult {
  photoCount: number;
}

export interface LocalBackupLifecycle {
  afterDatabaseRestored: () => Promise<void>;
  afterPhotoUrisRemapped: () => Promise<void>;
}
