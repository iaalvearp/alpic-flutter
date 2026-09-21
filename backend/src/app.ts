import express from 'express';
import { env } from './config/env.js';
import { createCorsMiddleware } from './middleware/cors.middleware.js';
import { errorMiddleware } from './middleware/error.middleware.js';
import { notFoundMiddleware } from './middleware/not-found.middleware.js';
import { swaggerRouter } from './middleware/swagger.js';
import { apiRouter } from './routes/index.js';

export const app = express();

app.disable('x-powered-by');
app.use(createCorsMiddleware(env.corsOrigins));
app.use(express.json({ limit: '1mb' }));
app.use(swaggerRouter);
app.use(apiRouter);
app.use(notFoundMiddleware);
app.use(errorMiddleware);
