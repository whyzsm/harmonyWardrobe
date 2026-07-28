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
  bgBase: string;
  bgHeader: string;
  cardWhite: string;
  cardSurface: string;
  cardMuted: string;
  cardSoftGray: string;
  cardDark: string;
  iconDarkSurface: string;
  bottomNavigationSurface: string;
  searchHeaderSurface: string;
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  textQuaternary: string;
  textDisabled: string;
  textInverse: string;
  actionBlack: string;
  iconAccent: string;
  iconAccentSurface: string;
  profileHeroSurface: string;
  selectionAccent: string;
  selectionAccentSurface: string;
  success: string;
  successBg: string;
  danger: string;
  borderLight: string;
  borderMedium: string;
  borderStrong: string;
  overlayDark: string;
  scrimLight: string;
  scrimMedium: string;
  scrimStrong: string;
  glassLight: string;
  glassMedium: string;
  glassStrong: string;
  glassBadge: string;
  transparent: string;
  transparentBlack: string;
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
  mainNavigationClearance: number;
}

export interface YibuqueRadiusTokens {
  micro: number;
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
  appTopBar: ShadowOptions;
  bottomNavigation: ShadowOptions;
  cameraGlow: ShadowOptions;
  editorSheet: ShadowOptions;
  badge: ShadowOptions;
  sheetHandle: ShadowOptions;
}

export interface YibuqueMotionTokens {
  fullScreenPageTransition: number;
  sheetTransition: number;
}

export interface YibuqueTransitionTokens {
  fullScreenOpacity: TransitionEffect;
  sheetOpacity: TransitionEffect;
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
  bgBase: '#FFFFFF',
  bgHeader: '#F5F5F7',
  cardWhite: '#FFFFFF',
  cardSurface: '#F2F2F7',
  cardMuted: '#F5F5F7',
  cardSoftGray: '#FBFBFD',
  cardDark: '#1C1C1E',
  iconDarkSurface: '#3A3A3C',
  bottomNavigationSurface: '#E62D2C2C',
  searchHeaderSurface: '#F2FBF9F9',
  textPrimary: '#1D1D1F',
  textSecondary: '#6E6E73',
  textTertiary: '#86868B',
  textQuaternary: '#626267',
  textDisabled: '#B8B8BD',
  textInverse: '#FFFFFF',
  actionBlack: '#1D1D1F',
  iconAccent: '#0071E3',
  iconAccentSurface: '#EAF3FE',
  profileHeroSurface: '#E2EEFC',
  selectionAccent: '#0071E3',
  selectionAccentSurface: '#EAF3FE',
  success: '#16A34A',
  successBg: '#ECFDF3',
  danger: '#DC2626',
  borderLight: '#E8E8ED',
  borderMedium: '#D2D2D7',
  borderStrong: '#1D1D1F',
  overlayDark: '#7A1D1D1F',
  // 半透明黑色遮罩（ARGB #AARRGGBB），由浅到深
  scrimLight: '#29000000',
  scrimMedium: '#52000000',
  scrimStrong: '#99000000',
  // 白色半透明（毛玻璃）表面，由浅到深
  glassLight: '#38FFFFFF',
  glassMedium: '#D9FFFFFF',
  glassStrong: '#F2FFFFFF',
  glassBadge: '#E6FFFFFF',
  // 全透明占位：白色通道（等价 #00FFFFFF），用于 backgroundColor 透明底
  transparent: '#00FFFFFF',
  // 全透明占位：黑色通道（等价 #00000000），用于黑色渐变的起始停靠点，避免插值泛白
  transparentBlack: '#00000000'
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
  bottomSafe: 24,
  mainNavigationClearance: 96
};

export const YibuqueRadius: YibuqueRadiusTokens = {
  micro: 4,
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
  floating: { radius: 24, color: '#26000000', offsetX: 0, offsetY: 8 },
  appTopBar: { radius: 12, color: '#18000000', offsetX: 0, offsetY: 4 },
  bottomNavigation: { radius: 16, color: '#32000000', offsetX: 0, offsetY: 6 },
  cameraGlow: { radius: 18, color: '#26000000', offsetX: 0, offsetY: 0 },
  editorSheet: { radius: 24, color: '#12000000', offsetX: 0, offsetY: -6 },
  badge: { radius: 8, color: '#16000000', offsetX: 0, offsetY: 3 },
  sheetHandle: { radius: 28, color: '#29000000', offsetX: 0, offsetY: -8 }
};

export const YibuqueMotion: YibuqueMotionTokens = {
  fullScreenPageTransition: 350,
  sheetTransition: 300
};

export const YibuqueTransition: YibuqueTransitionTokens = {
  fullScreenOpacity: TransitionEffect.OPACITY.animation({
    duration: YibuqueMotion.fullScreenPageTransition,
    curve: Curve.EaseOut
  }),
  sheetOpacity: TransitionEffect.OPACITY.animation({
    duration: YibuqueMotion.sheetTransition,
    curve: Curve.FastOutSlowIn
  })
};
