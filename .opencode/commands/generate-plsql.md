---
description: Genera SQL/PLSQL Oracle SIGEIF basado en el schema del proyecto
subtask: false
---

Antes de hacer cualquier cosa verifica los siguientes parametros en orden. No
avances al siguiente hasta tener confirmado el anterior.

PASO 1 - Si $ARGUMENTS esta vacio pregunta:
   "Indica el contexto inicial: objetivo funcional, tipo de script requerido (DML, DDL, limpieza, validacion, seed, procedure, function, trigger o bloque anonimo), tablas o dominio involucrado, criterio principal de filtrado y archivo destino si aplica."
   Espera la respuesta. No continues.

PASO 2 - Si el pedido implica crear, definir o modificar tablas y no incluye
prefijo de tabla o prefijo de campos, pregunta:
   "Para definir tablas necesito el prefijo de tabla (ej: SSI) y el prefijo de campos (ej: PF, AR, ZO). Indicalos para continuar."
   Espera la respuesta. No continues.

Solo cuando tengas el contexto obligatorio confirmado, ejecuta:

1. Usa la skill `generate-plsql`.
2. Lee `plsql_scripts/oracle_schema_tables_catalog.md` antes de generar SQL o PL/SQL.
3. Identifica tablas candidatas, columnas exactas, PK, FK, constraints, secuencias y relaciones directas o indirectas.
4. Genera SQL/PLSQL Oracle para: $ARGUMENTS.
5. Respeta las convenciones de nombres, prefijos, indentacion de 3 espacios y separador `/` del proyecto.
6. Si el script es destructivo, genera o propone `SELECT COUNT(*)` previo y deja `COMMIT` comentado salvo pedido explicito.
7. Si el filtro es por servicio, usa el campo real definido en el schema, por ejemplo `SI_ID_SERVICIO`, `SF_ID_SERVICIO` o la relacion padre correspondiente.
