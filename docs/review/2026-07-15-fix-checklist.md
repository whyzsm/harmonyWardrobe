# Harmony Wardrobe 修复执行清单（重排版）

> **来源**：基于 `2026-07-15-three-line-review.md` 重排
> **重排原则**：不按严重度分层，而按两条线驱动 —— ①用户能不能用（功能阻断）②返工成本（改一次 vs 改多次）
> **P0 抽查已验证**：P0-1 / P0-2 / P0-3 / P0-6 已在真实代码中确认属实（2026-07-15）
> **勾选说明**：`[ ]` 待办 · `[x]` 完成 · 每项含「文件 / 验收标准」，做完打勾

---

## 批次一 · 让 App 恢复可用（半天内，最优先）

> 只做真正的功能断点。P0-1 与 P0-2 强耦合，**必须一起改**：P0-2 的附带问题（@Prop 不同步到 @State）正是 P0-1 子页切换机制的一部分，分开改会导致「从搜索跳转后无法切回衣物列表」。

- [x] **B1-1｜P0-1：旧衣橱复合子页切换需求已废弃**
  - 当前处理：衣柜页只保留衣物浏览、搜索、分类和双列瀑布流，不再维护复合子页切换。
  - 验收：不恢复旧子页组件、状态或入口。

- [x] **B1-2｜P0-2：穿着记录搜索结果跳转流程已收敛**
  - 当前处理：搜索遮罩关闭后由 `Index.ets` 统一跳转 `OutfitsPage`，再打开 `WearLogEditPage`。
  - 验收：点击 WearLog 搜索结果后，搜索页消失并进入独立的穿着记录编辑流程。

- [x] **B1-3｜P0-2 附带：旧子页路由同步任务已废弃**
  - 当前处理：不再为已废弃的衣橱复合子页增加路由同步机制；穿着记录统一由独立页面处理。
  - 验收：从搜索结果跳转后能关闭搜索并进入对应的穿着记录编辑流程。

- [ ] **B1-验收｜整体回归**
  - 搜索 → 点各类结果（衣物/穿搭/门店/心愿/穿着记录）均能正确关闭搜索并跳转
  - 衣柜衣物列表与套装页面可独立进入

---

## 批次二 · token 体系一次性收口（1-2 天）

> **最大优化点**：报告把 token 问题散在 P0-3/4/5、P1-11/12/13/14/17/19、P2-17/18/19/20 共十几处、分三阶段做。本质是同一件事，分批做等于同一文件反复打开、严重返工。这里合并为一个批次，**严格按下面顺序**：先补定义 → 再批量替换 → 最后人眼校验。

### 阶段 2A：先补/修 token 定义（后续替换都依赖它们，必须最先）

- [ ] **B2-1｜P1-17：新增半透明语义 token**
  - 文件：`Tokens.ets`（`YibuqueColor`）
  - 动作：新增 `scrimLight` / `scrimMedium` / `scrimStrong` / `glassLight` / `glassMedium`，覆盖反复硬编码的 `#00FFFFFF`、`#38FFFFFF`、`#D9FFFFFF`、`#29000000`、`#52000000` 等
  - 验收：token 定义齐全，值与原硬编码一致

- [ ] **B2-2｜P1-14 前置 + P2-19：补齐缺失 radius token**
  - 文件：`Tokens.ets`（`YibuqueRadius`）
  - 动作：评估 `19`、`22` 两个游离值 —— 新增 token 或对齐到现有值（建议对齐，减少 token 膨胀）
  - 验收：无游离 radius 值需要引用

- [ ] **B2-3｜P2-17：修正名不副实的 token（关键，防替换时踩坑）**
  - 文件：`Tokens.ets`
  - 现状：`bgBlueGray` 实为纯白、`bgHeaderBlue` 实为浅灰、`cardBlue` 实为浅灰
  - 动作：重命名为与实际值相符的语义名（如 `bgBase`/`bgHeader`/`cardSurface`），或修正值
  - 验收：token 名与实际颜色语义一致 —— **这步不做，阶段 2B 闭眼替换会把白色错换成名叫蓝灰实为白的 token**

### 阶段 2B：批量替换（建议脚本按文件扫描，机械但量大）

- [ ] **B2-4｜P0-3：删除三页面本地颜色常量**
  - 文件：`ProfilePage.ets:7-16`（10 个 `PROFILE_*`，80+ 引用）、`CaptureEditPage.ets:22-28`（7 个 `CAPTURE_*`，40+ 引用）、`OutfitsPage.ets:26-34`（9 个本地常量）
  - 现状核实：`CaptureEditPage.ets:22-26` 的 `CAPTURE_BG/SURFACE/TEXT/MUTED/META` 已确认存在
  - 动作：删除全部本地 const，替换为 `YibuqueColor.*` 对应 token
  - 验收：三文件无 `PROFILE_*`/`CAPTURE_*`/本地颜色 const

- [ ] **B2-5｜P0-4：StoreVisitEditPage 散落硬编码颜色**
  - 文件：`StoreVisitEditPage.ets:420-639`
  - 动作：`#444748`/`#1B1C1C`/`#C4C7C7`/`#000000`/`#FFFFFF`/`#00FFFFFF` 全量替换为 token
  - 验收：该文件无硬编码颜色字面量

- [ ] **B2-6｜P0-5：OutfitEditPage 硬编码颜色**
  - 文件：`OutfitEditPage.ets:211-285`
  - 动作：`#00000000`/`#99000000`/`#FFFFFF`/`#D9FFFFFF` 等替换为 token（半透明用 2A 新增的 scrim/glass）
  - 验收：无硬编码颜色

- [ ] **B2-7｜P1-11：旧 AppTheme 迁移至 YibuqueColor**
  - 文件：`WishlistEditPage.ets`、`WishlistCard.ets`、`SearchBar.ets`
  - 动作：`AppTheme.color.*` / `AppTheme.radius.*` → `YibuqueColor` / `YibuqueRadius`
  - 验收：5 文件无 `AppTheme.` 引用

- [ ] **B2-8｜P1-12：多页面散落硬编码颜色清理**
  - 文件：`ProfilePage.ets`、`CaptureEditPage.ets`、`WardrobePage.ets`、`StoreVisitPage.ets`、`SearchResultsPage.ets`、`Index.ets:376`、`AppTopBar.ets`、`SecondaryPageHeader.ets`、`ClothingEditPage.ets`、`ClothingDetailPage.ets:322`
  - 动作：`#8E8E93`/`#3A3A3C`/`#96969C`/`#626267` 等替换为 token
  - 验收：全项目颜色字面量清零（下方总校验统一验）

- [ ] **B2-9｜P1-13：硬编码 shadow → YibuqueShadow**
  - 文件：`BottomNavigationBar.ets`、`AppTopBar.ets`、`ProfilePage.ets`、`WardrobePage.ets`、`StoreVisitEditPage.ets:649`、`StoreVisitPage.ets:508`
  - 动作：统一用 `YibuqueShadow.card` / `.soft` / `.floating`
  - 验收：无硬编码 shadow 对象

- [ ] **B2-10｜P1-14 + P2-18/20：60+ 处 borderRadius → YibuqueRadius**
  - 文件：全项目（ProfilePage/CaptureEditPage/StoreVisitEditPage/OutfitEditPage/StoreVisitPage/WardrobePage/BottomNavigationBar/AppTopBar/OutfitCard/PhotoGrid/ClothingPicker 等）
  - 动作：5/12/14/16/18/19/22/24/28/999 全量替换为 token（`19`/`22` 已在 2B-2 处理）
  - 验收：无 `borderRadius(数字)` 字面量

- [ ] **B2-11｜P1-19：BottomNavigationBar 未选中态颜色**
  - 文件：`components/BottomNavigationBar.ets`
  - 动作：`#8D8D92` → `YibuqueColor.textTertiary`
  - 验收：无该硬编码值

### 阶段 2C：独立项 + 人眼校验

- [ ] **B2-12｜P0-6：相机图标渐变去除橙色（设计方向违规，非 token 迁移）**
  - 文件：`components/BottomNavigationBar.ets:62`
  - 现状核实：`colors: [['#F37A59', 0], ['#4578FF', 0.55], ['#56D0FF', 1]]` 含珊瑚橙
  - 动作：改为蓝色系单色或蓝色系渐变（如 `#1D1D1F`→`#4578FF`），去除 `#F37A59`
  - 验收：相机图标无橙色

- [ ] **B2-13｜阶段 2 总校验（必须人眼过一遍）**
  - 全局搜索确认无残留：`grep -rE '#[0-9A-Fa-f]{6,8}' entry/src/main/ets`（预期仅剩 Tokens.ets 定义处）
  - 全局搜索 `AppTheme.`、`borderRadius(数字)`、`PROFILE_`/`CAPTURE_` 均无业务代码命中
  - **逐页人眼看视觉**：因 2B-3 暴露过 token 名值不符，闭眼替换可能错换白/灰，务必肉眼确认每页颜色无变化

---

## 批次三 · 交互健壮性（内部按「防数据错乱 > 防体验受损 > 纯打磨」排序）

> 报告把 6 个交互项平铺，这里按危害重排：先修「用户以为存了其实没存」，最后才做纯动效。

### 3A：防数据错乱（最高优先，会导致数据丢失/不一致）

- [ ] **B3-1｜P1-7：ProfilePage 偏好保存竞态**
  - 文件：`ProfilePage.ets:299-320, 709-720, 937-942`
  - 问题：快速切第二个开关时 `persistPreferences` 因 `isSaving=true` return，保存后 `applyProfile` 覆盖回滚，操作被静默丢失
  - 动作：保存期间禁用所有开关 `.enabled(!this.isSaving)`，或将状态变更推迟到保存成功后
  - 验收：连续快速切换多个开关，全部正确持久化，无回弹

- [ ] **B3-2｜P1-5：三编辑页选图缺防重入 + try/catch**
  - 文件：`OutfitEditPage.ets:94-110`、`WearLogEditPage.ets:75-91`、`WishlistEditPage.ets:78-94`
  - 参照标杆：`ClothingEditPage.ets:204-244`、`StoreVisitEditPage.ets:102-142`
  - 动作：加 `isChoosingPhotos` 状态守卫、try/catch/finally、按钮 `.enabled(!this.isSaving && !this.isChoosingPhotos)`
  - 验收：取消选图无 unhandled rejection；快速连点不并发拉起多个选择器

- [ ] **B3-3｜P1-6：CaptureEditPage 选照片按钮保存期未禁用**
  - 文件：`CaptureEditPage.ets:178, 297`
  - 动作：`.enabled(!this.isChoosingPhotos)` → `.enabled(!this.isChoosingPhotos && !this.isSaving)`
  - 验收：保存中无法触发选图

- [ ] **B3-4｜P2-1：可点击区域统一 ≥44×44（提前到本批，与上面改同批文件）**
  - 文件：WardrobePage/ShoppingPage/StoreVisitPage/OutfitsPage/ClothingDetailPage/ProfilePage/SearchResultsPage 等（35 处）
  - 动作：重试按钮 34vp、补记按钮 38vp、编辑 Text ~20px 等命中区补足到 44×44
  - 验收：抽查主要可点击元素命中区 ≥44×44

### 3B：防体验受损

- [ ] **B3-5｜P1-8：ShoppingPage 搜索框每键跳转**
  - 文件：`ShoppingPage.ets:222-229`
  - 动作：`onChange` 改为 `onSubmit` 触发，或加 debounce + 最小字符数门槛
  - 验收：能完整输入关键词后再跳搜索结果

- [ ] **B3-6｜P1-9：三处列表改 LazyForEach**
  - 文件：`WardrobePage.ets:696-712`（美搭子页）、`SearchResultsPage.ets:555-561`、`ClothingPicker.ets:59`
  - 参照：`WardrobePage.ets:988-1004`（衣裤列表 WaterFlow + LazyForEach）
  - 动作：改用 `LazyForEach` + `IDataSource`（复用已有 ArrayDataSource）
  - 验收：大数据量下首屏与滚动流畅

### 3C：纯打磨（工作量大，不与数据正确性抢工期，可分批）

- [ ] **B3-7｜P1-10：全局页面/弹层转场动画**
  - 文件：全局（现仅 QuickCaptureSheet、ClothingCard 有）
  - 动作：编辑器/详情页/嵌套页进出加 `.transition()`（Opacity + translate）；Index.ets Stack 叠加层加遮罩淡入；底层可见时禁用交互
  - 验收：页面切换有过渡，底层不被穿透点击

---

## 批次四 · P2 收尾（后续迭代）

> 采纳报告 TOP 5，其中 P2-1 已提到批次三。

- [ ] **B4-1｜P2-15：死代码清理**
  - 文件：`ClothingCard.ets`、`OutfitCard.ets`、`StoreVisitCard.ets`
  - 验收：旧 UI 死代码不回流；当前页面只保留已接入的组件

- [ ] **B4-2｜P2-6：各 Edit 页保存成功 Toast 反馈**
  - 文件：ClothingEditPage/OutfitEditPage/StoreVisitEditPage/WearLogEditPage/WishlistEditPage
  - 验收：保存成功有统一 Toast

- [ ] **B4-3｜P2-5：日期选择器统一**
  - 文件：`WearLogEditPage.ets:198`、`CaptureEditPage.ets:542`
  - 动作：纯文本输入改为日期选择器
  - 验收：日期字段统一用选择器

- [ ] **B4-4｜P2-7：列表卡片 pressed 触感反馈**
  - 文件：WardrobePage/OutfitsPage/StoreVisitPage/ShoppingPage 卡片
  - 验收：卡片按压有视觉反馈

- [ ] **B4-5｜其余 P2**（按需）
  - P1-15 placeholderColor 改 textTertiary（`ClothingEditPage.ets:451,475,551`）
  - P1-16 旧页面标题字号问题已随页面移除，不纳入当前验收
  - P1-18 SearchBar 高度 44→48
  - P2-2/3/4/8/9/10、P2-11~14/16 见原报告

---

## 进度总览

| 批次 | 主题 | 项数 | 预估 | 状态 |
|------|------|------|------|------|
| 一 | 恢复可用（真功能阻断） | 3 | 半天 | ☐ |
| 二 | token 一次性收口 | 13 | 1-2 天 | ☐ |
| 三 | 交互健壮性 | 7 | 2-3 天 | ☐ |
| 四 | P2 收尾 | 5+ | 迭代 | ☐ |

**核心重排逻辑**：①7 个 P0 拆成「2 个真阻断 + 5 个设计违规」，只有前 2 个进批次一；②散落十几处的 token 问题合并成带前置顺序的一个批次；③交互批次内部按危害排序，数据正确性优先于动效打磨。
