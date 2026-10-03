# RentaMax — Back-End (Spring Boot) · APF2

Curso Integrador II (UTP) · Grupo 07 · Avance de Proyecto Final 2.
Versiones: Spring Boot 3.4.10 · Spring Security 6.4 · Hibernate 6.6 · jjwt 0.12.5 · MySQL 8.0 · Java 21 (compatible con tu JDK 22).

## Qué hace
API REST con **autenticación JWT + BCrypt**, **RBAC por permisos guardados en la base de datos** y **CRUD de equipos** sobre MySQL con JPA.
El esquema lo define `../database/schema_v1.sql` (fuente de verdad). Hibernate corre en `ddl-auto=validate`: **no crea tablas**, solo comprueba que las entidades coincidan con el script; si no coinciden, la aplicación no arranca.

## Arquitectura por capas
```
controller/  recibe HTTP y valida (@Valid)          Auth, Equipo, Categoria, Cliente, Admin, Health
service/     reglas de negocio                      AuthService, EquipoService
repository/  acceso a datos (JPA, consultas parametrizadas)   Rol, Usuario, Categoria, Equipo, Cliente
model/       entidades JPA = tablas de schema_v1.sql          Rol, Usuario, Categoria, Equipo, Cliente
dto/         datos de entrada/salida (nunca se expone la entidad)
security/    JwtService (firma y lee el token), JwtAuthFilter (filtro por peticion)
config/      SecurityConfig (rutas, CORS, BCrypt), DataInitializer (roles y admin inicial)
exception/   errores JSON uniformes (400, 401, 403, 404, 409)
```

## Mapeo API → Base de datos
| Campo en la API | Tabla.columna | Nota |
|---|---|---|
| `email` | `usuario.correo` | el DTO conserva el nombre estándar `email` |
| `password` | `usuario.contrasena_hash` | se guarda solo el hash BCrypt (`$2a$10$…`) |
| rol (`ADMINISTRADOR`/`SUPERVISOR`/`OPERADOR`) | `rol.nombre` vía `usuario.rol_id` (FK) | |
| permisos `ALTA_EQUIPO`, `VER_DOC_COMPLETO` | `rol.permisos_alta_equipo`, `rol.permisos_ver_doc_completo` | viajan dentro del JWT |
| `categoriaId`, `stockDisponible`, `stockMinimo` | `equipo.categoria_id`, `stock_disponible`, `stock_minimo` | |

## Endpoints y permisos
| Método y ruta | OPERADOR | SUPERVISOR | ADMINISTRADOR |
|---|:-:|:-:|:-:|
| `GET /api/health`, `POST /api/auth/login`, `POST /api/auth/register` (crea OPERADOR) | público | público | público |
| `GET /api/equipos`, `/api/equipos/{id}`, `/api/categorias` | ✅ | ✅ | ✅ |
| `GET /api/clientes` | teléfono enmascarado | completo | completo |
| `POST` / `PUT /api/equipos` | 403 | ✅ | ✅ |
| `DELETE /api/equipos/{id}` | 403 | 403 | ✅ |
| `GET /api/admin/usuarios`, `/api/admin/roles` | 403 | 403 | ✅ |

Sin token o con token inválido/alterado: **401**. Equipo inexistente: **404**. Datos inválidos (XSS, estado fuera del catálogo, stock negativo…): **400**. Código duplicado o borrar un equipo con alquileres: **409**.

## Controles de seguridad (OWASP)
| Riesgo | Control en el código |
|---|---|
| A01 Control de acceso roto | RBAC en `SecurityConfig` **y** `@PreAuthorize` en los métodos (defensa en profundidad); el rol del registro público no se puede elegir |
| A02 Fallas criptográficas | BCrypt para contraseñas; JWT firmado (HS384); la clave JWT sale de variable de entorno y debe tener ≥ 256 bits |
| A03 Inyección | Spring Data JPA con consultas parametrizadas; validación de DTO (`@Pattern`, `@Email`, `@Size`); CHECK/UNIQUE/FK en la base |
| A05 Configuración | CORS solo para el front de Vercel; errores sin trazas; perfil `prod` sin valores por defecto (fail-fast) |
| A07 Autenticación | mensaje único "Credenciales inválidas" (no revela qué correos existen); token con expiración de 1 hora |

## Cómo correrlo en tu laptop (VS Code, Windows)
1. **Un solo MySQL en el puerto 3306:** cierra XAMPP/Wamp y deja activo el servicio `MySQL80`.
2. **Base de datos (HeidiSQL, conectado como root):** abre y ejecuta, en este orden, `database/schema_v1.sql`, `database/usuario_aplicacion.sql` y `database/seed_v1.sql`.
3. **VS Code:** instala la extensión *Extension Pack for Java* y abre la carpeta `backend`. En la terminal, `java -version` debe decir 22.
4. **Arrancar:** en la terminal de VS Code, dentro de `backend`: `.\mvnw.cmd spring-boot:run`. La primera vez descarga Maven y las librerías (unos minutos). Espera `Started RentaMaxApplication`.
5. **Comprobar:** abre http://localhost:8080/api/health → debe mostrar `"estado":"UP","baseDatos":"UP"`.
6. **Pruebas:** en Git Bash, `cd backend && ./pruebas.sh` (resultado esperado: `FALLOS=0`). Para carga: `./rendimiento.sh 200 20`. Para Postman: importar `RentaMax-APF2.postman_collection.json` y usar *Run collection*.

Cuentas de demostración (las del seed y del front de Vercel): `admin@rentamax.pe` / `Admin2026` · `ana.silva@rentamax.pe` / `RentaMax2026` · `carlos.mendoza@rentamax.pe` / `RentaMax2026`.

## Variables de entorno en la nube (perfil `prod`, ya activo en el Dockerfile)
| Variable | Ejemplo / uso |
|---|---|
| `DB_URL` | `jdbc:mysql://HOST:PUERTO/rentamax?sslMode=REQUIRED&serverTimezone=America/Lima` |
| `DB_USER`, `DB_PASSWORD` | credenciales de la base en Aiven |
| `JWT_SECRET` | clave Base64 de ≥ 32 bytes (se genera una nueva para producción) |
| `CORS_ORIGINS` | `https://integrador2-grupo7.vercel.app` |
| `ADMIN_EMAIL`, `ADMIN_PASSWORD` | opcionales: solo se usan si la BD no tiene ningún administrador |

Si falta una variable obligatoria o la clave JWT es débil, la aplicación **no arranca**.

## Alcance actual y próximo sprint
Implementado: autenticación, RBAC, CRUD de equipos, lectura de categorías y clientes sobre la BD real.
Mapeadas en la BD pero sin API todavía: `alquiler` y `devolucion` (Sprint 5).
