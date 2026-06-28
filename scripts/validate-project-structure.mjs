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
