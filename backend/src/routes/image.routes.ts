import { Hono } from 'hono';
import type { ImageController } from '../controllers/image.controller.js';
import type { WeatherController } from '../controllers/weather.controller.js';
import type { createAuthMiddleware } from '../middleware/auth.middleware.js';

export const createImageRoutes = (
  imageController: ImageController,
  weatherController: WeatherController,
  authMiddleware: ReturnType<typeof createAuthMiddleware>,
) => {
  const app = new Hono();

  app.post('/', authMiddleware, (c) => imageController.create(c));
  app.get('/', authMiddleware, (c) => imageController.list(c));
  app.get('/:id', authMiddleware, (c) => imageController.getById(c));
  app.patch('/:id', authMiddleware, (c) => imageController.update(c));
  app.delete('/:id', authMiddleware, (c) => imageController.remove(c));

  app.get('/:id/weather', authMiddleware, (c) => weatherController.getForImage(c));

  return app;
};
