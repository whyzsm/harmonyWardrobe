# Xiaohongshu Home And Wardrobe Navigation Implementation Plan

> **For implementer:** Use TDD throughout. Write failing test first. Watch it fail. Then implement.

## 中文

**目标：** 将底部导航改为 `首页 / 套装 / + / 日历 / 逛街`，并把首页和衣橱页改成小红书式内容流。

**架构：** 保持现有 ArkUI 页面结构，继续使用 `Tabs` 管理主页面。`WardrobePage` 保留为第三个 `TabContent`，但 tabBar 改成中间凸起的 `+`。首页内容流和衣橱内容流通过现有页面与卡片组件局部重构完成。

**技术栈：** HarmonyOS ArkTS、ArkUI、现有 Node 静态验证脚本、现有 `AppTheme` token。

## English

**Goal:** Change the bottom navigation to `首页 / 套装 / + / 日历 / 逛街` and refresh the home and wardrobe pages into Xiaohongshu-style content feeds.

**Architecture:** Keep the current ArkUI page structure and continue using `Tabs` for main navigation. `WardrobePage` remains the third `TabContent`, but its tabBar becomes the raised center `+`. The home feed and wardrobe feed are implemented through scoped refactors of existing pages and card components.

**Tech Stack:** HarmonyOS ArkTS, ArkUI, existing Node static validation scripts, and existing `AppTheme` tokens.

---

## Task 1: Navigation Contract

## 中文

**文件：**
- 修改：`scripts/validate-navigation.mjs`
- 修改：`entry/src/main/ets/pages/Index.ets`

**步骤：**
1. 修改 `scripts/validate-navigation.mjs`，要求 `Index.ets` 包含 `首页 / 套装 / + / 日历 / 逛街`，不再要求普通 `衣橱` tab。
2. 运行 `node scripts/validate-navigation.mjs`，确认 RED。
3. 修改 `Index.ets`：将第一 tab 文案改为 `首页`，第三 tab 改为 `WardrobePage` 并使用自定义中间 `+` tabBar，移除普通 `衣橱` tab。
4. 运行 `node scripts/validate-navigation.mjs`，确认 GREEN。
5. 提交：`git add scripts/validate-navigation.mjs entry/src/main/ets/pages/Index.ets && git commit -m "style: add xhs center wardrobe navigation"`

## English

**Files:**
- Modify: `scripts/validate-navigation.mjs`
- Modify: `entry/src/main/ets/pages/Index.ets`

**Steps:**
1. Update `scripts/validate-navigation.mjs` so `Index.ets` must contain `首页 / 套装 / + / 日历 / 逛街` and no longer requires a regular `衣橱` tab.
2. Run `node scripts/validate-navigation.mjs` and confirm RED.
3. Update `Index.ets`: rename the first tab to `首页`, make the third tab `WardrobePage` with a custom center `+` tabBar, and remove the regular `衣橱` tab.
4. Run `node scripts/validate-navigation.mjs` and confirm GREEN.
5. Commit: `git add scripts/validate-navigation.mjs entry/src/main/ets/pages/Index.ets && git commit -m "style: add xhs center wardrobe navigation"`

## Task 2: Home Discovery Feed

## 中文

**文件：**
- 新建：`scripts/validate-xhs-home-feed.mjs`
- 修改：`entry/src/main/ets/pages/TodayPage.ets`

**步骤：**
1. 新建验证脚本，检查 `推荐 / 今日 / 灵感`、`今天穿什么？`、`从最近套装里挑一套`、`记录一次今日搭配`、双列 `Grid`、`AppTheme.color.primary` 下划线。
2. 运行 `node scripts/validate-xhs-home-feed.mjs`，确认 RED。
3. 修改 `TodayPage.ets`：保留数据加载逻辑，改顶部频道和双列内容流卡片，空态使用内容流占位。
4. 运行 `node scripts/validate-xhs-home-feed.mjs`，确认 GREEN。
5. 提交：`git add scripts/validate-xhs-home-feed.mjs entry/src/main/ets/pages/TodayPage.ets && git commit -m "style: refresh home as discovery feed"`

## English

**Files:**
- Create: `scripts/validate-xhs-home-feed.mjs`
- Modify: `entry/src/main/ets/pages/TodayPage.ets`

**Steps:**
1. Create a validation script that checks for `推荐 / 今日 / 灵感`, `今天穿什么？`, `从最近套装里挑一套`, `记录一次今日搭配`, a two-column `Grid`, and an `AppTheme.color.primary` underline.
2. Run `node scripts/validate-xhs-home-feed.mjs` and confirm RED.
3. Update `TodayPage.ets`: keep the data loading logic, but change the top channel bar and two-column feed cards, using feed placeholders for empty states.
4. Run `node scripts/validate-xhs-home-feed.mjs` and confirm GREEN.
5. Commit: `git add scripts/validate-xhs-home-feed.mjs entry/src/main/ets/pages/TodayPage.ets && git commit -m "style: refresh home as discovery feed"`

## Task 3: Wardrobe Content Feed Cards

## 中文

**文件：**
- 新建：`scripts/validate-xhs-wardrobe-feed.mjs`
- 修改：`entry/src/main/ets/pages/WardrobePage.ets`
- 修改：`entry/src/main/ets/components/ClothingCard.ets`
- 修改：`entry/src/main/ets/components/OutfitCard.ets`

**步骤：**
1. 新建验证脚本，检查衣橱页文案、浅灰搜索占位、`鞋包` 分类、`点中间 + 添加第一件衣服` 空态、卡片无厚边框、图片主导样式。
2. 运行 `node scripts/validate-xhs-wardrobe-feed.mjs`，确认 RED。
3. 修改衣橱页与卡片组件：弱化 `添加衣服` 按钮，分类改为 `鞋包`，卡片去边框并增加轻阴影，空态改内容流占位。
4. 运行 `node scripts/validate-xhs-wardrobe-feed.mjs`，确认 GREEN。
5. 提交：`git add scripts/validate-xhs-wardrobe-feed.mjs entry/src/main/ets/pages/WardrobePage.ets entry/src/main/ets/components/ClothingCard.ets entry/src/main/ets/components/OutfitCard.ets && git commit -m "style: refresh wardrobe as content feed"`

## English

**Files:**
- Create: `scripts/validate-xhs-wardrobe-feed.mjs`
- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Modify: `entry/src/main/ets/components/ClothingCard.ets`
- Modify: `entry/src/main/ets/components/OutfitCard.ets`

**Steps:**
1. Create a validation script that checks wardrobe page copy, the light search affordance, the `鞋包` category, the `点中间 + 添加第一件衣服` empty state, borderless cards, and image-led styling.
2. Run `node scripts/validate-xhs-wardrobe-feed.mjs` and confirm RED.
3. Update the wardrobe page and card components: soften the `添加衣服` button, rename the category to `鞋包`, remove thick borders from cards, add subtle shadow, and change the empty state into a feed placeholder.
4. Run `node scripts/validate-xhs-wardrobe-feed.mjs` and confirm GREEN.
5. Commit: `git add scripts/validate-xhs-wardrobe-feed.mjs entry/src/main/ets/pages/WardrobePage.ets entry/src/main/ets/components/ClothingCard.ets entry/src/main/ets/components/OutfitCard.ets && git commit -m "style: refresh wardrobe as content feed"`

## Task 4: Final Verification

## 中文

**文件：**
- 只读验证。

**步骤：**
1. 运行 `for script in scripts/*.mjs; do node "$script"; done`。
2. 运行 `git diff --check`。
3. 运行 HarmonyOS HAP/App 构建。
4. 如有模拟器，安装启动并截图确认不是白屏。

## English

**Files:**
- Read-only verification.

**Steps:**
1. Run `for script in scripts/*.mjs; do node "$script"; done`.
2. Run `git diff --check`.
3. Run the HarmonyOS HAP/App builds.
4. If an emulator is available, install, launch, and capture a screenshot to confirm the app is not blank.
