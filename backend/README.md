# AlPics Backend

Backend REST para AlPics. Gestiona autenticación, imágenes y datos climáticos.

> Para la documentación completa del proyecto, ver el [README principal](../README.md).

## Requisitos

- Node.js ≥ 20
- npm
- Cuenta de Supabase con proyecto activo

## Inicio rápido

```bash
npm install
cp .env.example .env   # Configurar variables de Supabase
npm run dev             # Desarrollo con hot-reload
```

El servidor arranca en `http://127.0.0.1:3000`.

## Comandos

| Comando | Descripción |
|---------|-------------|
| `npm run dev` | Desarrollo con hot-reload |
| `npm run build` | Compilar TypeScript |
| `npm start` | Ejecutar versión compilada |
| `npm test` | Ejecutar todas las pruebas |
| `npm run test:integration` | Pruebas con Supabase real |
| `npm run test:external` | Pruebas con Open-Meteo real |
| `npm run check` | Verificar tipos (build) |

## Endpoints

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/health` | No | Estado del servicio |
| POST | `/api/auth/register` | No | Registro de usuario |
| POST | `/api/auth/login` | No | Login, retorna JWT |
| GET | `/api/auth/me` | Bearer | Perfil del usuario |
| POST | `/api/images` | Bearer | Crear imagen (multipart) |
| GET | `/api/images` | Bearer | Listar imágenes del usuario |
| GET | `/api/images/:id` | Bearer | Obtener imagen por ID |
| PUT | `/api/images/:id` | Bearer | Actualizar metadata |
| DELETE | `/api/images/:id` | Bearer | Soft delete |
| GET | `/api/images/:id/weather` | Bearer | Clima de coordenadas |
| GET | `/api/admin/images` | Bearer + ADMIN | Listar todas las imágenes |

## Documentación

- **Swagger UI**: `http://127.0.0.1:3000/docs`
- **OpenAPI JSON**: `http://127.0.0.1:3000/openapi.json`
- **Spec YAML**: `docs/openapi.yaml`
- **Postman**: `docs/AlPics-API.postman_collection.json`

## Arquitectura de capas

```
Routes → Controllers → Services → Repositories → Supabase
```

- `config/` — configuración de entorno
- `controllers/` — coordinadores HTTP
- `dtos/` — contratos de transporte
- `integrations/` — clientes de APIs externas
- `middleware/` — auth, CORS, errores, Swagger
- `models/` — tipos de dominio y errores
- `repositories/` — adaptadores de persistencia
- `routes/` — registro de endpoints
- `services/` — lógica de negocio
