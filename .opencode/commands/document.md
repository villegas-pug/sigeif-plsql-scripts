---
description: Documenta una tabla, vista u objeto del schema Oracle
agent: plan
subtask: true
---

Lee @data_base_schema.sql y genera documentación completa para el objeto: $ARGUMENTS

Incluye:
- Propósito del objeto en el sistema
- Descripción de cada columna: nombre, tipo, restricciones, descripción funcional
- Relaciones con otras tablas (claves foráneas entrantes y salientes)
- Índices existentes y su propósito
- Constraints definidos (PK, UK, CHECK)
- Ejemplo de consulta de uso típico
- Notas de integridad o reglas de negocio inferidas del schema