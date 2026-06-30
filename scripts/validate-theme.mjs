import fs from 'node:fs';

const tokenPath = 'entry/src/main/ets/theme/Tokens.ets';
if (!fs.existsSync(tokenPath)) {
  throw new Error(`${tokenPath} does not exist`);
}

const text = fs.readFileSync(tokenPath, 'utf8');
for (const needle of ['primary', 'surface', 'danger', 'radius', 'spacing', 'AppTheme']) {
  if (!text.includes(needle)) {
    throw new Error(`Tokens missing ${needle}`);
  }
}

for (const path of [
  'entry/src/main/ets/components/SearchBar.ets',
  'entry/src/main/ets/components/EmptyState.ets',
  'entry/src/main/ets/components/CategoryTabs.ets',
  'entry/src/main/ets/pages/Index.ets'
]) {
  const source = fs.readFileSync(path, 'utf8');
  if (!source.includes('AppTheme')) {
    throw new Error(`${path} must use AppTheme tokens`);
  }
}

console.log('PASS');
