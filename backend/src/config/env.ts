export interface Env {
  NODE_ENV: string;
  API_PREFIX: string;
  SUPABASE_URL: string;
  SUPABASE_SERVICE_ROLE_KEY: string;
  SUPABASE_STORAGE_BUCKET: string;
  CORS_ORIGINS: string;
  OPEN_METEO_BASE_URL: string;
  EXTERNAL_API_TIMEOUT_MS: string;
}

export const getEnv = (env: Env) => ({
  nodeEnv: env.NODE_ENV ?? 'development',
  apiPrefix: env.API_PREFIX ?? '/api/v1',
  supabaseUrl: env.SUPABASE_URL,
  supabaseServiceRoleKey: env.SUPABASE_SERVICE_ROLE_KEY,
  supabaseStorageBucket: env.SUPABASE_STORAGE_BUCKET ?? 'alpics-images',
  corsOrigins: env.CORS_ORIGINS ?? '',
  openMeteoBaseUrl: env.OPEN_METEO_BASE_URL ?? 'https://api.open-meteo.com/v1/forecast',
  externalApiTimeoutMs: parseInt(env.EXTERNAL_API_TIMEOUT_MS ?? '5000', 10),
});

export type AppEnv = ReturnType<typeof getEnv>;
