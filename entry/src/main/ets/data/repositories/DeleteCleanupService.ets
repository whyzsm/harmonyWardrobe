import { SearchEntityType } from '../../domain/search/SearchModels';
import { PhotoDeleteResult } from '../../media/PhotoModels';
import { PhotoStorage } from '../../media/PhotoStorage';
import { MigrationDatabase } from '../migrations/Migration';
import { SearchRepository } from './SearchRepository';

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
    const orphanPhotoUris = await this.readPhotoUris(tableName, ownerColumnName, ownerId);
    await this.database.executeSql(`DELETE FROM ${tableName} WHERE ${ownerColumnName} = ?`, [ownerId]);

    const photoDeleteResults: PhotoDeleteResult[] = [];
    if (this.photoStorage !== undefined) {
      for (const orphanPhotoUri of orphanPhotoUris) {
        photoDeleteResults.push(await this.deleteLocalPhoto(orphanPhotoUri));
      }
    }

    return {
      orphanPhotoUris,
      photoDeleteResults,
      recoverable: this.hasRecoverablePhotoFailure(photoDeleteResults)
    };
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
