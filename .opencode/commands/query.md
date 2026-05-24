---
description: Genera una consulta SELECT Oracle desde lenguaje natural
agent: query-builder
subtask: true
---

Antes de hacer cualquier cosa verifica los siguientes parámetros
en orden. No avances al siguiente hasta tener confirmado el anterior.

PASO 1 — Si $1 está vacío pregunta:
  "¿Qué información necesitas consultar? Descríbelo en lenguaje natural."
  Espera la respuesta. No continues.

PASO 2 — Si $2 está vacío pregunta:
  "¿En qué ruta guardamos el archivo? (ej: sql/queries/QRY_NOMBRE.sql)"
  Espera la respuesta. No continues.

Solo cuando tengas $1 y $2 confirmados, ejecuta:
1. Lee @data_base_schema.sql
2. Genera la consulta Oracle para: $1
3. Aplica la skill oracle-syntax para validar convenciones
4. Guarda el resultado en: $2