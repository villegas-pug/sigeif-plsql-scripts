---
name: read-schema
description: Parsea y extrae información clave del archivo data_base_schema.sql para proporcionar contexto estructurado de tablas, columnas, relaciones e índices antes de generar SQL
compatibility: opencode
---

## Qué hago

Leo y proceso el archivo `oracle_schema_tables_catalog.md` para extraer y organizar
la información del modelo de datos antes de que se genere cualquier SQL.

## Información que extraigo

### Tablas
- Nombre exacto de cada tabla (respetando mayúsculas)
- Lista de columnas con nombre, tipo de dato y tamaño
- Columnas NOT NULL vs. nullable
- Clave primaria (PRIMARY KEY)

### Relaciones
- Claves foráneas (FOREIGN KEY ... REFERENCES ...)
- Tabla padre y columna referenciada
- Tipo de relación inferida (1:N, N:M mediante tabla intermedia)

### Índices
- Nombre del índice
- Tabla e columnas indexadas
- Tipo: UNIQUE INDEX vs INDEX regular

### Secuencias
- Nombre de cada secuencia disponible
- Tabla a la que típicamente alimenta (inferido del nombre)

### Constraints
- CHECK constraints y su condición
- UNIQUE constraints adicionales (fuera de PK)

## Cómo uso esta información

Cuando extraigo el schema, priorizo:
1. Tablas involucradas en la solicitud actual
2. Sus columnas con tipos exactos
3. Las FK que las conectan con otras tablas
4. Los índices disponibles (relevante para optimización)

## Cuándo usarme

Úsame siempre al inicio de cualquier tarea SQL para garantizar que el
código generado use nombres exactos del schema y respete las
relaciones definidas. Esto previene errores de compilación por nombres
incorrectos.