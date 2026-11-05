# APF3 · Capacidad, rendimiento y CI (Grupo 07)

## 1. Consola de capacidad (medición real)
- URL de producción: `https://integrador2-grupo7.vercel.app/capacidad.html` (archivo `public/capacidad.html`).
- Vive en el dominio de Vercel porque el backend solo acepta CORS desde ese origen; no se modificó el backend.
- Uso: 1) *Despertar servicio* (mide el arranque en frío) → 2) *Iniciar sesión* con un usuario OPERADOR → 3) *Escalera 1→5→10→20* o una corrida a medida → 4) revisar tabla, plan de capacidad y resumen.
- La clave se escribe en la página; solo viaja a `/api/auth/login` y el token queda en memoria (no en localStorage).
- Complementa al simulador `ITIL Capacity Ops` del docente: el simulador es un **modelo**; esta consola mide el servicio **real**.

## 2. Script de línea de comandos
`backend/rendimiento-apf3.sh` (Git Bash): despierta Render, mide arranque en frío, 3 niveles × 2 endpoints, imprime la ventana UTC y guarda TXT + CSV en `docs/evidencias/`.

```
export BASE_URL=https://rentamax-backend.onrender.com
cd backend && bash ./rendimiento-apf3.sh      # pide la clave sin mostrarla
```

## 3. Cómo se valida que la medición es real
1. Conteo cliente = conteo servidor (Render > Metrics, misma ventana UTC). El servidor suma además el login y las peticiones previas CORS (OPTIONS).
2. Ley de Little: N ≈ RPS × latencia media debe parecerse al número de usuarios virtuales.
3. CPU y RAM del servicio se toman de Render (Metrics) en la ventana de la prueba.

## 4. CI (Gestión del cambio)
- `.github/workflows/ci.yml`: backend (Java 21, `./mvnw verify`), construcción de la imagen Docker y front (compilación bloqueante; tipos, lint y pruebas informativos por deuda conocida).
- `.github/workflows/codeql.yml`: análisis estático (CodeQL) de Java y TypeScript.
- Render y Vercel despliegan desde `main` (CD). Para que Render solo despliegue con CI en verde: Render > Settings > Auto-Deploy > *After CI checks pass*.
