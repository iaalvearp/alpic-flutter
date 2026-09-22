import { randomUUID } from 'node:crypto';
import {
  ImageModel,
  type CreateImageInput,
  type ImageFile,
} from '../models/image.model.js';
import { UserRole, type ImageActor } from '../models/user.model.js';
import type { ImageRepository } from '../repositories/image.repository.js';
import { EntityNotFoundError } from '../models/not-found-error.model.js';

const normalizeExtension = (extension: string): string =>
  extension.trim().replace(/^\./, '').toLowerCase();

export class ImageService {
  constructor(private readonly repository: ImageRepository) {}

  checkConnection(): Promise<void> {
    return this.repository.checkConnection();
  }

  findVisible(actor: ImageActor): Promise<ImageModel[]> {
    return actor.role === UserRole.ADMIN
      ? this.repository.findAllVisible()
      : this.repository.findVisibleByOwner(actor.id);
  }

  findById(id: string, actor: ImageActor): Promise<ImageModel | null> {
    return this.repository.findById(
      id,
      actor.role === UserRole.ADMIN ? undefined : actor.id,
    );
  }

  async create(input: CreateImageInput, file: ImageFile): Promise<ImageModel> {
    const id = randomUUID();
    const extension = normalizeExtension(file.extension || input.extension);
    const storagePath = `${input.ownerId}/${id}.${extension}`;
    const now = new Date();
    const draft = new ImageModel({
      id,
      ownerId: input.ownerId,
      name: input.name,
      src: this.repository.publicUrl(storagePath),
      storagePath,
      alt: input.alt,
      description: input.description,
      mimeType: input.mimeType,
      extension,
      sizeBytes: input.sizeBytes,
      latitude: input.latitude,
      longitude: input.longitude,
      mapsUrl: input.mapsUrl,
      source: input.source,
      originalFilename: input.originalFilename,
      createdAt: now,
      updatedAt: now,
      isVisible: true,
      deletedAt: null,
    });

    await this.repository.uploadFile(storagePath, file.bytes, file.contentType);
    try {
      return await this.repository.create(draft);
    } catch (error) {
      await this.repository.removeFile(storagePath).catch(() => undefined);
      throw error;
    }
  }

  updateMetadata(
    id: string,
    actor: ImageActor,
    values: Pick<ImageModel, 'name' | 'alt' | 'description'>,
  ): Promise<ImageModel> {
    return this.repository.updateMetadata(
      id,
      {
        ...values,
        updatedAt: new Date(),
      },
      actor.role === UserRole.ADMIN ? undefined : actor.id,
    ).then((updated) => {
      if (!updated) throw new EntityNotFoundError('Image');
      return updated;
    });
  }

  async softDelete(id: string, actor: ImageActor): Promise<void> {
    const deleted = await this.repository.softDelete(
      id,
      new Date(),
      actor.role === UserRole.ADMIN ? undefined : actor.id,
    );
    if (!deleted) throw new EntityNotFoundError('Image');
  }
}

export interface ImageServicePort {
  create(input: CreateImageInput, file: ImageFile): Promise<ImageModel>;
  findVisible(actor: ImageActor): Promise<ImageModel[]>;
  findById(id: string, actor: ImageActor): Promise<ImageModel | null>;
  updateMetadata(
    id: string,
    actor: ImageActor,
    values: Pick<ImageModel, 'name' | 'alt' | 'description'>,
  ): Promise<ImageModel>;
  softDelete(id: string, actor: ImageActor): Promise<void>;
}
