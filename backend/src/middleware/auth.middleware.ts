import type { Context, Next } from 'hono';
import { AppError } from '../models/app-error.model.js';
import type { AuthServicePort } from '../services/auth.service.js';
import type { UserRole } from '../models/user.model.js';

export interface JwtUser {
  sub: string;
  email?: string;
  role?: UserRole;
}

declare module 'hono' {
  interface ContextVariableMap {
    user: JwtUser;
  }
}

export const createAuthMiddleware = (authService: AuthServicePort) => {
  return async (c: Context, next: Next) => {
    const header = c.req.header('Authorization');
    if (!header?.startsWith('Bearer ')) {
      throw new AppError('Missing or invalid Authorization header', 401, 'UNAUTHORIZED');
    }

    const token = header.slice(7);
    try {
      const user = await authService.verifyToken(token);
      c.set('user', user);
      await next();
    } catch {
      throw new AppError('Invalid or expired token', 401, 'INVALID_TOKEN');
    }
  };
};
