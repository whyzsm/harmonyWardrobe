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
    this.migrations = migrations.slice().sort((left, right) => left.version - right.version);
  }

  async runMigrations(): Promise<void> {
    await this.ensureSchemaMigrationsTable();

    const appliedVersions = await this.readAppliedVersions();
    for (const migration of this.migrations) {
      if (appliedVersions.has(migration.version)) {
        continue;
      }

      await migration.up(this.database);
      await this.recordMigration(migration);
      appliedVersions.add(migration.version);
    }
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
