---
name: build-excel-unpivot-template
description: Convierte una plantilla pivot SIGEIF en Excel plano, conserva AR_FECHA_REGISTRA/SF_ID_FASE y resuelve PF_ID_FAMILIA desde COD_FAMILIA para una carga posterior.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: build-excel-unpivot-template, path: .opencode/skills/build-excel-unpivot-template/SKILL.md}
    source_sha256: 93cafcbf718142dee8b577eadbec623827bf905fcd8519cf90a56ca9a7f50daa
    transformations: [adapt-compatibility, normalize-instructions, relay-inputs-to-main]
    losses: []
    generated_sha256: 1fdb4253e0559bed28e0a669a6e3a5625dda7fd24b0f942a799bf0e24879c178
    synced_at: "2026-10-04T12:27:02Z"
---

# Build Excel Unpivot Template

Exclusiva del flujo unpivot de `excel-template-builder`.

## Mandatory Gate

Requiere `input_file.xlsx` generado por la Skill pivot, `output_file.xlsx` con
ruta completa y `family_map_file.xlsx` con COD_FAMILIA y PF_ID_FAMILIA. Si falta
un input, detener y devolverlo al principal; no inventar ni asumir rutas.

El maestro legacy `cod_familia_+_id_Familia.xlsx` junto al input es compatible,
pero su ruta debe recibirse o validarse explícitamente antes de ejecutar.

## Transformation

Origen: fila 1 primeras cuatro columnas vacías y preguntas desde E; fila 2
`N° | COD_FAMILIA | AR_FECHA_REGISTRA | SF_ID_FASE` y AP_ID_PREGUNTA desde E;
datos desde fila 3.

Leer filas 1/2 como metadatos, validar existencia de los tres archivos/rutas
pertinentes y columnas del maestro. Conservar fecha y fase, resolver familia
con el maestro, despivotar preguntas a AP_ID_PREGUNTA y valores a AR_RESPUESTA.
Mantener respuestas vacías en blanco; agregar AR_USU_REGISTRA=1 y excluir
COD_FAMILIA del resultado.

Orden de salida:
`PF_ID_FAMILIA, AR_FECHA_REGISTRA, SF_ID_FASE, AP_ID_PREGUNTA, AR_RESPUESTA,
AR_USU_REGISTRA`.

Usar solo para conversión de templates SIGEIF y preparación de carga posterior.
No genera el pivot original, no inserta Oracle y no transforma Excels con otra
estructura.

Invocar después del gate y aprobación técnica:

```text
python py_notebooks/unpivot_sigeif_form.py --input-file <input.xlsx> --output-file <output.xlsx> --family-map-file <family_map.xlsx>
```

Conservar el script existente; la migración no altera negocio ni ejecuta cargas.
