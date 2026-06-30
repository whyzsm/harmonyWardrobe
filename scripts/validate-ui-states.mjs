import fs from 'node:fs';

const pages = ['TodayPage', 'WardrobePage', 'OutfitsPage', 'CalendarPage', 'ShoppingPage'];
for (const page of pages) {
  const text = fs.readFileSync(`entry/src/main/ets/pages/${page}.ets`, 'utf8');
  const emptyStateNeedle = page === 'TodayPage' ? '今天穿什么？' : 'EmptyState';
  for (const needle of ['loading', 'error', emptyStateNeedle, 'retry']) {
    if (!text.includes(needle)) {
      throw new Error(`${page} missing ${needle} state`);
    }
  }
}

for (const page of ['ClothingEditPage', 'OutfitEditPage', 'WearLogEditPage', 'WishlistEditPage']) {
  const text = fs.readFileSync(`entry/src/main/ets/pages/${page}.ets`, 'utf8');
  for (const needle of ['isSaving', 'errorMessage', 'enabled(this.canSave())']) {
    if (!text.includes(needle)) {
      throw new Error(`${page} missing save state ${needle}`);
    }
  }
}

console.log('PASS');
