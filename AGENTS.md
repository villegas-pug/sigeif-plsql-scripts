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
- A read-only `SELECT` may run only through the confirmed Excel export flow or another explicitly authorized read-only flow.
- The exact SELECT, binds, JOINs, format, destination, and confirmation hash must be shown before execution.

## Plan and Build Architecture
The project uses OpenCode built-in primary agents `plan` and `build`. Their
project-specific permissions are configured in the root `opencode.json`.

`plan` delegates Oracle/Excel technical analysis through Task only to:
- `oracle-design-analyst`: schema, dependencies, and implementation options.
- `oracle-validation-analyst`: integrity constraints and prevalidation.
- `oracle-performance-analyst`: performance, indexes, and tuning risks.
- `excel-template-analyst`: pivot, unpivot, catalog resolution, and export inputs.

`build` delegates domain implementation through Task only to:
- `oracle-query-builder`: SELECT queries and export manifests; never executes Oracle.
- `oracle-script-builder`: DML, DDL, cleanup, and migration SQL artifacts.
- `oracle-plsql-builder`: procedures, functions, triggers, packages, and anonymous blocks.
- `excel-template-builder`: SIGEIF templates and confirmed Oracle result exports.
- `data-analytics`: local fuzzy catalog resolution; no Oracle or SQL.

Plan permanece sin edicion ni Skills operativas. Build conserva capacidades normales de edicion y shell para integrar, validar y consolidar cambios, pero mantiene los gates de seguridad Oracle. Analysts are read-only.
Builders do not delegate. Oracle builders may write only `.sql` artifacts under
`plsql_scripts/`. Excel builder may execute only the three approved Python
commands after the applicable confirmation. `data-analytics` may execute only
its local resolver command after confirmation.

## Excel Export Flow
The generic read-only export flow is separate from SIGEIF pivot/unpivot:

`Build -> oracle-query-builder -> user confirmation -> excel-template-builder -> export script`

The export script is `py_notebooks/export_oracle_query_results.py`; the pivot
script `py_notebooks/export_template_to_sigeif_form.py` must not be reused for
business-data exports.

Mandatory conversational inputs are table(s), output path plus filename, and
format (`XLSX` or `CSV`). Use selectors for tables, columns, filters, operators,
`AND`/`OR`, format, and XLSX sheet organization whenever possible. Offer
`Todos los campos exportables`; it excludes `BLOB`, `BFILE`, `RAW`, and
`LONG RAW`, while CLOB/NCLOB may be exported as text.

For the same table with different filters, create independent SELECTs and ask
whether XLSX results share a sheet or use separate sheets. For different
tables, propose a JOIN when catalog evidence, names, conventions, and compatible
types reach at least 70% confidence. Below 70%, require an explicit JOIN
condition. An inferred JOIN is never presented as a confirmed FK and is always
shown in the final confirmation.

The export uses a local `.env` and a dedicated read-only Oracle identity. It
requires explicit confirmation and a matching SHA-256 manifest hash before
opening the connection. It rejects `SELECT *`, DML/DDL/PLSQL, comments,
multiple statements, `FOR UPDATE`, and database links. XLSX results are Excel
tables; if any result exceeds 1,048,576 rows, output is forced to CSV.

## Skill Ownership
- `read-schema`: Oracle analysts and builders that require catalog facts.
- `oracle-syntax`: query, script, PL/SQL, and performance work.
- `generate-plsql`: DML, DDL, cleanup, and migration scripts only.
- `exception-handler`: PL/SQL program units only.
- `build-excel-pivot-template` and `build-excel-unpivot-template`: Excel builder only.
- `export-oracle-query-results`: confirmed read-only Oracle export, Excel builder only.
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
