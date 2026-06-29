import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { DatabaseError } from './DatabaseError';

const DATABASE_NAME = 'harmony_wardrobe.db';
const ENABLE_FOREIGN_KEYS_SQL = 'PRAGMA foreign_keys = ON';

export class DatabaseProvider implements MigrationDatabase {
  private readonly context: common.Context;
  private readonly config: relationalStore.StoreConfig;
  private store?: relationalStore.RdbStore;

  constructor(context: common.Context, databaseName: string = DATABASE_NAME) {
    this.context = context;
    this.config = {
      name: databaseName,
      securityLevel: relationalStore.SecurityLevel.S1
    };
  }

  async getStore(): Promise<relationalStore.RdbStore> {
    if (this.store) {
      return this.store;
    }

    try {
      this.store = await relationalStore.getRdbStore(this.context, this.config);
      await this.store.executeSql(ENABLE_FOREIGN_KEYS_SQL);
      return this.store;
    } catch (error) {
      throw new DatabaseError('Failed to open wardrobe database.', error as Error);
    }
  }

  async executeSql(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<void> {
    const store = await this.getStore();

    try {
      await store.executeSql(sql, bindArgs);
    } catch (error) {
      throw new DatabaseError('Failed to execute database statement.', error as Error);
    }
  }

  async querySql(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<MigrationResultSet> {
    const store = await this.getStore();

    try {
      return new DatabaseResultSet(await store.querySql(sql, bindArgs));
    } catch (error) {
      throw new DatabaseError('Failed to query wardrobe database.', error as Error);
    }
  }

  async transaction<T>(operation: () => Promise<T>): Promise<T> {
    const store = await this.getStore();
    try {
      store.beginTransaction();
    } catch (error) {
      throw new DatabaseError('Failed to begin database transaction.', error as Error);
    }

    try {
      const result = await operation();
      try {
        store.commit();
      } catch (error) {
        throw new DatabaseError('Failed to commit database transaction.', error as Error);
      }
      return result;
    } catch (error) {
      let rollbackCause: Error | undefined;
      try {
        store.rollBack();
      } catch (rollbackError) {
        rollbackCause = rollbackError as Error;
      }

      if (error instanceof DatabaseError) {
        throw new DatabaseError(error.message, error.cause, rollbackCause);
      }

      throw new DatabaseError('Failed to execute database transaction.', error as Error, rollbackCause);
    }
  }
}

class DatabaseResultSet implements MigrationResultSet {
  private readonly resultSet: relationalStore.ResultSet;

  constructor(resultSet: relationalStore.ResultSet) {
    this.resultSet = resultSet;
  }

  goToFirstRow(): boolean {
    return this.resultSet.goToFirstRow();
  }

  goToNextRow(): boolean {
    return this.resultSet.goToNextRow();
  }

  getNumber(columnName: string): number {
    return this.resultSet.getLong(this.resultSet.getColumnIndex(columnName));
  }

  close(): void {
    this.resultSet.close();
  }
}
