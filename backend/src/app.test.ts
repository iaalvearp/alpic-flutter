import assert from 'node:assert/strict';
import { test } from 'node:test';
import request from 'supertest';
import { app } from './app.js';

test('GET /health returns the backend status', async () => {
  const response = await request(app).get('/health');

  assert.equal(response.status, 200);
  assert.equal(response.body.status, 'ok');
  assert.equal(response.body.service, 'alpic-backend');
  assert.equal(response.body.environment, 'development');
  assert.equal(typeof response.body.timestamp, 'string');
  assert.equal(typeof response.body.uptime, 'number');
});

test('unknown routes return the standard error shape', async () => {
  const response = await request(app).get('/missing');

  assert.equal(response.status, 404);
  assert.deepEqual(response.body, {
    error: {
      code: 'ROUTE_NOT_FOUND',
      message: 'Route not found',
    },
  });
});

test('malformed JSON returns 400 without exposing parser details', async () => {
  const response = await request(app)
    .post('/api/auth/login')
    .set('Content-Type', 'application/json')
    .send('{"email":');

  assert.equal(response.status, 400);
  assert.deepEqual(response.body, {
    error: {
      code: 'INVALID_REQUEST',
      message: 'Request body is not valid JSON',
    },
  });
});

test('the real app protects auth and image routes before Supabase access', async () => {
  const authResponse = await request(app).get('/api/auth/me');
  const imageResponse = await request(app).get('/api/images');

  assert.equal(authResponse.status, 401);
  assert.equal(authResponse.body.error.code, 'UNAUTHORIZED');
  assert.equal(imageResponse.status, 401);
  assert.equal(imageResponse.body.error.code, 'UNAUTHORIZED');
});
