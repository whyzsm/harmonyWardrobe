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
    primary: '#4894FE',
    primaryStrong: '#246BFE',
    primaryPressed: '#246BFE',
    primarySoft: '#EAF3FF',
    surface: '#FFFFFF',
    surfaceRaised: '#FFFFFF',
    surfaceMuted: '#F6F8FC',
    border: '#E5EAF2',
    text: '#111827',
    textMuted: '#6B7280',
    textDisabled: '#9CA3AF',
    success: '#22C55E',
    warning: '#FFB020',
    danger: '#EF4444',
    accent: '#FF7A90',
    disabled: '#9CA3AF'
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
  card: { radius: 24, color: '#0A000000', offsetX: 0, offsetY: 8 },
  soft: { radius: 18, color: '#0D000000', offsetX: 0, offsetY: 6 },
  floating: { radius: 28, color: '#14000000', offsetX: 0, offsetY: 10 }
};
