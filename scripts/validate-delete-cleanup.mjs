import fs from 'node:fs';

const servicePath = 'entry/src/main/ets/data/repositories/DeleteCleanupService.ets';

if (!fs.existsSync(servicePath)) {
  throw new Error(`${servicePath} does not exist`);
}

const service = fs.readFileSync(servicePath, 'utf8');
for (const needle of [
  'DeleteCleanupService',
  'deleteObjectPhotos',
  'deleteSearchDocument',
  'deleteLocalPhoto',
  'orphan',
  'PhotoStorage',
  'PhotoDeleteResult',
  'MigrationDatabase',
  'SearchRepository',
  'SearchEntityType',
  'recoverable'
]) {
  if (!service.includes(needle)) {
    throw new Error(`DeleteCleanupService missing ${needle}`);
  }
}

for (const [path, needles] of [
  ['entry/src/main/ets/data/repositories/ClothingRepository.ets', ['DeleteCleanupService', 'PhotoStorage', 'deleteObjectPhotos', 'deleteDocumentInTransaction', 'SearchEntityType.Clothing']],
  ['entry/src/main/ets/data/repositories/OutfitRepository.ets', ['DeleteCleanupService', 'PhotoStorage', 'deleteObjectPhotos', 'deleteDocumentInTransaction', 'SearchEntityType.Outfit']],
  ['entry/src/main/ets/data/repositories/WearLogRepository.ets', ['DeleteCleanupService', 'PhotoStorage', 'deleteObjectPhotos', 'deleteDocumentInTransaction', 'SearchEntityType.WearLog']],
  ['entry/src/main/ets/data/repositories/WishlistRepository.ets', ['DeleteCleanupService', 'PhotoStorage', 'deleteObjectPhotos', 'deleteDocumentInTransaction', 'SearchEntityType.Wishlist']],
  ['entry/src/main/ets/data/repositories/StoreRepository.ets', ['DeleteCleanupService', 'PhotoStorage', 'deleteObjectPhotos', 'deleteStore', 'deleteStoreVisit', 'deleteDocumentInTransaction', 'SearchEntityType.Store', 'SearchEntityType.StoreVisit']]
]) {
  const source = fs.readFileSync(path, 'utf8');
  for (const needle of needles) {
    if (!source.includes(needle)) {
      throw new Error(`${path} missing ${needle}`);
    }
  }

  if (!/constructor\s*\(\s*database:\s*MigrationDatabase\s*,\s*searchIndexMode:\s*SearchIndexMode\s*,\s*photoStorage\?:\s*PhotoStorage\s*\)/.test(source)) {
    throw new Error(`${path} constructor must accept optional PhotoStorage for delete cleanup`);
  }

  if (!/new\s+DeleteCleanupService\s*\([\s\S]*photoStorage\s*\)/.test(source)) {
    throw new Error(`${path} must pass PhotoStorage into DeleteCleanupService`);
  }

  if (/photoStorage\.(copy|save|persist|import|write|ensure)/.test(source)) {
    throw new Error(`${path} must not copy or write photo files directly`);
  }
}

console.log('PASS');
