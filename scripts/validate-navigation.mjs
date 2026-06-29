import fs from 'node:fs';

const indexPath = 'entry/src/main/ets/pages/Index.ets';
const index = fs.readFileSync(indexPath, 'utf8');

for (const tab of ['TodayPage', 'WardrobePage', 'OutfitsPage', 'CalendarPage', 'ShoppingPage']) {
  if (!index.includes(tab)) {
    throw new Error(`Index missing ${tab}`);
  }
}

for (const label of ['今日', '衣橱', '套装', '日历', '逛街']) {
  if (!index.includes(label)) {
    throw new Error(`Index missing nav label ${label}`);
  }
}

for (const page of ['TodayPage', 'WardrobePage', 'OutfitsPage', 'CalendarPage', 'ShoppingPage']) {
  const pagePath = `entry/src/main/ets/pages/${page}.ets`;
  if (!fs.existsSync(pagePath)) {
    throw new Error(`Missing ${pagePath}`);
  }

  const pageText = fs.readFileSync(pagePath, 'utf8');
  if (!pageText.includes('@Component')) {
    throw new Error(`${page} must be an ArkUI component`);
  }
}

console.log('PASS');
