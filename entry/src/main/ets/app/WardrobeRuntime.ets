import common from '@ohos.app.ability.common';
import { fileIo } from '@kit.CoreFileKit';
import { DatabaseProvider } from '../data/database/DatabaseProvider';
import { MigrationRunner } from '../data/migrations/MigrationRunner';
import { v1InitialSchema } from '../data/migrations/V1InitialSchema';
import { v2ClothingPurchaseColumns } from '../data/migrations/V2ClothingPurchaseColumns';
import { v3StoreVisitSchema } from '../data/migrations/V3StoreVisitSchema';
import { v4StoreVisitDetails } from '../data/migrations/V4StoreVisitDetails';
import { v5ProfilePreferences } from '../data/migrations/V5ProfilePreferences';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { ProfileRepository } from '../data/repositories/ProfileRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { WishlistRepository } from '../data/repositories/WishlistRepository';
import { detectSearchCapability, SearchIndexMode } from '../data/searchIndex/SearchCapability';
import {
  buildClothingSearchDocument,
  buildOutfitSearchDocument,
  buildStoreSearchDocument,
  buildStoreVisitSearchDocument,
  buildWearLogSearchDocument,
  buildWishlistSearchDocument,
  SearchDocument
} from '../domain/search/SearchDocumentBuilder';
import { ClothingItem } from '../domain/clothing/ClothingModels';
import { OutfitTemplate } from '../domain/outfit/OutfitModels';
import { PhotoFileSystem } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';

interface RuntimeErrorLike {
  message?: string;
  code?: string | number;
}

type RuntimeThrowable = Error | string | RuntimeErrorLike;

class HarmonyPhotoFileSystem implements PhotoFileSystem {
  async ensureDirectory(path: string): Promise<void> {
    try {
      await fileIo.mkdir(path, true);
    } catch (error) {
      throw new Error(`Failed to create photo directory "${path}": ${runtimeErrorText(error as RuntimeThrowable)}`);
    }
  }

  async copyFile(sourceUri: string, destinationUri: string): Promise<void> {
    try {
      await fileIo.copyFile(sourceUri, destinationUri);
      return;
    } catch (copyError) {
      let sourceFile: fileIo.File | undefined;
      let fallbackFailure: Error | undefined;
      try {
        sourceFile = await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY);
        await fileIo.copyFile(sourceFile.fd, destinationUri);
      } catch (fallbackError) {
        fallbackFailure = new Error(
          `Failed to copy photo "${sourceUri}" to "${destinationUri}": ${runtimeErrorText(fallbackError as RuntimeThrowable)}; direct copy: ${runtimeErrorText(copyError as RuntimeThrowable)}`
        );
      } finally {
        if (sourceFile !== undefined) {
          const closeError = await this.closeFile(sourceFile);
          if (fallbackFailure !== undefined && closeError !== undefined) {
            fallbackFailure.message = `${fallbackFailure.message}; close: ${closeError}`;
          }
        }
      }

      if (fallbackFailure !== undefined) {
        throw fallbackFailure;
      }
    }
  }

  async deleteFile(localUri: string): Promise<void> {
    try {
      await fileIo.unlink(localUri);
    } catch (error) {
      throw new Error(`Failed to delete photo "${localUri}": ${runtimeErrorText(error as RuntimeThrowable)}`);
    }
  }

  private async closeFile(file: fileIo.File): Promise<string | undefined> {
    try {
      await fileIo.close(file);
      return undefined;
    } catch (error) {
      return runtimeErrorText(error as RuntimeThrowable);
    }
  }
}

function runtimeErrorText(error: RuntimeThrowable): string {
  if (error instanceof Error && error.message.length > 0) {
    return error.message;
  }

  if (typeof error === 'string' && error.length > 0) {
    return error;
  }

  return runtimeErrorLikeText(error as RuntimeErrorLike);
}

function runtimeErrorLikeText(error: RuntimeErrorLike): string {
  const message = error.message;
  if (message !== undefined && message.length > 0) {
    return message;
  }

  const code = error.code;
  return code !== undefined ? String(code) : 'unavailable error detail';
}

export class WardrobeRuntime {
  readonly database: DatabaseProvider;
  readonly searchIndexMode: SearchIndexMode;
  readonly clothingRepository: ClothingRepository;
  readonly outfitRepository: OutfitRepository;
  readonly wearLogRepository: WearLogRepository;
  readonly wishlistRepository: WishlistRepository;
  readonly storeRepository: StoreRepository;
  readonly profileRepository: ProfileRepository;
  readonly searchRepository: SearchRepository;
  readonly photoPickerAdapter: PhotoPickerAdapter;
  readonly photoStorage: PhotoStorage;

  private constructor(
    database: DatabaseProvider,
    searchIndexMode: SearchIndexMode,
    clothingRepository: ClothingRepository,
    outfitRepository: OutfitRepository,
    wearLogRepository: WearLogRepository,
    wishlistRepository: WishlistRepository,
    storeRepository: StoreRepository,
    profileRepository: ProfileRepository,
    searchRepository: SearchRepository,
    photoPickerAdapter: PhotoPickerAdapter,
    photoStorage: PhotoStorage
  ) {
    this.database = database;
    this.searchIndexMode = searchIndexMode;
    this.clothingRepository = clothingRepository;
    this.outfitRepository = outfitRepository;
    this.wearLogRepository = wearLogRepository;
    this.wishlistRepository = wishlistRepository;
    this.storeRepository = storeRepository;
    this.profileRepository = profileRepository;
    this.searchRepository = searchRepository;
    this.photoPickerAdapter = photoPickerAdapter;
    this.photoStorage = photoStorage;
  }

  static async create(context: common.Context): Promise<WardrobeRuntime> {
    const database = new DatabaseProvider(context);
    const migrationRunner = new MigrationRunner(database, [
      v1InitialSchema,
      v2ClothingPurchaseColumns,
      v3StoreVisitSchema,
      v4StoreVisitDetails,
      v5ProfilePreferences
    ]);
    await migrationRunner.runMigrations();
    await WardrobeRuntime.ensureBaseSchema(database);

    const searchCapability = await detectSearchCapability(database);
    const searchIndexMode = searchCapability.mode;
    const photoStorage = new PhotoStorage(context.filesDir, new HarmonyPhotoFileSystem());
    const clothingRepository = new ClothingRepository(database, searchIndexMode, photoStorage);
    const outfitRepository = new OutfitRepository(database, searchIndexMode, photoStorage);
    const wearLogRepository = new WearLogRepository(database, searchIndexMode, photoStorage);
    const wishlistRepository = new WishlistRepository(database, searchIndexMode, photoStorage);
    const storeRepository = new StoreRepository(database, searchIndexMode, photoStorage);
    const profileRepository = new ProfileRepository(database);
    const searchRepository = new SearchRepository(database, searchIndexMode);

    await WardrobeRuntime.rebuildSearchIndex(
      searchRepository,
      clothingRepository,
      outfitRepository,
      wearLogRepository,
      wishlistRepository,
      storeRepository
    );

    return new WardrobeRuntime(
      database,
      searchIndexMode,
      clothingRepository,
      outfitRepository,
      wearLogRepository,
      wishlistRepository,
      storeRepository,
      profileRepository,
      searchRepository,
      PhotoPickerAdapter.withHarmonyProviders(context),
      photoStorage
    );
  }

  private static async rebuildSearchIndex(
    searchRepository: SearchRepository,
    clothingRepository: ClothingRepository,
    outfitRepository: OutfitRepository,
    wearLogRepository: WearLogRepository,
    wishlistRepository: WishlistRepository,
    storeRepository: StoreRepository
  ): Promise<void> {
    const clothingItems = await clothingRepository.listClothing();
    const outfits = await outfitRepository.listOutfits();
    const wearLogs = await wearLogRepository.listWearLogs();
    const wishlistItems = await wishlistRepository.listWishlistItems();
    const stores = await storeRepository.listStores();
    const storeVisits = await storeRepository.listStoreVisits();
    const clothingNameById = WardrobeRuntime.buildClothingNameById(clothingItems);
    const documents: SearchDocument[] = [];

    for (const item of clothingItems) {
      documents.push(buildClothingSearchDocument(item));
    }

    for (const outfit of outfits) {
      documents.push(buildOutfitSearchDocument(outfit, WardrobeRuntime.clothingNamesForOutfit(outfit, clothingNameById)));
    }

    for (const wearLog of wearLogs) {
      documents.push(buildWearLogSearchDocument(wearLog));
    }

    for (const item of wishlistItems) {
      documents.push(buildWishlistSearchDocument(item));
    }

    for (const store of stores) {
      documents.push(buildStoreSearchDocument(store));
    }

    for (const visit of storeVisits) {
      documents.push(buildStoreVisitSearchDocument(visit));
    }

    await searchRepository.rebuildSearchIndex(documents);
  }

  private static buildClothingNameById(clothingItems: ClothingItem[]): Map<string, string> {
    const clothingNameById = new Map<string, string>();
    for (const item of clothingItems) {
      clothingNameById.set(item.id, item.name);
    }
    return clothingNameById;
  }

  private static clothingNamesForOutfit(outfit: OutfitTemplate, clothingNameById: Map<string, string>): string[] {
    const names: string[] = [];
    for (const itemId of outfit.clothingItemIds) {
      const name = clothingNameById.get(itemId);
      if (name !== undefined) {
        names.push(name);
      }
    }
    return names;
  }

  private static async ensureBaseSchema(database: DatabaseProvider): Promise<void> {
    await v1InitialSchema.up(database);
    await v2ClothingPurchaseColumns.up(database);
    await v3StoreVisitSchema.up(database);
    await v4StoreVisitDetails.up(database);
    await v5ProfilePreferences.up(database);
  }
}
