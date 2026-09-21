import type { RequestHandler } from 'express';
import { AppError } from '../models/app-error.model.js';
import type { UserRole } from '../models/user.model.js';

export interface JwtUser {
  sub: string;
  email?: string;
  role?: UserRole;
  [claim: string]: unknown;
}

export interface JwtVerifier {
  verify(token: string): Promise<JwtUser>;
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtUser;
    }
  }
}

const bearerToken = (authorization: string | undefined): string => {
  const match = /^Bearer\s+(.+)$/i.exec(authorization ?? '');
  if (!match?.[1]) {
    throw new AppError('A Bearer token is required', 401, 'UNAUTHORIZED');
  }
  const token = match[1].trim();
  if (!token || token.length > 4096 || /\s/.test(token)) {
    throw new AppError('Invalid Bearer token', 401, 'INVALID_TOKEN');
  }
  return token;
};

/**
 * Authentication middleware: extracts the Bearer token, verifies it and
 * attaches the authenticated identity to the request.
 */
export const createJwtMiddleware = (
  verifier: JwtVerifier,
): RequestHandler => (request, _response, next) => {
  try {
    const token = bearerToken(request.header('authorization'));
    verifier
      .verify(token)
      .then((user) => {
        if (!user || typeof user.sub !== 'string' || user.sub.trim() === '') {
          throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
        }
        request.user = user;
        next();
      })
      .catch(next);
  } catch (error) {
    next(error);
  }
};
