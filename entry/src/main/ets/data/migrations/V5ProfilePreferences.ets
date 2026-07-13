import { Migration, MigrationDatabase } from './Migration';

const PROFILE_TABLE_INFO_SQL = 'PRAGMA table_info(user_profile)';

interface ProfileColumnPatch {
  name: string;
  sql: string;
}

const PROFILE_COLUMNS: ProfileColumnPatch[] = [
  { name: 'fitting_preference_enabled', sql: 'ALTER TABLE user_profile ADD COLUMN fitting_preference_enabled INTEGER NOT NULL DEFAULT 0' },
  { name: 'style_tags', sql: 'ALTER TABLE user_profile ADD COLUMN style_tags TEXT NOT NULL DEFAULT \'[]\'' },
  { name: 'frequent_districts', sql: 'ALTER TABLE user_profile ADD COLUMN frequent_districts TEXT NOT NULL DEFAULT \'[]\'' },
  { name: 'monthly_budget', sql: 'ALTER TABLE user_profile ADD COLUMN monthly_budget REAL' },
  { name: 'privacy_mode_enabled', sql: 'ALTER TABLE user_profile ADD COLUMN privacy_mode_enabled INTEGER NOT NULL DEFAULT 0' }
];

async function columnNames(database: MigrationDatabase): Promise<Set<string>> {
  const resultSet = await database.querySql(PROFILE_TABLE_INFO_SQL);
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

export class V5ProfilePreferences implements Migration {
  version: number = 5;
  name: string = 'profile_preferences';

  async up(database: MigrationDatabase): Promise<void> {
    const names = await columnNames(database);
    for (const column of PROFILE_COLUMNS) {
      if (!names.has(column.name)) {
        await database.executeSql(column.sql);
      }
    }
  }
}

export const v5ProfilePreferences: Migration = new V5ProfilePreferences();
