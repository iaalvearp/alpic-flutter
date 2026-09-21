import 'dotenv/config';

const parsePort = (value: string | undefined): number => {
  const port = Number(value ?? 3000);

  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('PORT must be an integer between 1 and 65535');
  }

  return port;
};

const parsePositiveInteger = (
  value: string | undefined,
  fallback: number,
): number => {
  const parsed = Number(value ?? fallback);
  if (!Number.isInteger(parsed) || parsed < 1) {
    throw new Error('EXTERNAL_API_TIMEOUT_MS must be a positive integer');
  }
  return parsed;
};

const parseOrigins = (value: string | undefined): readonly string[] =>
  Object.freeze(
    (value ?? '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
  );

const parseHttpUrl = (
  value: string | undefined,
  field: string,
  fallback?: string,
): string | undefined => {
  const candidate = value ?? fallback;
  if (candidate === undefined || candidate === '') return undefined;

  let url: URL;
  try {
    url = new URL(candidate);
  } catch {
    throw new Error(`${field} must be a valid URL`);
  }
  if (!['http:', 'https:'].includes(url.protocol)) {
    throw new Error(`${field} must use HTTP or HTTPS`);
  }
  return url.toString();
};

export const env = Object.freeze({
  nodeEnv: process.env.NODE_ENV ?? 'development',
  host: process.env.HOST ?? '127.0.0.1',
  port: parsePort(process.env.PORT),
  apiPrefix: process.env.API_PREFIX ?? '/api/v1',
  supabaseUrl: process.env.SUPABASE_URL,
  supabaseServiceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  supabaseStorageBucket: process.env.SUPABASE_STORAGE_BUCKET ?? 'alpics-images',
  jwtIssuer: process.env.JWT_ISSUER,
  jwtAudience: process.env.JWT_AUDIENCE,
  corsOrigins: parseOrigins(process.env.CORS_ORIGINS),
  externalApiBaseUrl: parseHttpUrl(
    process.env.EXTERNAL_API_BASE_URL,
    'EXTERNAL_API_BASE_URL',
  ),
  openMeteoBaseUrl: parseHttpUrl(
    process.env.OPEN_METEO_BASE_URL,
    'OPEN_METEO_BASE_URL',
    'https://api.open-meteo.com/v1/forecast',
  ) as string,
  externalApiTimeoutMs: parsePositiveInteger(
    process.env.EXTERNAL_API_TIMEOUT_MS,
    5000,
  ),
});
