import assert from 'node:assert/strict';
import fs from 'node:fs';

const repositoryPath = 'entry/src/main/ets/data/repositories/WearLogRepository.ets';
const outfitRepositoryPath = 'entry/src/main/ets/data/repositories/OutfitRepository.ets';
const modelPath = 'entry/src/main/ets/domain/wearLog/WearLogModels.ets';

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
  'buildWearLogSearchDocument',
  'SearchEntityType',
  'WearLog',
  'createId',
  'toIsoDateTime',
  'WearLogRepository',
  'CreateWearLogInput',
  'UpdateWearLogInput',
  'createWearLog',
  'updateWearLog',
  'deleteWearLog',
  'getWearLogById',
  'listWearLogs',
  'encodeClothingItemIdsSnapshot',
  'decodeClothingItemIdsSnapshot'
]) {
  assertIncludes(source, needle);
}

for (const method of ['createWearLog', 'updateWearLog', 'deleteWearLog']) {
  assertMatches(
    source,
    new RegExp(`${method}\\s*\\([^)]*\\)\\s*:\\s*Promise<[^>]+>\\s*{[\\s\\S]*?this\\.database\\.transaction`, 'm'),
    `${method} must run in a database transaction`
  );
}

assertMatches(source, /constructor\s*\(\s*database:\s*MigrationDatabase\s*,\s*searchIndexMode:\s*SearchIndexMode\s*,\s*photoStorage\?:\s*PhotoStorage\s*\)/, 'constructor must accept the shared database, search index mode, and optional photo storage');
assertMatches(source, /new\s+SearchRepository\s*\(\s*database\s*,\s*searchIndexMode\s*\)/, 'WearLogRepository must build SearchRepository from the same database');
assertMatches(source, /new\s+DeleteCleanupService\s*\([\s\S]*photoStorage\s*\)/, 'WearLogRepository must pass PhotoStorage to DeleteCleanupService');
assertMatches(source, /INSERT\s+INTO\s+wear_logs/i, 'createWearLog must insert wear_logs');
assertMatches(source, /UPDATE\s+wear_logs/i, 'updateWearLog must update wear_logs');
assertMatches(source, /export\s+interface\s+CreateWearLogInput\s*{[\s\S]*?outfitTemplateId\?:\s*string/, 'CreateWearLogInput should allow an optional outfitTemplateId');
assertMatches(source, /export\s+interface\s+UpdateWearLogInput\s*{[\s\S]*?outfitTemplateId\?:\s*string/, 'UpdateWearLogInput should allow an optional outfitTemplateId');
assertMatches(source, /wearLogBindArgs\s*\(\s*wearLog:\s*WearLog\s*,\s*outfitTemplateId\??:\s*string\s*\)/, 'wearLogBindArgs must accept an optional outfitTemplateId');
assertMatches(source, /optionalOutfitSnapshot|requiredOutfitSnapshot|fallbackTitle/, 'WearLogRepository must support a fallback snapshot when no outfit is selected');
assert.equal(source.includes('wearLog.outfitTemplateId,'), false, 'SQL bind args must not use optional wearLog.outfitTemplateId directly');
assertMatches(source, /DELETE\s+FROM\s+wear_logs/i, 'deleteWearLog must delete wear_logs');
assertMatches(source, /INSERT\s+INTO\s+wear_log_photos/i, 'repository must insert wear_log_photos');
assertMatches(source, /DELETE\s+FROM\s+wear_log_photos\s+WHERE\s+wear_log_id\s*=\s*\?/i, 'repository must replace wear_log_photos by wear_log_id');
assertMatches(source, /ORDER\s+BY\s+sort_order/i, 'photo loading must respect sort_order');
assertMatches(source, /SELECT[\s\S]*outfit_templates[\s\S]*outfit_items/i, 'repository must snapshot outfit title and clothing ids');
assertMatches(source, /COALESCE\(\s*items\.clothing_id,\s*(?:\\?['"]){2}\s*\)\s+AS\s+clothing_id/i, 'outfit snapshot must tolerate outfits without clothing rows');
assertMatches(source, /JSON\.stringify\s*\(\s*clothingItemIds\s*\)/, 'clothing item snapshot must be encoded as JSON');
assertMatches(source, /JSON\.parse/, 'clothing item snapshot must be decoded as JSON');
assertMatches(source, /Array\.isArray/, 'snapshot decode must validate JSON arrays');
assertMatches(source, /typeof\s+id\s+===\s+['"`]string['"`]/, 'snapshot decode must validate JSON string elements');
assertMatches(source, /listWearLogs\s*\([^)]*\)\s*:\s*Promise<WearLog\[\]>/, 'listWearLogs must expose all logs for startup search index rebuild');
assert.equal(source.includes('listWearLogsByDate'), false, 'WearLogRepository must not keep date-only query for the removed calendar UI');
assert.equal(source.includes('listWearLogDatesForMonth'), false, 'WearLogRepository must not keep month marker query for the removed calendar UI');
assert.equal(source.includes('SELECT DISTINCT worn_date'), false, 'WearLogRepository must not keep calendar marker SQL');
assertMatches(source, /upsertDocumentInTransaction\s*\(\s*buildWearLogSearchDocument/i, 'create/update must update search index inside the wear log transaction');
assertMatches(source, /deleteDocumentInTransaction\s*\(\s*SearchEntityType\.WearLog/i, 'delete must remove wear log search index inside the transaction');
assertMatches(source, /COALESCE\(\s*place_text,\s*(?:\\?['"]){2}\s*\)/i, 'repository must tolerate nullable place_text values');
assertMatches(source, /COALESCE\(\s*note,\s*(?:\\?['"]){2}\s*\)/i, 'repository must tolerate nullable note values');

assertOrdered(
  source,
  'DELETE FROM wear_log_photos WHERE wear_log_id = ?',
  'INSERT INTO wear_log_photos',
  'wear log photo replacement should delete existing rows before inserting new rows'
);

assert.equal(source.includes('@ohos.net'), false, 'WearLogRepository must stay local-only');
assert.equal(source.includes('fetch('), false, 'WearLogRepository must not use fetch');
assert.equal(/photoStorage\.(copy|save|persist|import|write|ensure)/.test(source), false, 'WearLogRepository must not copy photo files directly');
assert.equal(source.includes('BLOB'), false, 'WearLogRepository must not store image blobs');

const outfitRepository = readRequired(outfitRepositoryPath);
assertMatches(outfitRepository, /decodeClothingItemIdsSnapshot|JSON\.parse/, 'OutfitRepository recent wear log hook must use the shared JSON snapshot format');
assertMatches(outfitRepository, /typeof\s+id\s+===\s+['"`]string['"`]/, 'OutfitRepository snapshot decode must validate JSON string elements');

const model = readRequired(modelPath);
assertMatches(model, /outfitTemplateId\??:\s*string/, 'WearLog model must allow deleted outfits to be represented without a fake id');

console.log('PASS');
