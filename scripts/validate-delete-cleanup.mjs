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
  ['entry/src/main/ets/data/repositories/ClothingRepository.ets', ['DeleteCleanupService', 'deleteObjectPhotos', 'deleteDocumentInTransaction', 'SearchEntityType.Clothing']],
  ['entry/src/main/ets/data/repositories/OutfitRepository.ets', ['DeleteCleanupService', 'deleteObjectPhotos', 'deleteDocumentInTransaction', 'SearchEntityType.Outfit']],
  ['entry/src/main/ets/data/repositories/WearLogRepository.ets', ['DeleteCleanupService', 'deleteObjectPhotos', 'deleteDocumentInTransaction', 'SearchEntityType.WearLog']],
  ['entry/src/main/ets/data/repositories/WishlistRepository.ets', ['DeleteCleanupService', 'deleteObjectPhotos', 'deleteDocumentInTransaction', 'SearchEntityType.Wishlist']]
]) {
  const source = fs.readFileSync(path, 'utf8');
  for (const needle of needles) {
    if (!source.includes(needle)) {
      throw new Error(`${path} missing ${needle}`);
    }
  }
}

console.log('PASS');
