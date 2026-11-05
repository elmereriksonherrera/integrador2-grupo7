# Plan de Control de Cambios — RentaMax (APF3)

Objetivo: que todo cambio a la **aplicación**, la **infraestructura**, la **documentación** o el **calendario** sea solicitado, evaluado, aprobado, probado y reversible, sin interrumpir el servicio en producción.

## 1. Tipos de cambio

| Tipo | Cuándo | Aprobación | Ejemplo |
|---|---|---|---|
| Estándar | Bajo riesgo, repetible, ya probado | Preaprobado; CI en verde | Actualizar un texto o la documentación |
| Normal | Cambia comportamiento o infraestructura | Revisión de otro integrante + CI verde | Nuevo endpoint, cambio de variable en Render |
| Emergencia | Restablecer un servicio caído | Aprobación verbal inmediata y RFC registrado **después** | Base de datos de Aiven apagada (caso real, 4-5 nov 2026) |

## 2. Flujo de un cambio normal

1. **Solicitud (RFC):** se abre un Issue con la plantilla "RFC · Solicitud de cambio" (tipo, ámbito, riesgo, plan de reversa, ventana).
2. **Desarrollo en rama:** `feature/...` o `fix/...`. No se edita `main` directamente.
3. **Pull Request:** con la plantilla del repositorio; enlaza el RFC (`Cierra #n`).
4. **Integración continua (CI):** GitHub Actions compila, prueba y valida (ver sección 4). Sin CI verde no se fusiona.
5. **Revisión y aprobación:** el comité de cambios (Líder de Proyecto + Scrum Master) revisa el PR; el autor no aprueba su propio cambio.
6. **Fusión a `main`:** dispara el despliegue automático (Render para el backend, Vercel para el front).
7. **Verificación posterior:** `/api/health`, login y, si aplica, `pruebas.sh`.
8. **Cierre:** se anota el resultado en el RFC. Si falla: **reversa** (revertir el PR o redesplegar el commit anterior desde Render).

## 3. Calendario de cambios

- Ventana normal: lunes a viernes después de las 20:00 (Lima), fuera del horario de uso.
- Congelamiento: 24 h antes de cada exposición del avance de proyecto (solo cambios de emergencia).
- Mantenimiento de Aiven: según su ventana semanal (ver Overview del servicio).

## 4. Integración Continua (CI) y análisis estático

| Flujo | Qué hace | Cuándo |
|---|---|---|
| `ci.yml` — CI RentaMax | Backend: Java 21 + `./mvnw verify` (JUnit 5 y Mockito). Docker: construye la misma imagen que usa Render. Front: instala con `npm ci` y compila (`vite build`); tipos, lint y pruebas se reportan como informativos (deuda técnica registrada). | Cada push y cada Pull Request |
| `codeql.yml` — Análisis estático | CodeQL para Java y TypeScript (equivalente a la etapa SonarQube del flujo de clase). | Push/PR a `main` y cada lunes |
| `cargar-bd.yml` | Carga manual y puntual del esquema y datos en una base nueva de Aiven, sin instalar clientes. | A demanda (ejecución manual) |

Entrega continua (CD): Render y Vercel despliegan desde `main`. Opcional recomendado: en Render > Settings > Auto-Deploy elegir *After CI checks pass* para que producción solo despliegue con CI en verde.

## 5. Protección de `main`

Configuración en GitHub (Settings > Branches > Add branch ruleset): exigir Pull Request y que pasen los checks de CI antes de fusionar.

## 6. Registro de cambios relevantes

| Fecha | Cambio | Tipo | Resultado |
|---|---|---|---|
| 2026-11-04 | PR #6: CI, CodeQL y herramientas de capacidad | Normal | CI en verde, fusionado |
| 2026-11-04/05 | Reemplazo de la base de datos de Aiven (fin de la prueba) y carga automatizada | Emergencia | Servicio restablecido (Render "Live" a las 00:02) |
