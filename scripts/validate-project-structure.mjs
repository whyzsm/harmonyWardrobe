import fs from 'node:fs';

const required = [
  'AppScope/app.json5',
  'entry/src/main/module.json5',
  'entry/src/main/ets/entryability/EntryAbility.ets',
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/resources/base/element/string.json',
  'build-profile.json5',
  'hvigorfile.ts',
  'oh-package.json5'
];

const missing = required.filter((file) => !fs.existsSync(file));
if (missing.length > 0) {
  console.error(`Missing files:\n${missing.map((file) => `- ${file}`).join('\n')}`);
  process.exit(1);
}

const requiredDirs = [
  'entry/src/main/ets/components',
  'entry/src/main/ets/domain/clothing',
  'entry/src/main/ets/domain/outfit',
  'entry/src/main/ets/domain/wearLog',
  'entry/src/main/ets/domain/wishlist',
  'entry/src/main/ets/domain/search',
  'entry/src/main/ets/data/database',
  'entry/src/main/ets/data/migrations',
  'entry/src/main/ets/data/repositories',
  'entry/src/main/ets/data/searchIndex',
  'entry/src/main/ets/media',
  'entry/src/main/ets/utils'
];

const missingDirs = requiredDirs.filter((dir) => !fs.existsSync(dir) || !fs.statSync(dir).isDirectory());
if (missingDirs.length > 0) {
  console.error(`Missing directories:\n${missingDirs.map((dir) => `- ${dir}`).join('\n')}`);
  process.exit(1);
}
