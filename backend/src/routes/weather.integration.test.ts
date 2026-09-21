import assert from 'node:assert/strict';
import express from 'express';
import { test } from 'node:test';
import request from 'supertest';
import { OpenMeteoWeatherClient } from '../integrations/open-meteo.client.js';
import { errorMiddleware } from '../middleware/error.middleware.js';
import type { JwtUser, JwtVerifier } from '../middleware/auth.middleware.js';
import {
  ImageModel,
  type CreateImageInput,
  type ImageFile,
} from '../models/image.model.js';
import { UserRole } from '../models/user.model.js';
import { createImageRouter } from './image.routes.js';
import type { ImageServicePort } from '../services/image.service.js';

const canRun = process.env.RUN_EXTERNAL_INTEGRATION === 'true';

test('weather endpoint reaches the real Open-Meteo API', {
  skip: canRun ? false : 'RUN_EXTERNAL_INTEGRATION is not true',
}, async () => {
  const app = express();
  app.use(express.json());
  app.use(createImageRouter(
    new CoordinateImageService(),
    new IntegrationJwtVerifier(),
    undefined,
    new OpenMeteoWeatherClient(),
  ));
  app.use(errorMiddleware);

  const response = await request(app)
    .get('/api/images/11111111-1111-4111-8111-111111111111/weather')
    .set('Authorization', 'Bearer integration-token');

  assert.equal(response.status, 200);
  assert.equal(response.body.data.provider, 'open-meteo');
  assert.equal(typeof response.body.data.current.temperature.value, 'number');
  assert.equal(typeof response.body.data.current.weatherCode, 'number');
});

class IntegrationJwtVerifier implements JwtVerifier {
  async verify(_token: string): Promise<JwtUser> {
    return {
      sub: 'owner-1',
      email: 'owner@example.com',
      role: UserRole.USER,
    };
  }
}

class CoordinateImageService implements ImageServicePort {
  async create(_input: CreateImageInput, _file: ImageFile): Promise<ImageModel> {
    throw new Error('not used');
  }

  async findVisible(): Promise<ImageModel[]> {
    return [];
  }

  async findById(): Promise<ImageModel> {
    return new ImageModel({
      id: '11111111-1111-4111-8111-111111111111',
      ownerId: 'owner-1',
      name: 'Imagen con coordenadas',
      src: null,
      storagePath: null,
      alt: 'Alt',
      description: 'Descripción',
      mimeType: 'image/png',
      extension: 'png',
      sizeBytes: 3,
      latitude: -0.18,
      longitude: -78.48,
      mapsUrl: null,
      source: 'gallery',
      originalFilename: 'foto.png',
      createdAt: new Date(),
      updatedAt: new Date(),
      isVisible: true,
      deletedAt: null,
    });
  }

  async updateMetadata(): Promise<ImageModel> {
    throw new Error('not used');
  }

  async softDelete(): Promise<void> {
    throw new Error('not used');
  }
}
