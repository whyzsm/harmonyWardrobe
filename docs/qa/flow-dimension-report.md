# 流程维度验收表（端到端跨模块流程贯通）

> 验收专家：流程测试专家（程贯通）兜底执行体 flow-fallback
> 基线：`docs/qa/manual-test-script.md`
> 代码范围：`entry/src/main/ets`（pages / components / data / domain / media / utils / app）
> 说明：本维度只核对「入口 → 操作 → 状态变化 → 闭环/出口」的路由、状态变量与保存回写逻辑，不做像素级视觉与真实手感判断。当前无真机/模拟器，凡涉及真实回显、手感、重启持久化者均标注「待真机验证」。

## 流程维度覆盖率

- 已枚举跨模块旅程：**16** 条
- 路由/状态/保存回写逻辑**静态可验证走通**：**13** 条
- 存在**文案/旧概念口径偏差但路由正确**：**3** 条（J16、J17、J18）
- 覆盖率（静态走通 / 总旅程）：**13 / 16**
- 需真机复核项：离线保存后重启回显、删除后孤立媒体清理、选中指示视觉、各列表真实回显手感。

---

## 旅程明细

### J1 核心录入闭环·衣物（相机/相册 → 衣橱 → 回衣柜列表回显）
- 步骤：底部相机 → 快捷面板「衣柜」→ ClothingEditPage → 选图（相册/拍照）→ 填名/分类/备注/购买信息 → 保存 → 回衣柜
- 预期流转：归类衣橱；未选图不可保存并提示；保存后列表出现新衣物（图+名+分类）；退出再进仍可见
- 实际流转：
  - QuickCaptureSheet「衣柜」→`openQuickClothingEditor()`→`AppRouteKind.ClothingEditor`/`AppMainTab.Wardrobe`（Index.ets:175-183）
  - `ClothingEditPage.canSave()` 要求 `photoUris.length>0`，按钮文案「先选择照片」/「保存衣物」（ClothingEditPage.ets:119-125, 584）
  - 保存 `clothingRepository.createClothing` 写 SQLite（ClothingRepository.ets:264-284），`onSave`→`closeQuickClothingEditor`→`resetMainRoute(Wardrobe)`→重新挂载 WardrobePage，`aboutToAppear`→`loadClothingItems` 回显（Index.ets:185-188；WardrobePage.ets:56-58, 321-327）
- 结论：**通过（静态）**；真实回显/重启持久化「待真机验证」
- 证据：`Index.ets:175-188`、`ClothingEditPage.ets:119-125,267-286`、`ClothingRepository.ets:264-283`、`WardrobePage.ets:56-58,321-327`

### J2 核心录入闭环·美搭（穿搭 → 美搭 → 回穿搭列表回显）
- 步骤：底部相机 → 快捷面板「穿搭」→ OutfitEditPage → 选图/选关联衣物/填名 → 保存 → 回穿搭
- 预期流转：归类为美搭；名称可空（生成默认「美搭 HH-MM…」）；保存回穿搭且卡片回显
- 实际流转：
  - QuickCaptureSheet「穿搭」→`openQuickOutfitEditor()`→`AppRouteKind.OutfitEditor`/`AppMainTab.Outfit`（Index.ets:190-205, 331-348）
  - 默认名 `generatedOutfitTitle()`=「美搭 ${time}」（CaptureEditPage.ets:126-128；OutfitEditPage 同口径）
  - 保存 `outfitRepository.createOutfit` 写库，`onSave`→`resetMainRoute(Outfit)`（Index.ets:207-210）
- 结论：**通过（静态）**；真实回显「待真机验证」
- 证据：`Index.ets:190-210`、`OutfitEditPage.ets:160-163`、`CaptureEditPage.ets:245-256`

### J3 核心录入闭环·逛店（逛店 → 店铺 → 回逛店列表回显）
- 步骤：底部相机 → 快捷面板「逛店」→ StoreVisitEditPage → 填店名/商圈/日期/备注+选图 → 保存 → 回逛店
- 预期流转：归类为店铺；保存回逛店，卡片显示店名/日期/地址；店名与商圈为必填校验
- 实际流转：
  - QuickCaptureSheet「逛店」→`openQuickStoreEditor()`→`AppRouteKind.StoreEditor`/`AppMainTab.Store`（Index.ets:161-169, 349-362）
  - `StoreVisitEditPage` 校验「先补上店名和商圈，再保存这条逛店记录」，保存按钮「保存记录」（StoreVisitEditPage.ets:81, 636, 187-188）
  - 保存 `storeRepository.createStoreVisitWithOptionalStore` 写库，`onSave`→`resetMainRoute(Store)`（Index.ets:171-173）
- 结论：**通过（静态）**；真实回显「待真机验证」
- 证据：`Index.ets:161-173`、`StoreVisitEditPage.ets:81,187-188,243-247,636`

### J4 相机三入口归类正确（快捷面板 衣柜/逛店/穿搭 → 衣橱/店铺/美搭，不串类）
- 步骤：打开底部相机面板，分别点 衣柜 / 逛店 / 穿搭
- 预期流转：衣柜→衣橱(Clothing/Wardrobe)；逛店→店铺(Store/Store)；穿搭→美搭(Outfit/Outfit)；不串类、不歧义
- 实际流转：
  - QuickCaptureSheet 三项：`onOpenWardrobe`→ClothingEditor/Wardrobe、`onOpenStoreVisit`→StoreEditor/Store、`onOpenOutfit`→OutfitEditor/Outfit（QuickCaptureSheet.ets:72-82；Index.ets:541-549）
  - 与 `AppMainTab` 映射一致，无交叉
- 结论：**通过（静态）**
- 证据：`QuickCaptureSheet.ets:72-82`、`Index.ets:541-549`

### J5 搜索 → 结果 → 详情（四类实体类型文案与跳转）
- 步骤：衣柜搜索框 → 全局 SearchResultsPage → 看类型文案 → 点结果进对应详情
- 预期流转：类型文案为 衣物 / 美搭 / 逛店记录 / 店铺；点击衣物→衣物详情，美搭→穿搭详情，逛店/店铺→逛店详情
- 实际流转：
  - `entityTypeLabel`：Clothing=衣物、Outfit=美搭、StoreVisit=逛店记录、Store=店铺（SearchResultsPage.ets:34-54）
  - 衣物结果：`onOpenClothingResult`→WardrobePage 内 `openClothingDetail`（WardrobePage.ets:351-312）
  - 美搭：`onOpenOutfitResult`→`onOpenSearchTarget(Outfit)`→`showMainRoute(Outfit)`（Index.ets:426-429）
  - 逛店/店铺：`onOpenStoreResult`→`showMainRoute(Store, {storeVisitId|storeQuery})`→StoreVisitPage 带查询/ID 打开（Index.ets:430-434；StoreVisitPage.ets:65-76）
- 结论：**通过（静态）**；点击进入详情手感「待真机验证」
- 证据：`SearchResultsPage.ets:34-54,312-326`、`Index.ets:425-444`、`WardrobePage.ets:295-312`

### J6 逛店搜索无结果文案（「没有找到相关逛店记录」而非「还没有逛店记录」）
- 步骤：进入逛店 tab → 搜索框输入无匹配词
- 预期流转：显示「没有找到相关逛店记录」，而非「还没有逛店记录」
- 实际流转：
  - `StoreVisitPage.EmptyState`：`isSearching() ? '没有找到相关逛店记录' : visits.length===0 ? '还没有逛店记录' : ...`（StoreVisitPage.ets:621）
  - 即搜索态精确命中期望文案，空库默认态才是「还没有逛店记录」
- 结论：**通过（静态）**
- 证据：`StoreVisitPage.ets:621,626,641-647`
- 备注：全局 `SearchResultsPage` 无结果通用文案为「没有找到「query」」（SearchResultsPage.ets:557），与逛店页内搜索文案不同但均非「还没有逛店记录」，不冲突。

### J7 状态穿越·离线保存不丢、重启回显
- 步骤：飞行模式/断网 → 新增三类记录 → 杀进程重启 → 回显
- 预期流转：数据落本地 SQLite + 本地图片 URI；重启后仍可见
- 实际流转：
  - 仓库 `create*` 均在本地 `MigrationDatabase` 事务内写库 + `replacePhotoRows` 写本地 URI（ClothingRepository.ets:264-283）
  - `module.json5` 未声明 `INTERNET`/`GET_NETWORK_INFO` 等网络权限（grep 无结果），符合离线优先
  - 重启回显依赖各列表页 `aboutToAppear` 重新 `load*`（WardrobePage.ets:56、StoreVisitPage.ets:51-53）
- 结论：**通过（静态架构）**；重启后真实回显「待真机验证」
- 证据：`ClothingRepository.ets:264-283`、`module.json5（无网络权限）`、`WardrobePage.ets:56`、`StoreVisitPage.ets:51-53`

### J8 状态穿越·空态 → 有数据 → 删除回空态
- 步骤：无数据看空态 → 新增 → 出现列表 → 删除最后一条 → 回空态
- 预期流转：三种状态切换连贯，无残留或卡死
- 实际流转：
  - 空态：`visibleClothingItems().length===0` → 空态引导（WardrobePage.ets:410-445）；逛店 `EmptyState`（StoreVisitPage.ets:614-658）
  - 删除：`deleteClothingItem` 过滤内存列表并 `closeClothingDetail`（WardrobePage.ets:270-279）；`deleteStoreVisit` 同理（StoreVisitPage.ets:191-200）；末条删除后自然回空态
- 结论：**通过（静态逻辑）**；真机连贯手感「待真机验证」
- 证据：`WardrobePage.ets:410-445,270-279`、`StoreVisitPage.ets:191-200,614-658`

### J9 状态穿越·加载/错误态有反馈
- 步骤：进入列表/保存/删除 等异步操作
- 预期流转：加载有 loading 文案；失败有错误文案 + 重试
- 实际流转：
  - 衣柜加载「正在加载衣橱…」、错误带「重试」（WardrobePage.ets:385-406）；逛店 `LoadingState`/`ErrorState`（StoreVisitPage.ets:554-612）
  - 保存中：`CaptureEditPage`「保存中…」、`ClothingEditPage` LoadingProgress（CaptureEditPage.ets:294-305；ClothingEditPage.ets:578-589）；搜索 `LoadingList`/`ErrorPanel`（SearchResultsPage.ets:680-745）
- 结论：**通过（静态）**
- 证据：`WardrobePage.ets:385-406`、`StoreVisitPage.ets:554-612`、`SearchResultsPage.ets:334-340,680-745`

### J10 导航闭环·五标签互相可达 + 当前 tab 选中指示
- 步骤：底部 衣柜/逛店/相机/穿搭/我的 互相切换
- 预期流转：四主标签互相可达；当前 tab 有清晰选中指示；相机仅图标无「拍照」文字
- 实际流转：
  - `BottomNavigationBar`：`NavItem('wardrobe','衣柜')`/`store','逛店'`/`outfit','穿搭'`/`profile','我的'` + 中间 `CameraIcon`（无文字）（BottomNavigationBar.ets:16-39,52-66）
  - 选中指示：`selected===value` 时图标/文字用 `textInverse`（白），未选用 `textTertiary`（灰）（BottomNavigationBar.ets:73,102）
  - 切换：`onSelectWardrobe/Store/Outfit/Profile`→`resetMainRoute` 到对应 `AppMainTab`（Index.ets:518-535）
- 结论：**通过（静态）**；选中指示视觉对比度「待真机验证」
- 证据：`BottomNavigationBar.ets:16-39,52-66,68-129`、`Index.ets:515-537`

### J11 导航闭环·相机面板可开关、遮罩可关
- 步骤：点相机开面板 → 点遮罩/取消关面板
- 预期流转：面板可开；点遮罩空白或「取消」均可关闭并回到来源页
- 实际流转：
  - 开：`onOpenCapture`→`openQuickActions`→`activeRoute.kind=QuickCapture`（Index.ets:522-524,109-118）
  - 关：遮罩 `Blank.onClick`→`closeSheet`→`onCancel`→`returnToCaptureSource`→`showMainRoute`（QuickCaptureSheet.ets:44-48,58-66；Index.ets:95-107,550-552）
  - 「取消」同样 `closeSheet`（QuickCaptureSheet.ets:58-66）
- 结论：**通过（静态）**
- 证据：`Index.ets:109-118,539-554`、`QuickCaptureSheet.ets:42-95`

### J12 导航闭环·无「进得去出不来」死路
- 步骤：进入任一新增/编辑/详情页
- 预期流转：每页均有返回/取消，可回到列表
- 实际流转：
  - `ClothingEditPage`/`CaptureEditPage`/`StoreVisitEditPage`/`OutfitEditPage` 均含 `SecondaryPageHeader` 返回→`onCancel`（ClothingEditPage.ets:607-613；CaptureEditPage.ets:309-315；StoreVisitEditPage.ets:243-247；OutfitEditPage.ets:319-323）
  - `onCancel` 链条均回到对应主列表（Index.ets:155-159,185-210）
  - 衣物详情 `ClothingDetailPage.onBack`→`closeClothingDetail`（WardrobePage.ets:332-344）
- 结论：**通过（静态）**
- 证据：`ClothingEditPage.ets:607-613`、`CaptureEditPage.ets:309-315`、`StoreVisitEditPage.ets:243-247`、`OutfitEditPage.ets:319-323`、`WardrobePage.ets:332-344`

### J13 数据一致性·本地 SQLite + 本地图片 URI，无孤立媒体
- 步骤：新增（带图）→ 删除该记录
- 预期流转：保存以 SQLite 行 + 应用本地存储 URI 为准；删除后对应本地图片文件被清理，无孤儿文件
- 实际流转：
  - 照片经 `photoStorage.copyToAppStorage` 复制到应用本地并以 `localUri` 入库（Index.ets:128-140；ClothingEditPage.ets:190-202）
  - 删除走 `DeleteCleanupService.deleteObjectPhotos`，按 `PHOTO_REFERENCE_TABLES` 跨表查重后 `photoStorage.deleteLocalPhoto` 清理孤儿文件（DeleteCleanupService.ets:12-19,42-58,118-169,171-211）
- 结论：**通过（静态）**；删除后真机文件系统清理「待真机验证」
- 证据：`Index.ets:128-140`、`DeleteCleanupService.ets:42-211`、`ClothingRepository.ets:324-333`

### J14 数据一致性·编辑后列表/详情回显一致
- 步骤：新增/编辑衣物 → 返回列表/详情
- 预期流转：编辑后列表卡片与详情页信息一致
- 实际流转：
  - 页内编辑：`upsertClothingItem` 直接替换内存列表项并 `refreshClothingDataSource`，详情 `detailClothingId=item.id` 同步（WardrobePage.ets:249-268,321-327）
  - 快捷面板编辑：保存后 `resetMainRoute` 重新 `loadClothingItems` 全量回显（WardrobePage.ets:56-58）
  - 仓库 `updateClothing` 同步更新搜索文档（ClothingRepository.ets:286-322）
- 结论：**通过（静态）**；真实回显一致「待真机验证」
- 证据：`WardrobePage.ets:249-268,321-327`、`ClothingRepository.ets:286-322`

### J15 旧概念不串场·主流程无 首页/日历/逛街/心愿单 tab；衣柜无二级 tab
- 步骤：检查底部导航与衣柜页分类
- 预期流转：主导航仅 衣柜/逛店/相机/穿搭/我的；衣柜分类仅 全部/上衣/裤装/裙装，无 衣橱/美搭/日历 二级 tab
- 实际流转：
  - 底部导航确为 5 项，无 首页/日历/逛街/心愿单（BottomNavigationBar.ets:16-39）
  - 衣柜 `WARDROBE_CATEGORY_FILTERS` = 全部/上衣/裤装/裙装（WardrobePage.ets:21-26），`WardrobeSearchTabs` 渲染同上
- 结论：**通过（静态）**
- 证据：`BottomNavigationBar.ets:16-39`、`WardrobePage.ets:21-26,502-534`

### J16 旧概念不串场·可达页面无点赞/收藏/评论/关注（偏差）
- 步骤：检查各可达页是否出现社交动作
- 预期流转：无点赞/收藏/评论/关注
- 实际流转：
  - 逛店状态筛选用 `symbol.heart` 表示「想去」（`wantToVisit`），属 逛店功能状态（去过/想去/回购），非内容社交收藏（StoreVisitPage.ets:399-402,216-225）
  - 但「心形」图标语义易与「收藏」混淆，建议评估改用更中性图标
- 结论：**偏差（待真机/设计确认）**——功能上为状态筛选非社交动作，但图标口径有歧义风险
- 证据：`StoreVisitPage.ets:399-402,216-225,15-19`

### J17 旧概念串场·心愿单/穿着仍可通过全局搜索与「我的」进入（偏差）
- 步骤：全局搜索范围 / 「我的」页入口
- 预期流转：主流程不可见心愿单；旧概念不串场
- 实际流转：
  - 全局 `SearchResultsPage` 的 `SEARCH_SCOPES` 含 `profile`=「我的」，过滤出 `WearLog|Wishlist`，`entityTypeLabel` 暴露「穿着/心愿」（SearchResultsPage.ets:24-30,299,47-52）
  - 结果可 `onOpenWishlistResult`→`openWishlistPage` 进入 `WishlistPage`（Index.ets:435-437,363-379）；`ProfilePage.onOpenWishlist`→`WishlistPage`（ProfilePage.ets:84,866）
  - 即心愿单/穿着 仍可达，与「旧概念不串场」原则有出入
- 结论：**偏差**——心愿单/穿着 经全局搜索与「我的」仍可达，建议确认是否需从主流程收敛
- 证据：`SearchResultsPage.ets:24-30,299,319-325`、`Index.ets:435-437,363-379`、`ProfilePage.ets:84,866`

### J18 拍照录入分类文案口径不一致（偏差）
- 步骤：衣柜页相机 → 拍照/相册 → 拍照录入页
- 预期流转（基线）：归类为 衣橱/店铺/美搭
- 实际流转：
  - `CaptureEditPage.ModeTabs` 展示「单品 / 试穿 / 吊牌」，内部 `selectMode` 映射为 衣橱/美搭/店铺（CaptureEditPage.ets:402-431,194-203）
  - 保存按钮文案随类型变为「保存试穿」(美搭)、「保存吊牌」(店铺)（CaptureEditPage.ets:294-305）
  - 路由正确（单品→衣橱、试穿→美搭、吊牌→店铺），但用户可见分类名与基线期望的 衣橱/店铺/美搭 不完全一致，存在口径不统一
- 结论：**偏差**——流程路由正确，但拍照录入页分类/按钮文案为 单品·试穿·吊牌，与基线 衣橱·店铺·美搭 口径不一致，建议统一
- 证据：`CaptureEditPage.ets:194-203,294-305,398-437`

---

## 代码静态可验证 vs 需真机操作验证

**可静态验证（路由/状态变量/保存回写逻辑）：** J1–J15 的路由与持久化逻辑、J16–J18 的偏离事实本身。
- 关键链路：QuickCaptureSheet/相机 → 对应 Editor（Clothing/Outfit/Store）→ Repository.create* 写 SQLite+本地 URI → onSave 回调 → resetMainRoute/showMainRoute 回到主列表 → 列表页 aboutToAppear 重新 load* 回显。
- 删除闭环：Editor/列表 → Repository.delete* → DeleteCleanupService 跨表查重 + 本地文件清理。

**需真机/模拟器操作验证（不在本次静态范围内）：**
1. 离线保存后杀进程重启的真实回显（J7）
2. 删除记录后应用本地存储中孤儿图片文件是否真的被删除（J13）
3. 各列表/详情真实回显内容与图片加载（J1–J3、J14）
4. 底部 tab 选中指示的视觉对比度与按压反馈（J10）
5. 搜索→详情跳转的真实手感与结果正确性（J5）
6. 空态→有数据→删除回空态 的连贯手感（J8）
7. J16/J17/J18 的文案/图标歧义在真机上的可接受的判定

## 结论摘要
- 端到端跨模块流程**路由贯通、状态回写、闭环出口在代码层面均正确**，覆盖率 **13/16** 旅程静态走通。
- 3 项偏差均**不影响流程可达性**，集中在：① 逛店「想去」用 heart 图标（J16）；② 心愿单/穿着 仍经全局搜索与「我的」可达（J17）；③ 拍照录入页分类文案为「单品/试穿/吊牌」而非基线期望的「衣橱/店铺/美搭」（J18）。
- 建议：J18 与 J17 优先与产品对齐文案与旧概念收敛范围；J16 评估图标替换以避「收藏」歧义。其余待真机回归确认。
