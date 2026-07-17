# 衣不缺（Harmony Wardrobe）手工 QA 功能走查报告

- **走查依据**：`docs/qa/manual-test-script.md`（权威基线）
- **代码基线**：`entry/src/main/ets`（分层架构：pages / components / domain / data / media / utils）
- **走查方式**：静态代码对照（无真机、无构建运行），对照每一验收点定位页面/组件/数据代码并判断实现状态
- **走查日期**：2026-07-14
- **应用 commit**：`7adda09`（fix: remove local reload and sync entries）

---

## 一、覆盖率概览

| 维度 | 数量 |
| --- | --- |
| 拆分验收点（按脚本条目） | 47 |
| 代码静态可验证 | 38 |
| 其中：通过 | 31 |
| 其中：失败 / 偏差（含轻微措辞） | 7 |
| 需真机 / 离线 / 截图验证 | 9 |

> 结论口径：`通过`=代码实现与脚本一致；`失败`=与脚本冲突或缺失关键功能；`偏差`=实现正确但文案/交互与基线略有出入（建议对齐）；`待验证`=依赖真机、离线或截图，代码层无法判定。

---

## 二、记录信息（QA 脚本「记录」章节）

| 项 | 值 |
| --- | --- |
| 设备型号 | 待真机验证（未提供实机） |
| 系统版本 | 待真机验证（HarmonyOS / OpenHarmony 具体版本未获知） |
| 应用 commit | `7adda09` |
| 是否使用种子数据 | 否（应用不内置种子数据；依赖本地调试包 + 本地相册图片） |
| 失败截图路径 | 无（本次为静态代码走查，无真机截图） |
| 离线权限核查 | `entry/src/main/module.json5` 未声明任何 `reqPermissions` / `INTERNET`；源码无网络调用路径 → 离线优先约束满足 |

---

## 三、逐模块验收明细

### App 壳层

| 验收点 | 预期 | 实际 | 结论 | 证据 |
| --- | --- | --- | --- | --- |
| 首页不自绘状态栏；状态栏下方全宽搜索框；无额外标题/右上角相机 | 系统状态栏 + 全宽搜索框 | 首页（衣橱）仅渲染 `WardrobeSearchHeader` 全宽搜索框，无自绘状态栏、无页面标题 | 通过 | `WardrobePage.ets:723-764`；`Index.ets:174` |
| 底部深色浮动胶囊：衣柜/逛店/相机/套装/我的；相机只显图标 | 5 项，中间相机无文字 | `BottomNavigationBar` 顺序正确，相机仅 `SymbolGlyph(camera_fill)`，无文字 | 通过 | `BottomNavigationBar.ets:16-39` |
| 点击底部「我的」进入个人信息页 | 进入我的 | 底部 `onOpenProfile` → `ProfilePage` | 通过 | `Index.ets:410-416` |
| 点击相机打开快捷面板，含「拍照」「从相册选择」 | 面板含两项 | 面板动作标题为「拍一张」「从相册选择」（非基线「拍照」） | 偏差 | `QuickCaptureSheet.ets:71-77`（见 F-偏差1） |
| 快捷面板动作是大行入口，含标题+说明，触达≥44 | 大行、可点 | `ActionCard` 高 82，图标 44×44 | 通过 | `QuickCaptureSheet.ets:107-155` |
| 面板可点遮罩或取消关闭 | 两种关闭 | 遮罩 `Blank.onClick` + 「取消」文本均关闭 | 通过 | `QuickCaptureSheet.ets:43-66` |
| 底部 tab 有清晰选中指示，点击有按压反馈 | 选中态 + 反馈 | 选中项白色、未选中灰（`#8D8D92`）；按压 `scale` 动画 | 通过（指示偏弱） | `BottomNavigationBar.ets:89-129` |

### 衣橱

| 验收点 | 预期 | 实际 | 结论 | 证据 |
| --- | --- | --- | --- | --- |
| 顶部全宽搜索框 + 横向分类胶囊，无标题/数量摘要/区块标题 | 搜索框+分类胶囊 | `WardrobeSearchHeader` + `WardrobeSearchTabs`；`wardrobeSummaryText()` 已定义但未渲染（无数量摘要） | 通过 | `WardrobePage.ets:635-637, 490-504` |
| 搜索框浅灰边框+系统搜索图标，键盘搜索键进结果页 | 浅灰边框+放大镜+回车搜索 | 边框 `borderMedium`，`magnifyingglass` 图标，`enterKeyType(Search)`+`onSubmit`→结果页 | 通过 | `WardrobePage.ets:723-764` |
| 分类选中态黑底白图标白字，未选中白底浅灰边框 | 黑/白选中 | `selectedCategoryLabel` 选中 `actionBlack` 底白字；未选中白底 `borderMedium` | 通过 | `WardrobePage.ets:926-959` |
| 衣裤下分类：全部/上衣/裤装/裙装，首屏完整，无旧筛选 | 4 项 | `WARDROBE_CATEGORY_FILTERS=[全部,上衣,裤装,裙装]` | 通过 | `WardrobePage.ets:28-33` |
| 双列原生瀑布流；卡片左上角分类图标、右上角收藏图标，标题≤2行 | 双列+两图标 | `WaterFlow` 双列 ✓；`CardCategoryIcon` 仅左上角；**无右上角收藏图标**（数据模型无 favorite 字段） | 失败（F1） | `WardrobePage.ets:986-1095`；`ClothingModels.ets:10-19` |
| 点击真实衣物卡片进详情，不进拍照/编辑 | 进详情 | `onClick→openClothingDetail→ClothingDetailPage` | 通过 | `WardrobePage.ets:1067-1070` |
| 相机选图归类为衣橱，自动生成名称；名称/分类/备注/购买信息可选填 | 归类衣橱+自动名 | `captureType` 默认 `衣橱`，`generatedClothingName()` 自动名；各字段可选 | 通过 | `CaptureEditPage.ets:74-78, 109-111` |
| 添加衣服页图片优先表单；无图时保存按钮提示「先添加照片」；仅中文标签，无 name/衣物名称 等调试词 | 先添加照片提示 | **无图时保存按钮显示「存入衣柜」且置灰，未提示「先添加照片」**；字段用中文/生成名，无调试词 | 失败（F2） | `CaptureEditPage.ets:259-270, 317-319`（对比 `OutfitEditPage.ets:386` 已实现） |
| 添加页分类选中黑色胶囊，不用蓝色；保存按钮黑色胶囊「保存衣服」 | 黑胶囊+「保存衣服」 | 分类选中近黑 `#1D1D1F` 胶囊 ✓；保存按钮文案为「存入衣柜」非「保存衣服」 | 偏差（F3） | `CaptureEditPage.ets:359-348, 259-270` |
| 卡片显示衣物名称和分类，不只序号 | 名称+分类 | `displayItemTitle`+`displayItemMeta` 显示名称/分类/备注 | 通过 | `WardrobePage.ets:242-256, 1047-1063` |
| 编辑刚新增衣物，改名称/备注保存后列表回显 | 回显更新 | `upsertClothingItem` 更新列表；编辑页 `updateClothing` 落库 | 通过（代码逻辑） | `WardrobePage.ets:395-414`；`ClothingEditPage.ets:267-285` |
| 空态引导用户通过底部相机添加 | 相机引导文案 | 空态「先放入第一件衣服…点底部相机，选择照片后归类为衣橱」 | 通过 | `WardrobePage.ets:641-672` |

### 美搭（套装）

| 验收点 | 预期 | 实际 | 结论 | 证据 |
| --- | --- | --- | --- | --- |
| 切到美搭 tab | 套装 tab | 底部「套装」→`OutfitsPage` | 通过 | `Index.ets:322-334` |
| 相机选图归类为美搭，图片必填；名称/关联衣物/备注可空，保存生成默认名 | 归类美搭+图片必填+默认名 | `试穿` 模式→`美搭`；`canSave` 需照片；`generatedOutfitTitle` 默认名 | 通过 | `CaptureEditPage.ets:159-168, 210-221`；`OutfitEditPage.ets:58-69` |
| 创建页显示「美搭信息（选填）」「美搭名称，可不填」「备注」等中文；黑色胶囊保存 | 中文字段+黑胶囊 | `OutfitEditPage` 含上述字段；保存黑胶囊「保存美搭」 | 通过 | `OutfitEditPage.ets:307-342, 379-400` |
| 保存后回套装，卡片显示照片或柔和占位 | 回套装+占位 | `onSave→upsertOutfit`；卡片无图显示占位 | 通过 | `OutfitsPage.ets:239-256, 570-597` |
| 底部显示「套装」，编辑保存流程内继续用美搭/搭配 | 术语一致 | 底部「套装」；编辑页标题「创建/编辑美搭」、保存「保存美搭」 | 通过 | `OutfitEditPage.ets:295-301` |

### 逛店

| 验收点 | 预期 | 实际 | 结论 | 证据 |
| --- | --- | --- | --- | --- |
| 进入逛店 tab，默认列表或空态 | 列表/空态 | `StoreVisitPage` 默认列表或空态 | 通过 | `StoreVisitPage.ets:253-296` |
| 空态像可行动入口，指向相机；搜索无结果显示「没有找到相关逛店记录」，不误提示「还没有逛店记录」 | 正确空态文案 | `isSearching()` 显示「没有找到相关逛店记录」；无结果显示「还没有逛店记录」 | 通过 | `StoreVisitPage.ets:583-627` |
| 页面显示逛店数量；**搜索时显示匹配条数** | 总数+匹配数 | `RouteCard` 仅显示总条数 `visits.length`；**搜索无「找到 N 条」文案** | 失败（F4） | `StoreVisitPage.ets:389-428` |
| 相机选图归类为店铺，新增逛店记录 | 归类店铺 | `吊牌` 模式→`店铺`；`saveStore` 落库 | 通过 | `CaptureEditPage.ets:163-168, 223-236` |
| 记录页显示店铺信息/地址或商圈/试穿备注 等中文；黑色胶囊保存 | 中文字段+黑胶囊 | `BasicInfoCard`（店名/品牌、商圈/地址）+备注；保存「保存记录」黑胶囊 | 通过 | `StoreVisitEditPage.ets:413-492, 621-650` |
| 填店铺名/地址/日期/备注+选图，保存回逛店 | 回逛店 | `onSave→upsertVisit→closeEditor` | 通过 | `StoreVisitPage.ets:254-270` |
| 卡片展示店铺名/日期/地址或商圈/图片或店占位，备注≤2行 | 卡片字段 | `StoreVisitResultCard` 含上述；`visitMeta` `maxLines(2)` | 通过 | `StoreVisitPage.ets:450-521` |
| 搜索店铺名/地址或商圈/备注，正确过滤 | 正确过滤 | `filterStoreVisits` 覆盖 storeNameSnapshot/visitDate/districtOrAddress/note/focusTags | 通过 | `StoreVisitPage.ets:105-126` |

### 我的

| 验收点 | 预期 | 实际 | 结论 | 证据 |
| --- | --- | --- | --- | --- |
| 点击顶部右侧头像/我的 | 入口可达 | 底部「我的」进入（无顶部右侧头像，`AppTopBar` 组件未被引用） | 通过（底部入口） | `Index.ets:335-362`；`AppTopBar.ets`（孤儿） |
| 页面显示头像占位、身高、体重、腰围 和 设置 | 上述元素 | 头像占位✓；身高/体重/腰围在「常用尺码」浮层内✓；**无独立「设置」入口**（隐私等置于「本地与隐私」） | 偏差（F6） | `ProfilePage.ets:368-442, 958-1055, 873-893` |
| 合法数值保存，退出再进入可回显 | 回显 | `saveProfile`→`profileRepository`；`loadProfile` 重读 | 通过（代码逻辑） | `ProfilePage.ets:199-233, 127-144` |
| 负数/非数字时字段附近错误提示，保存按钮禁用 | 校验+禁用 | `measurementError` 返回「不能小于 0」/「请输入数字」；按钮 `enabled(!hasInvalidMeasurements)` | 通过 | `ProfilePage.ets:241-255, 1039-1041` |
| 保存成功显示「已保存个人信息」 | 成功提示 | `savedMessage='已保存个人信息'` | 通过 | `ProfilePage.ets:226` |
| 保存按钮「保存中...」状态，重复点击无异常 | 防重入 | `isSaving` 守卫 + `LoadingProgress` | 通过 | `ProfilePage.ets:1024-1044` |

### 搜索与旧概念

| 验收点 | 预期 | 实际 | 结论 | 证据 |
| --- | --- | --- | --- | --- |
| 搜索结果类型为用户可理解文案（衣物/美搭/逛店记录/店铺 等） | 上述标签 | `entityTypeLabel`：衣物✓、套装（非「美搭」）、逛店（非「逛店记录」）、店铺✓、穿着、心愿 | 偏差（F7） | `SearchResultsPage.ets:33-53` |
| 主流程不可见 首页推荐流/逛街主入口/心愿单主入口 | 无主入口 | 底部导航仅 5 项；心愿单经「我的→心愿清单」可达（非主入口）；穿着记录经搜索进入套装页编辑 | 通过 | `BottomNavigationBar.ets`；`Index.ets` |
| 可达页面不可见点赞/收藏/评论/关注等社交动作 | 无社交动作 | 全站无此类动作（收藏功能本身亦未实现） | 通过 | 全局检索无社交组件 |

### 视觉验收

| 验收点 | 预期 | 实际 | 结论 | 证据 |
| --- | --- | --- | --- | --- |
| 主操作按钮黑色胶囊 | 黑胶囊 | 保存/主操作为 `actionBlack`(#1D1D1F) 或 `#000` 胶囊 | 通过 | `Tokens.ets:164`；各 `SaveAction` |
| 卡片大圆角，图片圆角，无直角大图 | 大圆角 | 卡片 `xxl(18)`/`xxxl(20)`，图片 `borderRadius(18)` | 通过 | `Tokens.ets:209-219`；`WardrobePage.ets:1025-1031` |
| 背景轻、留白足，不呈后台管理风/社交流 | 轻量留白 | 白底、留白充足、无后台管理风 | 通过 | `Tokens.ets:150-173` |
| 首页精致感来自图片/留白/柔和卡片/轻动效，无大面积粉色/花哨 | 中性克制 | 黑+白+浅灰，无粉色/刻板化图形 | 通过 | 全局 |
| 主要触达区域高度≥44 | ≥44 | 导航项 52、分类 44、卡片 44、各按钮 44+ | 通过 | 各组件 |
| 加载/错误/重试/搜索等用户可见文案中文，不出现 loading/error/retry/search 调试词 | 纯中文 | **`ShoppingPage.ets:200` 显示 `loading / 正在加载心愿...`**（可达，经我的→心愿清单） | 失败（F5，ShoppingPage 实显） | `ShoppingPage.ets:200` |

---

## 四、失败与偏差清单（含修复建议）

### 失败项（需修复）

**F1 — 衣物卡片缺少右上角收藏图标**
- 位置：`WardrobePage.ets:986-1095`（`WardrobeSearchResultCard`）；`domain/clothing/ClothingModels.ets:10-19`
- 说明：QA 要求卡片图片右上角显示收藏图标，但数据模型无 `favorite/isFavorite` 字段，卡片仅渲染左上角分类图标。收藏功能整体未实现。
- 建议：若产品需要收藏，先在 `ClothingItem` 增加 `favorite?` 字段与仓储读写，再在卡片右上角渲染收藏图标（含选中/未选态）。若本期不打算做收藏，应从 QA 脚本移除该验收点或标注「本期不做」。

**F2 — 衣橱添加流程未提示「先添加照片」**
- 位置：`CaptureEditPage.ets:259-270`（saveButtonLabel）、`:317-319`（enabled/canSave）
- 说明：无照片时保存按钮显示「存入衣柜」并置灰，未按要求提示「先添加照片」。注意同一基线下的美搭添加页（`OutfitEditPage.ets:386`）已正确实现「先添加照片」——两处实现不一致。
- 建议：`saveButtonLabel()` 在 `!canSave()` 时返回 `photoUris.length === 0 ? '先添加照片' : <其他>`；保持与 `OutfitEditPage` 一致措辞（可考虑统一为「先添加照片」）。

**F4 — 逛店搜索未显示匹配条数**
- 位置：`StoreVisitPage.ets:389-428`（`RouteCard` 仅显示总条数）
- 说明：QA 要求搜索时显示匹配条数（如「找到 N 条逛店记录」）。当前 `RouteCard` 只显示总记录数 `visits.length`，列表按 `filterStoreVisits()` 过滤但无匹配计数文案。衣橱页已有 `wardrobeSummaryText()` 范例，逛店缺失。
- 建议：搜索态（`searchQuery` 非空）时，将 `RouteCard` 文案或新增一行改为「找到 N 条逛店记录」（`filterStoreVisits().length`）。

**F5 — 心愿单页显示调试式英文「loading /」**
- 位置：`ShoppingPage.ets:200` `Text('loading / 正在加载心愿...')`
- 说明：违反视觉验收「不出现 loading/error/retry/search 调试式文案」。该页经「我的→心愿清单」可达，属真实用户可见缺陷。
- 建议：改为纯中文 `正在加载心愿...`，移除 `loading /` 前缀。

### 偏差项（建议对齐基线，非硬阻塞）

**F-偏差1** 快捷面板相机动作标题为「拍一张」而非基线「拍照」——`QuickCaptureSheet.ets:71`。建议改为「拍照」以对齐脚本。

**F3** 衣橱添加保存按钮文案「存入衣柜」而非「保存衣服」——`CaptureEditPage.ets:269`。黑色胶囊已满足，仅文案差异；建议统一为「保存衣服」或直接沿用「存入衣柜」并在脚本中固化措辞。

**F6** 「我的」页无独立「设置」入口——相关项（隐私模式等）在「本地与隐私」区。若脚本要求显式「设置」，建议补充入口或在脚本中确认「本地与隐私」即等价设置区。

**F7** 搜索结果类型标签用「套装/逛店/穿着/心愿」，基线写「美搭/逛店记录」——`SearchResultsPage.ets:33-53`。底部导航与场景过滤统一用「套装」，内部一致；建议与 QA 脚本措辞对齐或在脚本中确认术语。

---

## 五、代码卫生旁注（非功能阻塞，建议清理）

以下组件/页面已被定义但**无任何 import 引用**（未被实例化）：

| 文件 | 状态 | 备注 |
| --- | --- | --- |
| `components/AppTopBar.ets` | 孤儿 | 含「衣不缺」标题+我的；未用于任何页面 |
| `components/CategoryTabs.ets` | 孤儿 | `CaptureEditPage` 内用同名 `@Builder` 而非该组件 |
| `components/ClothingCard.ets` | 孤儿 | 衣橱页用 `WardrobeSearchResultCard` |
| `components/OutfitCard.ets` | 孤儿 | 套装页用 `OutfitWallCard` |
| `components/StoreVisitCard.ets` | 孤儿 | 逛店页用 `StoreVisitResultCard` |
| `WardrobePage.ets:490-504` `wardrobeSummaryText()` | 死代码 | 定义但未在 `build()` 中调用（与 F4 相关，建议启用或删除） |

---

## 六、未覆盖项（待真机 / 离线 / 截图验证）

以下验收点依赖真机运行、离线环境或截图，静态代码无法判定，列为待验证：

1. **离线持久化前置条件**（脚本「前置条件」）：飞行模式/断网下启动、保存、重启后回显。代码层证据：无网络权限、SQLite+媒体本地复制，强烈支持离线，但**未真机验证**。
2. **真机视觉与动效**：瀑布流实际排版、按压反馈手感、圆角/留白观感、加载骨架屏。
3. **相机/相册真实采集**：`photoPickerAdapter.captureFromCamera` / `pickFromGallery` 真机授权与复制行为。
4. **「我的」数值保存后真机回显**：代码逻辑齐全，但需实机退出重进确认。
5. **编辑新增衣物后真机列表回显**：代码逻辑齐全，需实机确认渲染顺序与刷新。
6. **失败截图路径**：本次无真机，所有失败项均缺截图；建议真机复现时补 `docs/qa/screenshots/` 下对应截图。
7. **`module.json5` 仅核查 entry 模块**；若 AppScope 级别另行声明权限，需二次确认（当前未检出网络权限）。

---

## 七、总结

- **代码静态可验证 38 项中：通过 31、失败 4（F1/F2/F4/F5）、偏差 3（F-偏差1/F3/F6/F7）**。
- 最需优先修复的是 **F5（用户可见调试英文）** 与 **F2（衣橱添加未提示先添加照片，且与美搭实现不一致）**——二者均为用户直接可见且违背基线。
- **F1（收藏图标）** 与 **F4（逛店匹配条数）** 为功能缺失类，建议排期补齐或在脚本中标注本期范围。
- 离线优先约束在代码层成立（无网络权限、数据走本地 SQLite+媒体复制）。
- 存在较多孤儿组件/死代码，建议清理以降低维护成本，但非功能阻塞。
