import { env } from '../config/env.js';
import type { HealthResponseDto } from '../dtos/health-response.dto.js';

export class HealthService {
  getStatus(): HealthResponseDto {
    return {
      status: 'ok',
      service: 'alpic-backend',
      environment: env.nodeEnv,
      timestamp: new Date().toISOString(),
      uptime: Math.floor(process.uptime()),
    };
  }
}
