import common from '@ohos.app.ability.common';
import { DatabaseProvider } from '../data/database/DatabaseProvider';
import { WardrobeRuntimeFactory } from './WardrobeRuntimeFactory';
import { ClothingRepository } from '../data/repositories/ClothingRepository';
import { OutfitRepository } from '../data/repositories/OutfitRepository';
import { ProfileRepository } from '../data/repositories/ProfileRepository';
import { SearchRepository } from '../data/repositories/SearchRepository';
import { StoreRepository } from '../data/repositories/StoreRepository';
import { WearLogRepository } from '../data/repositories/WearLogRepository';
import { WishlistRepository } from '../data/repositories/WishlistRepository';
import { SearchIndexMode } from '../data/searchIndex/SearchCapability';
import { PhotoPickerAdapter } from '../media/PhotoPickerAdapter';
import { PhotoStorage } from '../media/PhotoStorage';
import { WeatherService } from '../services/WeatherService';

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
  readonly weatherService: WeatherService;

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
    photoStorage: PhotoStorage,
    weatherService: WeatherService
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
    this.weatherService = weatherService;
  }

  static async create(context: common.Context): Promise<WardrobeRuntime> {
    const dependencies = await WardrobeRuntimeFactory.create(context);

    return new WardrobeRuntime(
      dependencies.database,
      dependencies.searchIndexMode,
      dependencies.clothingRepository,
      dependencies.outfitRepository,
      dependencies.wearLogRepository,
      dependencies.wishlistRepository,
      dependencies.storeRepository,
      dependencies.profileRepository,
      dependencies.searchRepository,
      dependencies.photoPickerAdapter,
      dependencies.photoStorage,
      dependencies.weatherService
    );
  }
}
