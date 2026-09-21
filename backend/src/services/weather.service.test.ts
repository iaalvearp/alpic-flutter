import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  ExternalApiClientError,
} from '../integrations/external-api.client.js';
import type {
  OpenMeteoWeather,
  WeatherExternalClient,
} from '../integrations/open-meteo.client.js';
import { ImageModel } from '../models/image.model.js';
import { UserRole } from '../models/user.model.js';
import type { ImageServicePort } from './image.service.js';
import { WeatherService } from './weather.service.js';

test('WeatherService obtains coordinates and maps provider data', async () => {
  const client = new FakeWeatherClient();
  const service = new WeatherService(
    imageServiceWith(imageWithCoordinates()),
    client,
  );

  const result = await service.getForImage('image-1', {
    id: 'owner-1',
    role: UserRole.USER,
  });

  assert.deepEqual(client.coordinates, { latitude: -0.18, longitude: -78.48 });
  assert.equal(result.imageId, 'image-1');
  assert.equal(result.provider, 'open-meteo');
  assert.equal(result.current.temperature.value, 18.5);
  assert.equal(result.current.isDay, true);
});

test('WeatherService rejects an image without coordinates', async () => {
  const service = new WeatherService(
    imageServiceWith(imageWithoutCoordinates()),
    new FakeWeatherClient(),
  );

  await assert.rejects(
    () => service.getForImage('image-1', userActor()),
    (error: unknown) => {
      assert.equal((error as { statusCode: number }).statusCode, 400);
      assert.equal((error as { code: string }).code, 'IMAGE_COORDINATES_REQUIRED');
      return true;
    },
  );
});

test('WeatherService maps a provider timeout to 504', async () => {
  const service = new WeatherService(
    imageServiceWith(imageWithCoordinates()),
    new FailingWeatherClient(new ExternalApiClientError('TIMEOUT', 'timeout')),
  );

  await assert.rejects(
    () => service.getForImage('image-1', userActor()),
    (error: unknown) => {
      assert.equal((error as { statusCode: number }).statusCode, 504);
      assert.equal((error as { code: string }).code, 'WEATHER_PROVIDER_TIMEOUT');
      return true;
    },
  );
});

test('WeatherService maps invalid provider data to 502', async () => {
  const service = new WeatherService(
    imageServiceWith(imageWithCoordinates()),
    new FailingWeatherClient(
      new ExternalApiClientError('INVALID_JSON', 'invalid response'),
    ),
  );

  await assert.rejects(
    () => service.getForImage('image-1', userActor()),
    (error: unknown) => {
      assert.equal((error as { statusCode: number }).statusCode, 502);
      assert.equal(
        (error as { code: string }).code,
        'WEATHER_PROVIDER_INVALID_RESPONSE',
      );
      return true;
    },
  );
});

test('WeatherService returns 404 when the image is not visible to the actor', async () => {
  const service = new WeatherService(
    imageServiceWith(null),
    new FakeWeatherClient(),
  );

  await assert.rejects(
    () => service.getForImage('missing-image', userActor()),
    (error: unknown) => {
      assert.equal((error as { statusCode: number }).statusCode, 404);
      assert.equal((error as { code: string }).code, 'IMAGE_NOT_FOUND');
      return true;
    },
  );
});

const userActor = () => ({ id: 'owner-1', role: UserRole.USER });

const imageServiceWith = (
  image: ImageModel | null,
): Pick<ImageServicePort, 'findById'> => ({
  findById: async () => image,
});

const imageWithCoordinates = (): ImageModel => new ImageModel({
  id: 'image-1',
  ownerId: 'owner-1',
  name: 'Imagen',
  src: null,
  storagePath: null,
  alt: 'Alt',
  description: 'Descripción',
  mimeType: 'image/png',
  extension: 'png',
  sizeBytes: 3,
  latitude: -0.18,
  longitude: -78.48,
  mapsUrl: null,
  source: 'gallery',
  originalFilename: 'foto.png',
  createdAt: new Date(),
  updatedAt: new Date(),
  isVisible: true,
  deletedAt: null,
});

const imageWithoutCoordinates = (): ImageModel => new ImageModel({
  ...imageWithCoordinates(),
  latitude: null,
  longitude: null,
});

const weather: OpenMeteoWeather = {
  providerCoordinates: { latitude: -0.18, longitude: -78.48 },
  timezone: 'America/Guayaquil',
  observedAt: '2026-09-21T12:00',
  temperature: { value: 18.5, unit: '°C' },
  apparentTemperature: { value: 18.1, unit: '°C' },
  relativeHumidity: { value: 72, unit: '%' },
  precipitation: { value: 0, unit: 'mm' },
  windSpeed: { value: 8, unit: 'km/h' },
  weatherCode: 2,
  isDay: true,
};

class FakeWeatherClient implements WeatherExternalClient {
  coordinates: { latitude: number; longitude: number } | undefined;

  async getCurrentWeather(
    latitude: number,
    longitude: number,
  ): Promise<OpenMeteoWeather> {
    this.coordinates = { latitude, longitude };
    return weather;
  }
}

class FailingWeatherClient implements WeatherExternalClient {
  constructor(private readonly error: ExternalApiClientError) {}

  async getCurrentWeather(): Promise<OpenMeteoWeather> {
    throw this.error;
  }
}
