# Harmony Wardrobe UI Refresh Implementation Plan

> **For implementer:** Use TDD throughout. Write failing test first. Watch it fail. Then implement.
>
> **给实现者：** 全程使用 TDD。先写失败测试，确认失败，再实现。

**Goal:** Refresh the Harmony Wardrobe mobile UI into a `#4894FE` blue lightweight ecommerce wardrobe experience without changing business behavior.

**目标：** 在不改变业务行为的前提下，把 Harmony Wardrobe 移动端 UI 刷新为以 `#4894FE` 为主色的蓝色轻电商衣橱体验。

**Architecture:** Keep the existing HarmonyOS ArkTS/ArkUI structure. Centralize visual roles in `AppTheme`, then update shared components before page shells. Use Node validation scripts as lightweight TDD gates because ArkUI visual tests are not available in this repository.

**架构：** 保持现有 HarmonyOS ArkTS/ArkUI 结构。先把视觉角色集中到 `AppTheme`，再更新共享组件和页面壳。由于仓库没有 ArkUI 视觉测试框架，使用 Node 校验脚本作为轻量 TDD 门禁。

**Tech Stack:** HarmonyOS ArkTS Stage model, ArkUI, Node.js validation scripts, local hvigor build.

**技术栈：** HarmonyOS ArkTS Stage 模型、ArkUI、Node.js 校验脚本、本地 hvigor 构建。

---

## Execution Rules / 执行规则

- Do not add network permissions or network APIs.
- 不新增网络权限或网络 API。
- Do not modify database, repository, photo picker, or photo storage behavior.
- 不修改数据库、仓储、图片选择器或图片存储行为。
- Do not commit DevEco local files such as `.idea/`, `.clang-format`, `.hvigor/`, or build outputs.
- 不提交 DevEco 本地文件，例如 `.idea/`、`.clang-format`、`.hvigor/` 或构建产物。
- Keep UI changes scoped to theme, shared components, and existing pages.
- UI 改动只限定在主题、共享组件和现有页面。
- Every task must end with a scoped commit after its validation passes.
- 每个任务在验证通过后都要独立提交。

## Task Checklist / 任务清单

- [ ] Task 1: Add UI Refresh Theme Tokens
- [ ] Task 2: Refresh Core Display Components
- [ ] Task 3: Refresh Search, Tabs, Calendar, And Empty States
- [ ] Task 4: Refresh Main Page Shells
- [ ] Task 5: Refresh Edit And Picker Flows
- [ ] Task 6: Run Visual Build Verification

## Task 1: Add UI Refresh Theme Tokens / 新增 UI 改版主题 Token

**Files / 文件：**

- Create: `scripts/validate-ui-refresh.mjs`
- Modify: `entry/src/main/ets/theme/Tokens.ets`

**Step 1: Write the failing validation / 写失败校验**

Create `scripts/validate-ui-refresh.mjs` with the following initial gate:

创建 `scripts/validate-ui-refresh.mjs`，初始门禁如下：

```js
import fs from 'node:fs';

const tokenPath = 'entry/src/main/ets/theme/Tokens.ets';
const tokenSource = fs.readFileSync(tokenPath, 'utf8');

function fail(message) {
  console.error(message);
  process.exit(1);
}

function requireIncludes(source, value, label) {
  if (!source.includes(value)) {
    fail(`${label} missing: ${value}`);
  }
}

function forbidIncludes(source, value, label) {
  if (source.includes(value)) {
    fail(`${label} still contains forbidden value: ${value}`);
  }
}

requireIncludes(tokenSource, "primary: '#4894FE'", 'primary token');
requireIncludes(tokenSource, "primaryPressed: '#246BFE'", 'primary pressed token');
requireIncludes(tokenSource, "primarySoft: '#EAF3FF'", 'primary soft token');
requireIncludes(tokenSource, "surfaceMuted: '#F6F8FC'", 'app background token');
requireIncludes(tokenSource, "success: '#22C55E'", 'success token');
requireIncludes(tokenSource, "warning: '#FFB020'", 'warning token');
requireIncludes(tokenSource, "danger: '#EF4444'", 'danger token');
requireIncludes(tokenSource, "accent: '#FF7A90'", 'fashion accent token');
forbidIncludes(tokenSource, "'#0F766E'", 'old teal primary');
forbidIncludes(tokenSource, "'#115E59'", 'old teal primaryStrong');
```

**Step 2: Run test, confirm RED / 运行测试，确认 RED**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: FAIL because `Tokens.ets` still uses the old teal palette.

预期：失败，因为 `Tokens.ets` 仍使用旧的青绿色调色板。

**Step 3: Implement minimal theme tokens / 最小实现主题 Token**

Update `AppThemeColorTokens` and `AppTheme` in `entry/src/main/ets/theme/Tokens.ets`:

更新 `entry/src/main/ets/theme/Tokens.ets` 中的 `AppThemeColorTokens` 和 `AppTheme`：

- Add `primaryPressed`, `primarySoft`, `surfaceRaised`, `success`, `warning`, and `accent`.
- 新增 `primaryPressed`、`primarySoft`、`surfaceRaised`、`success`、`warning` 和 `accent`。
- Set `primary` to `#4894FE`.
- 将 `primary` 设置为 `#4894FE`。
- Set `primaryStrong` to `#246BFE` for compatibility with existing callers.
- 将 `primaryStrong` 设置为 `#246BFE`，兼容现有调用方。
- Set background and neutral colors to the design doc values.
- 将背景和中性色设置为设计文档中的值。

**Step 4: Run test, confirm GREEN / 运行测试，确认 GREEN**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: PASS with no output.

预期：无输出，退出码为 0。

**Step 5: Commit / 提交**

```bash
git add entry/src/main/ets/theme/Tokens.ets scripts/validate-ui-refresh.mjs && git commit -m "style: add blue wardrobe theme tokens"
```

## Task 2: Refresh Core Display Components / 刷新核心展示组件

**Files / 文件：**

- Modify: `scripts/validate-ui-refresh.mjs`
- Modify: `entry/src/main/ets/components/ClothingCard.ets`
- Modify: `entry/src/main/ets/components/OutfitCard.ets`
- Modify: `entry/src/main/ets/components/WishlistCard.ets`

**Step 1: Extend failing validation / 扩展失败校验**

Extend `scripts/validate-ui-refresh.mjs`:

扩展 `scripts/validate-ui-refresh.mjs`：

```js
const componentFiles = [
  'entry/src/main/ets/components/ClothingCard.ets',
  'entry/src/main/ets/components/OutfitCard.ets',
  'entry/src/main/ets/components/WishlistCard.ets'
];

for (const file of componentFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, "import { AppTheme } from '../theme/Tokens';", `${file} theme import`);
  requireIncludes(source, 'AppTheme.color.', `${file} theme colors`);
  requireIncludes(source, 'AppTheme.radius.', `${file} theme radius`);
  forbidIncludes(source, "'#0F766E'", `${file} old teal`);
  forbidIncludes(source, "'#0F172A'", `${file} old near-black action`);
  forbidIncludes(source, "'#E2E8F0'", `${file} old slate border`);
}
```

**Step 2: Run test, confirm RED / 运行测试，确认 RED**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: FAIL because the three card components still hardcode old colors and do not all import `AppTheme`.

预期：失败，因为三个卡片组件仍硬编码旧颜色，并且并非全部导入 `AppTheme`。

**Step 3: Implement component refresh / 实现组件刷新**

Update the components as follows:

按以下方式更新组件：

- `ClothingCard.ets`
  - Import `AppTheme`.
  - Use `AppTheme.color.surfaceRaised`, `border`, `text`, `textMuted`, `primarySoft`, and `primary`.
  - Keep the two-column product-card footprint.
  - Turn category text into a small blue soft label.
- `OutfitCard.ets`
  - Import `AppTheme`.
  - Use `AppTheme.color.primarySoft` for the empty cover.
  - Add a compact item-count badge using `primarySoft` and `primary`.
  - Keep title one-line ellipsis.
- `WishlistCard.ets`
  - Import `AppTheme`.
  - Use ecommerce list-card hierarchy: left thumbnail, right content, price in `success`.
  - Use `primarySoft` for empty thumbnail and `accent` only for small wishlist/status emphasis if needed.

**Step 4: Run test, confirm GREEN / 运行测试，确认 GREEN**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: PASS.

预期：通过。

**Step 5: Commit / 提交**

```bash
git add scripts/validate-ui-refresh.mjs entry/src/main/ets/components/ClothingCard.ets entry/src/main/ets/components/OutfitCard.ets entry/src/main/ets/components/WishlistCard.ets && git commit -m "style: refresh wardrobe content cards"
```

## Task 3: Refresh Search, Tabs, Calendar, And Empty States / 刷新搜索、分类、日历和空态

**Files / 文件：**

- Modify: `scripts/validate-ui-refresh.mjs`
- Modify: `entry/src/main/ets/components/SearchBar.ets`
- Modify: `entry/src/main/ets/components/CategoryTabs.ets`
- Modify: `entry/src/main/ets/components/MonthCalendar.ets`
- Modify: `entry/src/main/ets/components/EmptyState.ets`

**Step 1: Extend failing validation / 扩展失败校验**

Extend `scripts/validate-ui-refresh.mjs`:

扩展 `scripts/validate-ui-refresh.mjs`：

```js
const controlFiles = [
  'entry/src/main/ets/components/SearchBar.ets',
  'entry/src/main/ets/components/CategoryTabs.ets',
  'entry/src/main/ets/components/MonthCalendar.ets',
  'entry/src/main/ets/components/EmptyState.ets'
];

for (const file of controlFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, "import { AppTheme } from '../theme/Tokens';", `${file} theme import`);
  requireIncludes(source, 'AppTheme.color.', `${file} theme colors`);
  forbidIncludes(source, "'#0F172A'", `${file} old selected state`);
  forbidIncludes(source, "'#E2E8F0'", `${file} old border`);
}

requireIncludes(
  fs.readFileSync('entry/src/main/ets/components/MonthCalendar.ets', 'utf8'),
  'AppTheme.color.primary',
  'MonthCalendar selected blue'
);
```

**Step 2: Run test, confirm RED / 运行测试，确认 RED**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: FAIL because `MonthCalendar` and some controls still hardcode old selected and border colors.

预期：失败，因为 `MonthCalendar` 和部分控件仍硬编码旧选中态和边框色。

**Step 3: Implement control refresh / 实现控件刷新**

Update:

更新：

- `SearchBar.ets`
  - Keep 44 height.
  - Use `surface`, `border`, `text`, `textDisabled`.
  - Use `radius.lg` for a softer mobile search field.
- `CategoryTabs.ets`
  - Selected chip: `primary` background, white text.
  - Inactive chip: white background, `textMuted`.
  - Use `primarySoft` for subtle selected border/fill if a filled pill is visually too heavy.
- `MonthCalendar.ets`
  - Selected date: `primary` background, white text.
  - Marked date: `primary` border or small blue marker text.
  - Default date: white background, `border`.
- `EmptyState.ets`
  - Use `surfaceRaised`, `primarySoft`, `text`, `textMuted`.
  - Keep a compact card; do not add decorative large illustrations.

**Step 4: Run test, confirm GREEN / 运行测试，确认 GREEN**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: PASS.

预期：通过。

**Step 5: Commit / 提交**

```bash
git add scripts/validate-ui-refresh.mjs entry/src/main/ets/components/SearchBar.ets entry/src/main/ets/components/CategoryTabs.ets entry/src/main/ets/components/MonthCalendar.ets entry/src/main/ets/components/EmptyState.ets && git commit -m "style: refresh wardrobe controls"
```

## Task 4: Refresh Main Page Shells / 刷新主页面壳

**Files / 文件：**

- Modify: `scripts/validate-ui-refresh.mjs`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/TodayPage.ets`
- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Modify: `entry/src/main/ets/pages/OutfitsPage.ets`
- Modify: `entry/src/main/ets/pages/CalendarPage.ets`
- Modify: `entry/src/main/ets/pages/ShoppingPage.ets`

**Step 1: Extend failing validation / 扩展失败校验**

Extend `scripts/validate-ui-refresh.mjs`:

扩展 `scripts/validate-ui-refresh.mjs`：

```js
const mainPageFiles = [
  'entry/src/main/ets/pages/Index.ets',
  'entry/src/main/ets/pages/TodayPage.ets',
  'entry/src/main/ets/pages/WardrobePage.ets',
  'entry/src/main/ets/pages/OutfitsPage.ets',
  'entry/src/main/ets/pages/CalendarPage.ets',
  'entry/src/main/ets/pages/ShoppingPage.ets'
];

for (const file of mainPageFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, "import { AppTheme } from '../theme/Tokens';", `${file} theme import`);
  requireIncludes(source, 'AppTheme.color.', `${file} theme colors`);
  forbidIncludes(source, "'#0F172A'", `${file} old black primary action`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}
```

**Step 2: Run test, confirm RED / 运行测试，确认 RED**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: FAIL because the main pages still hardcode old colors and black primary actions.

预期：失败，因为主页面仍硬编码旧颜色和黑色主按钮。

**Step 3: Implement page refresh / 实现页面刷新**

Update pages:

更新页面：

- `Index.ets`
  - Keep runtime wiring unchanged.
  - Apply `AppTheme` to initialization state.
  - Set Tabs background/bar surface using available ArkUI tab attributes.
- `TodayPage.ets`
  - Import `AppTheme`.
  - Use compact header, `surfaceMuted` background, and a `primarySoft` today-status card.
  - Primary actions use `primary`; secondary text uses `textMuted`.
- `WardrobePage.ets`
  - Import `AppTheme`.
  - Use blue primary add button.
  - Keep two-column product grid and existing search/category behavior.
- `OutfitsPage.ets`
  - Import `AppTheme`.
  - Use primary create button and secondary blue outline record button.
- `CalendarPage.ets`
  - Import `AppTheme`.
  - Use white calendar card and blue action button.
  - Selected-day records should read as lightweight schedule cards.
- `ShoppingPage.ets`
  - Import `AppTheme`.
  - Use blue add button and refreshed list spacing.

**Step 4: Run test, confirm GREEN / 运行测试，确认 GREEN**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: PASS.

预期：通过。

**Step 5: Commit / 提交**

```bash
git add scripts/validate-ui-refresh.mjs entry/src/main/ets/pages/Index.ets entry/src/main/ets/pages/TodayPage.ets entry/src/main/ets/pages/WardrobePage.ets entry/src/main/ets/pages/OutfitsPage.ets entry/src/main/ets/pages/CalendarPage.ets entry/src/main/ets/pages/ShoppingPage.ets && git commit -m "style: refresh wardrobe main screens"
```

## Task 5: Refresh Edit And Picker Flows / 刷新编辑和选择流程

**Files / 文件：**

- Modify: `scripts/validate-ui-refresh.mjs`
- Modify: `entry/src/main/ets/pages/ClothingEditPage.ets`
- Modify: `entry/src/main/ets/pages/OutfitEditPage.ets`
- Modify: `entry/src/main/ets/pages/WearLogEditPage.ets`
- Modify: `entry/src/main/ets/pages/WishlistEditPage.ets`
- Modify: `entry/src/main/ets/pages/SearchResultsPage.ets`
- Modify: `entry/src/main/ets/components/ClothingPicker.ets`
- Modify: `entry/src/main/ets/components/OutfitPicker.ets`
- Modify: `entry/src/main/ets/components/PhotoGrid.ets`

**Step 1: Extend failing validation / 扩展失败校验**

Extend `scripts/validate-ui-refresh.mjs`:

扩展 `scripts/validate-ui-refresh.mjs`：

```js
const flowFiles = [
  'entry/src/main/ets/pages/ClothingEditPage.ets',
  'entry/src/main/ets/pages/OutfitEditPage.ets',
  'entry/src/main/ets/pages/WearLogEditPage.ets',
  'entry/src/main/ets/pages/WishlistEditPage.ets',
  'entry/src/main/ets/pages/SearchResultsPage.ets',
  'entry/src/main/ets/components/ClothingPicker.ets',
  'entry/src/main/ets/components/OutfitPicker.ets',
  'entry/src/main/ets/components/PhotoGrid.ets'
];

for (const file of flowFiles) {
  const source = fs.readFileSync(file, 'utf8');
  requireIncludes(source, "AppTheme", `${file} theme usage`);
  forbidIncludes(source, "'#0F172A'", `${file} old black primary action`);
  forbidIncludes(source, "'#F8FAFC'", `${file} old background`);
  forbidIncludes(source, "'#B91C1C'", `${file} old danger`);
}
```

**Step 2: Run test, confirm RED / 运行测试，确认 RED**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: FAIL because edit and picker flows still use old hardcoded colors.

预期：失败，因为编辑和选择流程仍使用旧的硬编码颜色。

**Step 3: Implement flow refresh / 实现流程刷新**

Update edit and picker flows:

更新编辑和选择流程：

- Import `AppTheme` where missing.
- 缺失处导入 `AppTheme`。
- Primary save/add buttons use `AppTheme.color.primary`; disabled uses `disabled`.
- 主保存/添加按钮使用 `AppTheme.color.primary`；禁用态使用 `disabled`。
- Cancel/secondary buttons use white surface, blue or neutral text, and token border.
- 取消/次级按钮使用白色表面、蓝色或中性色文字、token 边框。
- Error text uses `danger`.
- 错误文字使用 `danger`。
- Page backgrounds use `surfaceMuted`.
- 页面背景使用 `surfaceMuted`。
- Picker selected states use `primary` instead of near-black.
- 选择器选中态使用 `primary`，不再使用近黑色。

**Step 4: Run test, confirm GREEN / 运行测试，确认 GREEN**

Command:

```bash
node scripts/validate-ui-refresh.mjs
```

Expected: PASS.

预期：通过。

**Step 5: Commit / 提交**

```bash
git add scripts/validate-ui-refresh.mjs entry/src/main/ets/pages/ClothingEditPage.ets entry/src/main/ets/pages/OutfitEditPage.ets entry/src/main/ets/pages/WearLogEditPage.ets entry/src/main/ets/pages/WishlistEditPage.ets entry/src/main/ets/pages/SearchResultsPage.ets entry/src/main/ets/components/ClothingPicker.ets entry/src/main/ets/components/OutfitPicker.ets entry/src/main/ets/components/PhotoGrid.ets && git commit -m "style: refresh wardrobe edit flows"
```

## Task 6: Run Visual Build Verification / 运行视觉构建验证

**Files / 文件：**

- No source changes expected.
- 预期不修改源码。

**Step 1: Run all validation scripts / 运行全部校验脚本**

Command:

```bash
for script in scripts/*.mjs; do node "$script"; done
```

Expected: PASS.

预期：通过。

**Step 2: Check whitespace / 检查空白**

Command:

```bash
git diff --check
```

Expected: PASS.

预期：通过。

**Step 3: Build HAP / 构建 HAP**

Command:

```bash
/Users/seminzhu/Downloads/command-line-tools/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
```

Expected: PASS.

预期：通过。

**Step 4: Build App / 构建 App**

Command:

```bash
/Users/seminzhu/Downloads/command-line-tools/bin/hvigorw assembleApp --no-daemon --no-incremental --no-parallel --stacktrace
```

Expected: PASS.

预期：通过。

**Step 5: Emulator smoke test / 模拟器冒烟测试**

Commands:

```bash
HDC=/Users/seminzhu/Downloads/command-line-tools/sdk/default/openharmony/toolchains/hdc
$HDC list targets
$HDC install -r entry/build/default/outputs/default/entry-default-unsigned.hap
$HDC shell hilog -r
$HDC shell aa force-stop com.harmonywardrobe.app
$HDC shell aa start -a EntryAbility -b com.harmonywardrobe.app
sleep 4
$HDC shell snapshot_display -f /data/local/tmp/harmony_wardrobe_ui_refresh.jpeg
$HDC file recv /data/local/tmp/harmony_wardrobe_ui_refresh.jpeg /tmp/harmony_wardrobe_ui_refresh.jpeg
```

Expected:

- App launches without white screen.
- Today screen shows blue refreshed styling.
- No runtime database error appears in hilog.

预期：

- App 启动后不白屏。
- Today 页面显示蓝色改版样式。
- hilog 中没有运行时数据库错误。

**Step 6: Commit only if verification required a small fix / 如验证修复了小问题才提交**

If a verification-only fix was needed:

如果验证阶段产生了小修复：

```bash
git add <fixed-files> && git commit -m "fix: polish ui refresh verification"
```

Otherwise do not create an empty commit.

否则不要创建空提交。
