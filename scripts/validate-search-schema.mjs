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
  const catchMatch = /^\s*catch\s*(?:\([^)]*\)\s*)?\{/.exec(tail);

  if (!catchMatch) {
    throw new Error('Missing catch block for try');
  }

  const catchOpenBraceIndex = source.indexOf('{', closeBraceIndex + 1 + catchMatch.index);
  const catchCloseBraceIndex = findMatchingBrace(source, catchOpenBraceIndex);

  return {
    tryBody: source.slice(openBraceIndex + 1, closeBraceIndex),
    catchBody: source.slice(catchOpenBraceIndex + 1, catchCloseBraceIndex)
  };
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

function assertNoThrowOrReturn(source, sourceName) {
  if (/\b(?:throw|return)\b/.test(source)) {
    throw new Error(`${sourceName} must not throw or return`);
  }
}

function assertBestEffortFts5CleanupFinally(finallyBlock) {
  if (!/DROP_SEARCH_FTS_PROBE_SQL/.test(finallyBlock)) {
    throw new Error('Search capability must drop the FTS probe table in finally');
  }

  const finallyTopLevelText = topLevelTextOnly(finallyBlock);
  assertNoThrowOrReturn(finallyTopLevelText, 'Search capability FTS cleanup finally top level');

  if (/^\s*await\s+database\.executeSql\s*\(\s*DROP_SEARCH_FTS_PROBE_SQL\s*\)/m.test(finallyTopLevelText)) {
    throw new Error('Search capability must not directly await probe cleanup in finally');
  }

  const cleanupTryCatchBlock = extractTryCatchBlock(finallyBlock);
  if (!/await\s+database\.executeSql\s*\(\s*DROP_SEARCH_FTS_PROBE_SQL\s*\)/.test(cleanupTryCatchBlock.tryBody)) {
    throw new Error('Search capability must run probe cleanup inside a nested try block');
  }

  assertNoThrowOrReturn(cleanupTryCatchBlock.catchBody, 'Search capability FTS cleanup catch');
}

function assertRejectsBadFts5CleanupFinally(finallyBlock, expectedMessage) {
  try {
    assertBestEffortFts5CleanupFinally(finallyBlock);
  } catch (error) {
    if (!String(error.message).includes(expectedMessage)) {
      throw new Error(`Negative self-check rejected for the wrong reason: ${error.message}`);
    }
    return;
  }

  throw new Error(`Negative self-check must reject ${expectedMessage}`);
}

assertRejectsBadFts5CleanupFinally(`
  try {
    await database.executeSql(DROP_SEARCH_FTS_PROBE_SQL);
  } catch (_error) {
    throw _error;
  }
`, 'cleanup catch');

assertRejectsBadFts5CleanupFinally(`
  try {
    await database.executeSql(DROP_SEARCH_FTS_PROBE_SQL);
  } catch (_error) {
    return false;
  }
`, 'cleanup catch');

assertRejectsBadFts5CleanupFinally(`
  try {
    await database.executeSql(DROP_SEARCH_FTS_PROBE_SQL);
  } catch (_error) {
  }

  return false;
`, 'finally top level');

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
assertBestEffortFts5CleanupFinally(canUseFts5FinallyBlock);

assertOmits(schema, 'Search schema', [
  'idx_search_index_documents_entity',
  'idx_search_index_ngrams_document_id'
]);
