# Uso de OpenCode en este proyecto

El proyecto usa los agentes primarios built-in `plan` y `build` de OpenCode.
La configuracion especifica de SIGEIF se agrega en `.opencode/opencode.json`;
no existen overrides locales de sus prompts.

1. Usa `Plan` para analizar una solicitud Oracle o Excel. Conserva su
   comportamiento built-in y delega el analisis tecnico a los analistas
   permitidos, devolviendo un plan con riesgos, dependencias y archivos.
2. Usa `Build` para implementar una solicitud o un plan aprobado. Conserva su
   comportamiento built-in y delega el trabajo de dominio a los builders
   permitidos.
3. Describe la necesidad en lenguaje natural. No hay slash commands del
   proyecto y no se debe invocar subagentes con `@`, porque se saltarian los
   gates de Plan y Build.

Ejemplos:

- Plan: `Analiza una limpieza de datos para una familia y prepara el plan.`
- Build: `Implementa el script aprobado en plsql_scripts/...`.
- Plan: `Analiza una plantilla Excel pivotada para preguntas SIGEIF.`
- Build: `Genera el archivo Excel pivotado con el SELECT y las rutas indicadas.`
- Plan: `Analiza el poblado fuzzy de IDs desde este catálogo Excel.`
- Build: `Completa los IDs de este Excel usando el catálogo y los cinco parámetros confirmados.`
