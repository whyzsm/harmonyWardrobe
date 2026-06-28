import fs from 'node:fs';

const checks = [
  ['entry/src/main/ets/domain/clothing/ClothingCategory.ets', ['Top', 'Pants', 'Skirt', 'Outerwear', 'Shoes', 'Bag', 'Accessory', 'Other']],
  ['entry/src/main/ets/domain/clothing/ClothingModels.ets', ['ClothingItem', 'PurchaseInfo']],
  ['entry/src/main/ets/domain/outfit/OutfitModels.ets', ['OutfitTemplate']],
  ['entry/src/main/ets/domain/wearLog/WearLogModels.ets', ['WearLog']],
  ['entry/src/main/ets/domain/wishlist/WishlistModels.ets', ['WishlistItem']],
  ['entry/src/main/ets/domain/search/SearchModels.ets', ['SearchEntityType', 'SearchResult']]
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
