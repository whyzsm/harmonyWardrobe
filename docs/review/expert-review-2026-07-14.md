# Harmony Wardrobe / 衣不缺 —— 专家团评审报告

> 评审日期：2026-07-14
> 方式：三位专家并行静态代码审查（纯静态，未运行真机 / 未修改文件）
> 范围：`entry/src/main/ets` 全部 `.ets`（pages / components / domain / data / media / utils / theme）+ 设计规范 `docs/background/yibuque-design.md` + 主题 `theme/Tokens.ets`
> 专家团：A=功能与流程、B=UI 与视觉、C=交互与动效

---

## 一、总览与健康度评分

| 维度 | 评分 | 一句话结论 |
|---|---|---|
| 功能与流程 | 6.5/10 | 可达流程扎实，但**删除全线缺失**、**心愿单不可达**两个 P0 断点 |
| UI 与视觉 | 6.0/10 | 白底黑交互基调守住，但**错误红三态不统一**、**token 被大面积本地复制/暖灰板脱节**、**虚构数据暗示** |
| 交互与动效 | 6.0/10 | 保存防重做得到位，但**全站零转场**、**无 LoadingProgress**、**假收藏控件** |
| **综合** | **6.2/10** | 骨架良好、能跑；上线前必须清除 P0，并集中治理 token 与转场 |

共同强项（三专家一致认可）：
- 编辑页保存流：`isSaving` 守卫 + `.enabled()` + "保存中…" 文案，重复提交防护到位。
- 衣橱/逛店瀑布流用 `WaterFlow`（天生懒加载），性能取向正确。
- 顶部导航、底部导航结构符合规范（90% 黑胶囊、中间相机唯一蓝色、无粉色主色/边框/阴影）。
- 搜索索引派生可重建（FTS5 + ngram fallback + rebuild），数据一致性设计正确。
- 空态文案普遍说明"下一步动作"，CTA 多为黑色。

---

## 二、P0 —— 阻断级（必须修，否则影响核心可用性 / 数据真实性）

### P0-1 删除功能在 UI 层全线缺失（CRUD 的 D 断点）
- 专家：A ｜ 位置：`pages/` 全目录；repository 删除方法定义于 `ClothingRepository.deleteClothing`、`OutfitRepository`/`WearLogRepository`/`WishlistRepository`/`StoreRepository.deleteStoreVisit`
- 现象：对 pages 目录检索 `delete|Delete|删除|AlertDialog|confirm`，唯一命中是 `ClothingDetailPage.ets:451` 的占位文案，并非删除动作。所有详情页/列表页/编辑页**均无可删除入口与确认弹窗**。
- 影响：衣物/穿搭/穿着/心愿/逛店记录**只能增改查、无法删除**，用户无数据清理路径；repository 的 `delete*` 全是死代码。
- 建议：在 `ClothingDetailPage`、各列表卡片、各编辑页加删除入口 + `AlertDialog` 二次确认，调用对应 `repository.deleteXxx(id)`，并通过 `onDelete` 回调刷新本地列表。

### P0-2 心愿单（Shopping / Wishlist）功能完全不可达
- 专家：A ｜ 位置：`Index.ets:10-15`（仅 import 5 个主页面）、`ShoppingPage.ets`（功能完整但从未被导航）；`BottomNavigationBar` 仅 wardrobe/store/outfit/profile + 相机
- 现象：`ShoppingPage`（标题"心仪单品"，记录想买衣物/门店/价格/试穿照片）内部完整，但 `Index` 五大分支无 `shopping`；`ProfilePage` 也未接入 `wishlistRepository`。
- 影响：整套心愿单对用户**完全不可见**，与"五大主标签 Shopping"直接冲突；`ShoppingPage`/`WishlistEditPage`/`WishlistCard`/`WishlistRepository` 实际为死代码。
- 建议：在底部导航或 `ProfilePage` 接入 `ShoppingPage`；若决定砍功能，应移除上述死代码与 repository。

### P0-3 底部相机使用彩色阴影（违反"阴影必须中性黑"）
- 专家：B ｜ 位置：`components/BottomNavigationBar.ets:65`
- 现象：`.shadow({ radius: 18, color: '#735A7CFF', ... })` —— `#735A7CFF` 是蓝紫色（RGB `5A7CFF`）的**彩色阴影**。胶囊本体阴影（`#32000000`）合规。
- 影响：直接违反设计规范"阴影必须为中性黑色透明，不使用彩色阴影"。
- 建议：改为中性黑透明（如 `color: '#1A000000'`），或复用 `YibuqueShadow.floating`；同时把胶囊阴影改为 `YibuqueShadow.floating`（当前也是硬编码未用 token）。

### P0-4 TodayPage 含虚构社交/推荐内容，且为孤儿页面
- 专家：B、C ｜ 位置：`pages/TodayPage.ets`（`HomeRecommendation:13-26`、`buildAllItems:339-499`、社交壳 `TabDiscover/TabAdd/TabMessage/TabProfile:256-289`）
- 现象：页面注入 `authorName`（"衣橱灵感社""小蓝穿搭"）、`likeText`（♡ 128/86/52）、`commentText/collectText`、"推荐/今日/灵感"Tab、"发现页/发布/消息"社交壳；`Index.ets` 并未装配此页。
- 影响：直接违反"禁止虚构网络同步/用户记录""design examples must never be presented as user data"。一旦启用将严重背离"本地优先、图片优先、安静工具感"。
- 建议：删除 `TodayPage` 及未引用的 `StoreVisitCard`/`OutfitCard` 死组件；如保留"今日"入口，仅渲染本地 WearLog/Outfit 真实数据，绝不可出现点赞/作者/社交概念。

### P0-5 QuickCaptureSheet 内容与规范定义偏离
- 专家：B ｜ 位置：`components/QuickCaptureSheet.ets:60-70`
- 现象：规范定义"快捷录入"为黑色主卡"拍一张"（白相机图标）+ 浅灰卡"从相册选择"。实际实现是三个**导航入口**「衣柜/逛店/套装」，且无相机图标；真实拍照/相册选择被下沉到各 Edit 页内部。
- 影响：改变了规范核心流程"点底部相机 → 拍一张/从相册选择 → 归类为…"；与"衣不缺"主流程定义不一致。
- 建议：按规范重建为「拍一张」（黑卡 + `sys.symbol.camera_fill`）与「从相册选择」（浅灰卡 + 灰边 + 中性灰图标底），点击进入 `CaptureEditPage` 并预选模式；或至少对齐为规范两项主操作。

### P0-6 WardrobePage 收藏爱心为假控件（看得到点不动）
- 专家：C ｜ 位置：`WardrobePage.ets:1056-1067`（`CardHeart`）
- 现象：设计规范要求"收藏按钮保持轻量"，但 `ClothingItem` 模型**无 `favorite` 字段**；`CardHeart` 只有 `SymbolGlyph($r('sys.symbol.heart'))`，**无 `onClick`、无选中态、不持久化**，且 30×30 < 44。
- 影响：呈现可点爱心却点击无效，是误导型 affordance，既违反规范意图也可能被误判为 bug。
- 建议：二选一 —— (a) 实现真实收藏：在 `ClothingItem` 加 `favorite: boolean`，仓库持久化，点击切换 `heart`/`heart_fill` 并做轻量缩放动画，命中区 ≥44×44；(b) 不实现则直接移除该图标。

---

## 三、P1 —— 重要级（修复 P0 时应一并治理）

### 数据 / 流程
- **P1-1 删除后照片文件泄漏（P0-1 修复后立即触发）**：`ClothingRepository.createDeleteCleanupService`（`ClothingRepository.ets:382`）未把 `photoStorage` 传入 `DeleteCleanupService`（缺第 3 参），导致 `DeleteCleanupService.ets:37-41` 在 `photoStorage===undefined` 时跳过文件删除。`WardrobeRuntime.create` 构造各 repository 时也未传 `photoStorage`。其余 repository 同模式。→ 修复 P0-1 的同时必须把 `photoStorage` 注入 cleanup 链路，否则沙盒图片永久残留。
- **P1-2 照片复制失败静默回退非本地 URI（违反媒体约束）**：`ClothingEditPage.pickGalleryPhotos`（`ClothingEditPage.ets:216-231`）先用相册/相机**原始 URI** 赋值 fallback，复制失败仅 `console.info` 吞掉，最终把非本地 URI 持久化。`WearLogEditPage`/`OutfitsPage` 复制逻辑同理。→ 仅当 `copySourcesToLocalUris` 成功才更新 `photoUris`；失败保留原值并给可见错误，绝不入库非本地 URI。

### UI / 视觉
- **P1-3 错误红三态不统一，且 `YibuqueColor` 缺 `danger` 字段**：现网三套红 —— `#EF4444`（`Index.ets:182,343`、`ClothingEditPage.ets:601`、`OutfitEditPage.ets:311`、`WardrobePage.ets:575`、`WearLogEditPage.ets:215`）、`#DC2626`（部分页面）、`#BA1A1A`（`StoreVisitEditPage`、`SearchResultsPage`）。`Tokens.ets` 中 `AppTheme.color.danger='#DC2626'` 但 `YibuqueColor` 接口无 `danger`，迫使页面硬编码。→ ① 给 `YibuqueColor` 加 `danger:'#DC2626'`；② 全量替换为 `YibuqueColor.danger`；③ `StoreVisitEditPage` 错误边框 `#BA1A1A` 改统一红。
- **P1-4 `WardrobePage` 用 `OPEN_DESIGN_*` 偏离 token 的硬编码色**：`WardrobePage.ets:36-40`（`OPEN_DESIGN_BLACK #242021`、`OPEN_DESIGN_MUTED #717177`、`OPEN_DESIGN_BORDER #D9D9DE`、`SCREENSHOT_NAV_GRAY #74747A`）及多处复用（`#E6FFFFFF`/`#F5FFFFFF` 浮动按钮），是 token 近似副本，导致与全站冷灰出现可感知差异。→ 统一改为 `YibuqueColor.textPrimary/textSecondary/borderMedium` 等，阴影用 `YibuqueShadow`。
- **P1-5 `StoreVisitEditPage` 整页暖灰色板脱节**：背景 `#FBF9F9`、输入底 `#F5F3F3`、文字 `#1B1C1C/#444748`、占位 `#C4C7C7`、错误底 `#FFF0F0/#FFF7F7`、输入圆角 24 —— 与全站冷灰 token 明显不一致且错误态暖粉调。→ 整体改用 `YibuqueColor`/`AppTheme`，输入圆角改 12，错误底用中性灰或统一红调。
- **P1-6 多页把 token 复制为本地 const 未引用语义 token**：`ProfilePage.ets:7-16`（`PROFILE_*`）、`CaptureEditPage.ets:25-31`（`CAPTURE_*`）、`OutfitsPage.ets:24-34`、`WardrobePage` 等。→ 删除本地常量，统一 `import { YibuqueColor, AppTheme }`；`ProfilePage.PROFILE_DANGER` 直接复用 `AppTheme.color.danger`。
- **P1-7 `WardrobePage` 分类筛选含"待同步"暗示虚构网络同步 + "包袋"恒为空**：`WardrobePage.ets:27-34` `label:'待同步', categories:[]`（暗示远程同步，违反规范）与 `label:'包袋', categories:[]`（空映射恒空列表）。→ 移除"待同步"（或改本地"未分类"）；`包袋` 绑定真实 `ClothingCategory` 或移除。
- **P1-8 `WishlistEditPage` 字段仅靠 placeholder，无可见标签**：`WishlistEditPage.ets:173-212` 四行输入仅 placeholder（`title / 心仪单品` 中英混排），无 section 标题。→ 为每段加清晰中文标签（名称/门店/价格/备注），复用 `ClothingEditPage` 的带标题区块样式。

### 交互 / 动效
- **P1-9 全站零转场动画（最大体验短板）**：grep 全工程无任何 `pageTransition`/`animateTo`/`transition(`/`bindSheet`。主 Tab 切换、列表↔详情、列表↔编辑器全部 `if/else if` 整屏瞬切。→ 主内容切换加 `animateTo` 淡入/位移；详情/编辑器叠加用 `.transition` 或统一转场容器；`QuickCaptureSheet` 的 translate 范式可复用。
- **P1-10 弹层只有进入动画、无退出动画**：`QuickCaptureSheet.onCancel` 直接置 `false` 瞬消失（进入用 `setTimeout 50ms + translate`）；`ClothingDetailPage.PhotoPreviewOverlay` 进入无 `.transition`。→ 退出时用 `animateTo`/`.transition` 同步收起。
- **P1-11 套装墙 `Grid + ForEach` 未懒加载**：`OutfitsPage.ets:324-338` 与 `WardrobePage.ets:649` 的"美搭"墙用 `Grid+ForEach`，一次性构建全部 item；全工程无 `LazyForEach`。→ 改 `WaterFlow + FlowItem`（与衣橱/逛店一致）或 `Grid + LazyForEach` + `IDataSource`。
- **P1-12 偏好/风格/隐私切换无保存中态与防重入**：`ProfilePage.persistPreferences`（`:289-307`）被 `StyleTag`/`ToggleRow`/`PreferenceRow` 调用，无 `isSaving` 守卫、按钮不禁用、无 loading；快速连点多个风格标签会并发多次 `saveProfile` 写全量 profile。→ 抽取统一 `isSaving` 守卫（与 `saveProfile` 共用），切换期间禁用控件并显示轻量 loading。
- **P1-13 相册/拍照按钮缺"进行中"防重入**：`StoreVisitEditPage.pickGalleryPhotos/captureStorePhoto` 仅检查 `isSaving`（`:100/:113`），`WearLogEditPage.pickGalleryPhotos/capturePhoto` 连 `isSaving` 都未检查；异步选图期间用户可连点两次拉起选择器。→ 对齐 `CaptureEditPage` 的 `isChoosingPhotos` 守卫，进行中禁用按钮。
- **P1-14 全局 loading 仅文本，无 `LoadingProgress`**：`WardrobePage.ets:565`、`StoreVisitPage.ets:504`、`OutfitsPage.ets:253`、`ProfilePage`、`SearchResultsPage.ets:642` 等多为 `Text('正在加载…')` 或纯骨架屏。→ 关键首屏加载处加 `LoadingProgress()` 或品牌化 spinner。

---

## 四、P2 —— 次要级（后续迭代打磨）

### UI / 视觉
- **P2-1 图片圆角不统一**：规范"图片圆角 5"；违规（radius 18）`ClothingCard.ets:26`、`StoreVisitCard.ets:26`、`WardrobePage.ets:986`、`StoreVisitPage.ets:439/454`；同页 `WardrobeSearchResultCard(18)` 与 `OutfitResultCard(5)` 不一致。→ 统一 `YibuqueRadius.xs`(5)。
- **P2-2 输入/控件尺寸偏离规范（高 48 / 圆角 12）**：`SearchBar.ets:13` 高 44、`WearLogEditPage.ets:153,190` 高 44、`ClothingEditPage.ets:330` 名称输入高 42；`WishlistEditPage` 多处 `borderRadius(8)`、`StoreVisitEditPage` 输入 `borderRadius(24)`。→ 统一高 48、圆角 12；胶囊按钮 `YibuqueRadius.full`(999)。
- **P2-3 错误/空态暖粉调背景**：`OutfitsPage.ets:34` `ERROR_BG='#FFF3F3'`、`StoreVisitEditPage` `#FFF7F7/#FFF0F0` 不在 token 集。→ 用 `cardSoftGray`/`borderLight` 或新增 `dangerBg` token 统一管理。
- **P2-4 `QuickCaptureSheet` 内部色值近似非 token**：`#1C1C1E`（SHEET_PRIMARY）≠ `actionBlack #1D1D1F`，与 `#3A3A3C`/`#1D1D1F` 混用。→ 直接引用 `YibuqueColor.actionBlack`/`cardSoftGray`。
- **P2-5 `EmptyState` 无 CTA 槽位**：仅 title/description，无操作按钮，各页空态 CTA 风格易不一致。→ 增加可选 `actionLabel`/`onAction`，统一黑色 CTA。
- **P2-6 `CaptureEditPage` 录入字段缺分组标题，依赖 placeholder**：对比 `ClothingEditPage` 有"项目详情""购买信息"标题。→ 补 section 标题。
- **P2-7 token 命名误导**：`Tokens.ets` `bgBlueGray`/`bgHeaderBlue` 实际值 `#FFFFFF/#F5F5F7`（无蓝），建议重命名为 `surface`/`surfaceHeader`。

### 交互 / 动效
- **P2-8 大量裸图标/小按钮命中区 < 44×44**：`WardrobePage` 分类 Tab/主 Tab 高 42、`ClothingEditPage` 分类按钮 42、日期清除 `36×36`、`ProfilePage` 风格标签 32/编辑 38、`SearchResultsPage` 多 Tab 36/40、`ShoppingPage` 添加心愿 40、`WishlistEditPage`/`WearLogEditPage` 相册/拍照 40 等。→ 用透明 padding / `hitTestBehavior` / 包 44 容器补齐。
- **P2-9 `ShoppingPage` 输入即整屏切换搜索**：`SearchBar.onChange` 每字符即 `openUnifiedSearch` → 整屏替换为 `SearchResultsPage`，原框丢焦点。→ 改为回车/清空才切换，或本页就地筛选（已有 `filterWishlistItems`）。
- **P2-10 相机捕获会卸载主页面、丢失滚动/筛选态**：`startCameraCapture`→`openCaptureEditor` 使 Index `else if` 卸载 `WardrobePage` 等，保存返回后重建、状态全重置。→ 用 `Stack` 叠加保留底层实例，或保存/恢复滚动与筛选 `@State`。
- **P2-11 `StoreVisitPage` 刷新筛选无刷新中态**：`selectStatus` 的 `refresh` 直接 `loadStoreVisits()` 无 `isRefreshing` 锁。→ 加 `isRefreshing` 守卫 + 轻量指示。
- **P2-12 列表增删/排序无反馈动画**：`ClothingCard` 有入场 scale/opacity，但无 `SwipeToDelete`、无项增删/重排动画、无 `ListItem` 滑动操作。→ 为列表增删加 `animateTo`/`.transition`，考虑 `ListItem` 右滑删除。

### 功能 / 流程（次要）
- **P2-13 `WardrobeRuntime` 重复执行 schema 初始化**：先 `runMigrations()` 又 `ensureBaseSchema(database)`，冗余双跑延长冷启动。→ 二选一为唯一来源。
- **P2-14 `ClothingRepository.categoryFilterValues` 与 enum 不一致**：对 Top 扩展出 enum 不存在的分类值，UI 只能创建 5 种。→ 统一 domain enum 与 UI 可选项。

---

## 五、修复优先级路线图

**第一优先（P0，阻断可用性 / 数据真实性）**
1. P0-1 删除入口 + `AlertDialog` 确认（同时修 P1-1 注入 `photoStorage`，否则删图泄漏）。
2. P0-2 接入或砍掉心愿单。
3. P0-3 相机彩色阴影改中性黑。
4. P0-4 删除/重构 `TodayPage` 虚构社交内容。
5. P0-5 对齐 `QuickCaptureSheet` 为"拍一张/从相册选择"。
6. P0-6 实现或移除收藏爱心。

**第二优先（P1，一致性 / 健壮性）**
- 统一错误红：补 `YibuqueColor.danger` + 全量替换（P1-3）。
- 消除 token 本地复制与暖灰板：`WardrobePage`/`StoreVisitEditPage`/`ProfilePage`/`CaptureEditPage`/`OutfitsPage` 改用语义 token（P1-4/5/6）。
- 移除"待同步"暗示、补 WishlistEdit 标签（P1-7/8）。
- 照片复制失败不静默入库非本地 URI（P1-2）。
- 全站转场动画 + 弹层退出动画（P1-9/10）。
- 套装墙改懒加载（P1-11）。
- 偏好保存统一 `isSaving` + 相册选图加锁 + 全局 `LoadingProgress`（P1-12/13/14）。

**第三优先（P2，打磨）**
- 图片圆角统一 5、控件高 48 圆角 12、空态统一 CTA、命中区补 44、列表增删动画、状态保存恢复等。

> 说明：以上为纯静态审查结论，未经真机运行；P0 各项在运行时会被直接触发，建议优先验证。
