# 衣不缺现代轻量设计规范 / Yibuque Modern Lightweight Design System

## 产品方向 / Product Direction

`衣不缺` 是一款本地优先、图片优先的个人衣柜与逛店记录应用。核心流程是点击底部相机，从“穿搭 / 逛店 / 衣柜”中选择新增目标；直接进入对应新增页面后，仍可通过拍照或相册选择添加记录。

`Yibuque` is a local-first, image-first personal wardrobe and store-visit app. The primary flow starts from the bottom camera, opens a `穿搭 / 逛店 / 衣柜` create destination, and keeps camera or gallery capture available inside the relevant create page.

视觉方向采用轻量白底、浅灰表面、黑色正文、蓝色选中强调和黑色主操作。页面应以真实照片为主要内容，保持低文字密度、清晰层级和安静的工具感。

The visual direction uses white backgrounds, light-gray surfaces, black text, blue selection accents, and black primary actions. Real photos remain the primary content, with low text density, clear hierarchy, and a quiet utility-oriented feel.

禁止使用旧 Rose VI 的粉色背景、粉色主按钮、粉色阴影或粉色边框。禁止虚构网络同步、预算、商场或用户记录。

Do not use the legacy Rose VI pink backgrounds, primary buttons, shadows, or borders. Do not invent remote sync, budget, mall, or user-record data.

## 颜色令牌 / Color Tokens

页面代码应使用语义 token，不要重新引入零散粉色值。

Page code must use semantic tokens and must not reintroduce isolated pink values.

```ts
export const YibuqueColor = {
  bgDefault: '#FFFFFF',
  bgGray: '#F5F5F7',
  bgBlueGray: '#FFFFFF',
  bgHeaderBlue: '#F5F5F7',
  cardWhite: '#FFFFFF',
  cardBlue: '#F2F2F7',
  cardMint: '#F5F5F7',
  cardSoftGray: '#FBFBFD',
  textPrimary: '#1D1D1F',
  textSecondary: '#6E6E73',
  textTertiary: '#86868B',
  textDisabled: '#B8B8BD',
  textInverse: '#FFFFFF',
  actionBlack: '#1D1D1F',
  selectionAccent: '#0071E3',
  selectionAccentSurface: '#EAF3FE',
  brandCyan: '#1D1D1F',
  success: '#16A34A',
  successBg: '#ECFDF3',
  borderLight: '#E8E8ED',
  borderMedium: '#D2D2D7',
  borderStrong: '#1D1D1F',
  overlayDark: '#7A1D1D1F'
};
```

`actionBlack` 是接近黑色的主操作色；`selectionAccent` 和 `selectionAccentSurface` 用于选中筛选项、选中标签、选中模式和链接强调。`brandCyan` 是兼容名称，当前不再使用。

`actionBlack` is the near-black primary action color. `selectionAccent` and `selectionAccentSurface` are used for selected filters, selected tags, selected modes, and link emphasis. `brandCyan` is retained only as a compatibility name and is not used.

### 使用规则 / Usage Rules

- 页面背景使用 `bgDefault`；次级区域使用 `bgGray` 或 `cardSoftGray`。
- Use `bgDefault` for page backgrounds and `bgGray` or `cardSoftGray` for secondary surfaces.
- 主标题使用 `textPrimary`；说明和元信息使用 `textSecondary`、`textTertiary`。
- Use `textPrimary` for headings and `textSecondary` or `textTertiary` for descriptions and metadata.
- 保存、删除、重试、主卡片以及衣柜/逛店列表的主筛选 Tab 使用 `actionBlack`；其它选中态、筛选态和链接使用 `selectionAccent` 及 `selectionAccentSurface`。
- Use `actionBlack` for save, delete, retry, primary cards, and the main wardrobe/store filter tabs. Use `selectionAccent` and `selectionAccentSurface` for other selected, filtered, and link states.
- 普通边框使用 `borderLight` 或 `borderMedium`；强选中边框使用 `selectionAccent`。
- Use `borderLight` or `borderMedium` for regular borders. Strong selected borders use `selectionAccent`.

## 字体与密度 / Typography And Density

使用系统中文无衬线字体，不引入自定义字体。页面标题 24-28，区块标题 18-21，正文 14-17，元信息 11-13。

Use the platform Chinese sans-serif font. Page titles are 24-28, section titles 18-21, body text 14-17, and metadata 11-13.

图片优先页面保持低文字密度。表单标题必须清晰，不能只依赖 placeholder 表达字段含义。

Image-first pages should keep text density low. Form labels must remain clear and must not rely only on placeholders.

## 间距、圆角与阴影 / Spacing, Radius, And Shadow

- 页面水平边距：20。
- Page horizontal padding: 20.
- 常规区块间距：14-20。
- Standard section gap: 14-20.
- 搜索和输入控件高度：48，圆角 12。
- Search and input controls: 48 high with 12 radius.
- 图片圆角：5。
- Image radius: 5.
- 内容卡片圆角：12-18。
- Content card radius: 12-18.
- 胶囊按钮圆角：999。
- Pill controls use a radius of 999.
- 阴影必须为中性黑色透明阴影，不使用彩色阴影。
- Shadows must use translucent neutral black, never tinted color shadows.

## 共享组件 / Shared Components

### 顶部导航 / Top Navigation

顶部导航使用白色半透明或纯白背景、浅灰底边和系统图标。不得使用粉色渐变。

Top navigation uses a white or translucent white background, a soft gray divider, and system icons. Pink gradients are forbidden.

### 底部导航 / Bottom Navigation

底部导航为宽度 90% 的黑色半透明悬浮胶囊，依次包含穿搭、衣柜、相机、逛街、我的。中间相机保留 `d8daa86` 的橙-蓝-青蓝三段彩色圆形图标，不显示“拍照”文字；它是本规范中唯一允许保留彩色渐变的操作入口。

应用冷启动默认进入“穿搭”页，并高亮底部“穿搭”入口。

The bottom navigation is a 90%-wide translucent black floating capsule with outfit, wardrobe, camera, shopping, and profile entries, in that order. Keep the `d8daa86` orange-blue-cyan gradient camera icon without a `拍照` label; it is the only action in this system allowed to retain a multicolor gradient.

The app opens the Outfits page by default on a cold start and highlights the Outfits entry in the bottom navigation.

### 快捷录入 / Quick Capture Sheet

快捷录入弹层使用白色贴底面板、顶部圆角、灰色遮罩和中性阴影；面板底部必须贴到屏幕底部，不能悬浮露出遮罩。标题为“快捷录入”，右侧“取消”使用蓝色强调色。

三个入口从上到下依次为“穿搭 / 逛店 / 衣柜”。

The quick capture sheet uses a white bottom-attached panel, rounded top corners, a gray scrim, and a neutral shadow; the panel must reach the bottom edge instead of floating above the scrim. Its title is `快捷录入`, with a blue `取消` action.

The three actions appear from top to bottom as `Outfit / Store Visit / Wardrobe`.

- “穿搭”：白色描边卡片、浅蓝图标底板和蓝色衣架图标。
- `穿搭`: white outlined card with a light-blue icon surface and a blue hanger icon.
- “逛店”：白色描边卡片、浅蓝图标底板和蓝色店铺图标。
- `逛店`: white outlined card with a light-blue icon surface and a blue store icon.
- “衣柜”：黑色主卡片、深灰图标底板和白色衣物系统图标。
- `衣柜`: black primary card with a dark-gray icon surface and a white shirt system icon.

### 卡片与空态 / Cards And Empty States

卡片使用白色或 `cardSoftGray`，配浅灰边框。真实图片优先；缺图时使用中性占位，不得把设计示例冒充用户数据。

Cards use white or `cardSoftGray` with soft gray borders. Prefer real images. Missing images use neutral placeholders, and design examples must never be presented as user data.

长按衣柜、穿搭或逛店主列表的卡片图片后，图片上显示半透明深色蒙层和居中的红色删除按钮；松手后蒙层继续保留，点击蒙层空白处可关闭。点击删除按钮后必须二次确认。短按仍进入详情，详情页保留可见删除入口，统一搜索结果不提供长按删除。

Long-pressing a card image in the main wardrobe, outfit, or store-visit list shows a translucent dark image overlay with a centered red delete button. The overlay remains after release and closes when its empty area is tapped. The delete button opens destructive confirmation. A regular tap still opens details, visible delete actions remain available on detail pages, and unified search results do not expose long-press deletion.

空态必须说明下一步动作；需要 CTA 时使用黑色，不使用蓝色或粉色。

Empty states must explain the next action. When a CTA is needed, use black rather than blue or pink.

## 页面规则 / Page Rules

### 衣柜 / Wardrobe

保留搜索、分类和双列瀑布流。真实照片占主要面积，图片圆角为 5，衣物卡片不提供收藏按钮或社交动作。

Keep search, categories, and the two-column waterfall. Real photos dominate, image radius is 5, and clothing cards do not provide favorite buttons or social actions.

### 穿搭 / Outfits

使用本地自定义分类筛选、真实衣物数量引导和双列瀑布穿搭墙。`全部` 是唯一固定筛选，未分类穿搭也显示在其中；`周末 / 通勤` 是可删除的初始分类，不提供默认 `逛店` 分类。每张穿搭卡可显示两张组合图片，标题与元信息保持紧凑。

新增穿搭默认选中 `通勤`；新增或编辑时可以多选已有分类，并可手动输入一个额外分类。手动输入的分类必须与穿搭在同一个 SQLite 事务中成功保存后才进入分类列表。已保存分类的删除入口直接显示在编辑页分类胶囊右侧，使用与常逛商圈标签一致的 `×`，不提供独立分类管理弹层。删除前必须二次确认；删除分类不删除穿搭或照片，只移除对应分类关联，相关穿搭继续显示在 `全部` 中。

穿搭详情主图点击后进入全屏等比预览；多图支持左右滑动，并显示当前序号和关闭操作，与衣柜详情保持一致。

Use local custom-category filters, real wardrobe-count guidance, and a two-column waterfall outfit wall. `All` is the only fixed filter and also contains uncategorized outfits. `Weekend / Commute` are removable starter categories, with no default shopping category. Each outfit card may show two combined photos with compact title and metadata.

New outfits select `Commute` by default. When creating or editing, users can select multiple saved categories and enter one additional category manually. A manually entered category joins the category list only after it and the outfit are committed in the same SQLite transaction. Saved categories expose an inline `x` on their editor chips, matching the frequent-district tag position, with no separate category manager sheet. Deletion requires confirmation, keeps outfits and photos, removes only the matching category relation, and leaves the outfits visible under `All`.

Tapping the hero image on an outfit detail opens a full-screen contain preview. Multiple images support horizontal swiping with a position counter and close action, matching wardrobe details.

### 拍照录入 / Capture

使用单品、试穿、吊牌模式，大图预览、识别提示、分类、名称和备注。保存流程必须继续写入本地 repository。

Use item, try-on, and tag modes with a large preview, recognition badge, category, name, and note. Saving must continue through local repositories.

### 逛店 / Store Visits

使用搜索、状态筛选、路线卡和双列图片墙。loading、empty、error 和重试状态必须保留。

逛店详情主图点击后进入全屏等比预览；多图支持左右滑动，并显示当前序号和关闭操作，与衣柜和穿搭详情保持一致。

Use search, status filters, a route card, and a two-column photo wall. Preserve loading, empty, error, and retry states.

Tapping the store-visit detail hero image opens a full-screen contain preview. Multiple images support horizontal swiping with a position counter and close action, matching wardrobe and outfit details.

### 我的 / Profile

使用真实衣柜图片、真实单品数量和本地个人数据。未配置预算或商场时必须显示未设置状态，不得虚构记录。

Use real wardrobe photos, real item counts, and local profile data. Show unset states for budget or malls when unavailable; do not invent records.

偏好检查列表中的常用尺码和常逛商圈图标使用 `iconAccent` 蓝色，并放在 `iconAccentSurface` 浅蓝色底上；文字和操作按钮仍使用黑灰色。

Preference-check icons for size, fitting preference, and frequent districts use the blue `iconAccent` token on the light `iconAccentSurface`; text and action buttons remain black and gray.

### 编辑与搜索页 / Editors And Search

所有编辑页、搜索结果、穿着记录、选择器和空态必须继承相同白灰黑 token。保存按钮和选中态统一使用黑色，错误使用统一红色。

All editors, search results, wear-log surfaces, pickers, and empty states inherit the same white-gray-black tokens. Save buttons and selected states use black, while errors use one consistent red.

## 交互与数据真实性 / Interaction And Data Integrity

- 可点击区域至少 44x44。
- Tap targets are at least 44x44.
- 保存期间禁用重复提交并显示 loading。
- Disable duplicate submissions and show loading while saving.
- 所有业务数据以本地 SQLite 和本地图片 URI 为准。
- Local SQLite and local photo URIs are the source of truth.
- 不增加网络权限，不显示不存在的远程同步能力。
- Do not add network permissions or display nonexistent remote sync behavior.
- 验收必须包含全量脚本、ArkTS 构建和设备截图。
- Acceptance requires all validation scripts, an ArkTS build, and device screenshots.
