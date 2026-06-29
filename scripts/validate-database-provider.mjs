import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/database/DatabaseProvider.ets', 'utf8');
for (const needle of ['relationalStore', 'getStore', 'executeSql', 'transaction', 'rollBack', 'rollbackCause', 'PRAGMA foreign_keys = ON', 'openStorePromise', 'openStore', 'getString']) {
  if (!text.includes(needle)) {
    console.error(`DatabaseProvider missing ${needle}`);
    process.exit(1);
  }
}

const errorText = fs.readFileSync('entry/src/main/ets/data/database/DatabaseError.ets', 'utf8');
for (const needle of ['DatabaseError', 'cause', 'rollbackCause']) {
  if (!errorText.includes(needle)) {
    console.error(`DatabaseError missing ${needle}`);
    process.exit(1);
  }
}
