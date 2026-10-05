---
metadata:
  harness-sync:
    version: 1
    origin:
      harness: opencode
      name: project-instructions
      path: AGENTS.md
    source_sha256: 24949f244c7e3253b4963ae2437e1cadf822d608868e801654beb496387c8f9c
    transformations: [reference-shared-rules, compact-harness-differences, adapt-coordination-to-main]
    losses: [primary-overrides, specialist-user-question-tool, exact-permission-engine]
    generated_sha256: 62caa24f182a1973e3e0f7f0f71bbcd6ad964a536ccd3c1ac2ad2f564520e81d
    synced_at: "2026-10-05T00:00:00Z"
    hash_scope: utf8-lf-without-generated-sha256-and-synced-at
---

# Claude Code Project Instructions

@AGENTS.md

## Harness Compatibility

Las reglas comunes viven en `AGENTS.md`; este complemento solo describe las
diferencias de Claude. Como existe este `CLAUDE.md`, Claude Code no lee
`AGENTS.md` de forma nativa: lo incluye el import anterior, que nunca lo duplica
con ningún valor de *Project instructions*. El import también cubre versiones
anteriores a v2.1.277 y sesiones sin el plugin `agents-md`. No reemplazarlo por
un symlink: en Windows Git lo convierte en un archivo de texto.

- No hay overrides de `plan` o `build`, ni comandos que los sustituyan.
- El agente principal coordina las fases de planificación e implementación.
  Activar el modo Plan nativo cuando se necesite su frontera de solo lectura;
  estas instrucciones no cambian los permisos ni activan modos por sí mismas.
- Los especialistas locales están en `.claude/agents/`. Usar la herramienta
  `Agent` para delegar y `Skill` para cargar instrucciones. Los especialistas no
  delegan ni deben declarar `omitClaudeMd`, porque perderían estas reglas.
- Las Skills de `.claude/skills/` son la fuente única compartida con OpenCode:
  no añadir en ellas texto, herramientas ni rutas exclusivas de Claude.
- Los subagentes integrados `Explore` y `Plan` no cargan `CLAUDE.md` ni
  `AGENTS.md`. No usarlos para capacidades Oracle o Excel; si se usan para
  búsquedas genéricas, incluir en el prompt las reglas aplicables.
- Un especialista devuelve faltantes y bloqueos al principal; el principal
  pregunta al usuario. `AskUserQuestion` no está disponible en los subagentes
  de Claude aunque se enumere en su frontmatter.

## Permission Compatibility

Las herramientas permitidas se declaran por agente. El hook de proyecto en
`.claude/settings.json` consulta `.claude/hooks/permission-policy.json` para adaptar
reglas específicas de escritura, Bash, Skills y acceso externo al especialista.
No añade aprobaciones generales de Bash/Write/Edit al principal. El builder
PL/SQL conserva Bash; los builders SQL/script no lo reciben.

El hook responde `allow` al Bash del builder PL/SQL, lo que omite el prompt de
permisos: la prohibición de conectar a Oracle depende de las instrucciones, no
de un control técnico.

Estos controles son una adaptación funcional, no el motor de permisos de
OpenCode. Las denegaciones y reglas `ask` nativas de mayor precedencia siguen
aplicándose. Los hooks pueden desactivarse o fallar sin bloquear, por ejemplo
si el intérprete no está disponible o expira el proceso. No declararlos una
frontera OS ni equivalencia exacta. Revisar la confianza del workspace, `/hooks`
y `/permissions` antes de usar los especialistas. No usar bypass para evitar
las restricciones del proyecto.

Las reglas externas se aplican a llamadas de herramientas, no a los accesos
indirectos de Bash. No hay equivalente de `doom_loop: deny`. La aprobación
técnica `ask` de un comando Excel no es la confirmación conversacional del hash.

<!-- Mantenimiento: validar con python .claude/hooks/validate_harness.py.
Tras editar este archivo o AGENTS.md, recalcular source_sha256 y generated_sha256
(--print-hashes). No generar reportes en outputs/. Las preferencias de idioma,
Git y ejecución proceden del global; no importar rutas personales absolutas.
Documentación de carga: https://code.claude.com/docs/en/memory#agents-md . -->
