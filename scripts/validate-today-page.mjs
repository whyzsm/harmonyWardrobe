import fs from 'node:fs';

const todayPagePath = 'entry/src/main/ets/pages/TodayPage.ets';

if (fs.existsSync(todayPagePath)) {
  throw new Error('TodayPage must stay removed; it contained fictional social/feed data');
}

for (const filePath of [
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/resources/base/profile/main_pages.json'
]) {
  const source = fs.readFileSync(filePath, 'utf8');
  if (source.includes('TodayPage')) {
    throw new Error(`${filePath} must not reference TodayPage`);
  }
}

console.log('PASS');
