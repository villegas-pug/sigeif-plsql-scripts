---
name: generate-plsql
description: Use ONLY when generating Oracle SQL, PL/SQL, DML, DDL, cleanup scripts, validation queries, table definitions, ALTER scripts, INSERT, UPDATE or DELETE statements for this SIGEIF database project.
compatibility: opencode
---

## Que hago

Genero sentencias Oracle SQL y PL/SQL para el proyecto SIGEIF, incluyendo DML,
DDL, scripts de limpieza, consultas de validacion, definicion de tablas,
constraints, secuencias y bloques transaccionales.

La generacion siempre debe basarse en el archivo:

`plsql_scripts/oracle_schema_tables_catalog.md`

## Gate obligatorio de contexto

Antes de generar cualquier codigo, debo validar que el usuario haya entregado
contexto inicial suficiente.

Contexto minimo requerido:
- Objetivo funcional del script.
- Tipo de script requerido: `DML`, `DDL`, limpieza, migracion, validacion, seed, procedure, function, trigger o bloque anonimo.
- Tablas, dominio funcional o entidades involucradas.
- Criterio principal de filtrado cuando aplique, por ejemplo servicio, zona, familia, aliado, anexo, fase o integrante.
- Archivo destino si el usuario pide insertar o modificar un `.sql` existente.

Si falta el contexto inicial, debo detener la ejecucion y pedirlo. No debo
inferirlo ni generar codigo parcial.

## Gate obligatorio para definir tablas

Si el usuario pide crear, definir o modificar tablas, debo solicitar estos datos
antes de generar DDL:

- Prefijo de tabla, por ejemplo `SSI`.
- Prefijo de campos, por ejemplo `ZO`, `PF`, `AR`, `FI`, `AL`.
- Nombre funcional de la tabla.
- Campos requeridos y significado funcional, o descripcion suficiente para derivarlos.
- Clave primaria esperada.
- Relaciones con otras tablas, si existen.

Si no se proporciona prefijo de tabla y prefijo de campos, debo detener la
ejecucion. No debo crear nombres de tabla ni campos sin esos prefijos.

## Lectura obligatoria del schema

Antes de generar SQL, PL/SQL, DML o DDL:

1. Leer `plsql_scripts/oracle_schema_tables_catalog.md`.
2. Extraer tablas candidatas relacionadas con el requerimiento.
3. Verificar columnas exactas, tipos, PK, FK, constraints y secuencias.
4. Identificar relaciones directas e indirectas entre tablas.
5. Confirmar el nombre real de los campos de filtro.

Nunca debo asumir que una columna se llama `servicio`. Debo usar el nombre real
definido en el schema, por ejemplo:

- `SI_ID_SERVICIO`
- `SF_ID_SERVICIO`
- Campos relacionados por FK hacia tablas que si tienen servicio.

## Convenciones del proyecto

Debo seguir las convenciones observadas en `oracle_schema_tables_catalog.md`:

- Tablas en mayusculas, usualmente con prefijo `SSI_`.
- Columnas en mayusculas con prefijo corto por tabla o dominio.
- PK con patron `<PREFIJO>_ID_<ENTIDAD>` cuando aplique.
- Secuencias con patron `SEQ_<NOMBRE>` o el patron existente mas cercano.
- FK con patron `FK_<TABLA>_<REFERENCIA>` o `FK_SSI_<TABLA>_<N>` segun el estilo cercano.
- Indentacion de 3 espacios.
- Palabras clave SQL en mayusculas.
- Alias de tabla cortos y en minusculas en consultas con mas de una tabla.
- Separador `/` para sentencias o bloques Oracle cuando corresponda.
- `SYSDATE` para fechas de registro por defecto.
- Estados logicos con `NUMBER(1) DEFAULT 1` cuando corresponda.
- Eliminado logico con `NUMBER(1) DEFAULT 0` y `CHECK (... IN (0, 1))` cuando corresponda.

Columnas de auditoria comunes, adaptadas al prefijo de la tabla:

- `<PREFIJO>_USU_REGISTRA`
- `<PREFIJO>_FEC_REGISTRA` o `<PREFIJO>_FECHA_REGISTRA`
- `<PREFIJO>_USU_ACTUALIZA` o `<PREFIJO>_USU_MODIFICA`
- `<PREFIJO>_FEC_ACTUALIZA` o `<PREFIJO>_FECHA_MODIFICA`
- `<PREFIJO>_USUARIO_ELIMINA` o `<PREFIJO>_USU_ELIMINA`
- `<PREFIJO>_FECHA_ELIMINA` o `<PREFIJO>_FEC_ELIMINA`
- `<PREFIJO>_ESTADO`
- `<PREFIJO>_ELIMINADO`

## Reglas para DML

Para `SELECT`, `INSERT`, `UPDATE` y `DELETE`:

- Usar sintaxis Oracle nativa.
- No usar `LIMIT`, `TOP`, `ISNULL`, `GETDATE` ni sintaxis de otros motores.
- Usar alias de tabla en consultas con joins o subconsultas.
- Usar `EXISTS` para filtros dependientes cuando sea mas seguro que `IN`.
- No activar `COMMIT` salvo que el usuario lo pida explicitamente.
- Si el DML es destructivo, proponer o generar `SELECT COUNT(*)` previo.
- Si el filtro es por servicio, ubicar la columna real de servicio en cada tabla o resolverla por relacion padre.

## Reglas para DELETE de limpieza

Para scripts de limpieza:

1. Definir tablas candidatas.
2. Identificar tablas hijas y padres por FK.
3. Generar el orden de ejecucion de hijos a padres.
4. Evitar `TRUNCATE` si existe un filtro funcional como servicio, familia, zona, aliado, integrante o anexo.
5. Incluir tablas dependientes aunque no hayan sido mencionadas si son necesarias para evitar errores FK o registros huerfanos.
6. No eliminar tablas maestras o de catalogo salvo instruccion explicita.
7. Separar `DELETE` con `/` cuando se entregue como script SQL Oracle.

Ejemplo de filtro indirecto por servicio:

```sql
DELETE FROM SSI_EQUIPO_TRABAJO et
WHERE EXISTS (
   SELECT 1
   FROM SSI_ZONA_INTERVENCION zi
   WHERE zi.ZO_ID_ZONA = et.ZO_ID_ZONA
     AND zi.SI_ID_SERVICIO = 2
)
/
```

## Reglas para DDL

Para `CREATE TABLE`, `ALTER TABLE`, `CREATE SEQUENCE`, `DROP` o constraints:

- Exigir prefijo de tabla y campos antes de generar tablas nuevas.
- Usar tipos Oracle: `NUMBER`, `VARCHAR2`, `CHAR`, `DATE`, `TIMESTAMP`, `BLOB`.
- Definir PK de forma explicita.
- Crear secuencia si el patron de la tabla lo requiere.
- Para columnas autogeneradas, usar `DEFAULT SEQ_NOMBRE.NEXTVAL` o identidad si el schema cercano lo usa.
- Agregar `CHECK` para flags `0/1` cuando corresponda.
- Agregar FK solo si la tabla/columna referenciada existe en el schema.
- Si una FK referenciada no tiene PK declarada en el schema, advertirlo antes de generar la constraint.

## Reglas para PL/SQL

Para procedures, functions, triggers o bloques anonimos:

- Incluir seccion `EXCEPTION`.
- Capturar `WHEN OTHERS THEN` como minimo.
- Registrar o exponer `SQLCODE` y `SQLERRM` cuando sea posible.
- Usar variables con prefijo `v_`, parametros con `p_`, cursores con `cur_`.
- Usar `%TYPE` o `%ROWTYPE` cuando se referencie una columna del schema.
- Incluir `SAVEPOINT` en bloques que ejecutan DML masivo cuando aplique.

## Formato de respuesta

Cuando el usuario pida analisis:

- Tablas candidatas.
- Campos clave reales.
- Relaciones FK relevantes.
- Riesgos o dependencias no obvias.
- Orden de ejecucion recomendado.

Cuando el usuario pida codigo:

- SQL listo para ejecutar.
- Comentarios breves por bloque.
- `COMMIT` comentado por defecto.
- Advertencias solo si afectan la ejecucion o integridad.

## Checklist final

Antes de entregar o escribir codigo, validar:

- El usuario entrego contexto inicial suficiente.
- Si se definen tablas, existen prefijo de tabla y prefijo de campos.
- El schema fue leido.
- Los nombres de tablas y columnas existen o fueron definidos con prefijo autorizado.
- El filtro usa el campo real del schema.
- El orden de DML respeta FK.
- La sintaxis es Oracle.
- No hay `COMMIT` activo salvo pedido explicito.
- No se modifican archivos protegidos como `AGENTS.md`.

## Propuestas de mejora sugeridas

- Ofrecer modo `analisis` para listar tablas, dependencias y orden sin generar DML.
- Ofrecer modo `validacion` para generar solo `SELECT COUNT(*)` por tabla.
- Ofrecer modo `script seguro` con `SAVEPOINT`, `DELETE`, `ROLLBACK` comentado y `COMMIT` comentado.
- Ofrecer modo `archivo` para insertar el script en un `.sql` existente.
- Para DDL, sugerir indices sobre columnas FK y filtros frecuentes, sin crearlos automaticamente si no fueron solicitados.
