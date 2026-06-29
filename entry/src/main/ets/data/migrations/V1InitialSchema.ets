import { Migration, MigrationDatabase } from './Migration';

const ENABLE_FOREIGN_KEYS_SQL = 'PRAGMA foreign_keys = ON';

const CREATE_CLOTHING_ITEMS_SQL = `
  CREATE TABLE IF NOT EXISTS clothing_items (
    id TEXT PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    note TEXT,
    purchase_store_name TEXT,
    purchase_price REAL,
    purchase_date TEXT,
    purchase_note TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
`;

const CREATE_CLOTHING_PHOTOS_SQL = `
  CREATE TABLE IF NOT EXISTS clothing_photos (
    id TEXT PRIMARY KEY NOT NULL,
    clothing_id TEXT NOT NULL,
    local_uri TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (clothing_id) REFERENCES clothing_items(id) ON DELETE CASCADE
  )
`;

const CREATE_OUTFIT_TEMPLATES_SQL = `
  CREATE TABLE IF NOT EXISTS outfit_templates (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL,
    note TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
`;

const CREATE_OUTFIT_PHOTOS_SQL = `
  CREATE TABLE IF NOT EXISTS outfit_photos (
    id TEXT PRIMARY KEY NOT NULL,
    outfit_id TEXT NOT NULL,
    local_uri TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (outfit_id) REFERENCES outfit_templates(id) ON DELETE CASCADE
  )
`;

const CREATE_OUTFIT_ITEMS_SQL = `
  CREATE TABLE IF NOT EXISTS outfit_items (
    outfit_id TEXT NOT NULL,
    clothing_id TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (outfit_id, clothing_id),
    FOREIGN KEY (outfit_id) REFERENCES outfit_templates(id) ON DELETE CASCADE,
    FOREIGN KEY (clothing_id) REFERENCES clothing_items(id) ON DELETE CASCADE
  )
`;

const CREATE_WEAR_LOGS_SQL = `
  CREATE TABLE IF NOT EXISTS wear_logs (
    id TEXT PRIMARY KEY NOT NULL,
    outfit_id TEXT NOT NULL,
    outfit_title_snapshot TEXT NOT NULL,
    clothing_item_ids_snapshot TEXT NOT NULL,
    worn_date TEXT NOT NULL,
    place_text TEXT,
    note TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (outfit_id) REFERENCES outfit_templates(id) ON DELETE RESTRICT
  )
`;

const CREATE_WEAR_LOG_PHOTOS_SQL = `
  CREATE TABLE IF NOT EXISTS wear_log_photos (
    id TEXT PRIMARY KEY NOT NULL,
    wear_log_id TEXT NOT NULL,
    local_uri TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (wear_log_id) REFERENCES wear_logs(id) ON DELETE CASCADE
  )
`;

const CREATE_WISHLIST_ITEMS_SQL = `
  CREATE TABLE IF NOT EXISTS wishlist_items (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL,
    store_name TEXT,
    price REAL,
    note TEXT,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  )
`;

const CREATE_WISHLIST_PHOTOS_SQL = `
  CREATE TABLE IF NOT EXISTS wishlist_photos (
    id TEXT PRIMARY KEY NOT NULL,
    wishlist_id TEXT NOT NULL,
    local_uri TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (wishlist_id) REFERENCES wishlist_items(id) ON DELETE CASCADE
  )
`;

const CREATE_INDEX_SQLS: string[] = [
  'CREATE INDEX IF NOT EXISTS idx_clothing_items_category ON clothing_items(category)',
  'CREATE INDEX IF NOT EXISTS idx_clothing_items_store_name ON clothing_items(purchase_store_name)',
  'CREATE INDEX IF NOT EXISTS idx_clothing_items_purchase_date ON clothing_items(purchase_date)',
  'CREATE INDEX IF NOT EXISTS idx_clothing_photos_clothing_id ON clothing_photos(clothing_id)',
  'CREATE INDEX IF NOT EXISTS idx_outfit_photos_outfit_id ON outfit_photos(outfit_id)',
  'CREATE INDEX IF NOT EXISTS idx_outfit_items_clothing_id ON outfit_items(clothing_id)',
  'CREATE INDEX IF NOT EXISTS idx_wear_logs_outfit_id ON wear_logs(outfit_id)',
  'CREATE INDEX IF NOT EXISTS idx_wear_logs_worn_date ON wear_logs(worn_date)',
  'CREATE INDEX IF NOT EXISTS idx_wear_log_photos_wear_log_id ON wear_log_photos(wear_log_id)',
  'CREATE INDEX IF NOT EXISTS idx_wishlist_items_store_name ON wishlist_items(store_name)',
  'CREATE INDEX IF NOT EXISTS idx_wishlist_photos_wishlist_id ON wishlist_photos(wishlist_id)'
];

const CREATE_TABLE_SQLS: string[] = [
  CREATE_CLOTHING_ITEMS_SQL,
  CREATE_CLOTHING_PHOTOS_SQL,
  CREATE_OUTFIT_TEMPLATES_SQL,
  CREATE_OUTFIT_PHOTOS_SQL,
  CREATE_OUTFIT_ITEMS_SQL,
  CREATE_WEAR_LOGS_SQL,
  CREATE_WEAR_LOG_PHOTOS_SQL,
  CREATE_WISHLIST_ITEMS_SQL,
  CREATE_WISHLIST_PHOTOS_SQL
];

export class V1InitialSchema implements Migration {
  version: number = 1;
  name: string = 'initial_schema';

  async up(database: MigrationDatabase): Promise<void> {
    await database.executeSql(ENABLE_FOREIGN_KEYS_SQL);

    for (const sql of CREATE_TABLE_SQLS) {
      await database.executeSql(sql);
    }

    for (const sql of CREATE_INDEX_SQLS) {
      await database.executeSql(sql);
    }
  }
}

export const v1InitialSchema: Migration = new V1InitialSchema();
