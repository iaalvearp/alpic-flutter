import type { Context } from 'hono';
import { HealthService } from '../services/health.service.js';

export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  getHealth = (c: Context) => {
    return c.json(this.healthService.getStatus());
  };
}
