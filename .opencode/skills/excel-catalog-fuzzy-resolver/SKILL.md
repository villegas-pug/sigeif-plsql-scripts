---
name: excel-catalog-fuzzy-resolver
description: Use ONLY when the user needs to populate one or more ID_/..._ID_ columns in a target Excel by fuzzy/semantic lookup against a source catalog Excel. Auto-detects ID columns by header regex, takes the adjacent-right column as search key, and writes the resolved ID back to the ID column. Stops if any of the 5 mandatory inputs is missing.
---

# Excel Catalog Fuzzy Resolver

Pobla columnas de tipo `ID_*` en un Excel destino (target) buscando sus descripciones adyacentes a la derecha contra un Excel fuente (source) que actúa como catálogo.

## Mandatory Inputs (Obligatorios)

| # | Variable | Descripción | Ejemplo |
|---|---|---|---|
| `$1` | `target_file` | Ruta absoluta del .xlsx destino | `C:\datos\matriz.xlsx` |
| `$2` | `target_header_row` | Fila 1-based donde inician los encabezados | `5` |
| `$3` | `source_file` | Ruta absoluta del .xlsx catálogo | `C:\datos\catalogo.xlsx` |
| `$4` | `source_key_column` | Columna del catálogo donde está el valor a buscar (letra o número 1-based) | `A` |
| `$5` | `source_result_column` | Columna del catálogo con el ID/resultado (letra o número 1-based) | `B` |

**Regla estricta de bloqueo**: si `$1..$5` están vacíos, ausentes o son ambiguos, **detener la ejecución** y listar los faltantes. No proceder bajo ninguna circunstancia.

## Optional Inputs

- `--target-sheet` (default: primera hoja)
- `--source-sheet` (default: primera hoja)
- `--umbral` (default: `82`) — score mínimo para aceptar match
- `--category-ranges` — pre-filtro por rangos de filas del catálogo (formato `COL=ini-fin;COL2=ini2-fin2`)
- `--aliases-file` — ruta a JSON con aliases adicionales
- `--output-suffix` (default: `_resuelto`) — sufijo del archivo de salida
- `--no-confirm` — saltar confirmación de columnas detectadas
- `--id-regex` (default: recomendado) — regex personalizada para detectar columnas ID
- `--skip-columns` — columnas a excluir (por letra, número o nombre). Ej: `B,E` o `ZO_ID_ZONA,PF_ID_FAMILIA`. Útil para excluir PKs/FKs propias del target.

## Mandatory Gate (Pre-condiciones)

Validar ANTES de tocar cualquier archivo:

1. **¿Existen `$1` y `$3` como archivos?**
   - Si no, detenerse: `"El archivo <ruta> no existe."`
2. **¿`$2` es entero positivo?**
   - Si no, detenerse: `"$2 debe ser la fila 1-based de encabezados."`
3. **¿`$4` y `$5` son columnas válidas en el catálogo?**
   - Si no, detenerse: `"Columna <col> no existe en <source>."`
4. **¿La regex detecta al menos una columna ID en el target?**
   - Si no, detenerse: `"Ninguna columna ID detectada en fila <N> con regex <regex>."`

Tras las validaciones, listar al usuario las columnas detectadas y sus adyacentes, y **pedir confirmación** antes de escribir (a menos que se pase `--no-confirm`).

## Detección de columnas ID

Regex por defecto (case-insensitive, con delimitadores):
```
(?:^ID[_.])|(?:_ID[_.])|(?:_ID$)|(?:ID$)
```

Matchea:
- `ID_TIP_DOC` (starts with `ID_`)
- `ZO_ID_ZONA` (contains `_ID_`)
- `PF_ID_FAMILIA` (contains `_ID_`)
- `USERID` (ends with `ID`)

No matchea (sin delimitación):
- `DIRECCION`
- `IDENTIDAD`
- `REG_CONADIS`

## Algoritmo de matching

1. **Normalización**: lowercase, sin acentos (`unicodedata`), sin puntuación redundante, espacios colapsados.
2. **Pre-filtro por categoría** (si se pasa `--category-ranges`).
3. **Alias dict** (cargado de `scripts/aliases_es.json` por defecto + archivo externo opcional).
4. **Ensemble de scorers** ponderado:
   - `token_set_ratio` × 0.40
   - `token_sort_ratio` × 0.25
   - `partial_ratio` × 0.20
   - `wratio` × 0.15
5. **Boost por mayoría histórica** (2 pasadas): si el mismo valor se asigna consistentemente al mismo candidato en ≥80% de filas y el score está entre 70-95, elevar a 95.
6. Umbral de aceptación: `score >= 82` por defecto.

## Workflow

1. Cargar skill via `skill excel-catalog-fuzzy-resolver`.
2. Solicitar los 5 inputs al usuario. Si falta alguno → **STOP**.
3. Validar pre-condiciones (mandatory gate).
4. Cargar target y source.
5. Detectar columnas ID con regex.
6. Listar al usuario y pedir confirmación.
7. Pasada 1: scoring para todas las celdas.
8. Pasada 2: boost por mayoría.
9. Escribir IDs en columnas ID detectadas.
10. Generar reportes (`reporte_cobertura.txt`, `reporte_no_match.csv`, `reporte_ambiguedades.csv`, `reporte_deteccion.txt`).
11. Reportar resumen al usuario con % de cobertura global y por columna.

## Salidas

- `<target_sin_ext>_resuelto.xlsx` — copia del target con columnas ID pobladas.
- `reporte_cobertura.txt` — % por columna detectada.
- `reporte_no_match.csv` — `(fila, columna_id, valor_origen, mejor_candidato, score, metodo)`.
- `reporte_ambiguedades.csv` — matches con score < 90.
- `reporte_deteccion.txt` — columnas detectadas y omitidas con justificación.

## Ejecución

Después de validar los cinco inputs y recibir confirmación del usuario, ejecutar
solo el resolvedor local con los parámetros recibidos:

```powershell
python .opencode/skills/excel-catalog-fuzzy-resolver/scripts/resolver.py --target "<target_file>" --target-header-row <target_header_row> --source "<source_file>" --source-key-col <source_key_column> --source-result-col <source_result_column>
```

Agregar únicamente los flags opcionales proporcionados explícitamente por el
usuario. No ejecutar consultas ni conexiones Oracle.

## Comportamiento para columnas adyacentes vacías

Si una columna ID es detectada pero su adyacente derecha:
- No existe (es la última columna) → **omitir y reportar** en `reporte_deteccion.txt`.
- Existe pero su header está vacío → **omitir y reportar**.
- Existe con datos pero todas las celdas de datos están vacías → procesada, 0% cobertura.

## Notas

- Las celdas con valor previo en columnas ID se **sobrescriben**.
- Multi-hoja: usar `--target-sheet` y `--source-sheet` para archivos con varias hojas.
- Si cobertura < 95%, sugerir al usuario revisar `reporte_no_match.csv` y ampliar el catálogo o el alias dict.
- El script es determinista: misma entrada → mismo resultado.

## Dependencias

- Python 3.10+
- `openpyxl`
- `rapidfuzz`
