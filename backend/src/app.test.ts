import assert from 'node:assert/strict';
import { describe, it } from 'vitest';
import { Hono } from 'hono';
import { errorHandler } from './middleware/error.middleware.js';
import { notFoundHandler } from './middleware/not-found.middleware.js';
import { createHealthRoutes } from './routes/health.routes.js';
import { HealthController } from './controllers/health.controller.js';
import { HealthService } from './services/health.service.js';

const createTestApp = () => {
  const app = new Hono();
  app.onError(errorHandler);
  app.notFound(notFoundHandler);

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
    await next();
  });

  const healthService = new HealthService();
  const healthController = new HealthController(healthService);
  app.route('/api/v1/health', createHealthRoutes(healthController));

  return app;
};

describe('App', () => {
  it('GET /api/v1/health returns the backend status', async () => {
    const app = createTestApp();
    const res = await app.fetch(new Request('http://localhost/api/v1/health'));
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    assert.equal(body.status, 'ok');
    assert.equal(body.service, 'alpic-backend');
    assert.equal(body.environment, 'cloudflare-workers');
    assert.equal(typeof body.timestamp, 'string');
    assert.equal(typeof body.uptime, 'number');
  });

  it('unknown routes return the standard error shape', async () => {
    const app = createTestApp();
    const res = await app.fetch(new Request('http://localhost/missing'));
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 404);
    assert.deepEqual(body, {
      error: {
        code: 'NOT_FOUND',
        message: 'Route GET /missing not found',
      },
    });
  });
});
