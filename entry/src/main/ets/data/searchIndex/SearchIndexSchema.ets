export const CREATE_SEARCH_INDEX_FTS_SQL = `
  CREATE VIRTUAL TABLE IF NOT EXISTS search_index_fts USING fts5 (
    entity_type UNINDEXED,
    entity_id UNINDEXED,
    title,
    body,
    category,
    store_name,
    ngrams,
    tokenize = 'unicode61'
  )
`;

export const CREATE_SEARCH_INDEX_FALLBACK_DOCUMENTS_SQL = `
  CREATE TABLE IF NOT EXISTS search_index_documents (
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    category TEXT,
    store_name TEXT,
    PRIMARY KEY (entity_type, entity_id)
  )
`;

export const CREATE_SEARCH_INDEX_FALLBACK_NGRAMS_SQL = `
  CREATE TABLE IF NOT EXISTS search_index_ngrams (
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    ngram TEXT NOT NULL,
    PRIMARY KEY (entity_type, entity_id, ngram),
    FOREIGN KEY (entity_type, entity_id)
      REFERENCES search_index_documents(entity_type, entity_id)
      ON DELETE CASCADE
  )
`;

export const CREATE_SEARCH_INDEX_FALLBACK_INDEX_SQLS: string[] = [
  'CREATE INDEX IF NOT EXISTS idx_search_index_ngrams_ngram ON search_index_ngrams(ngram)',
  'CREATE INDEX IF NOT EXISTS idx_search_index_documents_category ON search_index_documents(category)',
  'CREATE INDEX IF NOT EXISTS idx_search_index_documents_store_name ON search_index_documents(store_name)'
];

export const CREATE_SEARCH_INDEX_FALLBACK_SQLS: string[] = [
  CREATE_SEARCH_INDEX_FALLBACK_DOCUMENTS_SQL,
  CREATE_SEARCH_INDEX_FALLBACK_NGRAMS_SQL,
  ...CREATE_SEARCH_INDEX_FALLBACK_INDEX_SQLS
];
