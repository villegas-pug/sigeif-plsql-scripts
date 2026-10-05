---
name: generate-plsql
description: Genera scripts Oracle DML, DDL, limpieza y migración del proyecto SIGEIF; no usar para SELECT general, análisis de validación ni unidades PL/SQL.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: generate-plsql, path: .opencode/skills/generate-plsql/SKILL.md}
    source_sha256: 8fecea40c0969c28fe8e9f95d8cb76b38ea77e417f0d17cdaa8992de75c41506
    transformations: [adapt-compatibility, normalize-instructions, relay-inputs-to-main]
    losses: []
    generated_sha256: ddf2117551f1f1a1c1621535472aef29c453535c84aa31e7a7f978c16d7d21e2
    synced_at: "2026-10-04T12:27:02Z"
---

# Generate Oracle Scripts

Exclusiva de `oracle-script-builder`. Genera artefactos DML, DDL, limpieza y
migración; no SELECT general, performance, integridad, procedures, funciones,
triggers, packages o bloques PL/SQL. Nunca ejecuta Oracle.

## Context Gate

Requiere objetivo funcional, tipo (DML/DDL/limpieza/migración), tablas o dominio
o entidades, filtro principal cuando aplique y archivo destino si se pide
insertar o modificar un `.sql`. Sin contexto suficiente, detener y devolver
faltantes al principal; no inferir ni generar código parcial.

Para crear/definir/modificar tablas exige prefijo de tabla, prefijo de campos,
nombre funcional, campos y significado o descripción suficiente, PK esperada y
relaciones cuando existan. Los prefijos faltantes bloquean: no inventar nombres.

## Schema Gate

Leer `plsql_scripts/oracle_schema_tables_catalog.md` antes de generar. Verificar
tablas candidatas, columnas, tipos, PK/FK/constraints/secuencias, relaciones
directas/indirectas y nombre real del filtro. No asumir una columna `servicio`:
resolver SI_ID_SERVICIO/SF_ID_SERVICIO o la relación padre con evidencia.

## Conventions

- Tablas mayúsculas y prefijos confirmados, usualmente SSI_; campos con prefijo.
- PK `<PREFIJO>_ID_<ENTIDAD>` y secuencias `SEQ_<NOMBRE>` o convención confirmada.
- FKs `FK_<TABLA>_<REFERENCIA>` o `FK_SSI_<TABLA>_<N>` según precedentes.
- Tres espacios, keywords mayúsculas, alias cortos minúsculos en multitabla.
- `/` como separador Oracle cuando corresponda; SYSDATE para defaults de fecha.
- Estados NUMBER(1) DEFAULT 1; eliminación NUMBER(1) DEFAULT 0 y CHECK 0/1
  únicamente cuando correspondan al diseño acordado.
- Auditoría según prefijo: USU_REGISTRA, FEC_REGISTRA/FECHA_REGISTRA,
  USU_ACTUALIZA/USU_MODIFICA, FEC_ACTUALIZA/FEC_MODIFICA, USUARIO_ELIMINA,
  FECHA_ELIMINA, ESTADO y ELIMINADO, respetando columnas reales.

## DML and Cleanup

Usar Oracle nativo, nunca LIMIT/TOP/ISNULL/GETDATE; alias en JOINs/subconsultas,
EXISTS cuando sea más seguro que IN y binds para valores recibidos. No activar
COMMIT salvo petición. Proponer/generar SELECT COUNT previo a DML destructivo.
Resolver filtros de servicio reales, incluyendo relaciones padre.

Para DELETE: candidatas, hijas/padres por FK y orden hijos→padres; incluir las
dependencias necesarias aunque no se hayan nombrado. No TRUNCATE si existe
filtro funcional; no borrar maestros/catálogos sin petición explícita. Separar
DELETE con `/` cuando se entregue como script.

Un filtro indirecto usa EXISTS correlacionado al padre con el servicio real;
no copiar IDs ilustrativos ni relaciones no verificadas.

## DDL

Tipos Oracle NUMBER/VARCHAR2/CHAR/DATE/TIMESTAMP/BLOB; PK explícita. Definir
secuencia o identidad solo según diseño autorizado y convención del catálogo;
no afirmar una secuencia existente sin evidencia. Defaults NEXTVAL únicamente
cuando corresponda al objeto confirmado/definido. CHECK para flags pertinentes.
FK solo a tablas/columnas existentes; advertir si no está documentada su PK.

## Delivery and Checklist

Entregar artefacto con comentarios breves, COMMIT comentado y advertencias que
afectan integridad/ejecución. No afirmar que fue ejecutado ni compilado.
Verificar contexto, prefijos, lectura de catálogo, nombres, filtro real, orden
FK, sintaxis y ausencia de COMMIT activo no solicitado. No modificar archivos
protegidos como AGENTS.md; el builder escribe solo `.sql` autorizados.

Puede proponer modo seguro con SAVEPOINT y DELETE como artefactos, ROLLBACK y
COMMIT comentados, inserción en archivo existente y evaluación de índices FK o
filtros. No crear índices automáticamente sin petición. No ejecutar esas propuestas.
