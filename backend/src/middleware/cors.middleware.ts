import type { MiddlewareHandler } from 'hono';
import type { AppEnv } from '../config/env.js';

export const createCorsMiddleware = (env: AppEnv): MiddlewareHandler => {
  const origins = env.corsOrigins
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  return async (c, next) => {
    const origin = c.req.header('Origin');

    if (origin && origins.length > 0 && !origins.includes('*') && !origins.includes(origin)) {
      return c.json(
        { error: { code: 'CORS_ORIGIN_NOT_ALLOWED', message: 'Origin is not allowed' } },
        403,
      );
    }

    const headers: Record<string, string> = {};

    if (origin) {
      headers['Access-Control-Allow-Origin'] = origins.includes('*') ? '*' : origin;
      headers['Vary'] = 'Origin';
    }

    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS';
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
    headers['Access-Control-Expose-Headers'] = 'Content-Length';
    headers['Access-Control-Max-Age'] = '86400';

    if (c.req.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers });
    }

    for (const [key, value] of Object.entries(headers)) {
      c.header(key, value);
    }

    await next();
  };
};
