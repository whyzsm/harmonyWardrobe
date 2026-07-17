# 衣不缺个人衣橱改版执行计划

> **For implementer:** 采用 validation-first。每个任务先补或更新验证脚本，确认失败，再做最小实现让验证通过。

**设计依据：**

- 产品设计：`docs/plans/2026-07-04-yibuque-personal-wardrobe-design.md`
- UI 合同：`docs/background/yibuque-design.md`

**目标：** 交付第一版可用的 `衣不缺`：主导航为 `衣橱 / + / 逛店`，衣橱内有 `衣裤 / 美搭`，用户可拍/选衣服、拍/选搭配、登记逛店记录，并维护本地个人信息。

**架构方向：** 保持现有 HarmonyOS ArkTS、本地 SQLite、PhotoStorage 和验证脚本体系。新增 `Store`、`StoreVisit`、`UserProfile` 领域/数据/页面能力；旧 wishlist 表保留但从主流程停用。

---

## 总约束

- 不新增网络权限、远端 API 或登录账号体系。
- 不把照片二进制写入 SQLite，只保存本地 URI/path。
- 不在本轮删除 `wishlist_items`、`wishlist_photos` 旧表。
- 不回滚或清理无关本地改动。
- 页面和组件实现必须优先使用 `entry/src/main/ets/theme/Tokens.ets` 中的语义 token。
- 新主操作统一黑色胶囊按钮；蓝色/薄荷绿只作为柔和背景或状态色。
- 用户界面不出现推荐流、点赞、收藏、评论、关注等伪社交动作。
- 用户界面主文案使用 `美搭` / `搭配`，不把 `穿搭` 作为主要用户文案。

## 里程碑顺序

1. 建立产品范围、视觉系统和旧概念回归保护。
2. 落地 `衣不缺` token 与共享导航/快捷组件。
3. 改造 App 壳层：顶部工具栏、底部主导航、快捷面板。
4. 改造衣橱页：`衣裤 / 美搭` 二级 tab 与图片优先卡片。
5. 新增 Store / StoreVisit / UserProfile 数据基础。
6. 实现逛店记录页面和 `拍店铺` 流程。
7. 实现我的页面和个人信息保存。
8. 清理旧主入口与搜索展示文案，补齐 QA。

## Task 1: 建立产品范围和视觉回归验证

**Files:**

- Create or modify: `scripts/validate-yibuque-product-scope.mjs`
- Create: `scripts/validate-yibuque-visual-system.mjs`
- Modify only if needed: `scripts/validate-runtime-wiring.mjs`

**Step 1: 写失败验证**

`validate-yibuque-product-scope.mjs` 覆盖：

- `Index.ets` 包含 `衣不缺`、`衣橱`、`逛店`、`拍衣服`、`拍搭配`、`拍店铺`。
- `Index.ets` 不再把 `首页`、`日历`、`逛街` 作为底部主导航。
- `WardrobePage.ets` 包含 `衣裤`、`美搭`。
- 主流程不暴露 `心愿单`。
- 可达主界面不暴露 `点赞`、`收藏`、`评论`、`关注`。
- 旧 wishlist 文件可以存在，但不能从 `Index.ets` 主流程进入。

`validate-yibuque-visual-system.mjs` 覆盖：

- `Tokens.ets` 包含 `actionBlack`、`bgBlueGray`、`cardBlue`、`cardMint`、`borderStrong`、`full`、`sheet` 等设计 token。
- `AppTopBar`、`BottomNavigationBar`、`QuickCaptureSheet` 组件存在或被计划内验证引用。
- 黑色主操作、大圆角卡片、轻阴影、44 高触达区域有静态约束。
- 视觉合同文件 `docs/background/yibuque-design.md` 存在。

**Step 2: 运行验证并确认失败**

```bash
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-yibuque-visual-system.mjs
```

Expected: FAIL。当前代码还没有完成新导航、视觉 token 和共享组件。

**Step 3: 本任务只提交验证**

```bash
git add scripts/validate-yibuque-product-scope.mjs scripts/validate-yibuque-visual-system.mjs scripts/validate-runtime-wiring.mjs
git commit -m "test: add yibuque product and visual guards"
```

## Task 2: 落地设计 token 和共享 UI 组件

**Files:**

- Modify: `entry/src/main/ets/theme/Tokens.ets`
- Create: `entry/src/main/ets/components/AppTopBar.ets`
- Create: `entry/src/main/ets/components/BottomNavigationBar.ets`
- Create: `entry/src/main/ets/components/QuickCaptureSheet.ets`
- Modify: `scripts/validate-yibuque-visual-system.mjs`

**Step 1: 运行失败验证**

```bash
node scripts/validate-yibuque-visual-system.mjs
```

**Step 2: 实现 token**

在 `Tokens.ets` 中保留现有 `AppTheme` 兼容字段，同时新增或扩展 `YibuqueColor`、`YibuqueFontSize`、`YibuqueLineHeight`、`YibuqueSpacing`、`YibuqueRadius`、`YibuqueShadow`。

必须覆盖：

- 色彩：白底、极浅蓝灰、浅蓝、薄荷绿、黑色主操作、黑色标题、灰色元信息、浅边框。
- 字体：App 名称 18-20、页面标题 24、卡片标题 18-21、正文 16、元信息 14。
- 间距：页面左右 20-24、卡片 20-28、分区 28-40。
- 圆角：主卡片 24-32、Sheet 32-36、按钮/Tab/Chip 胶囊。
- 阴影：仅轻阴影，不做厚重卡片阴影。

**Step 3: 实现共享组件**

- `AppTopBar`：左侧 logo 占位 + `衣不缺`，右侧头像/我的入口，触达区域 44-48。
- `BottomNavigationBar`：只接受 `衣橱`、`+`、`逛店` 三个主入口；选中黑色，未选浅灰，中间 `+` 黑底白字。
- `QuickCaptureSheet`：白色 Sheet，顶部大圆角，包含 `拍衣服`、`拍搭配`、`拍店铺` 三个大触达动作。

**Step 4: 运行验证**

```bash
node scripts/validate-yibuque-visual-system.mjs
git diff --check
```

Expected: PASS。

**Step 5: Commit**

```bash
git add entry/src/main/ets/theme/Tokens.ets entry/src/main/ets/components/AppTopBar.ets entry/src/main/ets/components/BottomNavigationBar.ets entry/src/main/ets/components/QuickCaptureSheet.ets scripts/validate-yibuque-visual-system.mjs
git commit -m "feat: add yibuque visual system primitives"
```

## Task 3: 改造 App 壳层导航和快捷入口

**Files:**

- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `scripts/validate-yibuque-product-scope.mjs`
- Modify if needed: `scripts/validate-runtime-wiring.mjs`

**Step 1: 运行失败验证**

```bash
node scripts/validate-yibuque-product-scope.mjs
```

**Step 2: 实现壳层**

- 顶部常驻 `AppTopBar`，左侧 `logo + 衣不缺`，右侧头像/我的入口。
- 底部只保留 `衣橱 / + / 逛店`。
- `+` 打开 `QuickCaptureSheet`。
- `拍衣服` 进入衣物创建流程。
- `拍搭配` 进入美搭创建流程。
- `拍店铺` 暂时进入受保护占位状态，Task 7 完成后改为逛店记录编辑页。
- 移除主流程对 `TodayPage`、`CalendarPage`、`ShoppingPage` 的导航。

**Step 3: 视觉要求**

- 中间 `+` 是黑色圆角方形或胶囊按钮。
- 底部为系统安全区预留空间。
- 顶部和底部触达区域不小于 44。
- 不在壳层放推荐流、社交指标或电商入口。

**Step 4: 运行验证**

```bash
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-yibuque-visual-system.mjs
```

Expected: PASS for shell rules。

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets scripts/validate-yibuque-product-scope.mjs scripts/validate-runtime-wiring.mjs
git commit -m "feat: update yibuque app shell"
```

## Task 4: 改造衣橱页为 衣裤 / 美搭

**Files:**

- Modify: `entry/src/main/ets/pages/WardrobePage.ets`
- Modify: `entry/src/main/ets/pages/OutfitEditPage.ets`
- Modify: `entry/src/main/ets/components/ClothingCard.ets`
- Modify: `entry/src/main/ets/components/OutfitCard.ets`
- Modify: `entry/src/main/ets/components/CategoryTabs.ets`
- Modify: `entry/src/main/ets/components/EmptyState.ets`
- Modify: `scripts/validate-wardrobe-page.mjs`
- Create or modify: `scripts/validate-outfit-copy.mjs`

**Step 1: 写/更新失败验证**

验证要求：

- `WardrobePage.ets` 有 `衣裤`、`美搭` tab 状态。
- `衣裤` 展示衣物列表、搜索、分类筛选和空态。
- 分类为 `上衣`、`裤子`、`短裤`、`长裙`、`半裙`。
- `美搭` 展示搭配列表，空态指向 `+ / 拍搭配`。
- 可见文案使用 `美搭` 或 `搭配`，不把 `穿搭` 作为主要用户文案。
- `OutfitEditPage` 支持照片型搭配：有标题且有照片时可以保存，即使未关联衣物。
- 衣物卡片和美搭卡片图片优先、有圆角，缺图使用柔和占位。

**Step 2: 运行验证并确认失败**

```bash
node scripts/validate-wardrobe-page.mjs
node scripts/validate-outfit-copy.mjs
```

**Step 3: 实现**

- `WardrobePage` 内部维护 `selectedWardrobeTab: '衣裤' | '美搭'`。
- `衣裤` 复用现有衣物数据、搜索和分类逻辑。
- `美搭` 使用 `OutfitRepository.listOutfits()` 加载搭配。
- 卡片视觉对齐 `docs/background/yibuque-design.md`：大圆角、轻阴影、图片圆角、黑色标题、灰色元信息。
- 空态明确引导底部 `+` 的 `拍衣服` / `拍搭配`。

**Step 4: 运行验证**

```bash
node scripts/validate-wardrobe-page.mjs
node scripts/validate-outfit-copy.mjs
node scripts/validate-yibuque-product-scope.mjs
git diff --check
```

Expected: PASS。

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/WardrobePage.ets entry/src/main/ets/pages/OutfitEditPage.ets entry/src/main/ets/components/ClothingCard.ets entry/src/main/ets/components/OutfitCard.ets entry/src/main/ets/components/CategoryTabs.ets entry/src/main/ets/components/EmptyState.ets scripts/validate-wardrobe-page.mjs scripts/validate-outfit-copy.mjs
git commit -m "feat: add wardrobe clothing and outfit tabs"
```

## Task 5: 新增 Store / StoreVisit / UserProfile 数据基础

**Files:**

- Create: `entry/src/main/ets/domain/store/StoreModels.ets`
- Create: `entry/src/main/ets/domain/profile/ProfileModels.ets`
- Create: `entry/src/main/ets/data/migrations/V3StoreVisitSchema.ets`
- Modify: `entry/src/main/ets/app/WardrobeRuntime.ets`
- Create: `scripts/validate-store-domain.mjs`
- Create: `scripts/validate-profile-domain.mjs`
- Create: `scripts/validate-store-visit-migration.mjs`
- Modify: `scripts/validate-domain-models.mjs`
- Modify: `scripts/validate-runtime-wiring.mjs`

**Step 1: 写失败验证**

`Store` 字段：

- `id`
- `name`
- `districtOrAddress`
- `photoUris`
- `note`
- `createdAt`
- `updatedAt`

`StoreVisit` 字段：

- `id`
- `storeId`
- `storeNameSnapshot`
- `visitDate`
- `photoUris`
- `note`
- `createdAt`
- `updatedAt`

`UserProfile` 字段：

- `heightCm`
- `weightKg`
- `waistCm`
- `updatedAt`

迁移要求：

- 新增 `stores`、`store_photos`、`store_visits`、`store_visit_photos`、`user_profile`。
- 为 `store_visits.visit_date`、`store_visits.store_id`、`store_photos.store_id`、`store_visit_photos.store_visit_id` 建索引。
- 不 drop 旧 wishlist 表。
- 迁移接入 `WardrobeRuntime.create()`。

**Step 2: 运行验证并确认失败**

```bash
node scripts/validate-store-domain.mjs
node scripts/validate-profile-domain.mjs
node scripts/validate-store-visit-migration.mjs
node scripts/validate-domain-models.mjs
node scripts/validate-runtime-wiring.mjs
```

**Step 3: 实现**

- 领域模型只定义类型，不依赖 ArkUI、SQLite 或 PhotoStorage。
- `V3StoreVisitSchema` 使用幂等 `CREATE TABLE IF NOT EXISTS`、`CREATE INDEX IF NOT EXISTS`。
- `StoreVisit.storeNameSnapshot` 必须保留，避免店铺改名后旧记录不可读。

**Step 4: 运行验证**

```bash
node scripts/validate-store-domain.mjs
node scripts/validate-profile-domain.mjs
node scripts/validate-store-visit-migration.mjs
node scripts/validate-domain-models.mjs
node scripts/validate-runtime-wiring.mjs
git diff --check
```

Expected: PASS。

**Step 5: Commit**

```bash
git add entry/src/main/ets/domain/store/StoreModels.ets entry/src/main/ets/domain/profile/ProfileModels.ets entry/src/main/ets/data/migrations/V3StoreVisitSchema.ets entry/src/main/ets/app/WardrobeRuntime.ets scripts/validate-store-domain.mjs scripts/validate-profile-domain.mjs scripts/validate-store-visit-migration.mjs scripts/validate-domain-models.mjs scripts/validate-runtime-wiring.mjs
git commit -m "feat: add store visit and profile data contracts"
```

## Task 6: 新增 StoreRepository / ProfileRepository 和搜索契约

**Files:**

- Create: `entry/src/main/ets/data/repositories/StoreRepository.ets`
- Create: `entry/src/main/ets/data/repositories/ProfileRepository.ets`
- Modify: `entry/src/main/ets/app/WardrobeRuntime.ets`
- Modify if unified search remains: `entry/src/main/ets/domain/search/SearchModels.ets`
- Modify if unified search remains: `entry/src/main/ets/domain/search/SearchDocumentBuilder.ets`
- Modify if unified search remains: `entry/src/main/ets/data/repositories/SearchRepository.ets`
- Create: `scripts/validate-store-repository.mjs`
- Create: `scripts/validate-profile-repository.mjs`
- Modify: `scripts/validate-search-document-builder.mjs`
- Modify: `scripts/validate-search-repository.mjs`
- Modify: `scripts/validate-runtime-wiring.mjs`

**Step 1: 写失败验证**

`StoreRepository` 要求：

- 输入接口覆盖创建/更新店铺、创建/更新逛店记录。
- 方法：`createStore`、`updateStore`、`listStores`、`getStoreById`、`createStoreVisit`、`updateStoreVisit`、`listStoreVisits`、`getStoreVisitById`、`deleteStoreVisit`。
- 图片 URI 写入 `store_photos`、`store_visit_photos`。
- `listStoreVisits` 默认按 `visitDate / updatedAt` 倒序。
- repository 不 import `PhotoStorage`。

`ProfileRepository` 要求：

- 方法：`getProfile`、`saveProfile`。
- 使用单行 `user_profile`。
- 拒绝负数和非有限数值。

搜索要求：

- 如果统一搜索保留，新增 `Store`、`StoreVisit` 搜索类型。
- 搜索展示文案使用 `店铺`、`逛店记录`，不再展示 `Wishlist`。

**Step 2: 运行验证并确认失败**

```bash
node scripts/validate-store-repository.mjs
node scripts/validate-profile-repository.mjs
node scripts/validate-search-document-builder.mjs
node scripts/validate-search-repository.mjs
node scripts/validate-runtime-wiring.mjs
```

**Step 3: 实现**

- 参考现有 repository 的事务、输入清洗、photo row hydration 模式。
- 逛店记录允许只有 `storeNameSnapshot`，不强制先存在店铺主数据。
- 店铺名匹配创建逻辑放在页面或 repository helper 中，但不要让页面写 SQL。
- Profile 保存时只持久化合法字段；非法字段返回错误或不保存并交给页面提示。

**Step 4: 运行验证**

```bash
node scripts/validate-store-repository.mjs
node scripts/validate-profile-repository.mjs
node scripts/validate-search-document-builder.mjs
node scripts/validate-search-repository.mjs
node scripts/validate-runtime-wiring.mjs
git diff --check
```

Expected: PASS。

**Step 5: Commit**

```bash
git add entry/src/main/ets/data/repositories/StoreRepository.ets entry/src/main/ets/data/repositories/ProfileRepository.ets entry/src/main/ets/app/WardrobeRuntime.ets entry/src/main/ets/domain/search/SearchModels.ets entry/src/main/ets/domain/search/SearchDocumentBuilder.ets entry/src/main/ets/data/repositories/SearchRepository.ets scripts/validate-store-repository.mjs scripts/validate-profile-repository.mjs scripts/validate-search-document-builder.mjs scripts/validate-search-repository.mjs scripts/validate-runtime-wiring.mjs
git commit -m "feat: add store visit and profile repositories"
```

## Task 7: 实现逛店页面和 拍店铺 流程

**Files:**

- Create: `entry/src/main/ets/pages/StoreVisitPage.ets`
- Create: `entry/src/main/ets/pages/StoreVisitEditPage.ets`
- Create: `entry/src/main/ets/components/StoreVisitCard.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Create: `scripts/validate-store-visit-page.mjs`
- Create: `scripts/validate-store-visit-edit-page.mjs`
- Modify: `scripts/validate-yibuque-product-scope.mjs`

**Step 1: 写失败验证**

页面要求：

- `StoreVisitPage` 标题为 `逛店`。
- 主列表展示逛店记录，不退化成店铺主数据表格。
- 支持按店铺名、地址/商圈、备注搜索。
- 空态提示从底部 `+ / 拍店铺` 添加。
- 记录卡片展示店铺名、日期、地址/商圈、首图、备注摘要。
- 首图有圆角；无图占位使用柔和底色和 `店` 字。

编辑页要求：

- 标题为 `记录逛店` 或 `编辑逛店`。
- 字段包含店铺名、日期、备注、照片。
- 支持选择或新建店铺。
- 保存通过 `StoreRepository` 创建/更新 `StoreVisit`。
- 保存后返回 `逛店` 列表并回显。
- 不 import `WishlistRepository`。

**Step 2: 运行验证并确认失败**

```bash
node scripts/validate-store-visit-page.mjs
node scripts/validate-store-visit-edit-page.mjs
node scripts/validate-yibuque-product-scope.mjs
```

**Step 3: 实现**

- `StoreVisitPage` 使用 `StoreRepository.listStoreVisits()`。
- `拍店铺` 进入 `StoreVisitEditPage`。
- 照片选择复用现有 PhotoViewPicker / PhotoStorage 流程。
- 店铺不存在时允许在保存逛店记录时创建店铺。
- 保存失败提示靠近保存按钮；照片复制失败保留原始 URI 并给非阻塞提示。

**Step 4: 视觉要求**

- 店铺名黑色粗体。
- 日期和地址使用中灰元信息。
- 卡片白底、大圆角、轻阴影或浅边框。
- 主按钮黑底白字胶囊，高度约 56。
- 表单字段有明确标签，不只依赖 placeholder。

**Step 5: 运行验证**

```bash
node scripts/validate-store-visit-page.mjs
node scripts/validate-store-visit-edit-page.mjs
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-yibuque-visual-system.mjs
git diff --check
```

Expected: PASS。

**Step 6: Commit**

```bash
git add entry/src/main/ets/pages/StoreVisitPage.ets entry/src/main/ets/pages/StoreVisitEditPage.ets entry/src/main/ets/components/StoreVisitCard.ets entry/src/main/ets/pages/Index.ets scripts/validate-store-visit-page.mjs scripts/validate-store-visit-edit-page.mjs scripts/validate-yibuque-product-scope.mjs
git commit -m "feat: add store visit flows"
```

## Task 8: 实现 我的 页面和个人信息保存

**Files:**

- Create: `entry/src/main/ets/pages/ProfilePage.ets`
- Modify: `entry/src/main/ets/pages/Index.ets`
- Create: `scripts/validate-profile-page.mjs`
- Modify: `scripts/validate-yibuque-visual-system.mjs`

**Step 1: 写失败验证**

验证要求：

- 页面标题或入口为 `我的`。
- 包含头像/昵称区域，可先本地静态展示。
- 字段：`身高`、`体重`、`腰围`。
- 包含 `设置` 入口。
- 使用 `ProfileRepository` 加载和保存。
- 保存按钮有 loading/禁用态。
- 非法数值在字段附近提示。
- `Index.ets` 右上角头像入口可打开 `ProfilePage`。

**Step 2: 运行验证并确认失败**

```bash
node scripts/validate-profile-page.mjs
```

**Step 3: 实现**

- 页面背景使用 `bgBlueGray`。
- 头像为大圆形占位，直径约 112。
- 个人信息字段放在白色大圆角卡片。
- 编辑资料/保存使用黑色胶囊按钮。
- 设置入口使用白色大圆角菜单卡，菜单项高度约 74。

**Step 4: 运行验证**

```bash
node scripts/validate-profile-page.mjs
node scripts/validate-profile-repository.mjs
node scripts/validate-yibuque-visual-system.mjs
git diff --check
```

Expected: PASS。

**Step 5: Commit**

```bash
git add entry/src/main/ets/pages/ProfilePage.ets entry/src/main/ets/pages/Index.ets scripts/validate-profile-page.mjs scripts/validate-yibuque-visual-system.mjs
git commit -m "feat: add profile measurements page"
```

## Task 9: 清理旧主流程概念和搜索展示

**Files:**

- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/ets/pages/SearchResultsPage.ets`
- Modify only if reachable: `entry/src/main/ets/pages/TodayPage.ets`
- Modify only if reachable: `entry/src/main/ets/pages/ShoppingPage.ets`
- Modify: `scripts/validate-yibuque-product-scope.mjs`
- Modify: `scripts/validate-search-document-builder.mjs`
- Modify: `scripts/validate-search-repository.mjs`

**Step 1: 运行验证**

```bash
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-search-document-builder.mjs
node scripts/validate-search-repository.mjs
```

Expected: FAIL if old primary UI copy remains。

**Step 2: 清理**

- 主流程不再出现 `首页` 推荐流、`日历` 主入口、`逛街` 主入口、`心愿单` 主入口。
- 搜索结果展示名调整为 `衣物`、`美搭`、`逛店记录`、`店铺`。
- `Wishlist` 类型如为兼容旧数据保留，只能隐藏在不可达旧代码或迁移兼容层。
- 用户可达页面不出现 `点赞`、`收藏`、`评论`、`关注` 等伪社交动作。
- `穿搭` 不再作为主要用户文案；代码层 `OutfitTemplate` 可暂时保留。

**Step 3: 运行验证**

```bash
node scripts/validate-yibuque-product-scope.mjs
node scripts/validate-search-document-builder.mjs
node scripts/validate-search-repository.mjs
git diff --check
```

Expected: PASS。

**Step 4: Commit**

```bash
git add entry/src/main/ets/pages/Index.ets entry/src/main/ets/pages/SearchResultsPage.ets entry/src/main/ets/pages/TodayPage.ets entry/src/main/ets/pages/ShoppingPage.ets scripts/validate-yibuque-product-scope.mjs scripts/validate-search-document-builder.mjs scripts/validate-search-repository.mjs
git commit -m "chore: remove old primary ui concepts"
```

## Task 10: 补齐 QA 脚本和交付验证

**Files:**

- Modify or create: `docs/qa/manual-test-script.md`
- Modify or create: `docs/delivery/first-release-verification.md`

**Step 1: 更新手工 QA**

覆盖以下路径：

- 启动后顶部显示 `logo + 衣不缺`，右侧头像入口可进入 `我的`。
- 底部主导航只有 `衣橱 / + / 逛店`。
- `+` 面板可打开/关闭，包含 `拍衣服`、`拍搭配`、`拍店铺`。
- `衣橱` 内 `衣裤 / 美搭` 可切换。
- 新增衣物后回到 `衣橱 / 衣裤` 并显示图片。
- 新增美搭后回到 `衣橱 / 美搭` 并显示照片或柔和占位。
- 新增逛店记录后回到 `逛店` 并显示店铺名、日期、图片/占位和备注摘要。
- `我的` 中身高、体重、腰围可保存并回显。
- 主操作是黑色胶囊按钮。
- 卡片图片都有圆角。
- 页面没有后台管理风、推荐流或社交动作。

**Step 2: 全量验证**

```bash
for script in scripts/validate-*.mjs; do node "$script" || exit 1; done
git diff --check
```

如本地 DevEco CLI 可用，再执行 HAP 或 App 构建：

```bash
<command-line-tools>/bin/hvigorw --mode module -p product=default -p module=entry@default assembleHap --no-daemon --no-incremental --no-parallel --stacktrace
```

**Step 3: Commit**

```bash
git add docs/qa/manual-test-script.md docs/delivery/first-release-verification.md
git commit -m "docs: update yibuque qa coverage"
```

## 执行注意事项

- 若某个任务触碰已有本地改动，先看 diff，保留无关用户改动。
- 每个任务只提交本任务文件，避免把早前未完成改动混入。
- 如 `SearchEntityType.Wishlist` 为兼容保留，验证重点是“不可达”和“不作为主入口”。
- 如真机拍照权限或 API 接入超出当前范围，第一版继续使用系统图片选择器；按钮文案保留 `拍衣服 / 拍搭配 / 拍店铺`，实现可为拍/选入口。
- 不要把 `OutfitTemplate` 立即全量重命名为 `Look` 或 `BeautyMatch`；第一版优先改用户可见文案和页面结构。
