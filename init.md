# Uso de OpenCode en este proyecto

El proyecto usa los agentes primarios built-in `plan` y `build` de OpenCode.
La configuracion especifica de SIGEIF se agrega en `opencode.json`.

1. Usa `Plan` para analizar una solicitud Oracle o Excel. Delega el analisis
   tecnico a los analistas permitidos y devuelve un plan con riesgos,
   dependencias, validaciones y archivos.
2. Usa `Build` para implementar una solicitud o un plan aprobado. Delega el
   trabajo de dominio a los builders permitidos.
3. Describe la necesidad en lenguaje natural. No uses slash commands del
   proyecto ni invoques subagentes con `@`, porque saltarias los gates.

## Exportacion Oracle a Excel o CSV

Para una exportacion, Build solicita a `oracle-query-builder` que lea el
catalogo y genere un SELECT con columnas explicitas. El flujo conversacional
usa selectores para tablas, columnas, filtros, operadores, AND/OR, formato y
organizacion de hojas.

Son obligatorios:

- tabla o tablas
- output: ruta y nombre
- formato: XLSX o CSV

`Todos los campos exportables` excluye BLOB, BFILE, RAW y LONG RAW. CLOB y
NCLOB se permiten como texto. Para la misma tabla con filtros distintos se
producen consultas independientes. Para tablas distintas se propone un JOIN
con confianza >= 70%; con menor confianza se pide la condicion explicita. En
todos los casos se muestra el SQL final y se pide confirmacion antes de abrir
Oracle.

La ejecucion usa `.env` y una cuenta Oracle de solo lectura. El exportador
fuerza CSV si cualquier resultado supera 1,048,576 filas. El XLSX contiene
 tablas estructuradas y no se sobrescriben archivos existentes.

Ejemplos:

- Plan: `Analiza una limpieza de datos para una familia y prepara el plan.`
- Build: `Implementa el script aprobado en plsql_scripts/...`.
- Plan: `Analiza una plantilla Excel pivotada para preguntas SIGEIF.`
- Build: `Genera el archivo Excel pivotado con el SELECT y las rutas indicadas.`
- Build: `Exporta las tablas seleccionadas a XLSX con filtros confirmados.`
- Build: `Completa los IDs de este Excel usando el catalogo y los cinco parametros confirmados.`
