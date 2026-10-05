# Project Rules

## Instruction Loading
Este archivo contiene las reglas comunes a todos los harnesses. OpenCode lo carga
de forma nativa e ignora `CLAUDE.md`; Claude Code lo carga mediante `@AGENTS.md`
desde `CLAUDE.md`. Lo propio de cada harness va solo en su complemento:
`.opencode/agents/` y `opencode.json`, o `CLAUDE.md` y `.claude/`.

- Delegar con la herramienta de subagentes del harness: `Task` (OpenCode) o
  `Agent` (Claude). Preguntar con `question` (OpenCode) o `AskUserQuestion`
  (Claude, solo el agente principal).
- Skills: fuente única en `.claude/skills/`, que ambos harnesses leen. Su contenido
  es neutral al harness. No duplicarlas en `.opencode/skills/` ni `.agents/skills/`,
  no migrarlas con `harness-sync` y no definir `OPENCODE_DISABLE_CLAUDE_CODE` ni
  `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS`.
- Precedencia: Database Safety > este archivo > complemento del harness >
  contratos de especialistas y Skills. Ante un conflicto, aplicar la regla más
  restrictiva y reportarlo.
- Tras editar instrucciones, agentes o Skills, validar con
  `python .claude/hooks/validate_harness.py`.

## Schema Source of Truth
Oracle: leer `plsql_scripts/oracle_schema_tables_catalog.md` en la sesión antes
de analizar o generar SQL, PL/SQL, vistas o scripts. No afirmar tablas, columnas,
secuencias, constraints, relaciones o índices no confirmados; preguntar las
ambigüedades que el catálogo no resuelva.

## Database Safety
- Nunca ejecutar `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`, `CREATE`, `ALTER`, `GRANT` ni `REVOKE` contra Oracle.
- Nunca ocultar DML en CTEs, subconsultas, wrappers ni `EXECUTE IMMEDIATE`.
- Nunca revelar credenciales, cadenas de conexión ni schemas internos.
- Usar bind variables para entradas del usuario y señalar patrones probables de inyección.
- No consultar tablas de sistema de Oracle sin justificación explícita.
- Generar o escribir un artefacto SQL solicitado es distinto de ejecutarlo contra una base de datos.
- Ni el orquestador ni los especialistas conectan a Oracle ni invocan clientes (`sqlplus`, SQLcl, drivers o scripts propios); la única excepción son los comandos aprobados del builder Excel, ejecutados tras su gate.
- Un `SELECT` read-only solo puede ejecutarse mediante el flujo canónico de exportación Excel u otro flujo read-only autorizado explícitamente.
- Antes de ejecutar deben quedar registrados el SELECT exacto, binds, JOINs, formato, destino y hash de integridad.

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

Planning consulta Skills sin editar ni ejecutar pasos operativos.
Implementation edita/usa shell para integrar o validar dentro de sus permisos.
Skills no amplían permisos ni eliminan gates Oracle. El orquestador nunca conecta
ni ejecuta Oracle; builders no delegan. Builders Oracle escriben solo `.sql` bajo
`plsql_scripts/`; Excel ejecuta solo sus tres comandos aprobados tras el gate;
fuzzy solo su resolver local tras confirmación. Preguntas técnicas excepcionales
se rigen por el contrato y las herramientas del harness.

Para SP read-only con `SYS_REFCURSOR`, leer el contrato descriptivo en
`.claude/skills/build-report-list-sp/SKILL.md` antes de delegar, sin cargar la
Skill operativa; pedir solo entradas obligatorias faltantes o inválidas, sin
duplicar sus reglas. CREATE VIEW completo pertenece exclusivamente a
`oracle-script-builder`.

Los permisos los impone cada harness, no estas instrucciones de comportamiento.

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
- `read-schema`: analysts y builders Oracle que requieren hechos del catálogo.
- `oracle-syntax`: trabajo de query, script, PL/SQL y performance.
- `generate-plsql`: solo scripts DML, DDL, limpieza y migración.
- `exception-handler`: solo unidades de programa PL/SQL.
- `build-report-list-sp`: procedures Oracle de reporte read-only con `SYS_REFCURSOR`; solo `oracle-plsql-builder`.
- `build-excel-pivot-template` y `build-excel-unpivot-template`: solo el builder Excel.
- `export-oracle-query-results`: exportación Oracle read-only; solo el builder Excel.
- `excel-catalog-fuzzy-resolver`: solo `data-analytics`.

## Oracle Standards
- Usar solo sintaxis Oracle: `NVL`, `NVL2`, `DECODE`, `ROWNUM`, `ROWID`, `CONNECT BY`, `LEVEL`, `DUAL` y `SYSDATE` según corresponda.
- No usar `ISNULL`, `TOP` ni `LIMIT`.
- Usar nombres exactos del catálogo, alias de tabla y alias descriptivos para campos calculados; evitar `SELECT *`.
- Usar `SEQUENCE_NAME.NEXTVAL` solo cuando el catálogo confirme la secuencia.
- Advertir sobre probables full table scans.
- Usar las convenciones `PRC_`, `FNC_`, `TRG_`, `cur_`, `v_` y `p_`.
- PL/SQL requiere header, indentación de tres espacios y sección `EXCEPTION` con `WHEN OTHERS`, `SQLCODE` y `SQLERRM` donde aplique.
- Los scripts destructivos requieren prevalidación y orden según FK. Mantener `COMMIT` comentado salvo petición explícita.
