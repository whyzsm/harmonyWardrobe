export interface AppThemeColorTokens {
  primary: string;
  primaryStrong: string;
  primaryPressed: string;
  primarySoft: string;
  surface: string;
  surfaceRaised: string;
  surfaceMuted: string;
  border: string;
  text: string;
  textMuted: string;
  textDisabled: string;
  success: string;
  warning: string;
  danger: string;
  accent: string;
  disabled: string;
}

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

export interface YibuqueFontSizeTokens {
  display: number;
  pageTitle: number;
  section: number;
  cardTitle: number;
  body: number;
  meta: number;
  caption: number;
}

export interface YibuqueLineHeightTokens {
  display: number;
  pageTitle: number;
  section: number;
  cardTitle: number;
  body: number;
  meta: number;
  caption: number;
}

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

export interface YibuqueShadowTokens {
  card: ShadowOptions;
  soft: ShadowOptions;
  floating: ShadowOptions;
}

export interface AppThemeRadiusTokens {
  sm: number;
  md: number;
  lg: number;
}

export interface AppThemeSpacingTokens {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

export interface AppThemeTokens {
  color: AppThemeColorTokens;
  radius: AppThemeRadiusTokens;
  spacing: AppThemeSpacingTokens;
}

export const AppTheme: AppThemeTokens = {
  color: {
    primary: '#B11B68',
    primaryStrong: '#8E1454',
    primaryPressed: '#7A1048',
    primarySoft: '#FCE3EF',
    surface: '#FFFFFF',
    surfaceRaised: '#FFF7FB',
    surfaceMuted: '#FDE7F2',
    border: '#F1C1D8',
    text: '#381528',
    textMuted: '#8B5D73',
    textDisabled: '#C9A8B8',
    success: '#C53B88',
    warning: '#FFB020',
    danger: '#D94870',
    accent: '#E85D9E',
    disabled: '#C9A8B8'
  },
  radius: {
    sm: 6,
    md: 8,
    lg: 12
  },
  spacing: {
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 20
  }
};

export const YibuqueColor: YibuqueColorTokens = {
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

export const YibuqueFontSize: YibuqueFontSizeTokens = {
  display: 36,
  pageTitle: 24,
  section: 22,
  cardTitle: 21,
  body: 16,
  meta: 14,
  caption: 12
};

export const YibuqueLineHeight: YibuqueLineHeightTokens = {
  display: 44,
  pageTitle: 32,
  section: 30,
  cardTitle: 29,
  body: 24,
  meta: 20,
  caption: 18
};

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

export const YibuqueShadow: YibuqueShadowTokens = {
  card: { radius: 28, color: '#1FD83E8E', offsetX: 0, offsetY: 10 },
  soft: { radius: 22, color: '#18B11B68', offsetX: 0, offsetY: 8 },
  floating: { radius: 32, color: '#2AB11B68', offsetX: 0, offsetY: 14 }
};
