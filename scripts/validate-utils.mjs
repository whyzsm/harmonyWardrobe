import fs from 'node:fs';

const checks = [
  ['entry/src/main/ets/utils/id.ets', ['createId']],
  ['entry/src/main/ets/utils/date.ets', ['toIsoDate', 'toIsoDateTime', 'monthKey']],
  ['entry/src/main/ets/utils/result.ets', ['AppResult', 'ok', 'err']],
  ['entry/src/main/ets/utils/text.ets', ['normalizeSearchText']]
];

for (const [file, needles] of checks) {
  const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  for (const needle of needles) {
    if (!text.includes(needle)) {
      console.error(`${file} missing ${needle}`);
      process.exit(1);
    }
  }
}
