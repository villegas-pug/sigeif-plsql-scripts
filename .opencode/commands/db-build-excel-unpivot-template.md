---
description: Genera un Excel SIGEIF unpivot desde una plantilla pivotada
subtask: false
---

Antes de hacer cualquier cosa verifica los siguientes parametros en orden. No
avances al siguiente hasta tener confirmado el anterior.

PASO 1 - Si $1 esta vacio pregunta:
   "Indica el archivo Excel origen para realizar el unpivot. Debe terminar en .xlsx"
   Espera la respuesta. No continues.

PASO 2 - Si $2 esta vacio pregunta:
   "Indica la ruta completa y nombre del archivo Excel de salida. Debe terminar en .xlsx"
   Espera la respuesta. No continues.

Solo cuando tengas $1 y $2 confirmados, ejecuta:

1. Usa la skill `build-excel-unpivot-template`.
2. Lee el archivo origen: $1
3. Genera el archivo de salida en: $2
4. Usa el maestro `cod_familia_+_id_Familia.xlsx` ubicado en la misma carpeta del archivo origen.
5. El archivo final debe tener estas columnas:
   - `PF_ID_FAMILIA`
   - `AR_FECHA_REGISTRA`
   - `SF_ID_FASE`
   - `AP_ID_PREGUNTA`
   - `AR_RESPUESTA`
   - `AR_USU_REGISTRA`
6. No incluir `COD_FAMILIA` en el archivo final.
7. Si `AR_RESPUESTA` esta vacia, conservarla en blanco.
