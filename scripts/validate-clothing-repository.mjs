import assert from 'node:assert/strict';
import fs from 'node:fs';

const repositoryPath = 'entry/src/main/ets/data/repositories/ClothingRepository.ets';

function readRequired(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }

  return fs.readFileSync(path, 'utf8');
}

function assertIncludes(source, needle, message = `Missing ${needle}`) {
  if (!source.includes(needle)) {
    throw new Error(message);
  }
}

function assertMatches(source, pattern, message) {
  if (!pattern.test(source)) {
    throw new Error(message);
  }
}

function assertNoUnsafeTypes(path, source) {
  const unsafeType = source.match(/(?:^|[\s<(:,=|&])(?:unknown|any)(?=\b|[>\s,;)|&])/m);
  if (unsafeType) {
    throw new Error(`${path} must not use unsafe type ${unsafeType[0].trim()}`);
  }
}

function assertRejectsUnsafeType(source, expectedUnsafeType) {
  try {
    assertNoUnsafeTypes('negative-self-check.ets', source);
  } catch (error) {
    if (!String(error.message).includes(expectedUnsafeType)) {
      throw new Error(`Unsafe type self-check rejected for the wrong reason: ${error.message}`);
    }
    return;
  }

  throw new Error(`Unsafe type self-check must reject ${expectedUnsafeType}`);
}

function assertOrdered(source, first, second, message) {
  const firstIndex = source.indexOf(first);
  const secondIndex = source.indexOf(second);
  if (firstIndex < 0 || secondIndex < 0 || firstIndex >= secondIndex) {
    throw new Error(message);
  }
}

assertRejectsUnsafeType('function bad(value: any): string { return String(value); }', 'any');
assertRejectsUnsafeType('const values: Record<string, unknown> = {};', 'unknown');

const source = readRequired(repositoryPath);
assertNoUnsafeTypes(repositoryPath, source);

for (const needle of [
  'MigrationDatabase',
  'MigrationResultSet',
  'MigrationSqlValue',
  'SearchRepository',
  'SearchIndexMode',
  'buildClothingSearchDocument',
  'SearchEntityType',
  'ClothingItem',
  'PurchaseInfo',
  'ClothingCategory',
  'createId',
  'toIsoDateTime',
  'ClothingRepository',
  'CreateClothingInput',
  'UpdateClothingInput',
  'ListClothingOptions',
  'createClothing',
  'updateClothing',
  'deleteClothing',
  'listClothing',
  'getClothingById'
]) {
  assertIncludes(source, needle);
}

for (const method of ['createClothing', 'updateClothing', 'deleteClothing']) {
  assertMatches(
    source,
    new RegExp(`${method}\\s*\\([^)]*\\)\\s*:\\s*Promise<[^>]+>\\s*{[\\s\\S]*?this\\.database\\.transaction`, 'm'),
    `${method} must run in a database transaction`
  );
}

assertMatches(source, /INSERT\s+INTO\s+clothing_items/i, 'createClothing must insert clothing_items');
assertMatches(source, /constructor\s*\(\s*database:\s*MigrationDatabase\s*,\s*searchIndexMode:\s*SearchIndexMode\s*\)/, 'constructor must accept the shared database and search index mode');
assertMatches(source, /new\s+SearchRepository\s*\(\s*database\s*,\s*searchIndexMode\s*\)/, 'ClothingRepository must build SearchRepository from the same database');
assertMatches(source, /UPDATE\s+clothing_items/i, 'updateClothing must update clothing_items');
assertMatches(source, /DELETE\s+FROM\s+clothing_items/i, 'deleteClothing must delete clothing_items');
assertMatches(source, /INSERT\s+INTO\s+clothing_photos/i, 'repository must insert clothing_photos');
assertMatches(source, /DELETE\s+FROM\s+clothing_photos\s+WHERE\s+clothing_id\s*=\s*\?/i, 'repository must replace clothing_photos by clothing_id');
assertMatches(source, /ORDER\s+BY\s+sort_order/i, 'photo loading must respect sort_order');
assertMatches(source, /purchase_store_name/i, 'repository must persist purchase store');
assertMatches(source, /purchase_price/i, 'repository must persist purchase price');
assertMatches(source, /COALESCE\(\s*purchase_price,\s*-1\s*\)\s+AS\s+purchase_price_value/i, 'repository must preserve nullable purchase_price when reading rows');
assertMatches(source, /getNumber\s*\(\s*['"`]purchase_price_value['"`]\s*\)/, 'repository must read normalized purchase_price_value');
assertMatches(source, /Math\.round\s*\(\s*value\s*\*\s*100\s*\)/, 'repository must store price as cents to avoid getLong decimal truncation');
assertMatches(source, /value\s*\/\s*100/, 'repository must convert stored cents back to decimal price');
assertMatches(source, /function\s+normalizeDomainPrice[\s\S]*Math\.round\s*\(\s*value\s*\*\s*100\s*\)\s*\/\s*100/, 'domain purchase price must remain decimal after normalization');
assertMatches(source, /function\s+priceToStoredCents[\s\S]*Math\.round\s*\(\s*value\s*\*\s*100\s*\)/, 'SQL bind args must encode purchase price as cents');
assertMatches(source, /priceToStoredCents\s*\(\s*item\.purchaseInfo\?\.price\s*\)/, 'SQL writes must use priceToStoredCents');
assertMatches(source, /BASE_LIST_CLOTHING_SQL[\s\S]*purchase_price_value[\s\S]*FROM clothing_items/, 'listClothing rows must include purchase_price_value');
assertMatches(source, /SELECT_CLOTHING_BY_ID_SQL[\s\S]*purchase_price_value[\s\S]*FROM clothing_items/, 'getClothingById rows must include purchase_price_value');
assert.equal(/INSERT_CLOTHING_SQL[\s\S]*purchase_price_value[\s\S]*VALUES/.test(source), false, 'INSERT columns must not include derived purchase_price_value');
assertMatches(source, /purchase_date/i, 'repository must persist purchase date');
assertMatches(source, /purchase_note/i, 'repository must persist purchase note');
assertMatches(source, /whereClauses\.push\s*\(\s*['"`]category\s*=\s*\?['"`]\s*\)/, 'listClothing must support category filtering');
assertMatches(source, /WHERE\s+\$\{whereClauses\.join\(['"`] AND ['"`]\)\}/, 'listClothing must combine dynamic WHERE clauses');
assertMatches(source, /LIKE\s+\?/i, 'listClothing must support name/note text filtering');
assertMatches(source, /ESCAPE\s+['"`]\\{2}['"`]/, 'listClothing text search must escape LIKE wildcards');
assertMatches(source, /escapeLikeLiteral\s*\(\s*normalizedQuery\s*\)/, 'listClothing must escape LIKE wildcard input');
assertMatches(source, /ORDER\s+BY\s+updated_at\s+DESC/i, 'listClothing must order by recent updates');
assertMatches(source, /COALESCE\(\s*note,\s*(?:\\?['"]){2}\s*\)/i, 'listClothing search must tolerate null notes');
assertMatches(source, /upsertDocumentInTransaction\s*\(\s*buildClothingSearchDocument/i, 'create/update must update search index inside the clothing transaction');
assertMatches(source, /deleteDocumentInTransaction\s*\(\s*SearchEntityType\.Clothing/i, 'delete must remove search index document inside the clothing transaction');
assertMatches(source, /getClothingById\s*\([^)]*\)\s*:\s*Promise<ClothingItem\s*\|\s*undefined>/, 'getClothingById must return ClothingItem | undefined');

assertOrdered(
  source,
  'DELETE FROM clothing_photos WHERE clothing_id = ?',
  'INSERT INTO clothing_photos',
  'photo replacement should delete existing rows before inserting new rows'
);

assert.equal(source.includes('@ohos.net'), false, 'ClothingRepository must stay local-only');
assert.equal(source.includes('fetch('), false, 'ClothingRepository must not use fetch');
assert.equal(source.includes('PhotoStorage'), false, 'ClothingRepository must not copy photo files');

console.log('PASS');
