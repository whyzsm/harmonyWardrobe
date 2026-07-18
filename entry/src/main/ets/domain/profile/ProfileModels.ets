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
