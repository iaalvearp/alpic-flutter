import type { Context } from 'hono';

export const swaggerHandler = (c: Context) => {
  return c.json({
    openapi: '3.1.0',
    info: {
      title: 'AlPics API',
      description: 'REST API for photo management with location and weather.',
      version: '0.1.0',
    },
    servers: [
      {
        url: c.req.url.split('/api')[0],
        description: 'Current server',
      },
    ],
    paths: {
      '/api/v1/health': {
        get: {
          summary: 'Health check',
          tags: ['Health'],
          responses: {
            '200': {
              description: 'Service is healthy',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      status: { type: 'string', example: 'ok' },
                      service: { type: 'string', example: 'alpic-backend' },
                      environment: { type: 'string', example: 'production' },
                      timestamp: { type: 'string', format: 'date-time' },
                      uptime: { type: 'integer' },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  });
};
