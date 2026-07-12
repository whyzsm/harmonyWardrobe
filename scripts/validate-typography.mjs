import fs from 'node:fs';
import path from 'node:path';

const etsRoot = 'entry/src/main/ets';

function etsFiles(directory) {
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const entryPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      return etsFiles(entryPath);
    }
    return entry.isFile() && entry.name.endsWith('.ets') ? [entryPath] : [];
  });
}

for (const file of etsFiles(etsRoot)) {
  const source = fs.readFileSync(file, 'utf8');
  if (/FontWeight\.(?:Bold|Bolder|Medium)/.test(source) || /\.fontWeight\(\s*[5-9]\d{2}\s*\)/.test(source)) {
    throw new Error(`${file} must use regular font weight throughout the app`);
  }
}

console.log('PASS');
