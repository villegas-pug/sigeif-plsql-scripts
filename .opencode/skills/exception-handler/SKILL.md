---
name: exception-handler
description: Genera bloques de manejo de excepciones PL/SQL Oracle estándar para procedures, funciones y bloques anónimos según las convenciones del proyecto
compatibility: opencode
---

## Qué hago

Proporciono la estructura estándar de manejo de errores PL/SQL para
todos los objetos generados en el proyecto.

## Estructura base que genero

```sql
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      -- [ REEMPLAZAR: acción cuando no hay datos, ej: retornar NULL o valor default ]
      RAISE_APPLICATION_ERROR(-20001, 'Registro no encontrado: ' || SQLERRM);

   WHEN TOO_MANY_ROWS THEN
      -- [ REEMPLAZAR: acción cuando el SELECT retorna más de una fila ]
      RAISE_APPLICATION_ERROR(-20002, 'Múltiples registros encontrados: ' || SQLERRM);

   WHEN DUP_VAL_ON_INDEX THEN
      -- [ REEMPLAZAR: acción ante violación de clave única ]
      RAISE_APPLICATION_ERROR(-20003, 'Registro duplicado: ' || SQLERRM);

   WHEN OTHERS THEN
      -- Captura general — siempre presente
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      -- [ REEMPLAZAR: lógica de logging, ej: INSERT en tabla de errores ]
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,
         'Error en [NOMBRE_PROCEDURE]: ' || v_error_message);
```

## Variables de error requeridas en DECLARE

```sql
v_error_code    NUMBER;
v_error_message VARCHAR2(4000);
```

## Excepciones personalizadas comunes

```sql
-- Definir en la sección DECLARE:
e_registro_invalido EXCEPTION;
PRAGMA EXCEPTION_INIT(e_registro_invalido, -20010);

-- Lanzar:
RAISE e_registro_invalido;

-- Capturar:
WHEN e_registro_invalido THEN
   -- [ REEMPLAZAR: acción específica ]
   NULL;
```

## Cuándo usarme

Úsame cada vez que se genere un bloque PL/SQL para garantizar que
incluya manejo de errores consistente con el estándar del proyecto.
Especialmente importante en procedures que hacen DML (INSERT, UPDATE, DELETE).