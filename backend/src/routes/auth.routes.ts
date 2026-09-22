import { Hono } from 'hono';
import type { AuthController } from '../controllers/auth.controller.js';
import { createAuthMiddleware } from '../middleware/auth.middleware.js';

export const createAuthRoutes = (controller: AuthController, authMiddleware: ReturnType<typeof createAuthMiddleware>) => {
  const app = new Hono();

  app.post('/register', (c) => controller.register(c));
  app.post('/login', (c) => controller.login(c));
  app.get('/me', authMiddleware, (c) => controller.me(c));

  return app;
};
