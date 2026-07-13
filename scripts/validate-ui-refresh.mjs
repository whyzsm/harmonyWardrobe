import fs from 'node:fs';

const tokenPath = 'entry/src/main/ets/theme/Tokens.ets';
const tokenSource = fs.readFileSync(tokenPath, 'utf8');

function fail(message) {
  console.error(message);
  process.exit(1);
}

function requireIncludes(source, value, label) {
  if (!source.includes(value)) {
    fail(`${label} missing: ${value}`);
  }
}

function forbidIncludes(source, value, label) {
  if (source.includes(value)) {
    fail(`${label} still contains forbidden value: ${value}`);
  }
}

requireIncludes(tokenSource, "primary: '#1D1D1F'", 'primary token');
requireIncludes(tokenSource, "primaryPressed: '#000000'", 'primary pressed token');
requireIncludes(tokenSource, "primarySoft: '#F2F2F7'", 'primary soft token');
requireIncludes(tokenSource, "surfaceMuted: '#F5F5F7'", 'app background token');
requireIncludes(tokenSource, "success: '#16A34A'", 'success token');
requireIncludes(tokenSource, "warning: '#EAB308'", 'warning token');
requireIncludes(tokenSource, "danger: '#DC2626'", 'danger token');
requireIncludes(tokenSource, "accent: '#1D1D1F'", 'fashion accent token');

for (const oldRoseColor of ['#B11B68', '#8E1454', '#7A1048', '#FCE3EF', '#FFF2F8', '#FBE1F0', '#F8D4EF', '#D83E8E']) {
  forbidIncludes(tokenSource, oldRoseColor, 'legacy rose token');
}

const componentFiles = [
  'entry/src/main/ets/components/ClothingCard.ets',
  'entry/src/main/ets/components/OutfitCard.ets'
];

for (const file of componentFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, 'YibuqueColor', `${file} yibuque colors`);
  requireIncludes(source, 'YibuqueRadius', `${file} yibuque radius`);
  forbidIncludes(source, "'#0F766E'", `${file} old teal`);
  forbidIncludes(source, "'#0F172A'", `${file} old near-black action`);
  forbidIncludes(source, "'#E2E8F0'", `${file} old slate border`);
}

const controlFiles = [
  'entry/src/main/ets/components/SearchBar.ets',
  'entry/src/main/ets/components/CategoryTabs.ets',
  'entry/src/main/ets/components/EmptyState.ets'
];

for (const file of controlFiles) {
  const source = fs.readFileSync(file, 'utf8');
  if (file.endsWith('SearchBar.ets')) {
    requireIncludes(source, 'AppTheme.color.', `${file} compatibility theme colors`);
  } else {
    requireIncludes(source, 'YibuqueColor', `${file} yibuque colors`);
  }
  forbidIncludes(source, "'#0F172A'", `${file} old selected state`);
  forbidIncludes(source, "'#E2E8F0'", `${file} old border`);
}

const yibuqueComponentFiles = [
  'entry/src/main/ets/components/AppTopBar.ets',
  'entry/src/main/ets/components/BottomNavigationBar.ets',
  'entry/src/main/ets/components/QuickCaptureSheet.ets',
  'entry/src/main/ets/components/StoreVisitCard.ets'
];

for (const file of yibuqueComponentFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, 'YibuqueColor', `${file} yibuque colors`);
  requireIncludes(source, 'YibuqueRadius', `${file} yibuque radius`);
  forbidIncludes(source, "'#0F766E'", `${file} old teal`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}

const mainPageFiles = [
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/ets/pages/WardrobePage.ets'
];

for (const file of mainPageFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, 'YibuqueColor', `${file} yibuque colors`);
  forbidIncludes(source, "'#0F172A'", `${file} old black primary action`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}

const designPageFiles = [
  ['entry/src/main/ets/pages/ProfilePage.ets', 'PROFILE_ACCENT', "'#1D1D1F'"],
  ['entry/src/main/ets/pages/OutfitsPage.ets', 'ACCENT', "'#1D1D1F'"],
  ['entry/src/main/ets/pages/CaptureEditPage.ets', 'CAPTURE_TEXT', "'#1D1D1F'"],
  ['entry/src/main/ets/pages/StoreVisitPage.ets', 'ACCENT', 'YibuqueColor.brandCyan']
];

for (const [file, accentToken, expectedColor] of designPageFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, expectedColor, `${file} design color`);
  requireIncludes(source, accentToken, `${file} design token usage`);
  forbidIncludes(source, "'#0F172A'", `${file} old black primary action`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}

const flowFiles = [
  'entry/src/main/ets/pages/SearchResultsPage.ets',
  'entry/src/main/ets/components/OutfitPicker.ets',
  'entry/src/main/ets/components/PhotoGrid.ets'
];

for (const file of flowFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, 'Yibuque', `${file} yibuque token usage`);
  forbidIncludes(source, "'#0F172A'", `${file} old black primary action`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}

const yibuqueFlowFiles = [
  'entry/src/main/ets/pages/ClothingEditPage.ets',
  'entry/src/main/ets/pages/OutfitEditPage.ets',
  'entry/src/main/ets/pages/StoreVisitEditPage.ets',
  'entry/src/main/ets/components/ClothingPicker.ets'
];

for (const file of yibuqueFlowFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, 'YibuqueColor', `${file} yibuque colors`);
  requireIncludes(source, 'YibuqueRadius', `${file} yibuque radius`);
  forbidIncludes(source, "'#0F172A'", `${file} old black primary action`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}
