import { Migration, MigrationDatabase } from './Migration';

const OUTFIT_TEMPLATE_TABLE_INFO_SQL = 'PRAGMA table_info(outfit_templates)';

async function columnNames(database: MigrationDatabase): Promise<Set<string>> {
  const resultSet = await database.querySql(OUTFIT_TEMPLATE_TABLE_INFO_SQL);
  const names = new Set<string>();
  try {
    let hasRow = resultSet.goToFirstRow();
    while (hasRow) {
      names.add(resultSet.getString('name'));
      hasRow = resultSet.goToNextRow();
    }
  } finally {
    resultSet.close();
  }
  return names;
}

export class V9OutfitDisplaySource implements Migration {
  version: number = 9;
  name: string = 'outfit_display_source';

  async up(database: MigrationDatabase): Promise<void> {
    const names = await columnNames(database);
    if (!names.has('display_source')) {
      await database.executeSql(
        "ALTER TABLE outfit_templates ADD COLUMN display_source TEXT NOT NULL DEFAULT 'photo'"
      );
    }
  }
}

export const v9OutfitDisplaySource: Migration = new V9OutfitDisplaySource();
