import type { ErrorRequestHandler } from 'express';
import { AppError } from '../models/app-error.model.js';
import { EntityNotFoundError } from '../models/not-found-error.model.js';

interface RequestParsingError extends Error {
  type?: string;
  code?: string;
}

const isRequestParsingError = (
  error: unknown,
): error is RequestParsingError => {
  if (!(error instanceof Error)) return false;
  const candidate = error as RequestParsingError;
  return candidate.type === 'entity.parse.failed' ||
    candidate.type === 'entity.too.large' ||
    candidate.code === 'LIMIT_FILE_SIZE' ||
    candidate.code === 'LIMIT_UNEXPECTED_FILE';
};

export const errorMiddleware: ErrorRequestHandler = (
  error,
  _request,
  response,
  _next,
) => {
  const appError = error instanceof AppError ? error : null;
  const notFoundError = error instanceof EntityNotFoundError ? error : null;
  const parsingError = isRequestParsingError(error) ? error : null;
  const isTooLarge = parsingError?.type === 'entity.too.large' ||
    parsingError?.code === 'LIMIT_FILE_SIZE';
  const statusCode = appError?.statusCode ??
    (notFoundError ? 404 : parsingError ? (isTooLarge ? 413 : 400) : 500);
  const code = appError?.code ??
    (notFoundError ? 'NOT_FOUND' : parsingError
      ? (isTooLarge ? 'PAYLOAD_TOO_LARGE' : 'INVALID_REQUEST')
      : 'INTERNAL_ERROR');
  const message = appError?.message ?? notFoundError?.message ??
    (parsingError?.type === 'entity.parse.failed'
      ? 'Request body is not valid JSON'
      : isTooLarge
        ? 'Request payload is too large'
        : parsingError?.code === 'LIMIT_UNEXPECTED_FILE'
          ? 'Unexpected upload field'
          : 'Internal server error');

  if (statusCode >= 500) {
    const safeError = error instanceof Error ? error.name : 'Unknown error';
    console.error(`[api] ${safeError}`);
  }

  response.status(statusCode).json({
    error: {
      code,
      message,
    },
  });
};
