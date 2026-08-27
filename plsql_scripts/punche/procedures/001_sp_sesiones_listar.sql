-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_SESIONES_LISTAR
-- Propósito: Retorna el listado de sesiones EJECUTADAS en el
--            servicio PUNCHE (SI_ID_SERVICIO = 2), con filtros
--            opcionales por rango de fecha y por zona de
--            intervencion. Una fila por combinación (zona +
--            familia + cuidador + ejecución de sesión).
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
-- Alcance : Solo lectura. SELECT sobre SSI_EJECUCION_SESIONES +
--          catalogos y joins descritos abajo.
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
--   * Filtros de fecha (rango medio-abierto):
--       es.ES_FEC_HORA_INI >= p_fecha_ini
--       AND es.ES_FEC_HORA_INI <  p_fecha_fin + 1
--     Estrategia OR-NULL: si ambos parámetros son NULL, no se
--     aplica ningún filtro (devuelve todo, comportamiento
--     equivalente al SP original). Si solo uno viene, el otro
--     extremo queda abierto. Si p_fecha_ini > p_fecha_fin, el
--     filtro simplemente no devuelve filas (sin error).
--   * Columna filtrada: es.ES_FEC_HORA_INI (TIMESTAMP(6) en
--     SSI_EJECUCION_SESIONES). Oracle hace conversión implícita
--     DATE -> TIMESTAMP(6) agregando 00:00:00.000000.
--   * ACOMPAÑANTE_FAMILIAR: se obtiene de
--     SSI_POTENCIALES_FAMILIAS.PER_ID_PERSONAL (acompañante asignado
--     a la familia), resolviendo el nombre completo vía
--     TRPERSONAL -> TGPERSONA (PERNOMBRE + PERAPEPATERNO +
--     PERAPEMATERNO). LEFT JOIN para preservar familias sin
--     acompañante asignado; si es NULL se muestra 'NO REGISTRA'.
--     Se proyecta después de ZONA_INTERVENCION.
--   * CODIGO_FAMILIA: se obtiene desde SSI_CODIGOS_FAMILIAS
--     (subconsulta escalar correlacionada por pf.PF_ID_FAMILIA,
--     filtrando CF_TIPO_CODIGO = 1, CF_ESTADO = 1 y
--     CF_ELIMINADO = 0). Si hay varias filas activas para la
--     misma familia, se toma MAX(CF_CODIGO) (último código activo
--     registrado). Si no existe fila que cumpla las condiciones,
--     se devuelve NULL literal. NO se proyecta desde
--     pf.PF_COD_FAMILIA (legacy).
--   * Filtro opcional por zona (p_id_zona):
--       - p_id_zona = -1 (default) o NULL: sin filtro, devuelve todas las
--         zonas del servicio 2.
--       - Cualquier otro valor: filtra por zi.ZO_ID_ZONA (columna del
--         catalogo ya en JOIN con pf.ZO_ID_ZONA).
--       Sin validacion EXISTS: si el ID no existe, el WHERE no devuelve
--       filas (sin error), mismo patron que los filtros de fecha.
--   * Anclaje del JOIN con SSI_UNIDAD_SESIONES: la sesion del reporte
--     se toma del DET_PATFAM (dp.SE_ID_SESION), NO de la ejecucion
--     (es.SE_ID_SESION). Razon: si una ejecucion guarda un SE_ID_SESION
--     distinto al de su detalle, anclar por ejecucion multiplicaba
--     filas (una misma ejecucion cruzada con varias sesiones del
--     catalogo). Anclar al DET_PATFAM garantiza 1 sesion por ejecucion
--     activa y elimina la duplicacion.
--   * Anclaje del JOIN con SSI_UNIDADES, SSI_MODULOS y
--     SSI_OBJETIVOS_ESPECIFICOS: las columnas UN_ID_UNIDAD,
--     MO_ID_MODULO y OE_ID_OBJETIVO se leen DIRECTAMENTE desde
--     SSI_DET_PATFAM (dp.UN_ID_UNIDAD, dp.MO_ID_MODULO, dp.OE_ID_OBJETIVO),
--     NO se navega la cascada us -> un -> mo -> oe. Esto refuerza la
--     fuente unica de verdad en el DET_PATFAM y evita multiplicacion
--     cuando la jerarquia del catalogo no esta alineada con la
--     ejecucion. Como regla de negocio: un DET_PATFAM activo no puede
--     tener estas columnas en NULL (no existen DET_PATFAM huerfanos),
--     por lo que el INNER JOIN es seguro.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_SESIONES_LISTAR (
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
         sub."ACOMPAÑANTE_FAMILIAR",
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
            NVL(
               TRIM(
                  per_acom.PERNOMBRE || ' ' ||
                  per_acom.PERAPEPATERNO || ' ' ||
                  per_acom.PERAPEMATERNO
               ),
               'NO REGISTRA'
             )                                            AS "ACOMPAÑANTE_FAMILIAR",
             (
                SELECT MAX(cf.CF_CODIGO)
                FROM SSI_CODIGOS_FAMILIAS cf
                WHERE cf.PF_ID_FAMILIA  = pf.PF_ID_FAMILIA
                  AND cf.CF_TIPO_CODIGO = 1
                  AND cf.CF_ESTADO      = 1
                  AND cf.CF_ELIMINADO   = 0
             )                                            AS CODIGO_FAMILIA,
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
             ON us.SE_ID_SESION = dp.SE_ID_SESION
JOIN SSI_UNIDADES un
             ON un.UN_ID_UNIDAD = dp.UN_ID_UNIDAD
          JOIN SSI_MODULOS mo
             ON mo.MO_ID_MODULO = dp.MO_ID_MODULO
          JOIN SSI_OBJETIVOS_ESPECIFICOS oe
             ON oe.OE_ID_OBJETIVO = dp.OE_ID_OBJETIVO
         LEFT JOIN TGCATALOGO cat_sex
            ON cat_sex.IDCATALOGO = fi.CA_ID_SEXO
         LEFT JOIN TGCATALOGO cat_pare
            ON cat_pare.IDCATALOGO = fi.CA_ID_PARENTESCO
          LEFT JOIN TGCATALOGO cat_mod
             ON cat_mod.IDCATALOGO = es.CA_ID_MODALIDAD
          /* ----- Acompañante familiar: pf.PER_ID_PERSONAL -> TRPERSONAL/TGPERSONA ----- */
          LEFT JOIN TRPERSONAL tp_acom
             ON tp_acom.IDPERSONAL = pf.PER_ID_PERSONAL
          LEFT JOIN TGPERSONA per_acom
             ON per_acom.IDPERSONA = tp_acom.PRHPERSONA
         WHERE
            es.ES_REALIZO_SESION  = 1
            AND es.ES_ESTADO      = 1
            AND es.ES_ELIMINADO   = 0
            AND pf.PF_ESTADO      = 1
            AND pf.PF_ELIMINADO   = 0
            AND fi.FI_CUIDADOR    = 1
            AND fi.FI_ESTADO      = 1
            AND fi.FI_ELIMINADO   = 0
            AND dp.DP_ESTADO = 1
            AND dp.DP_ELIMINADO = 0
            AND zi.SI_ID_SERVICIO = 2
            AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
            -- Filtros opcionales por rango de fecha (rango medio-abierto).
            -- Si ambos parámetros son NULL no se aplica ningún filtro.
            AND (p_fecha_ini IS NULL OR es.ES_FEC_HORA_INI >= p_fecha_ini)
            AND (p_fecha_fin IS NULL OR es.ES_FEC_HORA_INI <  p_fecha_fin + 1)
            -- Filtro opcional por zona de intervencion.
            -- p_id_zona = -1 (default) o NULL => todas las zonas del servicio 2.
            -- Cualquier otro valor filtra por zi.ZO_ID_ZONA.
            AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
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
         'Error en PRC_PUNCHE_SESIONES_LISTAR: ' || v_error_message
      );
END PRC_PUNCHE_SESIONES_LISTAR;
/

-- ! COMMIT;


-- =============================================================
-- ! DROP del SP con el nombre antiguo
-- ! Ejecutar SOLO cuando se haya confirmado que ningún caller
-- ! (backend, jobs, otros SPs) sigue invocando
-- ! PRC_PUNCHE_SESIONES_LISTAR_TODAS.
-- =============================================================
-- DROP PROCEDURE PRC_PUNCHE_SESIONES_LISTAR_TODAS;
-- /

-- =============================================================
-- Bloque de invocación / prueba
-- =============================================================
-- Caso 1: sin filtros (debe devolver idéntico al SP original)
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_SESIONES_LISTAR(c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- Caso 2: solo fecha de inicio
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_SESIONES_LISTAR(
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
   PRC_PUNCHE_SESIONES_LISTAR(
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
   PRC_PUNCHE_SESIONES_LISTAR(
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
   PRC_PUNCHE_SESIONES_LISTAR(
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
   PRC_PUNCHE_SESIONES_LISTAR(
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
   PRC_PUNCHE_SESIONES_LISTAR(
      c_resultado_busqueda,
      p_fecha_ini => NULL,
      p_fecha_fin => NULL,
      p_id_zona   => NULL
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- =============================================================
-- Validacion post-cambio: conteo de filas vs. logica anterior.
-- Ejecutar Caso 1 (sin filtros) y comparar el COUNT(*) con este
-- SELECT directo (que replica la cadena JOIN actual). Si coincide,
-- la duplicacion esta corregida sin perdidas.
-- =============================================================
SELECT
   COUNT(*) AS total_directo
FROM SSI_EJECUCION_SESIONES es
JOIN SSI_DET_PATFAM dp
   ON dp.DP_ID_DET_PATFAM = es.DP_ID_DET_PATFAM
JOIN SSI_PATFAM pa
   ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
JOIN SSI_POTENCIALES_FAMILIAS pf
   ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
JOIN SSI_ZONA_INTERVENCION zi
   ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
JOIN SSI_UNIDAD_SESIONES us
   ON us.SE_ID_SESION = dp.SE_ID_SESION
JOIN SSI_UNIDADES un
   ON un.UN_ID_UNIDAD = dp.UN_ID_UNIDAD
JOIN SSI_MODULOS mo
   ON mo.MO_ID_MODULO = dp.MO_ID_MODULO
JOIN SSI_OBJETIVOS_ESPECIFICOS oe
   ON oe.OE_ID_OBJETIVO = dp.OE_ID_OBJETIVO
JOIN SSI_FAMILIA_INTEGRANTES fi
   ON fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
WHERE
   es.ES_REALIZO_SESION = 1
   AND es.ES_ESTADO      = 1
   AND es.ES_ELIMINADO   = 0
   AND dp.DP_ESTADO      = 1
   AND dp.DP_ELIMINADO   = 0
   AND pf.PF_ESTADO      = 1
   AND pf.PF_ELIMINADO   = 0
   AND fi.FI_CUIDADOR    = 1
   AND fi.FI_ESTADO      = 1
   AND fi.FI_ELIMINADO   = 0
   AND zi.SI_ID_SERVICIO = 2
   AND us.SE_ESTADO      = 1
   AND us.SE_ELIMINADO   = 0
/





-- * D1 — ¿Cuántas filas devuelve el SP vs. el conteo esperado?
-- Ejecuta el SP sin filtros (Caso 1) y captura el COUNT(*).
-- Compáralo con este conteo directo:
SELECT 
   COUNT(*) AS total_esperado
FROM SSI_EJECUCION_SESIONES es
JOIN SSI_DET_PATFAM dp ON dp.DP_ID_DET_PATFAM = es.DP_ID_DET_PATFAM
JOIN SSI_PATFAM pa ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
JOIN SSI_UNIDAD_SESIONES us ON us.SE_ID_SESION = es.SE_ID_SESION
JOIN SSI_FAMILIA_INTEGRANTES fi
   ON fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
   AND fi.FI_CUIDADOR = 1
   AND fi.FI_ESTADO = 1
   AND fi.FI_ELIMINADO = 0
WHERE
   es.ES_REALIZO_SESION = 1
   AND es.ES_ESTADO = 1
   AND es.ES_ELIMINADO = 0
   AND dp.DP_ESTADO = 1
   AND dp.DP_ELIMINADO = 0
   AND pa.PA_ESTADO = 1
   AND pa.PA_ELIMINADO = 0
   AND pf.PF_ESTADO = 1
   AND pf.PF_ELIMINADO = 0
   AND zi.SI_ID_SERVICIO = 2
   AND us.SE_ESTADO = 1
   AND us.SE_ELIMINADO = 0
/

-- * Si D1 > total del SP → el problema está en otra parte (no en este JOIN).
-- Si D1 < total del SP → el SP está multiplicando (probablemente por el resto del LISTAGG o las subconsultas).
-- D2 — Detectar familias con varios cuidadores activos (Causa #1)
SELECT
   fi.PF_ID_FAMILIA,
   COUNT(*) AS cuidadores_activos
FROM SSI_FAMILIA_INTEGRANTES fi
WHERE
   fi.FI_CUIDADOR = 1
   AND fi.FI_ESTADO = 1
   AND fi.FI_ELIMINADO = 0
   AND EXISTS (
      SELECT 1 FROM SSI_POTENCIALES_FAMILIAS pf
      WHERE pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
         AND pf.SI_ID_SERVICIO = 2
   )
GROUP BY fi.PF_ID_FAMILIA
HAVING COUNT(*) > 1
/

-- Si devuelve filas: Causa #1 confirmada.
-- * D3 — Detectar DP con múltiples ejecuciones activas (Causa #2)
SELECT
   es.DP_ID_DET_PATFAM,
   COUNT(*) AS ejecuciones_activas
FROM SSI_EJECUCION_SESIONES es
WHERE
   es.ES_REALIZO_SESION = 1
   AND es.ES_ESTADO = 1
   AND es.ES_ELIMINADO = 0
GROUP BY es.DP_ID_DET_PATFAM
HAVING COUNT(*) > 1
/

-- * D4 — Detectar PATFAM con múltiples detalles activos (Causa #3)
SELECT
   dp.PA_ID_PATFAM,
   COUNT(*) AS detalles_activos
FROM SSI_DET_PATFAM dp
WHERE
   dp.DP_ESTADO = 1
   AND dp.DP_ELIMINADO = 0
GROUP BY dp.PA_ID_PATFAM
HAVING COUNT(*) > 1
/

SELECT * FROM SSI_EJECUCION_SESIONES es
WHERE
   es.ES_ID_EJECUCION IN (
      569,
      18928
   )
/