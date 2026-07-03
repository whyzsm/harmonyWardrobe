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
- 右侧：头像按钮。
- 点击头像进入 `我的`。
- 进入编辑页、拍照表单页时可保留返回按钮，避免顶部工具栏挤占表单空间。

### 主导航

底部主导航只保留：

- `衣橱`
- 中间凸起 `+`
- `逛店`

`+` 点击后打开快捷操作面板：

- `拍衣服`：进入衣物创建流程。
- `拍搭配`：进入美搭创建流程。
- `拍店铺`：进入逛店记录创建流程。

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

`美搭`：

- 展示用户保存的搭配。
- 支持从衣裤选择多件衣物组成搭配。
- 支持拍照型搭配，即没有完整衣物关联时也可以保存照片和备注。
- 空态提示：点击底部 `+` 的 `拍搭配` 添加第一套美搭。

### 逛店页

逛店页以逛店记录为主列表：

- 默认按 `visitDate / updatedAt` 倒序展示。
- 每条记录展示店铺名、日期、首图和备注摘要。
- 支持新建/选择店铺。
- 支持从记录进入编辑店铺信息。

店铺是逛店记录的归属对象，不要求用户先维护店铺主数据。`拍店铺` 应优先创建一条逛店记录，然后在表单里选择或新建店铺。

### 我的页

我的页包含：

- 头像/昵称区域，可先本地静态展示。
- 个人信息：身高、体重、腰围。
- 设置入口。

第一版可以只保存个人信息，不实现复杂账号系统。

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

## 可访问性

- 主导航和快捷入口触达高度不小于 44。
- 图标按钮需要可读文本或等效语义名称。
- 二级 tab 需要明确选中态，不能只靠颜色。
- 表单字段需要明确标签，不能只依赖 placeholder。
- 错误提示使用文字说明，不只靠红色。

## 测试策略

新增或更新验证脚本覆盖：

1. 主导航只包含 `衣橱`、`+`、`逛店`。
2. 顶部工具栏包含 `衣不缺` 和我的入口。
3. 快捷入口包含 `拍衣服`、`拍搭配`、`拍店铺`。
4. 衣橱页包含 `衣裤`、`美搭` 二级 tab。
5. UI 文案不再出现 `首页` 推荐流、`心愿单` 作为主入口、`套装` 作为主要用户文案。
6. 新增 Store/StoreVisit domain、migration、repository 的静态契约校验。
7. 逛店记录保存后能从列表读取，照片 URI 顺序保持稳定。
8. 个人信息只保存合法数值。

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

## 实施顺序建议

1. 新增设计验证脚本，先让它失败。
2. 改主导航和顶部工具栏。
3. 改衣橱为 `衣裤 / 美搭` 二级 tab。
4. 新增 Store/StoreVisit 数据模型、迁移和仓储。
5. 改 `逛店` 页面和 `拍店铺` 流程。
6. 新增 Profile/UserProfile。
7. 清理推荐流、心愿单主入口和套装用户文案。
8. 跑全量校验和手工 QA。
