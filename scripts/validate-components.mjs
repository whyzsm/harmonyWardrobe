import fs from 'node:fs';

const components = ['SearchBar', 'CategoryTabs', 'PhotoGrid', 'WishlistCard', 'EmptyState'];

for (const component of components) {
  const file = `entry/src/main/ets/components/${component}.ets`;
  if (!fs.existsSync(file)) {
    throw new Error(`Missing ${file}`);
  }

  const text = fs.readFileSync(file, 'utf8');
  if (!text.includes('@Component')) {
    throw new Error(`${component} must be an ArkUI component`);
  }
}

for (const removedComponent of ['ClothingCard', 'OutfitCard', 'StoreVisitCard']) {
  const file = `entry/src/main/ets/components/${removedComponent}.ets`;
  if (fs.existsSync(file)) {
    throw new Error(`${file} should be removed as an unused legacy component`);
  }
}

console.log('PASS');
