-- =====================================================================
-- Usuario de la APLICACIÓN con mínimo privilegio (no usar root).
-- Solo puede leer y escribir datos; NO puede crear, alterar ni borrar tablas.
-- Ejecutar DESPUÉS de schema_v1.sql, conectado como root (solo en MySQL local).
-- En Aiven se usa el usuario que entrega el proveedor.
-- =====================================================================
CREATE USER IF NOT EXISTS 'rentamax'@'localhost' IDENTIFIED BY 'rentamax123';
GRANT SELECT, INSERT, UPDATE, DELETE ON rentamax.* TO 'rentamax'@'localhost';
FLUSH PRIVILEGES;
