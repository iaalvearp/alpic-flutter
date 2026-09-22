import type { Context } from 'hono';
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

  private actor(c: Context): ImageActor {
    const user = c.get('user');
    if (!user?.sub) {
      throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
    }
    return { id: user.sub, role: user.role ?? UserRole.USER };
  }

  getForImage = async (c: Context) => {
    const id = parseImageId(c.req.param('id'));
    const actor = this.actor(c);
    const weather = await this.service.getForImage(id, actor);
    const result: WeatherResponseDto = toWeatherResponseDto(weather);
    return c.json({ data: result });
  };
}
