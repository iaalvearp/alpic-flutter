import type { Context } from 'hono';
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

  private actor(c: Context): ImageActor {
    const user = c.get('user');
    if (!user?.sub) {
      throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
    }
    return { id: user.sub, role: user.role ?? UserRole.USER };
  }

  create = async (c: Context) => {
    const formData = await c.req.formData();
    const file = formData.get('file');
    console.log('Upload attempt:', {
      hasFile: !!file,
      isFileInstance: file instanceof File,
      fileName: file && typeof file === 'object' && 'name' in file ? (file as File).name : 'none',
      fileSize: file && typeof file === 'object' && 'size' in file ? (file as File).size : 'none',
      fileType: file && typeof file === 'object' && 'type' in file ? (file as File).type : 'none',
      formDataKeys: Array.from(formData.keys()),
    });
    const actor = this.actor(c);
    const { input, file: parsedFile } = await parseCreateImageDto(formData, actor.id);
    const image = await this.service.create(input, parsedFile);
    return c.json({ data: toImageResponseDto(image) }, 201);
  };

  list = async (c: Context) => {
    const actor = this.actor(c);
    const images = await this.service.findVisible(actor);
    return c.json({ data: images.map(toImageResponseDto) });
  };

  getById = async (c: Context) => {
    const id = parseImageId(c.req.param('id'));
    const actor = this.actor(c);
    const image = await this.service.findById(id, actor);
    if (!image) {
      throw new AppError('Image not found', 404, 'IMAGE_NOT_FOUND');
    }
    return c.json({ data: toImageResponseDto(image) });
  };

  update = async (c: Context) => {
    const id = parseImageId(c.req.param('id'));
    const body = await c.req.json();
    const dto = parseUpdateImageDto(body);
    const actor = this.actor(c);
    const image = await this.service.updateMetadata(id, actor, dto);
    return c.json({ data: toImageResponseDto(image) });
  };

  remove = async (c: Context) => {
    const id = parseImageId(c.req.param('id'));
    const actor = this.actor(c);
    await this.service.softDelete(id, actor);
    return c.json({ data: { id, deleted: true } });
  };
}
