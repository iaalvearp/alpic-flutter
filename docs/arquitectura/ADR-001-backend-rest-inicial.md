# ADR-001: Infraestructura REST inicial para AlPics

- Estado: aceptado para la fase inicial.
- Alcance: únicamente infraestructura del backend; no incluye CRUD, JWT
  funcional, roles, Supabase ni integración externa.

## Decisiones

1. El backend vive en `backend/` y se mantiene independiente del código
   Flutter.
2. La tecnología inicial es Node.js, Express y TypeScript.
3. El flujo HTTP se separa en `routes`, `controllers`, `services` y
   `middleware`.
4. La persistencia se conectará mediante `repositories`; los detalles de
   Supabase no deben llegar a controllers ni a routes.
5. Los contratos de transporte se ubican en `dtos` y los tipos propios del
   backend en `models`.
6. JWT e integraciones externas se incorporan mediante adaptadores, sin
   activarlos hasta definir sus contratos.
7. `GET /health` es el primer endpoint verificable y no requiere autenticación.

## Consecuencias

- El cliente Flutter no cambia en esta fase.
- Se puede añadir el primer slice de imágenes sin mezclar HTTP con persistencia.
- Aún falta decidir el contrato de autenticación, el esquema Supabase y el
  transporte de archivos antes de implementar CRUD.
