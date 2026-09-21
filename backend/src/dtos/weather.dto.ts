import type { ImageWeatherModel } from '../models/weather.model.js';

export type WeatherResponseDto = ImageWeatherModel;

export const toWeatherResponseDto = (
  weather: ImageWeatherModel,
): WeatherResponseDto => weather;
