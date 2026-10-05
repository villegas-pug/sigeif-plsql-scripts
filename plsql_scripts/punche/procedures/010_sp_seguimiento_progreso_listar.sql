-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_SEGUIMIENTO_PROGRESO_LISTAR
-- Proposito: Anexo 26 de PUNCHE, seguimiento del progreso familiar.
-- Grano   : Una fila por familia con ultimos valores globales POR pregunta.
-- Fuente  : 000_test.sql, bloque anexo26_seguimiento_progreso_pivote.
-- Plantilla: 26_reporte_seguimiento_progreso_familia_beneficiaria.xlsx,
--            hoja unica "Seguimiento del progreso", columnas A-O.
-- Parametros (mismo orden, tipos y defaults que SP 003):
--   p_fecha_ini IN DATE DEFAULT NULL: limite incluido sobre
--      AR_FECHA_REGISTRA de alguna respuesta vigente seleccionada.
--   p_fecha_fin IN DATE DEFAULT NULL: limite excluido p_fecha_fin + 1.
--      No se truncan parametros; NULL deja abierto el extremo respectivo.
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 todas; otro valor filtra zona.
--   p_cursor_out OUT SYS_REFCURSOR: 15 columnas; FECHA_EVALUACION es texto.
--      Salida final VARCHAR2(10) DD/MM/YYYY o NULL; TRIM ASCII y
--      DD/MM/YYYY/ISO estrictos gregorianos. Parser/DATE internos intactos,
--      incluidos sus formatos originales; no cambia admision ni calculos.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-10-01
-- Alcance : Solo lectura; SELECT estatico, sin control transaccional.
-- =============================================================
-- Contrato temporal confirmado:
-- * Latest global por (PF_ID_FAMILIA, AP_ID_PREGUNTA), antes del filtro.
--   AR_FECHA_REGISTRA DESC NULLS FIRST, AR_ID_RESPUESTA DESC: conserva
--   exactamente la prioridad de fechas NULL del ORDER BY fuente.
-- * Cada columna puede proceder de una evaluacion distinta. Los valores
--   de otras preguntas se conservan aunque su registro este fuera del rango.
-- * Admitir FAMILIA completa si alguna respuesta vigente cumple ambos extremos
--   sobre su AR_FECHA_REGISTRA; MAX de 0/1 transporta existencia, no fecha.
--   No se exige1324; sin limites se admiten tambien registros NULL.
--   Con algun limite, un registro NULL no admite por si solo la familia.
--   Nunca se recupera una respuesta anterior; texto invalido no decide filtro.
-- * Formato estricto: 10 caracteres ASCII, sin quitar espacios ni alterar
--   el texto. Validacion gregoriana (anios 0001-9999, meses y bisiestos).
-- * Conversion protegida en CASE, no dependiente del orden de predicados
--   WHERE ni de la materializacion de CTEs. Cada TO_NUMBER recibe solo
--   digitos validados, con mascara y NLS numerico explicitos. Fecha mediante
--   dias desde DATE '0001-01-01': sin TO_DATE, calendario NLS, conversion
--   implicita, VALIDATE_CONVERSION ni DEFAULT ON CONVERSION ERROR.
--   Precedente local: 005_sp_conductas_riesgo_listar.sql.
-- * >= p_fecha_ini y < p_fecha_fin + 1 SIN TRUNC de los parametros.
--   Se conserva la hora del registro fisico. No se valida rango invertido:
--   si inicio > fin pero inicio < fin + 1, aun puede haber resultados.
--   Los TRUNC numericos internos calculan dias de calendario, no limites.
-- Reglas preservadas y mapeos:
-- * Familia PUNCHE SI_ID_SERVICIO=2, PF_ELIMINADO=0; respuestas V1 con
--   AR_ELIMINADO=0, PF_ID_FAMILIA no NULL; preguntas anexo26 no eliminadas.
--   No se agregan filtros de estado, fase, destinatario ni sujeto individual.
-- * Cuidador FI_CUIDADOR=1, FI_ELIMINADO=0; menor FI_ID_INTEGRANTE segun
--   regla explicita del bloque fuente, no inferencia de principalidad.
--   Datos actuales del cuidador, no reconstruccion de su rol historico.
-- * Enriquecimientos LEFT conservan familias sin zona/cuidador/acompanante.
--   El filtro de zona activo excluye familias sin zona enlazada, como SP003.
-- * Codigo=SSI_CODIGOS_FAMILIAS.CF_CODIGO: SI_ID_SERVICIO=2,
--   CF_TIPO_CODIGO=1, CF_ESTADO=1, CF_ELIMINADO=0 e integrante NULL.
--   Mayor CF_ID_CODIGO elegible por PF_ID_FAMILIA, no fecha ni MAX textual.
--   Conjunto de una fila por familia; LEFT conserva codigo ausente como NULL,
--   sin sustitucion por codigo legado ni exclusion de la familia.
-- * A NUMERO; B zona; C codigo; D-F cuidador; G respuesta1324 texto;
--   H acompanante; I=1385; J=1329; K=1330; L=1331; M=1332; N=1334; O=1336.
--   M: plantilla "uso de libreta para organizar presupuesto familiar";
--   conserva el ID fuente 1332 y el alias CAP_ARTICULADA_1332.
-- * JOINs fuente, sin FK/UNIQUE documentadas en el catalogo: nombres,
--   semantica y tipos compatibles sustentan confianza estimada >=70%.
--   pf.PF_ID_FAMILIA=piv.PF_ID_FAMILIA (esperado 1:1);
--   zi.ZO_ID_ZONA=pf.ZO_ID_ZONA (esperado 0:1);
--   cui.PF_ID_FAMILIA=pf.PF_ID_FAMILIA y RN_CUIDADOR=1 (0:1);
--   cod.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (0:1 tras RN_CODIGO=1): relacion
--   inferida por nombres, tipos NUMBER compatibles y precedentes del plan
--   aprobado (confianza estimada >=70%), no FK catalogada. Origen esperado
--   0:N codigos por familia; la seleccion reduce a como maximo una fila.
--   per.IDPERSONAL=pf.PER_ID_PERSONAL (0:1),
--   pe.IDPERSONA=per.PRHPERSONA (0:1). Ausencias preservadas por LEFT.
--   ap.AP_ID_PREGUNTA=ar.AP_ID_PREGUNTA (esperado N:1).
--   Estas cardinalidades esperadas no prueban integridad real ni unicidad.
-- * Numeracion y orden: pf.ZO_ID_ZONA ASC NULLS LAST, pf.PF_ID_FAMILIA ASC.
--   Politica del plan aprobado: claves zona/familia, independiente del codigo
--   y de su ausencia; misma expresion en ROW_NUMBER y ORDER BY final.
-- Compatibilidad / riesgos:
-- * Nombre mayor de 30 bytes: Oracle 12.2+ y COMPATIBLE >=12.2, como
--   requisito documentado en SP008/009; version instalada NO verificada.
--   La conversion no introduce funciones exclusivas de esas versiones.
-- * Posibles full scans y ordenamientos en respuestas, integrantes y codigos;
--   OR-NULL y REGEXP pueden aumentar costo. No se verificaron indices/planes.
-- * Cursor vacio no lanza NO_DATA_FOUND. Errores durante FETCH corresponden
--   al consumidor, responsable de consumir/cerrar el cursor.
-- * Revision ESTATICA solamente: no compilado ni ejecutado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_SEGUIMIENTO_PROGRESO_LISTAR (
   p_fecha_ini IN DATE DEFAULT NULL,
   p_fecha_fin IN DATE DEFAULT NULL,
   p_id_zona IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE := 2;
   v_num_anexo SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE := 26;
   v_error_code NUMBER;
   v_error_message VARCHAR2(4000);
   v_diagnostico VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      WITH cte_resp AS (
         SELECT
            ar.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            ar.AP_ID_PREGUNTA AS AP_ID_PREGUNTA,
            ar.AR_RESPUESTA AS AR_RESPUESTA,
            ar.AR_FECHA_REGISTRA AS AR_FECHA_REGISTRA,
            ROW_NUMBER() OVER (
               PARTITION BY ar.PF_ID_FAMILIA, ar.AP_ID_PREGUNTA
               ORDER BY ar.AR_FECHA_REGISTRA DESC NULLS FIRST,
                  ar.AR_ID_RESPUESTA DESC
            ) AS RN_VALOR
         FROM SSI_ANEXOS_RESPUESTAS ar
         JOIN SSI_ANEXOS_PREGUNTAS ap
            ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         WHERE ap.SI_ID_SERVICIO = v_id_servicio
            AND ap.AP_NUM_ANEXO = v_num_anexo
            AND ap.AP_ID_PREGUNTA IN (1324, 1329, 1330, 1331, 1332, 1334, 1336, 1385)
            AND NVL(ap.AP_ELIMINADO, 0) = 0
            AND ar.AR_ELIMINADO = 0
            AND ar.PF_ID_FAMILIA IS NOT NULL
      ), cte_piv AS (
         SELECT
            cr.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1324 THEN cr.AR_RESPUESTA END) AS FECHA_EVALUACION,
            MAX(CASE WHEN (p_fecha_ini IS NULL OR cr.AR_FECHA_REGISTRA >= p_fecha_ini)
               AND (p_fecha_fin IS NULL OR cr.AR_FECHA_REGISTRA < p_fecha_fin + 1)
               THEN 1 ELSE 0 END) AS FILTRO_FECHA_CUMPLE,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1385 THEN cr.AR_RESPUESTA END) AS CUMPLIMIENTO_COMPROMISOS_OBJ_1_2,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1329 THEN cr.AR_RESPUESTA END) AS CAP_EMPRENDIMIENTO,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1330 THEN cr.AR_RESPUESTA END) AS CAP_EDUCACION_FINANCIERA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1331 THEN cr.AR_RESPUESTA END) AS CAP_ORIENTACION_LABORAL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1332 THEN cr.AR_RESPUESTA END) AS CAP_ARTICULADA_1332,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1334 THEN cr.AR_RESPUESTA END) AS USO_REDES_SOPORTE_LOCAL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1336 THEN cr.AR_RESPUESTA END) AS PARTICIPA_INCIDENCIA_COMUNITARIA
         FROM cte_resp cr
         WHERE cr.RN_VALOR = 1
         GROUP BY cr.PF_ID_FAMILIA
      ), cte_partes AS (
         SELECT
            piv.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            CASE
               WHEN LENGTH(piv.FECHA_EVALUACION) = 10
                  AND REGEXP_LIKE(piv.FECHA_EVALUACION, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FECHA_EVALUACION, 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS ANIO,
            CASE
               WHEN LENGTH(piv.FECHA_EVALUACION) = 10
                  AND REGEXP_LIKE(piv.FECHA_EVALUACION, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FECHA_EVALUACION, 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS MES,
            CASE
               WHEN LENGTH(piv.FECHA_EVALUACION) = 10
                  AND REGEXP_LIKE(piv.FECHA_EVALUACION, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FECHA_EVALUACION, 1, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS DIA
         FROM cte_piv piv
      ), cte_calendario AS (
         SELECT
            par.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            par.ANIO AS ANIO,
            par.MES AS MES,
            par.DIA AS DIA,
            CASE
               WHEN MOD(par.ANIO, 400) = 0
                  OR (MOD(par.ANIO, 4) = 0 AND MOD(par.ANIO, 100) <> 0)
               THEN 1
               ELSE 0
            END AS BISIESTO
         FROM cte_partes par
      ), cte_fechas AS (
         SELECT
            cal.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            CASE
               WHEN cal.ANIO BETWEEN 1 AND 9999
                  AND cal.MES BETWEEN 1 AND 12
                  AND cal.DIA BETWEEN 1 AND
                     CASE
                        WHEN cal.MES = 2 THEN 28 + cal.BISIESTO
                        WHEN cal.MES IN (4, 6, 9, 11) THEN 30
                        ELSE 31
                     END
               THEN DATE '0001-01-01'
                  + 365 * (cal.ANIO - 1)
                  + TRUNC((cal.ANIO - 1) / 4)
                  - TRUNC((cal.ANIO - 1) / 100)
                  + TRUNC((cal.ANIO - 1) / 400)
                  + CASE cal.MES
                     WHEN 1 THEN 0 WHEN 2 THEN 31 WHEN 3 THEN 59
                     WHEN 4 THEN 90 WHEN 5 THEN 120 WHEN 6 THEN 151
                     WHEN 7 THEN 181 WHEN 8 THEN 212 WHEN 9 THEN 243
                     WHEN 10 THEN 273 WHEN 11 THEN 304 WHEN 12 THEN 334
                    END
                  + CASE WHEN cal.MES > 2 THEN cal.BISIESTO ELSE 0 END
                  + cal.DIA - 1
            END AS FECHA_EVALUACION_DATE
         FROM cte_calendario cal
       ), cte_cod_rank AS (
          SELECT
             cf.PF_ID_FAMILIA AS PF_ID_FAMILIA,
             cf.CF_CODIGO AS CF_CODIGO,
             ROW_NUMBER() OVER (
                PARTITION BY cf.PF_ID_FAMILIA
                ORDER BY cf.CF_ID_CODIGO DESC
             ) AS RN_CODIGO
          FROM SSI_CODIGOS_FAMILIAS cf
          WHERE cf.SI_ID_SERVICIO = v_id_servicio
             AND cf.CF_TIPO_CODIGO = 1
             AND cf.CF_ESTADO = 1
             AND cf.CF_ELIMINADO = 0
             AND cf.FI_ID_INTEGRANTE IS NULL
       ), cte_cod AS (
          SELECT
             cfr.PF_ID_FAMILIA AS PF_ID_FAMILIA,
             cfr.CF_CODIGO AS CF_CODIGO
          FROM cte_cod_rank cfr
          WHERE cfr.RN_CODIGO = 1
       ), cte_cui AS (
         SELECT
            fi.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            fi.FI_PRIMER_APE AS FI_PRIMER_APE,
            fi.FI_SEGUNDO_APE AS FI_SEGUNDO_APE,
            fi.FI_NOMBRES AS FI_NOMBRES,
            ROW_NUMBER() OVER (
               PARTITION BY fi.PF_ID_FAMILIA
               ORDER BY fi.FI_ID_INTEGRANTE
            ) AS RN_CUIDADOR
         FROM SSI_FAMILIA_INTEGRANTES fi
         WHERE fi.FI_CUIDADOR = 1
            AND fi.FI_ELIMINADO = 0
      )
      SELECT
          ROW_NUMBER() OVER (ORDER BY pf.ZO_ID_ZONA ASC NULLS LAST, pf.PF_ID_FAMILIA ASC) AS NUMERO,
          zi.ZO_DESCRIPCION AS ZONA_INTERVENCION,
          cod.CF_CODIGO AS CODIGO_FAMILIA,
         cui.FI_PRIMER_APE AS PRIMER_APELLIDO,
         cui.FI_SEGUNDO_APE AS SEGUNDO_APELLIDO,
         cui.FI_NOMBRES AS NOMBRES,
         CAST(CASE
            WHEN LENGTH(TRIM(piv.FECHA_EVALUACION)) = 10
               AND REGEXP_LIKE(TRIM(piv.FECHA_EVALUACION), '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
            THEN CASE
               WHEN TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 9999
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 12
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 1, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND
                     CASE TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
                        WHEN 2 THEN 28 + CASE
                           WHEN MOD(TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 400) = 0
                              OR (MOD(TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 4) = 0
                                 AND MOD(TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 100) <> 0)
                           THEN 1 ELSE 0 END
                        WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30 ELSE 31 END
               THEN TRIM(piv.FECHA_EVALUACION)
               ELSE NULL END
            WHEN LENGTH(TRIM(piv.FECHA_EVALUACION)) = 10
               AND REGEXP_LIKE(TRIM(piv.FECHA_EVALUACION), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', 'c')
            THEN CASE
               WHEN TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 9999
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 12
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 9, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND
                     CASE TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
                        WHEN 2 THEN 28 + CASE
                           WHEN MOD(TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 400) = 0
                              OR (MOD(TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 4) = 0
                                 AND MOD(TO_NUMBER(SUBSTR(TRIM(piv.FECHA_EVALUACION), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 100) <> 0)
                           THEN 1 ELSE 0 END
                        WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30 ELSE 31 END
               THEN SUBSTR(TRIM(piv.FECHA_EVALUACION), 9, 2) || '/' || SUBSTR(TRIM(piv.FECHA_EVALUACION), 6, 2) || '/' || SUBSTR(TRIM(piv.FECHA_EVALUACION), 1, 4)
               ELSE NULL END
            ELSE NULL END AS VARCHAR2(10)) AS FECHA_EVALUACION,
         pe.PERNOMBRE || ' ' || pe.PERAPEPATERNO || ' ' || pe.PERAPEMATERNO AS ACOMPANANTE_FAMILIAR,
         piv.CUMPLIMIENTO_COMPROMISOS_OBJ_1_2 AS CUMPLIMIENTO_COMPROMISOS_OBJ_1_2,
         piv.CAP_EMPRENDIMIENTO AS CAP_EMPRENDIMIENTO,
         piv.CAP_EDUCACION_FINANCIERA AS CAP_EDUCACION_FINANCIERA,
         piv.CAP_ORIENTACION_LABORAL AS CAP_ORIENTACION_LABORAL,
         piv.CAP_ARTICULADA_1332 AS CAP_ARTICULADA_1332,
         piv.USO_REDES_SOPORTE_LOCAL AS USO_REDES_SOPORTE_LOCAL,
         piv.PARTICIPA_INCIDENCIA_COMUNITARIA AS PARTICIPA_INCIDENCIA_COMUNITARIA
      FROM cte_piv piv
      JOIN cte_fechas fec
         ON fec.PF_ID_FAMILIA = piv.PF_ID_FAMILIA
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = piv.PF_ID_FAMILIA
         AND pf.SI_ID_SERVICIO = v_id_servicio
       LEFT JOIN SSI_ZONA_INTERVENCION zi
          ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
       LEFT JOIN cte_cod cod
          ON cod.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
      LEFT JOIN cte_cui cui
         ON cui.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         AND cui.RN_CUIDADOR = 1
      LEFT JOIN TRPERSONAL per
         ON per.IDPERSONAL = pf.PER_ID_PERSONAL
      LEFT JOIN TGPERSONA pe
         ON pe.IDPERSONA = per.PRHPERSONA
      WHERE pf.PF_ELIMINADO = 0
         AND piv.FILTRO_FECHA_CUMPLE = 1
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
       ORDER BY pf.ZO_ID_ZONA ASC NULLS LAST, pf.PF_ID_FAMILIA ASC;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'Error en PRC_PUNCHE_SEGUIMIENTO_PROGRESO_LISTAR ['
         || TO_CHAR(v_error_code) || ']: ' || v_error_message;
      -- Acotar en bytes sin partir caracteres multibyte; preservar pila.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_PUNCHE_SEGUIMIENTO_PROGRESO_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- Invocaciones MANUALES separadas: NO EJECUTADAS, totalmente comentadas.
-- DBMS_SQL.RETURN_RESULT requiere Oracle 12c+ y cliente con soporte de
-- resultados implicitos (por ejemplo SQLcl o SQL*Plus compatible).
-- El nombre de este SP requiere ademas 12.2+ y COMPATIBLE >=12.2.
-- Sin ese soporte del cliente, obtener el OUT y consumir/cerrar el cursor
-- desde el caller. Un error de FETCH debe gestionarse alli.
-- =============================================================
-- Caso 1: sin filtros, incluye fechas de evaluacion ausentes/invalidas.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_SEGUIMIENTO_PROGRESO_LISTAR(
--       p_fecha_ini => NULL,
--       p_fecha_fin => NULL,
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 2: rango con argumentos a medianoche, dias completos incluidos.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_SEGUIMIENTO_PROGRESO_LISTAR(
--       p_fecha_ini => DATE '2026-01-01',
--       p_fecha_fin => DATE '2026-12-31',
--       p_id_zona => NULL,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 3: extremo final abierto; alguna respuesta vigente debe cumplir inicio.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_SEGUIMIENTO_PROGRESO_LISTAR(
--       p_fecha_ini => DATE '2026-01-01',
--       p_fecha_fin => NULL,
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 4: extremo inicial abierto; sin inventar IDs validos de zona.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_SEGUIMIENTO_PROGRESO_LISTAR(
--       p_fecha_ini => NULL,
--       p_fecha_fin => DATE '2026-12-31',
--       p_id_zona => -1, -- Sustituir manualmente por un ID valido si aplica.
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
