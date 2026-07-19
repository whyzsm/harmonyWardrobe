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

function mustMatch(text, file, pattern, message) {
  if (!pattern.test(text)) {
    throw new Error(`${file} ${message}`);
  }
}

const runtimePath = 'entry/src/main/ets/app/WardrobeRuntime.ets';
const factoryPath = 'entry/src/main/ets/app/WardrobeRuntimeFactory.ets';
const photoFileSystemPath = 'entry/src/main/ets/media/HarmonyPhotoFileSystem.ets';
const searchBootstrapPath = 'entry/src/main/ets/data/searchIndex/SearchIndexBootstrap.ets';
const indexPath = 'entry/src/main/ets/pages/Index.ets';
const runtime = read(runtimePath);
const factory = read(factoryPath);
const photoFileSystem = read(photoFileSystemPath);
const searchBootstrap = read(searchBootstrapPath);
const index = read(indexPath);

for (const needle of [
  'WardrobeRuntimeFactory',
  'WardrobeRuntimeFactory.create',
  'new WardrobeRuntime('
]) {
  mustInclude(runtime, runtimePath, needle);
}

for (const needle of [
  '@kit.CoreFileKit',
  'fileIo',
  'MigrationRunner',
  'ensureBaseSchema',
  'rebuildSearchIndex',
  'new ClothingRepository',
  'new OutfitRepository',
  'new WearLogRepository',
  'new WishlistRepository',
  'new StoreRepository'
]) {
  mustNotInclude(runtime, runtimePath, needle);
}

for (const needle of [
  '@ohos.app.ability.common',
  'DatabaseProvider',
  'MigrationRunner',
  'v1InitialSchema',
  'v2ClothingPurchaseColumns',
  'v3StoreVisitSchema',
  'v4StoreVisitDetails',
  'v5ProfilePreferences',
  'runMigrations()',
  'detectSearchCapability',
  'new HarmonyPhotoFileSystem',
  'new PhotoStorage',
  'context.filesDir',
  'new ClothingRepository',
  'new OutfitRepository',
  'new WearLogRepository',
  'new WishlistRepository',
  'new StoreRepository',
  'new ProfileRepository',
  'new SearchRepository',
  'PhotoPickerAdapter.withHarmonyProviders',
  'SearchIndexBootstrap.ensureReady'
]) {
  mustInclude(factory, factoryPath, needle);
}

for (const needle of [
  'ensureBaseSchema',
  'v1InitialSchema.up(database)',
  'v2ClothingPurchaseColumns.up(database)',
  'v3StoreVisitSchema.up(database)',
  'v4StoreVisitDetails.up(database)',
  'v5ProfilePreferences.up(database)'
]) {
  mustNotInclude(factory, factoryPath, needle);
}

for (const [repositoryName, pattern] of [
  ['ClothingRepository', /new\s+ClothingRepository\s*\(\s*database\s*,\s*searchIndexMode\s*,\s*photoStorage\s*\)/],
  ['OutfitRepository', /new\s+OutfitRepository\s*\(\s*database\s*,\s*searchIndexMode\s*,\s*photoStorage\s*\)/],
  ['WearLogRepository', /new\s+WearLogRepository\s*\(\s*database\s*,\s*searchIndexMode\s*,\s*photoStorage\s*\)/],
  ['WishlistRepository', /new\s+WishlistRepository\s*\(\s*database\s*,\s*searchIndexMode\s*,\s*photoStorage\s*\)/],
  ['StoreRepository', /new\s+StoreRepository\s*\(\s*database\s*,\s*searchIndexMode\s*,\s*photoStorage\s*\)/]
]) {
  mustMatch(factory, factoryPath, pattern, `must pass PhotoStorage into ${repositoryName}`);
}

mustMatch(
  factory,
  factoryPath,
  /await\s+SearchIndexBootstrap\.ensureReady\s*\(/,
  'must conditionally ensure the search index during startup'
);
mustNotInclude(factory, factoryPath, 'await SearchIndexBootstrap.rebuild');
mustMatch(
  searchBootstrap,
  searchBootstrapPath,
  /dependencies\.searchRepository\.rebuildSearchIndex\s*\(\s*documents\s*\)/,
  'must delegate startup search rebuild to SearchRepository.rebuildSearchIndex'
);
for (const needle of [
  'buildClothingSearchDocument',
  'buildOutfitSearchDocument',
  'buildWearLogSearchDocument',
  'buildWishlistSearchDocument',
  'buildStoreSearchDocument',
  'buildStoreVisitSearchDocument',
  'listClothing()',
  'listOutfits()',
  'listWearLogs()',
  'listWishlistItems()',
  'listStores()',
  'listStoreVisits()'
]) {
  mustInclude(searchBootstrap, searchBootstrapPath, needle);
}

const copyFileStart = photoFileSystem.indexOf('async copyFile');
const deleteFileStart = photoFileSystem.indexOf('async deleteFile');
if (copyFileStart < 0 || deleteFileStart < 0 || copyFileStart >= deleteFileStart) {
  throw new Error(`${photoFileSystemPath} missing HarmonyPhotoFileSystem.copyFile`);
}

const copyFileBody = photoFileSystem.substring(copyFileStart, deleteFileStart);
for (const needle of [
  'try',
  'await fileIo.copyFile(sourceUri, destinationUri)',
  'catch',
  'await fileIo.open(sourceUri, fileIo.OpenMode.READ_ONLY)',
  'await fileIo.copyFile(sourceFile.fd, destinationUri)',
  'finally',
  'const closeError = await this.closeFile(sourceFile)',
  'fallbackFailure.message'
]) {
  mustInclude(copyFileBody, photoFileSystemPath, needle);
}

for (const needle of ['PhotoFileSystem', 'ensureDirectory', 'copyFile', 'deleteFile', 'fileIo.mkdir', 'fileIo.unlink']) {
  mustInclude(photoFileSystem, photoFileSystemPath, needle);
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
  mustNotInclude(factory, factoryPath, needle);
  mustNotInclude(photoFileSystem, photoFileSystemPath, needle);
  mustNotInclude(searchBootstrap, searchBootstrapPath, needle);
  mustNotInclude(index, indexPath, needle);
}

for (const needle of [
  'WardrobeRuntime',
  'const hostContext = this.getUIContext().getHostContext()',
  'hostContext === undefined',
  '应用上下文不可用，请稍后重试',
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
  'this.runtime.clothingRepository.listClothing()',
  'BottomNavigationBar({',
  'onSelectOutfit',
  'onOpenProfile',
  'QuickCaptureSheet({',
  'StoreVisitPage({',
  'storeRepository: this.runtime.storeRepository',
  'ProfilePage({',
  'profileRepository: this.runtime.profileRepository',
  'clothingRepository: this.runtime.clothingRepository',
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
      'searchRepository: this.searchRepository'
    ]
  },
  {
    file: 'entry/src/main/ets/pages/OutfitsPage.ets',
    needles: [
      'outfitRepository?: OutfitRepository',
      'clothingRepository?: ClothingRepository',
      'wearLogRepository?: WearLogRepository',
      'photoPickerAdapter?: PhotoPickerAdapter',
      'photoStorage?: PhotoStorage',
      'initialWearLogId',
      'loadOutfits',
      'listOutfits',
      'OutfitEditPage({',
      'WearLogEditPage({',
      'openWearLogById'
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
      'clothingRepository?: ClothingRepository',
      'storeRepository?: StoreRepository',
      'outfitRepository?: OutfitRepository',
      'aboutToAppear()',
      'loadProfile',
      'loadActivitySummary',
      'getClothingSummary',
      'getStoreVisitCount',
      'getOutfitCount',
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
