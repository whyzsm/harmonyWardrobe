# Xiaohongshu Home And Wardrobe Navigation Design

## 中文

目标是把当前偏管理工具式的首页和底部导航，改成更接近小红书发现流的移动端体验，同时保留现有衣橱、穿搭、日历、逛街业务能力。

## English

The goal is to move the current management-style home screen and bottom navigation toward a Xiaohongshu-like discovery feed experience while preserving the existing wardrobe, outfit, calendar, and shopping capabilities.

## 中文

底部导航使用 `首页 / 衣橱 / + / 日历 / 逛街`。`今日` 改名为 `首页`，`衣橱` 保留为普通 tab，`穿搭` 不再作为底部 tab 出现。中间凸起的 `+` 是快捷操作入口，点击后打开快捷面板，包含 `添加衣服`、`创建穿搭`、`记录今日`。

## English

The bottom navigation uses `首页 / 衣橱 / + / 日历 / 逛街`. `今日` is renamed to `首页`, `衣橱` remains a regular tab, and `穿搭` is no longer shown as a bottom tab. The raised center `+` is a quick action entry. Tapping it opens a quick action sheet with `添加衣服`, `创建穿搭`, and `记录今日`.

## 中文

首页采用轻量顶部导航和双列内容流。顶部左侧显示日期或轻量入口，中间显示 `推荐 / 今日 / 灵感`，当前频道用 `#4894FE` 下划线强调，右侧显示搜索入口。主体以双列瀑布流展示今日穿搭、最近穿搭和最近记录。空态不再使用大块管理卡片，而是使用内容流占位卡。

## English

The home page uses a lightweight top bar and a two-column content feed. The left side shows the date or a lightweight entry, the center shows `推荐 / 今日 / 灵感`, the selected channel is emphasized with a `#4894FE` underline, and the right side shows a search entry. The body presents today’s outfit, recent outfits, and recent wear logs in a two-column masonry-style feed. Empty states use feed placeholder cards instead of large management cards.

## 中文

衣橱页保持“我的衣橱内容流”。顶部显示 `衣橱` 和弱化的 `添加衣服` 按钮；搜索栏保留但使用浅灰圆角搜索框；分类 chips 横向呈现 `全部 / 上衣 / 裤装 / 裙装 / 外套 / 鞋包 / 配饰`。衣物列表继续双列展示，但卡片去掉厚边框，改成白底、轻阴影、图片主导。空态提示用户点中间 `+` 添加第一件衣服。

## English

The wardrobe page remains “my wardrobe feed.” The top shows `衣橱` and a softened `添加衣服` button. The search bar stays but uses a light gray rounded style. Category chips remain horizontal with `全部 / 上衣 / 裤装 / 裙装 / 外套 / 鞋包 / 配饰`. Clothing items stay in a two-column layout, but cards remove heavy borders and become image-led white cards with subtle shadow. The empty state tells users to tap the center `+` to add the first clothing item.

## 中文

视觉规范保持主色 `#4894FE`，背景使用 `#F6F8FC` 或接近小红书的浅灰白。卡片图片圆角为 8，卡片整体圆角为 8 到 12。底部栏为白底、顶部细分割线，中间 `+` 使用主色、白色加号、圆角胶囊形态，尺寸约 `56x48`。

## English

The visual system keeps `#4894FE` as the primary color and uses `#F6F8FC` or a Xiaohongshu-like off-white background. Image corners use radius 8, and card corners use radius 8 to 12. The bottom bar uses a white background with a thin top divider, and the center `+` uses the primary color, a white plus sign, a rounded capsule shape, and an approximate size of `56x48`.

## 中文

实现边界：本轮只做 UI 和导航改版，不改数据库、不改 `PhotoStorage`、不改业务模型、不新增网络 API、不新增权限、不引入新组件库。优先复用 `TodayPage`、`WardrobePage`、`ClothingCard`、`OutfitCard` 和 `AppTheme`。

## English

Scope boundary: this pass only changes UI and navigation. It does not change the database, `PhotoStorage`, business models, network APIs, permissions, or third-party UI libraries. It should primarily reuse `TodayPage`, `WardrobePage`, `ClothingCard`, `OutfitCard`, and `AppTheme`.
