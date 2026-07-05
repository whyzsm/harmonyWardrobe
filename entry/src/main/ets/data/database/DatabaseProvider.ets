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

function compactSql(sql: string): string {
  return sql.replace(/\s+/g, ' ').trim();
}

function messageWithSql(message: string, sql: string, cause: Error): string {
  if (cause.message.length === 0) {
    return `${message} SQL: ${compactSql(sql)}`;
  }

  return `${message} SQL: ${compactSql(sql)} Cause: ${cause.message}`;
}

function messageWithCause(message: string, cause: Error): string {
  if (cause.message.length === 0) {
    return message;
  }

  return `${message} Cause: ${cause.message}`;
}

function isDatabaseError(error: Error): boolean {
  return error instanceof DatabaseError || error.name === 'DatabaseError';
}

export class DatabaseProvider implements MigrationDatabase {
  private readonly context: common.Context;
  private readonly config: relationalStore.StoreConfig;
  private store?: relationalStore.RdbStore;
  private openStorePromise?: Promise<relationalStore.RdbStore>;

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

    if (this.openStorePromise) {
      return this.openStorePromise;
    }

    this.openStorePromise = this.openStore();
    return this.openStorePromise;
  }

  private async openStore(): Promise<relationalStore.RdbStore> {
    try {
      const store = await relationalStore.getRdbStore(this.context, this.config);
      await store.executeSql(ENABLE_FOREIGN_KEYS_SQL);
      this.store = store;
      return store;
    } catch (error) {
      this.openStorePromise = undefined;
      throw new DatabaseError('Failed to open wardrobe database.', error as Error);
    }
  }

  async executeSql(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<void> {
    const store = await this.getStore();

    try {
      if (bindArgs.length === 0) {
        await store.executeSql(sql);
      } else {
        await store.executeSql(sql, bindArgs);
      }
    } catch (error) {
      const cause = error as Error;
      throw new DatabaseError(messageWithSql('Failed to execute database statement.', sql, cause), cause);
    }
  }

  async querySql(sql: string, bindArgs: MigrationSqlValue[] = []): Promise<MigrationResultSet> {
    const store = await this.getStore();

    try {
      if (bindArgs.length === 0) {
        return new DatabaseResultSet(await store.querySql(sql));
      }

      return new DatabaseResultSet(await store.querySql(sql, bindArgs));
    } catch (error) {
      const cause = error as Error;
      throw new DatabaseError(messageWithSql('Failed to query wardrobe database.', sql, cause), cause);
    }
  }

  async transaction<T>(operation: () => Promise<T>): Promise<T> {
    const store = await this.getStore();
    try {
      store.beginTransaction();
    } catch (error) {
      const cause = error as Error;
      throw new DatabaseError(messageWithCause('Failed to begin database transaction.', cause), cause);
    }

    try {
      const result = await operation();
      try {
        store.commit();
      } catch (error) {
        const cause = error as Error;
        throw new DatabaseError(messageWithCause('Failed to commit database transaction.', cause), cause);
      }
      return result;
    } catch (error) {
      let rollbackCause: Error | undefined;
      try {
        store.rollBack();
      } catch (rollbackError) {
        rollbackCause = rollbackError as Error;
      }

      const cause = error as Error;
      if (isDatabaseError(cause)) {
        const databaseError = cause as DatabaseError;
        throw new DatabaseError(databaseError.message, databaseError.cause, rollbackCause);
      }

      throw new DatabaseError(messageWithCause('Failed to execute database transaction.', cause), cause, rollbackCause);
    }
  }
}

class DatabaseResultSet implements MigrationResultSet {
  private readonly resultSet: relationalStore.ResultSet;

  constructor(resultSet: relationalStore.ResultSet) {
    this.resultSet = resultSet;
  }

  goToFirstRow(): boolean {
    try {
      return this.resultSet.goToFirstRow();
    } catch (error) {
      const cause = error as Error;
      throw new DatabaseError(messageWithCause('Failed to move database result set to first row.', cause), cause);
    }
  }

  goToNextRow(): boolean {
    try {
      return this.resultSet.goToNextRow();
    } catch (error) {
      const cause = error as Error;
      throw new DatabaseError(messageWithCause('Failed to move database result set to next row.', cause), cause);
    }
  }

  getNumber(columnName: string): number {
    try {
      return this.resultSet.getLong(this.resultSet.getColumnIndex(columnName));
    } catch (error) {
      const cause = error as Error;
      throw new DatabaseError(messageWithCause(`Failed to read numeric database column "${columnName}".`, cause), cause);
    }
  }

  getString(columnName: string): string {
    try {
      return this.resultSet.getString(this.resultSet.getColumnIndex(columnName));
    } catch (error) {
      const cause = error as Error;
      throw new DatabaseError(messageWithCause(`Failed to read text database column "${columnName}".`, cause), cause);
    }
  }

  close(): string | undefined {
    try {
      this.resultSet.close();
      return undefined;
    } catch (error) {
      const cause = error as Error;
      return messageWithCause('Failed to close database result set.', cause);
    }
  }
}
