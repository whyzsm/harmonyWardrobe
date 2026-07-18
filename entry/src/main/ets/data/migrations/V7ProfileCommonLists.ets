import { Migration, MigrationDatabase } from './Migration';

const PROFILE_TABLE_INFO_SQL = 'PRAGMA table_info(user_profile)';
const ADD_COMMON_BUDGETS_SQL = "ALTER TABLE user_profile ADD COLUMN common_budgets TEXT NOT NULL DEFAULT '[2400,3200,4000]'";

async function hasCommonBudgetsColumn(database: MigrationDatabase): Promise<boolean> {
  const resultSet = await database.querySql(PROFILE_TABLE_INFO_SQL);
  try {
    let hasRow = resultSet.goToFirstRow();
    while (hasRow) {
      if (resultSet.getString('name') === 'common_budgets') {
        return true;
      }
      hasRow = resultSet.goToNextRow();
    }
  } finally {
    resultSet.close();
  }
  return false;
}

export class V7ProfileCommonLists implements Migration {
  version: number = 7;
  name: string = 'profile_common_lists';

  async up(database: MigrationDatabase): Promise<void> {
    if (!await hasCommonBudgetsColumn(database)) {
      await database.executeSql(ADD_COMMON_BUDGETS_SQL);
    }
  }
}

export const v7ProfileCommonLists: Migration = new V7ProfileCommonLists();
