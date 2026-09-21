import type { RequestHandler } from 'express';
import { AppError } from '../models/app-error.model.js';
import type { UserRole } from '../models/user.model.js';

/**
 * Authorization is deliberately separate from JWT authentication. The JWT
 * middleware identifies the caller; this middleware checks the allowed roles.
 */
export const requireRoles = (...allowedRoles: UserRole[]): RequestHandler =>
  (request, _response, next) => {
    const user = request.user;
    if (!user) {
      next(new AppError('Authentication required', 401, 'UNAUTHORIZED'));
      return;
    }

    if (!user.role || !allowedRoles.includes(user.role)) {
      next(new AppError('Insufficient permissions', 403, 'FORBIDDEN'));
      return;
    }

    next();
  };
