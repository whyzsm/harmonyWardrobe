# 衣橱质量评审团 · 完整三线评审报告

- **评审对象**：HarmonyOS 本地优先衣橱应用 Harmony Wardrobe / 衣不缺
- **评审团**：衣橱质量评审团（wardrobe-review-team）— 顾审之（主理人）/ 程维序（功能流程）/ 颜守白（UI 视觉）/ 滑如丝（交互动效）
- **评审方式**：纯静态代码审查（未运行真机、未改动任何文件），三线并行、主理人去重汇编
- **审查范围**：`entry/src/main/ets`（pages / components / domain / data / media / utils / theme）+ 设计规范 `docs/background/yibuque-design.md` + 主题 token `theme/Tokens.ets`
- **日期**：2026-07-14

> 状态：历史静态评审。后续提交已修复或改变部分结论，本文保留当时快照事实，不作为当前实现状态判断。

---

## 一、总览

综合健康度 **≈ 5.3 / 10**。分层架构、迁移链、搜索索引一致性、照片复制管线（除 ClothingEditPage 外）基础扎实；但**删除链路全线缺失**、**心愿单整域不可达**、**媒体回收未接线**、以及若干**设计方向硬违规（彩色阴影 / 粉色错误态 / 虚构社交数据 / 远程同步暗示）**必须在上线前清除。

### 健康度评分（分维度）

| 维度 | 评分 | 一句话结论 |
|---|---|---|
| 功能与流程 | 5.5 / 10 | 数据层扎实，但删除全线缺失、心愿单不可达、媒体回收未接线 |
| UI 与视觉 | 5.8 / 10 | 共享组件大多合规，但彩色阴影 / 粉色错误态 / 虚构内容 / 错误红不统一须返工 |
| 交互与动效 | 4.5 / 10 | 保存防重合格，但零转场、零懒加载、零 LoadingProgress 拉低体验 |

### 发现数量统计

| 严重级 | 数量 | 含义 |
|---|---|---|
| **P0（阻断）** | 7 | 功能断点 / 存储泄漏 / 数据真实性红线 / 明显违反设计方向 |
| **P1（重要）** | 14 | 数据不一致风险 / token 不一致 / 约束违反 / 缺失必要反馈 |
| **P2（次要）** | 11 | 视觉瑕疵 / 动效润色 / 健壮性 / 死代码 |

---

## 二、P0 清单（阻断级，必须修复）

### P0-1 删除（D）功能在全部 UI 中缺失
- **来源**：程维序（功能流程 P0-1）
- **位置**：repository 删除方法均已实现但页面零调用——`ClothingRepository.ets:336` `deleteClothing`、`OutfitRepository.ets:315` `deleteOutfit`、`WearLogRepository.ets:303` `deleteWearLog`、`WishlistRepository.ets:245` `deleteWishlistItem`、`StoreRepository.ets:440` `deleteStoreVisit`；`pages/**` 下以 `delete|remove|删除|onDelete|AlertDialog` 检索几乎无匹配（唯一命中 `ClothingDetailPage.ets:451` 一句"可能已经被删除"提示文案）
- **问题**：衣物 / 穿搭 / 穿着 / 心愿 / 逛店均只有 C/R/U，D 全线缺席，无删除入口与确认弹窗。
- **影响**：用户无法删除数据，隐私内容无法清除，数据无限膨胀。
- **建议**：在各列表 / 详情页增加删除入口 + 确认弹窗，接入对应 `repository.delete`，并通过 `DeleteCleanupService` 联动清理媒体文件与搜索索引。

### P0-2 删除时媒体文件泄漏（photoStorage 未注入 DeleteCleanupService）
- **来源**：程维序（功能流程 P0-3）
- **位置**：`app/WardrobeRuntime.ets:160` 创建 `photoStorage`，仅传构造 `:172-173` 供 pages 用，从不传 repositories；各 repository 组装 `DeleteCleanupService` 时均未传 `photoStorage`（如 `ClothingRepository.ets:382-384`、`OutfitRepository.ets:372-374`、`WearLogRepository.ets:355-357`、`WishlistRepository.ets:289-291`、`StoreRepository.ets:306`）；`data/DeleteCleanupService.ets:16,21-26`（`photoStorage` 可选）、`:37`（`if (this.photoStorage !== undefined)` 才删文件）、`:87-94`（无 photoStorage 直接返回"未删除"）
- **问题**：删除链路未接线，JPEG 永久残留在 `filesDir/photos/`。
- **影响**：一旦启用 P0-1 删除，照片文件将永久泄漏，存储无限增长 —— 存储泄漏型缺陷。
- **建议**：在 `WardrobeRuntime` 装配时把 `photoStorage` 注入所有涉及删除的 repository / `DeleteCleanupService`，确保删除对象时一并清理本地图片。

### P0-3 购物心愿（Wishlist）整域不可达
- **来源**：程维序（功能流程 P0-2）
- **位置**：`pages/ShoppingPage.ets` / `pages/WishlistEditPage.ets`（两页引用 `wishlistRepository`，但均未被 `Index.ets` 或其它页面 import，死代码）；`pages/Index.ets` 底部导航仅 4 标签 + 相机，无心愿入口；`pages/SearchResultsPage.ets` 把 Wishlist 结果路由到 profile 死路
- **问题**：心愿单功能完整却从未被导航接入，等于未交付，相关代码全为死代码。
- **影响**：用户无法访问心愿单，整域功能失效。
- **建议**：在底部导航 / `Index.ets` 接入 `ShoppingPage`（或直接在首页提供心愿入口），并修复心愿搜索结果点击路由。

### P0-4 TodayPage 伪造社交内容（数据真实性红线）
- **来源**：颜守白（UI 视觉 P0-3） + 滑如丝（交互动效 P0-1，双专家标记）
- **位置**：`pages/TodayPage.ets:354-492`（`buildAllItems` / `CardView`：虚构作者 `衣橱灵感社 / 小蓝穿搭 / 天气穿搭簿`、`metaText:'♡ 128'`、假点赞 / 评论入口、死社交 tab 骨架）
- **问题**：以"推荐灵感"为名伪造点赞数、作者名、评论等本不存在的远程社交 / 用户记录，直接违反「禁止虚构网络同步、用户记录」「不显示不存在的远程同步能力」。
- **影响**：当前为孤儿页未接入，但属"潜伏型红线地雷"——一旦接回即构成线上数据真实性违规。
- **建议**：直接删除该页；若需灵感位，仅展示用户本地已录入内容，且不得伪造点赞 / 作者 / 评论语义。**切勿原样接回。**

### P0-5 "待同步"标签暗示不存在的远程同步（数据真实性红线）
- **来源**：滑如丝（交互动效 P0-2） + 程维序（功能流程 P1，双专家标记）
- **位置**：`pages/WardrobePage.ets:27-34`（`WARDROBE_CATEGORY_FILTERS` 含 `{ label: '待同步', categories: [] }`）；使用处 `:182-184`
- **问题**：标签名"待同步"强烈暗示云端同步能力（红线），且该筛选项 `categories=[]` → `selectedCategories()` 返回 undefined → 实际等价于"显示全部"，是功能性空操作（no-op）+ 语义误导。
- **影响**：误导用户以为有同步后台，违反数据真实性规则。
- **建议**：删除"待同步"标签；若确要表达未归类，改名为"未分类"且真正按未归类项过滤。

### P0-6 底部导航相机图标彩色阴影 #735A7CFF
- **来源**：颜守白（UI 视觉 P0-1）
- **位置**：`components/BottomNavigationBar.ets:65`（`.shadow(...)` 用蓝紫 `#735A7CFF`）
- **问题**：全站唯一一处彩色阴影，其余皆为中性黑透明；违反「阴影必须中性黑色透明，不可彩色」。
- **影响**：明显违反设计方向。
- **建议**：改为中性黑透明阴影（如 `rgba(0,0,0,0.2)` 或对应 token），与全站一致。

### P0-7 StoreVisitEditPage 错误态使用粉色系
- **来源**：颜守白（UI 视觉 P0-2）
- **位置**：`pages/StoreVisitEditPage.ets`（错误态背景 / 边框用 `#FFF7F7 / #F3B8B8 / #FFF0F0`）
- **问题**：违反「严禁旧 Rose VI 粉色（背景 / 边框）」。
- **影响**：明显违反设计方向，粉色阴影 / 边框残留。
- **建议**：改用中性浅灰错误表面 + 统一错误红 token（见 P1-1）。

---

## 三、P1 清单（重要级，修复 P0 时一并治理）

### P1-1 错误红三态不统一（#EF4444 / #DC2626 / #BA1A1A）且 YibuqueColor 缺 danger 字段
- **来源**：颜守白（UI 视觉 P1-1）
- **位置**：`theme/Tokens.ets`（`YibuqueColor` 缺 `danger`；`AppTheme.danger = #DC2626`）；`pages/Index.ets`（硬编码 `#EF4444`）；其余处 `#BA1A1A`
- **问题**：错误红三态共存，根因是 token 缺 `danger` 字段，逼得页面硬编码。
- **建议**：在 `YibuqueColor` 补 `danger: #DC2626`，全站改用 token，消除 `#EF4444` 等硬编码。

### P1-2 ClothingEditPage 相册选图静默保留非本地 URI
- **来源**：程维序（功能流程 P1）
- **位置**：`pages/ClothingEditPage.ets:216-231`（`pickGalleryPhotos` 先用原始非本地 URI 预填 `photoUris`，复制失败仅 `console.info` 并保留非本地 URI）
- **问题**：违反「照片只存应用本地、SQLite 只存本地 URI」硬约束（其余编辑器均为失败即空，唯独此处违规）。
- **建议**：复制失败即清空 `photoUris`；正式入库前一律用复制后的本地 URI；对齐其余编辑器的"失败即空"做法。

### P1-3 ClothingEditPage / StoreVisitEditPage 相册选图缺 isChoosingPhotos 防重
- **来源**：滑如丝（交互动效 P1-4）
- **位置**：`pages/StoreVisitEditPage.ets:99-110`（仅守 `isSaving`，无 `isChoosingPhotos`）；`pages/ClothingEditPage.ets:203-235`（连 `isSaving` 都不守）
- **问题**：相册 / 拍照选择缺少"选择中"防重守卫，可在前一次 picker 未返回时再次拉起，造成重复拉起、状态混乱（ClothingEditPage 最严重）。
- **建议**：统一引入 `@State isChoosingPhotos`；入口 `if (this.isSaving || this.isChoosingPhotos) return; this.isChoosingPhotos = true; try { ... } finally { this.isChoosingPhotos = false; }`，并 `.enabled(!isChoosingPhotos)`。

### P1-4 rebuildSearchIndex 定义后无调用方（索引"可重建"保证未接线）
- **来源**：程维序（功能流程 P1）
- **位置**：`data/repositories/SearchRepository.ets:258`（`rebuildSearchIndex` 已实现，全仓无调用方）；`data/searchIndex/SearchIndexSchema.ets`、`SearchCapability.ets`（`detectSearchCapability` 建表不在迁移链中）
- **问题**：搜索索引"可重建"的架构保证未接线，存量数据先行时搜索会静默失效。
- **建议**：在迁移完成 / 数据修复路径显式调用 `rebuildSearchIndex`；或提供手动重建入口。

### P1-5 穿着日志 / 心愿单搜索结果路由错误
- **来源**：程维序（功能流程 P1）
- **位置**：`pages/SearchResultsPage.ets:46,270,623`（Wishlist 标为 profile scope）、`:279-289`（WearLog / Wishlist → `onOpenProfileResult`）；`pages/Index.ets:267-285`（`onOpenSearchTarget` 把 Outfit/Store 之外一律回退 profile）
- **问题**：穿着日志、心愿单搜索结果点击路由错误，用户点不到正确详情。
- **建议**：修正点击路由到对应详情页 / 列表。

### P1-6 StoreVisitEditPage 整页暖灰板、WardrobePage OPEN_DESIGN_* 暖色本地副本，脱离冷灰 token
- **来源**：颜守白（UI 视觉 P1）
- **位置**：`pages/StoreVisitEditPage.ets`（整页暖灰背景）、`pages/WardrobePage.ets`（`OPEN_DESIGN_*` 暖色常量本地副本）
- **问题**：与全站冷灰 token 体系脱节，暖灰板偏离设计方向。
- **建议**：统一使用冷灰 token，删除本地暖色副本或纳入 token 体系。

### P1-7 QuickCaptureSheet 做成三导航入口，偏离规范两动作录入面板
- **来源**：颜守白（UI 视觉 P1）
- **位置**：`components/QuickCaptureSheet.ets`（做成「衣柜 / 逛店 / 穿搭」三个导航入口）
- **问题**：规范要求的「快捷录入」是"拍一张（黑卡白相机）/ 从相册选择（浅灰卡灰边）"两动作面板，实际做成导航。
- **建议**：改为规范的两动作录入面板（黑卡"拍一张" + 浅灰卡"从相册选择"），标题"快捷录入"、取消黑色。

### P1-8 图片圆角不统一
- **来源**：颜守白（UI 视觉 P1）
- **位置**：`components/ClothingCard.ets` / `StoreVisitCard.ets`（圆角 18）vs `OutfitCard.ets` / `PhotoGrid.ets`（圆角 5）
- **问题**：同一应用内图片圆角尺度割裂，规范图片圆角 5、内容卡 12-18 需区分清楚。
- **建议**：按 token 统一图片与内容卡圆角。

### P1-9 WearLogEditPage / WishlistEditPage 表单仅依赖 placeholder
- **来源**：颜守白（UI 视觉 P1）
- **位置**：`pages/WearLogEditPage.ets`、`pages/WishlistEditPage.ets`（后者还使用开发态键名作标签）
- **问题**：违反「表单标题必须清晰，不能只靠 placeholder」；WishlistEditPage 标签是开发态键名，用户体验差。
- **建议**：补清晰表单标签；WishlistEditPage 替换为正式中文标签。

### P1-10 全站零转场动画（transition / animateTo / pageTransition 均为 0）
- **来源**：滑如丝（交互动效 P1-1）
- **位置**：`pages/Index.ets:171-417`（所有编辑器 / 页均用 if/else 硬切换）；`WardrobePage.ets:474-674`、`OutfitsPage.ets:218-343`、`StoreVisitPage.ets:237-277`、`ClothingDetailPage.ets:434-508`（if/else 切换）
- **问题**：编辑器、详情页、搜索页、设置面板全部"瞬现 / 瞬隐"，无进入 / 退出过渡；底层被遮盖时未用 `.enabled(false)` 显式禁用交互。
- **建议**：编辑器 / 弹层改用 `.transition()` + `animateTo` 对称进出；主标签切换用 `animateTo`；叠加层打开时底层容器 `.enabled(false)`。

### P1-11 列表无懒加载（LazyForEach 0 处）
- **来源**：滑如丝（交互动效 P1-2）
- **位置**：`WardrobePage.ets:943-949`（WaterFlow+ForEach）、`StoreVisitPage.ets:412-418`（WaterFlow+ForEach）、`OutfitsPage.ets:324-330`（Grid+ForEach）、`SearchResultsPage.ets:546-552`（List+ForEach）
- **问题**：均非 LazyForEach+IDataSource，数据量大时一次性构建全部节点，滚动性能与内存隐患。
- **建议**：WardrobePage / StoreVisitPage 改 LazyForEach+IDataSource；OutfitsPage / SearchResultsPage 评估懒加载。

### P1-12 ProfilePage persistPreferences 绕过 isSaving 守护（写竞态）
- **来源**：滑如丝（交互动效 P1-3）
- **位置**：`pages/ProfilePage.ets:289`（`persistPreferences` 直接 `this.profileRepository.saveProfile(...)`）；调用点 `:660-661`（试穿偏好）、`:696-706`（风格标签）、`:924-926`（隐私模式）；主 `saveProfile()` 在 `:198` 有 `if (this.isSaving) return;` 守护
- **问题**：`persistPreferences` 走仓储方法而非带守护的方法，快速点开关会并发多个 `saveProfile`，存在写覆盖 / 竞态且无防抖。
- **建议**：`persistPreferences` 复用 `isSaving` 互斥（进入置位、finally 复位），或合并到统一 `saveProfile` 路径；偏好切换与保存按钮共用同一守护。

### P1-13 全站无 LoadingProgress（0 处）
- **来源**：滑如丝（交互动效 P1-5）
- **位置**：各 Edit 页保存按钮（CaptureEditPage / StoreVisitEditPage / ClothingEditPage / OutfitEditPage / WearLogEditPage / WishlistEditPage / ProfilePage）；grep 确认全工程 `LoadingProgress = 0`
- **问题**：保存防重（`.enabled(canSave())`）已落实，但"显示 loading"仅以按钮文案变化 + 禁用态体现，缺明确加载指示器；长耗时保存（写库 + 图片落盘）时用户易误以为卡死而重复点击。
- **建议**：`isSaving` 期间按钮内联 `LoadingProgress` + 禁用态；异步加载 / 空 / 错均有可见友好态（`StoreVisitPage` 的 loading/empty/error 结构可复用为范本）。

### P1-14 OutfitsPage Grid 嵌套 Scroll（滚动冲突）
- **来源**：滑如丝（交互动效 P1-6）
- **位置**：`pages/OutfitsPage.ets:324-330`（Grid 置于 Scroll 内，Grid 未给显式高度）
- **问题**：Grid 自带滚动语义再套 Scroll，易产生手势 / 高度计算冲突，滚动体验割裂。
- **建议**：用 WaterFlow（与 WardrobePage 一致）或 List+GridItem，避免 Grid 再套 Scroll。

---

## 四、P2 清单（次要级，打磨与健壮性）

### P2-1 孤儿 / 死代码页与组件
- **来源**：程维序（功能流程 P2） + 滑如丝（交互动效 P2-7，双专家标记）
- **位置**：`TodayPage` / `ShoppingPage` / `WishlistEditPage` / `CategoryTabs` / `OutfitCard` / `StoreVisitCard` / `AppTopBar`（全站 0 import 引用）
- **问题**：大量不可达代码滞留构建中，属维护负担；其中 TodayPage 虚构数据是红线地雷（见 P0-4）。
- **建议**：统一清理或从导航接入；接入前先解决其 P0/P1/P2。

### P2-2 WardrobePage CardHeart 假控件（无 onClick）
- **来源**：滑如丝（交互动效 P2-1）
- **位置**：`pages/WardrobePage.ets:1055-1067`（`CardHeart()` 渲染心形图标 + 30×30 阴影框，整段无 `.onClick`）
- **问题**：视觉像可点收藏按钮，实际点击无响应；且 30×30 即使补 onClick 也不足 44×44。
- **建议**：接真实收藏态切换 + `.onClick` + 扩热区 ≥44×44，或移除该装饰。

### P2-3 多处可点击命中区 < 44×44
- **来源**：滑如丝（交互动效 P2-2）
- **位置**：`WardrobePage.ets`（分类 / 主标签 `.height(42)`、搜索图标 `.width(22)`）、`OutfitsPage.ets`（"记录穿着" 文字 ~11-15px）、`SearchResultsPage.ets`（返回 / 清除× / 相机 34px、"搜索" 36px、tabs 36、chips 40）、`ProfilePage.ets`（StyleTag `.height(32)`）、`ClothingEditPage.ets`（清除日期 × 36×36）
- **问题**：部分热区不达 44×44 规范，小屏 / 拇指操作易误触。
- **建议**：图标按钮用 padding / `.hitTestBehavior` 扩到 ≥44×44；标签 / 文字按钮 min-height 44（或外扩透明热区）。`BottomNavigationBar`(52) / `SecondaryPageHeader`(48) 为达标范本。

### P2-4 QuickCaptureSheet 仅入场动画无对称退场
- **来源**：滑如丝（交互动效 P2-3）
- **位置**：`components/QuickCaptureSheet.ets:23-28`（进场）+ `:79-83`（动画）；退场仅靠 `onCancel` 直接关闭
- **建议**：用 `.transition()` + `animateTo` 做对称进出，遮罩点击关闭保留。

### P2-5 ClothingCard 入场动画用 setTimeout 脆弱实现
- **来源**：滑如丝（交互动效 P2-4）
- **位置**：`components/ClothingCard.ets:12-17`（`aboutToAppear` 里 `setTimeout 50ms` 改 `cardOpacity/cardScale`）
- **问题**：入场淡入依赖 setTimeout，易因渲染时序丢失动画，不可控。
- **建议**：改用 item 级 `.transition()` 或 `onAppear` + `animateTo`，统一错落入场。

### P2-6 ClothingDetailPage PhotoPreviewOverlay 无淡入
- **来源**：滑如丝（交互动效 P2-5）
- **位置**：`pages/ClothingDetailPage.ets:501-508`（`if (this.showPhotoPreview)` 直接挂载，无过渡）
- **建议**：叠加层用 `.transition({ type: Opacity/Scale })` + `animateTo` 淡入缩放；下滑 / 点击关闭已支持，保留。

### P2-7 Index.ets 底部导航隐藏条件遗漏 showQuickActions
- **来源**：滑如丝（交互动效 P2-6）
- **位置**：`pages/Index.ets:351`（条件 `!showCaptureEditor && !showStoreEditor && !showQuickStoreEditor && !showClothingEditor && !showNestedPage` 未含 `showQuickActions`）
- **问题**：QuickCaptureSheet 展开时底层底部导航仍可能渲染在下层（依赖遮挡掩盖），叠放 / 误触有隐患，且与其他编辑器隐藏逻辑不一致。
- **建议**：补 `&& !this.showQuickActions`，保持叠加态下底层一致隐藏。

### P2-8 StoreRepository 无 deleteStore
- **来源**：程维序（功能流程 P2）
- **位置**：`data/StoreRepository.ets`（缺 `deleteStore`，配合删除链路 P0-1）
- **建议**：补充 `deleteStore` 并在 StoreVisit 删除入口调用。

### P2-9 冗余迁移 / 废弃常量 / 未用状态标志 / categoryFilterValues 隐藏超集
- **来源**：程维序（功能流程 P2）
- **位置**：`data/*`（`ensureBaseSchema` 冗余重跑迁移）、`theme`（多处理废弃主题常量）、`pages/Index.ets`（未用状态标志）、`WardrobePage`（`categoryFilterValues` 隐藏超集）
- **建议**：清理冗余，统一状态管理，移除废弃常量。

### P2-10 StoreVisitPage 误标「刷新 / refresh」筛选项
- **来源**：程维序（功能流程 P2）
- **位置**：`pages/StoreVisitPage.ets`（筛选项文案 "刷新/refresh"，本地语义不符）
- **建议**：更正文案为本地语义（如"全部 / 按店筛选"）。

### P2-11 零散视觉瑕疵（本地 token 副本 / 非 token 灰值 / 暖灰 PhotoSelector / 淡粉错误底 / TodayPage 圆角 / "同步"措辞 / 空态 CTA / 底栏选中态）
- **来源**：颜守白（UI 视觉 P2，8 项）
- **位置**：`OutfitEditPage.ets`（暖灰 PhotoSelector）、`OutfitsPage.ets`（淡粉错误底）、`TodayPage.ets`（圆角）、各页行内非 token 灰值、空态 CTA、底栏选中态等
- **建议**：统一 token，消除暖灰 / 淡粉 / 非 token 灰，修正"同步"类措辞与空态 CTA 文案。

---

## 五、修复优先级路线图

> 先 P0（阻断 / 红线）→ 再 P1（一致性 / 反馈 / 性能）→ 后 P2（打磨）。括号内为来源专家。

### 阶段一：P0 清零（上线前必做）
1. **删除链路打通 + 媒体回收接线**（P0-1 + P0-2，程维序）：补删除入口 / 确认弹窗 → 注入 `photoStorage` 到 `DeleteCleanupService` → 删除时清理本地图与索引。
2. **心愿单接入导航**（P0-3，程维序）：接入 `ShoppingPage` / 心愿入口 + 修正搜索结果路由。
3. **清除虚构数据与远程同步暗示**（P0-4 + P0-5，颜守白 + 滑如丝）：删除 `TodayPage` 或改写为纯本地；移除"待同步"标签。
4. **设计方向硬违规**（P0-6 + P0-7，颜守白）：底部导航相机阴影改中性黑；`StoreVisitEditPage` 错误态去粉色。

### 阶段二：P1 治理（质量与一致性）
- 统一错误红 token（P1-1，颜守白）
- 照片本地 URI 约束 + 选图防重（P1-2 + P1-3，程维序 + 滑如丝）
- 搜索索引重建接线 + 路由修正（P1-4 + P1-5，程维序）
- 视觉 token 收口：暖灰板、QuickCaptureSheet 两动作、圆角、表单标签（P1-6 ~ P1-9，颜守白）
- 动效与性能：转场动画、LazyForEach、LoadingProgress、Profile 写竞态、OutfitsPage 嵌套滚动（P1-10 ~ P1-14，滑如丝）

### 阶段三：P2 打磨（健壮性 / 体验细节）
- 死代码清理（P2-1，程维序 + 滑如丝）
- 点击区 ≥44、假收藏控件、转场对称、setTimeout 入场、预览淡入、底栏条件补全（P2-2 ~ P2-7，滑如丝）
- 删除仓储补齐、冗余清理、文案修正（P2-8 ~ P2-10，程维序）
- 零散视觉瑕疵（P2-11，颜守白）

---

## 六、各维度健康度小结（来自三位专家）

**功能与流程（程维序）**：分层、迁移链、搜索索引（FTS5 外部内容表 + fallback ngram）一致性、repository 级 C/U/R 与照片复制管线（除 ClothingEditPage 外）均扎实；主要风险集中在**删除链路全缺 + 媒体回收未接线**以及**心愿单整域失效**。

**UI 与视觉（颜守白）**：基础架构与共享组件大多合规；优先修复 P0-6 / P0-7 与 P1-1（补 `YibuqueColor.danger` 并统一错误红）即可消除绝大多数风险。健康度 ≈ 58/100（B-，需返工关键项）。

**交互与动效（滑如丝）**：保存防重 B+、可点击区域 B-、转场与动效 D（全站零过渡）、列表性能 C、数据真实性 C（含潜伏 P0）。最该补动效的 5 处：①编辑器 / 弹层对称进出场；②保存按钮 LoadingProgress；③列表错落入场替代 setTimeout；④主标签切换平滑；⑤预览层 / QuickCaptureSheet 退场补齐。

---

> 本报告为纯静态审查结论，未改动任何文件。每条均附 `文件:行号`、影响与建议修复，可直接作为修复补丁的工单来源。
