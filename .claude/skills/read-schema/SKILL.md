---
name: read-schema
description: Consulta el catálogo verificado antes de analizar o generar artefactos Oracle que requieren tablas, columnas, relaciones, constraints, índices o secuencias exactos.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: read-schema, path: .opencode/skills/read-schema/SKILL.md}
    source_sha256: cb5c5aecad448b8f687fa383af7616350632ab012ac56b049bd09fc5b06141cb
    transformations: [adapt-compatibility, normalize-instructions]
    losses: []
    generated_sha256: 5497d9e4fba3cb0551696d3ddb090af7970e82a6b9fc9a59fd1c987175fb2e73
    synced_at: "2026-10-04T12:27:02Z"
---

# Read Schema

Lee `plsql_scripts/oracle_schema_tables_catalog.md` para obtener hechos reales
del modelo antes de generar o analizar Oracle. No ejecutes consultas Oracle.

Extrae:
- Tablas: nombre exacto, columnas, tipos/tamaños, nulabilidad y PK declaradas.
- Relaciones: FKs y padre/columna referenciada; distingue cardinalidad inferida
  de relaciones documentadas.
- Índices: nombre, tabla, columnas y UNIQUE/regular cuando estén documentados.
- Secuencias: nombre y asociación documentada o inferida, etiquetando la inferencia.
- Constraints: CHECK y UNIQUE además de PK.

Prioriza entidades relevantes, columnas/tipos exactos, FKs y los índices
pertinentes para performance. No infieras tablas, columnas, secuencias,
constraints ni relaciones como hechos confirmados si el catálogo no los describe.
La ausencia de documentación es una ambigüedad, no permiso para inventar.

Los specialists autorizados cargan esta Skill mediante `Skill`. Cargarla no
autoriza ejecuciones, ni edición fuera del contrato de quien la usa.
