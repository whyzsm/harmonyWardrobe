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

requireIncludes(tokenSource, "primary: '#4894FE'", 'primary token');
requireIncludes(tokenSource, "primaryPressed: '#246BFE'", 'primary pressed token');
requireIncludes(tokenSource, "primarySoft: '#EAF3FF'", 'primary soft token');
requireIncludes(tokenSource, "surfaceMuted: '#F6F8FC'", 'app background token');
requireIncludes(tokenSource, "success: '#22C55E'", 'success token');
requireIncludes(tokenSource, "warning: '#FFB020'", 'warning token');
requireIncludes(tokenSource, "danger: '#EF4444'", 'danger token');
requireIncludes(tokenSource, "accent: '#FF7A90'", 'fashion accent token');
forbidIncludes(tokenSource, "'#0F766E'", 'old teal primary');
forbidIncludes(tokenSource, "'#115E59'", 'old teal primaryStrong');

const componentFiles = [
  'entry/src/main/ets/components/ClothingCard.ets',
  'entry/src/main/ets/components/OutfitCard.ets',
  'entry/src/main/ets/components/WishlistCard.ets'
];

for (const file of componentFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, "import { AppTheme } from '../theme/Tokens';", `${file} theme import`);
  requireIncludes(source, 'AppTheme.color.', `${file} theme colors`);
  requireIncludes(source, 'AppTheme.radius.', `${file} theme radius`);
  forbidIncludes(source, "'#0F766E'", `${file} old teal`);
  forbidIncludes(source, "'#0F172A'", `${file} old near-black action`);
  forbidIncludes(source, "'#E2E8F0'", `${file} old slate border`);
}

const controlFiles = [
  'entry/src/main/ets/components/SearchBar.ets',
  'entry/src/main/ets/components/CategoryTabs.ets',
  'entry/src/main/ets/components/MonthCalendar.ets',
  'entry/src/main/ets/components/EmptyState.ets'
];

for (const file of controlFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, "import { AppTheme } from '../theme/Tokens';", `${file} theme import`);
  requireIncludes(source, 'AppTheme.color.', `${file} theme colors`);
  forbidIncludes(source, "'#0F172A'", `${file} old selected state`);
  forbidIncludes(source, "'#E2E8F0'", `${file} old border`);
}

requireIncludes(
  fs.readFileSync('entry/src/main/ets/components/MonthCalendar.ets', 'utf8'),
  'AppTheme.color.primary',
  'MonthCalendar selected blue'
);

const mainPageFiles = [
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/ets/pages/TodayPage.ets',
  'entry/src/main/ets/pages/WardrobePage.ets',
  'entry/src/main/ets/pages/OutfitsPage.ets',
  'entry/src/main/ets/pages/CalendarPage.ets',
  'entry/src/main/ets/pages/ShoppingPage.ets'
];

for (const file of mainPageFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, "import { AppTheme } from '../theme/Tokens';", `${file} theme import`);
  requireIncludes(source, 'AppTheme.color.', `${file} theme colors`);
  forbidIncludes(source, "'#0F172A'", `${file} old black primary action`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}

const flowFiles = [
  'entry/src/main/ets/pages/ClothingEditPage.ets',
  'entry/src/main/ets/pages/OutfitEditPage.ets',
  'entry/src/main/ets/pages/WearLogEditPage.ets',
  'entry/src/main/ets/pages/WishlistEditPage.ets',
  'entry/src/main/ets/pages/SearchResultsPage.ets',
  'entry/src/main/ets/components/ClothingPicker.ets',
  'entry/src/main/ets/components/OutfitPicker.ets',
  'entry/src/main/ets/components/PhotoGrid.ets'
];

for (const file of flowFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, 'AppTheme', `${file} theme usage`);
  forbidIncludes(source, "'#0F172A'", `${file} old black primary action`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}
