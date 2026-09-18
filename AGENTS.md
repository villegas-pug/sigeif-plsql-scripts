# Oracle SQL Project - Global Rules

## Schema Source of Truth
This project uses Oracle. The authoritative schema catalog is
`plsql_scripts/oracle_schema_tables_catalog.md`.

Before analyzing or building any Oracle SQL, PL/SQL, view, or script, read the
catalog in the current session. Never infer tables, columns, sequences,
constraints, relationships, or indexes. Ask when the catalog does not resolve
an ambiguity.

## Database Safety
- Never execute `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`, `CREATE`, `ALTER`, `GRANT`, or `REVOKE` against Oracle.
- Never hide DML in CTEs, subqueries, wrappers, or `EXECUTE IMMEDIATE`.
- Never reveal credentials, connection strings, or internal schemas.
- Use bind variables for user input and flag likely injection patterns.
- Do not query Oracle system tables without explicit justification.
- Generating or writing a requested SQL artifact is distinct from executing it against a database; execution remains prohibited.
- A read-only `SELECT` may run only in an authorized flow such as Excel pivot, after the query is shown and the user confirms it.

## Plan and Build Architecture
`.opencode/agents/plan.md` and `.opencode/agents/build.md` are project-local
overrides of OpenCode's built-in `plan` and `build` agents. They are not
additional primary agents.

`plan` delegates analysis only:
- `oracle-design-analyst`: schema, dependencies, and implementation options.
- `oracle-validation-analyst`: integrity constraints and prevalidation.
- `oracle-performance-analyst`: performance, indexes, and tuning risks.
- `excel-template-analyst`: pivot/unpivot inputs, structure, and risks.

`build` delegates implementation only:
- `oracle-query-builder`: SELECT queries and views.
- `oracle-script-builder`: DML, DDL, cleanup, and migration scripts.
- `oracle-plsql-builder`: procedures, functions, triggers, packages, and anonymous blocks.
- `excel-template-builder`: Excel pivot/unpivot files through the approved Python scripts.
- `data-analytics`: fuzzy catalog resolution that populates IDs in a target Excel from a source catalog.

Primary overrides do not edit files, load Skills, or implement domain work.
Analysts are read-only. Builders do not delegate; Oracle builders may write
only `.sql` artifacts under `plsql_scripts/`. The Excel builder may run only
the two approved Python commands after permission confirmation. `data-analytics`
is a Build leaf agent: it uses no Oracle connection or SQL and may execute only
its local catalog-resolver command after permission confirmation.

## Skill Ownership
- `read-schema`: Oracle analysts and builders that require catalog facts.
- `oracle-syntax`: query, script, PL/SQL, and performance work.
- `generate-plsql`: DML, DDL, cleanup, and migration scripts only.
- `exception-handler`: PL/SQL program units only.
- `build-excel-pivot-template` and `build-excel-unpivot-template`: Excel builder only.
- `excel-catalog-fuzzy-resolver`: `data-analytics` only; it requires a target Excel,
  header row, source catalog, source key column, and source result column.

## Oracle Standards
- Use Oracle syntax only: `NVL`, `NVL2`, `DECODE`, `ROWNUM`, `ROWID`, `CONNECT BY`, `LEVEL`, `DUAL`, and `SYSDATE` as appropriate.
- Do not use `ISNULL`, `TOP`, or `LIMIT`.
- Use exact catalog names, table aliases, descriptive calculated aliases, and avoid `SELECT *` except explicit exploration.
- Use `SEQUENCE_NAME.NEXTVAL` only when the catalog confirms the sequence.
- Warn about likely full table scans.
- Use `PRC_`, `FNC_`, `TRG_`, `cur_`, `v_`, and `p_` conventions.
- PL/SQL requires a header, three-space indentation, and an `EXCEPTION` section with `WHEN OTHERS`, `SQLCODE`, and `SQLERRM` where applicable.
- Destructive scripts require prevalidation and FK-aware order. Keep `COMMIT` commented unless explicitly requested.

## Language
Respond in Spanish by default.
