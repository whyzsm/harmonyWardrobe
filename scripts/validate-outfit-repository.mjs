import assert from 'node:assert/strict';
import fs from 'node:fs';

const repositoryPath = 'entry/src/main/ets/data/repositories/OutfitRepository.ets';

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
  'buildOutfitSearchDocument',
  'SearchEntityType',
  'OutfitTemplate',
  'OutfitDisplaySource',
  'WearLog',
  'createId',
  'toIsoDateTime',
  'OutfitRepository',
  'CreateOutfitInput',
  'UpdateOutfitInput',
  'OutfitWithRecentWearLogs',
  'createOutfit',
  'updateOutfit',
  'deleteOutfit',
  'listOutfits',
  'getOutfitCount',
  'getOutfitById',
  'loadRecentWearLogs'
]) {
  assertIncludes(source, needle);
}

assertIncludes(source, 'display_source', 'repository must persist the outfit display source');
assertIncludes(source, 'displaySource', 'repository must hydrate the outfit display source');

for (const method of ['createOutfit', 'updateOutfit', 'deleteOutfit']) {
  assertMatches(
    source,
    new RegExp(`${method}\\s*\\([^)]*\\)\\s*:\\s*Promise<[^>]+>\\s*{[\\s\\S]*?this\\.database\\.transaction`, 'm'),
    `${method} must run in a database transaction`
  );
}

assertMatches(source, /constructor\s*\(\s*database:\s*MigrationDatabase\s*,\s*searchIndexMode:\s*SearchIndexMode\s*,\s*photoStorage\?:\s*PhotoStorage\s*\)/, 'constructor must accept the shared database, search index mode, and optional photo storage');
assertMatches(source, /new\s+SearchRepository\s*\(\s*database\s*,\s*searchIndexMode\s*\)/, 'OutfitRepository must build SearchRepository from the same database');
assertMatches(source, /new\s+DeleteCleanupService\s*\([\s\S]*photoStorage\s*\)/, 'OutfitRepository must pass PhotoStorage to DeleteCleanupService');
assertMatches(source, /INSERT\s+INTO\s+outfit_templates/i, 'createOutfit must insert outfit_templates');
assertMatches(source, /UPDATE\s+outfit_templates/i, 'updateOutfit must update outfit_templates');
assertMatches(source, /DELETE\s+FROM\s+outfit_templates/i, 'deleteOutfit must delete outfit_templates');
assertMatches(source, /INSERT\s+INTO\s+outfit_photos/i, 'repository must insert outfit_photos');
assert.equal(/INSERT_OUTFIT_PHOTO_SQL[\s\S]*COALESCE[\s\S]*VALUES/.test(source), false, 'INSERT outfit photo columns must not include derived values');
assertMatches(source, /DELETE\s+FROM\s+outfit_photos\s+WHERE\s+outfit_id\s*=\s*\?/i, 'repository must replace outfit_photos by outfit_id');
assertMatches(source, /ORDER\s+BY\s+sort_order/i, 'photo and clothing relation loading must respect sort_order');
assertMatches(source, /INSERT\s+INTO\s+outfit_items/i, 'repository must write outfit_items');
assert.equal(/INSERT_OUTFIT_ITEM_SQL[\s\S]*COALESCE[\s\S]*VALUES/.test(source), false, 'INSERT outfit item columns must not include derived values');
assertMatches(source, /DELETE\s+FROM\s+outfit_items\s+WHERE\s+outfit_id\s*=\s*\?/i, 'repository must replace outfit_items by outfit_id');
assertMatches(source, /SELECT\s+id,\s+name\s+FROM\s+clothing_items/i, 'repository must load clothing names for search documents');
assertMatches(source, /WHERE\s+id\s+IN\s+\(\{placeholders\}\)/i, 'clothing name lookup must use generated SQL placeholders');
assertMatches(source, /SELECT_CLOTHING_NAMES_SQL\.replace\s*\(\s*['"`]\{placeholders\}['"`]\s*,\s*placeholders\s*\)/, 'clothing name lookup must replace placeholders only, not values');
assertMatches(source, /buildOutfitSearchDocument\s*\(\s*item\s*,\s*clothingNames\s*\)/, 'search index must include clothing names');
assertMatches(source, /upsertDocumentInTransaction\s*\(\s*buildOutfitSearchDocument/i, 'create/update must update search index inside the outfit transaction');
assertMatches(source, /deleteDocumentInTransaction\s*\(\s*SearchEntityType\.Outfit/i, 'delete must remove outfit search index inside the outfit transaction');
assertMatches(source, /wear_logs/i, 'repository must expose recent wear log loading hook');
assertMatches(source, /ORDER\s+BY\s+worn_date\s+DESC/i, 'recent wear logs must order by worn_date DESC');
assertMatches(source, /LIMIT\s+\?/i, 'recent wear logs must support a limit');
assertMatches(source, /COALESCE\(\s*note,\s*(?:\\?['"]){2}\s*\)/i, 'repository must tolerate nullable note values');
assertMatches(source, /COALESCE\(\s*outfit_id,\s*(?:\\?['"]){2}\s*\)\s+AS\s+outfit_id/i, 'recent wear log hook must tolerate nullable outfit_id');
assertMatches(source, /const\s+COUNT_OUTFITS_SQL\s*=\s*['"]SELECT\s+COUNT\s*\(\s*\*\s*\)\s+AS\s+total_count\s+FROM\s+outfit_templates['"]\s*;/i, 'repository must count outfit_templates with a lightweight SQLite aggregate');

const outfitCountBody = source.match(/async\s+getOutfitCount\s*\(\s*\)\s*:\s*Promise<number>[\s\S]*?\n\s*}\n\n\s*async\s+getOutfitById/);
assert.ok(outfitCountBody, 'getOutfitCount body must be present');
assertMatches(outfitCountBody[0], /querySql\s*\(\s*COUNT_OUTFITS_SQL\s*\)/, 'getOutfitCount must execute the aggregate query directly');
assert.equal(/listOutfits|hydrateOutfits|readPhotoUris|readClothingItemIds/.test(outfitCountBody[0]), false, 'getOutfitCount must not load outfit objects, photos, or clothing relations');
assertMatches(outfitCountBody[0], /finally\s*{\s*resultSet\.close\s*\(\s*\)/, 'getOutfitCount must always close its ResultSet');

assertOrdered(
  source,
  'DELETE FROM outfit_items WHERE outfit_id = ?',
  'INSERT INTO outfit_items',
  'outfit item replacement should delete existing rows before inserting new rows'
);
assertOrdered(
  source,
  'DELETE FROM outfit_photos WHERE outfit_id = ?',
  'INSERT INTO outfit_photos',
  'outfit photo replacement should delete existing rows before inserting new rows'
);

assert.equal(source.includes('@ohos.net'), false, 'OutfitRepository must stay local-only');
assert.equal(source.includes('fetch('), false, 'OutfitRepository must not use fetch');
assert.equal(/photoStorage\.(copy|save|persist|import|write|ensure)/.test(source), false, 'OutfitRepository must not copy photo files directly');
assert.equal(source.includes('BLOB'), false, 'OutfitRepository must not store image blobs');

console.log('PASS');
