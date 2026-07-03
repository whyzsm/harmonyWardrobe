import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }

  return fs.readFileSync(file, 'utf8');
}

function mustInclude(text, file, needle) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function mustNotInclude(text, file, needle) {
  if (text.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

const runtimePath = 'entry/src/main/ets/app/WardrobeRuntime.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const runtime = read(runtimePath);
const index = read(indexPath);

for (const needle of [
  '@ohos.app.ability.common',
  '@kit.CoreFileKit',
  'fileIo.mkdir',
  'fileIo.copyFile',
  'fileIo.unlink',
  'PhotoFileSystem',
  'DatabaseProvider',
  'MigrationRunner',
  'v1InitialSchema',
  'v3StoreVisitSchema',
  'detectSearchCapability',
  'new ClothingRepository',
  'new OutfitRepository',
  'new WearLogRepository',
  'new WishlistRepository',
  'new StoreRepository',
  'new ProfileRepository',
  'new SearchRepository',
  'PhotoPickerAdapter.withHarmonyProviders',
  'new PhotoStorage',
  'context.filesDir',
  'runMigrations()',
  'ensureBaseSchema',
  'v1InitialSchema.up(database)',
  'v3StoreVisitSchema.up(database)'
]) {
  mustInclude(runtime, runtimePath, needle);
}

for (const needle of [
  'http.',
  '@ohos.net',
  '@kit.NetworkKit',
  'requestPermissions',
  'ohos.permission.INTERNET',
  ': any',
  ': unknown'
]) {
  mustNotInclude(runtime, runtimePath, needle);
  mustNotInclude(index, indexPath, needle);
}

for (const needle of [
  'WardrobeRuntime',
  'getContext(this) as common.Context',
  'WardrobeRuntime.create',
  '@State private runtimeReady',
  'clothingRepository: this.runtime.clothingRepository',
  'outfitRepository: this.runtime.outfitRepository',
  'WardrobePage({',
  'clothingRepository: this.runtime.clothingRepository',
  'outfitRepository: this.runtime.outfitRepository',
  'searchRepository: this.runtime.searchRepository',
  'photoPickerAdapter: this.runtime.photoPickerAdapter',
  'photoStorage: this.runtime.photoStorage',
  'ClothingEditPage({',
  'OutfitEditPage({',
  'this.runtime.clothingRepository.listClothing()',
  'AppTopBar({',
  'BottomNavigationBar({',
  'QuickCaptureSheet({',
  'StoreVisitPage({',
  'storeRepository: this.runtime.storeRepository',
  'StoreVisitEditPage({',
  'ProfilePage({',
  'profileRepository: this.runtime.profileRepository',
  '正在初始化'
]) {
  mustInclude(index, indexPath, needle);
}

const pageChecks = [
  {
    file: 'entry/src/main/ets/pages/WardrobePage.ets',
    needles: [
      'clothingRepository?: ClothingRepository',
      'outfitRepository?: OutfitRepository',
      'searchRepository?: SearchRepository',
      'photoPickerAdapter?: PhotoPickerAdapter',
      'photoStorage?: PhotoStorage',
      'aboutToAppear()',
      'loadClothingItems',
      'listClothing',
      'ClothingEditPage({',
      'photoPickerAdapter: this.photoPickerAdapter',
      'photoStorage: this.photoStorage',
      'SearchResultsPage({',
      'searchRepository: this.searchRepository',
      'OutfitEditPage({'
    ]
  },
  {
    file: 'entry/src/main/ets/pages/StoreVisitPage.ets',
    needles: [
      'storeRepository?: StoreRepository',
      'photoPickerAdapter?: PhotoPickerAdapter',
      'photoStorage?: PhotoStorage',
      'aboutToAppear()',
      'loadStoreVisits',
      'listStoreVisits',
      'StoreVisitEditPage({'
    ]
  },
  {
    file: 'entry/src/main/ets/pages/ProfilePage.ets',
    needles: [
      'profileRepository?: ProfileRepository',
      'aboutToAppear()',
      'loadProfile',
      'saveProfile'
    ]
  }
];

for (const check of pageChecks) {
  const text = read(check.file);
  for (const needle of check.needles) {
    mustInclude(text, check.file, needle);
  }

  for (const forbidden of [
    '@Prop clothingRepository',
    '@Prop outfitRepository',
    '@Prop wearLogRepository',
    '@Prop wishlistRepository',
    '@Prop searchRepository',
    '@Prop photoPickerAdapter',
    '@Prop photoStorage'
  ]) {
    mustNotInclude(text, check.file, forbidden);
  }
}

console.log('PASS');
