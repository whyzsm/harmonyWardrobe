# 衣不缺个人衣橱改版实施计划

> **For implementer:** Use TDD throughout. Write the failing validation first. Watch it fail. Then implement the smallest change that makes it pass.

**Goal:** Build the first usable `衣不缺` version with `衣橱 / + / 逛店` navigation, `衣裤 / 美搭` wardrobe tabs, store-visit records, and local profile measurements.

**Architecture:** Keep the existing local-first HarmonyOS ArkTS layering. Add new domain/data/page surfaces for `Store`, `StoreVisit`, and `UserProfile`; reuse existing clothing, outfit, photo storage, and validation script patterns. Stop exposing wishlist and recommendation/social concepts in the primary UI, but do not delete old wishlist tables in this pass.

**Tech Stack:** HarmonyOS ArkTS, ArkUI components, local SQLite migrations/repositories, existing `PhotoStorage`, Node.js validation scripts under `scripts/`.

---

## Constraints

- Do not add network permissions or remote APIs.
- Do not store image binaries in SQLite.
- Do not delete old `wishlist_items` or `wishlist_photos` tables in this pass.
- Do not revert unrelated existing worktree changes.
- Use `apply_patch` for manual edits.
- After each task, run the listed validation and commit only files touched by that task.

## Task 1: Add Product-Scope Validation

**Files:**
- Create: `scripts/validate-yibuque-product-scope.mjs`
- Modify only if needed: `README.md`

**Step 1: Write the failing validation**

Create `scripts/validate-yibuque-product-scope.mjs` to assert these product rules:

- `entry/src/main/ets/pages/Index.ets` includes `衣不缺`, `衣橱`, `逛店`, `拍衣服`, `拍搭配`, `拍店铺`.
- `Index.ets` does not include bottom nav labels `首页`, `日历`, `逛街`.
- `entry/src/main/ets/pages/WardrobePage.ets` includes `衣裤` and `美搭`.
- Primary UI files do not expose `心愿单` as a main entry.
- Primary UI files do not expose fake social labels `点赞`, `收藏`, `评论`, `关注` as app-level actions.
- Existing `wishlist` files may still exist, but are not wired in `Index.ets`.

**Step 2: Run test — confirm it fails**

Command:

```bash
node scripts/validate-yibuque-product-scope.mjs
```

Expected: FAIL because current navigation still exposes old app structure.

**Step 3: Minimal implementation**

No UI implementation in this task. Keep the failing test as the scope guard.

**Step 4: Commit**

```bash
git add scripts/validate-yibuque-product-scope.mjs
git commit -m "test: add yibuque product scope guard"
```

## Task 2: Add Store And StoreVisit Domain Contracts

**Files:**
- Create: `entry/src/main/ets/domain/store/StoreModels.ets`
- Create: `scripts/validate-store-domain.mjs`
- Modify: `scripts/validate-domain-models.mjs`

**Step 1: Write the failing validation**

Create `scripts/validate-store-domain.mjs` to require:

- exported `Store` interface
- exported `StoreVisit` interface
- `Store` fields: `id`, `name`, `districtOrAddress`, `photoUris`, `note`, `createdAt`, `updatedAt`
- `StoreVisit` fields: `id`, `storeId`, `storeNameSnapshot`, `visitDate`, `photoUris`, `note`, `createdAt`, `updatedAt`
- no `any` or `unknown`

Update `scripts/validate-domain-models.mjs` to include `Store` and `StoreVisit`.

**Step 2: Run test — confirm it fails**

```bash
node scripts/validate-store-domain.mjs
node scripts/validate-domain-models.mjs
```

Expected: FAIL because `StoreModels.ets` does not exist.

**Step 3: Implement minimal domain model**

Add `StoreModels.ets` with typed interfaces only. Keep it framework-free.

**Step 4: Run test — confirm it passes**

```bash
node scripts/validate-store-domain.mjs
node scripts/validate-domain-models.mjs
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/domain/store/StoreModels.ets scripts/validate-store-domain.mjs scripts/validate-domain-models.mjs
git commit -m "feat: add store visit domain contracts"
```

## Task 3: Add StoreVisit Database Migration

**Files:**
- Create: `entry/src/main/ets/data/migrations/V3StoreVisitSchema.ets`
- Modify: `entry/src/main/ets/app/WardrobeRuntime.ets`
- Create: `scripts/validate-store-visit-migration.mjs`
- Modify: `scripts/validate-runtime-wiring.mjs`

**Step 1: Write the failing validation**

Create `scripts/validate-store-visit-migration.mjs` to require:

- `V3StoreVisitSchema` exists and exports `v3StoreVisitSchema`
- SQL creates `stores`, `store_photos`, `store_visits`, `store_visit_photos`, `user_profile`
- SQL indexes `store_visits.visit_date`, `store_visits.store_id`, `store_photos.store_id`, `store_visit_photos.store_visit_id`
- old wishlist table names are not dropped

Update runtime validation to require `v3StoreVisitSchema` in the migration list.

**Step 2: Run test — confirm it fails**

```bash
node scripts/validate-store-visit-migration.mjs
node scripts/validate-runtime-wiring.mjs
```

Expected: FAIL because the migration is not present or not wired.

**Step 3: Implement migration and runtime wiring**

Add `V3StoreVisitSchema.ets` following the existing `Migration` interface. Include idempotent `CREATE TABLE IF NOT EXISTS` and `CREATE INDEX IF NOT EXISTS`. Wire it after `v2ClothingPurchaseColumns` in `WardrobeRuntime.create`.

**Step 4: Run test — confirm it passes**

```bash
node scripts/validate-store-visit-migration.mjs
node scripts/validate-runtime-wiring.mjs
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/data/migrations/V3StoreVisitSchema.ets entry/src/main/ets/app/WardrobeRuntime.ets scripts/validate-store-visit-migration.mjs scripts/validate-runtime-wiring.mjs
git commit -m "feat: add store visit schema"
```

## Task 4: Add StoreRepository

**Files:**
- Create: `entry/src/main/ets/data/repositories/StoreRepository.ets`
- Modify: `entry/src/main/ets/app/WardrobeRuntime.ets`
- Create: `scripts/validate-store-repository.mjs`
- Modify: `scripts/validate-runtime-wiring.mjs`

**Step 1: Write the failing validation**

Create `scripts/validate-store-repository.mjs` to require:

- exported `StoreRepository`
- input interfaces for create/update store and create/update store visit
- methods: `createStore`, `updateStore`, `listStores`, `getStoreById`, `createStoreVisit`, `updateStoreVisit`, `listStoreVisits`, `getStoreVisitById`, `deleteStoreVisit`
- photo rows are stored in `store_photos` and `store_visit_photos`
- repository does not import `PhotoStorage`
- no `any` or `unknown`

Update runtime wiring validation to require `storeRepository`.

**Step 2: Run test — confirm it fails**

```bash
node scripts/validate-store-repository.mjs
node scripts/validate-runtime-wiring.mjs
```

Expected: FAIL because repository and runtime wiring do not exist.

**Step 3: Implement repository**

Follow existing repository patterns:

- normalize optional text and photo URI arrays
- store prices are not needed in v1
- hydrate photo URI arrays from photo tables
- keep `storeNameSnapshot` on visits so old records remain readable if a store is renamed
- use transactions for create/update/delete

**Step 4: Run test — confirm it passes**

```bash
node scripts/validate-store-repository.mjs
node scripts/validate-runtime-wiring.mjs
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/data/repositories/StoreRepository.ets entry/src/main/ets/app/WardrobeRuntime.ets scripts/validate-store-repository.mjs scripts/validate-runtime-wiring.mjs
git commit -m "feat: add store visit repository"
```

## Task 5: Add UserProfile Domain And Repository

**Files:**
- Create: `entry/src/main/ets/domain/profile/ProfileModels.ets`
- Create: `entry/src/main/ets/data/repositories/ProfileRepository.ets`
- Modify: `entry/src/main/ets/app/WardrobeRuntime.ets`
- Create: `scripts/validate-profile-repository.mjs`
- Modify: `scripts/validate-runtime-wiring.mjs`

**Step 1: Write the failing validation**

Create `scripts/validate-profile-repository.mjs` to require:

- exported `UserProfile`
- fields: `heightCm`, `weightKg`, `waistCm`, `updatedAt`
- exported `ProfileRepository`
- methods: `getProfile`, `saveProfile`
- numeric normalization rejects negative and non-finite values
- uses `user_profile` table

**Step 2: Run test — confirm it fails**

```bash
node scripts/validate-profile-repository.mjs
node scripts/validate-runtime-wiring.mjs
```

Expected: FAIL because profile model/repository are missing.

**Step 3: Implement profile model and repository**

Use a single-row `user_profile` table. Store centimeters/kilograms as decimal numbers unless existing database abstractions require integer conversion. Keep validation in repository-level helpers.

**Step 4: Run test — confirm it passes**

```bash
node scripts/validate-profile-repository.mjs
node scripts/validate-runtime-wiring.mjs
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/domain/profile/ProfileModels.ets entry/src/main/ets/data/repositories/ProfileRepository.ets entry/src/main/ets/app/WardrobeRuntime.ets scripts/validate-profile-repository.mjs scripts/validate-runtime-wiring.mjs
git commit -m "feat: add local profile repository"
```

## Task 6: Rework App Shell Navigation

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Create or modify: `scripts/validate-yibuque-product-scope.mjs`
- Modify: `scripts/validate-runtime-wiring.mjs`

**Step 1: Run failing validation**

```bash
node scripts/validate-yibuque-product-scope.mjs
```

Expected: FAIL from Task 1 until this navigation is implemented.

**Step 2: Implement shell**

Modify `Index.ets`:

- replace bottom labels with `衣橱`, center `+`, `逛店`
- add top bar with logo placeholder, `衣不缺`, and avatar/我的 action
- quick sheet actions: `拍衣服`, `拍搭配`, `拍店铺`
- remove primary navigation to `TodayPage`, `CalendarPage`, and `ShoppingPage`
- route `拍衣服` to clothing editor
- route `拍搭配` to outfit editor
- route `拍店铺` to store visit editor once that page exists; until Task 9, leave a guarded placeholder state that validation can detect

**Step 3: Run test — confirm it passes**

```bash
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-runtime-wiring.mjs
```

Expected: PASS for shell rules.

**Step 4: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets scripts/validate-yibuque-product-scope.mjs scripts/validate-runtime-wiring.mjs
git commit -m "feat: update yibuque app shell"
```

## Task 7: Split Wardrobe Into 衣裤 And 美搭

**Files:**
- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Modify: `entry/src/main/ets/pages/OutfitEditPage.ets`
- Modify: `scripts/validate-wardrobe-page.mjs`
- Create or modify: `scripts/validate-outfit-copy.mjs`

**Step 1: Write failing validation**

Update `scripts/validate-wardrobe-page.mjs` to require:

- `衣裤`
- `美搭`
- selected wardrobe tab state
- clothing category filters under clothing tab
- outfit list under beauty-match tab
- no primary user-facing `套装`

Create or update outfit validation to require UI text `美搭` or `搭配`, and allow photo-only outfits when created from `拍搭配`.

**Step 2: Run test — confirm it fails**

```bash
node scripts/validate-wardrobe-page.mjs
node scripts/validate-outfit-copy.mjs
```

Expected: FAIL because current wardrobe has only clothing list and old outfit copy remains.

**Step 3: Implement wardrobe tabs**

Keep one `WardrobePage` container:

- `selectedWardrobeTab: '衣裤' | '美搭'`
- `衣裤` renders current clothing search/category/list
- `美搭` loads outfits through `OutfitRepository`
- card click opens `OutfitEditPage`
- `OutfitEditPage.canSave()` allows title plus either selected clothing ids or at least one photo
- update empty states to point to `拍衣服` and `拍搭配`

**Step 4: Run test — confirm it passes**

```bash
node scripts/validate-wardrobe-page.mjs
node scripts/validate-outfit-copy.mjs
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/WardrobePage.ets entry/src/main/ets/pages/OutfitEditPage.ets scripts/validate-wardrobe-page.mjs scripts/validate-outfit-copy.mjs
git commit -m "feat: add wardrobe clothing and outfit tabs"
```

## Task 8: Add StoreVisit Edit Page

**Files:**
- Create: `entry/src/main/ets/pages/StoreVisitEditPage.ets`
- Create: `entry/src/main/ets/components/StoreVisitCard.ets`
- Create: `scripts/validate-store-visit-edit-page.mjs`

**Step 1: Write failing validation**

Create validation to require:

- page imports `StoreRepository`, `StoreVisit`, `Store`, `PhotoStorage`, `PhotoViewPicker`
- fields for store name, visit date, note, photos
- save button and cancel action
- photo preview
- create/update flow through `StoreRepository`
- no `WishlistRepository`

**Step 2: Run test — confirm it fails**

```bash
node scripts/validate-store-visit-edit-page.mjs
```

Expected: FAIL because page does not exist.

**Step 3: Implement edit page and card**

Build a minimal form:

- top title: `记录逛店`
- photo selector with one or more photos
- store name input
- visit date picker or text field
- note input
- save creates or updates `StoreVisit`
- if matching store name does not exist, create `Store` before saving the visit

**Step 4: Run test — confirm it passes**

```bash
node scripts/validate-store-visit-edit-page.mjs
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/StoreVisitEditPage.ets entry/src/main/ets/components/StoreVisitCard.ets scripts/validate-store-visit-edit-page.mjs
git commit -m "feat: add store visit editor"
```

## Task 9: Add 逛店 Page And Wire 拍店铺

**Files:**
- Create: `entry/src/main/ets/pages/StoreVisitPage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Create: `scripts/validate-store-visit-page.mjs`
- Modify: `scripts/validate-yibuque-product-scope.mjs`

**Step 1: Write failing validation**

Create validation to require:

- page title `逛店`
- list of store visits
- local search by store name/address/note
- empty state points to `+` and `拍店铺`
- editor wiring with `StoreVisitEditPage`
- `Index.ets` passes `storeRepository` and `photoStorage`

**Step 2: Run test — confirm it fails**

```bash
node scripts/validate-store-visit-page.mjs
node scripts/validate-yibuque-product-scope.mjs
```

Expected: FAIL until page and wiring exist.

**Step 3: Implement page and wiring**

`StoreVisitPage` loads visits through `StoreRepository.listStoreVisits()`. `Index.ets` renders it for the `逛店` nav item and opens `StoreVisitEditPage` for `拍店铺`.

**Step 4: Run test — confirm it passes**

```bash
node scripts/validate-store-visit-page.mjs
node scripts/validate-yibuque-product-scope.mjs
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/StoreVisitPage.ets entry/src/main/ets/pages/Index.ets scripts/validate-store-visit-page.mjs scripts/validate-yibuque-product-scope.mjs
git commit -m "feat: wire store visit page"
```

## Task 10: Add Profile Page

**Files:**
- Create: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Create: `scripts/validate-profile-page.mjs`

**Step 1: Write failing validation**

Create validation to require:

- page title `我的`
- fields `身高`, `体重`, `腰围`
- `设置` entry
- uses `ProfileRepository`
- save and cancel actions
- `Index.ets` opens profile from avatar

**Step 2: Run test — confirm it fails**

```bash
node scripts/validate-profile-page.mjs
```

Expected: FAIL because page is not present.

**Step 3: Implement profile page**

Load existing profile on appear. Save normalized measurements through `ProfileRepository.saveProfile()`. Show validation messages next to invalid fields.

**Step 4: Run test — confirm it passes**

```bash
node scripts/validate-profile-page.mjs
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/ProfilePage.ets entry/src/main/ets/pages/Index.ets scripts/validate-profile-page.mjs
git commit -m "feat: add profile measurements page"
```

## Task 11: Clean Up Old Primary UI Concepts

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/SearchResultsPage.ets`
- Modify: `entry/src/main/ets/pages/TodayPage.ets` only if still reachable
- Modify: `scripts/validate-yibuque-product-scope.mjs`
- Modify: search validation scripts as needed

**Step 1: Run failing validation**

```bash
node scripts/validate-yibuque-product-scope.mjs
```

Expected: FAIL if old user-facing primary copy remains.

**Step 2: Implement cleanup**

- remove fake social details from reachable UI
- remove `首页`, `日历`, `逛街`, `心愿单`, and primary `套装` copy from primary navigation surfaces
- update search result copy to user-facing names: `衣物`, `美搭`, `逛店记录`, `店铺`
- keep old files only if no longer reachable or needed for compatibility

**Step 3: Run test — confirm it passes**

```bash
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-search-document-builder.mjs
node scripts/validate-search-repository.mjs
```

Expected: PASS.

**Step 4: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets entry/src/main/ets/pages/SearchResultsPage.ets entry/src/main/ets/pages/TodayPage.ets scripts/validate-yibuque-product-scope.mjs scripts/validate-search-document-builder.mjs scripts/validate-search-repository.mjs
git commit -m "chore: remove old primary ui concepts"
```

## Task 12: Full Verification And Manual QA Notes

**Files:**
- Modify: `docs/qa/manual-test-script.md`
- Modify: `docs/delivery/first-release-verification.md` if release notes are maintained during this pass

**Step 1: Update manual QA script**

Add coverage for:

- app launch shows `衣不缺`
- main nav has `衣橱 / + / 逛店`
- wardrobe `衣裤 / 美搭` tab switching
- `拍衣服`
- `拍搭配`
- `拍店铺`
- create/edit store visit
- profile measurements save/reload

**Step 2: Run full validation**

```bash
for script in scripts/validate-*.mjs; do node "$script" || exit 1; done
git diff --check
```

Expected: PASS.

**Step 3: Commit**

```bash
git add docs/qa/manual-test-script.md docs/delivery/first-release-verification.md
git commit -m "docs: update yibuque qa coverage"
```

## Execution Notes

- If a task touches a file that already has user changes, inspect the diff before editing and preserve unrelated changes.
- If `SearchEntityType.Wishlist` remains in code for old data compatibility, ensure it is not exposed as a primary UI entry.
- If full renaming of `OutfitTemplate` to `Look` becomes tempting, defer it. UI text changes are enough for v1.
- If true camera capture requires additional platform permission or breaks the current gallery-only flow, keep using photo picker for v1 and label the action as `拍/选`.
