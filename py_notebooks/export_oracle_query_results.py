from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import tempfile
from pathlib import Path
from typing import Any, Iterable


MAX_EXCEL_ROWS = 1_048_576
FORMULA_PREFIXES = ("=", "+", "-", "@")


# ---------------------------------------------------------------------------
# Environment / DSN
# ---------------------------------------------------------------------------

def load_env(path: Path, profile: str | None = None) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].lstrip()
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
            value = value[1:-1]
        values[key.strip()] = value
    selected_profile = (profile or values.get("ORACLE_PROFILE", "")).strip().upper()
    if selected_profile:
        suffix = f"_{selected_profile}"
        for key, value in list(values.items()):
            if key.endswith(suffix):
                values[key[: -len(suffix)]] = value
    return values


def make_dsn(config: dict[str, str]) -> str:
    dsn = config.get("ORACLE_DSN")
    if dsn:
        return dsn
    host = config.get("ORACLE_HOST")
    port = config.get("ORACLE_PORT", "1521")
    sid = config.get("ORACLE_SID")
    service_name = config.get("ORACLE_SERVICE_NAME")
    if not host or not (sid or service_name):
        raise ValueError(
            "Define ORACLE_DSN o bien ORACLE_HOST con ORACLE_SID/ORACLE_SERVICE_NAME."
        )
    import oracledb
    if sid:
        return oracledb.makedsn(host, int(port), sid=sid)
    return oracledb.makedsn(host, int(port), service_name=service_name)


# ---------------------------------------------------------------------------
# Manifest
# ---------------------------------------------------------------------------

def load_manifest(path: Path) -> dict[str, Any]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError(f"El manifiesto no es JSON valido: {error}") from error
    if not isinstance(manifest, dict):
        raise ValueError("El manifiesto debe ser un objeto JSON.")
    for field in ("output", "format", "queries"):
        if field not in manifest:
            raise ValueError(f"Falta el campo obligatorio del manifiesto: {field}")
    if manifest["format"] not in {"xlsx", "csv"}:
        raise ValueError("format debe ser xlsx o csv.")
    if "sheet_name" in manifest and (
        not isinstance(manifest["sheet_name"], str) or not manifest["sheet_name"].strip()
    ):
        raise ValueError("sheet_name debe ser texto no vacio.")
    if not isinstance(manifest["queries"], list) or not manifest["queries"]:
        raise ValueError("queries debe contener al menos una consulta.")
    for index, query in enumerate(manifest["queries"], start=1):
        if not isinstance(query, dict) or not isinstance(query.get("sql"), str):
            raise ValueError(f"La consulta {index} debe incluir sql como texto.")
        if not isinstance(query.get("binds", {}), dict):
            raise ValueError(f"Los binds de la consulta {index} deben ser un objeto.")
    return manifest


# ---------------------------------------------------------------------------
# SQL validation
# ---------------------------------------------------------------------------

def replace_sql_literals(sql: str) -> str:
    output: list[str] = []
    index = 0
    while index < len(sql):
        character = sql[index]
        if character != "'":
            output.append(character)
            index += 1
            continue
        output.append(" ")
        index += 1
        while index < len(sql):
            if sql[index] == "'":
                if index + 1 < len(sql) and sql[index + 1] == "'":
                    output.append("  ")
                    index += 2
                    continue
                index += 1
                break
            output.append(" ")
            index += 1
    return "".join(output)


def validate_select(sql: str) -> str:
    if not sql.strip():
        raise ValueError("La consulta no puede estar vacia.")
    outside_literals = replace_sql_literals(sql)
    if any(marker in outside_literals for marker in ("--", "/*", "*/", ";", "@")):
        raise ValueError("La consulta contiene comentarios, multiples sentencias o un enlace no permitido.")
    normalized = re.sub(r"\s+", " ", outside_literals).strip().upper()
    if not re.match(r"^(SELECT|WITH)\b", normalized):
        raise ValueError("Cada consulta debe iniciar con SELECT o WITH.")
    forbidden = (
        r"\b(INSERT|UPDATE|DELETE|MERGE|TRUNCATE|DROP|CREATE|ALTER|GRANT|REVOKE|"
        r"EXECUTE|IMMEDIATE|COMMIT|ROLLBACK|CALL|BEGIN|DECLARE)\b"
    )
    if re.search(forbidden, normalized) or re.search(r"\bFOR\s+UPDATE\b", normalized):
        raise ValueError("La consulta contiene una operacion o bloqueo no permitido.")
    if re.search(r"(?:\bSELECT\s+|,)\s*(?:[A-Z0-9_$#]+\.)*\*\s*(?:,|\bFROM\b|$)", normalized):
        raise ValueError("La exportacion requiere columnas explicitas; no se permite SELECT *.")
    return sql.strip()


# ---------------------------------------------------------------------------
# Hash
# ---------------------------------------------------------------------------

def confirmation_hash(manifest: dict[str, Any]) -> str:
    payload = {
        "output": manifest["output"],
        "format": manifest["format"],
        "sheet_mode": manifest.get("sheet_mode", "one_per_result"),
        "sheet_name": manifest.get("sheet_name", "Resultados"),
        "queries": [
            {
                "name": query.get("name", f"resultado_{index}"),
                "sql": validate_select(query["sql"]),
                "binds": query.get("binds", {}),
            }
            for index, query in enumerate(manifest["queries"], start=1)
        ],
    }
    encoded = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(encoded.encode("utf-8")).hexdigest()


# ---------------------------------------------------------------------------
# Oracle -> XLSX (directo, sin CSV intermedio)
# ---------------------------------------------------------------------------

def parse_headers(description: Iterable[Any]) -> list[str]:
    headers: list[str] = []
    seen: dict[str, int] = {}
    for item in description:
        base = str(item[0]).strip() or "COLUMN"
        count = seen.get(base, 0) + 1
        seen[base] = count
        headers.append(base if count == 1 else f"{base}_{count}")
    return headers


def safe_value(value: Any) -> Any:
    if hasattr(value, "read") and callable(value.read):
        value = value.read()
    if isinstance(value, (bytes, bytearray, memoryview)):
        raise ValueError("El resultado contiene un tipo binario no exportable.")
    if isinstance(value, str) and value.startswith(FORMULA_PREFIXES):
        return "'" + value
    return value


def _is_number(value: Any) -> bool:
    return isinstance(value, (int, float))


def _infer_numeric(value: str) -> Any:
    """Intenta inferir numero desde CSV para alineacion."""
    try:
        v = float(value)
        return int(v) if v == int(v) else v
    except (ValueError, OverflowError):
        return value


def safe_sheet_title(value: str, used: set[str]) -> str:
    title = re.sub(r"[\\/*?:\[\]]", "_", value).strip() or "Resultado"
    title = title[:31]
    candidate = title
    suffix = 2
    while candidate in used:
        suffix_text = f"_{suffix}"
        candidate = f"{title[:31 - len(suffix_text)]}{suffix_text}"
        suffix += 1
    used.add(candidate)
    return candidate


def _make_border() -> Any:
    from openpyxl.styles import Border, Side
    side = Side(style="thin", color="808080")
    return Border(left=side, right=side, top=side, bottom=side)


def write_cursor_to_xlsx(
    cursor: Any,
    worksheet: Any,
    start_row: int,
) -> tuple[int, int]:
    """Escribe cursor Oracle directamente al worksheet con formato.

    Retorna (last_row, row_count).
    """
    from openpyxl.styles import Alignment, Font, PatternFill
    from openpyxl.utils import get_column_letter

    headers = parse_headers(cursor.description or [])
    border = _make_border()
    header_font = Font(bold=True)
    header_fill = PatternFill(fill_type="solid", fgColor="D9D9D9")
    align_left = Alignment(horizontal="left")
    align_right = Alignment(horizontal="right")

    row_count = 0
    max_col = len(headers)
    # Anchos de columna por defecto
    col_widths: dict[int, float] = {c + 1: max(len(h), 10) for c, h in enumerate(headers)}

    # Fila de encabezados
    current_row = start_row
    for col, header in enumerate(headers, start=1):
        cell = worksheet.cell(row=current_row, column=col, value=header)
        cell.border = border
        cell.font = header_font
        cell.fill = header_fill
        cell.alignment = align_left
    current_row += 1

    # Filas de datos
    while True:
        rows = cursor.fetchmany(2_000)
        if not rows:
            break
        for row_data in rows:
            for col, raw_value in enumerate(row_data, start=1):
                value = safe_value(raw_value)
                is_num = _is_number(value)
                cell = worksheet.cell(
                    row=current_row,
                    column=col,
                    value=value,
                )
                cell.border = border
                cell.alignment = align_right if is_num else align_left
                if is_num:
                    width = max(len(str(value)), col_widths.get(col, 10))
                    col_widths[col] = min(width, 30)
            current_row += 1
            row_count += 1

    # Aplicar anchos de columna
    for col, width in col_widths.items():
        worksheet.column_dimensions[get_column_letter(col)].width = width + 2

    last_row = current_row - 1
    return last_row, row_count


def write_cursor_to_csv(cursor: Any, output_path: Path) -> tuple[list[str], int]:
    """Escribe cursor Oracle directamente a CSV."""
    headers = parse_headers(cursor.description or [])
    row_count = 0
    with output_path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(headers)
        while True:
            rows = cursor.fetchmany(2_000)
            if not rows:
                break
            for row_data in rows:
                writer.writerow([safe_value(v) for v in row_data])
                row_count += 1
    return headers, row_count


# ---------------------------------------------------------------------------
# Oracle
# ---------------------------------------------------------------------------

def connect(config: dict[str, str]) -> Any:
    import oracledb
    user = config.get("ORACLE_USER")
    password = config.get("ORACLE_PASSWORD") or config.get("ORACLE_PWD")
    if not user or not password:
        raise ValueError("Define ORACLE_USER y ORACLE_PASSWORD en el archivo .env.")
    dsn = make_dsn(config)
    return oracledb.connect(user=user, password=password, dsn=dsn)


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

def output_csv_paths(output_path: Path, count: int) -> list[Path]:
    if count == 1:
        return [output_path]
    paths: list[Path] = []
    for index in range(1, count + 1):
        paths.append(output_path.with_name(f"{output_path.stem}_{index}.csv"))
    return paths


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------

def export(
    manifest: dict[str, Any], env_path: Path, profile: str | None = None
) -> list[Path]:
    # Infierir y aplicar hash automaticamente
    actual_hash = confirmation_hash(manifest)
    manifest["confirmed_query_hash"] = actual_hash

    output_path = Path(manifest["output"]).expanduser()
    requested_format = manifest["format"]
    if requested_format == "xlsx" and output_path.suffix.lower() != ".xlsx":
        raise ValueError("Una salida XLSX debe terminar en .xlsx.")
    if requested_format == "csv" and output_path.suffix.lower() not in {".csv", ".xlsx"}:
        raise ValueError("Una salida CSV debe terminar en .csv o usar .xlsx como nombre base.")
    sheet_mode = manifest.get("sheet_mode", "one_per_result")
    if sheet_mode not in {"same_sheet", "one_per_result"}:
        raise ValueError("sheet_mode debe ser same_sheet o one_per_result.")
    sheet_name = str(manifest.get("sheet_name", "Resultados"))
    if output_path.exists():
        raise FileExistsError(f"El archivo de salida ya existe: {output_path}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    queries = manifest["queries"]

    # --- CSV: un archivo por consulta, sin XLSX ---
    if requested_format == "csv":
        csv_targets = output_csv_paths(output_path, len(queries))
        for i, (query, dest) in enumerate(zip(queries, csv_targets)):
            if dest.exists():
                raise FileExistsError(f"El archivo de salida ya existe: {dest}")
        connection = None
        results_meta: list[dict[str, Any]] = []
        try:
            connection = connect(load_env(env_path, profile))
            for index, query in enumerate(queries):
                name = str(query.get("name") or f"resultado_{index + 1}")
                dest = csv_targets[index]
                cursor = connection.cursor()
                try:
                    cursor.execute(validate_select(query["sql"]), query.get("binds", {}))
                    headers, row_count = write_cursor_to_csv(cursor, dest)
                finally:
                    cursor.close()
                results_meta.append({"name": name, "row_count": row_count, "headers": headers})
        finally:
            if connection is not None:
                connection.close()
        summary = "; ".join(
            f"{r['name']}: {r['row_count']} filas, {len(r['headers'])} columnas"
            for r in results_meta
        )
        print(f"Exportacion completada (csv): {', '.join(map(str, csv_targets))}")
        print(summary)
        return csv_targets

    # --- XLSX: Oracle -> Excel directo (sin CSV intermedio) ---
    connection = None
    try:
        connection = connect(load_env(env_path, profile))

        from openpyxl import Workbook
        workbook = Workbook()
        workbook.remove(workbook.active)
        used_titles: set[str] = set()
        total_row_count = 0

        if sheet_mode == "same_sheet":
            ws = workbook.create_sheet(safe_sheet_title(sheet_name, used_titles))
            current_row = 1
            for index, query in enumerate(queries):
                name = str(query.get("name") or f"resultado_{index + 1}")
                cursor = connection.cursor()
                try:
                    cursor.execute(validate_select(query["sql"]), query.get("binds", {}))
                    _, row_count = write_cursor_to_xlsx(cursor, ws, current_row)
                finally:
                    cursor.close()
                current_row += row_count + 1  # datos + separador
                total_row_count += row_count
        else:
            for index, query in enumerate(queries):
                name = str(query.get("name") or f"resultado_{index + 1}")
                title = safe_sheet_title(name, used_titles)
                ws = workbook.create_sheet(title)
                cursor = connection.cursor()
                try:
                    cursor.execute(validate_select(query["sql"]), query.get("binds", {}))
                    _, row_count = write_cursor_to_xlsx(cursor, ws, 1)
                finally:
                    cursor.close()
                total_row_count += row_count
                if row_count > 0:
                    ws.freeze_panes = "A2"

        output_path.parent.mkdir(parents=True, exist_ok=True)
        workbook.save(output_path)
    finally:
        if connection is not None:
            connection.close()

    created = [output_path]
    summary_lines = []
    for index, query in enumerate(queries):
        name = str(query.get("name") or f"resultado_{index + 1}")
        summary_lines.append(f"{name}")
    summary = ", ".join(summary_lines)
    print(f"Exportacion completada (xlsx): {', '.join(map(str, created))}")
    print(f"{len(queries)} resultados, {total_row_count} filas totales")
    return created


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Exporta SELECT Oracle a XLSX o CSV.")
    parser.add_argument("--manifest", required=True, help="Manifiesto JSON con consultas, binds y salida.")
    parser.add_argument("--env-file", default=".env", help="Archivo de configuracion Oracle.")
    parser.add_argument(
        "--profile",
        default="PROD",
        help="Perfil del archivo .env; por defecto PROD. Sus variables *_PROFILE se mapean a variables base.",
    )
    parser.add_argument(
        "--print-query-hash", action="store_true", help="Muestra el hash sin conectarse a Oracle."
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    manifest = load_manifest(Path(args.manifest).expanduser())
    if args.print_query_hash:
        print(confirmation_hash(manifest))
        return
    export(manifest, Path(args.env_file).expanduser(), args.profile)


if __name__ == "__main__":
    main()
