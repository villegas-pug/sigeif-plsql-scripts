---
metadata:
  harness-sync:
    version: 1
    origin:
      harness: opencode
      name: project-instructions
      path: AGENTS.md
    source_sha256: 5a74755964435148fd4a501a54ba6ff3360b4715f11d2752d4bae5ba8df46650
    transformations: [reference-shared-rules, compact-harness-differences, adapt-coordination-to-main, adapt-skill-paths]
    losses: [primary-overrides, specialist-user-question-tool, exact-permission-engine]
    generated_sha256: 352a0d3eba2362f882096a1e566c03c2ec1922b8d9c17dd27b7e3e61115eb6a7
    synced_at: "2026-10-04T12:27:02Z"
    hash_scope: utf8-lf-without-generated-sha256-and-synced-at
---

# Claude Code Project Instructions

@AGENTS.md

## Harness Compatibility

Las reglas comunes se mantienen en `AGENTS.md`; este complemento solo describe
diferencias de Claude. La importación se conserva porque la carga predeterminada
elige CLAUDE.md cuando ambos coexisten; Claude deduplica AGENTS.md si también
se carga nativamente. No requiere modificar la configuración global del usuario.

- No hay overrides migrados de `plan` o `build`, ni comandos que los sustituyan.
- El agente principal coordina las fases de planificación e implementación.
  Activar el modo Plan nativo cuando se necesite su frontera de solo lectura;
  estas instrucciones no cambian los permisos ni activan modos por sí mismas.
- Los especialistas locales están en `.claude/agents/` y las Skills en
  `.claude/skills/`. Usar la herramienta `Agent` para delegar y `Skill` para
  cargar instrucciones. Los especialistas no delegan.
- Un especialista devuelve faltantes y bloqueos al principal; el principal
  pregunta al usuario. `AskUserQuestion` no está disponible en los subagentes
  de Claude aunque se enumere en su frontmatter.
- El contrato descriptivo de report-list está en
  `.claude/skills/build-report-list-sp/SKILL.md`.

## Permission Compatibility

Las herramientas permitidas se declaran por agente. El hook de proyecto en
`.claude/settings.json` consulta `.claude/hooks/permission-policy.json` para adaptar
reglas específicas de escritura, Bash, Skills y acceso externo al especialista.
No añade aprobaciones generales de Bash/Write/Edit al principal. El builder
PL/SQL conserva Bash; los builders SQL/script no lo reciben.

Estos controles son una adaptación funcional, no el motor de permisos de
OpenCode. Las denegaciones y reglas `ask` nativas de mayor precedencia siguen
aplicándose. Los hooks pueden desactivarse o fallar sin bloquear, por ejemplo
si el intérprete no está disponible o expira el proceso. No declararlos una
frontera OS ni equivalencia exacta. Revisar la confianza del workspace, `/hooks`
y `/permissions` antes de usar los especialistas. No usar bypass para evitar
las restricciones del proyecto.

Las reglas externas se aplican a llamadas de herramientas, no a los accesos
indirectos de Bash. No hay equivalente migrado de `doom_loop: deny`. La aprobación
técnica `ask` de un comando Excel no es la confirmación conversacional del hash.

<!-- Mantenimiento: validar provenance con .claude/hooks/validate_harness.py.
No generar reportes en outputs/. Las preferencias de idioma, Git y ejecución
proceden del global; no importar rutas personales absolutas. Documentación de
carga: https://code.claude.com/docs/en/memory#agents-md . -->
