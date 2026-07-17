# 「衣不缺」完整优化方案

> 基于 2026-07-14 衣橱质量评审团三线并行评审报告，逐条验证关键代码后制定。
> 每条改动均附文件路径与行号，可直接作为开发工单执行。
> 状态：本计划记录 2026-07-14 的旧实现快照；导航状态和页面命名已由 `architecture-convergence-2026-07-15` 变更完成，旧代码片段仅供追溯，不应直接照抄。

---

## 一、评审结果速览

| 维度 | 当前评分 | 优化目标 | 关键缺陷 |
|---|---|---|---|
| 功能与流程 | 5.5/10 | 8.0/10 | 删除全线缺失、心愿单不可达、媒体泄漏、搜索索引未接线 |
| UI 与视觉 | 5.8/10 | 8.5/10 | 彩色阴影、粉色错误态、错误红三态不统一、token 缺字段 |
| 交互与动效 | 4.5/10 | 7.5/10 | 零转场、零懒加载、零 LoadingProgress、Profile 写竞态 |

**综合目标**：5.3/10 → 8.0/10

---

## 二、优化分阶段执行计划

### 阶段一：P0 清零（阻断 + 红线，1-2 天）

#### 1.1 删除链路打通 + 媒体回收接线

**涉及文件**：
- `app/WardrobeRuntime.ets:160,165-169`
- `data/repositories/ClothingRepository.ets:382-384`
- `data/repositories/OutfitRepository.ets:372-374`
- `data/repositories/WearLogRepository.ets:355-357`
- `data/repositories/WishlistRepository.ets:289-291`
- `data/repositories/StoreRepository.ets:306`
- `pages/ClothingDetailPage.ets`（加删除入口）
- `pages/WardrobePage.ets`（加列表项删除入口）
- 其余需要删除的列表/详情页

**改动 A：WardrobeRuntime 注入 photoStorage 到 repository**

```
// 🔴 现状：各 repository 构造时只传 database + searchIndexMode
new ClothingRepository(database, searchIndexMode)
new OutfitRepository(database, searchIndexMode)
new WearLogRepository(database, searchIndexMode)
new WishlistRepository(database, searchIndexMode)
new StoreRepository(database, searchIndexMode)

// 🟢 改为：追加 photoStorage 参数
new ClothingRepository(database, searchIndexMode, photoStorage)
new OutfitRepository(database, searchIndexMode, photoStorage)
new WearLogRepository(database, searchIndexMode, photoStorage)
new WishlistRepository(database, searchIndexMode, photoStorage)
new StoreRepository(database, searchIndexMode, photoStorage)
```

**改动 B：各 repository 构造函数接收并透传 photoStorage**

每个 repository（以 ClothingRepository 为例）：

```typescript
// 🔴 现状
constructor(database: MigrationDatabase, searchIndexMode: SearchIndexMode) { ... }
// createDeleteCleanupService() 中：
return new DeleteCleanupService(this.database, this.searchRepository);

// 🟢 改为
private readonly photoStorage?: PhotoStorage;

constructor(database: MigrationDatabase, searchIndexMode: SearchIndexMode, photoStorage?: PhotoStorage) {
  ...
  this.photoStorage = photoStorage;
}

// createDeleteCleanupService() 中：
return new DeleteCleanupService(this.database, this.searchRepository, this.photoStorage);
```

影响：5 个 repository 各约 3 行改动，无 API 破坏性变更（photoStorage 为可选参数）。

**改动 C：UI 层加删除入口**

以 `ClothingDetailPage` 为例（在页面右上角或底部加删除按钮）：

```typescript
// 新增 @State
@State showDeleteConfirm: boolean = false;
@State isDeleting: boolean = false;

// 新增 Builder
@Builder DeleteConfirmDialog() {
  AlertDialog.show({
    message: '确定要删除这件衣物吗？照片也将一并移除',
    primaryButton: { value: '取消', action: () => {} },
    secondaryButton: {
      value: '删除',
      action: async () => {
        this.isDeleting = true;
        try {
          await this.clothingRepository?.deleteClothing(this.clothingId);
          this.onDeleted?.();
        } finally {
          this.isDeleting = false;
        }
      }
    }
  });
}
```

需要加删除入口的页面清单：
- `ClothingDetailPage.ets` — 衣物详情
- `WardrobePage.ets` — 衣物列表（长按菜单或卡片右上角）
- 穿搭详情/列表（`OutfitPage` 或 `OutfitDetailPage`，如存在）
- 穿着日志列表（`WearLogPage`，如存在）
- 心愿单详情（`WishlistPage.ets` 或 `WishlistEditPage.ets`，见 1.2）
- 逛店记录列表（`StoreVisitPage.ets`）

**风险**：无。repository 的 delete 方法已实现，只是无 UI 调用。

---

#### 1.2 心愿单接入导航

**涉及文件**：
- `pages/Index.ets:267-285`（onOpenSearchTarget 路由修正）
- `pages/SearchResultsPage.ets:46,270,279-289,623`（路由修正）
- `pages/BottomNavigationBar.ets`（可选：加心愿单标签）

**改动 A：搜索结果路由修正**

```typescript
// 🔴 现状 (Index.ets:267-285)
onOpenSearchTarget(entityType, entityId) {
  if (entityType === SearchEntityType.Outfit) { ... }
  else if (entityType === SearchEntityType.StoreVisit) { ... }
  else { this.showProfilePage = true; }  // ← Wishlist / WearLog 统统落到 profile
}

// 🟢 改为
onOpenSearchTarget(entityType, entityId) {
  if (entityType === SearchEntityType.Outfit) { ... }
  else if (entityType === SearchEntityType.StoreVisit) { ... }
  else if (entityType === SearchEntityType.Wishlist) {
    this.openWishlistPage(entityId);
    this.wishlistTargetId = entityId;
  }
  else if (entityType === SearchEntityType.WearLog) {
    this.showWearLogDetail = true;
    this.wearLogTargetId = entityId;
  }
  else { this.showProfilePage = true; }
}
```

**改动 B：SearchResultsPage 路由修正**

```typescript
// 🔴 现状 (:279-289) WearLog/Wishlist → onOpenProfileResult
// 🟢 改为各自的回调节点
onOpenWishlistResult(entityId: string) { ... }
onOpenWearLogResult(entityId: string) { ... }
```

**改动 C：底部导航加心愿单入口（推荐方案）**

在 `BottomNavigationBar.ets` 现有的「衣柜/逛店/相机/穿搭/我的」五个位置中，将「我的」内含心愿单子入口，或在 ProfilePage 内增加「心愿单」区块。

**注意**：`WishlistPage.ets` 当前已实现完整功能，`WishlistEditPage.ets` 亦然。接入即可用，改动量主要在 Index.ets 的导航状态管理（约 30-40 行）。

---

#### 1.3 清除虚构数据与远程同步暗示

**改动 A：删除或重写 TodayPage**

**涉及文件**：`pages/TodayPage.ets:354-492`

两个方案选一：
- **方案 A（推荐）**：直接删除 `pages/TodayPage.ets` 及对应 import 引用。该页当前已是孤儿代码（全站 0 import），删除零副作用。
- **方案 B**：重写为「今日灵感」，仅展示用户本地已录入的穿搭/衣物，不涉及任何社区/点赞/作者/评论。但工作量 > 方案 A 且与当前需求背离。

**改动 B：移除"待同步"标签**

**涉及文件**：`pages/WardrobePage.ets:27-34`

```typescript
// 🔴 现状
const WARDROBE_CATEGORY_FILTERS: WardrobeCategoryFilter[] = [
  { label: '全部' },
  { label: '上衣', category: ClothingCategory.Top },
  { label: '裤装', ... },
  { label: '裙装', ... },
  { label: '包袋', categories: [] },    // ← 恒空，也删
  { label: '待同步', categories: [] }    // ← 红线，删除
];

// 🟢 改为
const WARDROBE_CATEGORY_FILTERS: WardrobeCategoryFilter[] = [
  { label: '全部' },
  { label: '上衣', category: ClothingCategory.Top },
  { label: '裤装', categories: [ClothingCategory.Pants, ClothingCategory.Shorts] },
  { label: '裙装', categories: [ClothingCategory.LongSkirt, ClothingCategory.HalfSkirt] }
];
```

同时清理 `WardrobePage.ets:36-40` 的死常量 `OPEN_DESIGN_*`、`SCREENSHOT_NAV_GRAY`。

---

#### 1.4 设计方向硬违规修复

**改动 A：BottomNavigationBar 相机阴影改中性黑**

**涉及文件**：`components/BottomNavigationBar.ets:65`

```typescript
// 🔴 现状
.shadow({ radius: 18, color: '#735A7CFF', offsetX: 0, offsetY: 0 })

// 🟢 改为（对齐全站 YibuqueShadow 规范）
.shadow({ radius: 18, color: '#26000000', offsetX: 0, offsetY: 0 })
```

**改动 B：StoreVisitEditPage 去粉色**

**涉及文件**：`pages/StoreVisitEditPage.ets:208,210,374,411`

```typescript
// 🔴 现状
.backgroundColor('#FFF7F7')                   // :208
.border({ width: 1, color: '#F3B8B8' })      // :210
.backgroundColor(this.isStoreNameInvalid() ? '#FFF0F0' : '#F5F3F3')  // :374, 411

// 🟢 改为
.backgroundColor(YibuqueColor.bgGray)          // 中性浅灰错误表面
.border({ width: 1, color: AppTheme.color.danger }) // 统一错误红边框
.backgroundColor(this.isStoreNameInvalid() ? AppTheme.color.surfaceMuted : YibuqueColor.cardSoftGray)
```

**阶段一预估**：改动 ~200 行（含 5 个 repository 各 3 行 + Index 导航 30 行 + 搜索结果路由 20 行 + 各页面删除入口 100 行 + TodayPage 删除或重写 + token 修正 20 行）。

---

### 阶段二：P1 治理（质量与一致性，2-3 天）

#### 2.1 错误红 token 统一

**涉及文件**：
- `theme/Tokens.ets`（补 `danger` 字段）
- `pages/Index.ets`（消除硬编码 `#EF4444`）
- 所有使用 `#EF4444` / `#BA1A1A` 的页面

**改动 A：Tokens.ets 补 danger 字段到 YibuqueColor**

```typescript
// YibuqueColorTokens 接口（:20-42）增加
danger: string;

// YibuqueColor 值对象（:149-171）增加
danger: '#DC2626',          // 对齐 AppTheme.color.danger
```

**改动 B：全站搜索替换**

```bash
# 搜索所有硬编码错误红
grep -rn '#EF4444\|#BA1A1A' entry/src/main/ets/
```

将找到的所有硬编码改为 `YibuqueColor.danger`（与视觉语义一致时）或 `AppTheme.color.danger`（与系统语义一致时）。

---

#### 2.2 ClothingEditPage 照片复制失败回退

**涉及文件**：`pages/ClothingEditPage.ets:216-231`

```typescript
// 🔴 现状：复制失败保留非本地 URI（:216-231）
const fallbackUris = sources.map(s => s.uri);
this.photoUris = fallbackUris;  // 先预设非本地 URI
try {
  const localUris = await this.copySourcesToLocalUris(sources);
  if (localUris.length > 0) {
    this.photoUris = localUris;  // 成功后覆盖
  }
} catch (copyError) {
  console.info(...);  // ⚠️ 失败沉默，非本地 URI 保留在 photoUris 中
}

// 🟢 改为：失败即清空，展示错误提示
try {
  const localUris = await this.copySourcesToLocalUris(sources);
  if (localUris.length > 0) {
    this.photoUris = localUris;
    this.previewPhotoUri = localUris[0];
  } else {
    this.errorMessage = '照片复制失败，请重试';
    this.photoUris = [];
    this.previewPhotoUri = '';
  }
} catch (copyError) {
  this.errorMessage = `照片保存失败：${copyError instanceof Error ? copyError.message : '未知错误'}`;
  this.photoUris = [];
  this.previewPhotoUri = '';
}
```

参考范本：其余编辑器（CaptureEditPage、StoreVisitEditPage）均为失败即空做法。

---

#### 2.3 相册选图防重（isChoosingPhotos）

**涉及文件**：
- `pages/ClothingEditPage.ets:203-235`（最严重：连 isSaving 都不守）
- `pages/StoreVisitEditPage.ets:99-110`（只守 isSaving，缺 isChoosingPhotos）

参照范本：`pages/CaptureEditPage.ets` 已有 `isChoosingPhotos` + `isSaving` 双重守护。

**通用模板**：

```typescript
@State isChoosingPhotos: boolean = false;

async pickGalleryPhotos() {
  if (this.isSaving || this.isChoosingPhotos) return;
  this.isChoosingPhotos = true;
  try {
    // 拉起相册选择...
  } finally {
    this.isChoosingPhotos = false;
  }
}

async capturePhoto() {
  if (this.isSaving || this.isChoosingPhotos) return;
  this.isChoosingPhotos = true;
  try {
    // 拉起拍照...
  } finally {
    this.isChoosingPhotos = false;
  }
}
```

---

#### 2.4 搜索索引重建接线

**涉及文件**：`data/repositories/SearchRepository.ets:258`、`app/WardrobeRuntime.ets`

```typescript
// WardrobeRuntime.create() 中迁移完成后追加：
const searchCapability = await detectSearchCapability(database);
const searchIndexMode = searchCapability.mode;

// 🟢 新增：首次启动或索引缺失时重建
if (searchIndexMode !== SearchIndexMode.None) {
  await new SearchRepository(database, searchIndexMode).rebuildSearchIndex();
}
```

或在 `SearchRepository` 构造函数内部自动检测并重建。推荐启动时显式调用，降低隐式副作用风险。

---

#### 2.5 搜索路由修正（见阶段一 1.2，在此完成）

与 1.2 共用同一组改动。

---

#### 2.6 视觉 token 收口

**改动 A：StoreVisitEditPage 暖灰板统一**

```typescript
// 搜索 StoreVisitEditPage.ets 中所有 '#F5F3F3' 实例
// 替换为 YibuqueColor.bgGray 或 YibuqueColor.cardSoftGray
```

**改动 B：WardrobePage 删除 OPEN_DESIGN_* 死常量**

与 1.3 改动 B 同一组（`:36-40`）。

**改动 C：QuickCaptureSheet 恢复为三分类入口**

**涉及文件**：`components/QuickCaptureSheet.ets`

恢复为：
1. 黑卡「衣柜」（白衣物 SymbolGlyph）
2. 浅灰卡「逛店」（灰边店铺 SymbolGlyph）
3. 浅灰卡「穿搭」（灰边衣架 SymbolGlyph）

点击后直接进入对应新增页面：衣柜进入新增衣物，逛店进入新增逛店记录，穿搭进入新增穿搭；拍照和相册选择继续由对应页面内的入口提供。标题「快捷录入」、取消按钮黑色，与设计规范对齐。

**改动 D：图片圆角统一**

- `ClothingCard.ets` + `StoreVisitCard.ets`：图片圆角 18 → `YibuqueRadius.xs` (5)
- 保持内容卡片本身圆角不变（`:12-18` 为卡片壳圆角，不是图片圆角）

**改动 E：WearLogEditPage / WishlistEditPage 表单标签**

在输入框上方增加 `Text('标签名')` 描述，不依赖 placeholder 充当标题。WishlistEditPage 替换开发态键名为正式中文标签（如 `'商品名称'` / `'期望价格'`）。

---

#### 2.7 动效与性能（核心体验升级）

**改动 A：编辑器/弹层转场动画**

**涉及文件**：`pages/Index.ets:171-417`、各编辑器页

```typescript
// 在 Index.ets 的条件渲染块外加转场
if (this.showClothingEditor) {
  Column() {
    ClothingEditPage(...)
  }
  .transition(TransitionEffect.asymmetric(
    TransitionEffect.OPACITY.animation({ duration: 250 }),
    TransitionEffect.OPACITY.animation({ duration: 200 })
  ))
  .onClick(() => {})  // 遮罩效果
}
```

同时叠加层打开时底层容器设 `.enabled(false)`：

```typescript
// 底层内容容器
Column() {
  // 主标签/列表内容...
}
.enabled(!this.showClothingEditor && !this.showCaptureEditor && !this.showNestedPage)
```

**改动 B：列表懒加载**

**涉及文件**：
- `pages/WardrobePage.ets:943-949`（WaterFlow）
- `pages/StoreVisitPage.ets:412-418`（WaterFlow）
- `pages/OutfitsPage.ets:324-330`（Grid）

实现类：

```typescript
class ClothingDataSource implements IDataSource {
  private items: ClothingItem[] = [];
  private listeners: DataChangeListener[] = [];

  totalCount(): number { return this.items.length; }
  getData(index: number): ClothingItem { return this.items[index]; }
  registerDataChangeListener(listener: DataChangeListener): void {
    if (!this.listeners.includes(listener)) this.listeners.push(listener);
  }
  unregisterDataChangeListener(listener: DataChangeListener): void {
    this.listeners = this.listeners.filter(l => l !== listener);
  }

  setData(items: ClothingItem[]): void {
    this.items = items;
    this.listeners.forEach(l => l.onDataReloaded());
  }
}
```

使用：

```typescript
// 🔴 现状：WaterFlow() { ForEach(this.clothingItems, ...) }
// 🟢 改为
@State clothingDataSource: ClothingDataSource = new ClothingDataSource();

// 加载数据后
this.clothingDataSource.setData(items);

// 模板中
WaterFlow() {
  LazyForEach(this.clothingDataSource, (item: ClothingItem, index: number) => {
    FlowItem() {
      ClothingCard({ item, ... })
    }
  }, (item: ClothingItem) => item.id)
}
```

**改动 C：保存按钮 LoadingProgress**

**涉及文件**：7 个 Edit 页 + ProfilePage

```typescript
// 🔴 现状：Button(`保存中...`) .enabled(canSave())
// 🟢 改为
Button() {
  if (this.isSaving) {
    LoadingProgress()
      .width(20).height(20)
      .color(Color.White)
  } else {
    Text('保存').fontColor(Color.White)
  }
}
.enabled(canSave())
.backgroundColor(canSave() ? AppTheme.color.primary : AppTheme.color.disabled)
```

**改动 D：ProfilePage persistPreferences 写竞态修复**

**涉及文件**：`pages/ProfilePage.ets:289-307`

```typescript
// 🔴 现状：直接 this.profileRepository.saveProfile(...)，绕过 isSaving
// 🟢 改为
async persistPreferences(): Promise<void> {
  if (this.isSaving) return;
  this.isSaving = true;
  try {
    await this.profileRepository.saveProfile(this.currentProfile);
  } finally {
    this.isSaving = false;
  }
}
```

**改动 E：OutfitsPage Grid 嵌套 Scroll 修复**

**涉及文件**：`pages/OutfitsPage.ets:324-330`

```typescript
// 🔴 现状：Scroll { Grid { ... } }
// 🟢 改为（与 WardrobePage 一致）
WaterFlow() {
  LazyForEach(this.outfitDataSource, (outfit: OutfitTemplate) => {
    FlowItem() { OutfitCard({ outfit, ... }) }
  }, (outfit: OutfitTemplate) => outfit.id)
}
```

**阶段二预估**：改动 ~500 行（token 30 行 + ClothingEditPage 20 行 + 防重 40 行 × 2 + 搜索路由 30 行 + token 收口 100 行 + 转场动画 80 行 × 4 + 懒加载 100 行 × 3 + LoadingProgress 20 行 × 8 + Profile 10 行 + Outfit 40 行）。

---

### 阶段三：P2 打磨（健壮性与体验细节，1-2 天）

#### 3.1 死代码清理

```
删除以下文件（全站 0 import）：
- pages/TodayPage.ets          （如阶段一已删除）
- pages/CalendarPage.ets
- pages/WishlistPage.ets       （如阶段一已接入则保留）
- pages/WishlistEditPage.ets   （如阶段一已接入则保留）
- components/CategoryTabs.ets
- components/OutfitCard.ets
- components/StoreVisitCard.ets
- components/AppTopBar.ets
```

如决定保留 WishlistPage / WishlistEditPage（已接入导航），则仅清理其余真正无引用的文件。

#### 3.2 点击区 ≥ 44×44

**批量修改清单**：

| 文件 | 行号/区域 | 当前尺寸 | 改为 |
|---|---|---|---|
| WardrobePage.ets | 分类标签 (:892 区) | `.height(42)` | `.constraintSize({ minHeight: 44 })` + padding |
| WardrobePage.ets | 搜索图标 (:684 区) | `.width(22)` | 外包 Stack `.width(44)`，图标居中 |
| OutfitsPage.ets | "记录穿着" 文字 (:521-530 区) | ~11-15px | 外包 Row `.minHeight(44)` |
| SearchResultsPage.ets | 返回/清除/相机 (:319-366 区) | 34px | `.width(44).height(44)` |
| SearchResultsPage.ets | tabs (:424 区) | `.height(36)` | `.constraintSize({ minHeight: 44 })` |
| SearchResultsPage.ets | chips (:501 区) | `.height(40)` | `.minHeight(44)` |
| ProfilePage.ets | StyleTag (:686 区) | `.height(32)` | `.constraintSize({ minHeight: 44 })` |
| ClothingEditPage.ets | 清除日期 × (:508-509) | 36×36 | 44×44（hitTestBehavior 扩热区） |

**范本参考**：`BottomNavigationBar` (52px)、`SecondaryPageHeader` (48px)、`ClothingPicker`/`OutfitPicker`（整行/44）。

#### 3.3 WardrobePage CardHeart 假控件

**涉及文件**：`pages/WardrobePage.ets:1055-1067`

方案：要么删除该装饰，要么接入真实 favorite 态。若接真实态，需同步更新 `ClothingItem` domain 模型加 `isFavorite` 字段及对应数据库列。

**推荐**：P2 阶段先移除装饰（1 行改动），等收藏功能正式落地时再补真实实现。

#### 3.4 转场对称 + setTimeout 清理

- `QuickCaptureSheet.ets:23-28,79-83`：退场补 `animateTo` 对称动画
- `ClothingCard.ets:12-17`：`setTimeout` 入场改 `.transition()` + `onAppear`
- `ClothingDetailPage.ets:501-508`：PhotoPreviewOverlay 加 `.transition({ type: TransitionType.Insert, opacity, scale })`

#### 3.5 其余 P2

- `Index.ets:351` 底部导航条件补 `&& !this.showQuickActions`
- `StoreRepository.ets` 补 `deleteStore` 方法
- `ensureBaseSchema` 冗余迁移清理（删 `WardrobeRuntime.ets:156,177-183`）
- 废弃主题常量清理（`theme/` 下多处理文件）
- `StoreVisitPage.ets` 滤选项 "刷新/refresh" → 本地语义
- 零散视觉 token 副本消除

**阶段三预估**：改动 ~200 行（清理 50 行 + 点击区 80 行 + 动画 40 行 + 其余 30 行）。

---

## 三、估工与里程碑

| 阶段 | 内容 | 改动量 | 估工 | 累积健康度 |
|---|---|---|---|---|
| **阶段一** | P0 × 7 清零 | ~200 行 | 1-2 天 | 5.3 → 7.0 |
| **阶段二** | P1 × 14 治理 | ~500 行 | 2-3 天 | 7.0 → 8.0 |
| **阶段三** | P2 × 11 打磨 | ~200 行 | 1-2 天 | 8.0 → 8.2 |
| **合计** | 全部 32 项 | ~900 行 | **4-7 天** | **5.3 → 8.2** |

---

## 四、执行顺序建议

```
Day 1-2（阶段一）
├── 1.1-A WardrobeRuntime 注入 photoStorage（20 行，10 分钟）
├── 1.1-B 5 个 repository 透传 photoStorage（15 行，15 分钟）
├── 1.3-B 移除"待同步"标签 + OPEN_DESIGN_*（5 行，2 分钟）
├── 1.3-A 删除 TodayPage（1 个文件删除，1 分钟）
├── 1.4-A BottomNavigationBar 阴影改中性黑（1 行，1 分钟）
├── 1.4-B StoreVisitEditPage 去粉色（6 行，5 分钟）
├── 1.1-C 各页面删除入口（100 行，半天）
└── 1.2 心愿单接入导航（50 行，半天）

Day 3-4（阶段二）
├── 2.1 错误红 token 统一（30 行，30 分钟）
├── 2.2 ClothingEditPage 非本地 URI 修正（20 行，15 分钟）
├── 2.3 isChoosingPhotos 防重（80 行，1 小时）
├── 2.4 rebuildSearchIndex 接线（10 行，10 分钟）
├── 2.6 视觉 token 收口（100 行，半天）
├── 2.7-A 转场动画（80 × 4，半天）
└── 2.7-B 列表懒加载（100 × 3，半天）

Day 5-6（阶段二续 + 阶段三）
├── 2.7-C LoadingProgress（20 × 8，1 小时）
├── 2.7-D Profile 写竞态（10 行，10 分钟）
├── 2.7-E OutfitsPage 嵌套滚动（40 行，30 分钟）
├── 3.1 死代码清理（50 行，15 分钟）
├── 3.2 点击区 ≥44（80 行，1 小时）
├── 3.3-3.5 其余 P2（70 行，1 小时）
└── 回归评审（用 wardrobe-review-team 专家跑一轮）
```

---

## 五、质量保障

1. **每阶段完成后跑回归评审**：用 `wardrobe-review-team` 专家包跑 Workflow C（对比 `docs/review/expert-review-2026-07-14-expert.md`），确认 P0/P1 无复现、无新引入。
2. **版本控制**：每个阶段独立 commit，方便回滚。
3. **无真机环境下的验证**：运行 `scripts/*.mjs` 校验脚本确认 `git diff --check` 无问题。
4. **构建验证**：阶段二完成后执行 `hvigorw assembleHap` 确保编译通过。

---

## 六、风险提示

| 风险 | 级别 | 应对 |
|---|---|---|
| 删除功能接入后媒体清理未充分测试 | 中 | 先在单件衣物上验证"删除 → photoStorage 确实删除了文件"，再扩展 |
| 手机号 = 旧迁移链依赖 | 低 | 迁移链 V1-V5 经专家确认顺序正确、幂等，改动不碰迁移 |
| LazyForEach 数据源生命周期 | 中 | 参考 HarmonyOS 官方 WaterFlow+LazyForEach 示例实现，避免内存泄漏 |
| 心愿单接入后 WishlistPage UI 与当前设计方向还有差距 | 低 | WishlistPage 本身 UI 较简陋，建议在 P2 阶段一并打磨 |

---

> 本方案基于 2026-07-14 衣橱质量评审团三线评审报告制定，所有关键发现已逐条验证。
> 执行时若遇到问题，可重新激活 `wardrobe-review-team` 专家做针对性审查。
