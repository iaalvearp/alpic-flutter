import assert from 'node:assert/strict';
import express from 'express';
import { test } from 'node:test';
import request from 'supertest';
import { errorMiddleware } from '../middleware/error.middleware.js';
import { AppError } from '../models/app-error.model.js';
import { UserRole, type AuthSessionModel } from '../models/user.model.js';
import { createAuthRouter } from './auth.routes.js';
import type {
  AuthServicePort,
} from '../services/auth.service.js';
import type { JwtUser, JwtVerifier } from '../middleware/auth.middleware.js';

const buildApp = (): express.Express => {
  const app = express();
  app.use(express.json());
  app.use(createAuthRouter(new FakeAuthService(), new FakeJwtVerifier()));
  app.use(errorMiddleware);
  return app;
};

test('POST /api/auth/register registers a valid user', async () => {
  const response = await request(buildApp())
    .post('/api/auth/register')
    .send({ email: 'new@example.com', password: 'correct-password' });

  assert.equal(response.status, 201);
  assert.equal(response.body.data.user.email, 'new@example.com');
  assert.equal(response.body.data.tokenType, 'Bearer');
  assert.equal(response.body.data.accessToken, 'valid-token');
  assert.equal(response.body.data.user.password, undefined);
});

test('POST /api/auth/login returns a JWT for valid credentials', async () => {
  const response = await request(buildApp())
    .post('/api/auth/login')
    .send({ email: 'user@example.com', password: 'correct-password' });

  assert.equal(response.status, 200);
  assert.equal(response.body.data.accessToken, 'valid-token');
});

test('POST /api/auth/login rejects invalid credentials', async () => {
  const response = await request(buildApp())
    .post('/api/auth/login')
    .send({ email: 'user@example.com', password: 'wrong-password' });

  assert.equal(response.status, 401);
  assert.deepEqual(response.body, {
    error: {
      code: 'INVALID_CREDENTIALS',
      message: 'Invalid credentials',
    },
  });
});

test('POST /api/auth/login rejects malformed credential bodies with 400', async () => {
  const response = await request(buildApp())
    .post('/api/auth/login')
    .set('Content-Type', 'application/json')
    .send('null');

  assert.equal(response.status, 400);
  assert.deepEqual(response.body, {
    error: {
      code: 'INVALID_REQUEST',
      message: 'Request body is not valid JSON',
    },
  });
});

test('GET /api/auth/me returns the authenticated user with a valid token', async () => {
  const response = await request(buildApp())
    .get('/api/auth/me')
    .set('Authorization', 'Bearer valid-token');

  assert.equal(response.status, 200);
  assert.deepEqual(response.body.data, {
    id: 'user-1',
    email: 'user@example.com',
    createdAt: null,
    role: 'USER',
  });
});

test('GET /api/auth/me rejects a request without a token', async () => {
  const response = await request(buildApp()).get('/api/auth/me');

  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'UNAUTHORIZED');
});

test('GET /api/auth/me rejects an invalid token', async () => {
  const response = await request(buildApp())
    .get('/api/auth/me')
    .set('Authorization', 'Bearer invalid-token');

  assert.equal(response.status, 401);
  assert.equal(response.body.error.code, 'INVALID_TOKEN');
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
    if (token !== 'valid-token') {
      throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
    }
    return { sub: 'user-1', email: 'user@example.com' };
  }
}

class FakeJwtVerifier implements JwtVerifier {
  constructor(private readonly service = new FakeAuthService()) {}

  verify(token: string): Promise<JwtUser> {
    return this.service.verifyToken(token);
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
