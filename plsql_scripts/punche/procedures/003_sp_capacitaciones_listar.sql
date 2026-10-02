-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR
-- Propósito: Reporte 12 "Organización de la economía familiar —
--            Capacitaciones" del servicio 2 (PUNCHE). Deserializa
--            la pregunta 1614 del Anexo 12 almacenada en
--            SSI_ANEXOS_RESPUESTAS.AR_RESPUESTA y devuelve UNA
--            FILA POR CAPACITACIÓN registrada por cada familia,
--            con filtros opcionales por rango de fecha de registro
--            y por zona de intervención.
-- Parámetros:
--   p_fecha_ini  IN  DATE   DEFAULT NULL — fecha inicial del rango
--                                          (incluida) sobre
--                                          ar.AR_FECHA_REGISTRA.
--                                          Si NULL, no se filtra
--                                          por inicio.
--   p_fecha_fin  IN  DATE   DEFAULT NULL — fecha final del rango
--                                          (incluida, día completo).
--                                          Si NULL, no se filtra
--                                          por fin.
--   p_id_zona    IN  NUMBER DEFAULT -1   — filtro por zona de
--                                          intervención
--                                          (zi.ZO_ID_ZONA). Si -1 o
--                                          NULL, no se filtra
--                                          (todas las zonas).
--   p_cursor_out OUT SYS_REFCURSOR       — cursor con el resultado
--                                          (19 columnas, orden A–S
--                                          de la plantilla).
-- Autor   : OpenCode (procedure-builder)
-- Fecha   : 2026-09-30
-- Alcance : Solo lectura. SELECT sobre SSI_ANEXOS_RESPUESTAS +
--           SSI_ANEXOS_PREGUNTAS + SSI_POTENCIALES_FAMILIAS +
--           SSI_ZONA_INTERVENCION + SSI_CODIGOS_FAMILIAS.
-- =============================================================
-- Notas de implementación:
--   * SP de SOLO LECTURA. No ejecuta DML. No usa COMMIT/ROLLBACK.
--   * SERIALIZACIÓN (pregunta 1614, Anexo 12): cada fila de
--     SSI_ANEXOS_RESPUESTAS con AP_ID_PREGUNTA = 1614 guarda una
--     o más capacitaciones en AR_RESPUESTA. Separador entre
--     capacitaciones: '|'. Separador entre campos de una
--     capacitación: ';'. Al guardar, los ';' y '|' internos de
--     los valores fueron reemplazados por espacios (no aparecen
--     dentro de valores). Orden fijo de 12 campos:
--       1  miembro_capacitado      7  tema_programa
--       2  dni                     8  fecha_inicio
--       3  parentesco              9  fecha_fin
--       4  institucion_capacitadora 10 conclusion
--       5  tipo_institucion        11 certificacion
--       6  linea_capacitacion      12 observaciones
--   * TODAS LAS RESPUESTAS HISTÓRICAS: NO se filtra por el valor
--     más reciente por familia (no ROW_NUMBER por familia). Toda
--     respuesta 1614 activa de cada familia se deserializa por
--     completo. Grano final: una fila por (AR_ID_RESPUESTA,
--     capacitación).
--   * SPLIT por '|' (CONNECT BY correlacionado por fila):
--       CONNECT BY PRIOR base.AR_ID_RESPUESTA = base.AR_ID_RESPUESTA
--              AND PRIOR SYS_GUID() IS NOT NULL
--              AND LEVEL <= REGEXP_COUNT(base.AR_RESPUESTA, '[^|]+')
--     LEVEL = número de capacitación (NRO_CAP). ADVERTENCIA: el
--     patrón '[^|]+' solo genera tokens NO vacíos, por lo que un
--     '|' vacío (capacitación sin contenido) colapsa y no produce
--     fila. Una AR_RESPUESTA NULL/vacía genera una única fila con
--     todos los campos de la capacitación en NULL (el WHERE del
--     contrato no la excluye).
--   * EXTRACCIÓN DE CAMPOS POSICIÓN-SEGURA: cada campo N (1..12)
--     se obtiene con
--       REGEXP_SUBSTR(capacitacion, '(.*?)(;|$)', 1, N, NULL, 1)
--     El patrón lazy preserva campos VACÍOS sin corrimiento de
--     índices (NO se usa '[^;]+', que descartaría los vacíos y
--     desplazaría las posiciones siguientes). El campo 12
--     (observaciones) forma parte del orden serial pero se
--     DESCARTA del cursor (no existe en la plantilla A–S).
--   * REGLA DE NOMBRE (campo 1 viene en una pieza, orden
--     'NOMBRES APE1 APE2'):
--     Extraer primero SOLO el campo 1 de cada capacitación con
--     '(.*?)(;|$)' (ocurrencia 1, subexpresión 1), incluso si vacío.
--       1) Normalizar: colapsar espacios múltiples a uno + TRIM
--          (TRIM(REGEXP_REPLACE(campo1, '\s+', ' '))).
--       2) Última palabra = SEGUNDO_APELLIDO; penúltima palabra =
--          PRIMER_APELLIDO; el resto inicial = NOMBRES.
--          Implementado con INSTR(nom, ' ', -1) (posición del
--          último espacio) e INSTR(nom, ' ', -1, 2) (posición del
--          penúltimo espacio) sobre el nombre normalizado.
--     Casos borde: 1 palabra → toda va a NOMBRES y apellidos
--     NULL; 2 palabras → ambas son apellidos (APE1 = palabra 1,
--     APE2 = palabra 2) y NOMBRES = NULL; nombre vacío → todo
--     NULL.
--   * SEXO y FECHA_NACIMIENTO: la serialización no los incluye; se
--     devuelven como literales NULL (CAST(NULL AS VARCHAR2(1)) y
--     CAST(NULL AS DATE)).
--   * FECHA_INICIO / FECHA_FIN (campos 8 y 9): se devuelven como
--     texto tal cual viene serializado (VARCHAR2). No se aplica
--     TO_DATE: el formato serializado no está especificado y un
--     casteo forzado arriesgaría ORA-01830/01861 sobre datos
--     históricos.
--   * CODIGO_FAMILIA: LEFT JOIN con una vista agregada de
--     SSI_CODIGOS_FAMILIAS (CF_TIPO_CODIGO = 1 = código de
--     familia, CF_ESTADO = 1, CF_ELIMINADO = 0, MAX(CF_CODIGO)
--     GROUP BY PF_ID_FAMILIA). El JOIN se hace SOBRE UNA FILA POR
--     FAMILIA ya agregada para no multiplicar el grano final (una
--     fila por capacitación) si una familia tuviera varios códigos
--     activos. Es LEFT para no excluir familias sin código activo
--     (devuelven NULL, igual que la subconsulta escalar original).
--     No se usa pf.PF_COD_FAMILIA.
--   * Filtros de fecha (rango medio-abierto, estrategia OR-NULL)
--     sobre ar.AR_FECHA_REGISTRA:
--       ar.AR_FECHA_REGISTRA >= p_fecha_ini
--       AND ar.AR_FECHA_REGISTRA <  p_fecha_fin + 1
--     Si ambos parámetros son NULL no se aplica ningún filtro. Si
--     p_fecha_ini > p_fecha_fin el resultado queda vacío (sin
--     error).
--   * Filtro por zona: p_id_zona = -1 (default) o NULL = todas las
--     zonas del servicio 2; cualquier otro valor filtra
--     zi.ZO_ID_ZONA. Sin validación EXISTS: un ID inexistente
--     devuelve cero filas (sin error).
--   * Defensa de servicio (mismo patrón que SP 002):
--       (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
--   * RENDIMIENTO: SSI_ANEXOS_RESPUESTAS es candidata a FULL
--     TABLE SCAN (filtro por AP_ID_PREGUNTA / AR_ELIMINADO sin
--     índice compuesto garantizado por el contrato). El CONNECT BY
--     con REGEXP evaluado por fila multiplica el costo por el
--     número de capacitaciones por respuesta. El wrapper
--     SELECT ROWNUM ordena el resultado completo antes de
--     numerarlo (NRO).
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR (
   p_fecha_ini  IN  DATE     DEFAULT NULL,
   p_fecha_fin  IN  DATE     DEFAULT NULL,
   p_id_zona    IN  NUMBER   DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      SELECT
         ROWNUM                                     AS NRO,
         sub.COD_ZON,
         sub.ZONA_INTERVENCION,
         sub.CODIGO_FAMILIA,
         sub.PRIMER_APELLIDO,
         sub.SEGUNDO_APELLIDO,
         sub.NOMBRES,
         sub.PARENTESCO,
         sub.DNI,
         sub.SEXO,
         sub.FECHA_NACIMIENTO,
         sub.INSTITUCION_CAPACITADORA,
         sub.TIPO_INSTITUCION,
         sub.LINEA_CAPACITACION,
         sub.TEMA_PROGRAMA,
         sub.FECHA_INICIO,
         sub.FECHA_FIN,
         sub.CONCLUSION,
         sub.CERTIFICACION
      FROM (
         SELECT
             des.ZO_ID_ZONA                             AS COD_ZON,
             des.ZO_DESCRIPCION                         AS ZONA_INTERVENCION,
             cf.CF_CODIGO                               AS CODIGO_FAMILIA,

            /* PRIMER_APELLIDO = penúltima palabra del campo 1 */
            CASE
               WHEN INSTR(des.NOM_NORMALIZADO, ' ', -1) = 0
                  THEN NULL
               WHEN INSTR(des.NOM_NORMALIZADO, ' ', -1, 2) = 0
                  THEN SUBSTR(
                         des.NOM_NORMALIZADO,
                         1,
                         INSTR(des.NOM_NORMALIZADO, ' ', -1) - 1
                      )
               ELSE SUBSTR(
                      des.NOM_NORMALIZADO,
                      INSTR(des.NOM_NORMALIZADO, ' ', -1, 2) + 1,
                      INSTR(des.NOM_NORMALIZADO, ' ', -1)
                         - INSTR(des.NOM_NORMALIZADO, ' ', -1, 2) - 1
                   )
            END                                         AS PRIMER_APELLIDO,

            /* SEGUNDO_APELLIDO = última palabra del campo 1 */
            CASE
               WHEN INSTR(des.NOM_NORMALIZADO, ' ', -1) = 0
                  THEN NULL
               ELSE SUBSTR(
                      des.NOM_NORMALIZADO,
                      INSTR(des.NOM_NORMALIZADO, ' ', -1) + 1
                   )
            END                                         AS SEGUNDO_APELLIDO,

            /* NOMBRES = resto inicial del campo 1 */
            CASE
               WHEN INSTR(des.NOM_NORMALIZADO, ' ', -1) = 0
                  THEN des.NOM_NORMALIZADO
               WHEN INSTR(des.NOM_NORMALIZADO, ' ', -1, 2) = 0
                  THEN NULL
               ELSE SUBSTR(
                      des.NOM_NORMALIZADO,
                      1,
                      INSTR(des.NOM_NORMALIZADO, ' ', -1, 2) - 1
                   )
            END                                         AS NOMBRES,

            /* Campo 3: parentesco */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 3, NULL, 1)
                                                        AS PARENTESCO,
            /* Campo 2: dni */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 2, NULL, 1)
                                                        AS DNI,
            /* La serialización no incluye sexo ni fecha de nacimiento */
            CAST(NULL AS VARCHAR2(1))                   AS SEXO,
            CAST(NULL AS DATE)                          AS FECHA_NACIMIENTO,
            /* Campo 4: institución capacitadora */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 4, NULL, 1)
                                                        AS INSTITUCION_CAPACITADORA,
            /* Campo 5: tipo de institución */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 5, NULL, 1)
                                                        AS TIPO_INSTITUCION,
            /* Campo 6: línea de capacitación */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 6, NULL, 1)
                                                        AS LINEA_CAPACITACION,
            /* Campo 7: tema / programa */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 7, NULL, 1)
                                                        AS TEMA_PROGRAMA,
            /* Campo 8: fecha de inicio (texto serializado) */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 8, NULL, 1)
                                                        AS FECHA_INICIO,
            /* Campo 9: fecha de fin (texto serializado) */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 9, NULL, 1)
                                                        AS FECHA_FIN,
            /* Campo 10: conclusión */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 10, NULL, 1)
                                                        AS CONCLUSION,
            /* Campo 11: certificación */
            REGEXP_SUBSTR(des.CAPACITACION, '(.*?)(;|$)', 1, 11, NULL, 1)
                                                        AS CERTIFICACION
            /* Campo 12 (observaciones): parseado en el orden serial,
               descartado por decisión de diseño. */
         FROM (
            /* des: deserialización (split por '|') + normalización
               del nombre del campo 1. */
            SELECT
               base.ZO_ID_ZONA,
               base.ZO_DESCRIPCION,
               base.PF_ID_FAMILIA,
               base.AR_FECHA_REGISTRA,
               LEVEL                                      AS NRO_CAP,
               REGEXP_SUBSTR(
                  base.AR_RESPUESTA,
                  '[^|]+',
                  1,
                  LEVEL
               )                                           AS CAPACITACION,
               TRIM(
                  REGEXP_REPLACE(
                     REGEXP_SUBSTR(
                        REGEXP_SUBSTR(
                           base.AR_RESPUESTA,
                           '[^|]+',
                           1,
                           LEVEL
                        ),
                        '(.*?)(;|$)',
                        1,
                        1,
                        NULL,
                        1
                     ),
                     '\s+',
                     ' '
                  )
               )                                           AS NOM_NORMALIZADO
            FROM (
               /* base: respuestas 1614 activas con familia/zona
                  filtradas. */
               SELECT
                  ar.AR_ID_RESPUESTA,
                  ar.PF_ID_FAMILIA,
                  ar.AR_RESPUESTA,
                  ar.AR_FECHA_REGISTRA,
                  zi.ZO_ID_ZONA,
                  zi.ZO_DESCRIPCION
               FROM SSI_ANEXOS_RESPUESTAS ar
               JOIN SSI_ANEXOS_PREGUNTAS ap
                  ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
               JOIN SSI_POTENCIALES_FAMILIAS pf
                  ON pf.PF_ID_FAMILIA = ar.PF_ID_FAMILIA
               JOIN SSI_ZONA_INTERVENCION zi
                  ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               WHERE
                  ap.SI_ID_SERVICIO  = 2                    -- PUNCHE
                  AND ap.AP_NUM_ANEXO    = 12               -- Anexo 12
                  AND ap.AP_ID_PREGUNTA  = 1614             -- Capacitaciones
                  AND NVL(ap.AP_ELIMINADO, 0) = 0
                  AND ar.AR_ELIMINADO    = 0
                  AND ar.PF_ID_FAMILIA  IS NOT NULL
                  AND (pf.SI_ID_SERVICIO = 2
                       OR zi.SI_ID_SERVICIO = 2)           -- Defensa
                  AND pf.PF_ESTADO       = 1
                  AND pf.PF_ELIMINADO    = 0
                  AND zi.ZO_ESTADO       = 1
                  -- Filtros opcionales por rango de fecha
                  -- (medio-abierto). Si ambos son NULL no se aplica
                  -- ningún filtro.
                  AND (p_fecha_ini IS NULL
                       OR ar.AR_FECHA_REGISTRA >= p_fecha_ini)
                  AND (p_fecha_fin IS NULL
                       OR ar.AR_FECHA_REGISTRA <  p_fecha_fin + 1)
                  -- Filtro opcional por zona.
                  -- p_id_zona = -1 (default) o NULL => todas.
                  AND (p_id_zona IS NULL
                       OR p_id_zona = -1
                       OR zi.ZO_ID_ZONA = p_id_zona)
            ) base
            CONNECT BY PRIOR base.AR_ID_RESPUESTA = base.AR_ID_RESPUESTA
                   AND PRIOR SYS_GUID() IS NOT NULL
                   AND LEVEL <= REGEXP_COUNT(base.AR_RESPUESTA, '[^|]+')
          ) des
          /* Código de familia: una fila por familia (agregado) para
             no multiplicar el grano del reporte. */
          LEFT JOIN (
             SELECT
                cf.PF_ID_FAMILIA,
                MAX(cf.CF_CODIGO) AS CF_CODIGO
             FROM SSI_CODIGOS_FAMILIAS cf
             WHERE cf.CF_TIPO_CODIGO = 1                 -- Código de familia
                AND cf.CF_ESTADO      = 1
                AND cf.CF_ELIMINADO   = 0
             GROUP BY cf.PF_ID_FAMILIA
          ) cf
             ON cf.PF_ID_FAMILIA = des.PF_ID_FAMILIA
          ORDER BY
             des.ZO_ID_ZONA        ASC,
             des.PF_ID_FAMILIA     ASC,
             des.AR_FECHA_REGISTRA ASC,
             des.NRO_CAP           ASC
       ) sub;

EXCEPTION
   WHEN OTHERS THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      RAISE_APPLICATION_ERROR(
         -20999,
         'Error en PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR: '
            || v_error_message
      );
END PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR;
/

--! COMMIT;

-- =============================================================
-- Bloque de invocación / prueba
-- Nota: se usa SIEMPRE notación nombrada (=>) porque el primer
-- parámetro formal es p_fecha_ini (DATE); pasar el cursor en
-- primer lugar por posición enlazaría el SYS_REFCURSOR a un DATE
-- y provocaría PLS-00306.
-- =============================================================
-- Caso 1: sin filtros (todas las capacitaciones históricas)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR(
      p_cursor_out => c_resultado_busqueda
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 2: solo fecha de inicio
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR(
      p_fecha_ini  => DATE '2026-01-01',
      p_fecha_fin  => NULL,
      p_cursor_out => c_resultado_busqueda
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 3: solo fecha de fin (incluye el día completo)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR(
      p_fecha_ini  => NULL,
      p_fecha_fin  => DATE '2026-07-20',
      p_cursor_out => c_resultado_busqueda
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 4: rango cerrado (medio-abierto)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR(
      p_fecha_ini  => DATE '2026-07-01',
      p_fecha_fin  => DATE '2026-07-20',
      p_cursor_out => c_resultado_busqueda
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- =============================================================
-- Bloque auxiliar: zonas disponibles del servicio 2
-- (ejecutar antes de los casos 5/6/7 para elegir un ID)
-- =============================================================
SELECT
   zi.ZO_ID_ZONA,
   zi.ZO_DESCRIPCION,
   zi.SI_ID_SERVICIO,
   zi.ZO_ESTADO,
   zi.ZO_ELIMINADO
FROM SSI_ZONA_INTERVENCION zi
WHERE zi.SI_ID_SERVICIO = 2
   AND zi.ZO_ESTADO      = 1
   AND zi.ZO_ELIMINADO   = 0
ORDER BY zi.ZO_ID_ZONA
/

-- Caso 5: p_id_zona = -1 (todas las zonas, explicito)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR(
      p_fecha_ini  => NULL,
      p_fecha_fin  => NULL,
      p_id_zona    => -1,
      p_cursor_out => c_resultado_busqueda
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 6: p_id_zona con un ID especifico del servicio 2
-- (REEMPLAZAR el ID 999 con un ZO_ID_ZONA valido del servicio 2)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR(
      p_fecha_ini  => DATE '2026-08-10',
      p_fecha_fin  => DATE '2026-08-15',
      p_id_zona    => -1, /* REEMPLAZAR con un ZO_ID_ZONA valido del servicio 2 */
      p_cursor_out => c_resultado_busqueda
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 7: p_id_zona = NULL (equivalente a todas las zonas)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_CAPACITACIONES_FAMILIAS_LISTAR(
      p_fecha_ini  => NULL,
      p_fecha_fin  => NULL,
      p_id_zona    => NULL,
      p_cursor_out => c_resultado_busqueda
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

--! COMMIT;
