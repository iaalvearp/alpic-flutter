import { Router, type RequestHandler } from 'express';
import swaggerUi from 'swagger-ui-express';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import YAML from 'yaml';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const openApiPath = join(__dirname, '..', '..', 'docs', 'openapi.yaml');

const fallbackDoc: Record<string, unknown> = {
  openapi: '3.1.0',
  info: { title: 'AlPics API', version: '0.1.0' },
  paths: {},
};

let resolvedDoc: Record<string, unknown> = fallbackDoc;
let loaded = false;

const getSwaggerDocument = (): Record<string, unknown> => {
  if (loaded) return resolvedDoc;
  loaded = true;
  try {
    const yaml = readFileSync(openApiPath, 'utf-8');
    resolvedDoc = YAML.parse(yaml) as Record<string, unknown>;
  } catch {
    resolvedDoc = fallbackDoc;
  }
  return resolvedDoc;
};

export const swaggerRouter = Router();

const swaggerMiddleware: RequestHandler = (req, res, next) => {
  swaggerUi.setup(getSwaggerDocument(), {
    customCss: '.swagger-ui .topbar { display: none }',
    customSiteTitle: 'AlPics API Documentation',
  })(req, res, next);
};

swaggerRouter.use('/docs', swaggerUi.serve, swaggerMiddleware);

swaggerRouter.get('/openapi.json', (_req, res) => {
  res.json(getSwaggerDocument());
});
