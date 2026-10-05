---
name: export-oracle-query-results
description: Exporta SELECT Oracle read-only a XLSX/CSV con tablas verificadas, columnas explícitas, binds, manifiesto auto-hasheado y conexión local; exclusivo del builder Excel.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: export-oracle-query-results, path: .opencode/skills/export-oracle-query-results/SKILL.md}
    source_sha256: 432e5cfa0a9af33159ef9a1a9d00a9e62333154452a0569c6a7f8dcfe4a6f311
    transformations: [adapt-compatibility, normalize-instructions, relay-selectors-to-main]
    losses: [native-specialist-question-selector]
    generated_sha256: 2ec1ddc8f8e7ad7344a36cca6a24e499f878d82f0d6a265bafefd2118deb48f1
    synced_at: "2026-10-04T12:27:02Z"
---

# Export Oracle Query Results

Extrae resultados read-only a XLSX/CSV; no reutiliza pivot ni permite escrituras
Oracle. Solo `excel-template-builder` ejecuta el flujo con datos de consulta
recibidos de `oracle-query-builder` a través del agente principal.

## Mandatory Inputs

Requiere tablas, salida con ruta/nombre y formato XLSX/CSV. El principal usa
AskUserQuestion si está disponible para seleccionar tablas del catálogo,
columnas, filtros, operadores, AND/OR, formato y organización de hojas; en
otro caso pregunta por texto. El subagente devuelve faltantes al principal.

La selección incluye `Todos los campos exportables`: excluye BLOB/BFILE/RAW/
LONG RAW; CLOB/NCLOB como texto están permitidos. No inventar valores.

## Query and JOIN

- Misma tabla con filtros distintos: consultas independientes, sin JOIN;
  preguntar mediante el principal si XLSX comparte hoja o usa hojas separadas.
- Tablas distintas: proponer JOIN si catálogo, nombres y tipos sostienen
  confianza >=70%; bajo ese umbral exigir condición explícita.
- Registrar todo JOIN inferido en SELECT y manifiesto; no rotularlo como FK
  confirmada sin documentación.

## Manifest

El builder Excel crea el manifiesto en `py_notebooks/export_manifests/`:

```json
{
  "output": "ruta/salida.xlsx",
  "format": "xlsx",
  "sheet_mode": "same_sheet",
  "queries": [{"name": "resultado_1", "sql": "SELECT T.ID FROM TABLA T WHERE T.ESTADO = :estado", "binds": {"estado": "ACTIVO"}}],
  "confirmed_query_hash": "sha256..."
}
```

El ejemplo es estructura, no tablas ni IDs confirmados. No pasar SQL por CLI.
Calcular automáticamente el hash canónico de output, formato, hojas, nombres,
SQL y binds y escribir `confirmed_query_hash`, sin confirmación conversacional
del hash. Cualquier cambio modifica su integridad.

## Safety and Execution

Leer catálogo, columnas explícitas sin SELECT *, binds para filtros. Rechazar
DML/DDL/PLSQL, múltiples sentencias, comentarios, FOR UPDATE, database links y
construcciones no aprobadas. Registrar consulta, tablas, JOIN, formato y destino,
sin exponer secretos; ejecutar únicamente el manifiesto asociado al hash.

El script usa `.env` y una identidad Oracle read-only. No copiar credenciales
a código, prompts ni logs. Variables admitidas por el script: ORACLE_USER,
ORACLE_PASSWORD, ORACLE_DSN, o HOST/PORT y SID/SERVICE_NAME; CONFIG_DIR opcional
con sus prefijos ORACLE_. No leer ni mostrar sus valores durante planificación.

```text
python py_notebooks/export_oracle_query_results.py --manifest <manifest.json> --env-file .env
```

Para revisar el hash sin conexión, cuando esté autorizado:

```text
python py_notebooks/export_oracle_query_results.py --manifest <manifest.json> --print-query-hash
```

La aprobación técnica de Bash permanece; no es confirmación de negocio del
hash. El script rechaza salidas existentes. XLSX: tablas estructuradas; CSV:
UTF-8 con protección frente a formula injection. Si cualquier resultado supera
1,048,576 filas, forzar CSV; múltiples resultados CSV generan archivos separados.
