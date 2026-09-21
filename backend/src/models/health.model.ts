export type HealthStatus = 'ok';

export interface HealthModel {
  status: HealthStatus;
  service: string;
  environment: string;
  timestamp: string;
  uptime: number;
}
