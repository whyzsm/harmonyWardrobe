# 衣不缺 Design Tokens And UI Rules

Source: extracted from the shared ChatGPT design-token conversation on 2026-07-04, then adapted for the `衣不缺` personal wardrobe app.

This document is the UI contract for new pages and refactors. It is not an implementation plan. Prefer the existing HarmonyOS ArkUI stack and keep tokens centralized in `entry/src/main/ets/theme/Tokens.ets` when implementing.

## Product Direction

`衣不缺` is a personal wardrobe and store-visit recording app. The interface should feel like a calm lifestyle tool: light, tactile, image-led, and easy to operate on mobile.

Keywords:

- Personal wardrobe
- Soft lifestyle utility
- Large rounded cards
- Low-saturation backgrounds
- Strong black titles
- Black primary actions
- Light shadows
- Emotional photos
- Spacious mobile layout

Avoid:

- Social-feed behavior such as likes, comments, follows, fake favorites.
- Dense back-office layouts.
- Heavy shadows and hard borders.
- Highly saturated large color blocks.
- Turning every action blue. Blue and mint are supporting background/status colors; black is the primary action color.

## Color Tokens

Use these semantic roles rather than hardcoded colors in page code.

```ts
export interface YibuqueColorTokens {
  bgDefault: string;
  bgGray: string;
  bgBlueGray: string;
  bgHeaderBlue: string;
  cardWhite: string;
  cardBlue: string;
  cardMint: string;
  cardSoftGray: string;
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  textDisabled: string;
  textInverse: string;
  actionBlack: string;
  brandCyan: string;
  success: string;
  successBg: string;
  borderLight: string;
  borderMedium: string;
  borderStrong: string;
  overlayDark: string;
}

export const YibuqueColor: YibuqueColorTokens = {
  bgDefault: '#FFFFFF',
  bgGray: '#EFEFEF',
  bgBlueGray: '#F6FAFD',
  bgHeaderBlue: '#E1F1FF',
  cardWhite: '#FFFFFF',
  cardBlue: '#E1F3FF',
  cardMint: '#DCFDF6',
  cardSoftGray: '#F6F6F6',
  textPrimary: '#0A0A0A',
  textSecondary: '#5F6870',
  textTertiary: '#9CA3AA',
  textDisabled: '#C8CDD2',
  textInverse: '#FFFFFF',
  actionBlack: '#000000',
  brandCyan: '#24BFE8',
  success: '#43D991',
  successBg: '#EFFFF7',
  borderLight: '#E9ECEF',
  borderMedium: '#D8DDE2',
  borderStrong: '#111111',
  overlayDark: '#73000000'
};
```

### Color Usage

- Page default background: `bgDefault`.
- Profile and quiet utility pages: `bgBlueGray`.
- Empty image placeholders: `cardBlue`, `cardMint`, or `cardSoftGray`.
- Primary headings and selected labels: `textPrimary`.
- Metadata and helper text: `textSecondary` or `textTertiary`.
- Primary CTA: `actionBlack` background with `textInverse`.
- Success status: `success` on `successBg`.
- Borders: `borderLight` by default, `borderStrong` only for selected chips or outline buttons.

## Typography Tokens

Use system Chinese sans fonts through platform defaults. Do not introduce a custom web font.

```ts
export interface YibuqueFontSizeTokens {
  display: number;
  pageTitle: number;
  section: number;
  cardTitle: number;
  body: number;
  meta: number;
  caption: number;
}

export const YibuqueFontSize: YibuqueFontSizeTokens = {
  display: 36,
  pageTitle: 24,
  section: 22,
  cardTitle: 21,
  body: 16,
  meta: 14,
  caption: 12
};

export interface YibuqueLineHeightTokens {
  display: number;
  pageTitle: number;
  section: number;
  cardTitle: number;
  body: number;
  meta: number;
  caption: number;
}

export const YibuqueLineHeight: YibuqueLineHeightTokens = {
  display: 44,
  pageTitle: 32,
  section: 30,
  cardTitle: 29,
  body: 24,
  meta: 20,
  caption: 18
};
```

### Typography Usage

- App name: 18 to 20, heavy, `textPrimary`.
- Page title: 24, heavy, `textPrimary`.
- Section title: 22, heavy, usually `textTertiary`.
- Card title: 18 to 21, heavy or bold, `textPrimary`.
- Body: 16, regular or medium, `textSecondary`.
- Metadata: 14, medium or bold, `textTertiary`.
- Caption/chip: 12, bold for status; regular for secondary labels.

Rules:

- Main titles must be black and visually strong.
- Do not use thin or low-contrast headings.
- Avoid excessive mixed English/Chinese debug labels in user-facing UI.

## Spacing Tokens

```ts
export interface YibuqueSpacingTokens {
  xxs: number;
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  xxl: number;
  section: number;
  pageX: number;
  cardX: number;
  bottomSafe: number;
}

export const YibuqueSpacing: YibuqueSpacingTokens = {
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

### Layout Rules

- Page horizontal padding: 20 to 24.
- Card internal padding: 20 to 28.
- Section gap: 28 to 40.
- Card vertical gap: 20 to 28.
- Bottom controls must reserve safe-area spacing.
- Keep mobile screens spacious. Do not compress controls into dense dashboard rows.

## Radius Tokens

```ts
export interface YibuqueRadiusTokens {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  xxl: number;
  xxxl: number;
  sheet: number;
  full: number;
}

export const YibuqueRadius: YibuqueRadiusTokens = {
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
```

### Radius Usage

- Primary and secondary pill buttons: `full`.
- Chips and segmented tabs: `full`.
- Small thumbnails: 16 to 20.
- Main image cards: 24 to 32.
- Large content cards: 28 to 32.
- Bottom sheets and modal sheets: top radius 32 to 36.
- Profile menu cards: 28.

## Shadow Tokens

Use very light shadows. Shadows should separate surfaces without making cards feel like ecommerce tiles.

```ts
export interface YibuqueShadowTokens {
  card: ShadowOptions;
  soft: ShadowOptions;
  floating: ShadowOptions;
}

export const YibuqueShadow: YibuqueShadowTokens = {
  card: { radius: 24, color: '#0A000000', offsetX: 0, offsetY: 8 },
  soft: { radius: 18, color: '#0D000000', offsetX: 0, offsetY: 6 },
  floating: { radius: 28, color: '#14000000', offsetX: 0, offsetY: 10 }
};
```

## Component Rules

### App Top Bar

Use on primary app surfaces.

- Height: about 56.
- Horizontal padding: 20.
- Left: logo mark plus `衣不缺`.
- App name: black, heavy, 18 to 20.
- Right: avatar / `我的` entry, 44 to 48 hit target.
- Icons: black linear style, 24 to 28, stroke around 2 to 2.5.

### Bottom Navigation

Primary nav contains only:

- `衣橱`
- Center `+`
- `逛店`

Rules:

- Active label/icon: black.
- Inactive label/icon: light gray.
- Center `+`: black rounded square or capsule, white plus.
- Hit target: at least 44 high.
- Keep bottom safe-area padding.

### Quick Capture Sheet

Actions:

- `拍衣服`
- `拍搭配`
- `拍店铺`

Rules:

- Use a white sheet with top radius 32 to 36.
- Each action should be a large row or pill, not a small text button.
- The first or most common action can use black primary style.
- Keep labels concrete: tapping an item should clearly enter that creation flow.

### Primary Button

```text
height: 56
paddingX: 22
radius: full
background: actionBlack
text: textInverse
fontSize: 17
fontWeight: heavy
```

Use for save, primary create, confirm, and key floating actions.

### Secondary Outline Button

```text
height: 48 to 50
paddingX: 24 to 28
radius: full
border: 2 solid borderStrong
background: transparent or white
text: actionBlack
fontSize: 17 to 18
fontWeight: heavy
```

Use for edit profile, alternate actions, and non-destructive secondary commands.

### Segmented Tabs And Chips

Selected:

- White background.
- 2px black border.
- Black text.
- Bold label.
- Pill radius.

Unselected:

- White background.
- 1px `borderLight`.
- `textTertiary`.
- Pill radius.

Use for:

- `衣裤 / 美搭`.
- Clothing category filters.
- Store-visit filters if added.

### Cards

Base card:

- Background: `cardWhite`.
- Radius: 24 to 32.
- Shadow: `card` or none.
- Border: avoid by default; use only very light border when the card is on pure white.
- Overflow hidden when containing images.

Image-led cards:

- Image should be the dominant visual.
- Image must have rounded corners.
- Avoid square image corners.
- Use placeholder blocks from `cardBlue`, `cardMint`, or `cardSoftGray` when no image exists.

### Clothing Cards

For `衣橱 / 衣裤`:

- White card with large image area.
- Image radius: 20 to 28.
- Name: black, bold.
- Category: small pill label.
- Metadata and purchase notes: secondary gray.
- Empty image state: soft blue or mint placeholder, not a hard icon-only box.

### Outfit Cards

For `衣橱 / 美搭`:

- Prefer image-first card.
- If photo exists, use it as cover.
- If no photo exists, use soft blue/mint placeholder.
- Title uses black bold.
- Show linked clothing count as metadata, not a loud badge.
- UI copy should say `美搭` or `搭配`, not `套装`.

### Store Visit Cards

For `逛店`:

- Main title: store name, black and bold.
- Metadata: date, address/district, gray.
- Cover photo optional; if present, make it rounded and prominent.
- Note preview max 2 lines.
- Empty image state can use `店` text on a soft background.

### Profile Page

Background: `bgBlueGray`.

Rules:

- Large avatar placeholder, about 112 diameter, light gray with soft shadow.
- Profile name/heading: 28, heavy, black.
- Edit/profile action: black outline pill.
- Measurement fields should live in white large-radius cards.
- Menu card: white, radius 28, menu row height about 74.
- Row text: about 20, medium, `#4A4A4A` if using raw color, otherwise `textSecondary`.
- Dividers: very light, `#F0F0F0` or `borderLight`.

## Page Rules For 衣不缺

### 衣橱

Structure:

```text
Top bar
衣橱
[衣裤] [美搭]
content
Bottom nav
```

Rules:

- `衣裤` manages clothing items.
- `美搭` manages outfits/looks.
- Keep categories visible but not visually louder than content.
- Empty states should point to the center `+` action.

### 逛店

Structure:

```text
Top bar
逛店
Store visit list
Bottom nav
```

Rules:

- Records are more important than store master data.
- `拍店铺` creates a store visit record.
- Store creation can happen inside the visit flow.
- Do not present this as wishlist or shopping cart.

### 我的

Structure:

```text
Top bar or back bar
Avatar/profile block
Measurements
Settings
```

Rules:

- The first version only needs height, weight, and waist.
- No online account assumptions.
- Settings can be a placeholder entry if no settings are implemented yet.

## Interaction Rules

- All tappable controls should have at least a 44x44 hit target.
- Async save buttons must show loading and prevent duplicate taps.
- Form errors should appear near the field or save area.
- Error copy should explain what to fix.
- Empty states should invite a specific action.
- Selection state must not rely on color alone; use border/weight/shape too.
- Prefer direct create/edit flows over hidden menus.

## Accessibility Rules

- Body text should target 4.5:1 contrast.
- Large title text should target at least 3:1 contrast.
- Icon-only buttons need a text label or equivalent semantic name.
- Do not use placeholder as the only form label.
- Focus/selected states need visible shape differences.
- Images used as content need meaningful fallback text in surrounding UI.

## Motion Rules

Use motion sparingly:

- Sheet open/close: translate + opacity.
- Button press: small scale or opacity feedback.
- Tab switch: instant or short opacity transition.
- Avoid decorative or ambient motion.
- Respect reduced-motion settings when available.

## Implementation Notes For ArkUI

- Keep tokens in `entry/src/main/ets/theme/Tokens.ets`.
- Use semantic token names instead of page-specific names.
- Prefer shared components for top bar, bottom nav, quick sheet, cards, and empty states.
- Do not add a third-party UI library for this visual system.
- Existing blue tokens can stay for compatibility, but new primary actions should use black.

## Validation Checklist

Before shipping a screen:

- The page has enough whitespace and does not feel dense.
- Primary title is black, bold, and obvious.
- Main cards use large radius.
- Images have rounded corners.
- Shadows are very light or absent.
- Primary action is black pill style.
- Chips/tabs have clear selected and unselected states.
- Empty/loading/error states exist.
- Touch targets are at least 44 high.
- User-facing text does not contain debug labels or old concepts like social metrics.
