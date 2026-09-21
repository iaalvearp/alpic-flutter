import { Router, type RequestHandler } from 'express';
import { AuthController } from '../controllers/auth.controller.js';
import { createJwtMiddleware, type JwtVerifier } from '../middleware/auth.middleware.js';
import {
  AuthService,
  createDefaultAuthService,
  SupabaseJwtVerifier,
  type AuthServicePort,
} from '../services/auth.service.js';

export const createAuthRouter = (
  service?: AuthServicePort,
  verifier?: JwtVerifier,
): Router => {
  let resolvedService = service;
  let controller: AuthController | undefined = service
    ? new AuthController(service)
    : undefined;
  let authMiddleware: RequestHandler | undefined;

  const getService = (): AuthServicePort => {
    resolvedService ??= createDefaultAuthService();
    return resolvedService;
  };

  const getController = (): AuthController => {
    controller ??= new AuthController(getService());
    return controller;
  };

  const getAuthMiddleware = (): RequestHandler => {
    authMiddleware ??= createJwtMiddleware(
      verifier ?? new SupabaseJwtVerifier(getService()),
    );
    return authMiddleware;
  };

  const router = Router();
  router.post('/api/auth/register', (request, response, next) =>
    getController().register(request, response, next),
  );
  router.post('/api/auth/login', (request, response, next) =>
    getController().login(request, response, next),
  );
  router.get(
    '/api/auth/me',
    (request, response, next) =>
      getAuthMiddleware()(request, response, next),
    (request, response, next) =>
      getController().me(request, response, next),
  );
  return router;
};
