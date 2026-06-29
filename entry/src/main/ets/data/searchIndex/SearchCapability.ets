import { MigrationDatabase } from '../migrations/Migration';
import {
  CREATE_SEARCH_INDEX_FALLBACK_SQLS,
  CREATE_SEARCH_INDEX_FTS_SQLS
} from './SearchIndexSchema';

export type SearchIndexMode = 'fts5' | 'fallback';

export interface SearchCapability {
  mode: SearchIndexMode;
}

export const CREATE_SEARCH_FTS_PROBE_SQL = `
  CREATE VIRTUAL TABLE IF NOT EXISTS temp.search_fts_probe USING fts5 (
    value,
    tokenize = 'unicode61'
  )
`;

export const DROP_SEARCH_FTS_PROBE_SQL = 'DROP TABLE IF EXISTS temp.search_fts_probe';

async function executeSqls(database: MigrationDatabase, sqls: string[]): Promise<void> {
  for (const sql of sqls) {
    await database.executeSql(sql);
  }
}

export async function canUseFts5(database: MigrationDatabase): Promise<boolean> {
  try {
    await database.executeSql(CREATE_SEARCH_FTS_PROBE_SQL);
    return true;
  } catch (_error) {
    return false;
  } finally {
    try {
      await database.executeSql(DROP_SEARCH_FTS_PROBE_SQL);
    } catch (_error) {
    }
  }
}

export async function detectSearchCapability(database: MigrationDatabase): Promise<SearchCapability> {
  if (await canUseFts5(database)) {
    await executeSqls(database, CREATE_SEARCH_INDEX_FTS_SQLS);
    return { mode: 'fts5' };
  }

  await executeSqls(database, CREATE_SEARCH_INDEX_FALLBACK_SQLS);
  return { mode: 'fallback' };
}
