# Harmony Wardrobe App Design

Date: 2026-06-28

## Confirmed Direction

Build a native HarmonyOS personal wardrobe management app for daily outfit planning, outfit history, photo recall, and shopping wish tracking.

The first release is a local-only mobile app:

- Native HarmonyOS app with ArkTS and Stage model.
- Phone portrait first.
- Local SQLite database.
- Photos stored in the app's local sandbox; SQLite stores only local paths or URIs.
- No network access, no account system, no cloud sync, and no remote API.

## Product Scope

The first release uses the "outfit plus shopping recall" direction.

Primary goals:

- Open the app and quickly decide or record what to wear today.
- Maintain a lightweight wardrobe.
- Create reusable outfit templates.
- Record each time an outfit is worn.
- Review outfit history by calendar date.
- Record shopping wish items with store, price, photos, and notes.

Explicit non-goals:

- AI outfit recommendation.
- Weather, location, or map integration.
- Multi-device sync.
- Privacy lock.
- Budget or amount statistics.
- Custom clothing categories.
- Social sharing.
- Network permissions.

## Navigation

The app has five bottom tabs:

1. Today
2. Wardrobe
3. Outfits
4. Calendar
5. Shopping

## Core Screens

### Today

Purpose: Make the current day's outfit the first task.

Content:

- Current date.
- Today's wear log if one exists.
- Empty state with "Select an outfit for today" when no log exists.
- Recent outfit templates.
- Recent wear logs.

Actions:

- Select an outfit.
- Record today's wear.
- Create an outfit.

### Wardrobe

Purpose: Manage clothing items as simple outfit materials.

Content:

- Search field.
- Fixed category filters: top, pants, skirt, outerwear, shoes, bag, accessory, other.
- Clothing grid with photo, name, and category.
- Clothing details.

Create/edit fields:

- Photos.
- Name.
- Category.
- Note.
- Optional purchase information.

### Outfits

Purpose: Manage reusable outfit templates.

Content:

- Search field.
- Outfit grid with cover photo, title, and item count.
- Outfit detail with photos, clothing list, note, and recent wear logs.

Create/edit fields:

- Title.
- Photos.
- Clothing items.
- Note.

Actions:

- Record a wear log from an outfit.

### Calendar

Purpose: Review what was worn on each date.

Content:

- Month view.
- Marker on days with wear logs.
- Date detail with that day's outfit, photos, place text, and notes.

Actions:

- Add or edit a wear log for a selected date.

### Shopping

Purpose: Quickly record wish items while shopping.

Content:

- Search field.
- Wishlist list with photo, title, store, and price.
- Wishlist detail with photos, store, price, and notes.

Create/edit fields:

- Photos.
- Title or description.
- Store name.
- Price.
- Note.

## Core Business Objects

### ClothingItem

Represents one owned clothing item.

Fields:

- id
- name
- category
- photoUris
- note
- optional purchaseInfo
- createdAt
- updatedAt

### PurchaseInfo

Optional purchase details attached to a clothing item.

Fields:

- storeName
- price
- purchaseDate
- note

### OutfitTemplate

Represents one reusable outfit.

Fields:

- id
- title
- photoUris
- clothingItemIds
- note
- createdAt
- updatedAt

### WearLog

Represents one time an outfit was worn.

Fields:

- id
- outfitTemplateId
- wornDate
- photoUris
- placeText
- note
- createdAt
- updatedAt

### WishlistItem

Represents one shopping wish item.

Fields:

- id
- title
- photoUris
- storeName
- price
- note
- createdAt
- updatedAt

## Object Relationships

- One clothing item can belong to many outfit templates.
- One outfit template can have many wear logs.
- A wear log should reference an outfit template.
- A wishlist item is independent from owned clothing.
- If a wishlist item is purchased, the user can manually create a clothing item later.
- Purchase information is optional and does not block clothing creation.

## SQLite Schema

Business tables are the source of truth.

```sql
CREATE TABLE clothing_items (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  note TEXT,
  purchase_store_name TEXT,
  purchase_price INTEGER,
  purchase_date TEXT,
  purchase_note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE clothing_photos (
  id TEXT PRIMARY KEY,
  clothing_id TEXT NOT NULL,
  local_uri TEXT NOT NULL,
  sort_order INTEGER NOT NULL
);

CREATE TABLE outfit_templates (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE outfit_photos (
  id TEXT PRIMARY KEY,
  outfit_id TEXT NOT NULL,
  local_uri TEXT NOT NULL,
  sort_order INTEGER NOT NULL
);

CREATE TABLE outfit_items (
  outfit_id TEXT NOT NULL,
  clothing_id TEXT NOT NULL,
  sort_order INTEGER NOT NULL
);

CREATE TABLE wear_logs (
  id TEXT PRIMARY KEY,
  outfit_id TEXT NOT NULL,
  worn_date TEXT NOT NULL,
  place_text TEXT,
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE wear_log_photos (
  id TEXT PRIMARY KEY,
  wear_log_id TEXT NOT NULL,
  local_uri TEXT NOT NULL,
  sort_order INTEGER NOT NULL
);

CREATE TABLE wishlist_items (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  store_name TEXT,
  price INTEGER,
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE wishlist_photos (
  id TEXT PRIMARY KEY,
  wishlist_id TEXT NOT NULL,
  local_uri TEXT NOT NULL,
  sort_order INTEGER NOT NULL
);
```

Price fields stored as `INTEGER` represent cents; domain models keep decimal prices for UI and business logic.

## Search Design

The first release includes full-text search with Chinese-friendly n-gram support.

Search architecture:

- Business tables remain the source of truth.
- A derived FTS5 table stores searchable documents.
- Chinese n-grams are generated into the searchable document.
- Search returns entity type and entity id, then repositories load full records from business tables.

FTS table:

```sql
CREATE VIRTUAL TABLE search_index_fts USING fts5(
  entity_type UNINDEXED,
  entity_id UNINDEXED,
  title,
  body,
  category,
  store_name,
  ngrams
);
```

Indexed content:

- Clothing: name, category, note, purchase store, purchase note.
- Outfit: title, note, included clothing names.
- Wear log: date, place, note, related outfit title.
- Wishlist item: title, store, price text, note.

Index maintenance:

- Create, update, and delete operations refresh the affected entity's search document.
- `rebuildSearchIndex()` can rebuild the FTS table from business tables.
- If the HarmonyOS SQLite runtime does not support FTS5 in the target environment, keep the repository interface and fall back to a normal n-gram index table.

Chinese search:

- Use n-gram tokens for common Chinese matching.
- Do not implement pinyin search in the first release.
- Do not add a complex Chinese tokenizer in the first release.

## Local Photo Storage

Photos are stored as files in the app sandbox.

Rules:

- Camera or gallery input is copied into app-private storage before saving records.
- SQLite stores only local URI or path strings.
- Deleting a business object deletes photo records and attempts to remove local files.
- File deletion failure must not block business deletion, but should be recorded for retry.
- Pages never manage raw file copying directly; they call the media layer.

## Technical Architecture

### UI Layer

Pages:

- TodayPage
- WardrobePage
- OutfitsPage
- CalendarPage
- ShoppingPage

Responsibilities:

- Render page state.
- Handle user interaction.
- Navigate between pages.
- Display forms and validation messages.

### Component Layer

Reusable components:

- PhotoGrid
- CategoryTabs
- SearchBar
- OutfitCard
- ClothingCard
- WishlistCard
- EmptyState

### Domain Layer

Domains:

- clothing
- outfit
- wearLog
- wishlist
- search

Responsibilities:

- Type definitions.
- Business validation.
- Entity conversion.
- Search document generation.

### Data Layer

Modules:

- database
- migrations
- repositories
- searchIndex

Responsibilities:

- SQLite initialization.
- Schema migration.
- CRUD operations.
- Transactions.
- FTS and n-gram index maintenance.

### Media Layer

Modules:

- photoPicker
- photoStorage

Responsibilities:

- Camera input.
- Gallery input.
- Copy files to app sandbox.
- Delete local photo files.
- Return stable local URIs.

### Utility Layer

Modules:

- id
- date
- text/ngram
- result

## Data Flow

Create clothing:

1. UI collects form data and selected photos.
2. Media layer copies photos into app storage.
3. Repository writes clothing and photo rows in a transaction.
4. Repository updates search index.
5. UI reloads list data.

Create outfit:

1. UI selects clothing items and optional photos.
2. Media layer stores photos.
3. Repository writes outfit, outfit photos, and outfit item relations.
4. Repository updates search index using outfit fields and clothing names.

Record wear log:

1. UI selects outfit and date.
2. Media layer stores wear photos.
3. Repository writes wear log and photo rows.
4. Repository updates search index.
5. Calendar marker updates from wear log query.

Create wishlist item:

1. UI captures or selects photos.
2. Media layer stores photos.
3. Repository writes wishlist rows.
4. Repository updates search index.

Search:

1. UI submits query.
2. Search repository queries FTS table.
3. Search repository returns entity references.
4. Feature repositories load full display models.

## Error Handling

- Required fields show inline validation errors.
- SQLite failures surface as user-readable save/load errors.
- Photo copy failures block save and explain that the image could not be stored.
- Photo deletion failures do not block record deletion.
- Search index failures should be recoverable through index rebuild.
- FTS5 unsupported environments should fall back to the normal n-gram index table through the same search repository interface.

## UX Direction

Product feel:

- Private.
- Clean.
- Lightweight.
- More like a daily outfit journal plus wardrobe recall tool than a productivity dashboard.

Visual principles:

- Photos are the first information layer.
- Text supports recall but should stay short.
- Forms stay short; optional fields are visually secondary.
- Touch targets should be at least 44px.
- Important actions stay near the bottom or as clear floating actions.

Suggested visual system:

- Primary color: calm teal or blue-green.
- Supporting background: warm off-white or light gray.
- Red only for destructive actions.
- Yellow for reminders.
- Green for save success.
- Radius: 8-12px.
- Cards show photos clearly without heavy decoration.
- Calendar marks days with small dots or thumbnails.

Avoid:

- Purple-blue gradient themes.
- Glassmorphism.
- Marketing hero sections.
- Long explanatory text on the home page.
- Heavy statistics in the first release.

## Acceptance Criteria

- The app runs as a native HarmonyOS phone portrait app.
- The app does not require network access.
- Users can create, edit, and delete clothing items.
- Users can add photos from camera or gallery.
- Photos are copied to local app storage.
- SQLite stores local photo paths only.
- Users can create, edit, and delete outfit templates.
- Outfits can reference multiple clothing items.
- Users can select an outfit from Today and record today's wear.
- Wear logs can include date, photos, place text, and note.
- Calendar marks dates with wear logs.
- Users can view wear logs by calendar date.
- Users can create, edit, and delete wishlist items.
- Wishlist items can include photos, store, price, and note.
- Search works for clothing, outfits, and wishlist items.
- Chinese-friendly n-gram search can match common short Chinese terms.
- Data remains after closing and reopening the app.
- Deleting records does not leave visible broken relations.
- Search index can be rebuilt from source tables.

## Risks

### FTS5 Support

HarmonyOS relational storage may vary by runtime version. Validate `CREATE VIRTUAL TABLE ... USING fts5` early. If unsupported, use a normal n-gram index table behind the same search interface.

### Photo Permissions And Sandbox Paths

Camera, gallery, and sandbox file APIs may differ across HarmonyOS versions. Keep all media handling behind the media layer.

### Chinese Search Quality

The first release does not include pinyin or advanced Chinese segmentation. N-gram indexing should be enough for short clothing, outfit, store, and note searches.

### Too Many Top-Level Tabs

Five tabs are justified by the confirmed scope. Keep each tab narrow and consistent to reduce cognitive load.

### Data Entry Burden

Keep clothing fields minimal. Purchase information and notes are optional.

## Confirmed Decisions

- Direction: outfit plus shopping recall.
- Storage: local SQLite.
- Photos: local sandbox files.
- Search: FTS5 plus Chinese n-gram support.
- Network: none.
- Sync: none.
- Main entry: Today.
- Recommendation: manual outfit templates only.
- Photos: clothing photos and wear photos both matter.
- Shopping: wishlist item records.
- Location: manual place or store text only.
- Clothing categories: fixed defaults.
- Price: record only, no statistics.
- Privacy lock: not in first release.
- Platform: native HarmonyOS ArkTS Stage model.
- Device: phone portrait first.
