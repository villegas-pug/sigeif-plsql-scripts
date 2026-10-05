"""Adapta permisos de especialistas a PreToolUse sin ejecutar negocio ni SQL."""

import json
import os
import re
import shlex
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
POLICY_PATH = Path(__file__).with_name("permission-policy.json")
FILE_TOOLS = {"Read", "Glob", "Grep", "Edit", "Write"}


def emit(decision, reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": decision,
        "permissionDecisionReason": reason,
    }}, ensure_ascii=False))


def resolve_path(value, cwd):
    """Resuelve rutas reales y padres existentes para detectar escapes/symlinks."""
    path = Path(os.path.expanduser(value))
    if not path.is_absolute():
        path = cwd / path
    return path.resolve()


def relative_path(path):
    try:
        return path.relative_to(PROJECT_ROOT).as_posix()
    except ValueError:
        return None


def glob_match(path, pattern):
    """El doble asterisco cruza directorios; el simple no cruza separadores."""
    expression = ""
    index = 0
    while index < len(pattern):
        if pattern[index:index + 3] == "**/":
            expression += "(?:.*/)?"
            index += 3
        elif pattern[index:index + 2] == "**":
            expression += ".*"
            index += 2
        elif pattern[index] == "*":
            expression += "[^/]*"
            index += 1
        elif pattern[index] == "?":
            expression += "[^/]"
            index += 1
        else:
            expression += re.escape(pattern[index])
            index += 1
    return re.fullmatch(expression, path, flags=re.IGNORECASE if os.name == "nt" else 0) is not None


def listed_command(command, allowed, cwd):
    """Reconoce una sola invocación literal; no interpreta ni ejecuta shell."""
    # Permitir delimitadores literales en argumentos entre comillas (como los
    # rangos de categorías), pero no composición ni expansión de shell.
    quote = None
    escaped = False
    for char in command:
        if char in "\r\n":
            return False
        if escaped:
            escaped = False
            continue
        if char == "\\" and quote != "'":
            escaped = True
            continue
        if quote == "'":
            if char == "'":
                quote = None
        elif quote == '"':
            if char == '"':
                quote = None
            elif char in "$`":
                return False
        elif char in "'\"":
            quote = char
        elif char in ";&|<>`$()#":
            return False
    if quote is not None:
        return False
    try:
        tokens = shlex.split(command, posix=True)
    except ValueError:
        return False
    if len(tokens) < 3:
        return False
    script = tokens[1].replace("\\", "/")
    if tokens[0] != "python" or f"python {script}" not in allowed:
        return False
    # El CLI se invoca respecto de la raíz, igual que los comandos del contrato.
    if cwd != PROJECT_ROOT:
        return False
    return resolve_path(script, cwd).is_relative_to(PROJECT_ROOT)


def decide(event, policy):
    name = event.get("agent_type")
    if name is None:
        if event.get("agent_id"):
            return "deny", "Falta la identidad del especialista; no se puede aplicar su política."
        # No altera permisos del principal ni de agentes no migrados.
        return None
    if not isinstance(name, str):
        return "deny", "Contexto de agente inválido."
    rule = policy["agents"].get(name)
    if rule is None:
        return None
    tool = event.get("tool_name")
    arguments = event.get("tool_input")
    if not isinstance(arguments, dict) or tool not in rule["tools"]:
        return "deny", "Herramienta o entrada no autorizada para este especialista."
    cwd_value = event.get("cwd")
    if not isinstance(cwd_value, str) or not cwd_value:
        return "deny", "Falta el directorio de trabajo del evento."
    cwd = Path(cwd_value).resolve()

    if tool == "Skill":
        skill = arguments.get("skill")
        if not isinstance(skill, str) or skill not in rule["skills"]:
            return "deny", "Skill no autorizada para este especialista."
        return "allow", "Skill incluida en la política del especialista."

    if tool in FILE_TOOLS:
        key = "file_path" if tool in {"Read", "Write", "Edit"} else "path"
        value = arguments.get(key)
        if value is None and tool in {"Glob", "Grep"}:
            value = str(cwd)
        if not isinstance(value, str) or not value:
            return "deny", "Ruta inválida o ausente."
        path = resolve_path(value, cwd)
        relative = relative_path(path)
        if tool in {"Write", "Edit"}:
            if relative is None or not any(glob_match(relative, item) for item in rule["edit"]):
                return "deny", "Escritura fuera del patrón autorizado del especialista."
            return "allow", "Escritura incluida en el ámbito autorizado."
        # Examinar también la ruta pedida: no permitir ../ como escape a una
        # excepción de lectura ni asumir que un symlink permanece en la raíz.
        if relative is None:
            external = rule["external_directory"]
            if external == "deny":
                return "deny", "Acceso externo denegado para este especialista."
            if external == "ask":
                return "ask", "El especialista requiere aprobación de acceso externo."
        return "allow", "Lectura o búsqueda autorizada."

    if tool == "Bash":
        command = arguments.get("command")
        if not isinstance(command, str) or not command.strip():
            return "deny", "Comando vacío o inválido."
        if rule["bash"] == "allow":
            return "allow", "Bash permitido para el builder PL/SQL; conservan vigencia los gates Oracle."
        if rule["bash"] == "ask-listed" and listed_command(command, rule["commands"], cwd):
            return "ask", "Comando previsto por el flujo; requiere aprobación técnica."
        return "deny", "Comando no incluido en la política del especialista."
    return "deny", "Herramienta sin traducción autorizada."


def main():
    try:
        raw = sys.stdin.read(1024 * 1024 + 1)
        if len(raw) > 1024 * 1024:
            emit("deny", "Evento demasiado grande para validar permisos.")
            return 2
        event = json.loads(raw)
        if not isinstance(event, dict) or event.get("hook_event_name") != "PreToolUse":
            emit("deny", "Evento de permisos inválido.")
            return 2
        policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
        result = decide(event, policy)
        if result is not None:
            emit(*result)
        return 0
    except Exception:
        # No incluir entradas, rutas sensibles ni comandos en el diagnóstico.
        emit("deny", "No se pudo validar la política del especialista.")
        return 2


if __name__ == "__main__":
    sys.exit(main())
