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

requireIncludes(tokenSource, "primary: '#B11B68'", 'primary token');
requireIncludes(tokenSource, "primaryPressed: '#7A1048'", 'primary pressed token');
requireIncludes(tokenSource, "primarySoft: '#FCE3EF'", 'primary soft token');
requireIncludes(tokenSource, "surfaceMuted: '#FDE7F2'", 'app background token');
requireIncludes(tokenSource, "success: '#C53B88'", 'success token');
requireIncludes(tokenSource, "warning: '#FFB020'", 'warning token');
requireIncludes(tokenSource, "danger: '#D94870'", 'danger token');
requireIncludes(tokenSource, "accent: '#E85D9E'", 'fashion accent token');
forbidIncludes(tokenSource, "'#0F766E'", 'old teal primary');
forbidIncludes(tokenSource, "'#115E59'", 'old teal primaryStrong');
forbidIncludes(tokenSource, "'#4894FE'", 'old blue primary');
forbidIncludes(tokenSource, "'#246BFE'", 'old blue primaryStrong');

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
  'entry/src/main/ets/pages/WardrobePage.ets',
  'entry/src/main/ets/pages/StoreVisitPage.ets',
  'entry/src/main/ets/pages/ProfilePage.ets'
];

for (const file of mainPageFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, 'YibuqueColor', `${file} yibuque colors`);
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
