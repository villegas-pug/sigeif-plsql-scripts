# Uso de OpenCode en este proyecto

El proyecto personaliza los agentes built-in `plan` y `build` mediante los
overrides locales `.opencode/agents/plan.md` y `.opencode/agents/build.md`.
No son agentes primarios adicionales.

1. Usa `Plan` para analizar una solicitud Oracle o Excel. El override delega
   solo a analistas y devuelve un plan con riesgos, dependencias y archivos.
2. Usa `Build` para implementar una solicitud o un plan aprobado. El override
   delega solo al builder especializado y no implementa directamente.
3. Describe la necesidad en lenguaje natural. No hay slash commands del
   proyecto y no se debe invocar subagentes con `@`, porque se saltarían los
   gates de Plan y Build.

Ejemplos:

- Plan: `Analiza una limpieza de datos para una familia y prepara el plan.`
- Build: `Implementa el script aprobado en plsql_scripts/...`.
- Plan: `Analiza una plantilla Excel pivotada para preguntas SIGEIF.`
- Build: `Genera el archivo Excel pivotado con el SELECT y las rutas indicadas.`
- Plan: `Analiza el poblado fuzzy de IDs desde este catálogo Excel.`
- Build: `Completa los IDs de este Excel usando el catálogo y los cinco parámetros confirmados.`
