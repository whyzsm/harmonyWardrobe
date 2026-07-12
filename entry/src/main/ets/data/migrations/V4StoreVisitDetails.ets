import { Migration, MigrationDatabase } from './Migration';

const STORE_VISIT_TABLE_INFO_SQL = 'PRAGMA table_info(store_visits)';

interface StoreVisitColumnPatch {
  name: string;
  addColumnSql: string;
}

const STORE_VISIT_COLUMN_PATCHES: StoreVisitColumnPatch[] = [
  {
    name: 'status',
    addColumnSql: "ALTER TABLE store_visits ADD COLUMN status TEXT NOT NULL DEFAULT 'visited'"
  },
  {
    name: 'focus_tags',
    addColumnSql: "ALTER TABLE store_visits ADD COLUMN focus_tags TEXT NOT NULL DEFAULT ''"
  }
];

export async function ensureStoreVisitDetailColumns(database: MigrationDatabase): Promise<void> {
  const columns = await readColumnNames(database);
  for (const columnPatch of STORE_VISIT_COLUMN_PATCHES) {
    if (columns.has(columnPatch.name)) {
      continue;
    }

    await database.executeSql(columnPatch.addColumnSql);
    columns.add(columnPatch.name);
  }
}

async function readColumnNames(database: MigrationDatabase): Promise<Set<string>> {
  const resultSet = await database.querySql(STORE_VISIT_TABLE_INFO_SQL);
  const columns = new Set<string>();

  try {
    let hasRow = resultSet.goToFirstRow();
    while (hasRow) {
      const columnName = resultSet.getString('name');
      if (columnName.length > 0) {
        columns.add(columnName);
      }
      hasRow = resultSet.goToNextRow();
    }
  } finally {
    resultSet.close();
  }

  return columns;
}

export class V4StoreVisitDetails implements Migration {
  version: number = 4;
  name: string = 'store_visit_details';

  async up(database: MigrationDatabase): Promise<void> {
    await ensureStoreVisitDetailColumns(database);
  }
}

export const v4StoreVisitDetails: Migration = new V4StoreVisitDetails();
