# Uso de OpenCode en este proyecto

El proyecto usa los agentes primarios built-in `plan` y `build` de OpenCode.
La configuracion compartida vive en `opencode.json`; los prompts y permisos
especificos de SIGEIF viven en `.opencode/agents/plan.md` y `build.md`.

1. Usa `Plan` para analizar una solicitud Oracle o Excel. Plan delega primero
   todo el contexto disponible al analyst propietario del contrato. Despues
   pregunta solo por las entradas faltantes reportadas y devuelve un plan con
   riesgos, dependencias, validaciones y archivos.
2. Usa `Build` para implementar una solicitud o un plan aprobado. Delega el
   trabajo de dominio a los builders permitidos.
3. Describe la necesidad en lenguaje natural. No uses slash commands del
   proyecto ni invoques subagentes con `@`, porque saltarias los gates.

Los analysts devuelven un handoff comun con capacidad, entradas requeridas,
resueltas y faltantes, supuestos y riesgos. Plan solo redelega cuando una
respuesta cambia el analisis tecnico, sus supuestos o el routing.

## Exportacion Oracle a Excel o CSV

Para una exportacion, Plan obtiene el contrato y los faltantes desde
`excel-template-analyst`. Build solicita a `oracle-query-builder` que lea el
catalogo y genere el SELECT con columnas explicitas. El SQL final queda
registrado en un manifiesto creado por `excel-template-builder`, que agrega
automaticamente su hash de integridad sin pedir confirmacion conversacional
antes de abrir Oracle.

La ejecucion usa `.env` y una cuenta Oracle de solo lectura. El exportador
fuerza CSV si cualquier resultado supera 1,048,576 filas. El XLSX contiene
 tablas estructuradas y no se sobrescriben archivos existentes.

Ejemplos:

- Plan: `Analiza una limpieza de datos para una familia y prepara el plan.`
- Build: `Implementa el script aprobado en plsql_scripts/...`.
- Plan: `Analiza una plantilla Excel pivotada para preguntas SIGEIF.`
- Build: `Genera el archivo Excel pivotado con el SELECT y las rutas indicadas.`
- Build: `Exporta las tablas seleccionadas a XLSX con estos filtros.`
- Build: `Completa los IDs de este Excel usando el catalogo y los cinco parametros confirmados.`
