# Harmony Wardrobe（衣不缺）三线质量评审报告

> **评审日期**：2026-07-15
> **评审模式**：完整三线并行评审（功能 / UI / 交互）
> **评审团**：程维序（功能流程）· 颜守白（UI 视觉）· 滑如丝（交互动效）
> **汇编人**：顾审之（主理人）

---

## 一、总览

本次评审覆盖 `entry/src/main/ets` 下全部 67 个 ETS 源文件，从功能完整性、UI 设计规范一致性、交互动效三个维度独立审查后去重汇编。

| 维度 | 评审人 | P0 | P1 | P2 | 健康度 |
|------|--------|----|----|-----|--------|
| 功能流程 | 程维序 | 1 | 5 | 6 | **B+** |
| UI 视觉 | 颜守白 | 5 | 18 | 7 | **C+** |
| 交互动效 | 滑如丝 | 1 | 10 | 12 | **C+** |
| **去重合计** | — | **7** | **~20** | **~20** | **C+** |

### 健康度评分

| 维度 | 评分 | 一句话 |
|------|------|--------|
| 功能流程 | **B+（良好）** | 四大约束全部遵守，CRUD 全闭环，事务一致；1 个搜索路由 P0 + 启动性能冗余 |
| UI 视觉 | **C+（中等偏下）** | 设计方向合规（无粉色/彩色阴影/蓝色主色），但 token 体系执行不彻底，3 页面绕过 token，60+ 处硬编码 borderRadius |
| 交互动效 | **C+（中等偏下）** | 1 个 P0 tab 缺失，4 编辑页防重入不一致，全局转场动画缺失；但衣裤列表懒加载正确，QuickCaptureSheet 动效规范 |

### 跨专家去重说明

- **三编辑页选图缺防重入**：滑如丝（P1-1/2/3，交互动效视角）+ 程维序（P1-3，错误处理视角）→ 合并为 1 项
- **ShoppingPage 搜索框每键跳转**：滑如丝（P1-6）+ 程维序（P2-4）→ 合并为 1 项，取 P1
- **死代码组件**：滑如丝（P2-9）+ 程维序（P2-2，补充 CalendarPage onDelete 缺失）→ 合并为 1 项

---

## 二、P0 清单（阻断：功能断点 / 数据真实性违规 / 明显违反设计方向）

### P0-1｜衣橱二级 Tab 切换条定义但从未渲染，日历功能基本不可达
- **来源**：滑如丝
- **文件**：`pages/WardrobePage.ets:767`（定义处）；`build()` 内 608-720 行未调用
- **问题**：`WardrobePrimaryTabs()` Builder（衣裤/美搭/日历 三级 tab 切换条）已实现含 onClick 逻辑，但 `build()` 中从未调用。`selectedWardrobeTab` 初始为 `initialWardrobeTab`（默认 '衣裤'），之后没有任何 UI 能改变它。
- **影响**：用户在衣橱页无法切换到「日历」或「美搭」子页。日历功能除从搜索结果跳转外完全不可达；一旦从搜索跳到「日历」子页，用户无法切回「衣裤」。
- **建议修复**：在 `build()` 主分支（约 609 行 `Column` 内、`WardrobeSearchHeader()` 之后）调用 `this.WardrobePrimaryTabs()`。

### P0-2｜穿搭记录搜索结果不关闭搜索遮罩，流程中断
- **来源**：程维序
- **文件**：`pages/WardrobePage.ets:592-593`
- **问题**：点击穿搭记录搜索结果时，`onOpenWearLogResult` 直接调用 `this.onOpenSearchTarget(SearchEntityType.WearLog, id, '')`，但**没有先将 `showUnifiedSearch` 设为 `false`**。对比 `onOpenClothingResult`（行 471-488）会先关闭搜索再打开详情。WearLog 路由设 `selectedMainTab = 'wardrobe'`（已经是 wardrobe，无变化），WardrobePage 不会被卸载，搜索遮罩停留在原处。
- **影响**：用户在衣柜页搜索后点击穿搭记录结果，**界面无任何变化**，搜索页不消失、不跳转。流程完全中断。
- **附带问题**：即使搜索遮罩关闭了，`initialWardrobeTab = '日历'` 也不会生效——因为 `selectedWardrobeTab` 仅在 `aboutToAppear` 中赋值，组件未重新创建时 `@Prop` 更新不会同步到 `@State`。
- **建议修复**：
  1. `onOpenWearLogResult` 中先关闭搜索：`this.showUnifiedSearch = false; this.onNestedPageVisibilityChange(false);`
  2. Index.ets 的 WearLog 路由分支中，用 WardrobePage 可观察的机制（如新增 `@Prop initialCalendarDate` 或 `@Watch`）触发 tab 切换和日期定位。

### P0-3｜三个页面自建颜色常量副本，完全绕过 token 系统
- **来源**：颜守白
- **文件**：
  - `pages/ProfilePage.ets:7-16` — 10 个 `PROFILE_*` 常量，全页 80+ 处引用
  - `pages/CaptureEditPage.ets:22-28` — 7 个 `CAPTURE_*` 常量，全页 40+ 处引用
  - `pages/OutfitsPage.ets:26-34` — 9 个本地颜色常量，全页引用
- **问题**：设计规范明确「严禁 OPEN_DESIGN_*、PROFILE_*、CAPTURE_* 等本地 const 副本」。这三个页面系统性违反，值虽正确但完全脱离语义 token 体系。
- **影响**：token 更新无法传播到这些页面；未来主题变更需逐页手改。
- **建议修复**：删除全部本地常量，全量替换为 `YibuqueColor.*` 对应 token。

### P0-4｜StoreVisitEditPage 大量散落硬编码颜色，完全脱离 token 系统
- **来源**：颜守白
- **文件**：`pages/StoreVisitEditPage.ets:420-639`
- **问题**：大量非 token 硬编码颜色值：`#444748`（6 处）、`#1B1C1C`（3 处）、`#C4C7C7`（4 处）、`#000000`（7 处）、`#FFFFFF`（4 处）、`#00FFFFFF`（2 处）。这些颜色值与 token 系统中的 `textPrimary(#1D1D1F)` / `textSecondary(#6E6E73)` / `textTertiary(#86868B)` 均不一致。
- **影响**：颜色值碎片化，同一语义存在多种硬编码值。
- **建议修复**：全量替换为 `YibuqueColor` 对应 token。

### P0-5｜OutfitEditPage 多处硬编码颜色
- **来源**：颜守白
- **文件**：`pages/OutfitEditPage.ets:211-285`
- **问题**：多处硬编码非 token 颜色：`#00000000`/`#99000000` 渐变、`#FFFFFF`、`#D9FFFFFF`、`#000000`、`#E4E2E2`（不在任何 token 中）、`#4DC4C7C7`、`#F2FFFFFF`。
- **影响**：颜色碎片化，与设计规范的 token 体系完全脱节。
- **建议修复**：替换为 `YibuqueColor` token；半透明值在 Tokens.ets 中新增对应语义 token。

### P0-6｜底部导航相机图标渐变包含橙色，超出「唯一允许蓝色」约束
- **来源**：颜守白
- **文件**：`components/BottomNavigationBar.ets`（linearGradient 定义处）
- **问题**：相机圆形图标使用三色渐变 `['#F37A59', 0], ['#4578FF', 0.55], ['#56D0FF', 1]`（橙→蓝→青）。设计规范允许相机使用彩色但明确限定为「蓝色入口」，渐变中的 `#F37A59`（珊瑚橙）不属于设计调色板。
- **影响**：橙色与整体黑白灰设计方向不协调。
- **建议修复**：将渐变改为蓝色系单色或蓝色系渐变（如 `#1D1D1F`→`#4578FF`），去除橙色。

### P0-7｜CaptureEditPage 表单字段缺少可见标签，仅靠 placeholder
- **来源**：颜守白
- **文件**：`pages/CaptureEditPage.ets`（PurchaseFields / StoreFields builder）
- **问题**：采购信息字段（价格、购入日期）和门店字段（门店名、地点）均只有 placeholder 文本，没有独立的 `Text()` 标签。设计规范：「表单标题必须清晰，不能只靠 placeholder」。
- **影响**：用户开始输入后 placeholder 消失，无法辨认字段含义；可访问性差。
- **建议修复**：为每个输入字段添加 `Text()` 标签，参考 StoreVisitEditPage 和 WearLogEditPage 的 label+input 模式。

---

## 三、P1 清单（重要：数据不一致风险 / token 不一致 / 约束违反 / 缺失必要反馈）

### 功能流程

#### P1-1｜WardrobeRuntime.ensureBaseSchema 在迁移完成后重复执行全部迁移
- **来源**：程维序
- **文件**：`app/WardrobeRuntime.ets:167, 267-273`
- **问题**：`initialize()` 先调用 `migrationRunner.runMigrations()` 执行所有迁移，紧接着又调用 `ensureBaseSchema(database)` 依次调用 V1-V5 每个迁移的 `up()` 方法。完全冗余。
- **影响**：每次启动多执行 5 轮 DDL 检查，增加启动耗时；掩盖迁移系统权威性。
- **建议修复**：删除 `ensureBaseSchema` 调用和方法，完全信任 MigrationRunner。

#### P1-2｜WardrobeRuntime 每次启动全量重建搜索索引
- **来源**：程维序
- **文件**：`app/WardrobeRuntime.ets:180-187, 204-246`
- **问题**：`rebuildSearchIndex` 在每次 `WardrobeRuntime.create()` 时被调用，加载全部数据全量替换索引。搜索索引本应是派生数据，正常写入时已由 repository 同步维护。
- **影响**：数据量大时冷启动延迟可感知。
- **建议修复**：改为仅在首次安装或 schema 版本变更时重建；正常启动跳过或增量校验。

#### P1-3｜ProfileRepository.saveProfile 未包裹在事务中
- **来源**：程维序
- **文件**：`data/repositories/ProfileRepository.ets:118`
- **问题**：`saveProfile` 直接调用 `executeSql`，未使用 `transaction()`。所有其他 repository 写操作都在事务中。
- **影响**：违反架构一致性；未来扩展为多步操作时有数据不一致风险。
- **建议修复**：用 `this.database.transaction()` 包裹。

#### P1-4｜StoreRepository.findStoreByNameInTransaction 全量加载后内存过滤
- **来源**：程维序
- **文件**：`data/repositories/StoreRepository.ets:511-526`
- **问题**：查找同名店铺时执行无 WHERE 条件的全量加载，然后在 JS 中遍历比较。
- **影响**：店铺数量增长后浪费 I/O 和内存，增加事务持有时间。
- **建议修复**：改为 SQL 查询 `WHERE LOWER(TRIM(name)) = LOWER(TRIM(?)) LIMIT 1`。

### 交互动效

#### P1-5｜三个编辑页选图缺防重入与 try/catch（跨专家合并）
- **来源**：滑如丝（P1-1/2/3）+ 程维序（P1-3）
- **文件**：
  - `pages/OutfitEditPage.ets:94-110`（pickGalleryPhotos / capturePhoto）
  - `pages/WearLogEditPage.ets:75-91`
  - `pages/WishlistEditPage.ets:78-94`
- **问题**：三个编辑页的选图/拍照方法均无 `isChoosingPhotos` 状态守卫、无 try/catch、按钮无 `.enabled()` 禁用态。用户取消选择时异常未捕获，产生 unhandled promise rejection；快速连点会并发拉起多个选择器。
- **参照标杆**：`ClothingEditPage.ets:204-244` 和 `StoreVisitEditPage.ets:102-142` 有完整实现。
- **建议修复**：参照 ClothingEditPage 模式，增加 `isChoosingPhotos` 状态、try/catch/finally、`.enabled(!this.isSaving && !this.isChoosingPhotos)`。

#### P1-6｜CaptureEditPage 选照片按钮未在保存期间禁用
- **来源**：滑如丝
- **文件**：`pages/CaptureEditPage.ets:178, 297`
- **问题**：选照片按钮 `.enabled(!this.isChoosingPhotos)` 未包含 `isSaving` 检查。保存期间用户仍可触发选图，`photoUris` 在保存过程中可能被修改。
- **影响**：保存与选图并发导致数据不一致。
- **建议修复**：改为 `.enabled(!this.isChoosingPhotos && !this.isSaving)`。

#### P1-7｜ProfilePage 偏好保存竞态导致开关状态丢失
- **来源**：滑如丝
- **文件**：`pages/ProfilePage.ets:299-320, 709-720, 937-942`
- **问题**：风格标签/隐私模式/试穿偏好的 onClick 先翻转本地布尔值，再调用 `persistPreferences()`。若第一次保存未完成时快速切换第二个开关，`persistPreferences` 因 `isSaving=true` 直接 return，第二次变更未持久化。保存完成后 `applyProfile(saved)` 用数据库返回值覆盖全部本地状态，第二次切换被静默回滚。
- **影响**：用户看到开关先翻转再弹回，操作被丢失，且无提示。
- **建议修复**：保存期间禁用所有开关（`enabled(!this.isSaving)`），或将状态变更推迟到 persistPreferences 成功后。

#### P1-8｜ShoppingPage 搜索框每次按键即跳转搜索结果页（跨专家合并）
- **来源**：滑如丝（P1-6）+ 程维序（P2-4）
- **文件**：`pages/ShoppingPage.ets:222-229`
- **问题**：SearchBar 的 `onChange` 每次触发都调用 `openUnifiedSearch(value)`，后者在 `query.trim().length > 0` 时立即设 `showUnifiedSearch = true`，页面瞬间切换。用户打第一个字符就被弹走，无法完整输入关键词。
- **影响**：搜索体验严重受损。
- **建议修复**：改为 `onSubmit` 或搜索按钮触发，或增加 debounce + 最小字符数门槛。

#### P1-9｜三处列表未使用懒加载，全量渲染
- **来源**：滑如丝
- **文件**：
  - `pages/WardrobePage.ets:696-712` — 美搭子页 `Scroll + Grid + ForEach`
  - `pages/SearchResultsPage.ets:555-561` — 搜索结果 `List + ForEach`（最多 100 条）
  - `components/ClothingPicker.ets:59` — 衣物选择器 `ForEach`（可能 200+ 件）
- **问题**：三处列表用 `ForEach` 一次性全量渲染，对比衣裤列表正确使用了 `WaterFlow + LazyForEach`（WardrobePage.ets:988-1004）。
- **影响**：数据量大时首屏渲染慢、内存占用高、滚动卡顿。
- **建议修复**：改用 `LazyForEach` + `IDataSource`（已有 ArrayDataSource 工具类）。

#### P1-10｜全局页面/弹层转场动画完全缺失
- **来源**：滑如丝
- **文件**：全局（除 `QuickCaptureSheet.ets:14,29` 和 `ClothingCard.ets:13` 外，全项目无 `animateTo` / `.transition()` / `pageTransition`）
- **问题**：所有页面切换（编辑器打开/关闭、详情页打开/关闭、嵌套页导航、tab 切换）均为 `if/else` 条件渲染的硬切，无任何过渡动画。底层页面被遮盖时也未禁用交互。
- **影响**：应用整体感觉生硬、缺乏打磨；页面切换突兀影响感知性能。
- **建议修复**：为编辑器/详情页/嵌套页的进入退出加 `.transition()`（Opacity + translate）；为 Index.ets 的 Stack 叠加层加遮罩淡入；底层页面可见时禁用交互。

### UI 视觉

#### P1-11｜多个页面/组件全量使用旧 AppTheme 而非 YibuqueColor
- **来源**：颜守白
- **文件**：`ShoppingPage.ets`、`CalendarPage.ets`、`WishlistEditPage.ets`、`WishlistCard.ets`、`SearchBar.ets`
- **问题**：项目已在向 `YibuqueColor` 迁移，但这 5 个文件全量使用旧 `AppTheme.color.*` / `AppTheme.radius.*`。两套 token 系统并存导致颜色值碎片化（如 `AppTheme.color.border=#D2D2D7` vs `YibuqueColor.borderLight=#E8E8ED`）。
- **建议修复**：统一迁移至 `YibuqueColor` / `YibuqueRadius` / `YibuqueSpacing` 系统。

#### P1-12｜多页面硬编码颜色散落
- **来源**：颜守白
- **文件**：`ProfilePage.ets`（:464, :833, :860 等 8 处）、`CaptureEditPage.ets`（:307-459 共 9 处）、`WardrobePage.ets`（:743, :937 等 4 处）、`StoreVisitPage.ets`（:332, :506 等 3 处）、`SearchResultsPage.ets`（:343, :429, :412）、`Index.ets:376`、`AppTopBar.ets`、`SecondaryPageHeader.ets`、`ClothingEditPage.ets`（:346-552 共 4 处）、`ClothingDetailPage.ets:322`
- **问题**：除 P0-3/4/5 已记录的页面外，多个页面仍有散落硬编码颜色值（如 `#8E8E93`、`#3A3A3C`、`#96969C`、`#626267` 等不在任何 token 中）。
- **建议修复**：全量替换为 `YibuqueColor` 对应 token。

#### P1-13｜多文件硬编码 shadow 未使用 YibuqueShadow
- **来源**：颜守白
- **文件**：`BottomNavigationBar.ets`（2 处）、`AppTopBar.ets`、`ProfilePage.ets`（3 处）、`WardrobePage.ets`（1 处）、`StoreVisitEditPage.ets:649`、`StoreVisitPage.ets:508`
- **问题**：所有 shadow 均为中性黑色透明（无彩色阴影，符合设计方向），但 8 处硬编码未使用 `YibuqueShadow` token。
- **建议修复**：统一使用 `YibuqueShadow.card` / `.soft` / `.floating`。

#### P1-14｜60+ 处硬编码 borderRadius 未使用 YibuqueRadius token
- **来源**：颜守白
- **文件**：全项目 60+ 处，涉及 ProfilePage、CaptureEditPage、StoreVisitEditPage、OutfitEditPage、StoreVisitPage、WardrobePage、BottomNavigationBar、AppTopBar 等
- **问题**：出现 5/12/14/16/18/19/22/24/28/999 共 10 种 borderRadius 值，其中 `22` 和 `19` 不在 YibuqueRadius 任何 token 中。
- **建议修复**：全量替换为 `YibuqueRadius.*` token；`22` 和 `19` 需评估是否新增 token 或对齐到现有值。

#### P1-15｜ClothingEditPage placeholderColor 使用 textPrimary
- **来源**：颜守白
- **文件**：`pages/ClothingEditPage.ets:451, 475, 551`
- **问题**：`.placeholderColor(YibuqueColor.textPrimary)` 使用主文字色 `#1D1D1F`，placeholder 与实际输入文字颜色相同。
- **影响**：用户无法区分占位提示与已输入内容。
- **建议修复**：改为 `YibuqueColor.textTertiary`（`#86868B`）。

#### P1-16｜ShoppingPage/CalendarPage 标题字号 30 超出规范
- **来源**：颜守白
- **文件**：`ShoppingPage.ets:175`、`CalendarPage.ets:131`
- **问题**：`fontSize(30)` 不匹配任何 token 且超出标题范围（规范「标题 24-28」；`pageTitle: 24`，`display: 36`）。
- **建议修复**：使用 `YibuqueFontSize.pageTitle`（24）。

#### P1-17｜YibuqueColor 缺少半透明语义 token
- **来源**：颜守白
- **问题**：多个文件反复硬编码 `#00FFFFFF`、`#38FFFFFF`、`#D9FFFFFF`、`#29000000`、`#52000000` 等半透明值，说明 token 系统缺少这些常用语义。
- **建议修复**：在 `YibuqueColor` 中新增 `scrimLight`、`scrimMedium`、`scrimStrong`、`glassLight`、`glassMedium` 等半透明语义 token。

#### P1-18｜SearchBar 高度 44 不符合规范（应为 48）
- **来源**：颜守白
- **文件**：`components/SearchBar.ets`
- **问题**：设计规范「控件高 48」，SearchBar 高度为 44。
- **建议修复**：改为 48。

#### P1-19｜BottomNavigationBar 未选中态颜色硬编码
- **来源**：颜守白
- **文件**：`components/BottomNavigationBar.ets`
- **问题**：`#8D8D92` 硬编码，不在 token 中（接近 `textTertiary=#86868B` 但不一致）。
- **建议修复**：使用 `YibuqueColor.textTertiary`。

---

## 四、P2 清单（次要：视觉瑕疵 / 动效润色 / 健壮性）

### 交互动效

| # | 来源 | 问题 | 文件 |
|---|------|------|------|
| P2-1 | 滑如丝 | 多处按钮/可点击元素命中区 < 44×44（35 处，含重试按钮 34vp、补记按钮 38vp、编辑 Text ~20px 等） | WardrobePage/ShoppingPage/StoreVisitPage/OutfitsPage/ClothingDetailPage/ProfilePage/SearchResultsPage 等多处 |
| P2-2 | 滑如丝 | OutfitsPage 套装元信息文字可点击（记录穿着）但无视觉提示 | `OutfitsPage.ets:551-560` |
| P2-3 | 滑如丝 | ProfilePage MeasurementSheet 无进出动画 | `ProfilePage.ets:360-370` |
| P2-4 | 滑如丝 | ClothingDetailPage 全屏照片预览无过渡动画 | `ClothingDetailPage.ets:589-591` |
| P2-5 | 滑如丝 | WearLogEditPage/CaptureEditPage 日期用纯文本输入，无日期选择器 | `WearLogEditPage.ets:198`、`CaptureEditPage.ets:542` |
| P2-6 | 滑如丝 | 各 Edit 页保存成功后无 Toast 反馈（除 ProfilePage 外） | ClothingEditPage/OutfitEditPage/StoreVisitEditPage/WearLogEditPage/WishlistEditPage |
| P2-7 | 滑如丝 | 大量可点击卡片缺 pressed 触感反馈 | WardrobePage/OutfitsPage/StoreVisitPage/ShoppingPage 卡片 |
| P2-8 | 滑如丝 | MonthCalendar 无月份切换导航 | `components/MonthCalendar.ets` |
| P2-9 | 滑如丝 | BottomNavigationBar 按压反馈无动画过渡 | `BottomNavigationBar.ets:108` |
| P2-10 | 滑如丝 | WardrobeSearchTabs 分类标签宽度固定 76vp 可能截断 | `WardrobePage.ets:939` |

### 功能流程

| # | 来源 | 问题 | 文件 |
|---|------|------|------|
| P2-11 | 程维序 | ClothingRepository.categoryFilterValues 引用不存在的分类（死代码） | `ClothingRepository.ets:243-256` |
| P2-12 | 程维序 | V1InitialSchema 在 up() 中调用 ensureClothingPurchaseColumns，与 V2 重叠 | `V1InitialSchema.ets:142` |
| P2-13 | 程维序 | 孤儿店铺记录无清理机制 | `StoreRepository.ets` |
| P2-14 | 程维序 | StoreVisitEditPage 编辑时更改店名不会重新关联店铺实体 | `StoreVisitEditPage.ets:152-164` |

### 死代码与架构

| # | 来源 | 问题 | 文件 |
|---|------|------|------|
| P2-15 | 滑如丝+程维序 | 死代码组件从未被引用：ClothingCard/OutfitCard/StoreVisitCard/CalendarPage。其中 CalendarPage 的 WearLogEditPage 未提供 onDelete 回调，启用后删除按钮无效 | `components/ClothingCard.ets`、`components/OutfitCard.ets`、`components/StoreVisitCard.ets`、`pages/CalendarPage.ets` |
| P2-16 | 滑如丝 | Index.ets 底部导航栏显隐逻辑依赖 7 个布尔状态组合，底层页面交互穿透风险 | `pages/Index.ets:378` |

### UI 视觉

| # | 来源 | 问题 | 文件 |
|---|------|------|------|
| P2-17 | 颜守白 | Token 命名与实际值不符（`bgBlueGray` 实为纯白、`bgHeaderBlue` 实为浅灰、`cardBlue` 实为浅灰） | `Tokens.ets` |
| P2-18 | 颜守白 | OutfitCard/PhotoGrid/ClothingPicker 硬编码 borderRadius(5) 和 height | `OutfitCard.ets`、`PhotoGrid.ets`、`ClothingPicker.ets` |
| P2-19 | 颜守白 | StoreVisitPage borderRadius(19) 不在任何 token 中 | `StoreVisitPage.ets` |
| P2-20 | 颜守白 | AppTopBar/WardrobePage 多处 borderRadius 硬编码 | `AppTopBar.ets`、`WardrobePage.ets` |

---

## 五、修复优先级路线图

### 第一阶段：P0 阻断项（立即修复，7 项）

| 序号 | 修复内容 | 预估工作量 | 依赖关系 |
|------|---------|-----------|---------|
| 1 | **P0-1**：WardrobePage.build() 中调用 `this.WardrobePrimaryTabs()` | 1 行代码 | 无 |
| 2 | **P0-2**：onOpenWearLogResult 先关闭搜索遮罩 + 修复 tab 切换机制 | 中等 | 与 P0-1 关联 |
| 3 | **P0-3**：删除三页面本地颜色常量，替换为 YibuqueColor | 较大（机械替换） | 无 |
| 4 | **P0-4**：StoreVisitEditPage 硬编码颜色替换为 token | 中等 | 无 |
| 5 | **P0-5**：OutfitEditPage 硬编码颜色替换为 token | 中等 | 无 |
| 6 | **P0-6**：BottomNavigationBar 相机渐变去除橙色 | 1 行 | 无 |
| 7 | **P0-7**：CaptureEditPage 表单字段加 Text 标签 | 中等 | 无 |

### 第二阶段：P1 重要项（本周修复，~19 项）

**功能流程（4 项）**：
1. 删除 ensureBaseSchema 冗余调用（P1-1）
2. 搜索索引改为按需重建（P1-2）
3. ProfileRepository.saveProfile 包裹事务（P1-3）
4. StoreRepository 改 SQL 查询（P1-4）

**交互动效（6 项）**：
5. 三编辑页补齐防重入 + try/catch（P1-5）— 参照 ClothingEditPage 模式
6. CaptureEditPage 选照片按钮加 isSaving 检查（P1-6）— 1 行
7. ProfilePage 偏好保存竞态修复（P1-7）
8. ShoppingPage 搜索框改 onSubmit 或 debounce（P1-8）
9. 三处列表改 LazyForEach（P1-9）
10. 全局转场动画补齐（P1-10）— 工作量较大，可分批

**UI 视觉（9 项）**：
11. 5 文件迁移至 YibuqueColor（P1-11）
12. 多页面散落硬编码颜色清理（P1-12）— 与 P0-3/4/5 一并处理
13. 硬编码 shadow 替换为 YibuqueShadow（P1-13）
14. 60+ 处 borderRadius 替换为 YibuqueRadius（P1-14）— 机械替换
15. ClothingEditPage placeholderColor 修正（P1-15）— 1 行
16. 标题字号 30 改为 24（P1-16）— 2 处
17. 新增半透明语义 token（P1-17）
18. SearchBar 高度 44→48（P1-18）
19. BottomNavigationBar 未选中色替换为 token（P1-19）

### 第三阶段：P2 次要项（后续迭代，~20 项）

按收益排序的 TOP 5：
1. 可点击区域统一 ≥44×44（P2-1）— 影响全 App 可用性
2. 死代码清理（P2-15）— 降低维护成本
3. 保存成功 Toast 反馈（P2-6）— 提升操作确定性
4. 日期选择器统一（P2-5）— 体验一致性
5. 列表卡片 pressed 触感反馈（P2-7）— 提升精致度

---

## 六、值得肯定的设计实现

| 维度 | 亮点 |
|------|------|
| 功能流程 | 四大约束全部遵守（无网络/无页面 SQL/照片只存 URI/搜索索引派生）；CRUD 全闭环；除 ProfileRepository 外所有写操作在事务中；迁移链 V1→V5 顺序正确且幂等 |
| UI 视觉 | 无粉色/彩色阴影/蓝色主色；错误红统一 `#DC2626`；QuickCaptureSheet / EmptyState / ClothingCard / MonthCalendar / ClothingPicker 等组件完全 token 化；底部导航结构合规 |
| 交互动效 | 衣裤/逛店列表正确使用 WaterFlow + LazyForEach；QuickCaptureSheet 有完整进出动画 + 防重入；ClothingEditPage / StoreVisitEditPage 保存防重入完整；SearchResultsPage 有 searchRequestVersion 竞态保护；删除统一 AlertDialog 二次确认；各列表有 loading/empty/error 三态 |

---

## 七、附录：各专家原始报告索引

| 专家 | 评审范围 | P0 | P1 | P2 | 核心发现 |
|------|---------|----|----|-----|---------|
| 程维序 | CRUD/导航/索引一致性/迁移/媒体/架构 | 1 | 5 | 6 | 架构约束全通过；搜索路由 P0；启动性能冗余；三编辑页错误处理缺失 |
| 颜守白 | token/色彩/布局/空态/表单/导航 | 5 | 18 | 7 | 设计方向合规但 token 执行不彻底；3 页面绕过 token；60+ 处硬编码 borderRadius |
| 滑如丝 | 点击区域/防重入/转场/懒加载/状态反馈 | 1 | 10 | 12 | Tab 切换器 P0；4 编辑页防重入不一致；全局转场缺失；3 处列表未懒加载 |
