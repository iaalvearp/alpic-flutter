import multer from 'multer';
import { Router, type RequestHandler } from 'express';
import { ImageController } from '../controllers/image.controller.js';
import { WeatherController } from '../controllers/weather.controller.js';
import { createJwtMiddleware, type JwtVerifier } from '../middleware/auth.middleware.js';
import { requireRoles } from '../middleware/authorization.middleware.js';
import { AppError } from '../models/app-error.model.js';
import { UserRole } from '../models/user.model.js';
import {
  OpenMeteoWeatherClient,
  type WeatherExternalClient,
} from '../integrations/open-meteo.client.js';
import { SupabaseImageRepository } from '../repositories/image.repository.js';
import {
  ImageService,
  type ImageServicePort,
} from '../services/image.service.js';
import {
  createDefaultAuthService,
  SupabaseJwtVerifier,
} from '../services/auth.service.js';
import {
  WeatherService,
  type WeatherServicePort,
} from '../services/weather.service.js';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

const uploadSingleFile: RequestHandler = (request, response, next) => {
  upload.single('file')(request, response, (error: unknown) => {
    if (error) {
      const code = (error as { code?: unknown }).code;
      if (code === 'LIMIT_FILE_SIZE') {
        next(new AppError('Image file is too large', 413, 'UPLOAD_TOO_LARGE'));
        return;
      }
      if (code === 'LIMIT_UNEXPECTED_FILE') {
        next(new AppError('Unexpected upload field', 400, 'INVALID_UPLOAD'));
        return;
      }
      next(new AppError('Invalid image upload', 400, 'INVALID_UPLOAD'));
      return;
    }
    next();
  });
};

export const createImageRouter = (
  service?: ImageServicePort,
  verifier?: JwtVerifier,
  weatherService?: WeatherServicePort,
  weatherClient?: WeatherExternalClient,
): Router => {
  let imageService = service;
  let controller: ImageController | undefined;
  let weatherController: WeatherController | undefined;

  const getImageService = (): ImageServicePort => {
    imageService ??= new ImageService(new SupabaseImageRepository());
    return imageService;
  };

  const getController = (): ImageController => {
    controller ??= new ImageController(getImageService());
    return controller;
  };

  const getWeatherController = (): WeatherController => {
    weatherController ??= new WeatherController(
      weatherService ?? new WeatherService(
        getImageService(),
        weatherClient ?? new OpenMeteoWeatherClient(),
      ),
    );
    return weatherController;
  };

  const router = Router();
  let authentication: RequestHandler | undefined;
  const getAuthentication = (): RequestHandler => {
    authentication ??= createJwtMiddleware(
      verifier ?? new SupabaseJwtVerifier(createDefaultAuthService()),
    );
    return authentication;
  };
  let adminAuthorization: RequestHandler | undefined;
  const getAdminAuthorization = (): RequestHandler => {
    adminAuthorization ??= requireRoles(UserRole.ADMIN);
    return adminAuthorization;
  };
  router.use('/api/images', (request, response, next) =>
    getAuthentication()(request, response, next),
  );
  router.post('/api/images', uploadSingleFile, (request, response, next) =>
    getController().create(request, response, next),
  );
  router.get('/api/images', (request, response, next) =>
    getController().list(request, response, next),
  );
  router.get('/api/images/:id', (request, response, next) =>
    getController().getById(request, response, next),
  );
  router.get('/api/images/:id/weather', (request, response, next) =>
    getWeatherController().getForImage(request, response, next),
  );
  router.put('/api/images/:id', (request, response, next) =>
    getController().update(request, response, next),
  );
  router.delete('/api/images/:id', (request, response, next) =>
    getController().remove(request, response, next),
  );
  router.get(
    '/api/admin/images',
    (request, response, next) => getAuthentication()(request, response, next),
    (request, response, next) =>
      getAdminAuthorization()(request, response, next),
    (request, response, next) => getController().list(request, response, next),
  );
  return router;
};
