---
name: excel-catalog-fuzzy-resolver
description: Pobla columnas ID de Excel por fuzzy local contra un catálogo usando la descripción adyacente derecha; requiere cinco entradas y confirmación antes de escribir.
compatibility: opencode, claude-code
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

Si falta o es ambiguo cualquier input, STOP y devolver faltantes al orquestador.
No proceder bajo ninguna circunstancia ni sustituirlos por ejemplos.

## Optional Inputs

Solo flags proporcionados explícitamente: --target-sheet, --source-sheet
(default: primera hoja), --umbral (default 82), --category-ranges
(`COL=ini-fin;COL2=ini2-fin2`), --aliases-file, --output-suffix (default
`_resuelto`), --no-confirm, --id-regex y --skip-columns (letras, números o
nombres, como B,E o ZO_ID_ZONA). Los demás defaults se conservan como los
implemente el script; no añadir flags para cambiar su comportamiento.

## Gate and Detection

Validar antes de tocar archivos y detener sin escribir ante el primer fallo:

1. target/source existen: `"El archivo <ruta> no existe."`
2. Encabezado entero positivo: `"$2 debe ser la fila 1-based de encabezados."`
3. Columnas válidas del catálogo: `"Columna <col> no existe en <source>."`
4. Al menos una columna ID: `"Ninguna columna ID detectada en fila <N> con regex <regex>."`

Enumerar columnas detectadas y adyacentes y obtener confirmación antes de
escribir, salvo --no-confirm explícitamente recibido.

Regex case-insensitive:
`(?:^ID[_.])|(?:_ID[_.])|(?:_ID$)|(?:ID$)`.
Detecta ID_TIP_DOC, ZO_ID_ZONA, PF_ID_FAMILIA y USERID; no DIRECCION,
IDENTIDAD ni REG_CONADIS.

Adyacente inexistente o header vacío: omitir y reportar en
`reporte_deteccion.txt`. Header presente con celdas todas vacías: cobertura 0%.
IDs previos pueden sobrescribirse en la copia resultado, nunca en el target fuente.

## Matching Workflow

1. Cargar la Skill y recibir las cinco entradas del orquestador.
2. Validar precondiciones y cargar target/source.
3. Detectar columnas y confirmar escritura.
4. Normalizar lowercase, acentos, puntuación redundante y espacios.
5. Prefiltrar categorías si se recibió --category-ranges.
6. Usar `scripts/aliases_es.json` y aliases externos opcionales.
7. Ensemble: token_set_ratio .40, token_sort_ratio .25, partial_ratio .20,
   WRatio .15.
8. Segunda pasada: consistencia >=80% y score 70–95 permiten boost a 95.
9. Aceptar score >=82 por default; escribir IDs y reportes en copia resultado.
10. Informar cobertura global/por columna, no-match y ambigüedad exactamente.

No cambiar algoritmo ni defaults, ni corregir funcionalidad incidental al usar
esta Skill. La implementación es determinista para la misma entrada.

## Execution

Después de validar inputs y obtener confirmación, ejecutar desde la raíz del
proyecto solo el resolvedor local, con aprobación técnica del comando:

```text
python .claude/skills/excel-catalog-fuzzy-resolver/scripts/resolver.py --target "<target_file>" --target-header-row <target_header_row> --source "<source_file>" --source-key-col <source_key_column> --source-result-col <source_result_column>
```

Agregar únicamente los flags opcionales recibidos. No añadir --no-confirm
automáticamente; la confirmación interactiva del script puede requerir
intervención del usuario en un terminal autorizado. Si la herramienta no admite
esa interacción, devolver el bloqueo al orquestador; no saltarlo silenciosamente.

## Output

- `<target_sin_ext>_resuelto.xlsx` por default, copia con IDs resueltos.
- `reporte_cobertura.txt`, global y por columna.
- `reporte_no_match.csv`: fila, columna_id, valor_origen, mejor_candidato,
  score, método.
- `reporte_ambiguedades.csv`: matches con score < 90.
- `reporte_deteccion.txt`: detectadas/omitidas y motivos.

Si cobertura < 95%, sugerir revisión de no-match y ampliar catálogo/aliases.
Dependencias existentes: Python 3.10+, openpyxl, rapidfuzz. No instalarlas sin
autorización.
