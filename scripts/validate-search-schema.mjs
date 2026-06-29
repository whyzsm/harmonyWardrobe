import fs from 'node:fs';

function assertContains(source, sourceName, needles) {
  for (const needle of needles) {
    if (!source.includes(needle)) throw new Error(`${sourceName} missing ${needle}`);
  }
}

function assertOmits(source, sourceName, needles) {
  for (const needle of needles) {
    if (source.includes(needle)) throw new Error(`${sourceName} must not contain ${needle}`);
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

function extractFunctionBody(source, functionName) {
  const functionIndex = source.indexOf(`function ${functionName}`);
  if (functionIndex === -1) throw new Error(`Missing function ${functionName}`);

  const openBraceIndex = source.indexOf('{', functionIndex);
  if (openBraceIndex === -1) throw new Error(`Missing function body for ${functionName}`);

  const closeBraceIndex = findMatchingBrace(source, openBraceIndex);
  return source.slice(openBraceIndex + 1, closeBraceIndex);
}

function extractKeywordBlock(source, keyword) {
  const keywordPattern = new RegExp(`\\b${keyword}\\s*\\{`, 'm');
  const match = keywordPattern.exec(source);
  if (!match) throw new Error(`Missing ${keyword} block`);

  const openBraceIndex = source.indexOf('{', match.index);
  const closeBraceIndex = findMatchingBrace(source, openBraceIndex);
  return source.slice(openBraceIndex + 1, closeBraceIndex);
}

function extractTryCatchBlock(source) {
  const match = /\btry\s*\{/.exec(source);
  if (!match) throw new Error('Missing try block');

  const openBraceIndex = source.indexOf('{', match.index);
  const closeBraceIndex = findMatchingBrace(source, openBraceIndex);
  const tail = source.slice(closeBraceIndex + 1);

  if (!/^\s*catch\s*\([^)]*\)\s*\{/.test(tail)) {
    throw new Error('Missing catch block for try');
  }

  return source.slice(openBraceIndex + 1, closeBraceIndex);
}

function topLevelTextOnly(source) {
  let depth = 0;
  let result = '';

  for (let index = 0; index < source.length; index += 1) {
    const char = source[index];

    if (char === '{') {
      depth += 1;
    } else if (char === '}') {
      depth -= 1;
    } else if (depth === 0) {
      result += char;
    }
  }

  return result;
}

const schema = fs.readFileSync('entry/src/main/ets/data/searchIndex/SearchIndexSchema.ets', 'utf8');
assertContains(schema, 'Search schema', [
  'CREATE_SEARCH_INDEX_DOCUMENTS_SQL',
  'CREATE_SEARCH_INDEX_FTS_SQLS',
  'CREATE_SEARCH_INDEX_FALLBACK_SQLS',
  'CREATE VIRTUAL TABLE IF NOT EXISTS search_index_fts USING fts5',
  "content='search_index_documents'",
  "content_rowid='id'",
  'id INTEGER PRIMARY KEY AUTOINCREMENT',
  'UNIQUE(entity_type, entity_id)',
  'document_id INTEGER NOT NULL',
  'REFERENCES search_index_documents(id)',
  'ON DELETE CASCADE'
]);

const capability = fs.readFileSync('entry/src/main/ets/data/searchIndex/SearchCapability.ets', 'utf8');
assertContains(capability, 'Search capability', [
  'detectSearchCapability',
  'canUseFts5',
  'CREATE_SEARCH_FTS_PROBE_SQL',
  'DROP_SEARCH_FTS_PROBE_SQL',
  'temp.search_fts_probe',
  'finally',
  'CREATE_SEARCH_INDEX_FTS_SQLS',
  'CREATE_SEARCH_INDEX_FALLBACK_SQLS',
  'fts5',
  'fallback'
]);

if (/executeSql\s*\(\s*CREATE_SEARCH_INDEX_FTS_SQL\s*\)/.test(capability)) {
  throw new Error('Search capability must not probe by creating the production FTS table');
}

const canUseFts5Body = extractFunctionBody(capability, 'canUseFts5');
if (!/CREATE_SEARCH_FTS_PROBE_SQL/.test(canUseFts5Body)) {
  throw new Error('Search capability must probe FTS5 support with the probe SQL');
}

const canUseFts5FinallyBlock = extractKeywordBlock(canUseFts5Body, 'finally');
if (!/DROP_SEARCH_FTS_PROBE_SQL/.test(canUseFts5FinallyBlock)) {
  throw new Error('Search capability must drop the FTS probe table in finally');
}

if (/^\s*await\s+database\.executeSql\s*\(\s*DROP_SEARCH_FTS_PROBE_SQL\s*\)/m.test(topLevelTextOnly(canUseFts5FinallyBlock))) {
  throw new Error('Search capability must not directly await probe cleanup in finally');
}

const canUseFts5CleanupTryBlock = extractTryCatchBlock(canUseFts5FinallyBlock);
if (!/await\s+database\.executeSql\s*\(\s*DROP_SEARCH_FTS_PROBE_SQL\s*\)/.test(canUseFts5CleanupTryBlock)) {
  throw new Error('Search capability must run probe cleanup inside a nested try block');
}

assertOmits(schema, 'Search schema', [
  'idx_search_index_documents_entity',
  'idx_search_index_ngrams_document_id'
]);
