import { Migration, MigrationDatabase } from './Migration';

const CREATE_STORES_SQL = `
  CREATE TABLE IF NOT EXISTS stores (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    district_or_address TEXT,
    note TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
`;

const CREATE_STORE_PHOTOS_SQL = `
  CREATE TABLE IF NOT EXISTS store_photos (
    id TEXT PRIMARY KEY NOT NULL,
    store_id TEXT NOT NULL,
    local_uri TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
  )
`;

const CREATE_STORE_VISITS_SQL = `
  CREATE TABLE IF NOT EXISTS store_visits (
    id TEXT PRIMARY KEY NOT NULL,
    store_id TEXT,
    store_name_snapshot TEXT NOT NULL,
    district_or_address TEXT,
    visit_date TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE SET NULL
  )
`;

const CREATE_STORE_VISIT_PHOTOS_SQL = `
  CREATE TABLE IF NOT EXISTS store_visit_photos (
    id TEXT PRIMARY KEY NOT NULL,
    store_visit_id TEXT NOT NULL,
    local_uri TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (store_visit_id) REFERENCES store_visits(id) ON DELETE CASCADE
  )
`;

const CREATE_USER_PROFILE_SQL = `
  CREATE TABLE IF NOT EXISTS user_profile (
    id TEXT PRIMARY KEY NOT NULL,
    height_cm REAL,
    weight_kg REAL,
    waist_cm REAL,
    updated_at TEXT NOT NULL
  )
`;

const CREATE_TABLE_SQLS: string[] = [
  CREATE_STORES_SQL,
  CREATE_STORE_PHOTOS_SQL,
  CREATE_STORE_VISITS_SQL,
  CREATE_STORE_VISIT_PHOTOS_SQL,
  CREATE_USER_PROFILE_SQL
];

const CREATE_INDEX_SQLS: string[] = [
  'CREATE INDEX IF NOT EXISTS idx_store_visits_visit_date ON store_visits(visit_date)',
  'CREATE INDEX IF NOT EXISTS idx_store_visits_store_id ON store_visits(store_id)',
  'CREATE INDEX IF NOT EXISTS idx_store_photos_store_id ON store_photos(store_id)',
  'CREATE INDEX IF NOT EXISTS idx_store_visit_photos_store_visit_id ON store_visit_photos(store_visit_id)'
];

export class V3StoreVisitSchema implements Migration {
  version: number = 3;
  name: string = 'store_visit_schema';

  async up(database: MigrationDatabase): Promise<void> {
    for (const sql of CREATE_TABLE_SQLS) {
      await database.executeSql(sql);
    }

    for (const sql of CREATE_INDEX_SQLS) {
      await database.executeSql(sql);
    }
  }
}

export const v3StoreVisitSchema: Migration = new V3StoreVisitSchema();
