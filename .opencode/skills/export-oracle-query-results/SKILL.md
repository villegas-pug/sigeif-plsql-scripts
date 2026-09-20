---
name: export-oracle-query-results
description: Use ONLY for read-only Oracle SELECT exports to XLSX or CSV from catalog-validated tables, explicit columns, bind variables, an auto-hashed manifest, and a local .env connection.
compatibility: opencode
---

# Export Oracle Query Results

Skill exclusiva para extraer resultados Oracle de solo lectura a archivos XLSX o
CSV. No reutiliza el flujo pivot SIGEIF y no permite escrituras en Oracle.

## Entradas obligatorias

Contar con tabla(s), `output` con ruta y nombre, y `format`
(`XLSX` o `CSV`). Usar `question` con selectores para tablas coincidentes del
catalogo, columnas, filtros, operadores, `AND`/`OR`, formato y organizacion de
hojas. La seleccion de columnas debe incluir `Todos los campos exportables`,
que excluye `BLOB`, `BFILE`, `RAW` y `LONG RAW`; `CLOB` y `NCLOB` se permiten
como texto.

## Tablas y JOIN

- Una misma tabla con filtros distintos produce consultas independientes; no
  se agrega un JOIN. Para XLSX se pregunta si van en una hoja o en hojas
  separadas.
- Para tablas distintas se propone un JOIN si la evidencia del catalogo,
  nombres, tipos y convenciones alcanza una confianza de al menos 70%.
- Una inferencia menor al 70% requiere que el usuario indique la condicion.
- Toda condicion inferida se registra en el SELECT final y el manifiesto.
- Nunca se presenta una inferencia como FK confirmada si el catalogo no la
  documenta.

## Manifiesto

`excel-template-builder` crea el manifiesto canonico bajo
`py_notebooks/export_manifests/`:

```json
{
  "output": "ruta/salida.xlsx",
  "format": "xlsx",
  "sheet_mode": "same_sheet",
  "queries": [
    {
      "name": "resultado_1",
      "sql": "SELECT T.ID FROM TABLA T WHERE T.ESTADO = :estado",
      "binds": {"estado": "ACTIVO"}
    }
  ],
  "confirmed_query_hash": "sha256..."
}
```

No se pasa SQL directamente en la linea de comandos. El builder calcula
automaticamente el hash sobre output, formato, organizacion de hojas, nombres,
SQL y binds, y lo escribe en `confirmed_query_hash`. No solicita confirmacion
conversacional. Cualquier cambio produce un hash de integridad distinto.

## Seguridad y ejecucion

1. Leer el catalogo antes de formar la consulta.
2. Generar columnas explicitas; nunca usar `SELECT *`.
3. Usar binds para valores de filtros.
4. Rechazar DML, DDL, PL/SQL, multiples sentencias, comentarios, `FOR UPDATE`,
   enlaces de base de datos y construcciones no aprobadas.
5. Registrar SQL, binds sin exponer secretos, tablas, JOINs inferidos, formato y
   destino en el manifiesto.
6. Calcular y agregar automaticamente `confirmed_query_hash`.
7. Ejecutar el manifiesto exacto asociado a ese hash.

La conexion se lee desde `.env` mediante el script dedicado. No copiar
credenciales al codigo, prompt o logs. La cuenta Oracle debe tener solo
privilegios de lectura.

Variables admitidas: `ORACLE_USER`, `ORACLE_PASSWORD`, `ORACLE_DSN`. Tambien se
admite `ORACLE_HOST` con `ORACLE_PORT` y `ORACLE_SID` o
`ORACLE_SERVICE_NAME`; `ORACLE_CONFIG_DIR` es opcional.

## Salida

- XLSX: cada resultado se escribe como tabla estructurada de Excel.
- CSV: salida UTF-8 con proteccion contra formula injection.
- Si cualquier resultado supera `1,048,576` filas, se fuerza CSV aunque se haya
  seleccionado XLSX.
- Un CSV con varios resultados crea un archivo por resultado porque CSV no
  tiene hojas.

## Ejecucion autorizada

```text
python py_notebooks/export_oracle_query_results.py --manifest <manifest.json> --env-file .env
```

Para revisar el hash sin conectar:

```text
python py_notebooks/export_oracle_query_results.py --manifest <manifest.json> --print-query-hash
```

La ejecucion normal usa `confirmed_query_hash` como control de integridad y rechaza salidas
existentes para evitar sobrescrituras accidentales.
