import assert from 'node:assert/strict';
import express from 'express';
import { test } from 'node:test';
import request from 'supertest';
import { errorMiddleware } from '../middleware/error.middleware.js';
import { AppError } from '../models/app-error.model.js';
import {
  ImageModel,
  type CreateImageInput,
  type ImageFile,
} from '../models/image.model.js';
import { UserRole, type ImageActor } from '../models/user.model.js';
import { createImageRouter } from './image.routes.js';
import type { ImageServicePort } from '../services/image.service.js';
import type { WeatherServicePort } from '../services/weather.service.js';
import type { ImageWeatherModel } from '../models/weather.model.js';
import type { JwtVerifier, JwtUser } from '../middleware/auth.middleware.js';

const buildApp = (
  service: ImageServicePort = new FakeImageService(),
  weatherService: WeatherServicePort = new FakeWeatherService(),
): express.Express => {
  const app = express();
  app.use(express.json());
  app.use(createImageRouter(service, new FakeJwtVerifier(), weatherService));
  app.use(errorMiddleware);
  return app;
};

test('POST /api/images creates an image from multipart data', async () => {
  const response = await request(buildApp())
    .post('/api/images')
    .field('name', 'Imagen nueva')
    .field('alt', 'Texto alternativo')
    .field('description', 'Descripción')
    .field('source', 'gallery')
    .set('Authorization', 'Bearer valid-token')
    .attach('file', Buffer.from([1, 2, 3]), {
      filename: 'foto.png',
      contentType: 'image/png',
    });

  assert.equal(response.status, 201);
  assert.equal(response.body.data.name, 'Imagen nueva');
  assert.equal(response.body.data.originalFilename, 'foto.png');
});

test('GET /api/images returns visible images for an owner', async () => {
  const response = await request(buildApp())
    .get('/api/images')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.length, 1);
  assert.equal(response.body.data[0].ownerId, 'owner-1');
});

test('GET /api/admin/images rejects a normal user with 403', async () => {
  const response = await request(buildApp())
    .get('/api/admin/images')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 403);
  assert.deepEqual(response.body, {
    error: {
      code: 'FORBIDDEN',
      message: 'Insufficient permissions',
    },
  });
});

test('GET /api/admin/images allows an administrator', async () => {
  const response = await request(buildApp())
    .get('/api/admin/images')
    .set('Authorization', 'Bearer admin-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.length, 1);
});

test('GET /api/admin/images rejects an unauthenticated request with 401', async () => {
  const response = await request(buildApp()).get('/api/admin/images');

  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'UNAUTHORIZED');
});

test('GET /api/images/:id returns one image', async () => {
  const response = await request(buildApp())
    .get('/api/images/11111111-1111-4111-8111-111111111111')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.id, '11111111-1111-4111-8111-111111111111');
});

test('GET /api/images/:id rejects a malformed ID before persistence', async () => {
  const response = await request(buildApp())
    .get('/api/images/not-a-uuid')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 400);
  assert.deepEqual(response.body, {
    error: {
      code: 'VALIDATION_ERROR',
      message: 'id must be a valid UUID',
    },
  });
});

test('GET /api/images/:id/weather returns current weather JSON', async () => {
  const response = await request(buildApp())
    .get('/api/images/11111111-1111-4111-8111-111111111111/weather')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.imageId, '11111111-1111-4111-8111-111111111111');
  assert.equal(response.body.data.provider, 'open-meteo');
  assert.equal(response.body.data.current.temperature.value, 18.5);
});

test('GET /api/images/:id/weather returns 404 for a missing image', async () => {
  const response = await request(buildApp())
    .get('/api/images/22222222-2222-4222-8222-222222222222/weather')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 404);
  assert.equal(response.body.error.code, 'IMAGE_NOT_FOUND');
});

test('GET /api/images/:id/weather returns 400 without coordinates', async () => {
  const response = await request(buildApp())
    .get('/api/images/33333333-3333-4333-8333-333333333333/weather')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 400);
  assert.equal(response.body.error.code, 'IMAGE_COORDINATES_REQUIRED');
});

test('GET /api/images/:id/weather requires authentication', async () => {
  const response = await request(buildApp())
    .get('/api/images/11111111-1111-4111-8111-111111111111/weather');

  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'UNAUTHORIZED');
});

test('GET /api/images/:id returns 404 when the image does not exist', async () => {
  const response = await request(buildApp())
    .get('/api/images/22222222-2222-4222-8222-222222222222')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 404);
  assert.deepEqual(response.body, {
    error: {
      code: 'IMAGE_NOT_FOUND',
      message: 'Image not found',
    },
  });
});

test('GET /api/images/:id returns 404 when the image belongs to another user', async () => {
  const response = await request(buildApp())
    .get('/api/images/11111111-1111-4111-8111-111111111111')
    .set('Authorization', 'Bearer other-token');

  assert.equal(response.status, 404);
  assert.equal(response.body.error.code, 'IMAGE_NOT_FOUND');
});

test('PUT /api/images/:id returns 404 when another user tries to modify the image', async () => {
  const response = await request(buildApp())
    .put('/api/images/11111111-1111-4111-8111-111111111111')
    .send({
      name: 'Cambio no permitido',
      alt: 'Alt no permitido',
      description: 'Descripción no permitida',
    })
    .set('Authorization', 'Bearer other-token');

  assert.equal(response.status, 404);
  assert.equal(response.body.error.code, 'IMAGE_NOT_FOUND');
});

test('PUT /api/images/:id updates image metadata', async () => {
  const response = await request(buildApp())
    .put('/api/images/11111111-1111-4111-8111-111111111111')
    .send({
      name: 'Imagen editada',
      alt: 'Alt editado',
      description: 'Descripción editada',
    })
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.name, 'Imagen editada');
});

test('ADMIN can modify an image owned by another user', async () => {
  const response = await request(buildApp())
    .put('/api/images/11111111-1111-4111-8111-111111111111')
    .send({
      name: 'Imagen administrada',
      alt: 'Alt administrado',
      description: 'Descripción administrada',
    })
    .set('Authorization', 'Bearer admin-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.name, 'Imagen administrada');
});

test('DELETE /api/images/:id returns 404 when another user tries to delete the image', async () => {
  const response = await request(buildApp())
    .delete('/api/images/11111111-1111-4111-8111-111111111111')
    .set('Authorization', 'Bearer other-token');

  assert.equal(response.status, 404);
  assert.equal(response.body.error.code, 'IMAGE_NOT_FOUND');
});

test('DELETE /api/images/:id performs a soft delete', async () => {
  const response = await request(buildApp())
    .delete('/api/images/11111111-1111-4111-8111-111111111111')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body, {
    data: { id: '11111111-1111-4111-8111-111111111111', deleted: true },
  });
});

test('invalid image input returns a consistent 400 JSON error', async () => {
  const response = await request(buildApp())
    .post('/api/images')
    .field('name', 'Imagen sin archivo')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 400);
  assert.deepEqual(response.body, {
    error: {
      code: 'VALIDATION_ERROR',
      message: 'file is required',
    },
  });
});

test('protected image endpoint rejects requests without a token', async () => {
  const response = await request(buildApp()).get('/api/images');

  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'UNAUTHORIZED');
});

test('protected image endpoint rejects an invalid token', async () => {
  const response = await request(buildApp())
    .get('/api/images')
    .set('Authorization', 'Bearer invalid-token');

  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'INVALID_TOKEN');
});

test('repository failures return a consistent 500 JSON error', async () => {
  const failingService: ImageServicePort = {
    create: async () => { throw new Error('not used'); },
    findVisible: async () => { throw new Error('database unavailable'); },
    findById: async () => null,
    updateMetadata: async () => { throw new Error('not used'); },
    softDelete: async () => { throw new Error('not used'); },
  };

  const response = await request(buildApp(failingService))
    .get('/api/images')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 500);
  assert.deepEqual(response.body, {
    error: {
      code: 'INTERNAL_ERROR',
      message: 'Internal server error',
    },
  });
});

class FakeImageService implements ImageServicePort {
  async create(input: CreateImageInput, file: ImageFile): Promise<ImageModel> {
    return new ImageModel({
      ...sampleImage(),
      id: 'created-image',
      ownerId: input.ownerId,
      name: input.name,
      alt: input.alt,
      description: input.description,
      mimeType: file.contentType,
      extension: file.extension,
      sizeBytes: file.bytes.length,
      originalFilename: input.originalFilename,
    });
  }

  async findVisible(actor: ImageActor): Promise<ImageModel[]> {
    if (actor.role === UserRole.ADMIN) return [sampleImage()];
    return [sampleImage()];
  }

  async findById(id: string, actor: ImageActor): Promise<ImageModel | null> {
    if (id !== '11111111-1111-4111-8111-111111111111') return null;
    return actor.role === UserRole.ADMIN || actor.id === 'owner-1'
      ? sampleImage()
      : null;
  }

  async updateMetadata(
    _id: string,
    actor: ImageActor,
    values: Pick<ImageModel, 'name' | 'alt' | 'description'>,
  ): Promise<ImageModel> {
    if (actor.role !== UserRole.ADMIN && actor.id !== 'owner-1') {
      throw new AppError('Image not found', 404, 'IMAGE_NOT_FOUND');
    }
    return new ImageModel({ ...sampleImage(), ...values });
  }

  async softDelete(_id: string, actor: ImageActor): Promise<void> {
    if (actor.role !== UserRole.ADMIN && actor.id !== 'owner-1') {
      throw new AppError('Image not found', 404, 'IMAGE_NOT_FOUND');
    }
  }
}

class FakeWeatherService implements WeatherServicePort {
  async getForImage(id: string): Promise<ImageWeatherModel> {
    if (id === '22222222-2222-4222-8222-222222222222') {
      throw new AppError('Image not found', 404, 'IMAGE_NOT_FOUND');
    }
    if (id === '33333333-3333-4333-8333-333333333333') {
      throw new AppError(
        'Image has no geographic coordinates',
        400,
        'IMAGE_COORDINATES_REQUIRED',
      );
    }
    return {
      imageId: id,
      provider: 'open-meteo',
      coordinates: { latitude: -0.18, longitude: -78.48 },
      providerCoordinates: { latitude: -0.18, longitude: -78.48 },
      timezone: 'America/Guayaquil',
      observedAt: '2026-09-21T12:00',
      current: {
        temperature: { value: 18.5, unit: '°C' },
        apparentTemperature: { value: 18.1, unit: '°C' },
        relativeHumidity: { value: 72, unit: '%' },
        precipitation: { value: 0, unit: 'mm' },
        windSpeed: { value: 8, unit: 'km/h' },
        weatherCode: 2,
        isDay: true,
      },
    };
  }
}

class FakeJwtVerifier implements JwtVerifier {
  async verify(token: string): Promise<JwtUser> {
    if (!['valid-token', 'admin-token', 'other-token'].includes(token)) {
      throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
    }
    if (token === 'admin-token') {
      return { sub: 'admin-1', email: 'admin@example.com', role: UserRole.ADMIN };
    }
    if (token === 'other-token') {
      return { sub: 'owner-2', email: 'other@example.com', role: UserRole.USER };
    }
    return { sub: 'owner-1', email: 'owner@example.com', role: UserRole.USER };
  }
}

const sampleImage = (): ImageModel => {
  const timestamp = new Date('2026-09-21T12:00:00.000Z');
  return new ImageModel({
    id: '11111111-1111-4111-8111-111111111111',
    ownerId: 'owner-1',
    name: 'Imagen',
    src: 'https://example.test/image.png',
    storagePath: 'owner-1/image-1.png',
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
    createdAt: timestamp,
    updatedAt: timestamp,
    isVisible: true,
    deletedAt: null,
  });
};
