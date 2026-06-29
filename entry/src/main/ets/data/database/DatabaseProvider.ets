import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';
import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { DatabaseError } from './DatabaseError';

const DATABASE_NAME = 'harmony_wardrobe.db';

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
    store.beginTransaction();

    try {
      const result = await operation();
      store.commit();
      return result;
    } catch (error) {
      store.rollBack();
      throw error;
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
