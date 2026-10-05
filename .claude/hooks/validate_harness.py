"""Valida artefactos y provenance estáticamente, sin ejecutar hooks ni negocio."""

import argparse
import ast
import copy
import hashlib
import json
import re
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[2]
CLAUDE = ROOT / ".claude"
NORMALIZATION = "utf8-lf-without-generated-sha256-and-synced-at"
SHARED_COMPATIBILITY = "opencode, claude-code"
# Las Skills son fuente única compartida; no deben depender de un harness.
HARNESS_SPECIFIC = re.compile(r"\.opencode/|AskUserQuestion|`question`|harness-sync")


def sha256(content):
    return hashlib.sha256(content).hexdigest()


def canonical_markdown(text):
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    if not text.startswith("---\n"):
        raise ValueError("Frontmatter ausente")
    header, body = text[4:].split("\n---\n", 1)
    # Eliminar únicamente los campos de hash/tiempo del bloque de provenance;
    # no ignorar modificaciones del cuerpo ni de otros campos del documento.
    header = re.sub(r"^    (?:generated_sha256|synced_at):.*\n?", "", header, flags=re.MULTILINE)
    return ("---\n" + header.rstrip("\n") + "\n---\n" + body).rstrip("\n").encode("utf-8") + b"\n"


def source_path(relative):
    path = (ROOT / relative).resolve()
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError(f"Referencia fuera del repositorio o inexistente: {relative}")
    return path


def validate(print_hashes=False):
    policy_file = CLAUDE / "hooks/permission-policy.json"
    policy = json.loads(policy_file.read_text(encoding="utf-8"))
    settings = json.loads((CLAUDE / "settings.json").read_text(encoding="utf-8"))
    hook = settings["hooks"]["PreToolUse"][0]["hooks"][0]
    assert hook["type"] == "command" and hook["command"] == "python"
    assert hook["args"] == ["${CLAUDE_PROJECT_DIR}/.claude/hooks/permission_guard.py"]
    assert "permissions" not in settings, "No añadir permisos generales al principal"
    assert len(policy["agents"]) == 9
    agents = sorted((CLAUDE / "agents").glob("*.md"))
    skills = sorted((CLAUDE / "skills").glob("*/SKILL.md"))
    assert len(agents) == len(skills) == 9
    assert not (CLAUDE / "agents/plan.md").exists()
    assert not (CLAUDE / "agents/build.md").exists()
    for duplicate in (ROOT / ".opencode/skills", ROOT / ".agents/skills"):
        assert not duplicate.exists(), f"Skills duplicadas fuera de la fuente única: {duplicate}"
    skill_names = set()
    for path in skills:
        text = path.read_text(encoding="utf-8")
        assert text.startswith("---\n"), path
        frontmatter = yaml.safe_load(text.split("---", 2)[1])
        assert frontmatter["name"] == path.parent.name and frontmatter["description"], path
        assert frontmatter.get("compatibility") == SHARED_COMPATIBILITY, path
        assert "metadata" not in frontmatter, f"Skill compartida con provenance generada: {path}"
        for item in path.parent.rglob("*"):
            if item.is_file() and item.suffix in {".md", ".json", ".py"}:
                match = HARNESS_SPECIFIC.search(item.read_text(encoding="utf-8"))
                assert match is None, f"Referencia específica de harness '{match.group(0)}': {item}"
        skill_names.add(path.parent.name)
    json.loads((CLAUDE / "skills/excel-catalog-fuzzy-resolver/scripts/aliases_es.json").read_text(encoding="utf-8"))
    documents = agents + [ROOT / "CLAUDE.md"]
    origins = set()
    hashes = {}
    source_count = 0
    for path in documents:
        text = path.read_text(encoding="utf-8")
        assert text.startswith("---\n"), path
        frontmatter = yaml.safe_load(text.split("---", 2)[1])
        provenance = frontmatter["metadata"]["harness-sync"]
        origin = provenance["origin"]
        identity = (origin["harness"], origin["name"])
        assert identity not in origins, f"Identidad duplicada: {identity}"
        origins.add(identity)
        assert sha256(source_path(origin["path"]).read_bytes()) == provenance["source_sha256"], path
        source_count += 1
        digest = sha256(canonical_markdown(text))
        hashes[path.relative_to(ROOT).as_posix()] = digest
        if not print_hashes:
            assert provenance["generated_sha256"] == digest, f"Destino editado o hash pendiente: {path}"
        if path in agents:
            name = frontmatter["name"]
            assert name == path.stem and frontmatter["description"]
            tools = frontmatter["tools"]
            if isinstance(tools, str):
                tools = [item.strip() for item in tools.split(",")]
            assert tools == policy["agents"][name]["tools"], path
            assert "Agent" not in tools and "AskUserQuestion" not in tools
            assert "omitClaudeMd" not in frontmatter, f"El especialista perdería CLAUDE.md/AGENTS.md: {path}"
    for path in sorted((CLAUDE / "hooks").glob("*.py")):
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    for name in ("settings.json", "hooks/permission_guard.py", "hooks/validate_harness.py"):
        path = CLAUDE / name
        hashes[path.relative_to(ROOT).as_posix()] = sha256(path.read_bytes())
    generated = policy["metadata"]["harness-sync"]["generated_files"]
    if not print_hashes:
        assert generated == {key: hashes[key] for key in hashes if not key.endswith(".md")}, "Hashes de settings/hooks desactualizados"
        source_hashes = policy["metadata"]["harness-sync"]["source_files"]
        for name, expected in source_hashes.items():
            assert sha256(source_path(name).read_bytes()) == expected, f"Origen modificado: {name}"
    for name, rule in policy["agents"].items():
        original_meta = yaml.safe_load((ROOT / f".opencode/agents/{name}.md").read_text(encoding="utf-8").split("---", 2)[1])
        permissions = original_meta["permission"]
        assert rule["external_directory"] == permissions["external_directory"]
        original_skills = permissions["skill"]
        assert rule["skills"] == [key for key, value in original_skills.items() if value == "allow"]
        assert set(rule["skills"]) <= skill_names, f"Skill inexistente en la política de {name}"
        original_edit = permissions["edit"]
        assert rule["edit"] == ([key for key, value in original_edit.items() if value == "allow"] if isinstance(original_edit, dict) else [])
        original_bash = permissions["bash"]
        assert rule["bash"] == ("ask-listed" if isinstance(original_bash, dict) else original_bash)
        if isinstance(original_bash, dict):
            commands = [key.removesuffix(" *") for key, value in original_bash.items() if value == "ask"]
            assert rule["commands"] == commands
    normalized_policy = copy.deepcopy(policy)
    policy_provenance = normalized_policy["metadata"]["harness-sync"]
    policy_provenance.pop("generated_sha256", None)
    policy_provenance.pop("synced_at", None)
    policy_digest = sha256(json.dumps(normalized_policy, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8"))
    hashes[policy_file.relative_to(ROOT).as_posix()] = policy_digest
    if not print_hashes:
        assert policy["metadata"]["harness-sync"]["generated_sha256"] == policy_digest, "Política editada o hash pendiente"
    if print_hashes:
        print(json.dumps(hashes, indent=2, ensure_ascii=False))
    else:
        print(f"Validación estática correcta: 9 agentes, 9 Skills compartidas, {source_count} orígenes, JSON, AST y provenance íntegros.")
        print("No se ejecutó ningún agente, hook, resolvedor, exportación, prueba ni SQL.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Valida estáticamente la migración y sus hashes, sin escribir archivos.")
    parser.add_argument("--print-hashes", action="store_true", help="Imprime hashes candidatos sin comprobar generated_sha256.")
    arguments = parser.parse_args()
    validate(arguments.print_hashes)
