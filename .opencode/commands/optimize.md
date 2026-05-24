---
description: Valida integridad de datos antes de una operación INSERT, UPDATE o carga masiva
agent: data-validator
subtask: true
model: anthropic/claude-sonnet-4-20250514
---

Antes de hacer cualquier cosa verifica los siguientes parámetros
en orden. No avances al siguiente hasta tener confirmado el anterior.

PASO 1 — Si $1 está vacío pregunta:
  "¿Qué operación quieres validar? (ej: inserción masiva en TABLA_X, actualización de COLUMNA_Y)"
  Espera la respuesta. No continues.

PASO 2 — Si $2 está vacío pregunta:
  "¿En qué ruta guardamos el script de validación? (ej: sql/validations/VAL_NOMBRE.sql)"
  Espera la respuesta. No continues.

Solo cuando tengas $1 y $2 confirmados, ejecuta:
1. Lee @data_base_schema.sql
2. Identifica constraints, FK y unique keys involucrados en: $1
3. Genera las consultas de validación (solo SELECT, sin modificar datos)
4. Guarda el resultado en: $2