import type { ErrorHandler } from 'hono';
import { AppError } from '../models/app-error.model.js';
import { EntityNotFoundError } from '../models/not-found-error.model.js';
import { PersistenceError } from '../models/persistence-error.model.js';

export const errorHandler: ErrorHandler = (error, c) => {
  if (error instanceof AppError) {
    return c.json(
      {
        error: {
          code: error.code,
          message: error.message,
          details: error.details,
        },
      },
      error.statusCode as any,
    );
  }

  if (error instanceof EntityNotFoundError) {
    return c.json(
      {
        error: {
          code: 'NOT_FOUND',
          message: error.message,
        },
      },
      404,
    );
  }

  if (error instanceof PersistenceError) {
    console.error('Persistence error:', error.message, error.cause);
    return c.json(
      {
        error: {
          code: 'PERSISTENCE_ERROR',
          message: 'An internal storage error occurred',
          details: error.cause instanceof Error ? error.cause.message : String(error.cause),
        },
      },
      500,
    );
  }

  console.error('Unhandled error:', error);
  return c.json(
    {
      error: {
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
      },
    },
    500,
  );
};
