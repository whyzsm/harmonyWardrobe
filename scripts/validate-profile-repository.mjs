import fs from 'node:fs';

const file = 'entry/src/main/ets/data/repositories/ProfileRepository.ets';
const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';

for (const needle of [
  'export class ProfileRepository',
  'getProfile',
  'saveProfile',
  'user_profile',
  'normalizeMeasurement',
  'PROFILE_HEIGHT_MIN_CM',
  'PROFILE_HEIGHT_MAX_CM',
  'PROFILE_WEIGHT_MIN_KG',
  'PROFILE_WEIGHT_MAX_KG',
  'PROFILE_WAIST_MIN_CM',
  'PROFILE_WAIST_MAX_CM',
  'common_budgets',
  'commonBudgets',
  'MAX_COMMON_ITEMS',
  'Number.isFinite',
  'value < min',
  'value > max',
  'value === null',
  'heightCm',
  'weightKg',
  'waistCm',
  'upperSize',
  'lowerSize',
  'shoeSize'
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

for (const [field, minName, maxName] of [
  ['input.heightCm', 'PROFILE_HEIGHT_MIN_CM', 'PROFILE_HEIGHT_MAX_CM'],
  ['input.weightKg', 'PROFILE_WEIGHT_MIN_KG', 'PROFILE_WEIGHT_MAX_KG'],
  ['input.waistCm', 'PROFILE_WAIST_MIN_CM', 'PROFILE_WAIST_MAX_CM']
]) {
  const pattern = new RegExp(`normalizeMeasurement\\(${field.replace('.', '\\.')},\\s*${minName},\\s*${maxName}\\)`);
  if (!pattern.test(text)) {
    throw new Error(`${file} must normalize ${field} with domain measurement bounds`);
  }
}

console.log('PASS');
