-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR
-- Propósito: Retorna el listado de TALLERES PROGRAMADOS en el
--            servicio PUNCHE (SI_ID_SERVICIO = 2), con filtros
--            opcionales por rango de fecha y por zona de
--            intervencion. Una fila por combinación (zona +
--            familia + cuidador + taller programado).
-- Parámetros:
--   p_cursor_out OUT SYS_REFCURSOR       — cursor con el resultado.
--   p_fecha_ini  IN  DATE DEFAULT NULL   — fecha inicial del rango
--                                          (incluida). Si NULL, no
--                                          se filtra por inicio.
--   p_fecha_fin  IN  DATE DEFAULT NULL   — fecha final del rango
--                                          (incluida, día completo).
--                                          Si NULL, no se filtra
--                                          por fin.
--   p_id_zona   IN  NUMBER DEFAULT -1   — filtro por zona de intervencion
--                                          (zi.ZO_ID_ZONA). Si -1 o NULL,
--                                          no se filtra (todas las zonas
--                                          del servicio 2).
-- Autor   : OpenCode (procedure-builder)
-- Fecha   : 2026-08-19
-- Alcance : Solo lectura. SELECT sobre SSI_PROG_TALLERES +
--          catalogos y joins descritos abajo.
-- =============================================================
-- Notas de implementación:
--   * SP de SOLO LECTURA. No ejecuta DML. No usa COMMIT/ROLLBACK.
--   * Granularidad: una fila por TALLER PROGRAMADO + FAMILIA ASISTENTE
--     (una combinación pt + ptf). La familia se une con el cuidador
--     (fi.FI_CUIDADOR = 1) para obtener los datos del cuidador.
--   * Se listan TODAS las familias registradas en
--     SSI_PROG_TALLER_FAMILIAS (no se filtra por PD_ASISTIO).
--   * Campo 15 (PROFESIONAL_DESARROLLO_TALLER): parsea
--     PT_RESPONSABLES_DICTADO (formato 'id; nombre | id; nombre')
--     y concatena los nombres resultantes separados por ', '.
--     (Se quitó la etiqueta (ALIADO)/(EQUIPO) que antes se
--     anteponía según PT_TIPO_RESPONSABLE_DICTADO.)
--   * Campo 20 (TOTAL_PARTICIPANTES): cantidad de IDs en
--     PD_INTEGRANTES_ASISTIERON (split por '|') + 1 (cuidador).
--   * Campo 21 (PARENTESCO_PARTICIPANTES): en
--     PD_INTEGRANTES_ASISTIERON SOLO se registran NNA (por
--     convención del usuario, el cuidador NUNCA está en este
--     campo), por lo que se concatenan dos piezas:
--       1) Parentesco del CUIDADOR (fi.FI_CUIDADOR = 1) con
--          sufijo ' [C]' (ej: 'MADRE [C]'). Si el cuidador
--          no tiene parentesco en catálogo, se muestra
--          'NO REGISTRA [C]'. Esta pieza va SIEMPRE AL INICIO.
--       2) LISTAGG de parentescos de los NNA asistentes
--          (separados por ', '), solo si
--          PD_INTEGRANTES_ASISTIERON no es NULL/vacío.
--     Esto evita duplicación cuando el parentesco del
--     cuidador coincide con el de un NNA. Si la subconsulta
--     del cuidador retorna NULL y la lista de NNA está
--     vacía, el NVL final retorna 'NO REGISTRA'. Cada
--     elemento se protege con NVL para evitar NULLs en
--     mitad de la cadena.
--   * Columnas de catálogo: se usa DESCRIPCION (no NOMBRE) para
--     los campos OBJETIVO, MÓDULO, UNIDAD, SESIÓN y TALLER.
--   * Alias con comillas dobles: preserva acentos exactos del
--     encabezado (MÓDULO, SESIÓN, FECHA_TALLER, HORA_TÉRMINO).
--   * Filtros de fecha (rango medio-abierto):
--       pt.PT_FEC_HORA_INI >= p_fecha_ini
--       AND pt.PT_FEC_HORA_INI <  p_fecha_fin + 1
--     Estrategia OR-NULL: si ambos parámetros son NULL, no se
--     aplica ningún filtro (devuelve todo, comportamiento
--     equivalente al SP original). Si solo uno viene, el otro
--     extremo queda abierto. Si p_fecha_ini > p_fecha_fin, el
--     filtro simplemente no devuelve filas (sin error).
--   * Columna filtrada: pt.PT_FEC_HORA_INI (TIMESTAMP(6) en
--     SSI_PROG_TALLERES). Oracle hace conversión implícita
--     DATE -> TIMESTAMP(6) agregando 00:00:00.000000.
--   * Filtro opcional por zona (p_id_zona):
--       - p_id_zona = -1 (default) o NULL: sin filtro, devuelve todas las
--         zonas del servicio 2.
--       - Cualquier otro valor: filtra por zi.ZO_ID_ZONA (columna del
--         catalogo ya en JOIN con pf.ZO_ID_ZONA).
--       Sin validacion EXISTS: si el ID no existe, el WHERE no devuelve
--       filas (sin error), mismo patron que los filtros de fecha.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR (
   p_cursor_out OUT SYS_REFCURSOR,
   p_fecha_ini  IN  DATE     DEFAULT NULL,
   p_fecha_fin  IN  DATE     DEFAULT NULL,
   p_id_zona    IN  NUMBER   DEFAULT -1
)
IS
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      SELECT
         ROWNUM                                        AS NRO,
         sub.COD_ZON,
         sub.ZONA_INTERVENCION,
         sub.CODIGO_FAMILIA,
         sub.PRIMER_APELLIDO_CUIDADOR,
         sub.SEGUNDO_APELLIDO_CUIDADOR,
         sub.NOMBRES_CUIDADOR,
         sub.PARENTESCO,
         sub.SEXO_CUIDADOR,
         sub.OBJETIVO,
         sub."MÓDULO",
         sub.UNIDAD,
         sub."SESIÓN",
         sub.TALLER,
         sub.PROFESIONAL_DESARROLLO_TALLER,
         sub.LUGAR,
         sub."FECHA_TALLER",
         sub.HORA_INICIO,
         sub."HORA_TÉRMINO",
         sub.TOTAL_PARTICIPANTES,
         sub.PARENTESCO_PARTICIPANTES
      FROM (
         SELECT
            zi.ZO_ID_ZONA                                AS COD_ZON,
            zi.ZO_DESCRIPCION                            AS ZONA_INTERVENCION,
            pf.PF_COD_FAMILIA                            AS CODIGO_FAMILIA,
            fi.FI_PRIMER_APE                             AS PRIMER_APELLIDO_CUIDADOR,
            fi.FI_SEGUNDO_APE                            AS SEGUNDO_APELLIDO_CUIDADOR,
            fi.FI_NOMBRES                                AS NOMBRES_CUIDADOR,
            cat_pare.CATDESCRIPCION                      AS PARENTESCO,
            cat_sex.CATDESCRIPCION                       AS SEXO_CUIDADOR,
            oe.OE_DESCRIPCION                             AS OBJETIVO,
            mo.MO_DESCRIPCION                             AS "MÓDULO",
            un.UN_DESCRIPCION                             AS UNIDAD,
            us.SE_DESCRIPCION                             AS "SESIÓN",
            ta.TA_DESCRIPCION                             AS TALLER,
            CASE
               WHEN pt.PT_RESPONSABLES_DICTADO IS NULL
                  OR TRIM(pt.PT_RESPONSABLES_DICTADO) = ''
                  THEN NULL
               ELSE
                  (
                     SELECT LISTAGG(nombre, ', ')
                                  WITHIN GROUP (ORDER BY orden)
                     FROM (
                        SELECT
                           TRIM(
                              REGEXP_SUBSTR(
                                 partes,
                                 ';\s*(.+)',
                                 1, 1, NULL, 1
                              )
                           )                                   AS nombre,
                           ROWNUM                             AS orden
                        FROM (
                           SELECT REGEXP_SUBSTR(
                              str,
                              '[^|]+',
                              1, LEVEL
                           ) AS partes
                           FROM (
                              SELECT pt.PT_RESPONSABLES_DICTADO AS str
                              FROM DUAL
                           )
                           CONNECT BY LEVEL <= REGEXP_COUNT(str, '[^|]+')
                        ) split
                     ) parsed
                  )
            END                                          AS PROFESIONAL_DESARROLLO_TALLER,
            pt.PT_LUGAR_TALLER                           AS LUGAR,
            TRUNC(pt.PT_FEC_HORA_INI)                    AS "FECHA_TALLER",
            TO_CHAR(pt.PT_FEC_HORA_INI, 'HH24:MI:SS')    AS HORA_INICIO,
            TO_CHAR(pt.PT_FEC_HORA_FIN, 'HH24:MI:SS')    AS "HORA_TÉRMINO",
            CASE
               WHEN ptf.PD_INTEGRANTES_ASISTIERON IS NULL
                  OR TRIM(ptf.PD_INTEGRANTES_ASISTIERON) = ''
                  THEN 1
               ELSE REGEXP_COUNT(ptf.PD_INTEGRANTES_ASISTIERON, '[^|]+') + 1
            END                                          AS TOTAL_PARTICIPANTES,
            NVL(
               (
                  -- 1) Parentesco del CUIDADOR con sufijo ' [C]' (siempre al inicio).
                  --    PD_INTEGRANTES_ASISTIERON solo registra NNA, por lo que
                  --    el cuidador SIEMPRE se concatena aparte (no se duplica).
                  NVL((
                     SELECT cat_pare_c2.CATDESCRIPCION
                     FROM SSI_FAMILIA_INTEGRANTES fic2
                     LEFT JOIN TGCATALOGO cat_pare_c2
                        ON cat_pare_c2.IDCATALOGO = fic2.CA_ID_PARENTESCO
                     WHERE fic2.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
                        AND fic2.FI_CUIDADOR   = 1
                        AND fic2.FI_ESTADO     = 1
                        AND fic2.FI_ELIMINADO  = 0
                  ), 'NO REGISTRA') || ' [C]'
                  -- 2) LISTAGG de parentescos de NNA asistentes (solo si hay IDs).
                  || CASE
                        WHEN ptf.PD_INTEGRANTES_ASISTIERON IS NOT NULL
                           AND TRIM(ptf.PD_INTEGRANTES_ASISTIERON) <> ''
                        THEN ', ' || (
                           SELECT LISTAGG(NVL(cat_p.CATDESCRIPCION, 'NO REGISTRA'), ', ')
                                        WITHIN GROUP (ORDER BY cat_p.CATDESCRIPCION)
                           FROM (
                              SELECT TO_NUMBER(
                                 TRIM(REGEXP_SUBSTR(ids_str, '[^|]+', 1, LEVEL))
                              ) AS id_integrante
                              FROM (
                                 SELECT ptf.PD_INTEGRANTES_ASISTIERON AS ids_str
                                 FROM DUAL
                              )
                              CONNECT BY LEVEL <= REGEXP_COUNT(ids_str, '[^|]+')
                           ) ids
                           JOIN SSI_FAMILIA_INTEGRANTES fin
                              ON fin.FI_ID_INTEGRANTE = ids.id_integrante
                           LEFT JOIN TGCATALOGO cat_p
                              ON cat_p.IDCATALOGO = fin.CA_ID_PARENTESCO
                           WHERE fin.FI_ESTADO    = 1
                             AND fin.FI_ELIMINADO = 0
                        )
                        ELSE ''
                     END
               ),
               'NO REGISTRA'
            )                                            AS PARENTESCO_PARTICIPANTES
         FROM SSI_PROG_TALLERES pt
         JOIN SSI_TALLERES ta
            ON ta.TA_ID_TALLER = pt.TA_ID_TALLER
         JOIN SSI_UNIDAD_SESIONES us
            ON us.SE_ID_SESION = ta.SE_ID_SESION
         JOIN SSI_UNIDADES un
            ON un.UN_ID_UNIDAD = us.UN_ID_UNIDAD
         JOIN SSI_MODULOS mo
            ON mo.MO_ID_MODULO = un.MO_ID_MODULO
         JOIN SSI_OBJETIVOS_ESPECIFICOS oe
            ON oe.OE_ID_OBJETIVO = mo.OE_ID_OBJETIVO
         JOIN SSI_PROG_TALLER_FAMILIAS ptf
            ON ptf.PT_ID_PROG_TALLER = pt.PT_ID_PROG_TALLER
         JOIN SSI_POTENCIALES_FAMILIAS pf
            ON pf.PF_ID_FAMILIA = ptf.PF_ID_FAMILIA
         JOIN SSI_ZONA_INTERVENCION zi
            ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
         JOIN SSI_FAMILIA_INTEGRANTES fi
            ON fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
            AND fi.FI_CUIDADOR = 1
         LEFT JOIN TGCATALOGO cat_sex
            ON cat_sex.IDCATALOGO = fi.CA_ID_SEXO
         LEFT JOIN TGCATALOGO cat_pare
            ON cat_pare.IDCATALOGO = fi.CA_ID_PARENTESCO
         WHERE
            oe.SI_ID_SERVICIO = 2                       -- PUNCHE
            AND (pf.SI_ID_SERVICIO = 2
                 OR zi.SI_ID_SERVICIO = 2)               -- Defensa
            AND pt.PT_ESTADO     = 1
            AND pt.PT_ELIMINADO  = 0
            AND ta.TA_ESTADO     = 1
            AND ta.TA_ELIMINADO  = 0
            AND ptf.PD_ESTADO    = 1
            AND ptf.PD_ELIMINADO = 0
            AND pf.PF_ESTADO     = 1
            AND pf.PF_ELIMINADO  = 0
            AND zi.ZO_ESTADO     = 1
            AND fi.FI_ESTADO     = 1
            AND fi.FI_ELIMINADO  = 0
            -- Filtros opcionales por rango de fecha (rango medio-abierto).
            -- Si ambos parámetros son NULL no se aplica ningún filtro.
            AND (p_fecha_ini IS NULL OR pt.PT_FEC_HORA_INI >= p_fecha_ini)
            AND (p_fecha_fin IS NULL OR pt.PT_FEC_HORA_INI <  p_fecha_fin + 1)
            -- Filtro opcional por zona de intervencion.
            -- p_id_zona = -1 (default) o NULL => todas las zonas del servicio 2.
            -- Cualquier otro valor filtra por zi.ZO_ID_ZONA.
            AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
          ORDER BY
            zi.ZO_ID_ZONA      ASC,
            pf.PF_COD_FAMILIA  ASC,
            pt.PT_FEC_HORA_INI ASC
      ) sub;

EXCEPTION
   WHEN OTHERS THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      RAISE_APPLICATION_ERROR(
         -20999,
         'Error en PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR: '
            || v_error_message
      );
END PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR;
/

--! COMMIT;

-- =============================================================
-- ! DROP del SP con el nombre antiguo
-- ! Ejecutar SOLO cuando se haya confirmado que ningún caller
-- ! sigue invocando PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR_TODAS.
-- =============================================================
-- DROP PROCEDURE PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR_TODAS;
-- /

-- =============================================================
-- Bloque de invocación / prueba
-- =============================================================
-- Caso 1: sin filtros (debe devolver idéntico al SP original)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR(c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 2: solo fecha de inicio
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR(
      c_resultado_busqueda,
      p_fecha_ini => DATE '2026-01-01',
      p_fecha_fin => NULL
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 3: solo fecha de fin (incluye el día completo)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR(
      c_resultado_busqueda,
      p_fecha_ini => NULL,
      p_fecha_fin => DATE '2026-07-20'
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 4: rango cerrado (medio-abierto)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR(
      c_resultado_busqueda,
      p_fecha_ini => DATE '2026-01-01',
      p_fecha_fin => DATE '2026-07-20'
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- =============================================================
-- Bloque auxiliar: zonas disponibles del servicio 2
-- (ejecutar antes de los nuevos casos 5/6/7 para elegir un ID)
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
   PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR(
      c_resultado_busqueda,
      p_fecha_ini => NULL,
      p_fecha_fin => NULL,
      p_id_zona   => -1
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 6: p_id_zona con un ID especifico del servicio 2
-- (REEMPLAZAR el ID 999 con un ZO_ID_ZONA valido del servicio 2)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR(
      c_resultado_busqueda,
      p_fecha_ini => DATE '2026-01-01',
      p_fecha_fin => DATE '2026-07-20',
      p_id_zona   => 999  /* REEMPLAZAR con un ZO_ID_ZONA valido del servicio 2 */
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 7: p_id_zona = NULL (equivalente a todas las zonas por D3)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_TALLERES_FAMILIAS_LISTAR(
      c_resultado_busqueda,
      p_fecha_ini => NULL,
      p_fecha_fin => NULL,
      p_id_zona   => NULL
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/


SELECT * FROM SSI_TALLERES
/

SELECT f.* FROM SSI_PROG_TALLER_FAMILIAS f
JOIN SSI_PROG_TALLERES p ON p.PT_ID_PROG_TALLER = f.PT_ID_PROG_TALLER
WHERE
   f.PD_ELIMINADO = 0
   AND p.PT_ELIMINADO = 0
   AND f.PD_INTEGRANTES_ASISTIERON IS NOT NULL
ORDER BY
   LENGTH(f.PD_INTEGRANTES_ASISTIERON) DESC
/

-- PD_INTEGRANTES_ASISTIERON



-- ! COMMIT;
