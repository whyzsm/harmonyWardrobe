# Harmony Wardrobe UI Refresh Design

Date: 2026-06-30

## 中文 / Chinese

### 已确认方向

把 Harmony Wardrobe 从“朴素本地管理工具”刷新为“蓝色轻电商感衣橱 App”。主色固定为 `#4894FE`，界面保持移动端高频记录工具的清晰度，同时借鉴电商 App 的商品卡、搜索、分类、心愿单和底部导航表达。

### Confirmed Direction

Refresh Harmony Wardrobe from a plain local management tool into a blue, lightweight ecommerce-style wardrobe app. The primary color is fixed to `#4894FE`. The interface should remain clear for frequent mobile logging while borrowing ecommerce patterns for product cards, search, categories, wishlist, and bottom navigation.

## Figma 参考结论 / Figma Reference Findings

### 中文

已读取用户提供的 Figma 社区文件。`Stylish Shopping App`、`Nexkart`、`Shopping App Prototype` 和 `ShopXpress` 主要提供电商结构参考：商品网格、横向分类、搜索框、心愿按钮、购物车/心愿列表和卡片层级。`Dokterian Doctor Appointment` 的蓝色、白底、日程卡和底部 Tab 结构最适合迁移到本项目，因为它和 `#4894FE` 以及“今日穿搭/日历记录”的任务模型最匹配。

### English

The provided Figma community files were read. `Stylish Shopping App`, `Nexkart`, `Shopping App Prototype`, and `ShopXpress` mainly provide ecommerce structure references: product grids, horizontal categories, search fields, wishlist buttons, cart/wishlist lists, and card hierarchy. `Dokterian Doctor Appointment` is the closest visual fit because its blue palette, white surfaces, schedule cards, and bottom tabs map well to `#4894FE` and the app's “today outfit / calendar logging” task model.

## 产品目标 / Product Goal

### 中文

本次改版只解决视觉体系和页面排版，不改变业务范围。用户应该能更快识别“今天要记录什么”“衣橱里有什么”“哪些单品想买”，并且第一眼觉得这是一个完整的移动 App，而不是数据库演示页面。

### English

This refresh only changes the visual system and page layout. It does not change product scope. Users should quickly understand what to log today, what is in the wardrobe, and which wishlist items they want to buy. The first impression should feel like a complete mobile app rather than a database demo page.

## 推荐方案 / Recommended Approach

### 中文

采用方案 A：蓝色轻电商衣橱。

取舍：

- 相比粉色时尚风，它更贴合用户指定的 `#4894FE`，也更耐看。
- 相比纯工具风，它能明显提升衣物和心愿单的商品展示感。
- 相比完整重做导航和页面结构，它能最大化复用现有 ArkUI 页面，降低白屏和运行时回归风险。

### English

Use Approach A: Blue Lightweight Ecommerce Wardrobe.

Trade-offs:

- Compared with a pink fashion style, it fits the requested `#4894FE` better and is more durable.
- Compared with a pure utility style, it makes clothing and wishlist content feel more like browsable products.
- Compared with rebuilding navigation and page structure, it reuses the current ArkUI pages and lowers the risk of white-screen or runtime regressions.

## 设计 Token / Design Tokens

### 中文

颜色角色：

- Primary: `#4894FE`
- Primary pressed: `#246BFE`
- Primary soft: `#EAF3FF`
- Background: `#F6F8FC`
- Surface: `#FFFFFF`
- Surface raised: `#FFFFFF`
- Text primary: `#111827`
- Text secondary: `#6B7280`
- Text disabled: `#9CA3AF`
- Border: `#E5EAF2`
- Success: `#22C55E`
- Warning: `#FFB020`
- Danger: `#EF4444`
- Fashion accent: `#FF7A90`

圆角和间距：

- 小控件圆角：`8`
- 卡片圆角：`12`
- 大图圆角：`14`
- 页面左右边距：`20`
- 卡片内边距：`12` 到 `16`
- 区块间距：`16`

### English

Color roles:

- Primary: `#4894FE`
- Primary pressed: `#246BFE`
- Primary soft: `#EAF3FF`
- Background: `#F6F8FC`
- Surface: `#FFFFFF`
- Surface raised: `#FFFFFF`
- Text primary: `#111827`
- Text secondary: `#6B7280`
- Text disabled: `#9CA3AF`
- Border: `#E5EAF2`
- Success: `#22C55E`
- Warning: `#FFB020`
- Danger: `#EF4444`
- Fashion accent: `#FF7A90`

Radius and spacing:

- Small controls radius: `8`
- Card radius: `12`
- Large image radius: `14`
- Page horizontal padding: `20`
- Card padding: `12` to `16`
- Section spacing: `16`

## 页面设计 / Screen Design

### 中文

Today 页面：

- 顶部使用紧凑标题和日期，不做大 Hero。
- 今日穿搭状态用浅蓝信息卡承载，主行动按钮使用 `#4894FE`。
- 最近套装继续使用两列网格，但卡片更像商品卡，图片优先、标题和件数次之。

Wardrobe 页面：

- 搜索框改为浅色胶囊感输入区。
- 分类 chip 横向滚动，选中态为蓝底白字，未选中态为白底灰字。
- 衣物卡保留两列商品网格，图片区域更稳定，分类改为小标签。

Outfits 页面：

- 套装卡增加蓝色件数 badge。
- “记录一次穿着”作为次级蓝色描边动作，而不是黑色工具按钮。
- 创建按钮使用主蓝色。

Calendar 页面：

- 日历容器使用白色卡片。
- 选中日期为蓝色实心态，有记录日期使用小蓝点或蓝色边框。
- 当天记录列表使用轻量日程卡，借鉴 Dokterian 的预约卡层级。

Shopping 页面：

- 心愿单卡片改成电商列表：左图、右侧标题/门店/价格。
- 价格使用成功色，心愿/状态强调可使用时尚强调色。
- 添加心愿按钮使用主蓝色。

底部导航：

- 激活态使用 `#4894FE`，非激活态使用 `#9CA3AF`。
- 保持当前五个 Tab，不新增页面和权限。

### English

Today screen:

- Use a compact title and date, not a large hero.
- Present today's outfit state in a light-blue info card, with the main action using `#4894FE`.
- Keep the recent outfits as a two-column grid, but make cards feel more like product cards with image first, then title and item count.

Wardrobe screen:

- Refresh the search field into a soft pill-like input.
- Keep horizontal category chips; selected uses blue fill with white text, inactive uses white surface with muted text.
- Keep the two-column clothing grid. Make the image region stable and turn the category into a small label.

Outfits screen:

- Add a blue item-count badge to outfit cards.
- Make “record a wear” a secondary blue outline action instead of a black utility button.
- Use the primary blue for create actions.

Calendar screen:

- Use a white card for the calendar container.
- Selected date uses a blue filled state. Dates with records use a small blue dot or blue border.
- Display selected-day records as lightweight schedule cards, borrowing hierarchy from Dokterian appointment cards.

Shopping screen:

- Refresh wishlist cards into ecommerce list rows: image on the left, title/store/price on the right.
- Use success color for prices. Use the fashion accent for wishlist/status emphasis when needed.
- Use primary blue for the add-wishlist action.

Bottom navigation:

- Active state uses `#4894FE`; inactive state uses `#9CA3AF`.
- Keep the current five tabs. Do not add pages or permissions.

## 组件职责 / Component Responsibilities

### 中文

- `Tokens.ets`：集中定义颜色、圆角、间距，减少硬编码颜色。
- `SearchBar.ets`：统一搜索框高度、背景、边框和 placeholder 颜色。
- `CategoryTabs.ets`：统一 chip 状态。
- `ClothingCard.ets`：衣物商品卡，负责图片、名称、分类标签。
- `OutfitCard.ets`：套装商品卡，负责封面、标题、件数 badge。
- `WishlistCard.ets`：心愿单电商列表卡，负责图片、标题、门店、价格。
- `MonthCalendar.ets`：日期选中态和记录态。
- 各页面：只组合组件和页面级布局，不复制组件内部视觉规则。

### English

- `Tokens.ets`: centralize colors, radius, and spacing, reducing hardcoded colors.
- `SearchBar.ets`: standardize search height, background, border, and placeholder color.
- `CategoryTabs.ets`: standardize chip states.
- `ClothingCard.ets`: clothing product card for image, name, and category label.
- `OutfitCard.ets`: outfit product card for cover, title, and item-count badge.
- `WishlistCard.ets`: ecommerce-style wishlist row for image, title, store, and price.
- `MonthCalendar.ets`: selected-date and recorded-date states.
- Pages: compose components and page-level layout only, avoiding duplicated component-level visual rules.

## 非目标 / Non-Goals

### 中文

- 不新增网络能力。
- 不新增权限。
- 不修改数据库、仓储或照片存储逻辑。
- 不实现 Figma 完整还原。
- 不引入新的 UI 框架或图标库。
- 不做暗色模式。
- 不改变业务流程和页面数量。

### English

- Do not add network capability.
- Do not add permissions.
- Do not modify database, repository, or photo storage logic.
- Do not attempt pixel-perfect Figma reproduction.
- Do not introduce a new UI framework or icon library.
- Do not add dark mode.
- Do not change business flows or the number of screens.

## 可访问性与可用性 / Accessibility And Usability

### 中文

- 主要文字与背景保持高对比。
- 关键按钮高度不小于 `40`，优先接近移动端 `44` 触达建议。
- 禁用态使用明确灰色，不能只降低透明度。
- 空态、加载态、错误态继续保留，颜色接入新 token。
- 页面不使用低对比大面积浅蓝文字。

### English

- Keep high contrast between main text and background.
- Key buttons should be at least `40` high, preferably close to the mobile `44` touch target recommendation.
- Disabled states use explicit muted colors, not opacity alone.
- Empty, loading, and error states remain and should use the refreshed tokens.
- Do not use low-contrast light-blue text for large content areas.

## 验证策略 / Verification Strategy

### 中文

实现阶段需要新增或更新一个 UI 主题验证脚本，至少检查：

- `Tokens.ets` 包含 `#4894FE` 和主要状态色。
- 页面和核心组件不再使用旧主色 `#0F766E`、`#115E59`、`#0F172A` 作为主按钮色。
- 核心组件使用 `AppTheme` token。
- `MonthCalendar` 使用蓝色选中/记录状态。
- 不新增网络 API 或权限。

完整验证：

- `for script in scripts/*.mjs; do node "$script"; done`
- `git diff --check`
- HarmonyOS HAP/App build
- 安装到模拟器后截图检查 Today、Wardrobe、Outfits、Calendar、Shopping 五个 tab 不白屏、无遮挡。

### English

Implementation should add or update a UI theme validation script that checks at least:

- `Tokens.ets` includes `#4894FE` and the main state colors.
- Pages and core components no longer use old primary colors `#0F766E`, `#115E59`, or `#0F172A` as primary button colors.
- Core components use `AppTheme` tokens.
- `MonthCalendar` uses blue selected/recorded states.
- No network APIs or permissions are added.

Full verification:

- `for script in scripts/*.mjs; do node "$script"; done`
- `git diff --check`
- HarmonyOS HAP/App build
- Install on the emulator and screenshot Today, Wardrobe, Outfits, Calendar, and Shopping tabs to confirm no white screen or overlap.

## 审批门禁 / Approval Gate

### 中文

本设计文档获批后，下一步进入 `superpowers` 的 Writing Plans 阶段：编写任务级实现计划，再按 TDD 执行代码改动。

### English

After this design is approved, the next step is the `superpowers` Writing Plans phase: write a task-level implementation plan, then execute code changes with TDD.
