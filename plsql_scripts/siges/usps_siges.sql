-- * Reportes SIGES

/*
*     1. ...
* ==============================================================================================================================
*     Procedimiento de solo lectura para los reportes:
*     - RPT_ASISTENCIA_ECONOMICA
*     - RPT_SIGEIR
*
*     p_valor:
*        El backend/frontend debe enviar los filtros concatenados con "|".
*        Usar "SF" cuando un filtro no aplique.
*
*        RPT_ASISTENCIA_ECONOMICA:
*           anio_ingreso|dni_usuario|nombre_usuario|nombre_centro
*           Ejemplo: 2026|SF|PEREZ|SF
*
*        RPT_SIGEIR:
*           anio_afiliacion|dni_usuario|nombre_usuario|dni_administrador|nombre_administrador|condicion
*           Ejemplo: 2025|SF|SF|SF|GOMEZ|1
* ============================================================================================================================== */

CREATE OR REPLACE PROCEDURE USP_GENERAR_REPORTES_SIGES
(
   p_tipo IN VARCHAR2,
   p_valor IN VARCHAR2,
   p_resultado OUT SYS_REFCURSOR
)
AS
BEGIN

   IF p_tipo = 'RPT_ASISTENCIA_ECONOMICA' THEN

      OPEN p_resultado FOR
         SELECT
            b.BEN_NRO_DOCUMENTO AS DNI_USUARIO,
            SUBSTR(b.BEN_NOMBRES, 0, 1) || SUBSTR(b.BEN_PRIMER_APELLIDO, 0, 1) || SUBSTR(b.BEN_SEGUNDO_APELLIDO, 0, 1) AS NOMBRE_COMPLETO_USUARIO,
            CASE
               WHEN b.BEN_SEXO = 0 THEN 'MUJER'
               WHEN b.BEN_SEXO = 1 THEN 'HOMBRE'
            END AS SEXO_USUARIO,
            TO_CHAR(b.BEN_FEC_NACIMIENTO, 'DD/MM/YYYY') AS FEC_NACIMIENTO_USUARIO,
            (
               SELECT u.UBILOCALIDAD
               FROM TGUBIGEO u
               WHERE u.IDUBIGEO = SUBSTR(b.BEN_PROC_UBIGEO, 1, 2) || '0000'
            ) || ', ' ||
            (
               SELECT u.UBILOCALIDAD
               FROM TGUBIGEO u
               WHERE u.IDUBIGEO = SUBSTR(b.BEN_PROC_UBIGEO, 1, 4) || '00'
            ) || ', ' ||
            (
               SELECT u.UBILOCALIDAD
               FROM TGUBIGEO u
               WHERE u.IDUBIGEO = b.BEN_PROC_UBIGEO
            ) AS UBIGEO_RESIDENCIA,
            '' AS DIRECCION_RESIDENCIA,
            TO_CHAR(b.BEN_FEC_INGRESO, 'DD/MM/YYYY') AS FEC_INGRESO_SERVICIO,
            uo.UORNOMBRE AS NOMBRE_SERVICIO,
            ca_tc.CATDESCRIPCION AS TIPO_CENTRO,
            CASE
               WHEN b.BEN_ESTADO = 0 THEN 'DE BAJA'
               WHEN b.BEN_ESTADO = 1 THEN 'ACTIVO'
            END AS ESTADO_SERVICIO,
            ca_pp.CATDESCRIPCION AS PERFIL_INGRESO,
            '' AS TIPO_EDUCACION,
            ce.CEN_EDU AS IIEE_MATRICULADO,
            ca_ne.CATDESCRIPCION AS NIVEL_ESTUDIO_ACTUAL,
            ce.D_NIV_MOD AS GRADO_ESTUDIO_ACTUAL
         FROM SG_BENEFICIARIO b
         LEFT JOIN TGUNIDADORGANICA uo ON b.FK_CENTRO = uo.IDUNIDADORGANICA
         LEFT JOIN TGCATALOGO ca_tc ON uo.UOR_TIPO_CENTRO = ca_tc.IDCATALOGO
         LEFT JOIN TGCATALOGO ca_pp ON uo.UOR_PERFIL_POBLACION = ca_pp.IDCATALOGO
         LEFT JOIN SG_FICHA_DATOS fd ON b.ID_BENEFICIARIO = fd.FIC_RESIDENTE
                                    AND fd.FIC_ELIMINADO = 0
                                    AND fd.FIC_ESTADO = 1
         LEFT JOIN SG_CENTRO_EDUCATIVO ce ON fd.FIC_NRO_DOCUMENTO = ce.COD_MOD
         LEFT JOIN TGCATALOGO ca_ne ON fd.FIC_NIVEL_EDUCATIVO = ca_ne.IDCATALOGO
         WHERE
            b.BEN_ELIMINADO = 0
            AND b.BEN_ESTADO = 1
            AND CASE
                  WHEN 'SF' = REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 1, NULL, 1) THEN 1
                  WHEN TO_CHAR(b.BEN_FEC_INGRESO, 'YYYY') = REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 1, NULL, 1) THEN 1
                  ELSE 0
               END = 1
            AND CASE
                  WHEN 'SF' = REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 2, NULL, 1) THEN 1
                  WHEN b.BEN_NRO_DOCUMENTO = REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 2, NULL, 1) THEN 1
                  ELSE 0
               END = 1
            AND CASE
                  WHEN 'SF' = REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 3, NULL, 1) THEN 1
                  WHEN TRANSLATE(UPPER(b.BEN_NOMBRES || ' ' || b.BEN_PRIMER_APELLIDO || ' ' || b.BEN_SEGUNDO_APELLIDO), 'ÁÉÍÓÚ', 'AEIOU') LIKE '%' || TRIM(TRANSLATE(UPPER(REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 3, NULL, 1)), 'ÁÉÍÓÚ', 'AEIOU')) || '%' THEN 1
                  ELSE 0
               END = 1
            AND CASE
                  WHEN 'SF' = REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 4, NULL, 1) THEN 1
                  WHEN TRANSLATE(UPPER(uo.UORNOMBRE), 'ÁÉÍÓÚ', 'AEIOU') LIKE '%' || TRIM(TRANSLATE(UPPER(REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 4, NULL, 1)), 'ÁÉÍÓÚ', 'AEIOU')) || '%' THEN 1
                  ELSE 0
               END = 1;

   ELSIF p_tipo = 'RPT_SIGEIR' THEN
      OPEN p_resultado FOR
         WITH cte_parametros AS (
            SELECT
               REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 1, NULL, 1) AS v_anio_afiliacion,
               REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 2, NULL, 1) AS v_dni_usuario,
               TRIM(TRANSLATE(UPPER(REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 3, NULL, 1)), 'ÁÉÍÓÚ', 'AEIOU')) AS v_nombre_usuario,
               REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 4, NULL, 1) AS v_dni_administrador,
               TRIM(TRANSLATE(UPPER(REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 5, NULL, 1)), 'ÁÉÍÓÚ', 'AEIOU')) AS v_nombre_administrador,
               REGEXP_SUBSTR(p_valor, '([^|]*)(\||$)', 1, 6, NULL, 1) AS v_condicion
            FROM DUAL
         ), cte_abonos AS (
            SELECT
               ab.ABN_NUM_DOCUMENTO_BEN,
               COUNT(1) AS CANT_BONOS
            FROM SAE_ABONO ab
            GROUP BY
               ab.ABN_NUM_DOCUMENTO_BEN
         ), cte_ultima_visita AS (
            SELECT
               fsl.FSL_ADMINISTRADOR,
               MAX(fsl.FSL_FECHA_HORA_INICIO) AS FEC_MAX_VISITA
            FROM SAE_FS01_LEY fsl
            WHERE
               fsl.FSL_ELIMINADO = 0
            GROUP BY
               fsl.FSL_ADMINISTRADOR
         ), cte_resultado_visita AS (
            SELECT
               rv.FSL_ADMINISTRADOR,
               rv.FSL_FECHA_HORA_INICIO,
               rv.FSL_RESULTADO
            FROM (
               SELECT
                  f.FSL_ADMINISTRADOR,
                  f.FSL_FECHA_HORA_INICIO,
                  f.FSL_RESULTADO,
                  ROW_NUMBER() OVER (
                     PARTITION BY
                        f.FSL_ADMINISTRADOR,
                        f.FSL_FECHA_HORA_INICIO
                     ORDER BY
                        f.ROWID
                  ) AS RN
               FROM SAE_FS01_LEY f
               WHERE
                  f.FSL_ELIMINADO = 0
            ) rv
            WHERE
               rv.RN = 1
         ), cte_base AS (
            SELECT
               pb.PER_NUM_DOCUMENTO AS DNI_USUARIO,
               CASE
                  WHEN FLOOR(MONTHS_BETWEEN(SYSDATE, pb.PER_FECHA_NACIMIENTO) / 12) >= 18 THEN pb.PER_NOMBRES || ' ' || pb.PER_PRIMER_APELLIDO || ' ' || pb.PER_SEGUNDO_APELLIDO
                  ELSE SUBSTR(pb.PER_NOMBRES, 0, 1) || SUBSTR(pb.PER_PRIMER_APELLIDO, 0, 1) || SUBSTR(pb.PER_SEGUNDO_APELLIDO, 0, 1)
               END AS NOMBRE_COMPLETO_USUARIO,
               CASE
                  WHEN pb.PER_SEXO = 'M' THEN 'MASCULINO'
                  ELSE 'FEMENINO'
               END AS SEXO_USUARIO,
               TO_CHAR(pb.PER_FECHA_NACIMIENTO, 'DD/MM/YYYY') AS FEC_NACIMIENTO_USUARIO,
               CASE
                  WHEN pb.PER_UBIGEO IS NULL THEN ''
                  ELSE (
                     (
                        SELECT u.UBILOCALIDAD
                        FROM TGUBIGEO u
                        WHERE u.IDUBIGEO = SUBSTR(pb.PER_UBIGEO, 1, 2) || '0000'
                     ) || ', ' ||
                     (
                        SELECT u.UBILOCALIDAD
                        FROM TGUBIGEO u
                        WHERE u.IDUBIGEO = SUBSTR(pb.PER_UBIGEO, 1, 4) || '00'
                     ) || ', ' ||
                     (
                        SELECT u.UBILOCALIDAD
                        FROM TGUBIGEO u
                        WHERE u.IDUBIGEO = pb.PER_UBIGEO
                     )
                  )
               END AS UBIGEO_RESIDENCIA,
               pb.PER_DIRECCION AS DIRECCION_RESIDENCIA,
               TO_CHAR(b.BEN_FEC_AFILIACION, 'DD/MM/YYYY') AS FECHA_AFILIACION,
               CASE
                  WHEN b.BEN_ESTADO = 1 THEN 'AFILIADO'
                  WHEN b.BEN_ESTADO = 2 THEN 'DESAFILIADO'
                  ELSE ''
               END AS ESTADO,
               pa.PER_NUM_DOCUMENTO AS DNI_ADMINISTRADOR,
               pa.PER_NOMBRES || ' ' || pa.PER_PRIMER_APELLIDO || ' ' || pa.PER_SEGUNDO_APELLIDO AS NOMBRE_COMPLETO_ADMINISTRADOR,
               pa.PER_PARENTESCO AS PARENTESCO_ADMINISTRADOR,
               CASE
                  WHEN pa.PER_SEXO = 'M' THEN 'MASCULINO'
                  ELSE 'FEMENINO'
               END AS SEXO_ADMINISTRADOR,
               TO_CHAR(pa.PER_FECHA_NACIMIENTO, 'DD/MM/YYYY') AS FEC_NACIMIENTO_ADMINISTRADOR,
               b.BEN_RDE_AFILIACION AS PADRON_INICIO_AFILIACION,
               b.BEN_RDE_DESAFILIACION AS PADRON_ULTIMO_AFILIACION,
               b.BEN_RDE_REINCORPORACION,
               NVL(ab.CANT_BONOS, 0) AS CANT_BONOS,
               uv.FEC_MAX_VISITA,
               rv.FSL_RESULTADO AS RESULTADO_ULTIMA_VISITA
            FROM SAE_BENEFICIARIO b
            CROSS JOIN cte_parametros cp
            LEFT JOIN SAE_PERSONA pb ON b.BEN_PERSONA = pb.ID_PERSONA
            LEFT JOIN SAE_ASISTENCIA a ON b.BEN_ASISTENCIA = a.ID_ASISTENCIA
            LEFT JOIN SAE_PERSONA pa ON a.AST_ADMINISTRADOR = pa.ID_PERSONA
            LEFT JOIN cte_abonos ab ON ab.ABN_NUM_DOCUMENTO_BEN = pb.PER_NUM_DOCUMENTO
            LEFT JOIN cte_ultima_visita uv ON uv.FSL_ADMINISTRADOR = a.AST_ADMINISTRADOR
            LEFT JOIN cte_resultado_visita rv ON rv.FSL_ADMINISTRADOR = uv.FSL_ADMINISTRADOR
                                         AND rv.FSL_FECHA_HORA_INICIO = uv.FEC_MAX_VISITA
            WHERE
               b.BEN_ELIMINADO = 0
               AND b.BEN_ESTADO = 1
               AND (
                  cp.v_anio_afiliacion = 'SF'
                  OR TO_CHAR(b.BEN_FEC_AFILIACION, 'YYYY') = cp.v_anio_afiliacion
               )
               AND (
                  cp.v_dni_usuario = 'SF'
                  OR pb.PER_NUM_DOCUMENTO = cp.v_dni_usuario
               )
               AND (
                  cp.v_nombre_usuario = 'SF'
                  OR TRANSLATE(UPPER(pb.PER_NOMBRES || ' ' || pb.PER_PRIMER_APELLIDO || ' ' || pb.PER_SEGUNDO_APELLIDO), 'ÁÉÍÓÚ', 'AEIOU') LIKE '%' || cp.v_nombre_usuario || '%'
               )
               AND (
                  cp.v_dni_administrador = 'SF'
                  OR pa.PER_NUM_DOCUMENTO = cp.v_dni_administrador
               )
               AND (
                  cp.v_nombre_administrador = 'SF'
                  OR TRANSLATE(UPPER(pa.PER_NOMBRES || ' ' || pa.PER_PRIMER_APELLIDO || ' ' || pa.PER_SEGUNDO_APELLIDO), 'ÁÉÍÓÚ', 'AEIOU') LIKE '%' || cp.v_nombre_administrador || '%'
               )
         ), cte_filtrado AS (
            SELECT
               cb.*
            FROM cte_base cb
            CROSS JOIN cte_parametros cp
            WHERE
               cp.v_condicion = 'SF'
               OR (cp.v_condicion = '1' AND cb.CANT_BONOS <= 1)
               OR (cp.v_condicion = '2' AND cb.CANT_BONOS > 1 AND cb.BEN_RDE_REINCORPORACION IS NULL)
               OR (cp.v_condicion = '3' AND cb.CANT_BONOS > 1 AND cb.BEN_RDE_REINCORPORACION IS NOT NULL)
         )
         SELECT
            cf.DNI_USUARIO,
            cf.NOMBRE_COMPLETO_USUARIO,
            cf.SEXO_USUARIO,
            cf.FEC_NACIMIENTO_USUARIO,
            cf.UBIGEO_RESIDENCIA,
            cf.DIRECCION_RESIDENCIA,
            cf.FECHA_AFILIACION,
            cf.ESTADO,
            CASE
               WHEN cf.CANT_BONOS <= 1 THEN 'NUEVO'
               WHEN cf.CANT_BONOS > 1 AND cf.BEN_RDE_REINCORPORACION IS NULL THEN 'CONTINUADOR'
               WHEN cf.CANT_BONOS > 1 AND cf.BEN_RDE_REINCORPORACION IS NOT NULL THEN 'REINCORPORADO'
               ELSE ''
            END AS CONDICION,
            CASE
               WHEN cf.CANT_BONOS >= 3 THEN 'CUENTA CON 3 O MAS ASISTENCIAS ECONOMICAS RECIBIDAS'
               ELSE 'CUENTA CON MENOS DE 3 ASISTENCIAS ECONOMICAS RECIBIDAS'
            END AS NUMERO_PENSIONES,
            cf.DNI_ADMINISTRADOR,
            cf.NOMBRE_COMPLETO_ADMINISTRADOR,
            cf.PARENTESCO_ADMINISTRADOR,
            cf.SEXO_ADMINISTRADOR,
            cf.FEC_NACIMIENTO_ADMINISTRADOR,
            cf.PADRON_INICIO_AFILIACION,
            cf.PADRON_ULTIMO_AFILIACION,
            TO_CHAR(cf.FEC_MAX_VISITA, 'DD/MM/YYYY') AS ULTIMA_FECHA_VISITA,
            cf.RESULTADO_ULTIMA_VISITA,
            '' AS NIVEL_ESTUDIO,
            '' AS CENTRO_ESTUDIO,
            '' AS GRADO_ESTUDIO
         FROM cte_filtrado cf;

   ELSIF p_tipo = 'RPT_TODO' THEN
      OPEN p_resultado FOR
         WITH respuesta_unica AS (
         SELECT
            rv2.AR_ID_RESPUESTA,
            rv2.ID_ANEXO,
            rv2.ID_CENTRO,
            rv2.CORRELATIVO,
            rv2.AP_ID_PREGUNTA,
            rv2.AR_RESPUESTA,
            rv2.AR_RESPUESTA2,
            rv2.AR_FECHA_REGISTRA,
            ROW_NUMBER() OVER (
               PARTITION BY rv2.ID_ANEXO,
                           rv2.ID_CENTRO,
                           rv2.CORRELATIVO,
                           rv2.AP_ID_PREGUNTA
               ORDER BY rv2.AR_FECHA_REGISTRA DESC NULLS LAST,
                        rv2.AR_ID_RESPUESTA DESC
            ) AS rn
         FROM SSI_ANEXOS_RESPUESTAS_V2 rv2
         WHERE NVL(rv2.AR_ELIMINADO, 0) = 0
      )
      SELECT
         ac.ID_ANEXO_CABECERA                                                    AS ID,
         ac.PERIODO                                                              AS PERIODO,
         ac.TIPO                                                                 AS TIPO,
         NVL(anx.ANX_CODIGO2, anx.ANX_CODIGO)                                    AS CODIGO,
         anx.ANX_NOMBRE                                                          AS INSTRUMENTO,
         ac.CORRELATIVO                                                          AS CORRELATIVO,
         anx.ANX_UNIDAD_ORGANICA                                                 AS UNIDAD,
         anx.ANX_SERVICIO                                                        AS SERVICIO,
         ac.MODALIDAD                                                            AS PERFIL,
         NVL(ac.CENTRO, uor.UORNOMBRE)                                           AS CENTRO,
         dep.UBILOCALIDAD || ' / ' || prv.UBILOCALIDAD || ' / ' || dis.UBILOCALIDAD
                                                                                 AS DEPARTAMENTO_PROVINCIA_DISTRITO,
         TRIM(
            per_resp.PERNOMBRE || ' ' ||
            per_resp.PERAPEPATERNO || ' ' ||
            per_resp.PERAPEMATERNO
         )                                                                       AS RESPONSABLE_SUPERVISION,
         TRIM(
            per_dir.PERNOMBRE || ' ' ||
            per_dir.PERAPEPATERNO || ' ' ||
            per_dir.PERAPEMATERNO
         )                                                                       AS DIRECTOR_COORDINADOR,
         ac.FECHA_REGISTRO                                                       AS FECHA_DE_REGISTRO,
         ap.AP_PREGUNTA                                                          AS PREGUNTAS,
         ap.AP_PREGUNTA2                                                          AS PREGUNTAS2,
         ru.AR_RESPUESTA                                                         AS RESPUESTAS,
         ru.AR_RESPUESTA2                                                         AS RESPUESTAS2,

         -- ? Aux
         ap.AP_NUM_PREGUNTA                                                      AS NUMERO_PREGUNTA,
         ap.AP_NUM_GRUPO                                                         AS NUMERO_GRUPO,
         anx.ANX_CODIGO                                                          AS ANEXO
      FROM SSI_ANEXOS_CABECERA ac
      INNER JOIN SSI_ANEXO anx
         ON anx.ID_ANEXO = ac.ID_ANEXO
      LEFT JOIN TGUNIDADORGANICA uor
         ON uor.IDUNIDADORGANICA = ac.ID_CENTRO
      LEFT JOIN TGUBIGEO dep
         ON SUBSTR(uor.UOR_UBIGEO, 1, 2) || '0000' =
            dep.UBIDEPARTAMENTO || dep.UBIPROVINCIA || dep.UBIDISTRITO
      LEFT JOIN TGUBIGEO prv
         ON SUBSTR(uor.UOR_UBIGEO, 1, 4) || '00' =
            prv.UBIDEPARTAMENTO || prv.UBIPROVINCIA || prv.UBIDISTRITO
      LEFT JOIN TGUBIGEO dis
         ON SUBSTR(uor.UOR_UBIGEO, 1, 6) =
            dis.UBIDEPARTAMENTO || dis.UBIPROVINCIA || dis.UBIDISTRITO
      LEFT JOIN TRPERSONAL tp_dir
         ON tp_dir.IDPERSONAL = ac.ID_DIRECTOR
      LEFT JOIN TGPERSONA per_dir
         ON per_dir.IDPERSONA = tp_dir.PRHPERSONA
      LEFT JOIN TRPERSONAL tp_resp
         ON tp_resp.IDPERSONAL = ac.ID_RESP_SUPERVISION
      LEFT JOIN TGPERSONA per_resp
         ON per_resp.IDPERSONA = tp_resp.PRHPERSONA
      INNER JOIN SSI_ANEXOS_PREGUNTAS ap
         ON ap.AP_NUM_ANEXO = anx.ID_ANEXO
      INNER JOIN respuesta_unica ru
         ON ru.ID_ANEXO = ac.ID_ANEXO
         AND ru.ID_CENTRO = ac.ID_CENTRO
         AND ru.CORRELATIVO = ac.CORRELATIVO
         AND ru.AP_ID_PREGUNTA = ap.AP_ID_PREGUNTA
         AND ru.rn = 1
      WHERE 
         anx.ID_SERVICIO_PADRE = 4 -- * SIGES
         AND NVL(ac.ELIMINADO, 0) = 0
         AND NVL(anx.ANX_ELIMINADO, 0) = 0
         AND NVL(ap.AP_ELIMINADO, 0) = 0
         AND NVL(ap.AP_TIPO_CONTROL, 'NA') NOT IN ('cabecera', 'label')
      ORDER BY
         ac.ID_ANEXO_CABECERA,
         ap.AP_NUM_GRUPO,
         ap.AP_NUM_PREGUNTA;

   ELSE

      OPEN p_resultado FOR
         SELECT
            'TIPO_REPORTE_NO_VALIDO' AS CODIGO,
            'El parametro p_tipo debe ser RPT_ASISTENCIA_ECONOMICA o RPT_SIGEIR.' AS MENSAJE
         FROM DUAL
         WHERE 1 = 0;

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error en USP_GENERAR_REPORTES_SIGES: ' || SQLCODE || ' - ' || SQLERRM);
      RAISE;
END USP_GENERAR_REPORTES_SIGES;
/

-- ! COMMIT;

-- ? ROLLBACK;

-- * 1.1 Llamar al procedimiento almacenado: RPT_ASISTENCIA_ECONOMICA
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_GENERAR_REPORTES_SIGES('RPT_ASISTENCIA_ECONOMICA', '2026|SF|SF|CAR DE URGENCIA CASA ISABEL I', c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- * 1.2 Llamar al procedimiento almacenado: RPT_SIGEIR
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_GENERAR_REPORTES_SIGES('RPT_SIGEIR', '2025|SF|SF|SF|SF|1', c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- * 1.3 Llamar al procedimiento almacenado: RPT_TODO
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_GENERAR_REPORTES_SIGES('RPT_TODO', NULL, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ! COMMIT;



-- ! Test
/* 
   Consulta de solo lectura SIGEIF:
   Retorna cabecera + preguntas/respuestas del anexo,
   excluyendo preguntas con AP_TIPO_CONTROL = 'cabecera' o 'label'
*/
WITH respuesta_unica AS (
   SELECT
      rv2.AR_ID_RESPUESTA,
      rv2.ID_ANEXO,
      rv2.ID_CENTRO,
      rv2.CORRELATIVO,
      rv2.AP_ID_PREGUNTA,
      rv2.AR_RESPUESTA,
      rv2.AR_RESPUESTA2,
      rv2.AR_FECHA_REGISTRA,
      ROW_NUMBER() OVER (
         PARTITION BY rv2.ID_ANEXO,
                      rv2.ID_CENTRO,
                      rv2.CORRELATIVO,
                      rv2.AP_ID_PREGUNTA
         ORDER BY rv2.AR_FECHA_REGISTRA DESC NULLS LAST,
                  rv2.AR_ID_RESPUESTA DESC
      ) AS rn
   FROM SSI_ANEXOS_RESPUESTAS_V2 rv2
   WHERE NVL(rv2.AR_ELIMINADO, 0) = 0
)
SELECT
   ac.ID_ANEXO_CABECERA                                                    AS ID,
   ac.PERIODO                                                              AS PERIODO,
   ac.TIPO                                                                 AS TIPO,
   NVL(anx.ANX_CODIGO2, anx.ANX_CODIGO)                                    AS CODIGO,
   anx.ANX_NOMBRE                                                          AS INSTRUMENTO,
   ac.CORRELATIVO                                                          AS CORRELATIVO,
   anx.ANX_UNIDAD_ORGANICA                                                 AS UNIDAD,
   anx.ANX_SERVICIO                                                        AS SERVICIO,
   ac.MODALIDAD                                                            AS PERFIL,
   NVL(ac.CENTRO, uor.UORNOMBRE)                                           AS CENTRO,
   dep.UBILOCALIDAD || ' / ' || prv.UBILOCALIDAD || ' / ' || dis.UBILOCALIDAD
                                                                            AS DEPARTAMENTO_PROVINCIA_DISTRITO,
   TRIM(
      per_resp.PERNOMBRE || ' ' ||
      per_resp.PERAPEPATERNO || ' ' ||
      per_resp.PERAPEMATERNO
   )                                                                       AS RESPONSABLE_SUPERVISION,
   TRIM(
      per_dir.PERNOMBRE || ' ' ||
      per_dir.PERAPEPATERNO || ' ' ||
      per_dir.PERAPEMATERNO
   )                                                                       AS DIRECTOR_COORDINADOR,
   ac.FECHA_REGISTRO                                                       AS FECHA_DE_REGISTRO,
   ap.AP_PREGUNTA                                                          AS PREGUNTAS,
   ru.AR_RESPUESTA                                                         AS RESPUESTAS,

   -- ? Aux
   ap.AP_NUM_PREGUNTA                                                      AS NUMERO_PREGUNTA,
   anx.ANX_CODIGO                                                          AS ANEXO
FROM SSI_ANEXOS_CABECERA ac
INNER JOIN SSI_ANEXO anx
   ON anx.ID_ANEXO = ac.ID_ANEXO
LEFT JOIN TGUNIDADORGANICA uor
   ON uor.IDUNIDADORGANICA = ac.ID_CENTRO
LEFT JOIN TGUBIGEO dep
   ON SUBSTR(uor.UOR_UBIGEO, 1, 2) || '0000' =
      dep.UBIDEPARTAMENTO || dep.UBIPROVINCIA || dep.UBIDISTRITO
LEFT JOIN TGUBIGEO prv
   ON SUBSTR(uor.UOR_UBIGEO, 1, 4) || '00' =
      prv.UBIDEPARTAMENTO || prv.UBIPROVINCIA || prv.UBIDISTRITO
LEFT JOIN TGUBIGEO dis
   ON SUBSTR(uor.UOR_UBIGEO, 1, 6) =
      dis.UBIDEPARTAMENTO || dis.UBIPROVINCIA || dis.UBIDISTRITO
LEFT JOIN TRPERSONAL tp_dir
   ON tp_dir.IDPERSONAL = ac.ID_DIRECTOR
LEFT JOIN TGPERSONA per_dir
   ON per_dir.IDPERSONA = tp_dir.PRHPERSONA
LEFT JOIN TRPERSONAL tp_resp
   ON tp_resp.IDPERSONAL = ac.ID_RESP_SUPERVISION
LEFT JOIN TGPERSONA per_resp
   ON per_resp.IDPERSONA = tp_resp.PRHPERSONA
INNER JOIN SSI_ANEXOS_PREGUNTAS ap
   ON ap.AP_NUM_ANEXO = anx.ID_ANEXO
INNER JOIN respuesta_unica ru
   ON ru.ID_ANEXO = ac.ID_ANEXO
   AND ru.ID_CENTRO = ac.ID_CENTRO
   AND ru.CORRELATIVO = ac.CORRELATIVO
   AND ru.AP_ID_PREGUNTA = ap.AP_ID_PREGUNTA
   AND ru.rn = 1
WHERE NVL(ac.ELIMINADO, 0) = 0
  AND NVL(anx.ANX_ELIMINADO, 0) = 0
  AND NVL(ap.AP_ELIMINADO, 0) = 0
  AND NVL(ap.AP_TIPO_CONTROL, 'NA') NOT IN ('cabecera', 'label')
ORDER BY
   ac.ID_ANEXO_CABECERA,
   ap.AP_NUM_GRUPO,
   ap.AP_NUM_PREGUNTA;
/


SELECT * FROM SSI_ANEXOS_PREGUNTAS p
/

SELECT * FROM SSI_ANEXOS_CABECERA
/

SELECT * FROM SSI_ANEXO a
/

/*
ID	
Periodo	
Tipo	
Codigo	
Instrumento	
Correlativo	 
UNIDAD	 
SERVICIO	
PERFIL	 
CENTRO	
DEPARTAMENTO/PROVINCIA/DISTRITO	
RESPONSABLE SUPERVISIÓN	
DIRECTOR/COORDINADOR	
FECHA DE REGISTRO
*/

