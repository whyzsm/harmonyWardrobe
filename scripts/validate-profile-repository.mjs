import fs from 'node:fs';

const file = 'entry/src/main/ets/data/repositories/ProfileRepository.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

for (const needle of [
  'export class ProfileRepository',
  'getProfile',
  'saveProfile',
  'user_profile',
  'normalizeMeasurement',
  'Number.isFinite',
  'value < 0',
  'heightCm',
  'weightKg',
  'waistCm'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

for (const forbidden of [': any', ': unknown']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

if (!/async\s+saveProfile\s*\([\s\S]*?return\s+this\.database\.transaction\s*\(\s*async\s*\(\)\s*=>\s*\{[\s\S]*?executeSql\(UPSERT_PROFILE_SQL/.test(text)) {
  throw new Error(`${file} saveProfile must execute the upsert inside a database transaction`);
}

console.log('PASS');
