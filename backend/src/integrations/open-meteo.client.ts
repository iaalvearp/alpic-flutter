import {
  ExternalApiClientError,
  FetchExternalApiClient,
  type ExternalApiClient,
} from './external-api.client.js';

export interface OpenMeteoWeather {
  providerCoordinates: {
    latitude: number;
    longitude: number;
  };
  timezone: string;
  observedAt: string;
  temperature: { value: number; unit: string };
  apparentTemperature: { value: number; unit: string };
  relativeHumidity: { value: number; unit: string };
  precipitation: { value: number; unit: string };
  windSpeed: { value: number; unit: string };
  weatherCode: number;
  isDay: boolean;
}

export interface WeatherExternalClient {
  getCurrentWeather(latitude: number, longitude: number): Promise<OpenMeteoWeather>;
}

const currentVariables = [
  'temperature_2m',
  'relative_humidity_2m',
  'apparent_temperature',
  'precipitation',
  'weather_code',
  'wind_speed_10m',
  'is_day',
].join(',');

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null;

const requiredNumber = (value: unknown, field: string): number => {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new ExternalApiClientError(
      'INVALID_JSON',
      `Open-Meteo response field ${field} is invalid`,
    );
  }
  return value;
};

const coordinate = (value: unknown, field: string, maximum: number): number => {
  const parsed = requiredNumber(value, field);
  if (parsed < -maximum || parsed > maximum) {
    throw new ExternalApiClientError(
      'INVALID_JSON',
      `Open-Meteo response field ${field} is out of range`,
    );
  }
  return parsed;
};

const requiredString = (value: unknown, field: string): string => {
  if (typeof value !== 'string' || value.length === 0) {
    throw new ExternalApiClientError(
      'INVALID_JSON',
      `Open-Meteo response field ${field} is invalid`,
    );
  }
  return value;
};

const requiredUnit = (
  units: Record<string, unknown>,
  field: string,
): string => requiredString(units[field], `current_units.${field}`);

const parseResponse = (payload: unknown): OpenMeteoWeather => {
  if (!isRecord(payload) || !isRecord(payload.current) ||
      !isRecord(payload.current_units)) {
    throw new ExternalApiClientError(
      'INVALID_JSON',
      'Open-Meteo response has an invalid structure',
    );
  }

  const current = payload.current;
  const units = payload.current_units;
  const isDay = requiredNumber(current.is_day, 'current.is_day');

  if (isDay !== 0 && isDay !== 1) {
    throw new ExternalApiClientError(
      'INVALID_JSON',
      'Open-Meteo response field current.is_day is invalid',
    );
  }

  return {
    providerCoordinates: {
      latitude: coordinate(payload.latitude, 'latitude', 90),
      longitude: coordinate(payload.longitude, 'longitude', 180),
    },
    timezone: requiredString(payload.timezone, 'timezone'),
    observedAt: requiredString(current.time, 'current.time'),
    temperature: {
      value: requiredNumber(current.temperature_2m, 'current.temperature_2m'),
      unit: requiredUnit(units, 'temperature_2m'),
    },
    apparentTemperature: {
      value: requiredNumber(
        current.apparent_temperature,
        'current.apparent_temperature',
      ),
      unit: requiredUnit(units, 'apparent_temperature'),
    },
    relativeHumidity: {
      value: requiredNumber(
        current.relative_humidity_2m,
        'current.relative_humidity_2m',
      ),
      unit: requiredUnit(units, 'relative_humidity_2m'),
    },
    precipitation: {
      value: requiredNumber(current.precipitation, 'current.precipitation'),
      unit: requiredUnit(units, 'precipitation'),
    },
    windSpeed: {
      value: requiredNumber(current.wind_speed_10m, 'current.wind_speed_10m'),
      unit: requiredUnit(units, 'wind_speed_10m'),
    },
    weatherCode: requiredNumber(current.weather_code, 'current.weather_code'),
    isDay: isDay === 1,
  };
};

export class OpenMeteoWeatherClient implements WeatherExternalClient {
  constructor(
    private readonly client: ExternalApiClient = new FetchExternalApiClient(
      'https://api.open-meteo.com/v1/forecast',
      5000,
    ),
  ) {}

  async getCurrentWeather(
    latitude: number,
    longitude: number,
  ): Promise<OpenMeteoWeather> {
    const query = new URLSearchParams({
      latitude: String(latitude),
      longitude: String(longitude),
      current: currentVariables,
      temperature_unit: 'celsius',
      wind_speed_unit: 'kmh',
      precipitation_unit: 'mm',
      timezone: 'auto',
    });

    const payload = await this.client.request<unknown>({
      path: `?${query.toString()}`,
    });
    return parseResponse(payload);
  }
}
