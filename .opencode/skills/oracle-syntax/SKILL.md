---
name: oracle-syntax
description: Garantiza el uso de sintaxis Oracle nativa, convenciones de alias, nomenclatura de objetos y estilo de código PL/SQL en todo el SQL generado del proyecto
compatibility: opencode
---

## Qué hago

Cuando soy invocado, verifico y corrijo el SQL y PL/SQL generado para
garantizar compatibilidad exclusiva con Oracle Database y consistencia
con las convenciones del proyecto.

---

## 1. Sintaxis Oracle Obligatoria

### Funciones de nulo
- Usar `NVL(expr, valor)`          — NO usar ISNULL ni IFNULL
- Usar `NVL2(expr, notnull, null)` — para lógica condicional de nulo
- Usar `COALESCE` solo cuando haya más de 2 alternativas

### Limitación de filas
- Usar `WHERE ROWNUM <= n`              (Oracle 11g o anterior)
- Usar `FETCH FIRST n ROWS ONLY`        (Oracle 12c en adelante)
- NUNCA usar `LIMIT n` ni `TOP n`

### Fechas y tiempo
- `SYSDATE`                   — fecha y hora actual del servidor
- `TRUNC(fecha)`               — truncar a inicio del día
- `TRUNC(fecha, 'MM')`         — truncar a inicio del mes
- `ADD_MONTHS(fecha, n)`       — sumar/restar meses
- `MONTHS_BETWEEN(f1, f2)`     — diferencia en meses
- `LAST_DAY(fecha)`            — último día del mes
- `TO_DATE('valor', 'formato')` — convertir texto a fecha
- `TO_CHAR(fecha, 'formato')`  — convertir fecha a texto
- NUNCA usar NOW(), GETDATE(), CURRENT_TIMESTAMP sin TO_CHAR

### Conversiones
- `TO_NUMBER(expr)`            — convertir a número
- `TO_CHAR(expr)`              — convertir a texto
- `TO_DATE(expr, fmt)`         — convertir a fecha
- Usar CAST solo cuando no exista función Oracle equivalente

### Concatenación
- Usar el operador `||`
- Evitar CONCAT() cuando haya más de 2 operandos

### Condicionales
- `DECODE(expr, v1, r1, v2, r2, default)` — casos simples
- `CASE WHEN ... THEN ... ELSE ... END`   — lógica compleja

### Tabla de prueba
- Siempre usar `FROM DUAL` para consultas sin tabla real

### Consultas jerárquicas
- Usar `START WITH ... CONNECT BY PRIOR`

---

## 2. Convenciones de Alias de Tabla

Usar las primeras letras significativas del nombre de la tabla,
siempre en minúsculas. El alias va después del nombre de tabla sin AS.

Formato: iniciales o abreviatura corta, máximo 4 caracteres.

Ejemplos de patrón:
- TABLA_CLIENTES          → cl
- TABLA_PEDIDOS           → pe
- TABLA_DETALLE_PEDIDO    → de
- TABLA_PRODUCTOS         → pr
- TABLA_FACTURAS          → fa
- TABLA_EMPLEADOS         → em

Reglas:
- Alias obligatorio en TODA columna de consultas con más de una tabla
- Formato: `alias.NOMBRE_COLUMNA` sin excepción
- Nunca usar alias de una sola letra (a, b, c) salvo autouniones

---

## 3. Convenciones de Alias de Columna (SELECT)

- Siempre para claridad o desambiguar
- Formato: snake_case en mayúsculas
- Usar sin comillas dobles salvo que contenga espacios o caracteres especiales

---

## 4. Convenciones de Nomenclatura de Objetos Oracle

### Objetos de base de datos
| Tipo        | Patrón                    | Ejemplo                        |
|-------------|---------------------------|--------------------------------|
| Tabla       | TABLA_NOMBRE              | TABLA_CLIENTES                 |
| Vista       | VW_NOMBRE_DESCRIPTIVO     | VW_PEDIDOS_ACTIVOS             |
| Procedure   | PRC_TABLA_ACCION          | PRC_CLIENTES_INSERTAR          |
| Función     | FNC_NOMBRE_RESULTADO      | FNC_PEDIDO_CALCULAR_TOTAL      |
| Trigger     | TRG_TABLA_EVENTO          | TRG_CLIENTES_BEFORE_INSERT     |
| Secuencia   | SEQ_TABLA                 | SEQ_CLIENTES                   |
| Índice      | IDX_TABLA_COLUMNA         | IDX_PEDIDOS_FECHA_CREACION     |
| Índice único| UDX_TABLA_COLUMNA         | UDX_CLIENTES_EMAIL             |
| Paquete     | PKG_DOMINIO               | PKG_FACTURACION                |
| Sinónimo    | SYN_NOMBRE_OBJETO         | SYN_CLIENTES                   |

### Eventos de Trigger
- `BEFORE_INSERT`
- `BEFORE_UPDATE`
- `BEFORE_DELETE`
- `AFTER_INSERT`
- `AFTER_UPDATE`
- `AFTER_DELETE`

---

## 5. Convenciones de Variables PL/SQL

| Tipo                | Prefijo  | Ejemplo                      |
|---------------------|----------|------------------------------|
| Variable local      | v_       | v_total_pedido               |
| Parámetro entrada   | p_       | p_cliente_id                 |
| Parámetro salida    | p_       | p_resultado_out              |
| Cursor              | cur_     | cur_pedidos_activos          |
| Registro (%ROWTYPE) | rec_     | rec_cliente                  |
| Constante           | c_       | c_iva_porcentaje             |
| Excepción propia    | e_       | e_cliente_invalido           |
| Tipo personalizado  | t_       | t_lista_ids                  |
| Contador/índice     | i_       | i_contador                   |

Reglas adicionales:
- Siempre tipar con `%TYPE` o `%ROWTYPE` cuando referencie el schema
- NUNCA declarar variables con el mismo nombre que una columna sin prefijo
- Parámetros OUT llevan sufijo `_out` para distinguirlos visualmente

```sql
-- Correcto
v_cliente_nombre  TABLA_CLIENTES.nombre%TYPE;
rec_pedido        TABLA_PEDIDOS%ROWTYPE;
p_cliente_id   IN TABLA_CLIENTES.id%TYPE;
p_total_out   OUT NUMBER;

-- Incorrecto
nombre   VARCHAR2(100);
pedido   TABLA_PEDIDOS%ROWTYPE;
```

---

## 6. Estilo de Formato PL/SQL

- Indentación: 3 espacios
- Palabras clave Oracle en MAYÚSCULAS: SELECT, FROM, WHERE, BEGIN, END, etc.
- Nombres de objetos del schema en MAYÚSCULAS: TABLA_CLIENTES, SEQ_CLIENTES
- Variables y alias en minúsculas: v_total, cli, ped
- Una columna por línea en SELECT con más de 3 columnas
- Alinear el `AS` de los alias en columna cuando haya varios

### Encabezado obligatorio en todo objeto

```sql
-- =============================================================
-- Tipo   : [ PROCEDURE | FUNCTION | TRIGGER | PACKAGE ]
-- Nombre : [ NOMBRE_DEL_OBJETO ]
-- Propósito: [ descripción breve ]
-- Parámetros:
--   p_param1 IN  tipo  — descripción
--   p_param2 OUT tipo  — descripción
-- Autor  : [ REEMPLAZAR: nombre del autor ]
-- Fecha  : [ REEMPLAZAR: fecha de creación ]
-- =============================================================
```

---

## Cuándo usarme

Úsame siempre que se genere o revise SQL/PL/SQL para:
- Validar que la sintaxis sea 100% Oracle compatible
- Verificar que los alias de tabla sigan el mapeo del proyecto
- Confirmar que variables y objetos usen los prefijos correctos
- Revisar que el encabezado y formato del objeto sea consistente