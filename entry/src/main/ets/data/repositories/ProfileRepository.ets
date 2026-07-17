import {
  MigrationDatabase,
  MigrationResultSet,
  MigrationSqlValue
} from '../migrations/Migration';
import { UserProfile } from '../../domain/profile/ProfileModels';
import { toIsoDateTime } from '../../utils/date';

const PROFILE_ID = 'local';

const SELECT_PROFILE_SQL = `
  SELECT
    COALESCE(height_cm, -1) AS height_cm,
    COALESCE(weight_kg, -1) AS weight_kg,
    COALESCE(waist_cm, -1) AS waist_cm,
    frequent_districts,
    COALESCE(monthly_budget, -1) AS monthly_budget,
    privacy_mode_enabled,
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
    frequent_districts,
    monthly_budget,
    privacy_mode_enabled,
    updated_at
  )
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)
`;

export interface SaveUserProfileInput {
  heightCm?: number;
  weightKg?: number;
  waistCm?: number;
  frequentDistricts?: string[];
  monthlyBudget?: number;
  privacyModeEnabled?: boolean;
}

function decodeStrings(value: string): string[] {
  try {
    const decoded = JSON.parse(value) as string[];
    return decoded.filter((item: string) => item.trim().length > 0);
  } catch (_error) {
    return [];
  }
}

function normalizeMeasurement(value?: number): number | undefined {
  if (value === undefined || !Number.isFinite(value) || value < 0) {
    return undefined;
  }

  return Math.round(value * 10) / 10;
}

function optionalMeasurement(value: number): number | undefined {
  return Number.isFinite(value) && value >= 0 ? value : undefined;
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
          privacyModeEnabled: false,
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
      heightCm: normalizeMeasurement(input.heightCm),
      weightKg: normalizeMeasurement(input.weightKg),
      waistCm: normalizeMeasurement(input.waistCm),
      frequentDistricts: input.frequentDistricts ?? [],
      monthlyBudget: normalizeMeasurement(input.monthlyBudget),
      privacyModeEnabled: input.privacyModeEnabled ?? false,
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
      JSON.stringify(profile.frequentDistricts),
      nullableMeasurement(profile.monthlyBudget),
      profile.privacyModeEnabled ? 1 : 0,
      profile.updatedAt
    ];
  }

  private readProfileRow(resultSet: MigrationResultSet): UserProfile {
    return {
      heightCm: optionalMeasurement(resultSet.getNumber('height_cm')),
      weightKg: optionalMeasurement(resultSet.getNumber('weight_kg')),
      waistCm: optionalMeasurement(resultSet.getNumber('waist_cm')),
      frequentDistricts: decodeStrings(resultSet.getString('frequent_districts')),
      monthlyBudget: optionalMeasurement(resultSet.getNumber('monthly_budget')),
      privacyModeEnabled: resultSet.getNumber('privacy_mode_enabled') === 1,
      updatedAt: resultSet.getString('updated_at')
    };
  }
}
