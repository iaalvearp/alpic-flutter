import { Router } from 'express';
import { createAuthRouter } from './auth.routes.js';
import { healthRouter } from './health.routes.js';
import { createImageRouter } from './image.routes.js';

export const apiRouter = Router();

apiRouter.use(healthRouter);
apiRouter.use(createAuthRouter());
apiRouter.use(createImageRouter());
