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

    if (origin) {
      const allowed = origins.includes('*') ? origin : (origins.includes(origin) ? origin : origin);
      c.header('Access-Control-Allow-Origin', allowed);
    }

    c.header('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    c.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    c.header('Access-Control-Expose-Headers', 'Content-Length');
    c.header('Access-Control-Max-Age', '86400');

    if (c.req.method === 'OPTIONS') {
      return new Response(null, { status: 204 });
    }

    await next();
  };
};
