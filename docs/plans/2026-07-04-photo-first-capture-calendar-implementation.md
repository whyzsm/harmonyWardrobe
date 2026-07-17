# Photo First Capture Calendar Implementation Plan

> **For implementer:** Use validation-first throughout. Write or update a failing validation first. Confirm it fails. Then implement the smallest change that makes it pass.

**Goal:** Build a photo-first capture flow for `衣橱 / 美搭 / 店铺`, make `拍美搭` and `拍店铺` persist reliably, and add a `日历` tab inside the wardrobe for daily outfit records.

**Architecture:** Keep the existing HarmonyOS ArkTS app, local SQLite repositories, `PhotoPickerAdapter`, `PhotoStorage`, and Yibuque tokens. Replace the current business-first quick sheet with a photo-source sheet, route selected photos into one `CaptureEditPage`, and save through existing repositories. Reuse `WearLogRepository` for the wardrobe calendar, but relax its API so a daily wear log can be photo-and-note-first without requiring an outfit.

**Tech Stack:** ArkTS / ArkUI, HarmonyOS photo picker and camera picker, local SQLite migrations/repositories, Node validation scripts.

---

## Current Constraints

- Work on `master`.
- Do not stage `.idea/`.
- The current working tree may contain an unrelated local edit in `entry/src/main/ets/pages/WardrobePage.ets`; inspect before editing and preserve user changes.
- Keep bottom main navigation as `衣橱 / camera / 逛店`; do not restore bottom `日历`.
- Do not add network APIs, login, cloud sync, or image BLOB storage.
- UI must use existing Yibuque tokens and black capsule primary actions.

## Task 1: Add Photo-First Capture Validation

**Files:**

- Create: `scripts/validate-photo-first-capture-flow.mjs`
- Create: `scripts/validate-capture-edit-page.mjs`
- Create: `scripts/validate-wardrobe-calendar-tab.mjs`
- Modify: `scripts/validate-navigation.mjs`
- Modify: `scripts/validate-store-visit-edit-page.mjs`
- Modify: `scripts/validate-wear-log-repository.mjs`

**Step 1: Write failing validations**

`scripts/validate-photo-first-capture-flow.mjs` must assert:

- `entry/src/main/ets/components/BottomNavigationBar.ets` contains `onOpenCapture` and no longer exposes `onOpenQuickActions`.
- The center button uses camera/photo semantics (`相机`, `拍照`, or an icon builder name such as `CameraIcon`) rather than a literal `Text('+')`.
- `entry/src/main/ets/components/QuickCaptureSheet.ets` contains `拍照` and `从相册选择`.
- `QuickCaptureSheet.ets` does not contain `拍衣服`, `拍搭配`, or `拍店铺`.
- `entry/src/main/ets/pages/Index.ets` imports `CaptureEditPage`.
- `Index.ets` calls `photoPickerAdapter.captureFromCamera`, `photoPickerAdapter.pickFromGallery`, and `photoStorage.copyToAppStorage` before opening `CaptureEditPage`.
- `Index.ets` routes save completion back to `衣橱` for wardrobe/outfit saves and `逛店` for store saves.

`scripts/validate-capture-edit-page.mjs` must assert:

- `entry/src/main/ets/pages/CaptureEditPage.ets` exists.
- It contains `衣橱`, `美搭`, `店铺`.
- It contains `小记`, `TextArea`, `photoUris`, `capturedAt`, `captureDate`.
- It imports and uses `ClothingRepository`, `OutfitRepository`, `StoreRepository`, `WearLogRepository`, `ClothingPicker`, `PhotoGrid`.
- It calls `createClothing`, `createOutfit`, `createStoreVisit`, and `createWearLog`.
- It has generated-name helpers for wardrobe, outfit, and store saves.
- It gates save on photo presence only, not on title/store/category fields.
- It uses `YibuqueColor.actionBlack` and does not use `AppTheme.color.primary`.

`scripts/validate-wardrobe-calendar-tab.mjs` must assert:

- `WardrobePage.ets` imports `WearLogRepository`, `WearLog`, `MonthCalendar`, and `WearLogEditPage` or uses an embedded daily-log editor.
- `WardrobePage.ets` contains the tab labels `衣橱`, `美搭`, `日历`.
- `WardrobePage.ets` has `selectedWardrobeTab`.
- It calls `listWearLogDatesForMonth` and `listWearLogsByDate`.
- It renders `MonthCalendar`.
- It does not import or render `CalendarPage` from `Index.ets`.
- It contains the empty-state copy `今天穿了什么`.

Update existing validations:

- `validate-navigation.mjs`: quick sheet should require `拍照` and `从相册选择`, not `拍衣服 / 拍搭配 / 拍店铺`; `Index.ets` should require `CaptureEditPage` instead of direct quick editor routing.
- `validate-store-visit-edit-page.mjs`: store name must not be required for saving; accept default store name.
- `validate-wear-log-repository.mjs`: `CreateWearLogInput.outfitTemplateId` and `UpdateWearLogInput.outfitTemplateId` should be optional, and `wearLogBindArgs` should accept an optional outfit id.

**Step 2: Run validations and confirm failure**

```bash
node scripts/validate-photo-first-capture-flow.mjs
node scripts/validate-capture-edit-page.mjs
node scripts/validate-wardrobe-calendar-tab.mjs
node scripts/validate-navigation.mjs
node scripts/validate-store-visit-edit-page.mjs
node scripts/validate-wear-log-repository.mjs
```

Expected: FAIL because the capture flow, capture page, optional wear log association, and wardrobe calendar tab are not implemented yet.

**Step 3: Commit only validations**

```bash
git add scripts/validate-photo-first-capture-flow.mjs scripts/validate-capture-edit-page.mjs scripts/validate-wardrobe-calendar-tab.mjs scripts/validate-navigation.mjs scripts/validate-store-visit-edit-page.mjs scripts/validate-wear-log-repository.mjs
git commit -m "test: add photo first capture guards"
```

## Task 2: Allow Wear Logs Without a Required Outfit

**Files:**

- Modify: `entry/src/main/ets/data/repositories/WearLogRepository.ets`
- Modify: `entry/src/main/ets/pages/WearLogEditPage.ets`
- Modify: `scripts/validate-wear-log-repository.mjs`
- Modify: `scripts/validate-wear-log-edit-page.mjs`

**Step 1: Run failing validation**

```bash
node scripts/validate-wear-log-repository.mjs
node scripts/validate-wear-log-edit-page.mjs
```

Expected: FAIL because the repository and edit page still require `outfitTemplateId`.

**Step 2: Update repository contract**

In `WearLogRepository.ets`:

- Change `CreateWearLogInput.outfitTemplateId` from required to optional.
- Change `UpdateWearLogInput.outfitTemplateId` from required to optional.
- Add a helper such as `optionalOutfitSnapshot(outfitId?: string, fallbackTitle?: string): Promise<OutfitSnapshot>`.
- If `outfitId` is empty, return:
  - `title`: a generated or passed fallback such as `每日穿搭`
  - `clothingItemIds`: `[]`
- Preserve existing behavior when an outfit id is provided.
- Change `wearLogBindArgs(wearLog: WearLog, outfitTemplateId?: string)`.
- Bind `null` for empty `outfit_id`.

**Step 3: Update daily wear-log editor**

In `WearLogEditPage.ets`:

- `canSave()` should require only `!isSaving`, a non-empty `wornDate`, and at least one photo or note.
- Outfit selection remains optional.
- Copy should use `美搭` or `每日穿搭`, not `穿搭`.
- Use Yibuque tokens for black primary action if touched.

**Step 4: Run validation**

```bash
node scripts/validate-wear-log-repository.mjs
node scripts/validate-wear-log-edit-page.mjs
node scripts/validate-search-document-builder.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/data/repositories/WearLogRepository.ets entry/src/main/ets/pages/WearLogEditPage.ets scripts/validate-wear-log-repository.mjs scripts/validate-wear-log-edit-page.mjs
git commit -m "feat: allow photo first daily wear logs"
```

## Task 3: Implement Photo-Source Quick Sheet and Camera Navigation

**Files:**

- Modify: `entry/src/main/ets/components/BottomNavigationBar.ets`
- Modify: `entry/src/main/ets/components/QuickCaptureSheet.ets`
- Modify: `scripts/validate-photo-first-capture-flow.mjs`
- Modify: `scripts/validate-navigation.mjs`
- Modify: `scripts/validate-yibuque-product-scope.mjs`

**Step 1: Run failing validation**

```bash
node scripts/validate-photo-first-capture-flow.mjs
node scripts/validate-navigation.mjs
```

Expected: FAIL because the bottom center still shows `+`, and quick sheet still shows business actions.

**Step 2: Update bottom navigation**

In `BottomNavigationBar.ets`:

- Rename callback `onOpenQuickActions` to `onOpenCapture`.
- Replace literal `Text('+')` center control with a camera/photo visual.
- Use an ArkUI-safe custom builder if no icon package exists:
  - outer rounded camera body
  - small lens circle
  - optional top notch
- Keep black background and white icon.
- Keep touch target at least 56 wide and 44 high.

**Step 3: Update quick sheet**

In `QuickCaptureSheet.ets`:

- Rename actions to `onCapturePhoto`, `onPickPhoto`, and `onCancel`.
- Replace rows with:
  - `拍照`
  - `从相册选择`
- Remove `拍衣服`, `拍搭配`, and `拍店铺`.
- Keep white sheet, top large radius, light shadow, and press feedback.

**Step 4: Run validation**

```bash
node scripts/validate-photo-first-capture-flow.mjs
node scripts/validate-navigation.mjs
node scripts/validate-yibuque-visual-system.mjs
git diff --check
```

Expected: PASS for component-level rules except any Index-specific checks intentionally still failing until Task 5. If `validate-photo-first-capture-flow.mjs` includes Index checks, keep those failing and do not commit until component checks are isolated or annotate expected failure in the script by separating component and Index assertions.

**Step 5: Commit**

```bash
git add entry/src/main/ets/components/BottomNavigationBar.ets entry/src/main/ets/components/QuickCaptureSheet.ets scripts/validate-photo-first-capture-flow.mjs scripts/validate-navigation.mjs scripts/validate-yibuque-product-scope.mjs
git commit -m "feat: make quick capture photo first"
```

## Task 4: Build CaptureEditPage

**Files:**

- Create: `entry/src/main/ets/pages/CaptureEditPage.ets`
- Modify: `scripts/validate-capture-edit-page.mjs`

**Step 1: Run failing validation**

```bash
node scripts/validate-capture-edit-page.mjs
```

Expected: FAIL because `CaptureEditPage.ets` does not exist.

**Step 2: Add page API**

`CaptureEditPage` should expose:

- `@Prop initialPhotoUris: string[] = []`
- `@Prop capturedAt: string = ''`
- `@Prop clothingItems: ClothingItem[] = []`
- `clothingRepository?: ClothingRepository`
- `outfitRepository?: OutfitRepository`
- `storeRepository?: StoreRepository`
- `wearLogRepository?: WearLogRepository`
- `onSave: (target: string) => void`
- `onCancel: () => void`

**Step 3: Add state**

Minimum state:

- `captureType: string = '衣橱'`
- `note: string = ''`
- `name: string = ''`
- `category: ClothingCategory = ClothingCategory.Top`
- `storeName: string = ''`
- `price: string = ''`
- `purchaseDate: string = ''`
- `outfitTitle: string = ''`
- `selectedClothingItemIds: string[] = []`
- `wearDate: string = toIsoDate(new Date())`
- `syncWearLog: boolean = false`
- `districtOrAddress: string = ''`
- `visitDate: string = toIsoDate(new Date())`
- `isSaving: boolean = false`
- `errorMessage: string = ''`

Derive `captureDate` from `capturedAt` when possible.

**Step 4: Add layout**

Layout order:

1. Header with cancel.
2. Large rounded photo preview via `PhotoGrid` or a single large `Image`.
3. Segmented type selector: `衣橱 / 美搭 / 店铺`.
4. `TextArea` placeholder `写一点小记`.
5. Optional information section for current type.
6. Black capsule save button.

**Step 5: Add save handlers**

For `衣橱`:

- Require `initialPhotoUris.length > 0`.
- Save with `ClothingRepository.createClothing`.
- Name fallback: `${categoryLabel(category)} ${MM-DD HH:mm}`.
- Note uses `note`.
- Purchase fields are optional.

For `美搭`:

- Require photo.
- Save with `OutfitRepository.createOutfit`.
- Title fallback: `美搭 ${MM-DD HH:mm}`.
- Note uses `note`.
- Clothing ids optional.
- If `syncWearLog` is true, call `WearLogRepository.createWearLog` with optional `outfitTemplateId`, `wornDate`, `photoUris`, and `note`.

For `店铺`:

- Require photo.
- Save with `StoreRepository.createStoreVisit`.
- Store name fallback: `逛店 ${MM-DD HH:mm}`.
- If `storeName` is non-empty, call or reuse `createStore/findStoreByName`; if empty, creating only a visit is acceptable.
- Note uses `note`.

**Step 6: Run validation**

```bash
node scripts/validate-capture-edit-page.mjs
node scripts/validate-store-visit-edit-page.mjs
node scripts/validate-outfit-edit-page.mjs
git diff --check
```

Expected: PASS.

**Step 7: Commit**

```bash
git add entry/src/main/ets/pages/CaptureEditPage.ets scripts/validate-capture-edit-page.mjs scripts/validate-store-visit-edit-page.mjs scripts/validate-outfit-edit-page.mjs
git commit -m "feat: add unified capture edit page"
```

## Task 5: Wire Capture Flow in Index

**Files:**

- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `scripts/validate-photo-first-capture-flow.mjs`
- Modify: `scripts/validate-navigation.mjs`
- Modify: `scripts/validate-runtime-wiring.mjs`

**Step 1: Run failing validation**

```bash
node scripts/validate-photo-first-capture-flow.mjs
node scripts/validate-navigation.mjs
node scripts/validate-runtime-wiring.mjs
```

Expected: FAIL because `Index.ets` still opens the old direct editors from the quick sheet.

**Step 2: Update Index state and imports**

In `Index.ets`:

- Import `CaptureEditPage`.
- Remove quick state that exists only for direct clothing/outfit/store editors where possible.
- Add:
  - `showCaptureEditor`
  - `capturePhotoUris`
  - `captureCapturedAt`
  - `captureClothingItems`
  - `isCapturing`

**Step 3: Add capture helpers**

Add helpers:

- `copySourcesToLocalUris(sources: PhotoSource[]): Promise<string[]>`
- `startCameraCapture(): Promise<void>`
- `startGalleryCapture(): Promise<void>`
- `openCaptureEditor(photoUris: string[]): Promise<void>`
- `closeCaptureEditor(): void`

Flow:

- Quick sheet `拍照` calls `startCameraCapture`.
- Quick sheet `从相册选择` calls `startGalleryCapture`.
- Both copy photos to app storage before opening `CaptureEditPage`.
- Load clothing items before opening capture page so `美搭` can optionally link items.

**Step 4: Render capture page**

Add branch before normal shell:

- If `showCaptureEditor`, render `CaptureEditPage`.
- Pass repositories:
  - `clothingRepository`
  - `outfitRepository`
  - `storeRepository`
  - `wearLogRepository`
- Pass `captureClothingItems`, `capturePhotoUris`, `captureCapturedAt`.
- On save:
  - close editor.
  - if target is `店铺`, set main tab to `store`.
  - otherwise set main tab to `wardrobe`.

**Step 5: Keep legacy editors available only for list item editing**

- Do not remove existing `ClothingEditPage`, `OutfitEditPage`, or `StoreVisitEditPage` branches if used elsewhere.
- Ensure bottom quick sheet no longer directly opens them.

**Step 6: Run validation**

```bash
node scripts/validate-photo-first-capture-flow.mjs
node scripts/validate-navigation.mjs
node scripts/validate-runtime-wiring.mjs
node scripts/validate-yibuque-product-scope.mjs
git diff --check
```

Expected: PASS.

**Step 7: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets scripts/validate-photo-first-capture-flow.mjs scripts/validate-navigation.mjs scripts/validate-runtime-wiring.mjs scripts/validate-yibuque-product-scope.mjs
git commit -m "feat: wire photo first capture flow"
```

## Task 6: Add Wardrobe Calendar Tab

**Files:**

- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `scripts/validate-wardrobe-calendar-tab.mjs`
- Modify: `scripts/validate-wardrobe-page.mjs`
- Modify: `scripts/validate-yibuque-product-scope.mjs`

**Step 1: Inspect local changes**

Before editing:

```bash
git diff -- entry/src/main/ets/pages/WardrobePage.ets
```

If there is a user edit, preserve it. Do not revert unrelated local changes.

**Step 2: Run failing validation**

```bash
node scripts/validate-wardrobe-calendar-tab.mjs
node scripts/validate-wardrobe-page.mjs
```

Expected: FAIL because `WardrobePage` does not yet expose `日历` as an internal tab.

**Step 3: Pass WearLogRepository into WardrobePage**

In `Index.ets`, pass:

- `wearLogRepository: this.runtime.wearLogRepository`

In `WardrobePage.ets`, add prop:

- `wearLogRepository?: WearLogRepository`

**Step 4: Add calendar state to WardrobePage**

Add:

- `currentMonth: string = monthKey(new Date())`
- `selectedDate: string = toIsoDate(new Date())`
- `markedDates: string[] = []`
- `selectedDateLogs: WearLog[] = []`
- `showWearLogEditor: boolean = false`
- `editingWearLogId: string = ''`

Add load helpers:

- `loadCalendar()`
- `loadMonthMarkers()`
- `loadSelectedDateLogs()`
- `selectCalendarDate(date: string)`
- `openWearLogEditor(wearLog?: WearLog)`
- `closeWearLogEditor()`

**Step 5: Add tab label**

Change wardrobe primary tabs to:

- `衣橱`
- `美搭`
- `日历`

If existing validations still expect `衣裤`, update product scope and wardrobe validations to the new confirmed copy `衣橱`.

**Step 6: Render calendar tab**

When selected tab is `日历`:

- Render `MonthCalendar`.
- Show selected date heading.
- If no logs, show `今天穿了什么？从相机记录一套。`
- If logs exist, show photo-first daily records with date, title, note/place, and edit action.
- Use Yibuque tokens, rounded photo cards, and light shadows.

**Step 7: Editor handling**

If `showWearLogEditor`:

- Render `WearLogEditPage` inside `WardrobePage`.
- Pass `outfits`, `wearLogRepository`, `photoPickerAdapter`, `photoStorage`.
- On save, close and reload calendar markers/logs.

**Step 8: Run validation**

```bash
node scripts/validate-wardrobe-calendar-tab.mjs
node scripts/validate-wardrobe-page.mjs
node scripts/validate-calendar-page.mjs
node scripts/validate-yibuque-product-scope.mjs
git diff --check
```

Expected: PASS.

**Step 9: Commit**

```bash
git add entry/src/main/ets/pages/WardrobePage.ets entry/src/main/ets/pages/Index.ets scripts/validate-wardrobe-calendar-tab.mjs scripts/validate-wardrobe-page.mjs scripts/validate-yibuque-product-scope.mjs
git commit -m "feat: add wardrobe calendar tab"
```

## Task 7: Refresh Legacy Form Copy and Optional Store Save

**Files:**

- Modify: `entry/src/main/ets/pages/StoreVisitEditPage.ets`
- Modify: `entry/src/main/ets/pages/OutfitEditPage.ets`
- Modify: `entry/src/main/ets/pages/WearLogEditPage.ets`
- Modify: `scripts/validate-store-visit-edit-page.mjs`
- Modify: `scripts/validate-outfit-edit-page.mjs`
- Modify: `scripts/validate-wear-log-edit-page.mjs`

**Step 1: Run validation**

```bash
node scripts/validate-store-visit-edit-page.mjs
node scripts/validate-outfit-edit-page.mjs
node scripts/validate-wear-log-edit-page.mjs
```

Expected: FAIL for any remaining copy or required-field mismatch.

**Step 2: Store visit editor**

- Change `canSave()` to require only `!isSaving` and at least one photo or note.
- Make store name optional.
- Use fallback store name in `createInput`.
- Skip `ensureStoreId()` when store name is empty.
- Change copy from form-heavy `店铺信息` to `小记` first and `选填信息`.

**Step 3: Outfit editor**

- Keep photo required.
- Keep title and linked clothing optional.
- Ensure note uses a multi-line field if ArkUI supports the existing `TextArea` pattern.
- Copy should align with `照片 + 小记`.

**Step 4: Wear log editor**

- Copy should align with `每日穿搭` and `小记`.
- Outfit selection optional.
- Date defaults to selected/captured date.

**Step 5: Run validation**

```bash
node scripts/validate-store-visit-edit-page.mjs
node scripts/validate-outfit-edit-page.mjs
node scripts/validate-wear-log-edit-page.mjs
git diff --check
```

Expected: PASS.

**Step 6: Commit**

```bash
git add entry/src/main/ets/pages/StoreVisitEditPage.ets entry/src/main/ets/pages/OutfitEditPage.ets entry/src/main/ets/pages/WearLogEditPage.ets scripts/validate-store-visit-edit-page.mjs scripts/validate-outfit-edit-page.mjs scripts/validate-wear-log-edit-page.mjs
git commit -m "feat: simplify capture detail forms"
```

## Task 8: Final Verification and Build

**Files:**

- Modify as needed: validation scripts only for real expected-contract changes.

**Step 1: Run all validation scripts**

```bash
for script in scripts/validate-*.mjs; do node "$script" || exit 1; done
```

Expected: PASS.

**Step 2: Run diff check**

```bash
git diff --check
```

Expected: PASS.

**Step 3: Run Harmony build if CLI exists**

```bash
/Users/seminzhu/Downloads/command-line-tools/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
```

Expected: PASS, with the known signing warning acceptable:

```text
No signingConfig found for product default
```

**Step 4: Manual QA checklist**

- Tap bottom camera button.
- Cancel photo-source sheet.
- Tap camera and complete/cancel.
- Tap gallery and select one image.
- Save as `衣橱` with only small note.
- Save as `美搭` with only photo.
- Save as `店铺` with only photo/small note and no store name.
- Confirm wardrobe list refreshes.
- Confirm beauty-match list refreshes.
- Confirm store visit list refreshes.
- Open wardrobe `日历` tab and confirm dates with wear logs are marked.
- Add/edit a daily wear log without choosing a美搭.

**Step 5: Final commit if any verification-only doc/script update exists**

Only commit if files changed during QA:

```bash
git status --short
git add <changed-files>
git commit -m "test: verify photo first capture flow"
```

