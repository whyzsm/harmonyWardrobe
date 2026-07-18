import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import {
  PROFILE_HEIGHT_MAX_CM,
  PROFILE_HEIGHT_MIN_CM,
  PROFILE_WAIST_MAX_CM,
  PROFILE_WAIST_MIN_CM,
  PROFILE_WEIGHT_MAX_KG,
  PROFILE_WEIGHT_MIN_KG,
  UserProfile
} from '../../domain/profile/ProfileModels';
import { toIsoDateTime } from '../../utils/date';

const PROFILE_ID = 'local';
const MAX_COMMON_ITEMS = 3;
const GENERIC_MEASUREMENT_MAX = 100000000;
const DEFAULT_COMMON_BUDGETS: number[] = [2400, 3200, 4000];

const SELECT_PROFILE_SQL = `
  SELECT
    COALESCE(height_cm, -1) AS height_cm,
    COALESCE(weight_kg, -1) AS weight_kg,
    COALESCE(waist_cm, -1) AS waist_cm,
    upper_size,
    lower_size,
    shoe_size,
    frequent_districts,
    COALESCE(monthly_budget, -1) AS monthly_budget,
    common_budgets,
    updated_at
  FROM user_profile
  WHERE id = ?
`;

const UPSERT_PROFILE_SQL = `
  INSERT OR REPLACE INTO user_profile (
    id,
    height_cm,
    weight_kg,
    waist_cm,
    upper_size,
    lower_size,
    shoe_size,
    frequent_districts,
    monthly_budget,
    common_budgets,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
`;

export interface SaveUserProfileInput {
  heightCm?: number;
  weightKg?: number;
  waistCm?: number;
  upperSize?: string;
  lowerSize?: string;
  shoeSize?: string;
  frequentDistricts?: string[];
  monthlyBudget?: number;
  commonBudgets?: number[];
}

function decodeStrings(value: string): string[] {
  try {
    const decoded = JSON.parse(value) as string[];
    const result: string[] = [];
    for (const item of decoded) {
      const trimmed = item.trim();
      if (trimmed.length > 0 && !result.includes(trimmed) && result.length < MAX_COMMON_ITEMS) {
        result.push(trimmed);
      }
    }
    return result;
  } catch (_error) {
    return [];
  }
}

function decodeNumbers(value: string): number[] {
  try {
    const decoded = JSON.parse(value) as number[];
    const result: number[] = [];
    for (const item of decoded) {
      if (Number.isFinite(item) && item >= 500) {
        const normalized = Math.round(item);
        if (!result.includes(normalized) && result.length < MAX_COMMON_ITEMS) {
          result.push(normalized);
        }
      }
    }
    return result;
  } catch (_error) {
    return [];
  }
}

function normalizeStrings(values?: string[]): string[] {
  return decodeStrings(JSON.stringify(values ?? []));
}

function optionalString(value: string | null | undefined): string | undefined {
  if (value === null || value === undefined) {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function normalizeNumbers(values?: number[]): number[] {
  return decodeNumbers(JSON.stringify(values ?? []));
}

function normalizeMeasurement(value?: number, min: number = 0, max: number = GENERIC_MEASUREMENT_MAX): number | undefined {
  if (value === undefined || !Number.isFinite(value) || value < min || value > max) {
    return undefined;
  }

  return Math.round(value * 10) / 10;
}

function optionalMeasurement(value: number, min: number = 0, max: number = GENERIC_MEASUREMENT_MAX): number | undefined {
  return Number.isFinite(value) && value >= min && value <= max ? value : undefined;
}

function nullableMeasurement(value?: number): number | null {
  return value === undefined ? null : value;
}

export class ProfileRepository {
  private readonly database: MigrationDatabase;

  constructor(database: MigrationDatabase) {
    this.database = database;
  }

  async getProfile(): Promise<UserProfile> {
    const resultSet = await this.database.querySql(SELECT_PROFILE_SQL, [PROFILE_ID]);

    try {
      if (!resultSet.goToFirstRow()) {
        return {
          frequentDistricts: [],
          commonBudgets: DEFAULT_COMMON_BUDGETS.slice(),
          updatedAt: ''
        };
      }

      return this.readProfileRow(resultSet);
    } finally {
      resultSet.close();
    }
  }

  async saveProfile(input: SaveUserProfileInput): Promise<UserProfile> {
    const profile: UserProfile = {
      heightCm: normalizeMeasurement(input.heightCm, PROFILE_HEIGHT_MIN_CM, PROFILE_HEIGHT_MAX_CM),
      weightKg: normalizeMeasurement(input.weightKg, PROFILE_WEIGHT_MIN_KG, PROFILE_WEIGHT_MAX_KG),
      waistCm: normalizeMeasurement(input.waistCm, PROFILE_WAIST_MIN_CM, PROFILE_WAIST_MAX_CM),
      upperSize: optionalString(input.upperSize ?? ''),
      lowerSize: optionalString(input.lowerSize ?? ''),
      shoeSize: optionalString(input.shoeSize ?? ''),
      frequentDistricts: normalizeStrings(input.frequentDistricts),
      monthlyBudget: normalizeMeasurement(input.monthlyBudget),
      commonBudgets: normalizeNumbers(input.commonBudgets),
      updatedAt: toIsoDateTime(new Date())
    };

    return this.database.transaction(async () => {
      await this.database.executeSql(UPSERT_PROFILE_SQL, this.profileBindArgs(profile));
      return profile;
    });
  }

  private profileBindArgs(profile: UserProfile): MigrationSqlValue[] {
    return [
      PROFILE_ID,
      nullableMeasurement(profile.heightCm),
      nullableMeasurement(profile.weightKg),
      nullableMeasurement(profile.waistCm),
      profile.upperSize ?? null,
      profile.lowerSize ?? null,
      profile.shoeSize ?? null,
      JSON.stringify(profile.frequentDistricts),
      nullableMeasurement(profile.monthlyBudget),
      JSON.stringify(profile.commonBudgets),
      profile.updatedAt
    ];
  }

  private readProfileRow(resultSet: MigrationResultSet): UserProfile {
    return {
      heightCm: optionalMeasurement(resultSet.getNumber('height_cm'), PROFILE_HEIGHT_MIN_CM, PROFILE_HEIGHT_MAX_CM),
      weightKg: optionalMeasurement(resultSet.getNumber('weight_kg'), PROFILE_WEIGHT_MIN_KG, PROFILE_WEIGHT_MAX_KG),
      waistCm: optionalMeasurement(resultSet.getNumber('waist_cm'), PROFILE_WAIST_MIN_CM, PROFILE_WAIST_MAX_CM),
      upperSize: optionalString(resultSet.getString('upper_size')),
      lowerSize: optionalString(resultSet.getString('lower_size')),
      shoeSize: optionalString(resultSet.getString('shoe_size')),
      frequentDistricts: decodeStrings(resultSet.getString('frequent_districts')),
      monthlyBudget: optionalMeasurement(resultSet.getNumber('monthly_budget')),
      commonBudgets: decodeNumbers(resultSet.getString('common_budgets')),
      updatedAt: resultSet.getString('updated_at')
    };
  }
}
