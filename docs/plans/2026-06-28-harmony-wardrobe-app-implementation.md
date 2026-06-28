# Harmony Wardrobe App Implementation Plan

> **For implementer:** Use TDD throughout. Write failing test first. Watch it fail. Then implement.

**Goal:** Build the first release of a native HarmonyOS ArkTS wardrobe app for daily outfit logging, local wardrobe management, outfit templates, calendar recall, and shopping wishlist records.

**Architecture:** Use a local-only HarmonyOS Stage app with UI, component, domain, data, media, and utility layers. SQLite business tables are the source of truth; the search index is derived and rebuildable; photos are copied into app-local storage and referenced by URI/path.

**Tech Stack:** HarmonyOS ArkTS Stage model, ArkUI, `@ohos.data.relationalStore`, local file APIs, local media picker/camera APIs, SQLite FTS5 with n-gram fallback, unit tests where the HarmonyOS toolchain supports them.

---

## Execution Rules

- Do not add network permissions or remote API dependencies.
- Do not store image blobs in SQLite.
- Do not make UI pages write SQL directly.
- Repository methods must keep business tables and search index consistent through transactions where supported.
- Every task starts unchecked. Only check a task after its verification command or manual verification evidence is complete.
- Delivery is complete only when every task in this plan is checked.

## Task Checklist

- [x] Task 1: Initialize HarmonyOS Stage Project
- [x] Task 2: Add Project Architecture Skeleton
- [x] Task 3: Define Domain Models And Constants
- [x] Task 4: Implement ID, Date, Result, And Text Utilities
- [ ] Task 5: Implement N-Gram Tokenizer Tests And Utility
- [ ] Task 6: Implement SQLite Migration Contract
- [ ] Task 7: Implement Database Provider
- [ ] Task 8: Implement Schema Migration V1
- [ ] Task 9: Implement Search Index Schema And Capability Detection
- [ ] Task 10: Implement Search Document Builder
- [ ] Task 11: Implement Search Repository
- [ ] Task 12: Implement Photo Storage Contract
- [ ] Task 13: Implement Photo Picker Adapter
- [ ] Task 14: Implement Clothing Repository
- [ ] Task 15: Implement Outfit Repository
- [ ] Task 16: Implement Wear Log Repository
- [ ] Task 17: Implement Wishlist Repository
- [ ] Task 18: Implement Repository Integration Tests
- [ ] Task 19: Implement App Navigation Shell
- [ ] Task 20: Implement Shared UI Components
- [ ] Task 21: Implement Wardrobe Page
- [ ] Task 22: Implement Clothing Create/Edit Flow
- [ ] Task 23: Implement Outfits Page
- [ ] Task 24: Implement Outfit Create/Edit Flow
- [ ] Task 25: Implement Today Page
- [ ] Task 26: Implement Wear Log Create/Edit Flow
- [ ] Task 27: Implement Calendar Page
- [ ] Task 28: Implement Shopping Page
- [ ] Task 29: Implement Wishlist Create/Edit Flow
- [ ] Task 30: Implement Unified Search Experience
- [ ] Task 31: Implement Delete And Orphan Cleanup
- [ ] Task 32: Add Empty, Loading, Error, And Disabled States
- [ ] Task 33: Add App Theme And Design Tokens
- [ ] Task 34: Add Manual QA Seed Data Command Or Debug Fixture
- [ ] Task 35: Run Full Verification And Update Delivery Notes

## Task 1: Initialize HarmonyOS Stage Project

**Files:**

- Create: `AppScope/app.json5`
- Create: `entry/src/main/module.json5`
- Create: `entry/src/main/ets/entryability/EntryAbility.ets`
- Create: `entry/src/main/ets/pages/Index.ets`
- Create: `entry/src/main/resources/base/element/string.json`
- Create: `entry/src/main/resources/base/media/app_icon.svg`
- Create: `build-profile.json5`
- Create: `hvigorfile.ts`
- Create: `oh-package.json5`
- Create: `oh_modules/.gitkeep` only if the toolchain requires the directory

**Step 1: Write the failing project validation**

Create `scripts/validate-project-structure.mjs`:

```js
import fs from 'node:fs';

const required = [
  'AppScope/app.json5',
  'entry/src/main/module.json5',
  'entry/src/main/ets/entryability/EntryAbility.ets',
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/resources/base/element/string.json',
  'build-profile.json5',
  'hvigorfile.ts',
  'oh-package.json5'
];

const missing = required.filter((file) => !fs.existsSync(file));
if (missing.length > 0) {
  console.error(`Missing files:\n${missing.map((file) => `- ${file}`).join('\n')}`);
  process.exit(1);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-project-structure.mjs`

Expected: FAIL with missing HarmonyOS project files.

**Step 3: Write minimal implementation**

Create the HarmonyOS Stage project files listed above. Keep the initial page minimal and local-only. `module.json5` must not request network permissions.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-project-structure.mjs`

Expected: PASS with no output and exit code 0.

**Step 5: Commit**

`git add AppScope entry build-profile.json5 hvigorfile.ts oh-package.json5 scripts/validate-project-structure.mjs && git commit -m "chore: initialize HarmonyOS Stage project"`

## Task 2: Add Project Architecture Skeleton

**Files:**

- Create: `entry/src/main/ets/components/.gitkeep`
- Create: `entry/src/main/ets/domain/clothing/.gitkeep`
- Create: `entry/src/main/ets/domain/outfit/.gitkeep`
- Create: `entry/src/main/ets/domain/wearLog/.gitkeep`
- Create: `entry/src/main/ets/domain/wishlist/.gitkeep`
- Create: `entry/src/main/ets/domain/search/.gitkeep`
- Create: `entry/src/main/ets/data/database/.gitkeep`
- Create: `entry/src/main/ets/data/migrations/.gitkeep`
- Create: `entry/src/main/ets/data/repositories/.gitkeep`
- Create: `entry/src/main/ets/data/searchIndex/.gitkeep`
- Create: `entry/src/main/ets/media/.gitkeep`
- Create: `entry/src/main/ets/utils/.gitkeep`
- Create: `docs/architecture.md`

**Step 1: Write the failing architecture validation**

Extend `scripts/validate-project-structure.mjs` with required architecture directories:

```js
const requiredDirs = [
  'entry/src/main/ets/components',
  'entry/src/main/ets/domain/clothing',
  'entry/src/main/ets/domain/outfit',
  'entry/src/main/ets/domain/wearLog',
  'entry/src/main/ets/domain/wishlist',
  'entry/src/main/ets/domain/search',
  'entry/src/main/ets/data/database',
  'entry/src/main/ets/data/migrations',
  'entry/src/main/ets/data/repositories',
  'entry/src/main/ets/data/searchIndex',
  'entry/src/main/ets/media',
  'entry/src/main/ets/utils'
];

const missingDirs = requiredDirs.filter((dir) => !fs.existsSync(dir) || !fs.statSync(dir).isDirectory());
if (missingDirs.length > 0) {
  console.error(`Missing directories:\n${missingDirs.map((dir) => `- ${dir}`).join('\n')}`);
  process.exit(1);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-project-structure.mjs`

Expected: FAIL with missing architecture directories.

**Step 3: Write minimal implementation**

Create directories and `docs/architecture.md` summarizing UI, component, domain, data, media, and utility layers.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-project-structure.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets docs/architecture.md scripts/validate-project-structure.mjs && git commit -m "chore: add app architecture skeleton"`

## Task 3: Define Domain Models And Constants

**Files:**

- Create: `entry/src/main/ets/domain/clothing/ClothingModels.ets`
- Create: `entry/src/main/ets/domain/outfit/OutfitModels.ets`
- Create: `entry/src/main/ets/domain/wearLog/WearLogModels.ets`
- Create: `entry/src/main/ets/domain/wishlist/WishlistModels.ets`
- Create: `entry/src/main/ets/domain/search/SearchModels.ets`
- Create: `entry/src/main/ets/domain/clothing/ClothingCategory.ets`
- Test: `scripts/validate-domain-models.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-domain-models.mjs`:

```js
import fs from 'node:fs';

const checks = [
  ['entry/src/main/ets/domain/clothing/ClothingCategory.ets', ['Top', 'Pants', 'Skirt', 'Outerwear', 'Shoes', 'Bag', 'Accessory', 'Other']],
  ['entry/src/main/ets/domain/clothing/ClothingModels.ets', ['ClothingItem', 'PurchaseInfo']],
  ['entry/src/main/ets/domain/outfit/OutfitModels.ets', ['OutfitTemplate']],
  ['entry/src/main/ets/domain/wearLog/WearLogModels.ets', ['WearLog']],
  ['entry/src/main/ets/domain/wishlist/WishlistModels.ets', ['WishlistItem']],
  ['entry/src/main/ets/domain/search/SearchModels.ets', ['SearchEntityType', 'SearchResult']]
];

for (const [file, needles] of checks) {
  const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  for (const needle of needles) {
    if (!text.includes(needle)) {
      console.error(`${file} missing ${needle}`);
      process.exit(1);
    }
  }
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-domain-models.mjs`

Expected: FAIL because model files do not exist.

**Step 3: Write minimal implementation**

Define ArkTS interfaces/classes for all confirmed objects. Keep fields aligned with the approved design.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-domain-models.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/domain scripts/validate-domain-models.mjs && git commit -m "feat: define wardrobe domain models"`

## Task 4: Implement ID, Date, Result, And Text Utilities

**Files:**

- Create: `entry/src/main/ets/utils/id.ets`
- Create: `entry/src/main/ets/utils/date.ets`
- Create: `entry/src/main/ets/utils/result.ets`
- Create: `entry/src/main/ets/utils/text.ets`
- Test: `scripts/validate-utils.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-utils.mjs` to verify utility exports exist:

```js
import fs from 'node:fs';

const checks = [
  ['entry/src/main/ets/utils/id.ets', ['createId']],
  ['entry/src/main/ets/utils/date.ets', ['toIsoDate', 'toIsoDateTime', 'monthKey']],
  ['entry/src/main/ets/utils/result.ets', ['AppResult', 'ok', 'err']],
  ['entry/src/main/ets/utils/text.ets', ['normalizeSearchText']]
];

for (const [file, needles] of checks) {
  const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  for (const needle of needles) {
    if (!text.includes(needle)) {
      console.error(`${file} missing ${needle}`);
      process.exit(1);
    }
  }
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-utils.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement deterministic helper signatures and simple behavior. `createId(prefix)` should include prefix and timestamp/random suffix. Date helpers should use ISO text. Result helpers should avoid throwing for expected errors.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-utils.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/utils scripts/validate-utils.mjs && git commit -m "feat: add app utility helpers"`

## Task 5: Implement N-Gram Tokenizer Tests And Utility

**Files:**

- Create: `entry/src/main/ets/utils/ngram.ets`
- Test: `scripts/test-ngram.mjs`

**Step 1: Write the failing test**

Create `scripts/test-ngram.mjs`:

```js
import fs from 'node:fs';

const source = fs.readFileSync('entry/src/main/ets/utils/ngram.ets', 'utf8');
if (!source.includes('buildSearchNgrams')) {
  console.error('Missing buildSearchNgrams');
  process.exit(1);
}
if (!source.includes('minGram') || !source.includes('maxGram')) {
  console.error('Tokenizer must support configurable gram sizes');
  process.exit(1);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/test-ngram.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement `buildSearchNgrams(input: string, minGram = 1, maxGram = 3): string[]`. Normalize whitespace, keep Chinese characters, letters, and numbers, and produce unique grams.

**Step 4: Run test — confirm it passes**

Command: `node scripts/test-ngram.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/utils/ngram.ets scripts/test-ngram.mjs && git commit -m "feat: add Chinese-friendly ngram tokenizer"`

## Task 6: Implement SQLite Migration Contract

**Files:**

- Create: `entry/src/main/ets/data/migrations/Migration.ets`
- Create: `entry/src/main/ets/data/migrations/MigrationRunner.ets`
- Test: `scripts/validate-migrations.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-migrations.mjs`:

```js
import fs from 'node:fs';

const migration = fs.readFileSync('entry/src/main/ets/data/migrations/Migration.ets', 'utf8');
const runner = fs.readFileSync('entry/src/main/ets/data/migrations/MigrationRunner.ets', 'utf8');

for (const needle of ['Migration', 'version', 'up']) {
  if (!migration.includes(needle)) throw new Error(`Migration.ets missing ${needle}`);
}
for (const needle of ['MigrationRunner', 'schema_migrations', 'runMigrations']) {
  if (!runner.includes(needle)) throw new Error(`MigrationRunner.ets missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-migrations.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Define a migration interface and runner contract. Runner should create `schema_migrations`, read applied versions, and apply pending migrations in order.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-migrations.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/migrations scripts/validate-migrations.mjs && git commit -m "feat: add database migration contract"`

## Task 7: Implement Database Provider

**Files:**

- Create: `entry/src/main/ets/data/database/DatabaseProvider.ets`
- Create: `entry/src/main/ets/data/database/DatabaseError.ets`
- Test: `scripts/validate-database-provider.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-database-provider.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/database/DatabaseProvider.ets', 'utf8');
for (const needle of ['relationalStore', 'getStore', 'executeSql', 'transaction']) {
  if (!text.includes(needle)) {
    console.error(`DatabaseProvider missing ${needle}`);
    process.exit(1);
  }
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-database-provider.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Wrap `@ohos.data.relationalStore` in a provider that exposes store initialization, SQL execution, and transaction helpers.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-database-provider.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/database scripts/validate-database-provider.mjs && git commit -m "feat: add SQLite database provider"`

## Task 8: Implement Schema Migration V1

**Files:**

- Create: `entry/src/main/ets/data/migrations/V1InitialSchema.ets`
- Test: `scripts/validate-schema-v1.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-schema-v1.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/migrations/V1InitialSchema.ets', 'utf8');
const tables = [
  'clothing_items',
  'clothing_photos',
  'outfit_templates',
  'outfit_photos',
  'outfit_items',
  'wear_logs',
  'wear_log_photos',
  'wishlist_items',
  'wishlist_photos'
];

for (const table of tables) {
  if (!text.includes(`CREATE TABLE`) || !text.includes(table)) {
    console.error(`Missing table ${table}`);
    process.exit(1);
  }
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-schema-v1.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Create V1 migration with all approved business tables, indexes for foreign keys/date/category/store, and no network-related tables.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-schema-v1.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/migrations/V1InitialSchema.ets scripts/validate-schema-v1.mjs && git commit -m "feat: add initial wardrobe SQLite schema"`

## Task 9: Implement Search Index Schema And Capability Detection

**Files:**

- Create: `entry/src/main/ets/data/searchIndex/SearchIndexSchema.ets`
- Create: `entry/src/main/ets/data/searchIndex/SearchCapability.ets`
- Test: `scripts/validate-search-schema.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-search-schema.mjs`:

```js
import fs from 'node:fs';

const schema = fs.readFileSync('entry/src/main/ets/data/searchIndex/SearchIndexSchema.ets', 'utf8');
for (const needle of ['CREATE VIRTUAL TABLE', 'USING fts5', 'search_index_fts', 'ngrams']) {
  if (!schema.includes(needle)) throw new Error(`Search schema missing ${needle}`);
}

const capability = fs.readFileSync('entry/src/main/ets/data/searchIndex/SearchCapability.ets', 'utf8');
for (const needle of ['detectSearchCapability', 'fts5', 'fallback']) {
  if (!capability.includes(needle)) throw new Error(`Search capability missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-search-schema.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Define FTS5 schema and fallback n-gram table schema. Add capability detection that attempts FTS5 setup and returns mode.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-search-schema.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/searchIndex scripts/validate-search-schema.mjs && git commit -m "feat: add search index schema"`

## Task 10: Implement Search Document Builder

**Files:**

- Create: `entry/src/main/ets/domain/search/SearchDocumentBuilder.ets`
- Test: `scripts/validate-search-document-builder.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-search-document-builder.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/domain/search/SearchDocumentBuilder.ets', 'utf8');
for (const needle of ['buildClothingSearchDocument', 'buildOutfitSearchDocument', 'buildWearLogSearchDocument', 'buildWishlistSearchDocument', 'buildSearchNgrams']) {
  if (!text.includes(needle)) throw new Error(`Missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-search-document-builder.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Map domain entities to `SearchDocument` with title, body, category, store name, and n-gram text.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-search-document-builder.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/domain/search/SearchDocumentBuilder.ets scripts/validate-search-document-builder.mjs && git commit -m "feat: build searchable wardrobe documents"`

## Task 11: Implement Search Repository

**Files:**

- Create: `entry/src/main/ets/data/repositories/SearchRepository.ets`
- Test: `scripts/validate-search-repository.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-search-repository.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/repositories/SearchRepository.ets', 'utf8');
for (const needle of ['upsertDocument', 'deleteDocument', 'search', 'rebuildSearchIndex']) {
  if (!text.includes(needle)) throw new Error(`SearchRepository missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-search-repository.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement repository methods for upsert/delete/search/rebuild with FTS5 and fallback modes behind the same interface.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-search-repository.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/repositories/SearchRepository.ets scripts/validate-search-repository.mjs && git commit -m "feat: add search repository"`

## Task 12: Implement Photo Storage Contract

**Files:**

- Create: `entry/src/main/ets/media/PhotoStorage.ets`
- Create: `entry/src/main/ets/media/PhotoModels.ets`
- Test: `scripts/validate-photo-storage.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-photo-storage.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/media/PhotoStorage.ets', 'utf8');
for (const needle of ['copyToAppStorage', 'deleteLocalPhoto', 'photos']) {
  if (!text.includes(needle)) throw new Error(`PhotoStorage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-photo-storage.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Add a photo storage service that copies selected/captured image files into an app-private `photos` folder and returns local URIs. Deletion returns a recoverable result.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-photo-storage.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/media scripts/validate-photo-storage.mjs && git commit -m "feat: add local photo storage service"`

## Task 13: Implement Photo Picker Adapter

**Files:**

- Create: `entry/src/main/ets/media/PhotoPickerAdapter.ets`
- Test: `scripts/validate-photo-picker.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-photo-picker.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/media/PhotoPickerAdapter.ets', 'utf8');
for (const needle of ['pickFromGallery', 'captureFromCamera']) {
  if (!text.includes(needle)) throw new Error(`PhotoPickerAdapter missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-photo-picker.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Wrap HarmonyOS gallery/camera APIs behind `pickFromGallery()` and `captureFromCamera()`. Return selected local temp URIs for `PhotoStorage` to copy.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-photo-picker.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/media/PhotoPickerAdapter.ets scripts/validate-photo-picker.mjs && git commit -m "feat: add photo picker adapter"`

## Task 14: Implement Clothing Repository

**Files:**

- Create: `entry/src/main/ets/data/repositories/ClothingRepository.ets`
- Test: `scripts/validate-clothing-repository.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-clothing-repository.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/repositories/ClothingRepository.ets', 'utf8');
for (const needle of ['createClothing', 'updateClothing', 'deleteClothing', 'listClothing', 'getClothingById', 'SearchRepository']) {
  if (!text.includes(needle)) throw new Error(`ClothingRepository missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-clothing-repository.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement CRUD, photo row persistence, category filtering, name/note search handoff, purchase fields, and search index updates.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-clothing-repository.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/repositories/ClothingRepository.ets scripts/validate-clothing-repository.mjs && git commit -m "feat: add clothing repository"`

## Task 15: Implement Outfit Repository

**Files:**

- Create: `entry/src/main/ets/data/repositories/OutfitRepository.ets`
- Test: `scripts/validate-outfit-repository.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-outfit-repository.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/repositories/OutfitRepository.ets', 'utf8');
for (const needle of ['createOutfit', 'updateOutfit', 'deleteOutfit', 'listOutfits', 'getOutfitById', 'outfit_items', 'SearchRepository']) {
  if (!text.includes(needle)) throw new Error(`OutfitRepository missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-outfit-repository.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement outfit CRUD, clothing relation writes, photo rows, recent wear log loading hook, and search index updates that include clothing names.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-outfit-repository.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/repositories/OutfitRepository.ets scripts/validate-outfit-repository.mjs && git commit -m "feat: add outfit repository"`

## Task 16: Implement Wear Log Repository

**Files:**

- Create: `entry/src/main/ets/data/repositories/WearLogRepository.ets`
- Test: `scripts/validate-wear-log-repository.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-wear-log-repository.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/repositories/WearLogRepository.ets', 'utf8');
for (const needle of ['createWearLog', 'updateWearLog', 'deleteWearLog', 'listWearLogsByDate', 'listWearLogDatesForMonth', 'SearchRepository']) {
  if (!text.includes(needle)) throw new Error(`WearLogRepository missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-wear-log-repository.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement wear log CRUD, date and month queries, photo rows, and search index updates.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-wear-log-repository.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/repositories/WearLogRepository.ets scripts/validate-wear-log-repository.mjs && git commit -m "feat: add wear log repository"`

## Task 17: Implement Wishlist Repository

**Files:**

- Create: `entry/src/main/ets/data/repositories/WishlistRepository.ets`
- Test: `scripts/validate-wishlist-repository.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-wishlist-repository.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/repositories/WishlistRepository.ets', 'utf8');
for (const needle of ['createWishlistItem', 'updateWishlistItem', 'deleteWishlistItem', 'listWishlistItems', 'getWishlistItemById', 'SearchRepository']) {
  if (!text.includes(needle)) throw new Error(`WishlistRepository missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-wishlist-repository.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement wishlist CRUD, photo rows, store/price fields, and search index updates.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-wishlist-repository.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/repositories/WishlistRepository.ets scripts/validate-wishlist-repository.mjs && git commit -m "feat: add wishlist repository"`

## Task 18: Implement Repository Integration Tests

**Files:**

- Create: `scripts/validate-repository-contracts.mjs`
- Modify: repository files as needed

**Step 1: Write the failing test**

Create `scripts/validate-repository-contracts.mjs` to assert repository contracts include transaction usage, search index calls, and no network imports:

```js
import fs from 'node:fs';

const files = [
  'entry/src/main/ets/data/repositories/ClothingRepository.ets',
  'entry/src/main/ets/data/repositories/OutfitRepository.ets',
  'entry/src/main/ets/data/repositories/WearLogRepository.ets',
  'entry/src/main/ets/data/repositories/WishlistRepository.ets'
];

for (const file of files) {
  const text = fs.readFileSync(file, 'utf8');
  if (!text.includes('transaction')) throw new Error(`${file} must use transaction`);
  if (!text.includes('SearchRepository')) throw new Error(`${file} must update search index`);
  if (text.includes('@ohos.net') || text.includes('http')) throw new Error(`${file} must not import network APIs`);
}
```

**Step 2: Run test — confirm it fails or passes according to current code**

Command: `node scripts/validate-repository-contracts.mjs`

Expected: FAIL until repositories meet the contract.

**Step 3: Write minimal implementation**

Adjust repository methods so writes use transaction helpers and search index updates.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-repository-contracts.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/repositories scripts/validate-repository-contracts.mjs && git commit -m "test: verify repository persistence contracts"`

## Task 19: Implement App Navigation Shell

**Files:**

- Modify: `entry/src/main/ets/pages/Index.ets`
- Create: `entry/src/main/ets/pages/TodayPage.ets`
- Create: `entry/src/main/ets/pages/WardrobePage.ets`
- Create: `entry/src/main/ets/pages/OutfitsPage.ets`
- Create: `entry/src/main/ets/pages/CalendarPage.ets`
- Create: `entry/src/main/ets/pages/ShoppingPage.ets`
- Test: `scripts/validate-navigation.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-navigation.mjs`:

```js
import fs from 'node:fs';

const index = fs.readFileSync('entry/src/main/ets/pages/Index.ets', 'utf8');
for (const tab of ['TodayPage', 'WardrobePage', 'OutfitsPage', 'CalendarPage', 'ShoppingPage']) {
  if (!index.includes(tab)) throw new Error(`Index missing ${tab}`);
}
for (const label of ['今日', '衣橱', '套装', '日历', '逛街']) {
  if (!index.includes(label)) throw new Error(`Index missing nav label ${label}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-navigation.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement five-tab bottom navigation with placeholder page components.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-navigation.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages scripts/validate-navigation.mjs && git commit -m "feat: add five-tab app shell"`

## Task 20: Implement Shared UI Components

**Files:**

- Create: `entry/src/main/ets/components/SearchBar.ets`
- Create: `entry/src/main/ets/components/CategoryTabs.ets`
- Create: `entry/src/main/ets/components/PhotoGrid.ets`
- Create: `entry/src/main/ets/components/ClothingCard.ets`
- Create: `entry/src/main/ets/components/OutfitCard.ets`
- Create: `entry/src/main/ets/components/WishlistCard.ets`
- Create: `entry/src/main/ets/components/EmptyState.ets`
- Test: `scripts/validate-components.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-components.mjs`:

```js
import fs from 'node:fs';

const components = ['SearchBar', 'CategoryTabs', 'PhotoGrid', 'ClothingCard', 'OutfitCard', 'WishlistCard', 'EmptyState'];
for (const component of components) {
  const file = `entry/src/main/ets/components/${component}.ets`;
  if (!fs.existsSync(file)) throw new Error(`Missing ${file}`);
  const text = fs.readFileSync(file, 'utf8');
  if (!text.includes('@Component')) throw new Error(`${component} must be an ArkUI component`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-components.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Create reusable ArkUI components with props and stable empty/loading slots where needed.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-components.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/components scripts/validate-components.mjs && git commit -m "feat: add shared wardrobe UI components"`

## Task 21: Implement Wardrobe Page

**Files:**

- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Test: `scripts/validate-wardrobe-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-wardrobe-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WardrobePage.ets', 'utf8');
for (const needle of ['SearchBar', 'CategoryTabs', 'ClothingCard', 'ClothingRepository', '添加衣服']) {
  if (!text.includes(needle)) throw new Error(`WardrobePage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-wardrobe-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement wardrobe list, category filter, search input, empty state, and add button.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-wardrobe-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/WardrobePage.ets scripts/validate-wardrobe-page.mjs && git commit -m "feat: build wardrobe page"`

## Task 22: Implement Clothing Create/Edit Flow

**Files:**

- Create: `entry/src/main/ets/pages/ClothingEditPage.ets`
- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Test: `scripts/validate-clothing-edit-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-clothing-edit-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/ClothingEditPage.ets', 'utf8');
for (const needle of ['PhotoPickerAdapter', 'PhotoStorage', 'ClothingRepository', 'name', 'category', 'purchase']) {
  if (!text.includes(needle)) throw new Error(`ClothingEditPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-clothing-edit-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement create/edit form with photos, name, category, note, optional purchase store/price/date/note, save validation, and disabled saving state.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-clothing-edit-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/ClothingEditPage.ets entry/src/main/ets/pages/WardrobePage.ets scripts/validate-clothing-edit-page.mjs && git commit -m "feat: add clothing edit flow"`

## Task 23: Implement Outfits Page

**Files:**

- Modify: `entry/src/main/ets/pages/OutfitsPage.ets`
- Test: `scripts/validate-outfits-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-outfits-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/OutfitsPage.ets', 'utf8');
for (const needle of ['SearchBar', 'OutfitCard', 'OutfitRepository', '创建套装', '记录一次穿着']) {
  if (!text.includes(needle)) throw new Error(`OutfitsPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-outfits-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement outfit list, search, empty state, add button, and entry to record wear.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-outfits-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/OutfitsPage.ets scripts/validate-outfits-page.mjs && git commit -m "feat: build outfits page"`

## Task 24: Implement Outfit Create/Edit Flow

**Files:**

- Create: `entry/src/main/ets/pages/OutfitEditPage.ets`
- Create: `entry/src/main/ets/components/ClothingPicker.ets`
- Test: `scripts/validate-outfit-edit-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-outfit-edit-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/OutfitEditPage.ets', 'utf8');
for (const needle of ['PhotoPickerAdapter', 'PhotoStorage', 'OutfitRepository', 'ClothingPicker', 'title', 'clothingItemIds']) {
  if (!text.includes(needle)) throw new Error(`OutfitEditPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-outfit-edit-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement outfit form with title, photos, clothing picker, note, validation, and save state.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-outfit-edit-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/OutfitEditPage.ets entry/src/main/ets/components/ClothingPicker.ets scripts/validate-outfit-edit-page.mjs && git commit -m "feat: add outfit edit flow"`

## Task 25: Implement Today Page

**Files:**

- Modify: `entry/src/main/ets/pages/TodayPage.ets`
- Test: `scripts/validate-today-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-today-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/TodayPage.ets', 'utf8');
for (const needle of ['WearLogRepository', 'OutfitRepository', '今天', '选择套装记录今天', '最近套装']) {
  if (!text.includes(needle)) throw new Error(`TodayPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-today-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement today date display, today's wear log state, empty CTA, recent outfits, and recent logs.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-today-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/TodayPage.ets scripts/validate-today-page.mjs && git commit -m "feat: build today outfit page"`

## Task 26: Implement Wear Log Create/Edit Flow

**Files:**

- Create: `entry/src/main/ets/pages/WearLogEditPage.ets`
- Create: `entry/src/main/ets/components/OutfitPicker.ets`
- Test: `scripts/validate-wear-log-edit-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-wear-log-edit-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WearLogEditPage.ets', 'utf8');
for (const needle of ['OutfitPicker', 'PhotoPickerAdapter', 'PhotoStorage', 'WearLogRepository', 'wornDate', 'placeText']) {
  if (!text.includes(needle)) throw new Error(`WearLogEditPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-wear-log-edit-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement wear log form with outfit selection, date, photos, place text, note, validation, and save state.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-wear-log-edit-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/WearLogEditPage.ets entry/src/main/ets/components/OutfitPicker.ets scripts/validate-wear-log-edit-page.mjs && git commit -m "feat: add wear log edit flow"`

## Task 27: Implement Calendar Page

**Files:**

- Modify: `entry/src/main/ets/pages/CalendarPage.ets`
- Create: `entry/src/main/ets/components/MonthCalendar.ets`
- Test: `scripts/validate-calendar-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-calendar-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/CalendarPage.ets', 'utf8');
for (const needle of ['MonthCalendar', 'WearLogRepository', 'listWearLogDatesForMonth', 'listWearLogsByDate', '补录穿着']) {
  if (!text.includes(needle)) throw new Error(`CalendarPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-calendar-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement month grid, date markers, selected date logs, and add/edit entry.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-calendar-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/CalendarPage.ets entry/src/main/ets/components/MonthCalendar.ets scripts/validate-calendar-page.mjs && git commit -m "feat: build wear calendar page"`

## Task 28: Implement Shopping Page

**Files:**

- Modify: `entry/src/main/ets/pages/ShoppingPage.ets`
- Test: `scripts/validate-shopping-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-shopping-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/ShoppingPage.ets', 'utf8');
for (const needle of ['SearchBar', 'WishlistCard', 'WishlistRepository', '心仪单品', '门店']) {
  if (!text.includes(needle)) throw new Error(`ShoppingPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-shopping-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement wishlist list, search, empty state, add button, and item detail navigation.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-shopping-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/ShoppingPage.ets scripts/validate-shopping-page.mjs && git commit -m "feat: build shopping wishlist page"`

## Task 29: Implement Wishlist Create/Edit Flow

**Files:**

- Create: `entry/src/main/ets/pages/WishlistEditPage.ets`
- Test: `scripts/validate-wishlist-edit-page.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-wishlist-edit-page.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/pages/WishlistEditPage.ets', 'utf8');
for (const needle of ['PhotoPickerAdapter', 'PhotoStorage', 'WishlistRepository', 'storeName', 'price', 'title']) {
  if (!text.includes(needle)) throw new Error(`WishlistEditPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-wishlist-edit-page.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement wishlist form with photos, title, store name, price, note, validation, and save state.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-wishlist-edit-page.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages/WishlistEditPage.ets scripts/validate-wishlist-edit-page.mjs && git commit -m "feat: add wishlist edit flow"`

## Task 30: Implement Unified Search Experience

**Files:**

- Create: `entry/src/main/ets/pages/SearchResultsPage.ets`
- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Modify: `entry/src/main/ets/pages/OutfitsPage.ets`
- Modify: `entry/src/main/ets/pages/ShoppingPage.ets`
- Test: `scripts/validate-search-ui.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-search-ui.mjs`:

```js
import fs from 'node:fs';

const resultPage = fs.readFileSync('entry/src/main/ets/pages/SearchResultsPage.ets', 'utf8');
for (const needle of ['SearchRepository', 'entity_type', 'entity_id', 'ClothingRepository', 'OutfitRepository', 'WishlistRepository']) {
  if (!resultPage.includes(needle)) throw new Error(`SearchResultsPage missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-search-ui.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Implement unified search results and connect feature pages' search bars to repository-backed search.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-search-ui.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/pages scripts/validate-search-ui.mjs && git commit -m "feat: add unified wardrobe search"`

## Task 31: Implement Delete And Orphan Cleanup

**Files:**

- Create: `entry/src/main/ets/data/repositories/DeleteCleanupService.ets`
- Modify: repository delete methods
- Test: `scripts/validate-delete-cleanup.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-delete-cleanup.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/data/repositories/DeleteCleanupService.ets', 'utf8');
for (const needle of ['deleteObjectPhotos', 'deleteSearchDocument', 'deleteLocalPhoto', 'orphan']) {
  if (!text.includes(needle)) throw new Error(`DeleteCleanupService missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-delete-cleanup.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Centralize deletion cleanup for photo rows, local files, relation rows, and search documents. Make file deletion failures recoverable.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-delete-cleanup.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/repositories scripts/validate-delete-cleanup.mjs && git commit -m "feat: add delete cleanup service"`

## Task 32: Add Empty, Loading, Error, And Disabled States

**Files:**

- Modify: page and component files
- Test: `scripts/validate-ui-states.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-ui-states.mjs`:

```js
import fs from 'node:fs';

const pages = ['TodayPage', 'WardrobePage', 'OutfitsPage', 'CalendarPage', 'ShoppingPage'];
for (const page of pages) {
  const text = fs.readFileSync(`entry/src/main/ets/pages/${page}.ets`, 'utf8');
  for (const needle of ['loading', 'error', 'EmptyState']) {
    if (!text.includes(needle)) throw new Error(`${page} missing ${needle} state`);
  }
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-ui-states.mjs`

Expected: FAIL until all states are present.

**Step 3: Write minimal implementation**

Add consistent loading, empty, error, disabled save, and retry states across pages and forms.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-ui-states.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets scripts/validate-ui-states.mjs && git commit -m "feat: add app UI states"`

## Task 33: Add App Theme And Design Tokens

**Files:**

- Create: `entry/src/main/ets/theme/Tokens.ets`
- Modify: components and pages
- Test: `scripts/validate-theme.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-theme.mjs`:

```js
import fs from 'node:fs';

const text = fs.readFileSync('entry/src/main/ets/theme/Tokens.ets', 'utf8');
for (const needle of ['primary', 'surface', 'danger', 'radius', 'spacing']) {
  if (!text.includes(needle)) throw new Error(`Tokens missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-theme.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Add teal/blue-green primary token, neutral surface tokens, semantic colors, radius, spacing, and apply them consistently.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-theme.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/theme entry/src/main/ets/components entry/src/main/ets/pages scripts/validate-theme.mjs && git commit -m "style: add wardrobe app theme tokens"`

## Task 34: Add Manual QA Seed Data Command Or Debug Fixture

**Files:**

- Create: `entry/src/main/ets/data/debug/SeedData.ets`
- Create: `docs/qa/manual-test-script.md`
- Test: `scripts/validate-qa-fixture.mjs`

**Step 1: Write the failing test**

Create `scripts/validate-qa-fixture.mjs`:

```js
import fs from 'node:fs';

const seed = fs.readFileSync('entry/src/main/ets/data/debug/SeedData.ets', 'utf8');
for (const needle of ['seedClothing', 'seedOutfits', 'seedWearLogs', 'seedWishlist']) {
  if (!seed.includes(needle)) throw new Error(`SeedData missing ${needle}`);
}

const qa = fs.readFileSync('docs/qa/manual-test-script.md', 'utf8');
for (const needle of ['Today', 'Wardrobe', 'Outfits', 'Calendar', 'Shopping', 'offline']) {
  if (!qa.includes(needle)) throw new Error(`QA script missing ${needle}`);
}
```

**Step 2: Run test — confirm it fails**

Command: `node scripts/validate-qa-fixture.mjs`

Expected: FAIL.

**Step 3: Write minimal implementation**

Add debug-only seed data helpers and a manual QA script that verifies core user flows offline.

**Step 4: Run test — confirm it passes**

Command: `node scripts/validate-qa-fixture.mjs`

Expected: PASS.

**Step 5: Commit**

`git add entry/src/main/ets/data/debug docs/qa/manual-test-script.md scripts/validate-qa-fixture.mjs && git commit -m "test: add wardrobe manual QA fixture"`

## Task 35: Run Full Verification And Update Delivery Notes

**Files:**

- Create: `docs/delivery/first-release-verification.md`
- Modify: `README.md`

**Step 1: Run all local validation scripts**

Command:

```bash
for script in scripts/*.mjs; do node "$script"; done
```

Expected: all scripts pass.

**Step 2: Run HarmonyOS build or documented local equivalent**

Command: use the available HarmonyOS build command for the local setup, for example `hvigorw assembleHap` if the wrapper exists.

Expected: build succeeds, or document missing local toolchain explicitly.

**Step 3: Manual QA**

Run `docs/qa/manual-test-script.md` on emulator/device if available.

Expected: today, wardrobe, outfit, calendar, shopping, photo, search, and offline persistence flows pass.

**Step 4: Update delivery notes**

Write `docs/delivery/first-release-verification.md` with:

- Commit range.
- Validation commands.
- Build result.
- Manual QA result.
- Known limitations.
- FTS5 support result or fallback result.

**Step 5: Commit**

`git add README.md docs/delivery/first-release-verification.md && git commit -m "docs: add first release verification notes"`

---

## Final Delivery Gate

Before declaring implementation complete:

- [ ] Every task checkbox in this plan is checked.
- [ ] Every validation script passes.
- [ ] HarmonyOS build status is documented.
- [ ] Manual QA status is documented.
- [ ] No network permission exists in module configuration.
- [ ] Photos are stored locally, not in SQLite blobs.
- [ ] SQLite business tables are source of truth.
- [ ] Search index can be rebuilt.
- [ ] Known limitations are documented.
