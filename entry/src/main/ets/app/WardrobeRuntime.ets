import common from '@ohos.app.ability.common';
import { fileIo } from '@kit.CoreFileKit';
import { DatabaseProvider } from '../data/database/DatabaseProvider';
import { MigrationRunner } from '../data/migrations/MigrationRunner';
import { v1InitialSchema } from '../data/migrations/V1InitialSchema';
import { v2ClothingPurchaseColumns } from '../data/migrations/V2ClothingPurchaseColumns';
import { v3StoreVisitSchema } from '../data/migrations/V3StoreVisitSchema';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { ProfileRepository } from '../data/repositories/ProfileRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { WishlistRepository } from '../data/repositories/WishlistRepository';
import { detectSearchCapability, SearchIndexMode } from '../data/searchIndex/SearchCapability';
import { PhotoFileSystem } from '../media/PhotoModels';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';

class HarmonyPhotoFileSystem implements PhotoFileSystem {
  async ensureDirectory(path: string): Promise<void> {
    await fileIo.mkdir(path, true);
  }

  async copyFile(sourceUri: string, destinationUri: string): Promise<void> {
    await fileIo.copyFile(sourceUri, destinationUri);
  }

  async deleteFile(localUri: string): Promise<void> {
    await fileIo.unlink(localUri);
  }
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
    const migrationRunner = new MigrationRunner(database, [v1InitialSchema, v2ClothingPurchaseColumns, v3StoreVisitSchema]);
    await migrationRunner.runMigrations();
    await WardrobeRuntime.ensureBaseSchema(database);

    const searchCapability = await detectSearchCapability(database);
    const searchIndexMode = searchCapability.mode;
    const photoStorage = new PhotoStorage(context.filesDir, new HarmonyPhotoFileSystem());

    return new WardrobeRuntime(
      database,
      searchIndexMode,
      new ClothingRepository(database, searchIndexMode),
      new OutfitRepository(database, searchIndexMode),
      new WearLogRepository(database, searchIndexMode),
      new WishlistRepository(database, searchIndexMode),
      new StoreRepository(database, searchIndexMode),
      new ProfileRepository(database),
      new SearchRepository(database, searchIndexMode),
      PhotoPickerAdapter.withHarmonyProviders(context),
      photoStorage
    );
  }

  private static async ensureBaseSchema(database: DatabaseProvider): Promise<void> {
    await v1InitialSchema.up(database);
    await v2ClothingPurchaseColumns.up(database);
    await v3StoreVisitSchema.up(database);
  }
}
