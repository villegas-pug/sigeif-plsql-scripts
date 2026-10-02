# Oracle SQL Project - Global Rules

## Schema Source of Truth
This project uses Oracle. The authoritative schema catalog is
`plsql_scripts/oracle_schema_tables_catalog.md`.

Before analyzing or building any Oracle SQL, PL/SQL, view, or script, read the
catalog in the current session. Never infer tables, columns, sequences,
constraints, relationships, or indexes as confirmed facts. Ask when the catalog
does not resolve an ambiguity.

## Database Safety
- Never execute `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`, `CREATE`, `ALTER`, `GRANT`, or `REVOKE` against Oracle.
- Never hide DML in CTEs, subqueries, wrappers, or `EXECUTE IMMEDIATE`.
- Never reveal credentials, connection strings, or internal schemas.
- Use bind variables for user input and flag likely injection patterns.
- Do not query Oracle system tables without explicit justification.
- Generating or writing a requested SQL artifact is distinct from executing it against a database.
- A read-only `SELECT` may run only through the canonical Excel export flow or another explicitly authorized read-only flow.
- The exact SELECT, binds, JOINs, format, destination, and integrity hash must be recorded before execution.

## Plan and Build Architecture
The project uses OpenCode built-in primary agents `plan` and `build`. Their
project-specific prompts and permissions are configured in
`.opencode/agents/plan.md` and `.opencode/agents/build.md`; root
`opencode.json` contains only shared project configuration.

`plan` delegates Oracle/Excel technical analysis through Task only to:
- `oracle-design-analyst`: schema, dependencies, and implementation options.
- `oracle-validation-analyst`: integrity constraints and prevalidation.
- `oracle-performance-analyst`: performance, indexes, and tuning risks.
- `excel-template-analyst`: pivot, unpivot, catalog resolution, and export inputs.

Planning is capability-first and delegate-first: Plan routes the available
context before asking the user. Each analyst owns its input contract and returns
`capability`, `required_inputs`, `resolved_inputs`, `missing_inputs`,
`assumptions`, and `risks`. Plan asks only for reported `missing_inputs` and
redelegates only when the answers change the technical analysis, assumptions,
or routing.

`build` delegates domain implementation through Task only to:
- `oracle-query-builder`: SELECT queries and structured export query data; never executes Oracle.
- `oracle-script-builder`: DML, DDL (including `CREATE VIEW`), cleanup, and migration SQL artifacts.
- `oracle-plsql-builder`: procedures, functions, triggers, packages, and anonymous blocks.
- `excel-template-builder`: SIGEIF templates, export manifests, and Oracle result exports.
- `data-analytics`: local fuzzy catalog resolution; no Oracle or SQL.

Plan permanece sin edicion ni Skills operativas. Build conserva capacidades normales de edicion y shell para integrar, validar y consolidar cambios, pero mantiene los gates de seguridad Oracle. Analysts are read-only and own their capability contracts; root rules and Plan must not duplicate those input lists.
Builders do not delegate. Oracle builders may write only `.sql` artifacts under
`plsql_scripts/`. Excel builder may execute only the three approved Python
commands after the applicable input gate. `data-analytics` may execute only
its local resolver command after confirmation.

## Excel Export Flow
The generic read-only export flow is separate from SIGEIF pivot/unpivot:

`Build -> oracle-query-builder -> excel-template-builder -> export script`

The export script is `py_notebooks/export_oracle_query_results.py`; the pivot
script `py_notebooks/export_template_to_sigeif_form.py` must not be reused for
business-data exports.

`excel-template-analyst` owns the planning input contract and reports unresolved
inputs to Plan. `excel-template-builder` validates the operational contract
before execution. Do not duplicate either contract in Plan or root rules.

For the same table with different filters, create independent SELECTs and ask
whether XLSX results share a sheet or use separate sheets. For different
tables, propose a JOIN when catalog evidence, names, conventions, and compatible
types reach at least 70% confidence. Below 70%, require an explicit JOIN
condition. An inferred JOIN is never presented as a confirmed FK and is always
recorded in the final manifest.

The export uses a local `.env` and a dedicated read-only Oracle identity.
`excel-template-builder` creates the canonical manifest and automatically adds
its SHA-256 integrity hash without requesting user confirmation. It rejects
`SELECT *`, DML/DDL/PLSQL, comments,
multiple statements, `FOR UPDATE`, and database links. XLSX results are Excel
tables; if any result exceeds 1,048,576 rows, output is forced to CSV.

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

## Language
Respond in Spanish by default.
