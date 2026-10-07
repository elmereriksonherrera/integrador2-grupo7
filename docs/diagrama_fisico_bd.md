# Diagrama físico de la base de datos — RentaMax (MySQL 8 en Aiven)

Fuente de verdad: `database/schema_v1.sql`. Motor InnoDB, FK con restricciones nombradas, índices B-Tree
(UNIQUE y FK se indexan solos). Hibernate corre con `ddl-auto=validate` (no modifica las tablas).

```mermaid
erDiagram
    ROL ||--o{ USUARIO : "tiene (rol_id)"
    CATEGORIA ||--o{ EQUIPO : "clasifica (categoria_id)"
    EQUIPO ||--o{ ALQUILER : "se alquila (equipo_id)"
    CLIENTE ||--o{ ALQUILER : "solicita (cliente_id)"
    USUARIO ||--o{ ALQUILER : "registra (usuario_id)"
    ALQUILER ||--o| DEVOLUCION : "se cierra con (alquiler_id UNIQUE)"

    ROL {
        INT id PK
        VARCHAR50 nombre UK
        BOOLEAN permisos_alta_equipo
        BOOLEAN permisos_ver_doc_completo
    }
    USUARIO {
        INT id PK
        VARCHAR100 nombre
        VARCHAR150 correo UK
        VARCHAR255 contrasena_hash "BCrypt $2a$10$"
        INT rol_id FK
    }
    CATEGORIA {
        INT id PK
        VARCHAR60 nombre UK
    }
    EQUIPO {
        INT id PK
        VARCHAR20 codigo UK
        VARCHAR100 nombre
        INT categoria_id FK
        VARCHAR20 estado "DISPONIBLE|ALQUILADO|MANTENIMIENTO|BAJA"
        INT stock_disponible "CHECK >= 0"
        INT stock_minimo "CHECK >= 0"
    }
    CLIENTE {
        INT id PK
        VARCHAR150 nombre
        VARCHAR20 documento_enmascarado UK
        VARCHAR20 telefono
    }
    ALQUILER {
        INT id PK
        VARCHAR20 codigo UK
        INT equipo_id FK
        INT cliente_id FK
        INT usuario_id FK
        DATE fecha_inicio
        DATE fecha_pactada_devolucion "CHECK > fecha_inicio"
        VARCHAR20 estado "ACTIVO|DEVUELTO|ATRASADO|CANCELADO"
    }
    DEVOLUCION {
        INT id PK
        INT alquiler_id FK,UK
        DATE fecha_real
        VARCHAR30 estado_equipo
        DECIMAL82 mora_calculada "CHECK >= 0"
        VARCHAR255 observaciones
    }
```

## Conexión (pool HikariCP)

`maximum-pool-size=10` · `minimum-idle=5` · `connection-timeout=20000` · `idle-timeout=600000` · `max-lifetime=1800000`.
Credenciales solo por variables de entorno (`SPRING_DATASOURCE_URL/USERNAME/PASSWORD`, o `DB_URL/DB_USER/DB_PASSWORD`).
