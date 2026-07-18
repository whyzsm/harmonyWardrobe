export const PROFILE_HEIGHT_MIN_CM: number = 80;
export const PROFILE_HEIGHT_MAX_CM: number = 250;
export const PROFILE_WEIGHT_MIN_KG: number = 20;
export const PROFILE_WEIGHT_MAX_KG: number = 300;
export const PROFILE_WAIST_MIN_CM: number = 40;
export const PROFILE_WAIST_MAX_CM: number = 200;

export interface UserProfile {
  heightCm?: number;
  weightKg?: number;
  waistCm?: number;
  upperSize?: string;
  lowerSize?: string;
  shoeSize?: string;
  frequentDistricts: string[];
  monthlyBudget?: number;
  commonBudgets: number[];
  updatedAt: string;
}
