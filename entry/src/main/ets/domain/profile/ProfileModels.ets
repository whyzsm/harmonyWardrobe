export interface UserProfile {
  heightCm?: number;
  weightKg?: number;
  waistCm?: number;
  fittingPreferenceEnabled: boolean;
  styleTags: string[];
  frequentDistricts: string[];
  monthlyBudget?: number;
  privacyModeEnabled: boolean;
  updatedAt: string;
}
