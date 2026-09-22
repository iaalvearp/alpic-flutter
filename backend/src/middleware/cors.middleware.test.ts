import assert from 'node:assert/strict';
import { describe, it } from 'vitest';
import { Hono } from 'hono';
import { createCorsMiddleware } from './cors.middleware.js';

describe('CORS middleware', () => {
  const createTestApp = (origins: string) => {
    const env = {
      corsOrigins: origins,
    } as any;
    const app = new Hono();
    app.use('*', createCorsMiddleware(env));
    app.get('/health', (c) => c.json({ ok: true }));
    return app;
  };

  it('allows configured origins', async () => {
    const app = createTestApp('http://localhost:8080');
    const req = new Request('http://localhost/health', {
      headers: { Origin: 'http://localhost:8080' },
    });
    const res = await app.fetch(req);
    assert.equal(res.status, 200);
    assert.equal(res.headers.get('access-control-allow-origin'), 'http://localhost:8080');
  });

  it('rejects unconfigured browser origins', async () => {
    const app = createTestApp('http://localhost:8080');
    const req = new Request('http://localhost/health', {
      headers: { Origin: 'https://malicious.example' },
    });
    const res = await app.fetch(req);
    assert.equal(res.status, 403);
  });
});
