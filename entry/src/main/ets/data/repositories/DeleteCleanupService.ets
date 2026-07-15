import { SearchEntityType } from '../../domain/search/SearchModels';
import { PhotoDeleteResult } from '../../media/PhotoModels';
import { PhotoStorage } from '../../media/PhotoStorage';
import { MigrationDatabase, MigrationSqlValue } from '../migrations/Migration';
import { SearchRepository } from './SearchRepository';

interface PhotoReferenceTable {
  tableName: string;
  ownerColumnName: string;
}

const PHOTO_REFERENCE_TABLES: PhotoReferenceTable[] = [
  { tableName: 'clothing_photos', ownerColumnName: 'clothing_id' },
  { tableName: 'outfit_photos', ownerColumnName: 'outfit_id' },
  { tableName: 'wear_log_photos', ownerColumnName: 'wear_log_id' },
  { tableName: 'wishlist_photos', ownerColumnName: 'wishlist_id' },
  { tableName: 'store_photos', ownerColumnName: 'store_id' },
  { tableName: 'store_visit_photos', ownerColumnName: 'store_visit_id' }
];

export interface DeleteCleanupResult {
  orphanPhotoUris: string[];
  photoDeleteResults: PhotoDeleteResult[];
  recoverable: boolean;
}

export class DeleteCleanupService {
  private readonly database: MigrationDatabase;
  private readonly searchRepository: SearchRepository;
  private readonly photoStorage?: PhotoStorage;

  constructor(
    database: MigrationDatabase,
    searchRepository: SearchRepository,
    photoStorage?: PhotoStorage
  ) {
    this.database = database;
    this.searchRepository = searchRepository;
    this.photoStorage = photoStorage;
  }

  async deleteObjectPhotos(
    tableName: string,
    ownerColumnName: string,
    ownerId: string
  ): Promise<DeleteCleanupResult> {
    const existingPhotoUris = await this.readPhotoUris(tableName, ownerColumnName, ownerId);
    const orphanPhotoUris = await this.unreferencedPhotoUris(
      tableName,
      ownerColumnName,
      ownerId,
      existingPhotoUris,
      []
    );
    await this.database.executeSql(`DELETE FROM ${tableName} WHERE ${ownerColumnName} = ?`, [ownerId]);

    return this.cleanupLocalPhotos(orphanPhotoUris);
  }

  async readObjectPhotoUris(tableName: string, ownerColumnName: string, ownerId: string): Promise<string[]> {
    return this.readPhotoUris(tableName, ownerColumnName, ownerId);
  }

  async cleanupReplacedPhotos(
    tableName: string,
    ownerColumnName: string,
    ownerId: string,
    existingPhotoUris: string[],
    retainedPhotoUris: string[]
  ): Promise<DeleteCleanupResult> {
    const orphanPhotoUris = await this.unreferencedPhotoUris(
      tableName,
      ownerColumnName,
      ownerId,
      existingPhotoUris,
      retainedPhotoUris
    );

    return this.cleanupLocalPhotos(orphanPhotoUris);
  }

  async deleteSearchDocument(
    entityType: SearchEntityType,
    entityId: string,
    deleteOperation?: Promise<void>
  ): Promise<void> {
    if (deleteOperation !== undefined) {
      await deleteOperation;
      return;
    }

    await this.searchRepository.deleteDocumentInTransaction(entityType, entityId);
  }

  private async readPhotoUris(tableName: string, ownerColumnName: string, ownerId: string): Promise<string[]> {
    const resultSet = await this.database.querySql(
      `SELECT local_uri FROM ${tableName} WHERE ${ownerColumnName} = ? ORDER BY sort_order ASC`,
      [ownerId]
    );
    const photoUris: string[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        const photoUri = resultSet.getString('local_uri');
        if (photoUri.length > 0) {
          photoUris.push(photoUri);
        }
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return photoUris;
  }

  private async unreferencedPhotoUris(
    tableName: string,
    ownerColumnName: string,
    ownerId: string,
    photoUris: string[],
    retainedPhotoUris: string[]
  ): Promise<string[]> {
    const retained = new Set<string>(retainedPhotoUris);
    const seen = new Set<string>();
    const orphanPhotoUris: string[] = [];

    for (const photoUri of photoUris) {
      if (retained.has(photoUri) || seen.has(photoUri)) {
        continue;
      }

      seen.add(photoUri);
      if (!(await this.isPhotoReferencedElsewhere(tableName, ownerColumnName, ownerId, photoUri))) {
        orphanPhotoUris.push(photoUri);
      }
    }

    return orphanPhotoUris;
  }

  private async isPhotoReferencedElsewhere(
    ownerTableName: string,
    ownerColumnName: string,
    ownerId: string,
    localUri: string
  ): Promise<boolean> {
    for (const referenceTable of PHOTO_REFERENCE_TABLES) {
      const sameOwnerTable = referenceTable.tableName === ownerTableName &&
        referenceTable.ownerColumnName === ownerColumnName;
      const ownerClause = sameOwnerTable ? ` AND ${referenceTable.ownerColumnName} <> ?` : '';
      const bindArgs: MigrationSqlValue[] = sameOwnerTable ? [localUri, ownerId] : [localUri];
      const resultSet = await this.database.querySql(
        `SELECT local_uri FROM ${referenceTable.tableName} WHERE local_uri = ?${ownerClause}`,
        bindArgs
      );

      try {
        if (resultSet.goToFirstRow()) {
          return true;
        }
      } finally {
        resultSet.close();
      }
    }

    return false;
  }

  private async cleanupLocalPhotos(orphanPhotoUris: string[]): Promise<DeleteCleanupResult> {
    const photoDeleteResults: PhotoDeleteResult[] = [];
    if (this.photoStorage !== undefined) {
      for (const orphanPhotoUri of orphanPhotoUris) {
        photoDeleteResults.push(await this.deleteLocalPhoto(orphanPhotoUri));
      }
    }

    const result: DeleteCleanupResult = {
      orphanPhotoUris,
      photoDeleteResults,
      recoverable: this.hasRecoverablePhotoFailure(photoDeleteResults)
    };
    this.throwIfPhotoCleanupFailed(result);
    return result;
  }

  private throwIfPhotoCleanupFailed(result: DeleteCleanupResult): void {
    if (!result.recoverable) {
      return;
    }

    for (const photoDeleteResult of result.photoDeleteResults) {
      if (!photoDeleteResult.deleted && photoDeleteResult.retryable) {
        throw new Error(`照片清理失败：${photoDeleteResult.localUri}，${photoDeleteResult.error ?? '请稍后重试'}`);
      }
    }
  }

  private async deleteLocalPhoto(localUri: string): Promise<PhotoDeleteResult> {
    if (this.photoStorage === undefined) {
      return {
        localUri,
        deleted: false,
        error: 'No local photo storage configured for orphan cleanup.',
        retryable: true
      };
    }

    return this.photoStorage.deleteLocalPhoto(localUri);
  }

  private hasRecoverablePhotoFailure(results: PhotoDeleteResult[]): boolean {
    for (const result of results) {
      if (!result.deleted && result.retryable) {
        return true;
      }
    }

    return false;
  }
}
