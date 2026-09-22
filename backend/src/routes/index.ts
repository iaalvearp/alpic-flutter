import { Hono } from 'hono';
import { createAuthRoutes } from './auth.routes.js';
import { createHealthRoutes } from './health.routes.js';
import { createImageRoutes } from './image.routes.js';
import type { HealthController } from '../controllers/health.controller.js';
import type { AuthController } from '../controllers/auth.controller.js';
import type { ImageController } from '../controllers/image.controller.js';
import type { WeatherController } from '../controllers/weather.controller.js';
import type { createAuthMiddleware } from '../middleware/auth.middleware.js';

export const createApiRoutes = (
  healthController: HealthController,
  authController: AuthController,
  imageController: ImageController,
  weatherController: WeatherController,
  authMiddleware: ReturnType<typeof createAuthMiddleware>,
) => {
  const app = new Hono();

  app.route('/health', createHealthRoutes(healthController));
  app.route('/auth', createAuthRoutes(authController, authMiddleware));
  app.route('/images', createImageRoutes(imageController, weatherController, authMiddleware));

  return app;
};
