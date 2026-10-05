---
name: build-excel-pivot-template
description: Genera una plantilla Excel vacía desde SELECT con AP_ID_PREGUNTA/AP_PREGUNTA, pivotando preguntas horizontalmente y manteniendo columnas manuales fijas.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: build-excel-pivot-template, path: .opencode/skills/build-excel-pivot-template/SKILL.md}
    source_sha256: 85736604bef71751eb753659ebd77426ac8e79b543e8690dc045daefce79da28
    transformations: [adapt-compatibility, normalize-instructions, relay-inputs-to-main]
    losses: []
    generated_sha256: b6c01d7859f6fc1960212118a4e08a3d6864c54ba9c8bd5670daeaeaa5c9deeb
    synced_at: "2026-10-04T12:27:02Z"
---

# Build Excel Pivot Template

Exclusiva del flujo pivot de `excel-template-builder`.

## Mandatory Gate

Contar con SELECT fuente, `output_dir` y `output_file` terminado en `.xlsx`.
Si falta cualquiera, detener y devolver faltantes al principal para preguntar;
no asumir ni inventar. El SELECT del contrato incluye AP_ID_PREGUNTA y
AP_PREGUNTA. Verificarlo antes de invocar el script y conservar el orden natural.

Usar para crear templates desde SELECT, pivotar preguntas y preparar cabeceras
para carga masiva futura. No para reportes completos, cargas Oracle ni datos de
negocio o consultas sin esas dos columnas.

## Output Structure

- Fila 1: primeras cuatro columnas vacías; desde E, AP_PREGUNTA.
- Fila 2: `N° | COD_FAMILIA | AR_FECHA_REGISTRA | SF_ID_FASE`; desde E,
  AP_ID_PREGUNTA.
- Fila 3+: filas vacías numeradas para digitación manual.
- Una hoja, freeze panes E3 y autoajuste básico.

El script existente `py_notebooks/export_template_to_sigeif_form.py` consulta
Oracle para obtener la definición de preguntas, elimina duplicados por
AP_ID_PREGUNTA conservando la primera aparición y genera la plantilla vacía.
No ejecutar esta consulta fuera del flujo autorizado.

Invocar con el SQL recibido y salida explícita, después del gate y aprobación
técnica de Bash:

```text
python py_notebooks/export_template_to_sigeif_form.py --sql-query <SELECT> --output-dir <output_dir> --output-file <output_file.xlsx>
```

Conservar las cuatro columnas fijas. No agregar JOINs ni lógica de respuestas
cuando solo se pide plantilla; no poblar datos sin instrucción. Los ejemplos de
rutas no sustituyen inputs. No modificar el script de negocio al migrar esta Skill.
