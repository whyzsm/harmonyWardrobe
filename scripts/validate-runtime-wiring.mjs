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
  'detectSearchCapability',
  'new ClothingRepository',
  'new OutfitRepository',
  'new WearLogRepository',
  'new WishlistRepository',
  'new SearchRepository',
  'PhotoPickerAdapter.withHarmonyProviders',
  'new PhotoStorage',
  'context.filesDir',
  'runMigrations()',
  'ensureBaseSchema',
  'v1InitialSchema.up(database)'
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
  'TodayPage({',
  'clothingRepository: this.runtime.clothingRepository',
  'outfitRepository: this.runtime.outfitRepository',
  'wearLogRepository: this.runtime.wearLogRepository',
  'WardrobePage({',
  'clothingRepository: this.runtime.clothingRepository',
  'searchRepository: this.runtime.searchRepository',
  'photoPickerAdapter: this.runtime.photoPickerAdapter',
  'photoStorage: this.runtime.photoStorage',
  'ClothingEditPage({',
  'OutfitEditPage({',
  'WearLogEditPage({',
  'this.runtime.outfitRepository.listOutfits()',
  'this.runtime.clothingRepository.listClothing()',
  'CalendarPage({',
  'ShoppingPage({',
  'runtime / 正在初始化'
]) {
  mustInclude(index, indexPath, needle);
}

const pageChecks = [
  {
    file: 'entry/src/main/ets/pages/WardrobePage.ets',
    needles: [
      'clothingRepository?: ClothingRepository',
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
      'searchRepository?: SearchRepository',
      'photoPickerAdapter?: PhotoPickerAdapter',
      'photoStorage?: PhotoStorage',
      'aboutToAppear()',
      'loadOutfits',
      'listOutfits',
      'OutfitEditPage({',
      'WearLogEditPage({',
      'SearchResultsPage({',
      'searchRepository: this.searchRepository'
    ]
  },
  {
    file: 'entry/src/main/ets/pages/TodayPage.ets',
    needles: [
      'clothingRepository?: ClothingRepository',
      'outfitRepository?: OutfitRepository',
      'wearLogRepository?: WearLogRepository',
      'photoPickerAdapter?: PhotoPickerAdapter',
      'photoStorage?: PhotoStorage',
      'onOpenRecommendation?:',
      'aboutToAppear()',
      'loadToday',
      'listOutfits',
      'listWearLogsByDate',
      'HomeRecommendation'
    ]
  },
  {
    file: 'entry/src/main/ets/pages/CalendarPage.ets',
    needles: [
      'outfitRepository?: OutfitRepository',
      'wearLogRepository?: WearLogRepository',
      'photoPickerAdapter?: PhotoPickerAdapter',
      'photoStorage?: PhotoStorage',
      'aboutToAppear()',
      'loadCalendar',
      'listWearLogDatesForMonth',
      'listWearLogsByDate',
      'WearLogEditPage({'
    ]
  },
  {
    file: 'entry/src/main/ets/pages/ShoppingPage.ets',
    needles: [
      'wishlistRepository?: WishlistRepository',
      'searchRepository?: SearchRepository',
      'photoPickerAdapter?: PhotoPickerAdapter',
      'photoStorage?: PhotoStorage',
      'aboutToAppear()',
      'loadWishlistItems',
      'listWishlistItems',
      'WishlistEditPage({',
      'SearchResultsPage({',
      'searchRepository: this.searchRepository'
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
