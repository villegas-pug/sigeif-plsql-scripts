---
name: read-schema
description: Consulta el catálogo verificado antes de analizar o generar artefactos Oracle que requieren tablas, columnas, relaciones, constraints, índices o secuencias exactos.
compatibility: opencode, claude-code
---

# Read Schema

Lee `plsql_scripts/oracle_schema_tables_catalog.md` para obtener hechos reales
del modelo antes de generar o analizar Oracle. No ejecutes consultas Oracle.

Extrae:
- Tablas: nombre exacto (respetando mayúsculas), columnas, tipos/tamaños,
  nulabilidad y PK declaradas.
- Relaciones: FKs y padre/columna referenciada; distingue cardinalidad inferida
  (1:N, N:M mediante tabla intermedia) de relaciones documentadas.
- Índices: nombre, tabla, columnas y UNIQUE/regular cuando estén documentados.
- Secuencias: nombre y asociación documentada o inferida, etiquetando la inferencia.
- Constraints: CHECK con su condición y UNIQUE además de PK.

Prioriza entidades relevantes, columnas/tipos exactos, FKs y los índices
pertinentes para performance. No infieras tablas, columnas, secuencias,
constraints ni relaciones como hechos confirmados si el catálogo no los describe.
La ausencia de documentación es una ambigüedad, no permiso para inventar.

Los especialistas autorizados cargan esta Skill con la herramienta de Skills del
harness. Cargarla no autoriza ejecuciones, ni edición fuera del contrato de
quien la usa.
