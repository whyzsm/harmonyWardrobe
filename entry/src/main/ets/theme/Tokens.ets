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
    primary: '#1D1D1F',
    primaryStrong: '#000000',
    primaryPressed: '#000000',
    primarySoft: '#F2F2F7',
    surface: '#FFFFFF',
    surfaceRaised: '#FBFBFD',
    surfaceMuted: '#F5F5F7',
    border: '#D2D2D7',
    text: '#1D1D1F',
    textMuted: '#6E6E73',
    textDisabled: '#B8B8BD',
    success: '#16A34A',
    warning: '#EAB308',
    danger: '#DC2626',
    accent: '#1D1D1F',
    disabled: '#B8B8BD'
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
  brandCyan: '#1D1D1F',
  success: '#16A34A',
  successBg: '#ECFDF3',
  borderLight: '#E8E8ED',
  borderMedium: '#D2D2D7',
  borderStrong: '#1D1D1F',
  overlayDark: '#7A1D1D1F'
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
  xs: 5,
  sm: 8,
  md: 12,
  lg: 14,
  xl: 16,
  xxl: 18,
  xxxl: 20,
  sheet: 28,
  full: 999
};

export const YibuqueShadow: YibuqueShadowTokens = {
  card: { radius: 20, color: '#14000000', offsetX: 0, offsetY: 6 },
  soft: { radius: 16, color: '#18000000', offsetX: 0, offsetY: 5 },
  floating: { radius: 24, color: '#26000000', offsetX: 0, offsetY: 8 }
};
