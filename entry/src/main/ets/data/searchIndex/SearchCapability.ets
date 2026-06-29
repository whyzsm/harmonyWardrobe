import { MigrationDatabase } from '../migrations/Migration';
import {
  CREATE_SEARCH_INDEX_FALLBACK_SQLS,
  CREATE_SEARCH_INDEX_FTS_SQL
} from './SearchIndexSchema';

export type SearchIndexMode = 'fts5' | 'fallback';

export interface SearchCapability {
  mode: SearchIndexMode;
}

export async function detectSearchCapability(database: MigrationDatabase): Promise<SearchCapability> {
  try {
    await database.executeSql(CREATE_SEARCH_INDEX_FTS_SQL);
    return { mode: 'fts5' };
  } catch (_error) {
    for (const sql of CREATE_SEARCH_INDEX_FALLBACK_SQLS) {
      await database.executeSql(sql);
    }

    return { mode: 'fallback' };
  }
}
