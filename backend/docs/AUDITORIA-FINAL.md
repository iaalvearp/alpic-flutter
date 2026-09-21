# Auditoría Final del Proyecto AlPics

**Fecha:** 2026-09-21  
**Alcance:** Revisión de todos los requisitos académicos  
**Metodología:** Verificación directa del código fuente, ejecución de pruebas, revisión de documentación

---

## 1. Resultados de Pruebas

### Backend (Node.js)

```
✔ tests 51
✔ pass 51
✔ fail 0
✔ duration_ms 1223ms
```

### Flutter

```
✔ 34 tests passed
✔ 0 failures
✔ Flutter analyze: No issues found
```

---

## 2. Auditoría por Requisito

### 2.1 Arquitectura por capas — CUMPLIDO ✅

**Evidencia:** 7 capas separadas en `backend/src/`:

| Capa | Directorio | Archivos | Función |
|------|-----------|----------|---------|
| Routes | `routes/` | 4 | Registro de endpoints |
| Controllers | `controllers/` | 4 | Coordinación HTTP |
| Services | `services/` | 6 | Lógica de negocio |
| Repositories | `repositories/` | 3 | Persistencia Supabase |
| Models | `models/` | 8 | Tipos de dominio |
| DTOs | `dtos/` | 6 | Contratos de transporte |
| Middleware | `middleware/` | 7 | Auth, CORS, errores |

**Verificación:** Los controllers delegan a servicios (`image.controller.ts:30`), los servicios dependen de interfaces (`image.service.ts:8`), los repositories son adaptadores de Supabase (`image.repository.ts:46`).

### 2.2 REST API — CUMPLIDO ✅

**Evidencia:** Endpoints en `backend/src/routes/image.routes.ts`:

```
POST   /api/images        → Crear
GET    /api/images        → Listar
GET    /api/images/:id    → Obtener
PUT    /api/images/:id    → Actualizar
DELETE /api/images/:id    → Eliminar
```

Métodos HTTP correctos: GET (lectura), POST (creación), PUT (actualización), DELETE (eliminación).

### 2.3 JSON — CUMPLIDO ✅

**Evidencia:**
- `backend/src/app.ts:13`: `express.json({ limit: '1mb' })`
- Controllers retornan JSON: `response.json({ data: ... })`
- Errores en JSON: `response.status(400).json({ error: { code, message } })`
- Flutter decodifica: `lib/services/api_client.dart:146` `jsonDecode(response.body)`

### 2.4 CRUD — CUMPLIDO ✅

**Evidencia completa (backend → repository → Flutter):**

| Operación | Controller | Service | Repository | Test |
|-----------|-----------|---------|------------|------|
| Create | `image.controller.ts:23` | `image.service.ts:34` | `image.repository.ts:117` | `image.routes.test.ts:30` |
| Read (list) | `image.controller.ts:37` | `image.service.ts:21` | `image.repository.ts:75` | `image.routes.test.ts:48` |
| Read (by id) | `image.controller.ts:46` | `image.service.ts:27` | `image.repository.ts:102` | `image.routes.test.ts:88` |
| Update | `image.controller.ts:59` | `image.service.ts:70` | `image.repository.ts:128` | `image.routes.test.ts:185` |
| Delete | `image.controller.ts:70` | `image.service.ts:88` | `image.repository.ts:152` | `image.routes.test.ts:222` |

### 2.5 DTOs — CUMPLIDO ✅

**Evidencia:**
- **Entrada:** `backend/src/dtos/auth.dto.ts:54` `parseCredentialsDto()` valida email (regex, max 320, lowercase), password (8-256 chars)
- **Entrada:** `backend/src/dtos/image.dto.ts:115` `parseCreateImageDto()` valida file, name, alt, description, source, coordinates, MIME, extension
- **Salida:** `backend/src/dtos/image.dto.ts:185` `toImageResponseDto()` serializa con fechas ISO
- **Validación UUID:** `backend/src/dtos/image.dto.ts:107` `parseImageId()` regex v1-v8

### 2.6 Persistencia — CUMPLIDO ✅

**Evidencia:**
- Conexión: `backend/src/config/supabase.ts` cliente singleton con `@supabase/supabase-js`
- Create: `supabase.from('images').insert(...).select().single()` (`image.repository.ts:117`)
- Read: `supabase.from('images').select(...).eq('owner_id', ownerId)` (`image.repository.ts:75`)
- Update: `supabase.from('images').update(...)` (`image.repository.ts:128`)
- Storage: `supabase.storage.from(bucket).upload(...)` (`image.repository.ts:173`)
- Test integración: `backend/src/supabase.integration.test.ts` (condicional)

### 2.7 JWT — CUMPLIDO ✅

**Evidencia:**
- Extracción: `backend/src/middleware/auth.middleware.ts:40` `createJwtMiddleware`
- Validación: `backend/src/repositories/auth.repository.ts:83` `supabase.auth.getUser(token)`
- Almacenamiento Flutter: `lib/services/api_client.dart:17` `flutter_secure_storage`
- Envío: `lib/services/api_client.dart:138` `authorization: 'Bearer $token'`
- Restauración: `lib/main.dart:19` `authService.restoreSession()`

### 2.8 Roles — CUMPLIDO ✅

**Evidencia:**
- Definición: `backend/src/models/user.model.ts:1` `UserRole = { USER: 'USER', ADMIN: 'ADMIN' }`
- Registro: `backend/src/repositories/auth.repository.ts:56` `app_metadata: { role: UserRole.USER }`
- Middleware: `backend/src/middleware/authorization.middleware.ts:9` `requireRoles()`
- Uso: `backend/src/routes/image.routes.ts:91` `requireRoles(UserRole.ADMIN)`

### 2.9 Autorización — CUMPLIDO ✅

**Evidencia:**
- USER solo ve sus imágenes: `image.repository.ts:75` `.eq('owner_id', ownerId)`
- ADMIN ve todas: `image.repository.ts:89` `findAllVisible()` sin filtro de owner
- Tests que verifican:
  - `image.routes.test.ts:58` "rejects a normal user with 403"
  - `image.routes.test.ts:72` "allows an administrator"
  - `image.routes.test.ts:162` "returns 404 when the image belongs to another user"
  - `image.routes.test.ts:199` "ADMIN can modify an image owned by another user"

### 2.10 HTTP Status Codes — CUMPLIDO ✅

**Evidencia completa:**

| Código | Uso | Archivo |
|--------|-----|---------|
| 200 | Éxito (GET, PUT, DELETE) | `image.controller.ts:40,53,64,74` |
| 201 | Recurso creado | `image.controller.ts:31`, `auth.controller.ts:21` |
| 400 | Validación, JSON malformado | `error.middleware.ts:33`, DTOs |
| 401 | Sin token / token inválido | `auth.middleware.ts:27,31,49` |
| 403 | Permisos insuficientes | `authorization.middleware.ts:18` |
| 404 | Recurso no encontrado | `not-found.middleware.ts`, `image.controller.ts:51` |
| 413 | Archivo > 10MB | `image.routes.ts:37` |
| 500 | Error interno genérico | `error.middleware.ts:33` (fallback) |
| 502 | API externa con error | `weather.service.ts:22-30` |
| 504 | Timeout API externa | `weather.service.ts:14` |
| 204 | CORS preflight | `cors.middleware.ts:32` |

### 2.11 API externa — CUMPLIDO ✅

**Evidencia:**
- Cliente: `backend/src/integrations/open-meteo.client.ts:135` `OpenMeteoWeatherClient`
- Endpoint: `GET /api/images/:id/weather` retorna clima actual
- Datos: temperatura, humedad, viento, precipitación, código WMO, día/noche
- Config: `OPEN_METEO_BASE_URL` + `EXTERNAL_API_TIMEOUT_MS`
- Errores: timeout→504, datos inválidos→502, red→502
- Tests: `open-meteo.client.test.ts` (2 unitarios), `weather.integration.test.ts` (1 real)

### 2.12 Integración Flutter — CUMPLIDO ✅

**Evidencia:**
- API Client: `lib/services/api_client.dart` envía HTTP requests con `package:http`
- Base URL: `lib/config/api_config.dart:3` `ALPICS_API_BASE_URL` via `--dart-define`
- Auth REST: `lib/services/api_auth_service.dart` llama `/api/auth/*`
- Images REST: `lib/repositories/rest_image_repository.dart` CRUD vía `/api/images`
- Weather REST: `lib/repositories/weather_repository.dart` llama `/api/images/:id/weather`
- Init: `lib/main.dart:15-35` inyecta dependencias REST

### 2.13 Manejo de errores — CUMPLIDO ✅

**Evidencia:**
- Middleware global: `backend/src/middleware/error.middleware.ts:21` `errorMiddleware`
- Formato consistente: `{ error: { code, message } }` (línea 52-57)
- 500 genérico: nunca expone stack traces (línea 38-45)
- Not-found: `not-found.middleware.ts` retorna 404 `ROUTE_NOT_FOUND`
- Parsing errors: JSON malformado→400, payload grande→413
- Flutter: `lib/services/api_client.dart:157` `_ensureSuccess()` parsea errores

### 2.14 Seguridad básica — CUMPLIDO ✅

**Evidencia:**
- CORS deny-by-default: `cors.middleware.ts` solo permite orígenes en `CORS_ORIGINS`
- No secretos hardcodeados: verificado por grep (0 coincidencias en código backend)
- `.gitignore` excluye `/backend/.env`
- Passwords hasheados: Supabase Auth maneja hash (`auth.repository.ts:52`)
- `x-powered-by` deshabilitado: `app.ts:10`
- Uploads en memoria: `image.routes.ts:28` `multer.memoryStorage()`
- Límite 10MB: `image.routes.ts:29`
- Errores 500 genéricos: no exponen detalles

### 2.15 Postman — CUMPLIDO ✅

**Evidencia:**
- Archivo: `backend/docs/AlPics-API.postman_collection.json` (861 líneas)
- 5 carpetas: Health, Authentication, Images, Weather, Error Tests
- 18 requests con scripts de validación
- Variables: `baseUrl`, `userToken`, `adminToken`, `createdImageId`
- Auto-captura de tokens e IDs

### 2.16 Swagger/OpenAPI — CUMPLIDO ✅

**Evidencia:**
- Spec: `backend/docs/openapi.yaml` (822 líneas, OpenAPI 3.1.0)
- Swagger UI: `backend/src/middleware/swagger.ts` integrado en `app.ts:14`
- Accesible en: `http://127.0.0.1:3000/docs`
- JSON: `http://127.0.0.1:3000/openapi.json`
- 11 endpoints documentados con parámetros, bodies, responses, ejemplos

### 2.17 README — CUMPLIDO ✅

**Evidencia:**
- Principal: `README.md` (534 líneas, 19 secciones)
- Backend: `backend/README.md` (72 líneas, referencia al principal)
- Incluye: descripción, arquitectura, tecnologías, estructura, requisitos, instalación, entorno, Supabase, ejecución, auth, roles, endpoints, API externa, pruebas, Postman, Swagger, seguridad

### 2.18 Pruebas — CUMPLIDO ✅

**Evidencia:**
- Backend: 51 pruebas unitarias/integración (10 archivos)
- Flutter: 34 pruebas (10 archivos)
- Total: **85 pruebas**, todas pasan
- Cobertura: DTOs, modelos, servicios, rutas, CORS, auth, autorización, errores, integración

### 2.19 Evidencias — PARCIAL ⚠️

**Evidencia existente:**
- `backend/docs/INFORME-DOCUMENTACION.md` con resultados de pruebas
- Pruebas ejecutadas y documentadas en esta auditoría

**Evidencia faltante:**
- No hay carpeta `evidencias/` con capturas de pantalla
- No hay screenshots de la app Flutter funcionando
- No hay logs de terminal guardados como archivos

### 2.20 Documento académico — NO CUMPLIDO ❌

**Hallazgo:** No existe ningún archivo `.docx`, `.pdf` o similar con un documento académico del proyecto. Los únicos documentos son READMEs, ADR y el informe técnico.

### 2.21 Formato APA 7 — NO CUMPLIDO ❌

**Hallazgo:** Ningún documento en el proyecto sigue formato APA 7. Los archivos `.md` usan formato técnico/markdown.

### 2.22 Bibliografía — NO CUMPLIDO ❌

**Hallazgo:** No hay sección de referencias bibliográficas en ningún archivo. No se encontraron citas formales de tecnologías o fuentes.

---

## 3. Problemas Encontrados

### 3.1 No críticos (no bloquean la entrega)

| # | Problema | Severidad | Archivo |
|---|----------|-----------|---------|
| 1 | `API_PREFIX` definido en `.env.example` pero no usado en rutas | Baja | `config/env.ts`, `routes/*.ts` |
| 2 | Código legacy no usado: `lib/services/auth_service.dart` | Baja | Flutter |
| 3 | Código legacy no usado: `lib/services/image_remote_gateway.dart` | Baja | Flutter |
| 4 | Código legacy no usado: `lib/repositories/image_repository.dart` (Supabase directo) | Baja | Flutter |
| 5 | No hay rate limiting | Baja | Backend |
| 6 | No hay Helmet (headers seguridad HTTP) | Baja | Backend |
| 7 | JWT issuer/audience no se validan | Baja | Backend |

### 3.2 Críticos

**No se encontraron problemas críticos en el código.** Todos los requisitos funcionales están implementados y verificados con pruebas.

---

## 4. Correcciones Realizadas

Durante esta auditoría no fue necesario corregir ningún problema crítico. El proyecto está funcional y completo en cuanto a código.

Las únicas mejoras pendientes son de tipo documental (documento académico, APA 7, bibliografía) y de limpieza de código legacy, que no son críticas para la funcionalidad.

---

## 5. Pruebas Finales

### Backend

```bash
$ cd backend && npm test
✔ tests 51
✔ pass 51
✔ fail 0
✔ duration_ms 1223ms
```

### Flutter

```bash
$ flutter test
34 tests passed, 0 failures

$ flutter analyze
No issues found!
```

---

## 6. Resumen de Requisitos

| # | Requisito | Estado | Evidencia |
|---|-----------|--------|-----------|
| 1 | Arquitectura por capas | ✅ CUMPLIDO | 7 capas en `backend/src/` |
| 2 | REST API | ✅ CUMPLIDO | 11 endpoints REST en `routes/` |
| 3 | JSON | ✅ CUMPLIDO | Request/response JSON, `express.json()` |
| 4 | CRUD | ✅ CUMPLIDO | Create, Read, Update, Delete verificados |
| 5 | DTOs | ✅ CUMPLIDO | Parseo entrada + serialización salida |
| 6 | Persistencia | ✅ CUMPLIDO | Supabase CRUD + Storage |
| 7 | JWT | ✅ CUMPLIDO | Bearer token, validación Supabase |
| 8 | Roles | ✅ CUMPLIDO | USER/ADMIN, `app_metadata.role` |
| 9 | Autorización | ✅ CUMPLIDO | USER→propios, ADMIN→todos |
| 10 | HTTP status codes | ✅ CUMPLIDO | 200, 201, 400, 401, 403, 404, 413, 500, 502, 504 |
| 11 | API externa | ✅ CUMPLIDO | Open-Meteo Forecast API |
| 12 | Integración Flutter | ✅ CUMPLIDO | REST client, JWT, CRUD |
| 13 | Manejo de errores | ✅ CUMPLIDO | Middleware global, formato consistente |
| 14 | Seguridad básica | ✅ CUMPLIDO | CORS, no hardcode, hasheo |
| 15 | Postman | ✅ CUMPLIDO | 18 requests, 5 carpetas, tests |
| 16 | Swagger/OpenAPI | ✅ CUMPLIDO | OpenAPI 3.1, Swagger UI en `/docs` |
| 17 | README | ✅ CUMPLIDO | 534 líneas, 19 secciones |
| 18 | Pruebas | ✅ CUMPLIDO | 85 pruebas (51 backend + 34 Flutter) |
| 19 | Evidencias | ⚠️ PARCIAL | Informe técnico existe, faltan screenshots |
| 20 | Documento académico | ❌ NO CUMPLIDO | No existe archivo académico |
| 21 | Formato APA 7 | ❌ NO CUMPLIDO | Ningún documento usa APA 7 |
| 22 | Bibliografía | ❌ NO CUMPLIDO | No hay referencias formales |

---

## 7. Evidencias Necesarias para Entrega

### Ya existentes en el repositorio

1. **Código fuente completo** — Backend REST + Flutter cliente
2. **85 pruebas** — Todas pasan (51 backend + 34 Flutter)
3. **Documentación OpenAPI** — `backend/docs/openapi.yaml`
4. **Swagger UI** — Integrado en `/docs`
5. **Colección Postman** — `backend/docs/AlPics-API.postman_collection.json`
6. **README completo** — `README.md` (534 líneas)
7. **Informe técnico** — `backend/docs/INFORME-DOCUMENTACION.md`
8. **ADR** — `docs/arquitectura/ADR-001-backend-rest-inicial.md`

### Pendientes de crear (fuera del alcance de esta auditoría de código)

1. **Documento académico** — Monografía/informe en formato APA 7
2. **Capturas de pantalla** — App funcionando, terminal con tests, Swagger UI, Postman
3. **Bibliografía** — Referencias formales de tecnologías y fuentes

---

## 8. Conclusión Final

**El proyecto AlPics está técnicamente completo y funcional.** Todos los requisitos de código están implementados y verificados:

- **17 de 22 requisitos** están cumplidos completamente
- **1 requisito** está parcialmente cumplido (evidencias)
- **4 requisitos** no están cumplidos (documento académico, APA 7, bibliografía — todos relacionados con la documentación escrita)

**El código es robusto:**
- Arquitectura de capas limpia y correctamente separada
- CRUD completo con validación exhaustiva
- Autenticación JWT con roles USER/ADMIN
- Manejo de errores global y consistente
- 85 pruebas que verifican funcionalidad, permisos y errores
- Sin secretos hardcodeados
- Documentación técnica completa (OpenAPI, Postman, README)

**Lo que falta es documentación académica**, no funcionalidad. El estudiante necesita crear el documento escrito (monografía/informe) en formato APA 7 con bibliografía, y recopilar evidencias visuales (screenshots).
