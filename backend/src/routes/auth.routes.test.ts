import assert from 'node:assert/strict';
import { describe, it } from 'vitest';
import { Hono } from 'hono';
import { errorHandler } from '../middleware/error.middleware.js';
import { AppError } from '../models/app-error.model.js';
import { UserRole, type AuthSessionModel } from '../models/user.model.js';
import { AuthController } from '../controllers/auth.controller.js';
import type { AuthServicePort } from '../services/auth.service.js';
import type { JwtUser } from '../middleware/auth.middleware.js';
import { createAuthMiddleware } from '../middleware/auth.middleware.js';
import { createAuthRoutes } from './auth.routes.js';

const createTestApp = (authService: AuthServicePort = new FakeAuthService()) => {
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

  const controller = new AuthController(authService);
  const authMiddleware = createAuthMiddleware(authService);
  app.route('/api/auth', createAuthRoutes(controller, authMiddleware));

  return app;
};

describe('Auth routes', () => {
  it('POST /api/auth/register registers a valid user', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/auth/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'new@example.com', password: 'correct-password' }),
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 201);
    const data = body.data as Record<string, unknown>;
    const user = data.user as Record<string, unknown>;
    assert.equal(user.email, 'new@example.com');
    assert.equal(data.tokenType, 'Bearer');
    assert.equal(data.accessToken, 'valid-token');
  });

  it('POST /api/auth/login returns a JWT for valid credentials', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'user@example.com', password: 'correct-password' }),
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    assert.equal((body.data as Record<string, unknown>).accessToken, 'valid-token');
  });

  it('POST /api/auth/login rejects invalid credentials', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: 'user@example.com', password: 'wrong-password' }),
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 401);
    assert.deepEqual(body, {
      error: {
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid credentials',
      },
    });
  });

  it('POST /api/auth/login rejects malformed credential bodies with 400', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: 'null',
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 400);
    assert.deepEqual(body, {
      error: {
        code: 'VALIDATION_ERROR',
        message: 'request body must be a JSON object',
      },
    });
  });

  it('GET /api/auth/me returns the authenticated user with a valid token', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/auth/me', {
        headers: { Authorization: 'Bearer valid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 200);
    assert.deepEqual(body.data, {
      id: 'user-1',
      email: 'user@example.com',
      createdAt: null,
      role: 'USER',
    });
  });

  it('GET /api/auth/me rejects a request without a token', async () => {
    const app = createTestApp();
    const res = await app.fetch(new Request('http://localhost/api/auth/me'));
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 401);
    const error = body.error as Record<string, unknown>;
    assert.equal(error.code, 'UNAUTHORIZED');
  });

  it('GET /api/auth/me rejects an invalid token', async () => {
    const app = createTestApp();
    const res = await app.fetch(
      new Request('http://localhost/api/auth/me', {
        headers: { Authorization: 'Bearer invalid-token' },
      }),
    );
    const body = await res.json() as Record<string, unknown>;

    assert.equal(res.status, 401);
    const error = body.error as Record<string, unknown>;
    assert.equal(error.code, 'INVALID_TOKEN');
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
    if (token !== 'valid-token') {
      throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
    }
    return { sub: 'user-1', email: 'user@example.com' };
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
