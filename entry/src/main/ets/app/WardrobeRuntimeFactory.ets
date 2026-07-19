import common from '@ohos.app.ability.common';
import { DatabaseProvider } from '../data/database/DatabaseProvider';
import { MigrationRunner } from '../data/migrations/MigrationRunner';
import { v1InitialSchema } from '../data/migrations/V1InitialSchema';
import { v2ClothingPurchaseColumns } from '../data/migrations/V2ClothingPurchaseColumns';
import { v3StoreVisitSchema } from '../data/migrations/V3StoreVisitSchema';
import { v4StoreVisitDetails } from '../data/migrations/V4StoreVisitDetails';
import { v5ProfilePreferences } from '../data/migrations/V5ProfilePreferences';
import { v6StoreNormalizedName } from '../data/migrations/V6StoreNormalizedName';
import { v7ProfileCommonLists } from '../data/migrations/V7ProfileCommonLists';
import { v8ProfileSizes } from '../data/migrations/V8ProfileSizes';
import { v9OutfitDisplaySource } from '../data/migrations/V9OutfitDisplaySource';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { ProfileRepository } from '../data/repositories/ProfileRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { WishlistRepository } from '../data/repositories/WishlistRepository';
import { detectSearchCapability, SearchIndexMode } from '../data/searchIndex/SearchCapability';
import { SearchIndexBootstrap } from '../data/searchIndex/SearchIndexBootstrap';
import { HarmonyPhotoFileSystem } from '../media/HarmonyPhotoFileSystem';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';

export interface WardrobeRuntimeDependencies {
  database: DatabaseProvider;
  searchIndexMode: SearchIndexMode;
  clothingRepository: ClothingRepository;
  outfitRepository: OutfitRepository;
  wearLogRepository: WearLogRepository;
  wishlistRepository: WishlistRepository;
  storeRepository: StoreRepository;
  profileRepository: ProfileRepository;
  searchRepository: SearchRepository;
  photoPickerAdapter: PhotoPickerAdapter;
  photoStorage: PhotoStorage;
}

export class WardrobeRuntimeFactory {
  static async create(context: common.Context): Promise<WardrobeRuntimeDependencies> {
    const database = new DatabaseProvider(context);
    const migrationRunner = new MigrationRunner(database, [
      v1InitialSchema,
      v2ClothingPurchaseColumns,
      v3StoreVisitSchema,
      v4StoreVisitDetails,
      v5ProfilePreferences,
      v6StoreNormalizedName,
      v7ProfileCommonLists,
      v8ProfileSizes,
      v9OutfitDisplaySource
    ]);
    await migrationRunner.runMigrations();

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

    await SearchIndexBootstrap.ensureReady({
      database,
      searchIndexMode,
      searchRepository,
      clothingRepository,
      outfitRepository,
      wearLogRepository,
      wishlistRepository,
      storeRepository
    });

    return {
      database,
      searchIndexMode,
      clothingRepository,
      outfitRepository,
      wearLogRepository,
      wishlistRepository,
      storeRepository,
      profileRepository,
      searchRepository,
      photoPickerAdapter: PhotoPickerAdapter.withHarmonyProviders(context),
      photoStorage
    };
  }
}
