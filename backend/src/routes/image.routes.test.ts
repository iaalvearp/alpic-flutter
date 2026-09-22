import assert from 'node:assert/strict';
import { describe, it } from 'vitest';
import { Hono } from 'hono';
import { errorHandler } from '../middleware/error.middleware.js';
import { AppError } from '../models/app-error.model.js';
import {
  ImageModel,
  type CreateImageInput,
  type ImageFile,
} from '../models/image.model.js';
import { UserRole, type ImageActor, type AuthSessionModel } from '../models/user.model.js';
import { ImageController } from '../controllers/image.controller.js';
import { WeatherController } from '../controllers/weather.controller.js';
import { createImageRoutes } from './image.routes.js';
import type { ImageServicePort } from '../services/image.service.js';
import type { WeatherServicePort } from '../services/weather.service.js';
import type { ImageWeatherModel } from '../models/weather.model.js';
import type { JwtUser } from '../middleware/auth.middleware.js';
import { createAuthMiddleware } from '../middleware/auth.middleware.js';
import type { AuthServicePort } from '../services/auth.service.js';

const createTestApp = (
  service: ImageServicePort = new FakeImageService(),
  weatherService: WeatherServicePort = new FakeWeatherService(),
  authService: AuthServicePort = new FakeAuthService(),
) => {
  const app = new Hono();
  app.onError(errorHandler);

  const env = {
    NODE_ENV: 'development',
    API_PREFIX: '/api/v1',
    SUPABASE_URL: 'https://test.supabase.co',
    SUPABASE_SERVICE_ROLE_KEY: 'test-key',
    SUPABASE_STORAGE_BUCKET: 'test-bucket',
    CORS_ORIGINS: '*',
    OPEN_METEO_BASE_URL: 'https://api.open-meteo.com/v1/forecast',
    EXTERNAL_API_TIMEOUT_MS: '5000',
  } as any;

  app.use('*', async (c, next) => {
    c.set('appEnv', env);
    c.set('authService', authService);
    await next();
  });

  const imageController = new ImageController(service);
  const weatherController = new WeatherController(weatherService);
  const authMiddleware = createAuthMiddleware(authService);
  app.route('/api/images', createImageRoutes(imageController, weatherController, authMiddleware));

  return app;
};

const createFormData = (fields: Record<string, string>, file?: File): FormData => {
  const formData = new FormData();
  for (const [key, value] of Object.entries(fields)) {
    formData.append(key, value);
  }
  if (file) {
    formData.append('file', file);
  }
  return formData;
};

const createFile = (name: string, type: string, size: number): File => {
  const buffer = new ArrayBuffer(size);
  return new File([buffer], name, { type });
};

describe('Image routes', () => {
  it('POST /api/images creates an image from multipart data', async () => {
    const app = createTestApp();
    const formData = createFormData(
      {
        name: 'Imagen nueva',
        alt: 'Texto alternativo',
        description: 'Descripción',
        source: 'gallery',
      },
      createFile('foto.png', 'image/png', 3),
    );

    const res = await app.fetch(
      new Request('http://localhost/api/images', {
        method: 'POST',
        headers: { Authorization: 'Bearer valid-token' },
        body: formData,
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 201);
    assert.equal((body.data as Record<string, unknown>).name, 'Imagen nueva');
    assert.equal((body.data as Record<string, unknown>).originalFilename, 'foto.png');
  });

  it('GET /api/images returns visible images for an owner', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    assert.equal((body.data as unknown[]).length, 1);
    assert.equal(((body.data as unknown[])[0] as Record<string, unknown>).ownerId, 'owner-1');
  });

  it('GET /api/images/:id returns one image', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    assert.equal((body.data as Record<string, unknown>).id, '11111111-1111-4111-8111-111111111111');
  });

  it('GET /api/images/:id rejects a malformed ID before persistence', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/not-a-uuid', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 400);
    assert.deepEqual(body, {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'id must be a valid UUID',
      },
    });
  });

  it('GET /api/images/:id/weather returns current weather JSON', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111/weather', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    const data = body.data as Record<string, unknown>;
    assert.equal(data.imageId, '11111111-1111-4111-8111-111111111111');
    assert.equal(data.provider, 'open-meteo');
    const current = data.current as Record<string, unknown>;
    const temp = current.temperature as Record<string, unknown>;
    assert.equal(temp.value, 18.5);
  });

  it('GET /api/images/:id/weather returns 404 for a missing image', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/22222222-2222-4222-8222-222222222222/weather', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 404);
    assert.equal((body.error as Record<string, unknown>).code, 'IMAGE_NOT_FOUND');
  });

  it('GET /api/images/:id/weather returns 400 without coordinates', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/33333333-3333-4333-8333-333333333333/weather', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 400);
    assert.equal((body.error as Record<string, unknown>).code, 'IMAGE_COORDINATES_REQUIRED');
  });

  it('GET /api/images/:id/weather requires authentication', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111/weather'),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 401);
    assert.equal((body.error as Record<string, unknown>).code, 'UNAUTHORIZED');
  });

  it('GET /api/images/:id returns 404 when the image does not exist', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/22222222-2222-4222-8222-222222222222', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 404);
    assert.deepEqual(body, {
      error: {
        code: 'IMAGE_NOT_FOUND',
        message: 'Image not found',
      },
    });
  });

  it('GET /api/images/:id returns 404 when the image belongs to another user', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111', {
        headers: { Authorization: 'Bearer other-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 404);
    assert.equal((body.error as Record<string, unknown>).code, 'IMAGE_NOT_FOUND');
  });

  it('PATCH /api/images/:id returns 404 when another user tries to modify the image', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer other-token',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: 'Cambio no permitido',
          alt: 'Alt no permitido',
          description: 'Descripción no permitida',
        }),
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 404);
    assert.equal((body.error as Record<string, unknown>).code, 'IMAGE_NOT_FOUND');
  });

  it('PATCH /api/images/:id updates image metadata', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer valid-token',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: 'Imagen editada',
          alt: 'Alt editado',
          description: 'Descripción editada',
        }),
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    assert.equal((body.data as Record<string, unknown>).name, 'Imagen editada');
  });

  it('ADMIN can modify an image owned by another user', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111', {
        method: 'PATCH',
        headers: {
          Authorization: 'Bearer admin-token',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: 'Imagen administrada',
          alt: 'Alt administrado',
          description: 'Descripción administrada',
        }),
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    assert.equal((body.data as Record<string, unknown>).name, 'Imagen administrada');
  });

  it('DELETE /api/images/:id returns 404 when another user tries to delete the image', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111', {
        method: 'DELETE',
        headers: { Authorization: 'Bearer other-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 404);
    assert.equal((body.error as Record<string, unknown>).code, 'IMAGE_NOT_FOUND');
  });

  it('DELETE /api/images/:id performs a soft delete', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images/11111111-1111-4111-8111-111111111111', {
        method: 'DELETE',
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    assert.deepEqual(body, {
      data: { id: '11111111-1111-4111-8111-111111111111', deleted: true },
    });
  });

  it('invalid image input returns a consistent 400 JSON error', async () => {
    const app = createTestApp();
    const formData = createFormData({
      name: 'Imagen sin archivo',
    });

    const res = await app.fetch(
      new Request('http://localhost/api/images', {
        method: 'POST',
        headers: { Authorization: 'Bearer valid-token' },
        body: formData,
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 400);
    assert.deepEqual(body, {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'file is required',
      },
    });
  });

  it('protected image endpoint rejects requests without a token', async () => {
    const app = createTestApp();
    const res = await app.fetch(new Request('http://localhost/api/images'));
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 401);
    assert.equal((body.error as Record<string, unknown>).code, 'UNAUTHORIZED');
  });

  it('protected image endpoint rejects an invalid token', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/images', {
        headers: { Authorization: 'Bearer invalid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 401);
    assert.equal((body.error as Record<string, unknown>).code, 'INVALID_TOKEN');
  });

  it('repository failures return a consistent 500 JSON error', async () => {
    const failingService: ImageServicePort = {
      create: async () => { throw new Error('not used'); },
      findVisible: async () => { throw new Error('database unavailable'); },
      findById: async () => null,
      updateMetadata: async () => { throw new Error('not used'); },
      softDelete: async () => { throw new Error('not used'); },
    };

    const app = createTestApp(failingService);
    const res = await app.fetch(
      new Request('http://localhost/api/images', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 500);
    assert.deepEqual(body, {
      error: {
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
      },
    });
  });
});

class FakeAuthService implements AuthServicePort {
  async register(email: string, password: string): Promise<AuthSessionModel> {
    assert.equal(password, 'correct-password');
    return session(email);
  }

  async login(email: string, password: string): Promise<AuthSessionModel> {
    if (password !== 'correct-password') {
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }
    return session(email);
  }

  async verifyToken(token: string): Promise<JwtUser> {
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

const session = (email: string): AuthSessionModel => ({
  user: {
    id: 'user-1',
    email,
    createdAt: null,
    role: UserRole.USER,
  },
  accessToken: 'valid-token',
  expiresAt: null,
});

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
