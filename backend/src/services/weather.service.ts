import {
  ExternalApiClientError,
  type ExternalApiFailureReason,
} from '../integrations/external-api.client.js';
import type { WeatherExternalClient } from '../integrations/open-meteo.client.js';
import { AppError } from '../models/app-error.model.js';
import type { ImageWeatherModel } from '../models/weather.model.js';
import type { ImageActor } from '../models/user.model.js';
import type { ImageServicePort } from './image.service.js';

const externalError = (reason: ExternalApiFailureReason): AppError => {
  if (reason === 'TIMEOUT') {
    return new AppError(
      'Weather provider timed out',
      504,
      'WEATHER_PROVIDER_TIMEOUT',
    );
  }
  if (reason === 'INVALID_JSON') {
    return new AppError(
      'Weather provider returned an invalid response',
      502,
      'WEATHER_PROVIDER_INVALID_RESPONSE',
    );
  }
  return new AppError(
    'Weather provider is unavailable',
    502,
    'WEATHER_PROVIDER_ERROR',
  );
};

export interface WeatherServicePort {
  getForImage(id: string, actor: ImageActor): Promise<ImageWeatherModel>;
}

export class WeatherService implements WeatherServicePort {
  constructor(
    private readonly imageService: Pick<ImageServicePort, 'findById'>,
    private readonly weatherClient: WeatherExternalClient,
  ) {}

  async getForImage(
    id: string,
    actor: ImageActor,
  ): Promise<ImageWeatherModel> {
    const image = await this.imageService.findById(id, actor);
    if (!image) {
      throw new AppError('Image not found', 404, 'IMAGE_NOT_FOUND');
    }
    if (image.latitude === null || image.longitude === null) {
      throw new AppError(
        'Image has no geographic coordinates',
        400,
        'IMAGE_COORDINATES_REQUIRED',
      );
    }

    try {
      const weather = await this.weatherClient.getCurrentWeather(
        image.latitude,
        image.longitude,
      );
      return {
        imageId: image.id,
        provider: 'open-meteo',
        coordinates: {
          latitude: image.latitude,
          longitude: image.longitude,
        },
        providerCoordinates: weather.providerCoordinates,
        timezone: weather.timezone,
        observedAt: weather.observedAt,
        current: {
          temperature: weather.temperature,
          apparentTemperature: weather.apparentTemperature,
          relativeHumidity: weather.relativeHumidity,
          precipitation: weather.precipitation,
          windSpeed: weather.windSpeed,
          weatherCode: weather.weatherCode,
          isDay: weather.isDay,
        },
      };
    } catch (error) {
      if (error instanceof ExternalApiClientError) {
        throw externalError(error.reason);
      }
      throw error;
    }
  }
}
