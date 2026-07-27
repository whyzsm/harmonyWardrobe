import fs from 'node:fs';

const checks = [
  ['entry/src/main/ets/domain/clothing/ClothingCategory.ets', ['Top', 'Pants', 'Shorts', 'LongSkirt', 'HalfSkirt']],
  ['entry/src/main/ets/domain/clothing/ClothingModels.ets', ['ClothingItem', 'PurchaseInfo']],
  ['entry/src/main/ets/domain/outfit/OutfitModels.ets', ['OutfitCategory', 'OutfitTemplate']],
  ['entry/src/main/ets/domain/wearLog/WearLogModels.ets', ['WearLog']],
  ['entry/src/main/ets/domain/wishlist/WishlistModels.ets', ['WishlistItem']],
  ['entry/src/main/ets/domain/search/SearchModels.ets', ['SearchEntityType', 'SearchResult', 'Store', 'StoreVisit']],
  ['entry/src/main/ets/domain/store/StoreModels.ets', ['Store', 'StoreVisit']],
  ['entry/src/main/ets/domain/profile/ProfileModels.ets', ['UserProfile']]
];

const interfaceFields = [
  ['entry/src/main/ets/domain/clothing/ClothingModels.ets', 'PurchaseInfo', ['storeName', 'price', 'purchaseDate', 'note']],
  ['entry/src/main/ets/domain/clothing/ClothingModels.ets', 'ClothingItem', ['id', 'name', 'category', 'photoUris', 'note', 'purchaseInfo', 'createdAt', 'updatedAt']],
  ['entry/src/main/ets/domain/outfit/OutfitModels.ets', 'OutfitCategory', ['id', 'name', 'usageCount']],
  ['entry/src/main/ets/domain/outfit/OutfitModels.ets', 'OutfitTemplate', ['id', 'title', 'photoUris', 'clothingItemIds', 'categoryIds', 'categoryNames', 'categoryId', 'categoryName', 'note', 'createdAt', 'updatedAt']],
  ['entry/src/main/ets/domain/wearLog/WearLogModels.ets', 'WearLog', ['id', 'outfitTemplateId', 'outfitTitleSnapshot', 'clothingItemIdsSnapshot', 'wornDate', 'photoUris', 'placeText', 'note', 'createdAt', 'updatedAt']],
  ['entry/src/main/ets/domain/wishlist/WishlistModels.ets', 'WishlistItem', ['id', 'title', 'photoUris', 'storeName', 'price', 'note', 'createdAt', 'updatedAt']],
  ['entry/src/main/ets/domain/search/SearchModels.ets', 'SearchResult', ['entityType', 'entityId', 'title']],
  ['entry/src/main/ets/domain/store/StoreModels.ets', 'Store', ['id', 'name', 'districtOrAddress', 'photoUris', 'note', 'createdAt', 'updatedAt']],
  ['entry/src/main/ets/domain/store/StoreModels.ets', 'StoreVisit', ['id', 'storeId', 'storeNameSnapshot', 'visitDate', 'photoUris', 'note', 'createdAt', 'updatedAt']],
  ['entry/src/main/ets/domain/profile/ProfileModels.ets', 'UserProfile', ['heightCm', 'weightKg', 'waistCm', 'commonBudgets', 'updatedAt']]
];

for (const [file, needles] of checks) {
  const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  for (const needle of needles) {
    if (!text.includes(needle)) {
      console.error(`${file} missing ${needle}`);
      process.exit(1);
    }
  }
}

for (const [file, interfaceName, fields] of interfaceFields) {
  const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  const match = text.match(new RegExp(`export\\s+interface\\s+${interfaceName}\\s*{([\\s\\S]*?)\\n}`));
  if (!match) {
    console.error(`${file} missing exported interface ${interfaceName}`);
    process.exit(1);
  }

  for (const field of fields) {
    if (!new RegExp(`\\b${field}\\??\\s*:`).test(match[1])) {
      console.error(`${file} interface ${interfaceName} missing field ${field}`);
      process.exit(1);
    }
  }
}
