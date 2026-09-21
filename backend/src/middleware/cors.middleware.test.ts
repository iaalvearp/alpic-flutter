import assert from 'node:assert/strict';
import express from 'express';
import { test } from 'node:test';
import request from 'supertest';
import { createCorsMiddleware } from './cors.middleware.js';
import { errorMiddleware } from './error.middleware.js';

const buildApp = (): express.Express => {
  const app = express();
  app.use(createCorsMiddleware(['http://localhost:8080']));
  app.get('/health', (_request, response) => response.json({ ok: true }));
  app.use(errorMiddleware);
  return app;
};

test('CORS allows configured origins and handles preflight', async () => {
  const response = await request(buildApp())
    .options('/health')
    .set('Origin', 'http://localhost:8080')
    .set('Access-Control-Request-Method', 'GET');

  assert.equal(response.status, 204);
  assert.equal(response.headers['access-control-allow-origin'], 'http://localhost:8080');
});

test('CORS rejects unconfigured browser origins', async () => {
  const response = await request(buildApp())
    .get('/health')
    .set('Origin', 'https://malicious.example');

  assert.equal(response.status, 403);
  assert.deepEqual(response.body, {
    error: {
      code: 'CORS_ORIGIN_NOT_ALLOWED',
      message: 'Origin is not allowed',
    },
  });
});
