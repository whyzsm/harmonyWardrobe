import { Migration, MigrationDatabase } from './Migration';

const CLOTHING_TABLE_INFO_SQL = 'PRAGMA table_info(clothing_items)';

interface ClothingColumnPatch {
  name: string;
  addColumnSql: string;
}

const PURCHASE_COLUMN_PATCHES: ClothingColumnPatch[] = [
  {
    name: 'purchase_store_name',
    addColumnSql: 'ALTER TABLE clothing_items ADD COLUMN purchase_store_name TEXT'
  },
  {
    name: 'purchase_price',
    addColumnSql: 'ALTER TABLE clothing_items ADD COLUMN purchase_price INTEGER'
  },
  {
    name: 'purchase_date',
    addColumnSql: 'ALTER TABLE clothing_items ADD COLUMN purchase_date TEXT'
  },
  {
    name: 'purchase_note',
    addColumnSql: 'ALTER TABLE clothing_items ADD COLUMN purchase_note TEXT'
  }
];

export async function ensureClothingPurchaseColumns(database: MigrationDatabase): Promise<void> {
  const columns = await readColumnNames(database);

  for (const columnPatch of PURCHASE_COLUMN_PATCHES) {
    if (!hasColumn(columns, columnPatch.name)) {
      await database.executeSql(columnPatch.addColumnSql);
    }
  }
}

export class V2ClothingPurchaseColumns implements Migration {
  version: number = 2;
  name: string = 'clothing_purchase_columns';

  async up(database: MigrationDatabase): Promise<void> {
    await ensureClothingPurchaseColumns(database);
  }
}

async function readColumnNames(database: MigrationDatabase): Promise<Set<string>> {
  const resultSet = await database.querySql(CLOTHING_TABLE_INFO_SQL);
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

function hasColumn(columns: Set<string>, columnName: string): boolean {
  return columns.has(columnName);
}

export const v2ClothingPurchaseColumns: Migration = new V2ClothingPurchaseColumns();
