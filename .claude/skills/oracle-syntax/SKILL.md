---
name: oracle-syntax
description: Verifica sintaxis Oracle nativa, alias, nomenclatura y formato de SQL/PLSQL; usar en generación o revisión por los especialistas autorizados.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: oracle-syntax, path: .opencode/skills/oracle-syntax/SKILL.md}
    source_sha256: 5bd88994622c0bdfce4f1cb629a5825212760426b05b67b03d0dfc5ac79c87e7
    transformations: [adapt-compatibility, normalize-instructions]
    losses: []
    generated_sha256: 71fb8462134f54b77e95ffb958de79cab7211a98dd0062e69148af28f72a022d
    synced_at: "2026-10-04T12:27:02Z"
---

# Oracle Syntax

Garantiza compatibilidad exclusiva con Oracle en SQL/PLSQL generado o revisado.
Aplica los hechos del catálogo y las reglas del proyecto antes de estos ejemplos.
No conecta, ejecuta ni compila Oracle.

## Native Syntax

- Nulos: `NVL`, `NVL2`; `COALESCE` cuando haya más de dos alternativas.
  No usar ISNULL ni IFNULL.
- Filas: `ROWNUM <= n` en 11g/anterior; `FETCH FIRST n ROWS ONLY` en 12c+.
  Nunca LIMIT ni TOP.
- Fechas: SYSDATE, TRUNC, ADD_MONTHS, MONTHS_BETWEEN, LAST_DAY, TO_DATE y
  TO_CHAR. Conservar la regla del origen: no NOW/GETDATE, ni CURRENT_TIMESTAMP
  sin TO_CHAR en los patrones de esta Skill.
- Conversiones: TO_NUMBER, TO_CHAR, TO_DATE con máscara; CAST solo si no hay
  equivalente Oracle adecuado en el patrón del proyecto.
- Concatenar con `||`; evitar CONCAT cuando haya más de dos operandos.
- Condiciones: DECODE simple y CASE complejo. DUAL para consultas sin tabla.
- Jerarquías: START WITH / CONNECT BY PRIOR.

## Aliases

Tabla: abreviatura explícita de las letras significativas, minúscula y máximo
cuatro caracteres; sin AS. No una sola letra salvo autouniones. En consultas
multitabla, toda columna lleva alias, sin excepción.

Alias calculados o de desambiguación: snake_case en mayúsculas, sin comillas
dobles salvo espacios o caracteres especiales. Ejemplos: clientes `cl`, pedidos
`pe`, detalle `de`, productos `pr`, facturas `fa`, empleados `em`.

## Naming

| Objeto | Patrón |
|---|---|
| Tabla | TABLA_NOMBRE, sujeto a nombres del catálogo |
| Vista | VW_NOMBRE_DESCRIPTIVO |
| Procedure | PRC_TABLA_ACCION |
| Función | FNC_NOMBRE_RESULTADO |
| Trigger | TRG_TABLA_EVENTO |
| Secuencia | SEQ_TABLA, solo confirmada o definida por contrato DDL |
| Índice / unique | IDX_TABLA_COLUMNA / UDX_TABLA_COLUMNA |
| Package / sinónimo | PKG_DOMINIO / SYN_NOMBRE_OBJETO |

Eventos trigger: BEFORE/AFTER + INSERT/UPDATE/DELETE. No crear objetos ni
secuencias por el solo hecho de tener una convención.

Variables: `v_`, parámetros `p_`, cursores `cur_`, registros `rec_`, constantes
`c_`, excepciones `e_`, tipos `t_`, contadores `i_`. Referencias al schema con
%TYPE/%ROWTYPE; no usar nombres de columna sin prefijo. Parámetros OUT con
sufijo `_out` cuando corresponda a la firma.

## Format

Tres espacios de indentación, palabras clave y objetos en mayúsculas, variables
y alias en minúsculas. Una columna por línea cuando SELECT tenga más de tres;
alinear AS de alias cuando existan varios. IS/AS en unidades y DECLARE en bloques.

Header obligatorio: tipo, nombre, propósito, parámetros, autor y fecha. No
inventar autor ni presentar ejemplos como objetos del catálogo. Mantener el
encabezado y las excepciones del contrato específico.
