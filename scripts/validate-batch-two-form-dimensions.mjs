import fs from 'node:fs';

function read(file) {
  if (!fs.existsSync(file)) {
    throw new Error(`${file} does not exist`);
  }
  return fs.readFileSync(file, 'utf8');
}

function requireIncludes(source, file, needle) {
  if (!source.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

function forbidIncludes(source, file, needle) {
  if (source.includes(needle)) {
    throw new Error(`${file} still contains ${needle}`);
  }
}

const clothingEdit = read('entry/src/main/ets/pages/ClothingEditPage.ets');
const wishlist = read('entry/src/main/ets/pages/WishlistPage.ets');
const searchBar = read('entry/src/main/ets/components/SearchBar.ets');
const photoGrid = read('entry/src/main/ets/components/PhotoGrid.ets');
const clothingPicker = read('entry/src/main/ets/components/ClothingPicker.ets');

forbidIncludes(clothingEdit, 'ClothingEditPage.ets', '.placeholderColor(YibuqueColor.textPrimary)');
requireIncludes(wishlist, 'WishlistPage.ets', 'YibuqueFontSize.pageTitle');
if (fs.existsSync('entry/src/main/ets/pages/CalendarPage.ets')) {
  throw new Error('CalendarPage.ets should remain removed; calendar UI is owned by WardrobePage');
}
forbidIncludes(wishlist, 'WishlistPage.ets', '.fontSize(30)');

requireIncludes(searchBar, 'SearchBar.ets', '.height(48)');
forbidIncludes(searchBar, 'SearchBar.ets', '.height(44)');

for (const [file, source] of [
  ['PhotoGrid.ets', photoGrid],
  ['ClothingPicker.ets', clothingPicker]
]) {
  requireIncludes(source, file, 'YibuqueRadius.xs');
  forbidIncludes(source, file, '.borderRadius(5)');
}

console.log('PASS');
