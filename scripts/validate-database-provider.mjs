import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/database/DatabaseProvider.ets', 'utf8');
for (const needle of [
  'relationalStore',
  'getStore',
  'executeSql',
  'insert',
  'transaction',
  'rollBack',
  'rollbackCause',
  'PRAGMA foreign_keys = ON',
  'openStorePromise',
  'openStore',
  'getString',
  'messageWithSql',
  'messageWithCause',
  'isDatabaseError',
  "error.name === 'DatabaseError'",
  'compactSql',
  'bindArgs.length === 0',
  'store.executeSql(sql)',
  'store.insert(table, values as Object as relationalStore.ValuesBucket)',
  'store.querySql(sql)'
]) {
  if (!text.includes(needle)) {
    console.error(`DatabaseProvider missing ${needle}`);
    process.exit(1);
  }
}

if (!/Failed to execute database transaction\.[\s\S]*cause/.test(text)) {
  console.error('DatabaseProvider transaction errors must preserve the original cause message.');
  process.exit(1);
}

const errorText = fs.readFileSync('entry/src/main/ets/data/database/DatabaseError.ets', 'utf8');
for (const needle of ['DatabaseError', 'cause', 'rollbackCause']) {
  if (!errorText.includes(needle)) {
    console.error(`DatabaseError missing ${needle}`);
    process.exit(1);
  }
}
