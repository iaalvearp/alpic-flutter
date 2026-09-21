import type { RequestHandler } from 'express';
import { AppError } from '../models/app-error.model.js';

const allowedMethods = 'GET,POST,PUT,DELETE,OPTIONS';
const allowedHeaders = 'Authorization,Content-Type';

/**
 * CORS is deny-by-default. Browser clients must explicitly configure their
 * origin through CORS_ORIGINS; native Flutter clients usually send no Origin.
 */
export const createCorsMiddleware = (
  allowedOrigins: readonly string[],
): RequestHandler => (request, response, next) => {
  const origin = request.header('origin');

  if (!origin) {
    next();
    return;
  }

  if (!allowedOrigins.includes(origin)) {
    next(new AppError('Origin is not allowed', 403, 'CORS_ORIGIN_NOT_ALLOWED'));
    return;
  }

  response.setHeader('Access-Control-Allow-Origin', origin);
  response.setHeader('Vary', 'Origin');
  response.setHeader('Access-Control-Allow-Methods', allowedMethods);
  response.setHeader('Access-Control-Allow-Headers', allowedHeaders);

  if (request.method === 'OPTIONS') {
    response.status(204).end();
    return;
  }

  next();
};
