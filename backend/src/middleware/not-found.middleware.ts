import type { RequestHandler } from 'express';
import { AppError } from '../models/app-error.model.js';

export const notFoundMiddleware: RequestHandler = (request, _response, next) => {
  next(
    new AppError(
      'Route not found',
      404,
      'ROUTE_NOT_FOUND',
    ),
  );
};
