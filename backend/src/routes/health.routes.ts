import { Hono } from 'hono';
import type { HealthController } from '../controllers/health.controller.js';

export const createHealthRoutes = (controller: HealthController) => {
  const app = new Hono();
  app.get('/', (c) => controller.getHealth(c));
  return app;
};
