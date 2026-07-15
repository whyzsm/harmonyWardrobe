export type MigrationSqlValue = string | number | boolean | null;

export interface MigrationValuesBucket {
  [key: string]: MigrationSqlValue;
}

export interface MigrationResultSet {
  goToFirstRow(): boolean;
  goToNextRow(): boolean;
  getNumber(columnName: string): number;
  getString(columnName: string): string;
  close(): string | undefined;
}

export interface MigrationDatabase {
  executeSql(sql: string, bindArgs?: MigrationSqlValue[]): Promise<void>;
  insert(table: string, values: MigrationValuesBucket): Promise<number>;
  querySql(sql: string, bindArgs?: MigrationSqlValue[]): Promise<MigrationResultSet>;
  transaction<T>(operation: () => Promise<T>): Promise<T>;
}

export interface Migration {
  version: number;
  name?: string;
  up(database: MigrationDatabase): Promise<void>;
}
