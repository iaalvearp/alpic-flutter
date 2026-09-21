# AlPics

Aplicación móvil para gestionar fotos geolocalizadas con metadatos GPS y datos
climáticos en tiempo real. Compuesta por un backend REST en Node.js y un
cliente Flutter.

## Objetivo

Permitir a los usuarios subir, organizar y recuperar fotografías con
información de ubicación y clima asociada. La app se orienta a fotógrafos,
viajeros y cualquiera que desee documentar eventos con contexto geográfico y
meteorológico.

## Arquitectura

```
┌─────────────┐      HTTP/REST       ┌──────────────────┐
│   Flutter    │ ◄──────────────────► │   Backend REST   │
│   (cliente)  │   Bearer JWT         │   Express/TS     │
└─────────────┘                      └────────┬─────────┘
                                              │
                                    ┌─────────▼─────────┐
                                    │     Supabase       │
                                    │  Auth + Storage    │
                                    │  + PostgreSQL      │
                                    └───────────────────┘
                                              │
                                    ┌─────────▼─────────┐
                                    │   Open-Meteo API   │
                                    │   (clima externo)  │
                                    └───────────────────┘
```

El backend sigue una arquitectura de **capas** (patrón hexagonal simplificado):

```
Routes → Controllers → Services → Repositories → Supabase
                ↘ DTOs      ↘ Models       ↘ Integrations
```

- **Routes**: registran endpoints y componen middlewares por ruta.
- **Controllers**: coordinan request/response, delegan a servicios.
- **Services**: lógica de negocio pura, depende de puertos (interfaces).
- **Repositories**: adaptadores de persistencia (Supabase).
- **DTOs**: contratos de transporte (parseo de entrada + serialización de salida).
- **Models**: tipos de dominio y clases de error propias.
- **Integrations**: clientes de APIs externas (Open-Meteo).
- **Middleware**: autenticación JWT, autorización por roles, manejo de errores.

## Tecnologías

### Backend

| Componente | Tecnología |
|------------|------------|
| Runtime | Node.js ≥ 20 |
| Framework | Express 5 |
| Lenguaje | TypeScript 5.9 |
| Persistencia | Supabase (PostgreSQL + Auth + Storage) |
| API externa | Open-Meteo Forecast API |
| Documentación | OpenAPI 3.1 + Swagger UI |
| Pruebas | Node.js test runner + supertest |

### Cliente Flutter

| Componente | Tecnología |
|------------|------------|
| Framework | Flutter ≥ 3.12 |
| Estado | Inyección de dependencias (sin provider externo) |
| Seguridad | flutter_secure_storage (JWT) |
| Ubicación | geolocator + permission_handler |
| Imágenes | image_picker |
| HTTP | http + http_parser |

## Estructura de carpetas

```
alpic-flutter/
├── backend/                    # Backend REST (Node.js/Express/TypeScript)
│   ├── src/
│   │   ├── config/             # Configuración de entorno
│   │   ├── controllers/        # Coordinadores HTTP
│   │   ├── dtos/               # Contratos de transporte
│   │   ├── integrations/       # Clientes de APIs externas
│   │   ├── middleware/          # Auth, CORS, errores, Swagger
│   │   ├── models/             # Tipos de dominio y errores
│   │   ├── repositories/       # Adaptadores de persistencia
│   │   ├── routes/             # Registro de endpoints
│   │   ├── services/           # Lógica de negocio
│   │   ├── app.ts              # Express app
│   │   └── server.ts           # Punto de entrada
│   ├── docs/
│   │   ├── openapi.yaml        # Especificación OpenAPI 3.1
│   │   ├── AlPics-API.postman_collection.json
│   │   └── INFORME-DOCUMENTACION.md
│   ├── .env.example
│   └── package.json
├── lib/                        # Cliente Flutter
│   ├── app/                    # Widget raíz, tema
│   ├── config/                 # Configuración de API y Supabase
│   ├── models/                 # Modelos de datos
│   ├── repositories/           # Repositorios (interfaz + implementación)
│   ├── screens/                # Pantallas (home, login, image_form, image_list)
│   ├── services/               # Servicios API (auth, images, weather)
│   ├── utils/                  # Utilidades (metadata, nombres)
│   ├── widgets/                # Componentes reutilizables
│   └── main.dart               # Punto de entrada
├── test/                       # Pruebas Flutter (10 archivos)
├── docs/arquitectura/          # ADRs
└── pubspec.yaml
```

## Requisitos

### Backend

- **Node.js** ≥ 20
- **npm** (incluido con Node)
- **Cuenta de Supabase** con proyecto activo

### Cliente Flutter

- **Flutter SDK** ≥ 3.12
- **Android Studio** o **VS Code** con plugins de Flutter
- Un emulador Android/iOS o dispositivo conectado

## Instalación

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd alpic-flutter
```

### 2. Instalar dependencias del backend

```bash
cd backend
npm install
```

### 3. Instalar dependencias de Flutter

```bash
cd ..
flutter pub get
```

## Variables de entorno

Crea un archivo `backend/.env` copiando el ejemplo:

```bash
cp backend/.env.example backend/.env
```

### Referencia de variables

| Variable | Requerida | Default | Descripción |
|----------|-----------|---------|-------------|
| `NODE_ENV` | No | `development` | Entorno de ejecución |
| `HOST` | No | `127.0.0.1` | Host de escucha del servidor |
| `PORT` | No | `3000` | Puerto del servidor |
| `API_PREFIX` | No | `/api/v1` | Prefijo de rutas (reservado) |
| `SUPABASE_URL` | **Sí** | — | URL del proyecto Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | **Sí** | — | Service Role Key de Supabase |
| `SUPABASE_STORAGE_BUCKET` | No | `alpics-images` | Nombre del bucket de almacenamiento |
| `JWT_ISSUER` | No | — | Reservado para futuro |
| `JWT_AUDIENCE` | No | — | Reservado para futuro |
| `CORS_ORIGINS` | No | (vacío) | Orígenes CORS permitidos (separados por coma) |
| `EXTERNAL_API_BASE_URL` | No | — | URL base de API externa genérica |
| `OPEN_METEO_BASE_URL` | No | `https://api.open-meteo.com/v1/forecast` | URL de Open-Meteo |
| `EXTERNAL_API_TIMEOUT_MS` | No | `5000` | Timeout de APIs externas (ms) |

> **Seguridad**: Nunca commitees el archivo `.env`. Ya está en `.gitignore`.

## Configuración de Supabase

### 1. Crear proyecto

1. Ve a [supabase.com](https://supabase.com) y crea una cuenta.
2. Crea un nuevo proyecto.
3. Anota la **URL del proyecto** y la **Service Role Key** (Settings → API).

### 2. Bucket de almacenamiento

1. Ve a **Storage** en el panel de Supabase.
2. Crea un bucket llamado `alpics-images` (o el nombre que indiques en `SUPABASE_STORAGE_BUCKET`).
3. Configura las políticas de acceso según tus necesidades.

### 3. Tabla de imágenes

El backend espera una tabla `images` en PostgreSQL. Ejemplo de esquema:

```sql
CREATE TABLE images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT NOT NULL,
  src TEXT,
  storage_path TEXT,
  alt TEXT NOT NULL,
  description TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  extension TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  maps_url TEXT,
  source TEXT NOT NULL CHECK (source IN ('camera', 'gallery')),
  original_filename TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  is_visible BOOLEAN NOT NULL DEFAULT true,
  deleted_at TIMESTAMPTZ
);

-- Políticas RLS (ejemplo básico)
ALTER TABLE images ENABLE ROW LEVEL SECURITY;

-- Los usuarios ven sus propias imágenes
CREATE POLICY "Users view own images" ON images
  FOR SELECT USING (auth.uid() = owner_id);

-- Los usuarios insertan sus propias imágenes
CREATE POLICY "Users insert own images" ON images
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- Los usuarios actualizan sus propias imágenes
CREATE POLICY "Users update own images" ON images
  FOR UPDATE USING (auth.uid() = owner_id);

-- Los usuarios eliminan sus propias imágenes
CREATE POLICY "Users delete own images" ON images
  FOR DELETE USING (auth.uid() = owner_id);
```

> **Nota**: El esquema exacto puede variar. Verifica la estructura real en tu proyecto Supabase o ajusta según sea necesario.

### 4. Service Role Key

La **Service Role Key** se usa en el backend para operar con privilegios
administrativos. Nunca la expongas al cliente Flutter ni la commitees.

## Ejecución del backend

```bash
cd backend

# Desarrollo (con hot-reload)
npm run dev

# Producción
npm run build
npm start
```

El servidor arranca en `http://127.0.0.1:3000` (configurable via `PORT`).

### Verificar que funciona

```bash
curl http://127.0.0.1:3000/health
# {"status":"ok","service":"alpic-backend","environment":"development",...}
```

## Ejecución de Flutter

### Preparar el cliente

Asegúrate de que el backend esté corriendo en `http://127.0.0.1:3000`.

### Ejecutar en desarrollo

```bash
# Desde la raíz del proyecto
flutter run --dart-define=ALPICS_API_BASE_URL=http://127.0.0.1:3000
```

### Emulador Android

En un emulador Android, el host de la máquina se expone como `10.0.2.2`:

```bash
flutter run --dart-define=ALPICS_API_BASE_URL=http://10.0.2.2:3000
```

### Dispositivo físico

Para un dispositivo físico en la misma red, usa la IP local de tu máquina:

```bash
flutter run --dart-define=ALPICS_API_BASE_URL=http://192.168.x.x:3000
```

### Verificaciones del cliente

```bash
flutter analyze    # Análisis estático
flutter test       # Ejecutar pruebas
flutter build apk --debug  # Build de prueba
```

## Autenticación

La autenticación usa **Supabase Auth** con JWT. El flujo es:

1. **Registro**: `POST /api/auth/register` → crea usuario + retorna JWT.
2. **Login**: `POST /api/auth/login` → valida credenciales + retorna JWT.
3. **Uso**: el cliente envía `Authorization: Bearer <token>` en cada request.
4. **Verificación**: el backend valida el JWT con Supabase en cada request autenticado.

El JWT se almacena en el cliente mediante `flutter_secure_storage` y se
restaura al iniciar la app via `GET /api/auth/me`.

### Formato del token

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

## Roles

| Rol | Descripción |
|-----|-------------|
| `USER` | Rol por defecto. Solo puede gestionar sus propias imágenes. |
| `ADMIN` | Puede ver y gestionar todas las imágenes. Accede a `/api/admin/images`. |

Los roles se leen de `app_metadata.role` en Supabase. El registro público
siempre asigna `USER`. Para crear un `ADMIN`, modifica el `app_metadata` del
usuario desde el panel de Supabase.

## Endpoints

### Health

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/health` | No | Estado del servicio |

### Autenticación

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/auth/register` | No | Registro de usuario |
| POST | `/api/auth/login` | No | Login, retorna JWT |
| GET | `/api/auth/me` | Bearer | Perfil del usuario autenticado |

### Imágenes

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/images` | Bearer | Crear imagen (multipart/form-data) |
| GET | `/api/images` | Bearer | Listar imágenes visibles del usuario |
| GET | `/api/images/:id` | Bearer | Obtener imagen por ID |
| PUT | `/api/images/:id` | Bearer | Actualizar metadata (name, alt, description) |
| DELETE | `/api/images/:id` | Bearer | Soft delete |

### API Externa (Clima)

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/api/images/:id/weather` | Bearer | Clima actual de coordenadas GPS |

### Admin

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/api/admin/images` | Bearer + ADMIN | Listar todas las imágenes visibles |

### Documentación

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/docs` | No | Swagger UI interactivo |
| GET | `/openapi.json` | No | Spec OpenAPI en JSON |

### Formato de errores

Todos los errores retornan un JSON consistente:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "email is required"
  }
}
```

Códigos de error comunes:

| Código | HTTP | Descripción |
|--------|------|-------------|
| `VALIDATION_ERROR` | 400 | Datos de entrada inválidos |
| `INVALID_REQUEST` | 400 | JSON malformado |
| `UNAUTHORIZED` | 401 | Token no proporcionado |
| `INVALID_TOKEN` | 401 | Token inválido o expirado |
| `INVALID_CREDENTIALS` | 401 | Email o contraseña incorrectos |
| `FORBIDDEN` | 403 | Permisos insuficientes |
| `IMAGE_NOT_FOUND` | 404 | Imagen no encontrada o no pertenece al usuario |
| `UPLOAD_TOO_LARGE` | 413 | Archivo supera 10MB |
| `INTERNAL_ERROR` | 500 | Error interno del servidor |

## API externa

### Open-Meteo

El endpoint `/api/images/:id/weather` consulta la **Open-Meteo Forecast API**
para obtener el clima actual de las coordenadas GPS de una imagen.

**Datos retornados:**
- Temperatura actual y aparente
- Humedad relativa
- Precipitación
- Velocidad del viento
- Código meteorológico WMO
- Estado día/noche
- Zona horaria
- Coordenadas resueltas del proveedor

**Configuración:**
- URL configurable via `OPEN_METEO_BASE_URL`
- Timeout configurable via `EXTERNAL_API_TIMEOUT_MS` (default: 5000ms)
- Timeouts del proveedor retornan `504`
- Errores de red/datos retornan `502`

## Pruebas

### Backend

```bash
cd backend

# Todas las pruebas (unitarias + integración)
npm test

# Pruebas con Supabase real (requiere .env configurado)
npm run test:integration

# Pruebas con API externa real (Open-Meteo)
npm run test:external

# Solo build (verificación de tipos)
npm run check
```

**Cobertura actual:** 51 pruebas que cubren DTOs, modelos, servicios,
rutas, CORS, autenticación, autorización y manejo de errores.

### Flutter

```bash
# Desde la raíz del proyecto
flutter test
```

**Cobertura actual:** 10 archivos de test cubriendo modelos, servicios,
pantallas y widgets.

## Postman

La colección completa está en `backend/docs/AlPics-API.postman_collection.json`.

### Importar en Postman

1. Abre Postman.
2. Clic en **Import** → **File**.
3. Selecciona `backend/docs/AlPics-API.postman_collection.json`.

### Flujo de pruebas

La colección está organizada en carpetas que siguen el flujo natural:

1. **Health** → Verificar que el servicio está vivo.
2. **Authentication** → Registro → Login → Obtener perfil.
3. **Images** → Crear → Listar → Obtener → Actualizar → Eliminar.
4. **Weather** → Obtener clima de una imagen.
5. **Error Tests** → Pruebas negativas (validación, auth, permisos).

### Variables

La colección usa variables que se auto-actualizan:

| Variable | Descripción |
|----------|-------------|
| `baseUrl` | URL del backend (default: `http://127.0.0.1:3000`) |
| `userToken` | JWT del usuario (se captura del login/registro) |
| `adminToken` | JWT del admin (configurar manualmente) |
| `createdImageId` | ID de imagen creada (se captura del POST) |

## Swagger

La documentación Swagger UI está integrada en el backend:

```bash
cd backend
npm run dev
# Abrir http://127.0.0.1:3000/docs
```

El spec OpenAPI 3.1 está disponible en `http://127.0.0.1:3000/openapi.json`
y en el archivo `backend/docs/openapi.yaml`.

Swagger UI permite probar los endpoints directamente desde el navegador,
incluyendo autenticación Bearer y uploads multipart.

## Consideraciones de seguridad

### Lo que se implementó

- **JWT via Supabase Auth**: los tokens se validan en cada request autenticado.
- **Autorización por roles**: USER solo accede a sus recursos; ADMIN tiene acceso ampliado.
- **CORS deny-by-default**: solo se permiten orígenes explícitos en `CORS_ORIGINS`.
- **No hay secretos hardcodeados**: todas las credenciales están en variables de entorno.
- **Passwords nunca en texto plano**: Supabase Auth maneja el hash.
- **Errores no exponen información sensible**: los 500 retornan mensaje genérico.
- **x-powered-by deshabilitado**: no se expone el framework.
- **Uploads en memoria**: no se escriben archivos temporales al disco.
- **Soft delete**: las imágenes se marcan como eliminadas, no se borran físicamente.
- **Service Role Key solo en backend**: nunca se retorna al cliente.

### Pendiente para producción

- **Rate limiting**: no hay protección contra fuerza bruta en login.
- **Helmet**: no se añaden headers de seguridad HTTP adicionales.
- **JWT issuer/audience**: configurable pero no validado aún.
- **Logging estructurado**: solo `console.error` para errores 500+.
- **Health checks de load balancer**: el endpoint `/health` es básico.

## Licencia

Proyecto privado. No distribuir sin autorización.
