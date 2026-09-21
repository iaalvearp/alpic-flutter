# Informe Técnico: Documentación y Pruebas de la API - AlPics

**Fecha:** 2026-09-21  
**Estado:** Completado

---

## 1. Documentación Creada

### 1.1 OpenAPI/Swagger (`backend/docs/openapi.yaml`)

Especificación OpenAPI 3.1.0 que documenta:

| Endpoint | Método | Auth | Descripción |
|----------|--------|------|-------------|
| `/health` | GET | No | Health check |
| `/api/auth/register` | POST | No | Registro de usuario |
| `/api/auth/login` | POST | No | Login, retorna JWT |
| `/api/auth/me` | GET | Bearer | Perfil del usuario autenticado |
| `/api/images` | POST | Bearer | Crear imagen (multipart) |
| `/api/images` | GET | Bearer | Listar imágenes del usuario |
| `/api/images/:id` | GET | Bearer | Obtener imagen por ID |
| `/api/images/:id` | PUT | Bearer | Actualizar metadata |
| `/api/images/:id` | DELETE | Bearer | Soft delete |
| `/api/images/:id/weather` | GET | Bearer | Clima de coordenadas |
| `/api/admin/images` | GET | Bearer + ADMIN | Listar todas las imágenes |

**Incluye para cada endpoint:**
- Parámetros de path, query y body
- Ejemplos de request/response exitosos
- Todos los códigos HTTP posibles (200, 201, 400, 401, 403, 404, 413, 500)
- Esquemas de error consistentes
- Descripción de autenticación Bearer JWT
- Descripción de roles (USER/ADMIN)

### 1.2 Swagger UI Integrado

**Archivos modificados:**
- `backend/src/middleware/swagger.ts` (nuevo)
- `backend/src/app.ts` (modificado)

**Endpoints de documentación:**
- `GET /docs` → Swagger UI interactivo
- `GET /openapi.json` → Spec OpenAPI en JSON

**Dependencias añadidas:**
- `swagger-ui-express` (runtime)
- `@types/swagger-ui-express` (dev)
- `yaml` (runtime, para parsear el YAML)

### 1.3 Colección Postman (`backend/docs/AlPics-API.postman_collection.json`)

Colección completa con 18 requests organizados en 5 carpetas:

| Carpeta | Requests | Descripción |
|---------|----------|-------------|
| Health | 1 | Health check |
| Authentication | 3 | Register, Login, Me |
| Images | 5 | CRUD completo |
| Weather | 1 | Clima por imagen |
| Error Tests | 8 | Pruebas negativas |

**Variables de colección:**
- `baseUrl` → `http://127.0.0.1:3000`
- `userToken` → JWT del usuario (auto-capturado)
- `adminToken` → JWT del admin
- `createdImageId` → ID de imagen creada (auto-capturado)

**Scripts de validación (tests) incluidos en cada request:**
- Validación de status code esperado
- Validación de estructura de respuesta
- Auto-captura de tokens y IDs para requests siguientes
- Verificación de que passwords no se exponen

---

## 2. Pruebas Ejecutadas

### 2.1 Pruebas Unitarias y de Integración (existentes)

```
✔ tests 51
✔ pass 51
✔ fail 0
✔ duration_ms 886ms
```

**Cobertura:**
- Auth DTO (validación de credenciales)
- Image DTO (coordenadas, MIME types, UUIDs)
- CORS (allow/reject, preflight)
- Image Model (mapeo de filas)
- Image Service (upload, rollback, permisos)
- Weather Service (coordenadas, timeouts, errores)
- OpenMeteo Client (request format, respuesta inválida)
- Auth Routes (register, login, me, JWT, errores)
- Image Routes (CRUD, permisos, weather, errores)

### 2.2 Build

```
✔ TypeScript build: exitoso (sin errores)
```

### 2.3 Verificación de Swagger

```
✔ GET /openapi.json → 200 (spec JSON válido)
✔ GET /docs/ → 200 (Swagger UI accesible)
```

### 2.4 Servidor

```
✔ Servidor inicia correctamente con Swagger integrado
```

---

## 3. Incidencias Pendientes

### 3.1 No críticas (mejoras futuras)

1. **API_PREFIX inconsistente**: `API_PREFIX=/api/v1` está definido en `.env.example` pero no se usa en las rutas (las rutas hardcodean `/api/images`, `/api/auth`). No afecta funcionalidad pero es inconsistente.

2. **Rate limiting**: No hay protección contra fuerza bruta en login. Recomendado para producción.

3. **Helmet**: No hay headers de seguridad HTTP (X-Content-Type-Options, X-Frame-Options, etc.).

4. **JWT issuer/audience**: Configurable pero no implementada la validación.

5. **Tests de integración completa**: Los tests con Supabase real requieren variables de entorno y no se ejecutan en CI por defecto.

6. **Código legacy**: `lib/services/auth_service.dart` con Supabase directo no se usa (obsoleto).

### 3.2 Seguridad verificada

| Verificación | Estado |
|--------------|--------|
| No hay secretos hardcodeados en backend | ✅ |
| Passwords no se almacenan en texto plano (Supabase Auth) | ✅ |
| Usuario no puede modificar recursos ajenos | ✅ (verificado en tests) |
| Usuario sin JWT no accede a endpoints protegidos | ✅ (verificado en tests) |
| ADMIN tiene permisos definidos | ✅ (verificado en tests) |
| Errores no exponen información sensible | ✅ (500 retorna mensaje genérico) |

---

## 4. Archivos Modificados/Creados

| Archivo | Acción |
|---------|--------|
| `backend/docs/openapi.yaml` | Creado |
| `backend/docs/AlPics-API.postman_collection.json` | Creado |
| `backend/src/middleware/swagger.ts` | Creado |
| `backend/src/app.ts` | Modificado (añadido swaggerRouter) |
| `backend/package.json` | Modificado (swagger-ui-express, yaml) |
