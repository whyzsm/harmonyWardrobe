export type MigrationSqlValue = string | number | boolean | null;

export interface MigrationResultSet {
  goToFirstRow(): boolean;
  goToNextRow(): boolean;
  getNumber(columnName: string): number;
  close(): void;
}

export interface MigrationDatabase {
  executeSql(sql: string, bindArgs?: MigrationSqlValue[]): Promise<void>;
  querySql(sql: string, bindArgs?: MigrationSqlValue[]): Promise<MigrationResultSet>;
}

export interface Migration {
  version: number;
  name?: string;
  up(database: MigrationDatabase): Promise<void>;
}
