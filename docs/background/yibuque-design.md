# 衣不缺 Rose VI Design Tokens And UI Rules

This document is the UI contract for `衣不缺`. It describes product scope, rose VI tokens, page rules, and interaction rules for HarmonyOS ArkUI implementation. Keep concrete token values centralized in `entry/src/main/ets/theme/Tokens.ets`.

## Product Direction

`衣不缺` is a local-first personal wardrobe and store-visit recording app. The core workflow is photo-first: the user taps the bottom camera, chooses `拍照` or `从相册选择`, then classifies the saved photo as `衣橱`、`美搭` or `店铺` and adds a short note if needed. The visual identity uses a soft rose base and deep rose (`深玫瑰`) primary action.

Keywords:

- Personal wardrobe
- Photo-first capture
- Clothes, outfits, stores
- Daily outfit calendar
- Local records
- Soft rose lifestyle utility
- Image-led cards
- Large rounded surfaces
- Lightweight forms

Avoid:

- Social-feed behavior such as likes, comments, follows, fake favorites.
- Shopping-cart, order, remote sync, or account assumptions.
- Main navigation concepts such as `首页`、`逛街`、`心愿单`.
- Asking the user to fill many required fields before a photo is saved.
- Large saturated pink blocks. Use rose as a refined accent, not a flat theme wash.

## Color Tokens

Use semantic roles rather than hardcoded colors in page code.

```ts
export const YibuqueColor = {
  bgDefault: '#FFF2F8',
  bgGray: '#F7D8E6',
  bgBlueGray: '#FBE1F0',
  bgHeaderBlue: '#F8D4EF',
  cardWhite: '#FFFFFE',
  cardBlue: '#F2DDFB',
  cardMint: '#FFE3EE',
  cardSoftGray: '#FFF6FA',
  textPrimary: '#391327',
  textSecondary: '#8A536B',
  textTertiary: '#B9879E',
  textDisabled: '#D0AFC0',
  textInverse: '#FFFFFF',
  actionBlack: '#B11B68',
  brandCyan: '#D83E8E',
  success: '#C53B88',
  successBg: '#FFEAF4',
  borderLight: '#F2C7DA',
  borderMedium: '#E7A3C4',
  borderStrong: '#8E1454',
  overlayDark: '#7A391327'
};
```

`actionBlack` is a compatibility token name. In the rose VI it means the deep rose primary action, not literal black.

### Color Usage

- Page default background: `bgDefault` or a soft rose gradient from `bgDefault` to `bgHeaderBlue`.
- Profile and quiet utility pages: `bgBlueGray`.
- Cards and form panels: `cardWhite`.
- Inputs and subtle blocks: `cardSoftGray`.
- Empty image placeholders: `cardBlue`, `cardMint`, or `cardSoftGray`.
- Primary headings and selected labels: `textPrimary`.
- Metadata and helper text: `textSecondary` or `textTertiary`.
- Primary CTA: `actionBlack` background with `textInverse`.
- Selected chip border: `borderStrong`; unselected chip border: `borderLight`.
- Error text can use a local danger red, but prefer one consistent red across pages.

## Typography Tokens

Use system Chinese sans fonts through platform defaults. Do not introduce a custom font.

```ts
export const YibuqueFontSize = {
  display: 36,
  pageTitle: 24,
  section: 22,
  cardTitle: 21,
  body: 16,
  meta: 14,
  caption: 12
};

export const YibuqueLineHeight = {
  display: 44,
  pageTitle: 32,
  section: 30,
  cardTitle: 29,
  body: 24,
  meta: 20,
  caption: 18
};
```

Rules:

- App name: 18 to 20, heavy, `textPrimary`.
- Page title: 24 to 28, heavy, `textPrimary`.
- Section title: 18 to 22, bold, `textPrimary`.
- Card title: 17 to 21, bold, `textPrimary`.
- Body: 15 to 16, regular or medium, `textSecondary`.
- Metadata: 12 to 14, `textTertiary` or `textSecondary`.
- Do not expose mixed debug labels such as `query:`, `entity_type`, `wornDate`, or `placeText` in user-facing UI.

## Spacing Tokens

```ts
export const YibuqueSpacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  section: 28,
  pageX: 20,
  cardX: 24,
  bottomSafe: 24
};
```

Rules:

- Page horizontal padding: 20 to 24.
- Card internal padding: 16 to 24.
- Main section gap: 20 to 32.
- Bottom controls reserve safe-area spacing.
- Keep forms lightweight; do not create dense back-office rows.

## Radius And Shadow

```ts
export const YibuqueRadius = {
  xs: 8,
  sm: 12,
  md: 16,
  lg: 20,
  xl: 24,
  xxl: 28,
  xxxl: 32,
  sheet: 36,
  full: 999
};

export const YibuqueShadow = {
  card: { radius: 28, color: '#1FD83E8E', offsetX: 0, offsetY: 10 },
  soft: { radius: 22, color: '#18B11B68', offsetX: 0, offsetY: 8 },
  floating: { radius: 32, color: '#2AB11B68', offsetX: 0, offsetY: 14 }
};
```

Rules:

- Primary buttons, chips and segmented tabs: `full`.
- Input fields: 16 to 20.
- Image thumbnails: 20 to 28.
- Content cards: 24 to 32.
- Bottom sheets: `sheet`.
- Shadows must be light and rose-tinted; avoid heavy ecommerce card shadows.

## Component Rules

### App Top Bar

- Height about 56.
- Left: app logo mark plus `衣不缺`.
- Right: avatar / `我的` entry.
- Tappable areas at least 44.
- Press feedback can use slight scale or opacity.

### Bottom Navigation

Primary navigation contains only:

- `衣橱`
- Center camera action
- `逛店`

Rules:

- Center action must communicate camera/photo capture, not a generic text plus.
- Active state uses color, font weight and shape.
- Keep bottom safe-area padding.

### Quick Capture Sheet

Actions:

- `拍照`
- `从相册选择`

Rules:

- The sheet does not contain type-specific capture labels.
- Classification happens after the photo is chosen, inside `CaptureEditPage`.
- Rows or buttons should be large, at least 56 to 64 high.
- Parent flow must prevent duplicate capture while loading.

### Capture Edit Page

Rules:

- Required: photo.
- Core input: `小记` as a multiline text area.
- Type tabs: `衣橱`、`美搭`、`店铺`.
- All structured fields are optional.
- `衣橱`: generate a clothing name from category and capture time.
- `美搭`: generate a title and allow optional clothing links and optional calendar sync.
- `店铺`: generate a store visit name and allow optional address/date.
- Save routes back to the corresponding main tab.

### Cards

Base card:

- `cardWhite` background.
- Radius 24 to 32.
- Use `YibuqueShadow.card` or a very light border.
- Image or placeholder should be the dominant visual.
- Image corners must be rounded.

Clothing card:

- Large image area.
- Name in bold `textPrimary`.
- Category as a small rose pill.
- Missing image uses a soft rose placeholder.

Outfit card:

- Use `美搭` / `搭配` wording.
- Photo cover if available.
- Linked clothing count is metadata, not a loud badge.

Store visit card:

- Title is store name or generated visit name.
- Metadata: date and address/district.
- Note preview max 2 lines.
- Missing image uses a soft `店` placeholder.

### Forms

- Do not rely on placeholder as the only label for important fields.
- Group secondary fields under `选填信息`.
- Save buttons show loading and disable duplicate taps.
- Error copy explains what to fix.
- Empty states invite a specific action through the bottom camera.

## Page Rules

### 衣橱

Structure:

```text
Top bar
Search / summary
[衣橱] [美搭] [日历]
Content
Bottom nav
```

Rules:

- `衣橱` manages clothing items.
- `美搭` manages outfit records.
- `日历` records daily outfits by date.
- Empty states reference the bottom camera, not type-specific pre-photo actions.

### 逛店

Structure:

```text
Top bar
逛店
Search / summary
Store visit records
Bottom nav
```

Rules:

- Records are more important than store master data.
- The main create path is bottom camera -> photo source -> `店铺`.
- The page may keep edit affordances for existing visits, but should not show a competing primary capture path.

### 我的

Rules:

- Local-only profile.
- Fields: height, weight, waist.
- Use large avatar placeholder, white cards, rose buttons, and soft background.
- Settings may be a visual placeholder in the first version.

### Search

Search result labels:

- `衣物`
- `美搭`
- `逛店记录`
- `店铺`

Rules:

- Do not expose internal IDs or debug entity labels.
- Do not expose wishlist as a primary product concept.

## Interaction Rules

- Tappable controls should be at least 44x44.
- Selection state must not rely on color alone.
- Use direct photo-first create flows.
- Async save buttons must prevent duplicate taps.
- Empty/loading/error states must be visible and written in user language.
- Motion should be subtle: sheet translate/opacity, press scale, small hero entrance.

## Implementation Notes For ArkUI

- Keep tokens in `entry/src/main/ets/theme/Tokens.ets`.
- Prefer `YibuqueColor`, `YibuqueRadius`, `YibuqueSpacing`, and `YibuqueShadow` in active pages/components.
- `AppTheme` may remain for compatibility, but active `衣不缺` surfaces should not depend on old primary styling.
- Do not add third-party UI libraries.
- For arrays passed through props or router params, clone before assigning to state.
- Store photos in app-local files only; SQLite stores URI/path strings.

## Validation Checklist

Before shipping a screen:

- The screen uses rose VI tokens or mapped compatibility tokens.
- Primary action is deep rose pill style.
- Main cards and images have large rounded corners.
- Empty states point to the bottom camera.
- Photo-first flow is `拍照 / 从相册选择` before classification.
- User-facing text does not contain old social, wishlist, or debug concepts.
- `衣橱`、`美搭`、`店铺` records save locally and re-open with persisted data.
