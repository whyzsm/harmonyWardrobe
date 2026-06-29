import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { SearchIndexMode } from '../searchIndex/SearchCapability';
import { SearchDocument } from '../../domain/search/SearchDocumentBuilder';
import { SearchEntityType, SearchResult } from '../../domain/search/SearchModels';
import { buildSearchNgrams } from '../../utils/ngram';

const DEFAULT_SEARCH_LIMIT = 20;
const MAX_SEARCH_LIMIT = 100;

const SELECT_DOCUMENT_SQL = `
  SELECT
    id,
    entity_type,
    entity_id,
    title,
    body,
    COALESCE(category, '') AS category,
    COALESCE(store_name, '') AS store_name,
    ngrams
  FROM search_index_documents
  WHERE entity_type = ? AND entity_id = ?
`;

const INSERT_DOCUMENT_SQL = `
  INSERT INTO search_index_documents (
    entity_type,
    entity_id,
    title,
    body,
    category,
    store_name,
    ngrams
  )
  VALUES (?, ?, ?, ?, ?, ?, ?)
`;

const UPDATE_DOCUMENT_SQL = `
  UPDATE search_index_documents
  SET
    title = ?,
    body = ?,
    category = ?,
    store_name = ?,
    ngrams = ?
  WHERE entity_type = ? AND entity_id = ?
`;

const DELETE_DOCUMENT_SQL = `
  DELETE FROM search_index_documents
  WHERE entity_type = ? AND entity_id = ?
`;

const INSERT_FTS_DOCUMENT_SQL = `
  INSERT INTO search_index_fts (
    rowid,
    entity_type,
    entity_id,
    title,
    body,
    category,
    store_name,
    ngrams
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)
`;

const DELETE_FTS_DOCUMENT_SQL = `
  INSERT INTO search_index_fts(
    search_index_fts,
    rowid,
    entity_type,
    entity_id,
    title,
    body,
    category,
    store_name,
    ngrams
  )
  VALUES('delete', ?, ?, ?, ?, ?, ?, ?, ?)
`;

const DELETE_ALL_FTS_DOCUMENTS_SQL = `
  INSERT INTO search_index_fts(search_index_fts)
  VALUES('delete-all')
`;

const DELETE_ALL_DOCUMENTS_SQL = 'DELETE FROM search_index_documents';
const DELETE_ALL_FALLBACK_NGRAMS_SQL = 'DELETE FROM search_index_ngrams';
const DELETE_DOCUMENT_NGRAMS_SQL = 'DELETE FROM search_index_ngrams WHERE document_id = ?';
const INSERT_DOCUMENT_NGRAM_SQL = `
  INSERT INTO search_index_ngrams (document_id, ngram)
  VALUES (?, ?)
`;

const SEARCH_FTS_SQL = `
  SELECT entity_type, entity_id, title
  FROM search_index_fts
  WHERE search_index_fts MATCH ?
  ORDER BY rank
  LIMIT ?
`;

interface SearchIndexDocumentRow {
  id: number;
  entityType: SearchEntityType;
  entityId: string;
  title: string;
  body: string;
  category: string;
  storeName: string;
  ngrams: string;
}

function documentBindArgs(document: SearchDocument): MigrationSqlValue[] {
  return [
    document.entityType,
    document.entityId,
    document.title,
    document.body,
    document.category ?? null,
    document.storeName ?? null,
    document.ngrams
  ];
}

function splitStoredNgrams(ngrams: string): string[] {
  const values: string[] = [];
  const seen = new Set<string>();

  for (const ngram of ngrams.split(/\s+/)) {
    if (ngram.length === 0 || seen.has(ngram)) {
      continue;
    }

    seen.add(ngram);
    values.push(ngram);
  }

  return values;
}

function quoteFtsTerm(term: string): string {
  return '"' + term.replace(/"/g, '""') + '"';
}

function buildFtsQuery(tokens: string[]): string {
  return tokens.map((term) => quoteFtsTerm(term)).join(' AND ');
}

export class SearchRepository {
  private readonly database: MigrationDatabase;
  private readonly mode: SearchIndexMode;

  constructor(database: MigrationDatabase, mode: SearchIndexMode) {
    this.database = database;
    this.mode = mode;
  }

  async upsertDocument(document: SearchDocument): Promise<void> {
    await this.database.transaction(async () => {
      await this.upsertDocumentInTransaction(document);
    });
  }

  async upsertDocumentInTransaction(document: SearchDocument): Promise<void> {
    const existing = await this.readDocumentRow(document.entityType, document.entityId);

    if (existing === undefined) {
      await this.insertDocument(document);
    } else {
      if (this.mode === 'fts5') {
        await this.deleteFtsDocument(existing);
      }

      await this.updateDocument(document);
    }

    const savedDocument = await this.requireDocumentRow(document.entityType, document.entityId);
    if (this.mode === 'fts5') {
      await this.insertFtsDocument(savedDocument);
      return;
    }

    await this.rebuildFallbackNgrams(savedDocument.id, document.ngrams);
  }

  async deleteDocument(entityType: SearchEntityType, entityId: string): Promise<void> {
    await this.database.transaction(async () => {
      await this.deleteDocumentInTransaction(entityType, entityId);
    });
  }

  async deleteDocumentInTransaction(entityType: SearchEntityType, entityId: string): Promise<void> {
    const existing = await this.readDocumentRow(entityType, entityId);
    if (existing === undefined) {
      return;
    }

    if (this.mode === 'fts5') {
      await this.deleteFtsDocument(existing);
    } else {
      await this.deleteFallbackNgrams(existing.id);
    }

    await this.database.executeSql(DELETE_DOCUMENT_SQL, [entityType, entityId]);
  }

  async search(query: string, limit: number = 20): Promise<SearchResult[]> {
    const tokens = buildSearchNgrams(query);
    if (tokens.length === 0) {
      return [];
    }

    let normalizedLimit = DEFAULT_SEARCH_LIMIT;
    if (Number.isFinite(limit) && limit > 0) {
      normalizedLimit = Math.min(MAX_SEARCH_LIMIT, Math.max(1, Math.floor(limit)));
    }

    if (this.mode === 'fts5') {
      return this.searchFts(tokens, normalizedLimit);
    }

    return this.searchFallback(tokens, normalizedLimit);
  }

  async rebuildSearchIndex(documents: SearchDocument[]): Promise<void> {
    await this.database.transaction(async () => {
      if (this.mode === 'fts5') {
        await this.database.executeSql(DELETE_ALL_FTS_DOCUMENTS_SQL);
      } else {
        await this.database.executeSql(DELETE_ALL_FALLBACK_NGRAMS_SQL);
      }

      await this.database.executeSql(DELETE_ALL_DOCUMENTS_SQL);

      for (const document of documents) {
        await this.insertDocument(document);
        const savedDocument = await this.requireDocumentRow(document.entityType, document.entityId);

        if (this.mode === 'fts5') {
          await this.insertFtsDocument(savedDocument);
        } else {
          await this.rebuildFallbackNgrams(savedDocument.id, document.ngrams);
        }
      }
    });
  }

  private async insertDocument(document: SearchDocument): Promise<void> {
    await this.database.executeSql(INSERT_DOCUMENT_SQL, documentBindArgs(document));
  }

  private async updateDocument(document: SearchDocument): Promise<void> {
    await this.database.executeSql(UPDATE_DOCUMENT_SQL, [
      document.title,
      document.body,
      document.category ?? null,
      document.storeName ?? null,
      document.ngrams,
      document.entityType,
      document.entityId
    ]);
  }

  private async readDocumentRow(
    entityType: SearchEntityType,
    entityId: string
  ): Promise<SearchIndexDocumentRow | undefined> {
    const resultSet = await this.database.querySql(SELECT_DOCUMENT_SQL, [entityType, entityId]);

    try {
      if (!resultSet.goToFirstRow()) {
        return undefined;
      }

      return this.readDocumentRowFromResultSet(resultSet);
    } finally {
      resultSet.close();
    }
  }

  private async requireDocumentRow(entityType: SearchEntityType, entityId: string): Promise<SearchIndexDocumentRow> {
    const document = await this.readDocumentRow(entityType, entityId);
    if (document === undefined) {
      throw new Error(`Search document not found: ${entityType}/${entityId}`);
    }

    return document;
  }

  private readDocumentRowFromResultSet(resultSet: MigrationResultSet): SearchIndexDocumentRow {
    return {
      id: resultSet.getNumber('id'),
      entityType: resultSet.getString('entity_type') as SearchEntityType,
      entityId: resultSet.getString('entity_id'),
      title: resultSet.getString('title'),
      body: resultSet.getString('body'),
      category: resultSet.getString('category'),
      storeName: resultSet.getString('store_name'),
      ngrams: resultSet.getString('ngrams')
    };
  }

  private async insertFtsDocument(document: SearchIndexDocumentRow): Promise<void> {
    await this.database.executeSql(INSERT_FTS_DOCUMENT_SQL, [
      document.id,
      document.entityType,
      document.entityId,
      document.title,
      document.body,
      document.category,
      document.storeName,
      document.ngrams
    ]);
  }

  private async deleteFtsDocument(document: SearchIndexDocumentRow): Promise<void> {
    await this.database.executeSql(DELETE_FTS_DOCUMENT_SQL, [
      document.id,
      document.entityType,
      document.entityId,
      document.title,
      document.body,
      document.category,
      document.storeName,
      document.ngrams
    ]);
  }

  private async deleteFallbackNgrams(documentId: number): Promise<void> {
    await this.database.executeSql(DELETE_DOCUMENT_NGRAMS_SQL, [documentId]);
  }

  private async rebuildFallbackNgrams(documentId: number, ngrams: string): Promise<void> {
    await this.deleteFallbackNgrams(documentId);

    for (const ngram of splitStoredNgrams(ngrams)) {
      await this.database.executeSql(INSERT_DOCUMENT_NGRAM_SQL, [documentId, ngram]);
    }
  }

  private async searchFts(tokens: string[], limit: number): Promise<SearchResult[]> {
    return this.readSearchResults(SEARCH_FTS_SQL, [buildFtsQuery(tokens), limit]);
  }

  private async searchFallback(tokens: string[], limit: number): Promise<SearchResult[]> {
    const placeholders = tokens.map(() => '?').join(', ');
    const sql = `
      SELECT
        documents.entity_type,
        documents.entity_id,
        documents.title,
        COUNT(ngrams.ngram) AS matched_count
      FROM search_index_ngrams ngrams
      JOIN search_index_documents documents ON documents.id = ngrams.document_id
      WHERE ngrams.ngram IN (${placeholders})
      GROUP BY documents.id, documents.entity_type, documents.entity_id, documents.title
      HAVING COUNT(DISTINCT ngrams.ngram) = ?
      ORDER BY matched_count DESC, documents.title ASC
      LIMIT ?
    `;

    return this.readSearchResults(sql, [...tokens, tokens.length, limit]);
  }

  private async readSearchResults(sql: string, bindArgs: MigrationSqlValue[]): Promise<SearchResult[]> {
    const resultSet = await this.database.querySql(sql, bindArgs);
    const results: SearchResult[] = [];

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        results.push({
          entityType: resultSet.getString('entity_type') as SearchEntityType,
          entityId: resultSet.getString('entity_id'),
          title: resultSet.getString('title')
        });
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return results;
  }
}
