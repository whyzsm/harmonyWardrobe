import fs from 'node:fs';

const schema = fs.readFileSync('entry/src/main/ets/data/searchIndex/SearchIndexSchema.ets', 'utf8');
for (const needle of [
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
  'ON DELETE CASCADE',
  'CREATE INDEX IF NOT EXISTS idx_search_index_documents_entity ON search_index_documents(entity_type, entity_id)'
]) {
  if (!schema.includes(needle)) throw new Error(`Search schema missing ${needle}`);
}

const capability = fs.readFileSync('entry/src/main/ets/data/searchIndex/SearchCapability.ets', 'utf8');
for (const needle of [
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
]) {
  if (!capability.includes(needle)) throw new Error(`Search capability missing ${needle}`);
}

if (/executeSql\s*\(\s*CREATE_SEARCH_INDEX_FTS_SQL\s*\)/.test(capability)) {
  throw new Error('Search capability must not probe by creating the production FTS table');
}

if (!/canUseFts5[\s\S]*CREATE_SEARCH_FTS_PROBE_SQL/.test(capability)) {
  throw new Error('Search capability must probe FTS5 support with the probe SQL');
}

if (!/finally[\s\S]*DROP_SEARCH_FTS_PROBE_SQL/.test(capability)) {
  throw new Error('Search capability must drop the FTS probe table in finally');
}
