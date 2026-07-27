import { Migration, MigrationDatabase } from './Migration';

const OUTFIT_TEMPLATE_TABLE_INFO_SQL = 'PRAGMA table_info(outfit_templates)';

const CREATE_OUTFIT_CATEGORIES_SQL = `
  CREATE TABLE IF NOT EXISTS outfit_categories (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    normalized_name TEXT NOT NULL UNIQUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
`;

const CREATE_OUTFIT_CATEGORY_INDEX_SQL = `
  CREATE INDEX IF NOT EXISTS idx_outfit_templates_category_id
  ON outfit_templates(category_id)
`;

const INSERT_STARTER_CATEGORIES_SQL = `
  INSERT OR IGNORE INTO outfit_categories (
    id,
    name,
    normalized_name,
    sort_order,
    created_at,
    updated_at
  )
  VALUES
    ('outfit_category_weekend', '周末', '周末', 10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('outfit_category_commute', '通勤', '通勤', 20, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
`;

async function hasCategoryIdColumn(database: MigrationDatabase): Promise<boolean> {
  const resultSet = await database.querySql(OUTFIT_TEMPLATE_TABLE_INFO_SQL);
  try {
    let hasRow = resultSet.goToFirstRow();
    while (hasRow) {
      if (resultSet.getString('name') === 'category_id') {
        return true;
      }
      hasRow = resultSet.goToNextRow();
    }
  } finally {
    resultSet.close();
  }

  return false;
}

export class V10OutfitCategories implements Migration {
  version: number = 10;
  name: string = 'outfit_categories';

  async up(database: MigrationDatabase): Promise<void> {
    await database.executeSql(CREATE_OUTFIT_CATEGORIES_SQL);
    if (!await hasCategoryIdColumn(database)) {
      await database.executeSql('ALTER TABLE outfit_templates ADD COLUMN category_id TEXT');
    }
    await database.executeSql(CREATE_OUTFIT_CATEGORY_INDEX_SQL);
    await database.executeSql(INSERT_STARTER_CATEGORIES_SQL);
  }
}

export const v10OutfitCategories: Migration = new V10OutfitCategories();
