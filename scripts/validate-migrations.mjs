import fs from 'node:fs';

const migration = fs.readFileSync('entry/src/main/ets/data/migrations/Migration.ets', 'utf8');
const runner = fs.readFileSync('entry/src/main/ets/data/migrations/MigrationRunner.ets', 'utf8');

for (const needle of ['Migration', 'version', 'up']) {
  if (!migration.includes(needle)) throw new Error(`Migration.ets missing ${needle}`);
}
for (const needle of ['MigrationRunner', 'schema_migrations', 'runMigrations']) {
  if (!runner.includes(needle)) throw new Error(`MigrationRunner.ets missing ${needle}`);
}
