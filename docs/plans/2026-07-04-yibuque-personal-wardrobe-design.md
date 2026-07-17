# 衣不缺个人衣橱改版设计

Date: 2026-07-04

## 背景

`Harmony Wardrobe` 需要从“首页内容流 + 衣橱 + 日历 + 逛街心愿单”收敛为个人衣橱工具。新产品名为 `衣不缺`。用户只管理自己的衣橱，可以自由搭配；逛街不再是心愿单，而是登记店铺和逛店记录。

本设计文档只定义需求和方案，不包含代码实现。

## 已确认需求

- 主导航只有三个位置：`衣橱 / 快捷 + / 逛店`。
- 顶部工具栏左侧显示 `logo + 衣不缺`。
- 顶部工具栏右侧显示 `我的` 头像入口。
- `我的` 入口包含个人信息和设置。
- 个人信息字段为：`身高`、`体重`、`腰围`。
- 快捷入口包含：`拍衣服`、`拍搭配`、`拍店铺`。
- `拍店铺` 创建逛店记录，而不是只创建店铺。
- `衣橱` 内部有二级 tab：`衣裤`、`美搭`。
- `逛店` 替换当前心愿单，不继续使用心愿单作为产品概念。

## 目标

1. 让用户第一眼知道这是自己的衣橱管理工具，不是推荐社区。
2. 让衣物、搭配、店铺、逛店记录成为清晰的业务对象。
3. 让拍照采集成为最快入口：拍衣服、拍搭配、拍店铺。
4. 保留本地优先、离线可用、不新增网络能力的架构约束。

## 非目标

- 不做推荐流。
- 不做点赞、收藏、评论等社交数据。
- 不做线上电商购买链路。
- 不保留心愿单作为主业务入口。
- 不新增网络权限。
- 不把照片二进制写入 SQLite。
- 不一次性强制删除旧 wishlist 表，避免破坏已有本地数据和迁移稳定性。

## 方案比较

### 方案 A：仅改文案和导航

把现有首页、衣橱、心愿单页面改名。实现最快，但 `逛店` 会继续复用心愿单对象，后续店铺和逛店记录关系会混乱。

结论：不推荐。

### 方案 B：新增店铺和逛店记录，旧心愿单停用

新增 `Store` 和 `StoreVisit` 领域对象、数据库表、仓储和页面。`ShoppingPage` 改造为 `StoreVisitPage` 或新的逛店页。旧心愿单入口移除，旧代码可暂时保留，不再进入主导航。

结论：推荐。对象边界清楚，迁移风险可控。

### 方案 C：彻底删除心愿单相关代码

删除 wishlist 模型、仓储、搜索类型、页面和校验。代码最干净，但会牵动搜索索引、数据库迁移、运行时初始化和旧数据兼容，风险最高。

结论：后续清理阶段再做。

## 推荐方案

采用方案 B：新增 `Store` 和 `StoreVisit`，停用心愿单入口。

现有 `OutfitTemplate` 可先继续作为代码层搭配对象使用，但 UI 文案统一改为 `美搭` 或 `搭配`。这能降低一次性重命名带来的风险。

## 视觉系统

本项目视觉规则以 `docs/background/yibuque-design.md` 为 UI 合同。本设计文档采用其中的核心方向：`衣不缺` 是轻量、柔和、卡片化的个人衣橱生活工具，不是后台工具、内容社区或电商货架。

### 视觉关键词

- 个人衣橱
- 轻生活工具
- 大圆角卡片
- 低饱和背景
- 黑色强标题
- 黑色主操作
- 极轻阴影
- 图片情绪化
- 宽松移动端布局

### 核心色彩

```yaml
colors:
  bgDefault: '#FFFFFF'
  bgGray: '#EFEFEF'
  bgBlueGray: '#F6FAFD'
  bgHeaderBlue: '#E1F1FF'
  cardWhite: '#FFFFFF'
  cardBlue: '#E1F3FF'
  cardMint: '#DCFDF6'
  cardSoftGray: '#F6F6F6'
  textPrimary: '#0A0A0A'
  textSecondary: '#5F6870'
  textTertiary: '#9CA3AA'
  textDisabled: '#C8CDD2'
  textInverse: '#FFFFFF'
  actionBlack: '#000000'
  brandCyan: '#24BFE8'
  success: '#43D991'
  successBg: '#EFFFF7'
  borderLight: '#E9ECEF'
  borderMedium: '#D8DDE2'
  borderStrong: '#111111'
  overlayDark: '#73000000'
```

### 字体层级

```yaml
fontSize:
  display: 36
  pageTitle: 24
  section: 22
  cardTitle: 21
  body: 16
  meta: 14
  caption: 12
lineHeight:
  display: 44
  pageTitle: 32
  section: 30
  cardTitle: 29
  body: 24
  meta: 20
  caption: 18
```

使用规则：

- App 名称 `衣不缺`：18 到 20，黑色，粗体。
- 页面标题：24，黑色，粗体。
- 卡片标题：18 到 21，黑色，粗体。
- 元信息：14，中灰或浅灰。
- 不使用细弱标题，不在用户界面出现调试式中英混排标签。

### 间距、圆角和阴影

- 页面左右边距：20 到 24。
- 卡片内边距：20 到 28。
- 分区间距：28 到 40。
- 卡片间距：20 到 28。
- 主卡片圆角：24 到 32。
- Sheet 顶部圆角：32 到 36。
- 按钮、Tab、Chip 使用胶囊圆角。
- 阴影必须很轻，优先使用 `0 8px 24px rgba(0, 0, 0, 0.04)` 对应的 ArkUI 轻阴影。

### 组件状态规则

- 主按钮：黑底白字，胶囊，高度 56，粗体。
- 次级按钮：白底或透明底，黑色 2px 描边，胶囊。
- Tab/Chip 选中态：白底、黑色 2px 描边、黑色粗体文字。
- Tab/Chip 未选中态：白底、浅灰边框、灰色文字。
- 图片必须有圆角；无图占位使用浅蓝、薄荷绿或浅灰背景。
- 主导航和快捷入口触达区域不小于 44。

### 明确避免

- 不继续使用伪社交行为：点赞、收藏、评论、关注。
- 不做后台工具式密集列表。
- 不使用重阴影、重边框或高饱和大色块。
- 不把所有主操作做成蓝色。蓝色和薄荷绿只作为柔和背景或状态色，主操作使用黑色。

## 信息架构

```text
App
├─ 顶部工具栏
│  ├─ logo + 衣不缺
│  └─ 我的头像
│     ├─ 个人信息
│     │  ├─ 身高
│     │  ├─ 体重
│     │  └─ 腰围
│     └─ 设置
├─ 主导航
│  ├─ 衣橱
│  │  ├─ 衣裤
│  │  └─ 美搭
│  ├─ 快捷 +
│  │  ├─ 拍衣服
│  │  ├─ 拍搭配
│  │  └─ 拍店铺
│  └─ 逛店
│     ├─ 逛店记录
│     └─ 店铺信息
```

## 页面设计

### 全局顶部工具栏

顶部工具栏在主页面常驻：

- 左侧：logo 图标和 `衣不缺`。
- 左侧 App 名称使用黑色粗体，字号约 18 到 20。
- 右侧：头像按钮，触达区域 44 到 48。
- 点击头像进入 `我的`。
- 进入编辑页、拍照表单页时可保留返回按钮，避免顶部工具栏挤占表单空间。

### 主导航

底部主导航只保留：

- `衣橱`
- 中间凸起 `+`
- `逛店`

视觉规则：

- 选中项使用黑色。
- 未选中项使用浅灰。
- 中间 `+` 使用黑色圆角方形或胶囊按钮，白色加号。
- 底部预留安全区。

`+` 点击后打开快捷操作面板：

- `拍衣服`：进入衣物创建流程。
- `拍搭配`：进入美搭创建流程。
- `拍店铺`：进入逛店记录创建流程。

快捷面板视觉规则：

- 白色 Sheet，顶部圆角 32 到 36。
- 三个动作使用大触达行或胶囊按钮。
- 入口文案必须直接说明动作，不使用抽象“新增”。

### 衣橱页

衣橱页包含二级 tab：

```text
衣橱
[衣裤] [美搭]
```

`衣裤`：

- 展示单件衣物。
- 分类筛选：`上衣`、`裤子`、`短裤`、`长裙`、`半裙`。
- 支持搜索衣物名称和备注。
- 空态提示：点击底部 `+` 的 `拍衣服` 添加第一件衣服。
- 衣物卡片使用图片优先布局，白底、大圆角、极轻阴影。
- 分类使用小胶囊标签，不抢占图片和名称层级。

`美搭`：

- 展示用户保存的搭配。
- 支持从衣裤选择多件衣物组成搭配。
- 支持拍照型搭配，即没有完整衣物关联时也可以保存照片和备注。
- 空态提示：点击底部 `+` 的 `拍搭配` 添加第一套美搭。
- UI 文案只使用 `美搭` 或 `搭配`，不再使用 `穿搭` 作为主要用户文案。
- 有照片时使用照片作为封面；无照片时使用浅蓝或薄荷绿占位。

### 逛店页

逛店页以逛店记录为主列表：

- 默认按 `visitDate / updatedAt` 倒序展示。
- 每条记录展示店铺名、日期、首图和备注摘要。
- 支持新建/选择店铺。
- 支持从记录进入编辑店铺信息。

店铺是逛店记录的归属对象，不要求用户先维护店铺主数据。`拍店铺` 应优先创建一条逛店记录，然后在表单里选择或新建店铺。

逛店记录卡片视觉规则：

- 店铺名黑色粗体。
- 日期、地址/商圈使用中灰。
- 首图可选，但如果存在必须圆角展示。
- 备注最多展示 2 行。
- 无图占位使用柔和底色和 `店` 字，不使用硬边框图标。

### 我的页

我的页包含：

- 头像/昵称区域，可先本地静态展示。
- 个人信息：身高、体重、腰围。
- 设置入口。

第一版可以只保存个人信息，不实现复杂账号系统。

我的页视觉规则：

- 背景使用极浅蓝灰 `#F6FAFD`。
- 头像使用大圆形，占位直径约 112。
- 个人信息字段放在白色大圆角卡片中。
- 编辑资料或保存主操作优先使用黑色胶囊按钮。
- 设置入口使用白色大圆角菜单卡，菜单项高度约 74。

## 核心业务对象

```yaml
coreBusinessObjects:
  - name: ClothingItem
    uiName: 衣物
    authoritySource: existing clothing domain and repository
    fields: [id, name, category, photoUris, note, purchaseInfo, createdAt, updatedAt]
  - name: OutfitTemplate
    uiName: 美搭
    authoritySource: existing outfit domain and repository
    fields: [id, title, photoUris, clothingItemIds, note, createdAt, updatedAt]
  - name: Store
    uiName: 店铺
    authoritySource: new domain model
    fields: [id, name, districtOrAddress, note, photoUris, createdAt, updatedAt]
  - name: StoreVisit
    uiName: 逛店记录
    authoritySource: new domain model
    fields: [id, storeId, storeNameSnapshot, visitDate, photoUris, note, createdAt, updatedAt]
  - name: UserProfile
    uiName: 个人信息
    authoritySource: new local profile model
    fields: [heightCm, weightKg, waistCm, updatedAt]
objectRelations:
  - source: OutfitTemplate
    target: ClothingItem
    relation: contains
  - source: StoreVisit
    target: Store
    relation: belongs_to
  - source: StoreVisit
    target: Photo
    relation: has_many
unresolvedObjects:
  - name: PurchasedClothingFromVisit
    reason: 是否要把逛店记录关联到最终买下并加入衣橱的衣物，尚未确认。
verificationAnchors:
  - wardrobe-clothing-tab
  - wardrobe-outfit-tab
  - quick-capture-clothing
  - quick-capture-outfit
  - quick-capture-store-visit
  - store-visit-list
  - profile-measurements
```

## 数据模型

### Store

```ts
export interface Store {
  id: string;
  name: string;
  districtOrAddress?: string;
  photoUris: string[];
  note?: string;
  createdAt: string;
  updatedAt: string;
}
```

### StoreVisit

```ts
export interface StoreVisit {
  id: string;
  storeId?: string;
  storeNameSnapshot: string;
  visitDate: string;
  photoUris: string[];
  note?: string;
  createdAt: string;
  updatedAt: string;
}
```

### UserProfile

```ts
export interface UserProfile {
  heightCm?: number;
  weightKg?: number;
  waistCm?: number;
  updatedAt: string;
}
```

## 数据库迁移

新增迁移版本，例如 `V3StoreVisitSchema`：

- `stores`
- `store_photos`
- `store_visits`
- `store_visit_photos`
- `user_profile`

建议保留旧表：

- `wishlist_items`
- `wishlist_photos`

旧表不再出现在主导航，不参与新逛店流程。后续如需删除，单独设计迁移和数据处理策略。

## 数据流

### 拍衣服

```text
点击 + -> 拍衣服 -> 选择/拍摄照片 -> 衣物编辑页 -> 保存 ClothingItem -> 回到 衣橱/衣裤
```

### 拍搭配

```text
点击 + -> 拍搭配 -> 选择/拍摄照片 -> 美搭编辑页 -> 可选衣物 -> 保存 OutfitTemplate -> 回到 衣橱/美搭
```

### 拍店铺

```text
点击 + -> 拍店铺 -> 选择/拍摄照片 -> 逛店记录编辑页 -> 选择或新建店铺 -> 保存 StoreVisit -> 回到 逛店
```

### 我的

```text
点击头像 -> 我的 -> 编辑个人信息 -> 保存 UserProfile -> 返回
```

## 错误处理

- 照片复制失败时，应保留用户刚选择的照片 URI，并展示非阻塞提示。
- 保存失败时，错误信息展示在表单底部保存按钮附近。
- 店铺未选择时，允许直接保存 `storeNameSnapshot`，后续再补完整店铺信息。
- 逛店记录缺少照片时允许保存，但空态和卡片要显示清晰占位。
- 个人信息数值非法时不保存该字段，并在字段附近提示。

## 搜索策略

第一版可保留局部页面搜索：

- 衣裤：搜索衣物名称和备注。
- 美搭：搜索搭配标题和备注。
- 逛店：搜索店铺名、地址/商圈和逛店备注。

统一搜索如继续保留，需要新增 `Store` 和 `StoreVisit` 搜索类型，并移除 UI 上的 `Wishlist` 入口。

## 组件职责

- `AppTopBar`：logo、应用名、我的头像入口。
- `BottomNavigationBar`：衣橱、快捷、逛店。
- `QuickCaptureSheet`：拍衣服、拍搭配、拍店铺。
- `WardrobePage`：衣橱容器和二级 tab。
- `ClothingPanel`：衣裤列表、分类、搜索和空态。
- `OutfitPanel`：美搭列表、搜索和空态。
- `StoreVisitPage`：逛店记录列表、筛选、空态和编辑入口。
- `StoreVisitEditPage`：创建/编辑逛店记录。
- `StoreEditPage`：创建/编辑店铺信息。
- `ProfilePage`：我的、个人信息和设置入口。

组件视觉职责：

- `AppTopBar` 负责应用品牌和我的入口，不承载页面业务操作。
- `BottomNavigationBar` 负责三项主导航，不能增加首页、日历、逛街等旧入口。
- `QuickCaptureSheet` 负责采集动作，必须大触达、低认知成本。
- `ClothingPanel` 和 `OutfitPanel` 负责内容卡片，不复制顶部栏和底部栏样式。
- `StoreVisitPage` 以逛店记录为主，不退化成店铺主数据表格。
- `ProfilePage` 采用个人中心样式，不使用后台表单风。

## ArkUI 落地约束

- 设计 token 统一维护在 `entry/src/main/ets/theme/Tokens.ets`，页面代码优先使用语义 token，不硬编码颜色、圆角、阴影。
- 新增或重构页面优先沉淀共享组件：`AppTopBar`、`BottomNavigationBar`、`QuickCaptureSheet`、内容卡片、空态组件。
- 现有蓝色 token 可兼容保留，但新主操作统一使用黑色胶囊按钮。
- 不引入新的第三方 UI 库。
- 图片内容必须统一走已有照片 URI / 本地存储能力，不把照片二进制写入 SQLite。
- 页面布局要为底部安全区和系统手势区域预留空间。

## 动效规则

- Sheet 打开和关闭使用位移加透明度过渡。
- 按钮点击使用轻微缩放或透明度反馈。
- Tab 切换保持即时或短透明度过渡，不做夸张滑动动画。
- 列表卡片不做持续环境动效。
- 如平台可感知减少动态效果设置，应避免非必要动画。

## 可访问性

- 主导航和快捷入口触达高度不小于 44。
- 图标按钮需要可读文本或等效语义名称。
- 二级 tab 需要明确选中态，不能只靠颜色。
- 表单字段需要明确标签，不能只依赖 placeholder。
- 错误提示使用文字说明，不只靠红色。
- 主要文字与背景对比度应接近或超过 4.5:1。
- 图片内容需要在周边文本中有可理解说明。
- 保存等异步按钮需要 loading 和禁用态，防止重复提交。

## 测试策略

新增或更新验证脚本覆盖：

1. 主导航只包含 `衣橱`、`+`、`逛店`。
2. 顶部工具栏包含 `衣不缺` 和我的入口。
3. 快捷入口包含 `拍衣服`、`拍搭配`、`拍店铺`。
4. 衣橱页包含 `衣裤`、`美搭` 二级 tab。
5. UI 文案不再出现 `首页` 推荐流、`心愿单` 作为主入口、`穿搭` 作为主要用户文案。
6. 新增 Store/StoreVisit domain、migration、repository 的静态契约校验。
7. 逛店记录保存后能从列表读取，照片 URI 顺序保持稳定。
8. 个人信息只保存合法数值。
9. 视觉 token 包含黑色主操作、大圆角、柔和背景和轻阴影规则。
10. 可达主界面不出现点赞、收藏、评论、关注等伪社交动作。

完整验证：

```bash
for script in scripts/validate-*.mjs; do node "$script" || exit 1; done
git diff --check
```

真机或模拟器 QA：

- 启动不白屏。
- 三个主导航可切换。
- `+` 面板可打开和关闭。
- 三个快捷入口均能进入对应编辑流程。
- 衣橱二级 tab 可切换。
- 逛店记录可新增、编辑并回显。
- 我的个人信息可保存并回显。
- 主操作按钮为黑色胶囊样式。
- 卡片图片为圆角，不出现直角大图。
- 页面整体不呈现后台管理风或社交推荐流。

## 实施顺序建议

1. 新增设计验证脚本，先让它失败。
2. 将 `docs/background/yibuque-design.md` 中的核心 token 落到 `Tokens.ets`。
3. 改主导航和顶部工具栏。
4. 改衣橱为 `衣裤 / 美搭` 二级 tab。
5. 新增 Store/StoreVisit 数据模型、迁移和仓储。
6. 改 `逛店` 页面和 `拍店铺` 流程。
7. 新增 Profile/UserProfile。
8. 清理推荐流、心愿单主入口和穿搭用户文案。
9. 跑全量校验和手工 QA。
