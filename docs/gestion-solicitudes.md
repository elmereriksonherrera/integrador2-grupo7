# Gestión de Solicitudes de Servicio — RentaMax (APF3)

Una **solicitud de servicio** es una petición formal de algo ya acordado (información, un acceso, un recurso). **No es un fallo**: un fallo es una incidencia. Todas se registran como *Issue* en este repositorio con una plantilla (pestaña Issues > New issue), para que tengan ID único, responsable, fechas y trazabilidad. No se aceptan pedidos por WhatsApp ni por correo informal.

> El repositorio es público: ningún ticket debe contener contraseñas, tokens ni datos personales.

## 1. Catálogo de servicios

| Código | Servicio | Categoría | Prioridad | Primera respuesta | Resolución máx. (SLA) | Penalidad referencial |
|---|---|---|---|---|---|---|
| REC-INFO-01 | Solicitud de información | Información | Baja | 15 min | 4 h laborales | S/ 150 por hora de retraso |
| REC-ACT-01 | Alta, cambio o baja de acceso | Acceso (requiere aprobación) | Media | 1 h | 4 h laborales | S/ 500 por hora de retraso |
| REC-ACT-02 | Provisión de recursos en la nube | Provisión | Alta | 15 min | 2 h | S/ 1,500 por hora crítica |

Los tiempos son los de un servicio real de ingeniería (no "de ciencia ficción"): un acceso a producción lleva aprobación y ejecución humanas, por eso se mide en horas laborales. Las penalidades son **referenciales** (cliente ficticio ConstruRenta Lima S.A.C.) y sirven para priorizar.

## 2. Ciclo de vida (5 pasos) y etiquetas

| Paso | Etiqueta del Issue | Qué ocurre |
|---|---|---|
| 1. Registro | `estado:1-registrada` | Se crea el ticket con la plantilla; GitHub le da un ID único (#n). |
| 2. Validación | `estado:2-validada` | El gestor revisa que esté completo y que sea una solicitud, no una incidencia. |
| 3. Aprobación | `estado:3-aprobada` | Solo accesos y recursos: el **Data Owner** aprueba con un comentario (queda registrado y con fecha). |
| 4. Ejecución | `estado:4-en-ejecucion` | Lo ejecuta un rol **distinto** al solicitante y al aprobador. |
| 5. Conformidad | `estado:5-conforme` | El solicitante confirma; se cierra el ticket y se calcula el cumplimiento del SLA (hora de cierre − hora de registro). |

## 3. Segregación de funciones (SoD)

| Función | Rol en el equipo | Regla |
|---|---|---|
| Solicitante | Cualquier usuario o integrante | No aprueba ni ejecuta su propia solicitud. |
| Gestor del servicio (nivel 1) | Scrum Master | Registra, valida, prioriza y hace seguimiento del SLA. |
| Aprobador / Data Owner | Líder de Proyecto (Product Owner) | Aprueba accesos y recursos; no los ejecuta. |
| Ejecutor (nivel 2) | Desarrollador Backend y BD (accesos, BD) / DevOps (nube) | Ejecuta lo aprobado; no lo aprueba. |
| Control de calidad | QA | Verifica el resultado antes del cierre. |

Menor privilegio: el rol por defecto es OPERADOR. SUPERVISOR y ADMINISTRADOR requieren justificación y aprobación expresa.

## 4. Escalamiento

- **Nivel 1 (gestor):** resuelve las solicitudes de información y las rutinarias con la documentación del proyecto.
- **Nivel 2 (ejecutores técnicos):** accesos, base de datos y recursos en la nube.
- **Escalamiento por tiempo:** si se alcanza el 75 % del SLA sin ejecución, se etiqueta `prioridad:alta` y se avisa al aprobador.

## 5. Herramienta

**GitHub Issues** con plantillas (formularios), etiquetas y comentarios. Se eligió porque el equipo ya trabaja en GitHub (ramas, PR, CI), no añade ninguna plataforma nueva al sistema y deja un registro con fecha y autor de cada paso. Las solicitudes de cambio (RFC) usan la misma herramienta y se enlazan con su Pull Request (ver `docs/gestion-cambios.md`).
