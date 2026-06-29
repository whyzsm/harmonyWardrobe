import fs from 'node:fs';

const repositoryPath = 'entry/src/main/ets/data/repositories/SearchRepository.ets';
const migrationPath = 'entry/src/main/ets/data/migrations/Migration.ets';
const databaseProviderPath = 'entry/src/main/ets/data/database/DatabaseProvider.ets';

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

function findMatchingBrace(source, openBraceIndex) {
  let depth = 0;

  for (let index = openBraceIndex; index < source.length; index += 1) {
    const char = source[index];

    if (char === '{') {
      depth += 1;
    } else if (char === '}') {
      depth -= 1;

      if (depth === 0) {
        return index;
      }
    }
  }

  throw new Error(`Could not find matching brace at ${openBraceIndex}`);
}

function extractMethodBody(source, methodName) {
  const match = new RegExp(`(?:^|\\n)\\s*(?:private\\s+)?(?:async\\s+)?${methodName}\\s*\\(`).exec(source);
  if (!match) {
    throw new Error(`SearchRepository missing method ${methodName}`);
  }

  const openBraceIndex = source.indexOf('{', match.index);
  if (openBraceIndex === -1) {
    throw new Error(`SearchRepository missing method body for ${methodName}`);
  }

  const closeBraceIndex = findMatchingBrace(source, openBraceIndex);
  return source.slice(openBraceIndex + 1, closeBraceIndex);
}

const repository = readRequired(repositoryPath);

assertMatches(
  repository,
  /export\s+class\s+SearchRepository\b/,
  'SearchRepository must export class SearchRepository'
);
assertMatches(
  repository,
  /constructor\s*\(\s*database:\s*MigrationDatabase\s*,\s*mode:\s*SearchIndexMode\s*\)/,
  'SearchRepository constructor must accept database and mode'
);

for (const method of ['upsertDocument', 'deleteDocument', 'search', 'rebuildSearchIndex']) {
  extractMethodBody(repository, method);
}

for (const needle of [
  'SearchDocument',
  'SearchResult',
  'SearchEntityType',
  'SearchIndexMode',
  'buildSearchNgrams',
  'search_index_documents',
  'search_index_fts',
  'search_index_ngrams'
]) {
  assertIncludes(repository, needle, `SearchRepository missing ${needle}`);
}

const upsertBody = extractMethodBody(repository, 'upsertDocument');
const deleteBody = extractMethodBody(repository, 'deleteDocument');
const searchBody = extractMethodBody(repository, 'search');
const rebuildBody = extractMethodBody(repository, 'rebuildSearchIndex');
const searchFallbackBody = extractMethodBody(repository, 'searchFallback');

for (const [name, body] of [
  ['upsertDocument', upsertBody],
  ['deleteDocument', deleteBody],
  ['rebuildSearchIndex', rebuildBody]
]) {
  assertIncludes(body, 'this.database.transaction', `${name} must use database.transaction`);
}

assertMatches(repository, /this\.mode\s*===\s*'fts5'|this\.mode\s*!==\s*'fallback'/, 'SearchRepository must branch on SearchIndexMode');
assertIncludes(repository, "VALUES('delete'", 'FTS mode must use the FTS5 special delete command');
assertMatches(repository, /INSERT\s+INTO\s+search_index_fts[\s\S]*rowid/i, 'FTS mode must insert indexed rows with rowid');
assertMatches(repository, /MATCH\s+\?/i, 'FTS search must use MATCH with bind args');
assertMatches(repository, /quoteFtsTerm|buildFtsQuery/, 'FTS search must build a safely quoted query');
assertMatches(repository, /term\.replace\s*\(\s*\/"\/g\s*,\s*['"`]""['"`]\s*\)/, 'FTS query terms must escape quotes');
assertMatches(repository, /return\s+['"`]"['"`]\s*\+\s*term\.replace/, 'FTS query terms must be wrapped in quotes');

assertMatches(repository, /DELETE\s+FROM\s+search_index_ngrams\s+WHERE\s+document_id\s*=\s*\?/i, 'Fallback upsert must delete existing ngrams by document_id');
assertMatches(repository, /INSERT\s+INTO\s+search_index_ngrams\s*\(\s*document_id\s*,\s*ngram\s*\)/i, 'Fallback upsert must rebuild document ngrams');
assertMatches(searchFallbackBody, /JOIN\s+search_index_documents/i, 'Fallback search must join documents');
assertMatches(searchFallbackBody, /GROUP\s+BY/i, 'Fallback search must group matches by document');
assertMatches(searchFallbackBody, /COUNT\s*\(/i, 'Fallback search must rank by matched count');
assertMatches(searchFallbackBody, /ORDER\s+BY[\s\S]*matched/i, 'Fallback search must order by matched count');

assertMatches(repository, /bindArgs|:\s*MigrationSqlValue\[\]/, 'SQL values must use bind args');
if (/IN\s*\(\s*\$\{[^}]*tokens/i.test(repository)) {
  throw new Error('Dynamic IN clauses may use placeholders, not interpolated token values');
}
assertMatches(repository, /\?[,)\s]/, 'Repository SQL must use placeholders');
assertMatches(searchBody, /Number\.isFinite/, 'search limit must be normalized with finite number checks');
assertMatches(searchBody, /Math\.floor/, 'search limit must normalize to an integer');
assertMatches(repository, /limit\s*:\s*number\s*=\s*20|limit\s*=\s*20/, 'search limit must default to 20');
assertMatches(searchBody, /return\s+\[\]/, 'empty search queries must return []');

assertMatches(repository, /getString\s*\(\s*'entity_type'\s*\)/, 'search() must read entity_type as a string');
assertMatches(repository, /getString\s*\(\s*'entity_id'\s*\)/, 'search() must read entity_id as a string');
assertMatches(repository, /getString\s*\(\s*'title'\s*\)/, 'search() must read title as a string');

assertMatches(repository, /delete-all|DELETE\s+FROM\s+search_index_fts/i, 'rebuildSearchIndex must clear FTS index');
assertMatches(rebuildBody, /DELETE_ALL_FALLBACK_NGRAMS_SQL|DELETE\s+FROM\s+search_index_ngrams/i, 'rebuildSearchIndex must clear fallback ngrams');
assertMatches(rebuildBody, /DELETE_ALL_DOCUMENTS_SQL|DELETE\s+FROM\s+search_index_documents/i, 'rebuildSearchIndex must clear search documents');
assertMatches(rebuildBody, /for\s*\(\s*const\s+document\s+of\s+documents\s*\)/, 'rebuildSearchIndex must rebuild from provided documents');

const migration = readRequired(migrationPath);
assertMatches(migration, /getString\s*\(\s*columnName:\s*string\s*\):\s*string/, 'MigrationResultSet must expose getString');

const databaseProvider = readRequired(databaseProviderPath);
assertMatches(databaseProvider, /getString\s*\(\s*columnName:\s*string\s*\):\s*string/, 'DatabaseResultSet must implement getString');
assertIncludes(databaseProvider, 'getString(', 'DatabaseProvider must read result strings');

console.log('PASS');
