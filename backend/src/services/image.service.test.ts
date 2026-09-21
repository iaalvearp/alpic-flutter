import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  ImageModel,
  type CreateImageInput,
  type ImageFile,
} from '../models/image.model.js';
import { ImageService } from './image.service.js';
import type { ImageRepository } from '../repositories/image.repository.js';
import { UserRole } from '../models/user.model.js';

test('ImageService uploads before creating and rolls back on persistence failure', async () => {
  const events: string[] = [];
  const repository = new FakeImageRepository(events, true);
  const service = new ImageService(repository);

  await assert.rejects(() => service.create(input, file));
  assert.deepEqual(events, ['publicUrl', 'uploadFile', 'create', 'removeFile']);
});

test('ImageService delegates visible-image queries to the repository', async () => {
  const events: string[] = [];
  const repository = new FakeImageRepository(events, false);
  const service = new ImageService(repository);

  const images = await service.findVisible({ id: 'owner-1', role: UserRole.USER });
  assert.equal(images.length, 1);
  assert.deepEqual(events, ['findVisibleByOwner']);
});

test('ImageService lets an administrator list all visible images', async () => {
  const events: string[] = [];
  const repository = new FakeImageRepository(events, false);
  const service = new ImageService(repository);

  await service.findVisible({ id: 'admin-1', role: UserRole.ADMIN });
  assert.deepEqual(events, ['findAllVisible']);
});

const input: CreateImageInput = {
  ownerId: 'owner-1',
  name: 'Imagen',
  alt: 'Alt',
  description: 'Descripción',
  mimeType: 'image/png',
  extension: 'png',
  sizeBytes: 3,
  latitude: null,
  longitude: null,
  mapsUrl: null,
  source: 'gallery',
  originalFilename: 'foto.png',
};

const file: ImageFile = {
  bytes: Buffer.from([1, 2, 3]),
  contentType: 'image/png',
  extension: 'png',
};

class FakeImageRepository implements ImageRepository {
  constructor(
    private readonly events: string[],
    private readonly failCreate: boolean,
  ) {}

  async checkConnection(): Promise<void> {}

  async findVisibleByOwner(): Promise<ImageModel[]> {
    this.events.push('findVisibleByOwner');
    return [new ImageModel({
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
      latitude: null,
      longitude: null,
      mapsUrl: null,
      source: 'gallery',
      originalFilename: 'foto.png',
      createdAt: new Date(),
      updatedAt: new Date(),
      isVisible: true,
      deletedAt: null,
    })];
  }

  async findAllVisible(): Promise<ImageModel[]> {
    this.events.push('findAllVisible');
    return [];
  }

  async findById(): Promise<ImageModel | null> {
    return null;
  }

  async create(): Promise<ImageModel> {
    this.events.push('create');
    if (this.failCreate) throw new Error('create failed');
    throw new Error('not used');
  }

  async updateMetadata(): Promise<ImageModel | null> {
    throw new Error('not used');
  }

  async softDelete(): Promise<boolean> {
    throw new Error('not used');
  }

  async uploadFile(): Promise<void> {
    this.events.push('uploadFile');
  }

  async removeFile(): Promise<void> {
    this.events.push('removeFile');
  }

  publicUrl(): string {
    this.events.push('publicUrl');
    return 'https://example.test/image.png';
  }
}
