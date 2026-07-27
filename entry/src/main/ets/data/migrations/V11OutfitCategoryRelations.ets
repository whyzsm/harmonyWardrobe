import { Migration, MigrationDatabase } from './Migration';

const CREATE_OUTFIT_CATEGORY_RELATIONS_SQL = `
  CREATE TABLE IF NOT EXISTS outfit_template_categories (
    outfit_id TEXT NOT NULL,
    category_id TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (outfit_id, category_id),
    FOREIGN KEY (outfit_id) REFERENCES outfit_templates(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES outfit_categories(id) ON DELETE CASCADE
  )
`;

const CREATE_OUTFIT_CATEGORY_RELATION_INDEX_SQL = `
  CREATE INDEX IF NOT EXISTS idx_outfit_template_categories_category_id
  ON outfit_template_categories(category_id)
`;

const BACKFILL_OUTFIT_CATEGORY_RELATIONS_SQL = `
  INSERT OR IGNORE INTO outfit_template_categories (
    outfit_id,
    category_id,
    sort_order
  )
  SELECT
    outfits.id,
    outfits.category_id,
    0
  FROM outfit_templates AS outfits
  INNER JOIN outfit_categories AS categories ON categories.id = outfits.category_id
  WHERE outfits.category_id IS NOT NULL
`;

export class V11OutfitCategoryRelations implements Migration {
  version: number = 11;
  name: string = 'outfit_category_relations';

  async up(database: MigrationDatabase): Promise<void> {
    await database.executeSql(CREATE_OUTFIT_CATEGORY_RELATIONS_SQL);
    await database.executeSql(CREATE_OUTFIT_CATEGORY_RELATION_INDEX_SQL);
    await database.executeSql(BACKFILL_OUTFIT_CATEGORY_RELATIONS_SQL);
  }
}

export const v11OutfitCategoryRelations: Migration = new V11OutfitCategoryRelations();
