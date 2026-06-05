---
name: build-excel-pivot-template
description: Use ONLY when generating an Excel template from a SQL SELECT that includes AP_ID_PREGUNTA and AP_PREGUNTA, pivoting questions horizontally and leaving fixed manual-entry columns.
compatibility: opencode
---

# Build Excel Pivot Template

## Gate obligatorio

Antes de ejecutar este flujo, se debe contar obligatoriamente con:

- una sentencia `SELECT ...` fuente
- un `output_dir`
- un `output_file` con extension `.xlsx`

Si falta cualquiera de esos tres datos, se debe detener la ejecucion y
preguntarlos. No se debe asumir ni inventar valores.

## Que hace

Genera una plantilla Excel vacia a partir de una consulta SQL que devuelve al
menos estas columnas:

- `AP_ID_PREGUNTA`
- `AP_PREGUNTA`

La salida es una hoja Excel lista para llenado manual, con preguntas pivotadas
horizontalmente y columnas fijas al inicio.

## Cuando usarla

Usar SOLO cuando el usuario pida cualquiera de estos escenarios:

- crear una plantilla Excel desde un `SELECT`
- pivotear preguntas horizontalmente en Excel
- construir una base para carga masiva futura
- generar cabeceras desde `AP_ID_PREGUNTA` y `AP_PREGUNTA`
- producir una plantilla sin datos de negocio

No usar para:

- reportes con datos completos
- cargas masivas hacia Oracle
- transformaciones donde no exista `AP_ID_PREGUNTA` y `AP_PREGUNTA`

## Estructura esperada del Excel

- Fila 1:
  - columnas 1 a 4 vacias
  - desde la columna 5: `AP_PREGUNTA`
- Fila 2:
  - `N° | COD_FAMILIA | AR_FECHA_REGISTRA | SF_ID_FASE`
  - desde la columna 5: `AP_ID_PREGUNTA`
- Fila 3 en adelante:
  - filas vacias para llenado manual

## Flujo operativo

1. Verificar que exista una sentencia `SELECT ...` fuente.
2. Verificar que exista `output_dir`.
3. Verificar que exista `output_file` y que termine en `.xlsx`.
4. Asumir que el `SELECT` incluye `AP_ID_PREGUNTA` y `AP_PREGUNTA`.
5. Ejecutar la consulta solo para obtener la definicion de columnas.
6. Respetar el orden natural del resultado del `SELECT`.
7. Eliminar duplicados por `AP_ID_PREGUNTA`, conservando la primera aparicion.
8. Generar la plantilla Excel sin datos de negocio.

## Implementacion actual del proyecto

El flujo base vive en:

`py_notebooks/export_template_to_sigeif_form.py`

Ese script ya implementa este patron:

- conexion Oracle
- ejecucion de un `SELECT`
- extraccion de `AP_ID_PREGUNTA` y `AP_PREGUNTA`
- generacion de plantilla en `py_notebooks/target/punche/`

## Reglas de adaptacion

Cuando se reutilice este flujo para otro template:

- invocar el script con:
  - `--sql-query`
  - `--output-dir`
  - `--output-file`
- conservar las columnas fijas:
  - `N°`
  - `COD_FAMILIA`
  - `AR_FECHA_REGISTRA`
  - `SF_ID_FASE`
- no agregar joins ni logica de respuestas si el usuario solo pide plantilla
- no poblar datos salvo instruccion explicita

## Ejecucion esperada

El flujo se debe ejecutar con una forma equivalente a esta:

```bash
python py_notebooks/export_template_to_sigeif_form.py \
  --sql-query "SELECT * FROM ..." \
  --output-dir "./target/punche" \
  --output-file "ficha_identificacion.xlsx"
```

## Resultado minimo esperado

- archivo `.xlsx`
- hoja unica
- `freeze panes` en `E3`
- autoajuste basico de columnas
- filas vacias numeradas para digitacion manual

## Nota operativa

Si se modifica esta skill o se agrega por primera vez, opencode debe reiniciarse
para cargarla en nuevas sesiones.
