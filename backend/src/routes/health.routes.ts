import { Router } from 'express';
import { HealthController } from '../controllers/health.controller.js';
import { HealthService } from '../services/health.service.js';

const healthController = new HealthController(new HealthService());
export const healthRouter = Router();

healthRouter.get('/health', healthController.getHealth);
