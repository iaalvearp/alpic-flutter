import type { Context, Next } from 'hono';
import { AppError } from '../models/app-error.model.js';
import { UserRole } from '../models/user.model.js';

export const requireRole = (...roles: UserRole[]) => {
  return async (c: Context, next: Next) => {
    const user = c.get('user');
    if (!user) {
      throw new AppError('Authentication required', 401, 'UNAUTHORIZED');
    }
    if (!user.role || !roles.includes(user.role)) {
      throw new AppError('Insufficient permissions', 403, 'FORBIDDEN');
    }
    await next();
  };
};
