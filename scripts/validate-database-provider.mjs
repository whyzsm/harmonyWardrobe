import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/database/DatabaseProvider.ets', 'utf8');
for (const needle of ['relationalStore', 'getStore', 'executeSql', 'transaction']) {
  if (!text.includes(needle)) {
    console.error(`DatabaseProvider missing ${needle}`);
    process.exit(1);
  }
}
