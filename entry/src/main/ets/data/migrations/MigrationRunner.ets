import { Migration, MigrationDatabase } from './Migration';

const CREATE_SCHEMA_MIGRATIONS_SQL = `
  CREATE TABLE IF NOT EXISTS schema_migrations (
    version INTEGER PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    applied_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
  )
`;

const SELECT_APPLIED_MIGRATIONS_SQL = `
  SELECT version
  FROM schema_migrations
  ORDER BY version ASC
`;

const INSERT_SCHEMA_MIGRATION_SQL = `
  INSERT INTO schema_migrations (version, name)
  VALUES (?, ?)
`;

export class MigrationRunner {
  private readonly database: MigrationDatabase;
  private readonly migrations: Migration[];

  constructor(database: MigrationDatabase, migrations: Migration[]) {
    this.database = database;
    this.migrations = this.validateAndSortMigrations(migrations);
  }

  async runMigrations(): Promise<void> {
    await this.ensureSchemaMigrationsTable();

    const appliedVersions = await this.readAppliedVersions();
    for (const migration of this.migrations) {
      if (appliedVersions.has(migration.version)) {
        continue;
      }

      await this.database.transaction(async () => {
        await migration.up(this.database);
        await this.recordMigration(migration);
      });
      appliedVersions.add(migration.version);
    }
  }

  private validateAndSortMigrations(migrations: Migration[]): Migration[] {
    const seenVersions = new Set<number>();

    for (const migration of migrations) {
      if (!Number.isSafeInteger(migration.version) || migration.version < 1) {
        throw new Error(`Invalid migration version: ${migration.version}`);
      }

      if (seenVersions.has(migration.version)) {
        throw new Error(`Duplicate migration version: ${migration.version}`);
      }

      seenVersions.add(migration.version);
    }

    return migrations.slice().sort((left, right) => left.version - right.version);
  }

  private async ensureSchemaMigrationsTable(): Promise<void> {
    await this.database.executeSql(CREATE_SCHEMA_MIGRATIONS_SQL);
  }

  private async readAppliedVersions(): Promise<Set<number>> {
    const versions = new Set<number>();
    const resultSet = await this.database.querySql(SELECT_APPLIED_MIGRATIONS_SQL);

    try {
      let hasRow = resultSet.goToFirstRow();
      while (hasRow) {
        versions.add(resultSet.getNumber('version'));
        hasRow = resultSet.goToNextRow();
      }
    } finally {
      resultSet.close();
    }

    return versions;
  }

  private async recordMigration(migration: Migration): Promise<void> {
    await this.database.executeSql(INSERT_SCHEMA_MIGRATION_SQL, [
      migration.version,
      migration.name ?? `migration_${migration.version}`
    ]);
  }
}
