import assert from 'node:assert/strict';
import fs from 'node:fs';

const repositoryPath = 'entry/src/main/ets/data/repositories/WishlistRepository.ets';
const modelPath = 'entry/src/main/ets/domain/wishlist/WishlistModels.ets';

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
  'PhotoStorage',
  'buildWishlistSearchDocument',
  'SearchEntityType',
  'WishlistItem',
  'createId',
  'toIsoDateTime',
  'WishlistRepository',
  'CreateWishlistItemInput',
  'UpdateWishlistItemInput',
  'ListWishlistItemsOptions',
  'createWishlistItem',
  'updateWishlistItem',
  'deleteWishlistItem',
  'listWishlistItems',
  'getWishlistItemById'
]) {
  assertIncludes(source, needle);
}

for (const method of ['createWishlistItem', 'updateWishlistItem', 'deleteWishlistItem']) {
  assertMatches(
    source,
    new RegExp(`${method}\\s*\\([^)]*\\)\\s*:\\s*Promise<[^>]+>\\s*{[\\s\\S]*?this\\.database\\.transaction`, 'm'),
    `${method} must run in a database transaction`
  );
}

assertMatches(source, /constructor\s*\(\s*database:\s*MigrationDatabase\s*,\s*searchIndexMode:\s*SearchIndexMode\s*,\s*photoStorage\?:\s*PhotoStorage\s*\)/, 'constructor must accept the shared database, search index mode, and optional photo storage');
assertMatches(source, /new\s+SearchRepository\s*\(\s*database\s*,\s*searchIndexMode\s*\)/, 'WishlistRepository must build SearchRepository from the same database');
assertMatches(source, /new\s+DeleteCleanupService\s*\([\s\S]*photoStorage\s*\)/, 'WishlistRepository must pass PhotoStorage to DeleteCleanupService');
assertMatches(source, /INSERT\s+INTO\s+wishlist_items/i, 'createWishlistItem must insert wishlist_items');
assertMatches(source, /UPDATE\s+wishlist_items/i, 'updateWishlistItem must update wishlist_items');
assertMatches(source, /DELETE\s+FROM\s+wishlist_items/i, 'deleteWishlistItem must delete wishlist_items');
assertMatches(source, /INSERT\s+INTO\s+wishlist_photos/i, 'repository must insert wishlist_photos');
assertMatches(source, /DELETE\s+FROM\s+wishlist_photos\s+WHERE\s+wishlist_id\s*=\s*\?/i, 'repository must replace wishlist_photos by wishlist_id');
assertMatches(source, /ORDER\s+BY\s+sort_order/i, 'photo loading must respect sort_order');
assertMatches(source, /store_name/i, 'repository must persist store_name');
assertMatches(source, /\bprice\b/i, 'repository must persist price');
assertMatches(source, /COALESCE\(\s*price,\s*-1\s*\)\s+AS\s+price_value/i, 'repository must preserve nullable price when reading rows');
assertMatches(source, /getNumber\s*\(\s*['"`]price_value['"`]\s*\)/, 'repository must read normalized price_value');
assertMatches(source, /Math\.round\s*\(\s*value\s*\*\s*100\s*\)/, 'repository must store price as cents');
assertMatches(source, /value\s*\/\s*100/, 'repository must convert stored cents back to decimal price');
assertMatches(source, /function\s+normalizeDomainPrice[\s\S]*Math\.round\s*\(\s*value\s*\*\s*100\s*\)\s*\/\s*100/, 'domain price must remain decimal after normalization');
assertMatches(source, /function\s+priceToStoredCents[\s\S]*Math\.round\s*\(\s*value\s*\*\s*100\s*\)/, 'SQL bind args must encode price as cents');
assertMatches(source, /priceToStoredCents\s*\(\s*item\.price\s*\)/, 'SQL writes must use priceToStoredCents');
assertMatches(source, /BASE_LIST_WISHLIST_SQL[\s\S]*price_value[\s\S]*FROM wishlist_items/, 'listWishlistItems rows must include price_value');
assertMatches(source, /SELECT_WISHLIST_BY_ID_SQL[\s\S]*price_value[\s\S]*FROM wishlist_items/, 'getWishlistItemById rows must include price_value');
assert.equal(/INSERT_WISHLIST_SQL[\s\S]*price_value[\s\S]*VALUES/.test(source), false, 'INSERT columns must not include derived price_value');
assertMatches(source, /WHERE\s+\$\{whereClauses\.join\(['"`] AND ['"`]\)\}/, 'listWishlistItems must combine dynamic WHERE clauses');
assertMatches(source, /LIKE\s+\?/i, 'listWishlistItems must support title/store/note text filtering');
assertMatches(source, /ESCAPE\s+['"`]\\{2}['"`]/, 'listWishlistItems text search must escape LIKE wildcards');
assertMatches(source, /escapeLikeLiteral\s*\(\s*normalizedQuery\s*\)/, 'listWishlistItems must escape LIKE wildcard input');
assertMatches(source, /ORDER\s+BY\s+updated_at\s+DESC/i, 'listWishlistItems must order by recent updates');
assertMatches(source, /COALESCE\(\s*store_name,\s*(?:\\?['"]){2}\s*\)/i, 'repository must tolerate nullable store_name values');
assertMatches(source, /COALESCE\(\s*note,\s*(?:\\?['"]){2}\s*\)/i, 'repository must tolerate nullable note values');
assertMatches(source, /upsertDocumentInTransaction\s*\(\s*buildWishlistSearchDocument/i, 'create/update must update search index inside the wishlist transaction');
assertMatches(source, /deleteDocumentInTransaction\s*\(\s*SearchEntityType\.Wishlist/i, 'delete must remove wishlist search index inside the transaction');
assertMatches(source, /getWishlistItemById\s*\([^)]*\)\s*:\s*Promise<WishlistItem\s*\|\s*undefined>/, 'getWishlistItemById must return WishlistItem | undefined');

assertOrdered(
  source,
  'DELETE FROM wishlist_photos WHERE wishlist_id = ?',
  'INSERT INTO wishlist_photos',
  'wishlist photo replacement should delete existing rows before inserting new rows'
);

assert.equal(source.includes('@ohos.net'), false, 'WishlistRepository must stay local-only');
assert.equal(source.includes('fetch('), false, 'WishlistRepository must not use fetch');
assert.equal(/photoStorage\.(copy|save|persist|import|write|ensure)/.test(source), false, 'WishlistRepository must not copy photo files directly');
assert.equal(source.includes('BLOB'), false, 'WishlistRepository must not store image blobs');

const model = readRequired(modelPath);
assertMatches(model, /storeName\??:\s*string/, 'Wishlist model must expose optional storeName');
assertMatches(model, /price\??:\s*number/, 'Wishlist model must expose optional decimal price');

console.log('PASS');
