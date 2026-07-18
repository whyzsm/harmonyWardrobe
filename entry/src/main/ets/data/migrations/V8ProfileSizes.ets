import { Migration, MigrationDatabase } from './Migration';

const PROFILE_TABLE_INFO_SQL = 'PRAGMA table_info(user_profile)';

const PROFILE_SIZE_COLUMNS: string[] = [
  'upper_size',
  'lower_size',
  'shoe_size'
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

export class V8ProfileSizes implements Migration {
  version: number = 8;
  name: string = 'profile_sizes';

  async up(database: MigrationDatabase): Promise<void> {
    const names = await columnNames(database);
    for (const column of PROFILE_SIZE_COLUMNS) {
      if (!names.has(column)) {
        await database.executeSql(`ALTER TABLE user_profile ADD COLUMN ${column} TEXT`);
      }
    }
  }
}

export const v8ProfileSizes: Migration = new V8ProfileSizes();
