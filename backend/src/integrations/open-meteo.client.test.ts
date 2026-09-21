import assert from 'node:assert/strict';
import { test } from 'node:test';
import type {
  ExternalApiClient,
  ExternalApiRequest,
} from './external-api.client.js';
import {
  ExternalApiClientError,
} from './external-api.client.js';
import { OpenMeteoWeatherClient } from './open-meteo.client.js';

test('OpenMeteoWeatherClient requests current weather for image coordinates', async () => {
  const client = new FakeExternalApiClient(validPayload());
  const weatherClient = new OpenMeteoWeatherClient(client);

  const result = await weatherClient.getCurrentWeather(-0.18, -78.48);
  const request = client.requestData;
  assert.ok(request);
  assert.equal(request.path.includes('latitude=-0.18'), true);
  assert.equal(request.path.includes('longitude=-78.48'), true);
  assert.equal(request.path.includes('current='), true);
  assert.equal(result.temperature.value, 18.5);
  assert.equal(result.isDay, true);
});

test('OpenMeteoWeatherClient rejects an invalid provider response', async () => {
  const weatherClient = new OpenMeteoWeatherClient(
    new FakeExternalApiClient({ current: {} }),
  );

  await assert.rejects(
    () => weatherClient.getCurrentWeather(-0.18, -78.48),
    (error: unknown) => {
      assert.equal(error instanceof ExternalApiClientError, true);
      assert.equal(
        (error as ExternalApiClientError).reason,
        'INVALID_JSON',
      );
      return true;
    },
  );
});

const validPayload = (): Record<string, unknown> => ({
  latitude: -0.18,
  longitude: -78.48,
  timezone: 'America/Guayaquil',
  current: {
    time: '2026-09-21T12:00',
    temperature_2m: 18.5,
    relative_humidity_2m: 72,
    apparent_temperature: 18.1,
    precipitation: 0,
    weather_code: 2,
    wind_speed_10m: 8,
    is_day: 1,
  },
  current_units: {
    temperature_2m: '°C',
    relative_humidity_2m: '%',
    apparent_temperature: '°C',
    precipitation: 'mm',
    wind_speed_10m: 'km/h',
  },
});

class FakeExternalApiClient implements ExternalApiClient {
  requestData: ExternalApiRequest | undefined;

  constructor(private readonly response: unknown) {}

  async request<TResponse>(request: ExternalApiRequest): Promise<TResponse> {
    this.requestData = request;
    return this.response as TResponse;
  }
}
