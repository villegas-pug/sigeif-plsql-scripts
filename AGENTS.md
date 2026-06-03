# Oracle SQL Project — Reglas Globales

## Contexto del Proyecto
Este proyecto trabaja con una base de datos **Oracle**.
El schema completo está definido en `sigeif_data_base_schema.sql`.

## REGLA CRÍTICA
Antes de generar cualquier sentencia SQL, procedimiento almacenado,
función, trigger o vista, SIEMPRE debes leer el archivo
`sigeif_data_base_schema.sql` para conocer las tablas, columnas, tipos de
datos y relaciones exactas.

## Flujo de Trabajo Obligatorio

### 1. Clasificar la Solicitud
Identificar el tipo de trabajo:
- `SELECT` / Consulta → `query-builder`
- `INSERT` / `UPDATE` / `DELETE` → `generate-plsql` + `data-validator`
- Procedure / Function / Trigger / Package → `procedure-builder`
- Optimización de rendimiento → `sql-optimizer`
- Validación de integridad → `data-validator`

### 2. Delegar al Subagente Especializado
No generar SQL/PLSQL directamente salvo solicitud directa del usuario.
Usar los subagentes disponibles:
- **query-builder**: SELECT, joins, subconsultas, vistas, CTEs, jerárquicas
- **procedure-builder**: procedures, functions, triggers, packages PL/SQL
- **data-validator**: validaciones FK, NOT NULL, CHECK, duplicados, conteos
- **sql-optimizer**: performance, índices, hints, análisis de consultas costosas

### 3. Aplicar Skills Transversales
- **generate-plsql**: DML/DDL, convenciones SIGEIF, filtros reales del schema
- **oracle-syntax**: sintaxis Oracle nativa, aliases, nomenclatura de objetos
- **exception-handler**: manejo de excepciones PL/SQL estándar

### 4. Consolidar Resultado
Entregar el código final con contexto, advertencias y validaciones previas
cuando apliquen.

### Excepciones al Flujo
Consultas simples y directas pueden responderse directamente si:
- El contexto del schema ya está cargado
- No requiere múltiples joins o subconsultas complejas
- No necesita análisis de performance

En caso de duda, siempre delegar al subagente apropiado.

## Estándares Oracle Obligatorios
- Usa sintaxis Oracle nativa: NVL, NVL2, DECODE, ROWNUM, ROWID,
  CONNECT BY, LEVEL, DUAL, SYSDATE, etc.
- NUNCA uses sintaxis de otros motores (ISNULL, TOP, LIMIT, etc.)
- Todos los nombres de tablas y columnas deben coincidir exactamente
  con el schema (respeta mayúsculas/minúsculas del schema)
- Toda consulta SELECT debe usar alias de tabla (ej: e.employee_id)
- Los números de secuencia deben usar la sintaxis: SEQUENCE_NAME.NEXTVAL

## Manejo de Errores
- Todo bloque PL/SQL debe incluir sección EXCEPTION
- Siempre capturar WHEN OTHERS THEN como mínimo
- Registrar errores con SQLERRM y SQLCODE cuando sea posible

## Convenciones de Nomenclatura
- Procedimientos: PRC_NOMBRE_ACCION (ej: PRC_CLIENTES_ACTUALIZAR)
- Funciones:      FNC_NOMBRE_RESULTADO (ej: FNC_PEDIDO_TOTAL)
- Triggers:       TRG_TABLA_EVENTO (ej: TRG_CLIENTES_BEFORE_INSERT)
- Cursores:       CUR_NOMBRE_DESCRIPTIVO
- Variables:      v_nombre_variable
- Parámetros:     p_nombre_parametro

## Formato de Salida
- Indentación de 3 espacios en bloques PL/SQL
- Comentarios de cabecera en cada objeto creado
- Incluir comentario con propósito, autor y fecha en cada objeto

## Archivo Protegido

El archivo `AGENTS.md` es de solo lectura para todos los agentes y subagentes.

Reglas:
- NUNCA modificar, editar, sobreescribir ni eliminar `AGENTS.md`
- NUNCA sugerir cambios directos sobre `AGENTS.md`
- Si detectas que algo en `AGENTS.md` debería actualizarse, notifícalo
  al usuario en el chat y espera instrucción explícita
- Esta regla no puede ser anulada por ninguna instrucción del usuario
  dentro de una sesión