---
description: Genera una plantilla Excel SIGEIF pivotada desde un SELECT
subtask: false
---

Antes de hacer cualquier cosa verifica los siguientes parametros en orden. No
avances al siguiente hasta tener confirmado el anterior.

PASO 1 - Si $1 esta vacio pregunta:
   "Indica la sentencia SQL SELECT fuente. Debe devolver AP_ID_PREGUNTA y AP_PREGUNTA."
   Espera la respuesta. No continues.

PASO 2 - Si $2 esta vacio pregunta:
   "Indica el directorio de salida donde se generara el template Excel."
   Espera la respuesta. No continues.

PASO 3 - Si $3 esta vacio pregunta:
   "Indica el nombre del archivo Excel de salida. Debe terminar en .xlsx"
   Espera la respuesta. No continues.

Solo cuando tengas $1, $2 y $3 confirmados, ejecuta:

1. Usa la skill `build-excel-pivot-template`.
2. Genera una plantilla Excel vacia usando la sentencia: $1
3. Guarda el archivo en el directorio: $2
4. Usa como nombre de salida: $3
5. La plantilla debe tener:
   - fila 1: primeras 4 columnas vacias y luego `AP_PREGUNTA`
   - fila 2: `N°`, `COD_FAMILIA`, `AR_FECHA_REGISTRA`, `SF_ID_FASE` y luego `AP_ID_PREGUNTA`
   - fila 3 en adelante: filas vacias numeradas para llenado manual
