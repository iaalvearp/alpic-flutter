import type { HealthResponseDto } from '../dtos/health-response.dto.js';

export class HealthService {
  getStatus(): HealthResponseDto {
    return {
      status: 'ok',
      service: 'alpic-backend',
      environment: 'cloudflare-workers',
      timestamp: new Date().toISOString(),
      uptime: 0,
    };
  }
}
