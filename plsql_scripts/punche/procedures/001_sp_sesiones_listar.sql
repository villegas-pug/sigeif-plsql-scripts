-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_SESIONES_LISTAR_TODAS
-- Propósito: Retorna el listado completo de sesiones EJECUTADAS
--            en el servicio PUNCHE (SI_ID_SERVICIO = 2), sin filtros
--            de entrada. Una fila por combinación
--            (zona + familia + cuidador + ejecución de sesión).
-- Parámetros:
--   p_cursor_out OUT SYS_REFCURSOR — cursor con el resultado.
-- Autor   : [ REEMPLAZAR: nombre del autor ]
-- Fecha   : [ REEMPLAZAR: fecha de creación ]
-- =============================================================
-- Notas de implementación:
--   * SP de SOLO LECTURA. No ejecuta DML. No usa COMMIT/ROLLBACK.
--   * Granularidad: una fila por sesión EJECUTADA
--     (es.ES_REALIZO_SESION = 1). Si una sesión se ejecuta varias
--     veces, aparecen varias filas (una por ejecución) con su
--     modalidad, fecha y hora propias.
--   * Alias con comillas dobles: preserva case y acentos exactos
--     del encabezado (REALIZÓ_CONSEJERÍA_FAMILIAR, MÓDULO, SESIÓN,
--     FECHA_SESIÓN, HORA_TÉRMINO).
--   * Campos OBJETIVO, MÓDULO, UNIDAD y SESIÓN se proyectan desde
--     las columnas *_DESCRIPCION del catálogo (OE_DESCRIPCION,
--     MO_DESCRIPCION, UN_DESCRIPCION, SE_DESCRIPCION) en lugar de
--     *_NOMBRE.
--   * PARTICIPANTES_PARENTESCO: si la subconsulta retorna NULL
--     (no hay asistentes a la sesión ejecutada) o si algún
--     parentesco viene nulo, se devuelve 'NO REGISTRA' (tanto
--     a nivel de elemento dentro del LISTAGG como a nivel de
--     la cadena completa).
--   * Marcado del CUIDADOR dentro de PARTICIPANTES_PARENTESCO:
--     el parentesco del integrante con FI_CUIDADOR = 1 se
--     concatena con el sufijo ' [C]' (ej: 'MADRE [C]') y se
--     ordena al INICIO de la lista (ORDER BY
--     fi2.FI_CUIDADOR DESC, cat_p.CATDESCRIPCION). Si el
--     cuidador no tiene parentesco en catálogo, se muestra
--     'NO REGISTRA [C]'. El resto de asistentes (NNA) se
--     lista sin sufijo.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_SESIONES_LISTAR_TODAS (
   p_cursor_out OUT SYS_REFCURSOR
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
         sub.PARENTESCO_CUIDADOR,
         sub.SEXO_CUIDADOR,
         sub."REALIZÓ_CONSEJERÍA_FAMILIAR",
         sub.OBJETIVO,
         sub."MÓDULO",
         sub.UNIDAD,
         sub."SESIÓN",
         sub.MODALIDAD,
         sub."FECHA_SESIÓN",
         sub.HORA_INICIO,
         sub."HORA_TÉRMINO",
         sub.TOTAL_PARTICIPANTES,
         sub.PARTICIPANTES_PARENTESCO
      FROM (
         SELECT
            zi.ZO_ID_ZONA                                AS COD_ZON,
            zi.ZO_DESCRIPCION                            AS ZONA_INTERVENCION,
            pf.PF_COD_FAMILIA                            AS CODIGO_FAMILIA,
            fi.FI_PRIMER_APE                             AS PRIMER_APELLIDO_CUIDADOR,
            fi.FI_SEGUNDO_APE                            AS SEGUNDO_APELLIDO_CUIDADOR,
            fi.FI_NOMBRES                                AS NOMBRES_CUIDADOR,
            cat_pare.CATDESCRIPCION                      AS PARENTESCO_CUIDADOR,
            cat_sex.CATDESCRIPCION                       AS SEXO_CUIDADOR,
            'SI'                                         AS "REALIZÓ_CONSEJERÍA_FAMILIAR",
            oe.OE_DESCRIPCION                            AS OBJETIVO,
            mo.MO_DESCRIPCION                            AS "MÓDULO",
            un.UN_DESCRIPCION                            AS UNIDAD,
            us.SE_DESCRIPCION                            AS "SESIÓN",
            cat_mod.CATDESCRIPCION                       AS MODALIDAD,
            TRUNC(es.ES_FEC_HORA_INI)                   AS "FECHA_SESIÓN",
            TO_CHAR(es.ES_FEC_HORA_INI, 'HH24:MI:SS')   AS HORA_INICIO,
            TO_CHAR(es.ES_FEC_HORA_FIN, 'HH24:MI:SS')   AS "HORA_TÉRMINO",
            (
               SELECT COUNT(1)
               FROM SSI_EJEC_SESION_INTEGRANTES esi
               WHERE esi.ES_ID_EJECUCION = es.ES_ID_EJECUCION
                 AND esi.SI_ASISTIO      = 1
                 AND esi.SI_ESTADO       = 1
                 AND esi.SI_ELIMINADO    = 0
            )                                            AS TOTAL_PARTICIPANTES,
            NVL(
               (
                  SELECT LISTAGG(
                           CASE WHEN fi2.FI_CUIDADOR = 1
                                THEN NVL(cat_p.CATDESCRIPCION, 'NO REGISTRA') || ' [C]'
                                ELSE NVL(cat_p.CATDESCRIPCION, 'NO REGISTRA')
                           END, ', ')
                           WITHIN GROUP (ORDER BY fi2.FI_CUIDADOR DESC, cat_p.CATDESCRIPCION)
                  FROM SSI_EJEC_SESION_INTEGRANTES esi2
                  JOIN SSI_FAMILIA_INTEGRANTES fi2
                     ON fi2.FI_ID_INTEGRANTE = esi2.FI_ID_INTEGRANTE
                  LEFT JOIN TGCATALOGO cat_p
                     ON cat_p.IDCATALOGO = fi2.CA_ID_PARENTESCO
                  WHERE esi2.ES_ID_EJECUCION = es.ES_ID_EJECUCION
                    AND esi2.SI_ASISTIO      = 1
                    AND esi2.SI_ESTADO       = 1
                    AND esi2.SI_ELIMINADO    = 0
               ),
               'NO REGISTRA'
            )                                            AS PARTICIPANTES_PARENTESCO
         FROM SSI_EJECUCION_SESIONES es
         JOIN SSI_DET_PATFAM dp
            ON dp.DP_ID_DET_PATFAM = es.DP_ID_DET_PATFAM
         JOIN SSI_PATFAM pa
            ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
         JOIN SSI_POTENCIALES_FAMILIAS pf
            ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
         JOIN SSI_ZONA_INTERVENCION zi
            ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
         JOIN SSI_FAMILIA_INTEGRANTES fi
            ON fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         JOIN SSI_UNIDAD_SESIONES us
            ON us.SE_ID_SESION = es.SE_ID_SESION
         JOIN SSI_UNIDADES un
            ON un.UN_ID_UNIDAD = us.UN_ID_UNIDAD
         JOIN SSI_MODULOS mo
            ON mo.MO_ID_MODULO = un.MO_ID_MODULO
         JOIN SSI_OBJETIVOS_ESPECIFICOS oe
            ON oe.OE_ID_OBJETIVO = mo.OE_ID_OBJETIVO
         LEFT JOIN TGCATALOGO cat_sex
            ON cat_sex.IDCATALOGO = fi.CA_ID_SEXO
         LEFT JOIN TGCATALOGO cat_pare
            ON cat_pare.IDCATALOGO = fi.CA_ID_PARENTESCO
         LEFT JOIN TGCATALOGO cat_mod
            ON cat_mod.IDCATALOGO = es.CA_ID_MODALIDAD
         WHERE
            es.ES_REALIZO_SESION  = 1
            AND es.ES_ESTADO      = 1
            AND es.ES_ELIMINADO   = 0
            AND pf.PF_ESTADO      = 1
            AND pf.PF_ELIMINADO   = 0
            AND fi.FI_CUIDADOR    = 1
            AND fi.FI_ESTADO      = 1
            AND fi.FI_ELIMINADO   = 0
            AND zi.SI_ID_SERVICIO = 2
            AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
         ORDER BY
            zi.ZO_ID_ZONA      ASC,
            pf.PF_COD_FAMILIA  ASC,
            es.ES_FEC_HORA_INI ASC
      ) sub;

EXCEPTION
   WHEN OTHERS THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      RAISE_APPLICATION_ERROR(
         -20999,
         'Error en PRC_PUNCHE_SESIONES_LISTAR_TODAS: ' || v_error_message
      );
END PRC_PUNCHE_SESIONES_LISTAR_TODAS;
/

-- ! COMMIT;

-- =============================================================
-- Bloque de invocación / prueba
-- =============================================================
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_SESIONES_LISTAR_TODAS(c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/
