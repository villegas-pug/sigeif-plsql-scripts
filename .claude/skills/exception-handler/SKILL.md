---
name: exception-handler
description: Proporciona manejo de excepciones PL/SQL estándar para unidades Oracle; exclusivo del builder PL/SQL, con adaptación al contrato de la capacidad.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: exception-handler, path: .opencode/skills/exception-handler/SKILL.md}
    source_sha256: ee478171de3c59de878efe9e71667702e51807cd42237166e728cc73fb95c2ad
    transformations: [adapt-compatibility, preserve-capability-precedence]
    losses: []
    generated_sha256: dfb5e276de4d167888357d98f23684b88404aff94cda84de7ac76ac1214e1f2a
    synced_at: "2026-10-04T12:27:02Z"
---

# Exception Handler

Proporciona la estructura estándar de manejo de errores de unidades PL/SQL.
No ejecutar el código ni confundir el ejemplo con una política universal.
El contrato read-only de `build-report-list-sp` prohíbe ROLLBACK y logging DML
y prevalece sobre esas partes del patrón genérico.

## Base Pattern

```sql
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      -- Reemplazar por la acción resuelta, como retornar NULL o un default.
      RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado: ' || SQLERRM);
   WHEN TOO_MANY_ROWS THEN
      -- Reemplazar por la acción resuelta ante más de una fila.
      RAISE_APPLICATION_ERROR(-20002, 'Múltiples registros encontrados: ' || SQLERRM);
   WHEN DUP_VAL_ON_INDEX THEN
      -- Reemplazar por la acción resuelta ante duplicados.
      RAISE_APPLICATION_ERROR(-20003, 'Registro duplicado: ' || SQLERRM);
   WHEN OTHERS THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      -- Logging solo si el contrato lo permite; nunca en reportes read-only.
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,
         'Error en [NOMBRE_PROCEDURE]: ' || v_error_message);
```

Variables en la sección de declaraciones correspondiente:

```sql
v_error_code    NUMBER;
v_error_message VARCHAR2(4000);
```

Excepciones personalizadas, cuando el contrato lo requiera:

```sql
e_registro_invalido EXCEPTION;
PRAGMA EXCEPTION_INIT(e_registro_invalido, -20010);
-- En la lógica, cuando corresponda:
RAISE e_registro_invalido;
-- En EXCEPTION, acción explícitamente resuelta:
WHEN e_registro_invalido THEN
   NULL;
```

Usar para errores consistentes, especialmente en unidades que contienen DML
como artefactos. No ejecutar DML ni transacciones contra Oracle. Siempre
mantener WHEN OTHERS con SQLCODE/SQLERRM donde aplique y resolver la propagación
de errores conforme al contrato; no copiar NULL ni ROLLBACK ciegamente.
