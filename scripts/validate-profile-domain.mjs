import fs from 'node:fs';

const file = 'entry/src/main/ets/domain/profile/ProfileModels.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

for (const needle of [
  'export interface UserProfile',
  'heightCm?: number',
  'weightKg?: number',
  'waistCm?: number',
  'updatedAt: string'
]) {
  if (!text.includes(needle)) {
    throw new Error(`${file} missing ${needle}`);
  }
}

for (const forbidden of [': any', ': unknown', 'ArkUI', 'MigrationDatabase']) {
  if (text.includes(forbidden)) {
    throw new Error(`${file} must not include ${forbidden}`);
  }
}

console.log('PASS');
