---
description: Valida integridad de datos antes de una operación INSERT, UPDATE o carga masiva
agent: data-validator
subtask: true
---

Lee @data_base_schema.sql y genera sentencias de validación para: $ARGUMENTS

Verifica:
- Integridad referencial (claves foráneas involucradas)
- Columnas con restricción NOT NULL
- Valores únicos (UNIQUE constraints)
- CHECK constraints definidos en el schema
- Posibles duplicados que romperían la operación

Genera únicamente consultas SELECT. No modifiques datos.