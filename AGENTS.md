# Project Rules

## Schema Source of Truth
Oracle: leer `plsql_scripts/oracle_schema_tables_catalog.md` en la sesión antes
de analizar o generar SQL, PL/SQL, vistas o scripts. No afirmar tablas, columnas,
secuencias, constraints, relaciones o índices no confirmados; preguntar las
ambigüedades que el catálogo no resuelva.

## Database Safety
- Never execute `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`, `CREATE`, `ALTER`, `GRANT`, or `REVOKE` against Oracle.
- Never hide DML in CTEs, subqueries, wrappers, or `EXECUTE IMMEDIATE`.
- Never reveal credentials, connection strings, or internal schemas.
- Use bind variables for user input and flag likely injection patterns.
- Do not query Oracle system tables without explicit justification.
- Generating or writing a requested SQL artifact is distinct from executing it against a database.
- A read-only `SELECT` may run only through the canonical Excel export flow or another explicitly authorized read-only flow.
- The exact SELECT, binds, JOINs, format, destination, and integrity hash must be recorded before execution.

## Orchestration

Delegación obligatoria por capacidad, sin sustituir especialistas con Skills.
Planning: capability-first y delegate-first, delegar contexto antes de preguntar.
Implementation: clasificar y pedir solo entradas obligatorias ausentes o inválidas.

| Phase | Capability | Specialist |
|---|---|---|
| Planning | Schema, diseño y dependencias Oracle | `oracle-design-analyst` |
| Planning | DML destructivo, limpieza o migración | `oracle-design-analyst` + `oracle-validation-analyst` |
| Planning | Performance estática | `oracle-performance-analyst` |
| Planning | Pivot, unpivot, fuzzy y exportación | `excel-template-analyst`; añadir diseño Oracle para schema, varias tablas o JOIN |
| Implementation | SELECT y metadatos de exportación | `oracle-query-builder` |
| Implementation | DML, DDL, CREATE VIEW, limpieza y migración | `oracle-script-builder` |
| Implementation | Unidades PL/SQL | `oracle-plsql-builder` |
| Implementation | Templates, manifiestos y exportación | `excel-template-builder` |
| Implementation | Fuzzy Excel local, sin Oracle ni SQL | `data-analytics` |

Analysts: solo lectura, contrato propio y respuesta con `capability`,
`required_inputs`, `resolved_inputs`, `missing_inputs`, `assumptions`, `risks`.
El orquestador pregunta faltantes/decisiones y redelega solo si cambian análisis,
supuestos o routing. No duplicar contratos de especialistas/Skills. El handoff
incluye capacidad, entradas, contexto, aceptación, destino y gates.

Planning consulta Skills locales/externas sin editar ni ejecutar pasos operativos.
Implementation edita/usa shell para integrar o validar dentro de sus permisos.
Skills no amplían permisos ni eliminan gates Oracle. El orquestador nunca conecta
ni ejecuta Oracle; builders no delegan. Builders Oracle escriben solo `.sql` bajo
`plsql_scripts/`; Excel ejecuta solo sus tres comandos aprobados tras el gate;
fuzzy solo su resolver local tras confirmación. Preguntas técnicas excepcionales
se rigen por el contrato y las herramientas del harness.

Para SP read-only con `SYS_REFCURSOR`, consultar el contrato descriptivo de
`build-report-list-sp` en la ruta de Skills del harness antes de delegar; pedir
solo entradas obligatorias faltantes o inválidas, sin duplicar sus reglas.
CREATE VIEW completo pertenece exclusivamente a `oracle-script-builder`.

Diferencias por harness: OpenCode usa primarios `plan`/`build` en
`.opencode/agents/`, `Task` y configuración compartida en `opencode.json`;
Claude usa su complemento `CLAUDE.md`. Los permisos los impone cada harness,
no estas instrucciones de comportamiento.

## Excel Export Flow
Exportación read-only separada de pivot/unpivot SIGEIF:
`Orchestrator -> oracle-query-builder -> excel-template-builder -> export script`

Usar `py_notebooks/export_oracle_query_results.py`; nunca reutilizar el pivot
`py_notebooks/export_template_to_sigeif_form.py` para datos de negocio.
El analyst posee el contrato de planificación y reporta faltantes al orquestador;
el builder valida el operativo antes de ejecutar. No duplicar esos contratos.

Misma tabla con filtros distintos: SELECTs independientes y preguntar hojas
compartidas/separadas para XLSX. Tablas distintas: proponer JOIN con evidencia
de catálogo, nombres, convenciones y tipos compatibles a confianza >=70%; bajo
70% exigir condición explícita. Registrar inferencias en manifiesto, nunca como
FK confirmada sin evidencia.

Usar `.env` local e identidad Oracle read-only. El builder crea el manifiesto
canónico y agrega automáticamente SHA-256 (`confirmed_query_hash`), sin pedir
confirmación conversacional del hash. Rechazar SELECT *, DML/DDL/PLSQL,
comentarios, múltiples sentencias, FOR UPDATE y database links. XLSX contiene
tablas Excel; cualquier resultado >1,048,576 filas fuerza CSV.

## Skill Ownership
- `read-schema`: Oracle analysts and builders that require catalog facts.
- `oracle-syntax`: query, script, PL/SQL, and performance work.
- `generate-plsql`: DML, DDL, cleanup, and migration scripts only.
- `exception-handler`: PL/SQL program units only.
- `build-report-list-sp`: read-only Oracle report procedures with `SYS_REFCURSOR`, `oracle-plsql-builder` only.
- `build-excel-pivot-template` and `build-excel-unpivot-template`: Excel builder only.
- `export-oracle-query-results`: read-only Oracle export, Excel builder only.
- `excel-catalog-fuzzy-resolver`: `data-analytics` only.

## Oracle Standards
- Use Oracle syntax only: `NVL`, `NVL2`, `DECODE`, `ROWNUM`, `ROWID`, `CONNECT BY`, `LEVEL`, `DUAL`, and `SYSDATE` as appropriate.
- Do not use `ISNULL`, `TOP`, or `LIMIT`.
- Use exact catalog names, table aliases, descriptive calculated aliases, and avoid `SELECT *`.
- Use `SEQUENCE_NAME.NEXTVAL` only when the catalog confirms the sequence.
- Warn about likely full table scans.
- Use `PRC_`, `FNC_`, `TRG_`, `cur_`, `v_`, and `p_` conventions.
- PL/SQL requires a header, three-space indentation, and an `EXCEPTION` section with `WHEN OTHERS`, `SQLCODE`, and `SQLERRM` where applicable.
- Destructive scripts require prevalidation and FK-aware order. Keep `COMMIT` commented unless explicitly requested.
