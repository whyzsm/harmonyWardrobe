import { Migration, MigrationDatabase } from './Migration';
import { normalizeSearchText } from '../../utils/text';

const STORE_TABLE_INFO_SQL = 'PRAGMA table_info(stores)';
const SELECT_STORE_NAMES_SQL = 'SELECT id, name FROM stores';
const ADD_NORMALIZED_NAME_SQL = "ALTER TABLE stores ADD COLUMN normalized_name TEXT NOT NULL DEFAULT ''";
const UPDATE_NORMALIZED_NAME_SQL = 'UPDATE stores SET normalized_name = ? WHERE id = ?';
const CREATE_NORMALIZED_NAME_INDEX_SQL = 'CREATE INDEX IF NOT EXISTS idx_stores_normalized_name ON stores(normalized_name)';

interface StoreNameRow {
  id: string;
  name: string;
}

async function hasNormalizedNameColumn(database: MigrationDatabase): Promise<boolean> {
  const resultSet = await database.querySql(STORE_TABLE_INFO_SQL);
  try {
    let hasRow = resultSet.goToFirstRow();
    while (hasRow) {
      if (resultSet.getString('name') === 'normalized_name') {
        return true;
      }
      hasRow = resultSet.goToNextRow();
    }
  } finally {
    resultSet.close();
  }
  return false;
}

async function readStoreNames(database: MigrationDatabase): Promise<StoreNameRow[]> {
  const resultSet = await database.querySql(SELECT_STORE_NAMES_SQL);
  const rows: StoreNameRow[] = [];
  try {
    let hasRow = resultSet.goToFirstRow();
    while (hasRow) {
      rows.push({
        id: resultSet.getString('id'),
        name: resultSet.getString('name')
      });
      hasRow = resultSet.goToNextRow();
    }
  } finally {
    resultSet.close();
  }
  return rows;
}

export class V6StoreNormalizedName implements Migration {
  version: number = 6;
  name: string = 'store_normalized_name';

  async up(database: MigrationDatabase): Promise<void> {
    if (!await hasNormalizedNameColumn(database)) {
      await database.executeSql(ADD_NORMALIZED_NAME_SQL);
    }

    const rows = await readStoreNames(database);
    for (const row of rows) {
      await database.executeSql(UPDATE_NORMALIZED_NAME_SQL, [normalizeSearchText(row.name), row.id]);
    }

    await database.executeSql(CREATE_NORMALIZED_NAME_INDEX_SQL);
  }
}

export const v6StoreNormalizedName: Migration = new V6StoreNormalizedName();
