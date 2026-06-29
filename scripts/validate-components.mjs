import fs from 'node:fs';

const components = ['SearchBar', 'CategoryTabs', 'PhotoGrid', 'ClothingCard', 'OutfitCard', 'WishlistCard', 'EmptyState'];

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

console.log('PASS');
