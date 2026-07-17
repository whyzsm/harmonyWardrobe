import fs from 'node:fs';

const tokenPath = 'entry/src/main/ets/theme/Tokens.ets';
if (!fs.existsSync(tokenPath)) {
  throw new Error(`${tokenPath} does not exist`);
}

const text = fs.readFileSync(tokenPath, 'utf8');
for (const needle of ['primary', 'surface', 'danger', 'radius', 'spacing', 'AppTheme', 'YibuqueColor', 'YibuqueRadius']) {
  if (!text.includes(needle)) {
    throw new Error(`Tokens missing ${needle}`);
  }
}

for (const path of [
  'entry/src/main/ets/components/EmptyState.ets',
  'entry/src/main/ets/components/CategoryTabs.ets',
  'entry/src/main/ets/pages/Index.ets'
]) {
  const source = fs.readFileSync(path, 'utf8');
  if (!source.includes('YibuqueColor')) {
    throw new Error(`${path} must use Yibuque tokens`);
  }
}

const searchBar = fs.readFileSync('entry/src/main/ets/components/SearchBar.ets', 'utf8');
for (const needle of ['YibuqueColor', 'YibuqueRadius', '.height(48)']) {
  if (!searchBar.includes(needle)) {
    throw new Error(`SearchBar missing ${needle}`);
  }
}

console.log('PASS');
