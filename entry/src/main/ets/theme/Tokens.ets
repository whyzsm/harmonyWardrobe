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
