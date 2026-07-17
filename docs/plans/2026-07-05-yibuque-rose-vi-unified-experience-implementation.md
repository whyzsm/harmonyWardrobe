# 衣不缺 Rose VI 统一体验 Implementation Plan

> **For implementer:** Use TDD throughout. Write failing validation first. Watch it fail. Then implement the smallest change that makes it pass.

**Goal:** 统一 `衣不缺` rose/pink VI、照片优先补录链路和 `衣橱 / 美搭 / 店铺 / 日历 / 我的` 的本地落库回显能力。

**Architecture:** 保持现有 HarmonyOS ArkTS + ArkUI + 本地 SQLite + repository 注入架构。用验证脚本约束产品范围和视觉系统，再逐步收敛 shared components、页面样式、补录落库和旧概念清理。照片继续通过 `PhotoPickerAdapter` 与 `PhotoStorage` 复制到 app-local storage，页面只保存本地 URI/path。

**Tech Stack:** HarmonyOS Stage, ArkTS, ArkUI, SQLite repositories, Node.js validation scripts, hvigor.

---

## Global Constraints

- 不提交 `.idea/`、`.appanalyzer/`、`.hvigor/`、`build/`、`entry/build/`。
- 不提交包含本机签名路径或密钥的 `build-profile.json5`，除非任务明确只修 product/target 且先移除敏感信息。
- 不新增网络权限、登录、远端同步或第三方 UI 库。
- 不把照片二进制写进 SQLite。
- 不恢复 `首页`、底部 `日历`、`逛街`、`心愿单`、`点赞`、`收藏`、`评论`、`关注` 为主流程。
- 用户可见主文案使用 `衣橱 / 美搭 / 店铺 / 逛店 / 日历 / 我的`。
- 每个任务提交前运行本任务验证和 `git diff --check`。

## Task 1: Align Rose VI Design Contract

**Files:**

- Modify: `docs/background/yibuque-design.md`
- Test: `scripts/validate-yibuque-visual-system.mjs`

**Step 1: Write failing validation**

Update `scripts/validate-yibuque-visual-system.mjs` so it asserts:

```js
for (const needle of ['#B11B68', '#8E1454', '#D83E8E', '#FFF2F8', '#FBE1F0']) {
  mustInclude(tokens, tokenPath, needle);
}

for (const needle of ['rose', '深玫瑰', '照片优先', '拍照', '从相册选择']) {
  mustInclude(design, designPath, needle);
}

for (const forbidden of ['actionBlack: #000000', '黑色主按钮', 'brandCyan', '薄荷绿只作为']) {
  mustNotInclude(design, designPath, forbidden);
}
```

**Step 2: Run test and confirm failure**

Command:

```bash
node scripts/validate-yibuque-visual-system.mjs
```

Expected: FAIL because the design background still contains old black/blue-green rules.

**Step 3: Implement**

Rewrite `docs/background/yibuque-design.md` to match `docs/plans/2026-07-05-yibuque-rose-vi-unified-experience-design.md`:

- Rose/pink VI is the source of truth.
- Main action is deep rose, not black.
- Background, card, text, border, placeholder and shadow roles match `Tokens.ets`.
- `QuickCaptureSheet` actions are `拍照` and `从相册选择`.
- Capture classification happens later in `CaptureEditPage`.

**Step 4: Verify**

Command:

```bash
node scripts/validate-yibuque-visual-system.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add docs/background/yibuque-design.md scripts/validate-yibuque-visual-system.mjs
git commit -m "docs: align yibuque rose vi contract"
```

## Task 2: Guard Product Scope And Stale Concepts

**Files:**

- Modify: `scripts/validate-yibuque-product-scope.mjs`
- Create: `scripts/validate-yibuque-stale-concepts.mjs`
- Test target files:
  - `entry/src/main/ets/pages/Index.ets`
  - `entry/src/main/ets/pages/WardrobePage.ets`
  - `entry/src/main/ets/pages/CaptureEditPage.ets`
  - `entry/src/main/ets/pages/SearchResultsPage.ets`
  - `entry/src/main/ets/components/QuickCaptureSheet.ets`

**Step 1: Write failing validation**

Create `scripts/validate-yibuque-stale-concepts.mjs`:

```js
import fs from 'node:fs';

function read(path) {
  if (!fs.existsSync(path)) {
    throw new Error(`${path} does not exist`);
  }
  return fs.readFileSync(path, 'utf8');
}

function mustNotInclude(source, file, needle) {
  if (source.includes(needle)) {
    throw new Error(`${file} must not include ${needle}`);
  }
}

const userFacingFiles = [
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/ets/pages/WardrobePage.ets',
  'entry/src/main/ets/pages/CaptureEditPage.ets',
  'entry/src/main/ets/pages/SearchResultsPage.ets',
  'entry/src/main/ets/pages/WearLogEditPage.ets',
  'entry/src/main/ets/components/QuickCaptureSheet.ets',
  'entry/src/main/ets/components/OutfitCard.ets',
  'entry/src/main/ets/components/EmptyState.ets'
];

for (const file of userFacingFiles) {
  const text = read(file);
  for (const forbidden of ['首页', '逛街', '心愿单', '点赞', '收藏', '评论', '关注', '穿搭']) {
    mustNotInclude(text, file, forbidden);
  }
}

console.log('PASS');
```

Update `validate-yibuque-product-scope.mjs` so it asserts:

- `Index.ets` contains `AppTopBar`, `BottomNavigationBar`, `QuickCaptureSheet`, `CaptureEditPage`.
- `BottomNavigationBar.ets` contains only `衣橱` and `逛店` labels plus camera action.
- `QuickCaptureSheet.ets` contains `拍照` and `从相册选择`.
- `QuickCaptureSheet.ets` does not contain `拍衣服`、`拍搭配`、`拍店铺`.
- `WardrobePage.ets` contains `衣橱`、`美搭`、`日历`.

**Step 2: Run test and confirm failure**

Command:

```bash
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-yibuque-stale-concepts.mjs
```

Expected: FAIL if any old user-facing copy remains in active flow.

**Step 3: Implement**

Remove or rename stale user-facing copy in active pages/components:

- `穿搭` -> `美搭` or `搭配`.
- `逛街` -> `逛店`.
- Debug placeholders such as `wornDate` or `placeText` -> Chinese field labels.
- Keep old repository/model names only where they are internal compatibility code and not user-facing.

**Step 4: Verify**

```bash
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-yibuque-stale-concepts.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add scripts/validate-yibuque-product-scope.mjs scripts/validate-yibuque-stale-concepts.mjs entry/src/main/ets/pages entry/src/main/ets/components
git commit -m "test: guard yibuque product scope"
```

## Task 3: Normalize Tokens And Legacy Theme Mapping

**Files:**

- Modify: `entry/src/main/ets/theme/Tokens.ets`
- Modify: `scripts/validate-yibuque-visual-system.mjs`
- Create: `scripts/validate-yibuque-theme-usage.mjs`

**Step 1: Write failing validation**

Create `scripts/validate-yibuque-theme-usage.mjs`:

```js
import fs from 'node:fs';
import path from 'node:path';

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full, out);
    } else if (full.endsWith('.ets')) {
      out.push(full);
    }
  }
  return out;
}

const files = walk('entry/src/main/ets/pages').concat(walk('entry/src/main/ets/components'));
const allowedLegacy = new Set([
  'entry/src/main/ets/pages/Index.ets'
]);

for (const file of files) {
  const text = fs.readFileSync(file, 'utf8');
  if (!allowedLegacy.has(file) && text.includes('AppTheme.color.primary')) {
    throw new Error(`${file} uses legacy AppTheme primary instead of Yibuque tokens`);
  }
}

console.log('PASS');
```

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-yibuque-theme-usage.mjs
```

Expected: FAIL for components/pages still using old primary theme.

**Step 3: Implement**

- Keep `AppTheme` exported for compatibility, but map it to rose VI values.
- Prefer direct `YibuqueColor`, `YibuqueRadius`, `YibuqueSpacing`, `YibuqueShadow` imports in active pages/components.
- Replace old blue/green/black hard-coded visual rules with rose token references.
- Ensure `YibuqueColor.actionBlack` remains as compatibility name but value is deep rose.

**Step 4: Verify**

```bash
node scripts/validate-yibuque-visual-system.mjs
node scripts/validate-yibuque-theme-usage.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/theme/Tokens.ets scripts/validate-yibuque-visual-system.mjs scripts/validate-yibuque-theme-usage.mjs entry/src/main/ets/pages entry/src/main/ets/components
git commit -m "style: normalize yibuque rose tokens"
```

## Task 4: Unify Shared Components

**Files:**

- Modify: `entry/src/main/ets/components/AppTopBar.ets`
- Modify: `entry/src/main/ets/components/BottomNavigationBar.ets`
- Modify: `entry/src/main/ets/components/QuickCaptureSheet.ets`
- Modify: `entry/src/main/ets/components/EmptyState.ets`
- Modify: `entry/src/main/ets/components/PhotoGrid.ets`
- Modify: `scripts/validate-yibuque-visual-system.mjs`

**Step 1: Write failing validation**

Extend visual validation to assert:

- `AppTopBar.ets` has `衣不缺`、`我的`、44/48 touch target and press feedback.
- `BottomNavigationBar.ets` has camera icon/action, `bottomSafe`, no literal `Text('+')`.
- `QuickCaptureSheet.ets` has `拍照`、`从相册选择`, 64px row or equivalent large hit target, and no type-specific labels.
- `EmptyState.ets` and `PhotoGrid.ets` import `YibuqueColor` and use large radius/soft placeholder.

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-yibuque-visual-system.mjs
```

Expected: FAIL until all shared components comply.

**Step 3: Implement**

- AppTopBar: rose logo, consistent height, avatar button, press scale.
- BottomNavigationBar: camera icon center action, selected/disabled states, safe area spacing.
- QuickCaptureSheet: two photo source actions, loading-safe click handling from parent.
- EmptyState: single reusable rose style with clear action copy.
- PhotoGrid: rounded image previews and soft fallback for invalid/missing image URI.

**Step 4: Verify**

```bash
node scripts/validate-yibuque-visual-system.mjs
node scripts/validate-photo-first-capture-flow.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/components/AppTopBar.ets entry/src/main/ets/components/BottomNavigationBar.ets entry/src/main/ets/components/QuickCaptureSheet.ets entry/src/main/ets/components/EmptyState.ets entry/src/main/ets/components/PhotoGrid.ets scripts/validate-yibuque-visual-system.mjs
git commit -m "style: unify yibuque shared components"
```

## Task 5: Complete Photo-First Capture Flow

**Files:**

- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/CaptureEditPage.ets`
- Modify: `scripts/validate-photo-first-capture-flow.mjs`
- Modify: `scripts/validate-capture-edit-page.mjs`

**Step 1: Write failing validation**

Update `validate-photo-first-capture-flow.mjs` and `validate-capture-edit-page.mjs` to assert:

- Camera and gallery both call `PhotoStorage.copyToAppStorage` before opening `CaptureEditPage`.
- `CaptureEditPage` clones `initialPhotoUris` with spread assignment.
- `canSave()` only requires `photoUris.length > 0` and not name/title/category/linked clothing.
- Capture type labels are exactly `衣橱`、`美搭`、`店铺`.
- On save, `店铺` returns to store tab; `衣橱` and `美搭` return to wardrobe tab.
- Error copy contains `拍照失败，请重试` and `选择照片失败，请重试`.

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-photo-first-capture-flow.mjs
node scripts/validate-capture-edit-page.mjs
```

Expected: FAIL if readonly state or file path handling is incomplete.

**Step 3: Implement**

- Ensure `startCameraCapture()` and `startGalleryCapture()` both:
  - guard `isCapturing`;
  - close sheet;
  - call adapter;
  - copy sources to local app storage;
  - open capture editor only when local URI array is non-empty;
  - set user-facing error on failure.
- Ensure `CaptureEditPage.aboutToAppear()` uses `this.photoUris = [...this.initialPhotoUris]`.
- Ensure `saveWardrobe`, `saveOutfit`, `saveStore` all use generated fallback names.
- Ensure no direct mutation of read-only route params or prop arrays.

**Step 4: Verify**

```bash
node scripts/validate-photo-first-capture-flow.mjs
node scripts/validate-capture-edit-page.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets entry/src/main/ets/pages/CaptureEditPage.ets scripts/validate-photo-first-capture-flow.mjs scripts/validate-capture-edit-page.mjs
git commit -m "fix: complete photo first capture flow"
```

## Task 6: Refine Capture Forms And Optional Fields

**Files:**

- Modify: `entry/src/main/ets/pages/CaptureEditPage.ets`
- Modify: `entry/src/main/ets/components/ClothingPicker.ets`
- Modify: `scripts/validate-capture-edit-page.mjs`

**Step 1: Write failing validation**

Add assertions:

- `CaptureEditPage.ets` contains visible labels for `小记` and `选填信息`.
- `TextArea` exists for note.
- Clothing fields include category options `上衣`、`裤子`、`短裤`、`长裙`、`半裙`.
- Outfit fields include optional clothing picker and optional `同步到日历`.
- Store fields include optional `商圈或地址`.
- Save button text changes to `保存到衣橱`、`保存到美搭`、`保存到店铺`.

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-capture-edit-page.mjs
```

Expected: FAIL if form copy or optional grouping is incomplete.

**Step 3: Implement**

- Move all non-photo fields under `选填信息`.
- Keep note above optional structured fields.
- Add short helper copy only where it reduces ambiguity.
- Use rose card/input styles consistently.
- Keep save button sticky or visually prominent near bottom.

**Step 4: Verify**

```bash
node scripts/validate-capture-edit-page.mjs
node scripts/validate-yibuque-visual-system.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/CaptureEditPage.ets entry/src/main/ets/components/ClothingPicker.ets scripts/validate-capture-edit-page.mjs
git commit -m "feat: simplify capture edit forms"
```

## Task 7: Unify Wardrobe Tabs, Cards, And Calendar

**Files:**

- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Modify: `entry/src/main/ets/pages/WearLogEditPage.ets`
- Modify: `entry/src/main/ets/components/ClothingCard.ets`
- Modify: `entry/src/main/ets/components/OutfitCard.ets`
- Modify: `entry/src/main/ets/components/CategoryTabs.ets`
- Modify: `entry/src/main/ets/components/MonthCalendar.ets`
- Modify: `scripts/validate-wardrobe-page.mjs`
- Modify: `scripts/validate-wardrobe-calendar-tab.mjs`
- Modify: `scripts/validate-wear-log-edit-page.mjs`

**Step 1: Write failing validation**

Update validations to assert:

- `WardrobePage.ets` has tabs `衣橱`、`美搭`、`日历`.
- Clothing category filters are only `上衣`、`裤子`、`短裤`、`长裙`、`半裙`.
- `OutfitRepository.listOutfits` is used for `美搭`.
- Calendar tab uses `WearLogRepository`.
- `WearLogEditPage.ets` does not expose debug placeholders like `wornDate` or `placeText`.
- Cards use `YibuqueColor`, `YibuqueRadius`, rounded images and soft placeholders.

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-wardrobe-page.mjs
node scripts/validate-wardrobe-calendar-tab.mjs
node scripts/validate-wear-log-edit-page.mjs
```

Expected: FAIL if old tab names, stale copy, or inconsistent card styles remain.

**Step 3: Implement**

- Make wardrobe tab labels exactly `衣橱 / 美搭 / 日历`.
- Ensure list refreshes after returning from save flows.
- Refine clothing and outfit cards to image-led rose style.
- Refine calendar and wear-log editor labels and empty states.
- Empty states should direct users to the bottom camera action.

**Step 4: Verify**

```bash
node scripts/validate-wardrobe-page.mjs
node scripts/validate-wardrobe-calendar-tab.mjs
node scripts/validate-wear-log-edit-page.mjs
node scripts/validate-yibuque-stale-concepts.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/WardrobePage.ets entry/src/main/ets/pages/WearLogEditPage.ets entry/src/main/ets/components/ClothingCard.ets entry/src/main/ets/components/OutfitCard.ets entry/src/main/ets/components/CategoryTabs.ets entry/src/main/ets/components/MonthCalendar.ets scripts/validate-wardrobe-page.mjs scripts/validate-wardrobe-calendar-tab.mjs scripts/validate-wear-log-edit-page.mjs
git commit -m "feat: unify wardrobe outfit and calendar tabs"
```

## Task 8: Complete Store Visit Feature

**Files:**

- Modify: `entry/src/main/ets/pages/StoreVisitPage.ets`
- Modify: `entry/src/main/ets/pages/StoreVisitEditPage.ets`
- Modify: `entry/src/main/ets/components/StoreVisitCard.ets`
- Modify: `entry/src/main/ets/data/repositories/StoreRepository.ets`
- Modify: `scripts/validate-store-repository.mjs`
- Modify: `scripts/validate-store-visit-page.mjs`
- Modify: `scripts/validate-store-visit-edit-page.mjs`

**Step 1: Write failing validation**

Assert:

- Store repository can create/list stores and store visits.
- `createStoreVisit` accepts optional `storeId` and generated `storeNameSnapshot`.
- `StoreVisitPage.ets` lists visits and uses `StoreVisitCard`.
- Empty state copy points to bottom camera, not old `拍店铺` direct button.
- `StoreVisitEditPage.ets` uses rose form/card style and has no required fields beyond photos when reached from capture flow.
- Store card shows photo, name, date/address and note preview.

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-store-repository.mjs
node scripts/validate-store-visit-page.mjs
node scripts/validate-store-visit-edit-page.mjs
```

Expected: FAIL if list, edit or repository contract is incomplete.

**Step 3: Implement**

- Ensure store visits are created from `CaptureEditPage.saveStore()`.
- Ensure `StoreVisitPage` refreshes in `aboutToAppear` or equivalent visibility path.
- Replace direct `拍店铺` CTA with guidance to bottom camera.
- Keep optional standalone editor working if already used elsewhere.
- Search index updates should include store and store visit records.

**Step 4: Verify**

```bash
node scripts/validate-store-repository.mjs
node scripts/validate-store-visit-page.mjs
node scripts/validate-store-visit-edit-page.mjs
node scripts/validate-search-repository.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/StoreVisitPage.ets entry/src/main/ets/pages/StoreVisitEditPage.ets entry/src/main/ets/components/StoreVisitCard.ets entry/src/main/ets/data/repositories/StoreRepository.ets scripts/validate-store-repository.mjs scripts/validate-store-visit-page.mjs scripts/validate-store-visit-edit-page.mjs
git commit -m "feat: complete store visit records"
```

## Task 9: Complete Profile And Settings Surface

**Files:**

- Modify: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/data/repositories/ProfileRepository.ets`
- Modify: `entry/src/main/ets/domain/profile/ProfileModels.ets`
- Modify: `scripts/validate-profile-page.mjs`
- Modify: `scripts/validate-profile-repository.mjs`

**Step 1: Write failing validation**

Assert:

- `ProfilePage.ets` shows `个人信息`、`身高`、`体重`、`腰围`、`设置`.
- Values save through `ProfileRepository`.
- Reopening profile loads existing values.
- Page uses rose background, large avatar placeholder, white cards and rose outline/primary controls.
- No login/account/network copy appears.

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-profile-repository.mjs
node scripts/validate-profile-page.mjs
```

Expected: FAIL if persistence or visual style is incomplete.

**Step 3: Implement**

- Keep profile local-only.
- Save height/weight/waist as optional values.
- Add loading/save/error states.
- Add settings row as local placeholder if no actual settings are required.

**Step 4: Verify**

```bash
node scripts/validate-profile-repository.mjs
node scripts/validate-profile-page.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/ProfilePage.ets entry/src/main/ets/data/repositories/ProfileRepository.ets entry/src/main/ets/domain/profile/ProfileModels.ets scripts/validate-profile-page.mjs scripts/validate-profile-repository.mjs
git commit -m "feat: complete local profile page"
```

## Task 10: Search And Old Flow Cleanup

**Files:**

- Modify: `entry/src/main/ets/pages/SearchResultsPage.ets`
- Modify: `entry/src/main/ets/domain/search/SearchDocumentBuilder.ets`
- Modify: `entry/src/main/ets/data/repositories/SearchRepository.ets`
- Modify: `scripts/validate-search-ui.mjs`
- Modify: `scripts/validate-search-document-builder.mjs`
- Modify: `scripts/validate-yibuque-stale-concepts.mjs`

**Step 1: Write failing validation**

Assert:

- Search result categories are `衣物`、`美搭`、`逛店记录`、`店铺`.
- No user-facing `心愿单` in search UI.
- No primary copy uses `穿搭`.
- Existing wishlist index code, if kept, is not exposed as a main result label.

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-search-ui.mjs
node scripts/validate-search-document-builder.mjs
node scripts/validate-yibuque-stale-concepts.mjs
```

Expected: FAIL until search copy is aligned.

**Step 3: Implement**

- Rename outfit result labels to `美搭`.
- Add store/store visit result labels where repository already supports them.
- Hide or relabel legacy wishlist results from primary UI.
- Keep internal compatibility code only when needed for old data.

**Step 4: Verify**

```bash
node scripts/validate-search-ui.mjs
node scripts/validate-search-document-builder.mjs
node scripts/validate-yibuque-stale-concepts.mjs
git diff --check
```

Expected: PASS.

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/SearchResultsPage.ets entry/src/main/ets/domain/search/SearchDocumentBuilder.ets entry/src/main/ets/data/repositories/SearchRepository.ets scripts/validate-search-ui.mjs scripts/validate-search-document-builder.mjs scripts/validate-yibuque-stale-concepts.mjs
git commit -m "feat: align search with yibuque scope"
```

## Task 11: Manual QA Script And Final Validation

**Files:**

- Modify: `docs/qa/manual-test-script.md`
- Modify: `README.md`
- Test: all `scripts/validate-*.mjs`

**Step 1: Write failing validation**

If no QA validation exists, add or update `scripts/validate-qa-fixture.mjs` to assert manual QA includes:

- 主导航切换。
- 相机入口。
- 拍照。
- 从相册选择。
- 保存衣橱。
- 保存美搭。
- 保存店铺。
- 日历同步。
- 我的信息保存。
- rose VI 视觉检查。

**Step 2: Run test and confirm failure**

```bash
node scripts/validate-qa-fixture.mjs
```

Expected: FAIL until docs include the current flow.

**Step 3: Implement**

- Update manual QA doc with exact test steps and expected results.
- Update README if it still describes old main navigation or wishlist-first scope.
- Note known local DevEco build requirement: product `default`, no committed signing secrets.

**Step 4: Verify all scripts**

```bash
for script in scripts/validate-*.mjs; do node "$script" || exit 1; done
git diff --check
```

Expected: PASS.

**Step 5: Run HarmonyOS build**

```bash
/Users/seminzhu/Downloads/command-line-tools/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
```

Expected: BUILD SUCCESSFUL. If build fails on local signing/product config, document the exact failure and do not commit machine-specific signing changes.

**Step 6: Commit**

```bash
git add docs/qa/manual-test-script.md README.md scripts/validate-qa-fixture.mjs
git commit -m "docs: update yibuque qa checklist"
```

## Final Delivery Checklist

Run:

```bash
for script in scripts/validate-*.mjs; do node "$script" || exit 1; done
git diff --check
/Users/seminzhu/Downloads/command-line-tools/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
git status --short
```

Expected:

- All validation scripts pass.
- `git diff --check` passes.
- HAP build passes or has a documented local signing/product blocker.
- `build-profile.json5`, `.idea/`, `.appanalyzer/` are not committed unless explicitly required and safe.
- The app opens to a unified rose VI experience.
- Camera/gallery -> classify -> save works for `衣橱`、`美搭`、`店铺`.
- Lists and profile persist locally and re-open with saved data.

## Execution Mode

Recommended: subagent-driven execution, one task per implementation pass, with a reviewer pass after each task.

Alternative: manual execution using the tasks above in order.
