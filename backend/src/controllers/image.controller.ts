import type { RequestHandler } from 'express';
import { AppError } from '../models/app-error.model.js';
import {
  parseCreateImageDto,
  parseImageId,
  parseUpdateImageDto,
  toImageResponseDto,
} from '../dtos/image.dto.js';
import type { ImageServicePort } from '../services/image.service.js';
import { UserRole, type ImageActor } from '../models/user.model.js';

export class ImageController {
  constructor(private readonly service: ImageServicePort) {}

  private actor(request: Parameters<RequestHandler>[0]): ImageActor {
    const user = request.user;
    if (!user?.sub) {
      throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
    }
    return { id: user.sub, role: user.role ?? UserRole.USER };
  }

  create: RequestHandler = async (request, response, next) => {
    try {
      const { input, file } = parseCreateImageDto(
        request.body,
        request.file,
        this.actor(request).id,
      );
      const image = await this.service.create(input, file);
      response.status(201).json({ data: toImageResponseDto(image) });
    } catch (error) {
      next(error);
    }
  };

  list: RequestHandler = async (request, response, next) => {
    try {
      const images = await this.service.findVisible(this.actor(request));
      response.json({ data: images.map(toImageResponseDto) });
    } catch (error) {
      next(error);
    }
  };

  getById: RequestHandler = async (request, response, next) => {
    try {
      const id = parseImageId(request.params.id);
      const image = await this.service.findById(id, this.actor(request));
      if (!image) {
        throw new AppError('Image not found', 404, 'IMAGE_NOT_FOUND');
      }
      response.json({ data: toImageResponseDto(image) });
    } catch (error) {
      next(error);
    }
  };

  update: RequestHandler = async (request, response, next) => {
    try {
      const id = parseImageId(request.params.id);
      const dto = parseUpdateImageDto(request.body);
      const image = await this.service.updateMetadata(id, this.actor(request), dto);
      response.json({ data: toImageResponseDto(image) });
    } catch (error) {
      next(error);
    }
  };

  remove: RequestHandler = async (request, response, next) => {
    try {
      const id = parseImageId(request.params.id);
      await this.service.softDelete(id, this.actor(request));
      response.json({ data: { id, deleted: true } });
    } catch (error) {
      next(error);
    }
  };
}
