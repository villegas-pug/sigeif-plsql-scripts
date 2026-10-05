---
name: excel-catalog-fuzzy-resolver
description: Pobla columnas ID de Excel por fuzzy local contra un catálogo usando la descripción adyacente derecha; requiere cinco entradas y confirmación antes de escribir.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: excel-catalog-fuzzy-resolver, path: .opencode/skills/excel-catalog-fuzzy-resolver/SKILL.md}
    source_sha256: c94882fd0b884ce8aa831e1349ab177a9bd3b07b48e6b9c61e8b298ef6a1a399
    files:
      - {path: scripts/resolver.py, sha256: bb771d66732bb2de120881975cb7feb9865bc742d5f49127dde11926f9349cfa}
      - {path: scripts/aliases_es.json, sha256: 9aff4a997bce27758b21ba669d6bb8c0526fdb1716643be4c81aa34076fabeec}
    transformations: [adapt-compatibility, normalize-instructions, adapt-resolver-path, relay-inputs-to-main, literalize-input-labels]
    losses: [native-specialist-question-tool]
    generated_sha256: 2ee1fd6de1f4921cd62d6b56709a784609b73e99ad9f18c0f549f62ea15b46e7
    synced_at: "2026-10-04T12:27:02Z"
---

# Excel Catalog Fuzzy Resolver

Exclusiva de `data-analytics`; sin Oracle ni SQL. Pobla ID_* usando la descripción
adyacente derecha del target y un catálogo source.

## Mandatory Inputs

| Input | Requisito |
|---|---|
| `target_file` | Ruta absoluta al target .xlsx |
| `target_header_row` | Fila positiva 1-based de encabezados |
| `source_file` | Ruta absoluta al catálogo .xlsx |
| `source_key_column` | Letra o número 1-based de búsqueda |
| `source_result_column` | Letra o número 1-based del ID/resultado |

Si falta o es ambiguo cualquier input, STOP y devolver faltantes al principal.
No proceder bajo ninguna circunstancia ni sustituirlos por ejemplos.

## Optional Inputs

Solo flags proporcionados explícitamente: --target-sheet, --source-sheet,
--umbral (default82), --category-ranges (`COL=ini-fin;COL2=ini2-fin2`),
--aliases-file, --output-suffix (default `_resuelto`), --no-confirm,
--id-regex y --skip-columns (letras, números o nombres, como B,E o ZO_ID_ZONA).
Las hojas por defecto y demás defaults se conservan como los implemente el
script; no añadir flags para cambiar su comportamiento al migrar.

## Gate and Detection

Validar existencia de target/source, encabezado positivo, columnas válidas del
catálogo y al menos una columna ID. En caso contrario devolver el error
correspondiente sin escribir. Enumerar columnas detectadas y adyacentes y
obtener confirmación antes de escritura, salvo --no-confirm explícitamente recibido.

Regex case-insensitive:
`(?:^ID[_.])|(?:_ID[_.])|(?:_ID$)|(?:ID$)`.
Detecta ID_TIP_DOC, ZO_ID_ZONA, PF_ID_FAMILIA y USERID; no DIRECCION,
IDENTIDAD ni REG_CONADIS.

Adyacente inexistente o header vacío: omitir y reportar. Header presente con
celdas todas vacías: cobertura 0%. IDs previos pueden sobrescribirse en la
copia resultado, nunca el target fuente.

## Matching Workflow

1. Cargar la Skill y recibir las cinco entradas del principal.
2. Validar precondiciones y cargar target/source.
3. Detectar columnas y confirmar escritura.
4. Normalizar lowercase, acentos, puntuación redundante y espacios.
5. Prefiltrar categorías si se recibió --category-ranges.
6. Usar `scripts/aliases_es.json` y aliases externos opcionales.
7. Ensemble: token_set_ratio .40, token_sort_ratio .25, partial_ratio .20,
   WRatio .15.
8. Segunda pasada: consistencia >=80% y score 70–95 permiten boost a95.
9. Aceptar score >=82 por default; escribir IDs y reportes en copia resultado.
10. Informar cobertura global/por columna, no-match y ambigüedad exactamente.

No cambiar algoritmo, defaults ni corregir funcionalidad incidental durante
la migración. La implementación copiada es determinista para la misma entrada.

## Execution

Después de validar inputs y obtener confirmación, ejecutar solo el resolvedor
local con aprobación técnica del comando:

```text
python .claude/skills/excel-catalog-fuzzy-resolver/scripts/resolver.py --target <target_file> --target-header-row <target_header_row> --source <source_file> --source-key-col <source_key_column> --source-result-col <source_result_column>
```

No añadir --no-confirm automáticamente; la confirmación interactiva del script
puede requerir intervención del usuario en un terminal autorizado. Si la
herramienta no admite esa interacción, devolver el bloqueo al principal; no
saltarlo silenciosamente.

## Output

- `<target_sin_ext>_resuelto.xlsx` por default, copia con IDs resueltos.
- `reporte_cobertura.txt`, global y por columna.
- `reporte_no_match.csv`: fila, columna_id, valor_origen, mejor_candidato,
  score, método.
- `reporte_ambiguedades.csv`: matches con score<90.
- `reporte_deteccion.txt`: detectadas/omitidas y motivos.

Si cobertura<95%, sugerir revisión de no-match y ampliar catálogo/aliases.
Dependencias existentes: Python3.10+, openpyxl, rapidfuzz. No instalarlas sin
autorización; no ejecutar el resolvedor durante la migración de artefactos.
