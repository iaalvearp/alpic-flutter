import type { RequestHandler } from 'express';
import { parseImageId } from '../dtos/image.dto.js';
import {
  toWeatherResponseDto,
  type WeatherResponseDto,
} from '../dtos/weather.dto.js';
import { AppError } from '../models/app-error.model.js';
import { UserRole, type ImageActor } from '../models/user.model.js';
import type { WeatherServicePort } from '../services/weather.service.js';

export class WeatherController {
  constructor(private readonly service: WeatherServicePort) {}

  private actor(request: Parameters<RequestHandler>[0]): ImageActor {
    const user = request.user;
    if (!user?.sub) {
      throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
    }
    return { id: user.sub, role: user.role ?? UserRole.USER };
  }

  getForImage: RequestHandler = async (request, response, next) => {
    try {
      const id = parseImageId(request.params.id);
      const weather = await this.service.getForImage(id, this.actor(request));
      const result: WeatherResponseDto = toWeatherResponseDto(weather);
      response.json({ data: result });
    } catch (error) {
      next(error);
    }
  };
}
