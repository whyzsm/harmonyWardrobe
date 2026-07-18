import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import { geoLocationManager } from '@kit.LocationKit';

interface WeatherKitCondition {
  description: string;
}

interface WeatherKitLocation {
  latitude: number;
  longitude: number;
}

interface WeatherKitDataset {
  CURRENT: number;
}

interface WeatherKitCurrent {
  temperature: number;
  condition: WeatherKitCondition;
  updateTime: Date;
}

interface WeatherKitResponse {
  current?: WeatherKitCurrent;
}

interface WeatherKitRequest {
  location: WeatherKitLocation;
  limitedDatasets: number[];
}

interface WeatherKitNamespace {
  Dataset: WeatherKitDataset;
  getWeather(request: WeatherKitRequest): Promise<WeatherKitResponse>;
}

interface WeatherKitModule {
  weatherService: WeatherKitNamespace;
}

export interface CurrentTemperatureReading {
  celsius: number;
  summary: string;
  updatedAt: Date;
}

const APPROXIMATE_LOCATION_PERMISSION: 'ohos.permission.APPROXIMATELY_LOCATION' =
  'ohos.permission.APPROXIMATELY_LOCATION';

export class WeatherService {
  private readonly context: common.Context;
  private locationPermissionGranted: boolean = false;

  constructor(context: common.Context) {
    this.context = context;
  }

  async fetchCurrentTemperature(): Promise<CurrentTemperatureReading> {
    await this.ensureLocationPermission();
    const location = await geoLocationManager.getCurrentLocation();
    const weatherKit = await this.loadWeatherKit();
    const weather = await weatherKit.getWeather({
      location: {
        latitude: location.latitude,
        longitude: location.longitude
      },
      limitedDatasets: [weatherKit.Dataset.CURRENT]
    });

    if (weather.current === undefined) {
      throw new Error('实时天气暂不可用，请稍后重试');
    }

    return {
      celsius: weather.current.temperature,
      summary: weather.current.condition.description,
      updatedAt: weather.current.updateTime
    };
  }

  private async loadWeatherKit(): Promise<WeatherKitNamespace> {
    const weatherKitModule: WeatherKitModule = await import('@kit.WeatherServiceKit');
    return weatherKitModule.weatherService;
  }

  private async ensureLocationPermission(): Promise<void> {
    if (this.locationPermissionGranted) {
      return;
    }

    const permissionManager = abilityAccessCtrl.createAtManager();
    const result = await permissionManager.requestPermissionsFromUser(
      this.context,
      [APPROXIMATE_LOCATION_PERMISSION]
    );
    if (result.authResults.length === 0 || result.authResults[0] !== 0) {
      throw new Error('需要位置权限才能显示实时温度');
    }

    this.locationPermissionGranted = true;
  }
}
