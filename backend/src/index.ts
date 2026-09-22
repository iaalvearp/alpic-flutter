import { Hono } from 'hono';
import type { Env } from './config/env.js';
import { getEnv } from './config/env.js';
import type { AppEnv } from './config/env.js';
import { createSupabaseClient } from './config/supabase.js';
import { createCorsMiddleware } from './middleware/cors.middleware.js';
import { createAuthMiddleware } from './middleware/auth.middleware.js';
import { errorHandler } from './middleware/error.middleware.js';
import { notFoundHandler } from './middleware/not-found.middleware.js';
import { HealthController } from './controllers/health.controller.js';
import { AuthController } from './controllers/auth.controller.js';
import { ImageController } from './controllers/image.controller.js';
import { WeatherController } from './controllers/weather.controller.js';
import { HealthService } from './services/health.service.js';
import { AuthService } from './services/auth.service.js';
import { ImageService } from './services/image.service.js';
import { WeatherService } from './services/weather.service.js';
import { SupabaseAuthRepository } from './repositories/auth.repository.js';
import { SupabaseImageRepository } from './repositories/image.repository.js';
import { OpenMeteoWeatherClient } from './integrations/open-meteo.client.js';
import { swaggerHandler } from './middleware/swagger.js';
import type { AuthServicePort } from './services/auth.service.js';
import type { ImageServicePort } from './services/image.service.js';
import type { WeatherServicePort } from './services/weather.service.js';
import type { HealthService as HealthServiceType } from './services/health.service.js';

declare module 'hono' {
  interface ContextVariableMap {
    appEnv: AppEnv;
    authService: AuthServicePort;
    imageService: ImageServicePort;
    weatherService: WeatherServicePort;
    healthService: HealthServiceType;
  }
}

const app = new Hono<{ Bindings: Env }>();

app.onError(errorHandler);
app.notFound(notFoundHandler);

app.use('*', async (c, next) => {
  c.set('appEnv', getEnv(c.env));
  await next();
});

app.use('*', async (c, next) => {
  return createCorsMiddleware(c.get('appEnv'))(c, next);
});

app.get('/api/v1/docs', (c) => swaggerHandler(c));
app.get('/api/v1/docs.json', (c) => c.redirect('/api/v1/docs'));

const api = new Hono<{ Bindings: Env }>();

api.use('*', async (c, next) => {
  const env = c.get('appEnv');
  const supabase = createSupabaseClient(env);

  const authRepository = new SupabaseAuthRepository(supabase);
  const authService = new AuthService(authRepository);

  const imageRepository = new SupabaseImageRepository(supabase, env.supabaseStorageBucket);
  const imageService = new ImageService(imageRepository);

  const weatherClient = new OpenMeteoWeatherClient();
  const weatherService = new WeatherService(imageService, weatherClient);

  const healthService = new HealthService();

  c.set('authService', authService);
  c.set('imageService', imageService);
  c.set('weatherService', weatherService);
  c.set('healthService', healthService);

  await next();
});

api.get('/health', (c) => {
  const controller = new HealthController(c.get('healthService'));
  return controller.getHealth(c);
});

api.post('/auth/register', async (c) => {
  const controller = new AuthController(c.get('authService'));
  return controller.register(c);
});

api.post('/auth/login', async (c) => {
  const controller = new AuthController(c.get('authService'));
  return controller.login(c);
});

api.get('/auth/me', async (c, next) => {
  const middleware = createAuthMiddleware(c.get('authService'));
  return middleware(c, next);
}, (c) => {
  const controller = new AuthController(c.get('authService'));
  return controller.me(c);
});

api.post('/images', async (c, next) => {
  const middleware = createAuthMiddleware(c.get('authService'));
  return middleware(c, next);
}, async (c) => {
  const controller = new ImageController(c.get('imageService'));
  return controller.create(c);
});

api.get('/images', async (c, next) => {
  const middleware = createAuthMiddleware(c.get('authService'));
  return middleware(c, next);
}, async (c) => {
  const controller = new ImageController(c.get('imageService'));
  return controller.list(c);
});

api.get('/images/:id', async (c, next) => {
  const middleware = createAuthMiddleware(c.get('authService'));
  return middleware(c, next);
}, async (c) => {
  const controller = new ImageController(c.get('imageService'));
  return controller.getById(c);
});

api.patch('/images/:id', async (c, next) => {
  const middleware = createAuthMiddleware(c.get('authService'));
  return middleware(c, next);
}, async (c) => {
  const controller = new ImageController(c.get('imageService'));
  return controller.update(c);
});

api.delete('/images/:id', async (c, next) => {
  const middleware = createAuthMiddleware(c.get('authService'));
  return middleware(c, next);
}, async (c) => {
  const controller = new ImageController(c.get('imageService'));
  return controller.remove(c);
});

api.get('/images/:id/weather', async (c, next) => {
  const middleware = createAuthMiddleware(c.get('authService'));
  return middleware(c, next);
}, async (c) => {
  const controller = new WeatherController(c.get('weatherService'));
  return controller.getForImage(c);
});

app.route('/api/v1', api);

export default app;
