-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_FFSIL_LISTAR
-- Proposito: Funcionamiento familiar FF-SIL, anexo 10 de PUNCHE (2).
-- Grano   : Una fila por (PF_ID_FAMILIA, SF_ID_FASE) con respuestas V1.
-- Plantilla: 10_funcionamiento_familiar_ffsil.xlsx, FUNC FAM(FFSIL),
--            encabezados fila 3, 24 columnas A-X; Hoja1 es auxiliar.
-- Parametros (firma identica a SP003):
--   p_fecha_ini IN DATE DEFAULT NULL: registro de alguna respuesta vigente.
--   p_fecha_fin IN DATE DEFAULT NULL: limite excluido p_fecha_fin + 1.
--      NULL abre cada extremo; no se truncan los parametros.
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 todas; otro valor filtra zona.
--   p_cursor_out OUT SYS_REFCURSOR: resultado A-X; fecha y respuestas texto.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-10-01
-- Alcance : Solo lectura, SELECT estatico, sin control transaccional.
-- =============================================================
-- CONTRATO / TRAZABILIDAD
-- * Sujeto confirmado: PF_ID_FAMILIA, nunca derivado de FI_ID_INTEGRANTE.
--   Latest = mayor AR_ID_RESPUESTA por familia/fase/pregunta, antes del
--   filtro temporal. AR_FECHA_REGISTRA no participa del ranking.
--   No se impone un filtro adicional por FI_ID_INTEGRANTE/destinatario:
--   PF_ID_FAMILIA presente es la identidad familiar expresamente acordada.
--   Fase NULL forma su propio grupo; no compite con fases conocidas.
-- * Una familia/fase se incluye si tiene alguna respuesta de las preguntas
--   proyectadas. No se inventan filas para familias/fases sin respuestas.
--   Cada pregunta puede provenir de una aplicacion distinta dentro de fase;
--   no se reconstruye una evaluacion indivisible. UPDATE puede conservar ID.
-- * Poblacion: familia SI_ID_SERVICIO=2 y PF_ELIMINADO=0; respuestas
--   AR_ELIMINADO=0; preguntas servicio2/anexo10 no eliminadas.
--   No se agregan filtros de estado de familia, zona, fase ni AN_ESTADO.
--   El servicio de zona no sustituye ni amplia el servicio de familia.
-- * Cuidador actual: FI_CUIDADOR=1, FI_ELIMINADO=0, datos estructurados.
--   Singularidad garantizada por usuario, no UNIQUE acreditado. Subconsultas
--   escalares conservan ausencia como NULL y hacen fallar duplicados con
--   ORA-01427 (posiblemente durante FETCH); no escogen menor ID ni ocultan
--   duplicados con MAX/DISTINCT. No reconstruccion historica del cuidador.
-- * Codigo familiar: LEFT JOIN a una fila por familia, servicio2,
--   CF_ESTADO=1, CF_ELIMINADO=0, FI_ID_INTEGRANTE NULL y tipos (0,1).
--   Tipo0 temporal / tipo1 principal familiar segun productor local
--   usps_ssi_inabif_v1.sql:1992-2105. Se excluyen codigos de integrantes.
--   Mayor CF_ID_CODIGO vigente, como consumidor local :2725-2737;
--   NO mayor fecha ni MAX textual. Si solo hay temporal, se conserva;
--   el principal lo reemplaza cuando es el de mayor ID vigente, conforme
--   a la secuencia de generacion local. No prioridad extra por tipo.
--   Ausencia => NULL; nunca fallback silencioso a PF_COD_FAMILIA.
-- * Salida A-H: NUMERO, ZONA_INTERV, COD_FAM, PRI_APE_USU, SEG_APE_USU,
--   NOM_USU, FASE (SF_NOMBRE), FEC_EVAL (932, salida VARCHAR2(10)
--   DD/MM/YYYY o NULL; TRIM ASCII y DD/MM/YYYY/ISO estrictos gregorianos).
--   Parser/DATE internos intactos; invalidos no cambian admision ni calculos.
--   I-V: 933 DEC_FAM, 934 ARM_CASA, 935 RESP_CASA, 936 CARINO,
--   937 EXPRES_CLAR, 938 SOBRE_DEF, 939 EXP_FAM, 940 AYUDA_FAM,
--   941 DISTR_TAREA, 942 COST_MODIF, 943 CONV_NO_TEMOR, 944 BUSCA_AYUDA,
--   945 INTER_RESP, 946 DEM_CAR. W=1480 PUNT_TOT; X=1479 DX_FUNC.
--   NUMERO y CARINO son los aliases ASCII de los encabezados N° y CARIÑO.
--   Decision expresa: items/puntaje/diagnostico tal cual AR_RESPUESTA;
--   sin traduccion, DECODE, normalizacion, conversion ni recalculo.
--   MAX(CASE) pivota solamente despues de RN_VALOR=1: no elige textos
--   entre respuestas competidoras. IDs y orden items: seed local
--   dml_insert_preguntas.sql:312-326 y evidencia XLSX comunicada por Build.
-- * Fecha932: formato estricto DD/MM/YYYY, 10 caracteres ASCII, sin TRIM.
--   Conversion gregoriana segura con CASE y dias desde DATE '0001-01-01',
--   precedente SP010; sin TO_DATE ni dependencia de NLS_DATE_FORMAT o
--   NLS_CALENDAR. TO_NUMBER usa mascara y NLS numerico explicitos.
--   Anios 0001-9999, meses/dias/bisiestos validados antes de sumar dias.
--   Conversion conservada, sin intervenir en el filtro exterior: este usa
--   AR_FECHA_REGISTRA de alguna respuesta vigente que cumple ambos extremos.
--   MAX de 0/1 transporta existencia, no fecha; no se exige932. Sin limites
--   admite registros NULL; con limites, NULL no admite por si solo el grupo.
--   Se conserva la ficha completa, sin recuperar respuestas antiguas.
--   >= p_fecha_ini y < p_fecha_fin+1; hora parametros preservada. Fecha
--   fisica conserva su hora. No validacion extra de rango:
--   inicio > fin aun puede devolver filas si inicio < fin+1.
--   p_fecha_fin+1 fuera del dominio DATE puede producir error de rango.
-- * Numeracion y orden: zona ID, familia ID, fase ID NULLS LAST.
-- JOINs inferidos (no FK/UNIQUE confirmadas por catalogo de columnas):
-- * ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA (N:1 esperado, confianza 95%),
--   piv.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (N:1 esperado, 95%),
--   pf.ZO_ID_ZONA=zi.ZO_ID_ZONA (0:1 por familia, 95%),
--   piv.SF_ID_FASE=af.SF_ID_FASE (0:1 por fila, 95%, mapeo usuario),
--   fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (0:1 cuidador, 95%),
--   cod.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (0:1 despues de ranking, 95%).
--   Evidencia: nombres/tipos NUMBER compatibles, consumidor local y
--   mapeos recibidos. No prueba integridad; se requiere unicidad IDs de
--   maestros y respuestas/codigos. Zona/fase/codigo ausentes preservados
--   por LEFT; filtro de zona activo exige zona enlazada como SP003.
-- RIESGOS / REVISION
-- * Posibles full scans en respuestas, codigos e integrantes; rankings,
--   pivote, OR-NULL, REGEXP y ordenamientos pueden aumentar costo.
--   No se verificaron indices, planes ni volumen. No se usan secuencias.
-- * Cursor vacio no lanza NO_DATA_FOUND. El caller consume/cierra el cursor
--   y maneja errores durante FETCH, fuera del EXCEPTION de OPEN.
-- * Revision exclusivamente estatica; no compilado ni ejecutado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_FFSIL_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE := 2;
   v_num_anexo SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE := 10;
   v_error_code NUMBER;
   v_error_message VARCHAR2(4000);
   v_diagnostico VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      WITH cte_resp AS (
         SELECT
            ar.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            ar.SF_ID_FASE AS SF_ID_FASE,
            ar.AP_ID_PREGUNTA AS AP_ID_PREGUNTA,
            ar.AR_RESPUESTA AS AR_RESPUESTA,
            ar.AR_FECHA_REGISTRA AS AR_FECHA_REGISTRA,
            ROW_NUMBER() OVER (
               PARTITION BY ar.PF_ID_FAMILIA, ar.SF_ID_FASE, ar.AP_ID_PREGUNTA
               ORDER BY ar.AR_ID_RESPUESTA DESC
            ) AS RN_VALOR
         FROM SSI_ANEXOS_RESPUESTAS ar
         WHERE ar.AR_ELIMINADO = 0
            AND ar.PF_ID_FAMILIA IS NOT NULL
            AND ar.AP_ID_PREGUNTA IN (
               932, 933, 934, 935, 936, 937, 938, 939, 940,
               941, 942, 943, 944, 945, 946, 1480, 1479
            )
            AND EXISTS (
               SELECT 1
               FROM SSI_ANEXOS_PREGUNTAS ap
               WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
                  AND ap.SI_ID_SERVICIO = v_id_servicio
                  AND ap.AP_NUM_ANEXO = v_num_anexo
                  AND NVL(ap.AP_ELIMINADO, 0) = 0
            )
      ), cte_piv AS (
         SELECT
            cr.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            cr.SF_ID_FASE AS SF_ID_FASE,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 932 THEN cr.AR_RESPUESTA END) AS FEC_EVAL,
            MAX(CASE WHEN (p_fecha_ini IS NULL OR cr.AR_FECHA_REGISTRA >= p_fecha_ini)
               AND (p_fecha_fin IS NULL OR cr.AR_FECHA_REGISTRA < p_fecha_fin + 1)
               THEN 1 ELSE 0 END) AS FILTRO_FECHA_CUMPLE,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 933 THEN cr.AR_RESPUESTA END) AS DEC_FAM,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 934 THEN cr.AR_RESPUESTA END) AS ARM_CASA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 935 THEN cr.AR_RESPUESTA END) AS RESP_CASA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 936 THEN cr.AR_RESPUESTA END) AS CARINO,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 937 THEN cr.AR_RESPUESTA END) AS EXPRES_CLAR,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 938 THEN cr.AR_RESPUESTA END) AS SOBRE_DEF,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 939 THEN cr.AR_RESPUESTA END) AS EXP_FAM,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 940 THEN cr.AR_RESPUESTA END) AS AYUDA_FAM,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 941 THEN cr.AR_RESPUESTA END) AS DISTR_TAREA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 942 THEN cr.AR_RESPUESTA END) AS COST_MODIF,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 943 THEN cr.AR_RESPUESTA END) AS CONV_NO_TEMOR,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 944 THEN cr.AR_RESPUESTA END) AS BUSCA_AYUDA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 945 THEN cr.AR_RESPUESTA END) AS INTER_RESP,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 946 THEN cr.AR_RESPUESTA END) AS DEM_CAR,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1479 THEN cr.AR_RESPUESTA END) AS PUNT_TOT,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1480 THEN cr.AR_RESPUESTA END) AS DX_FUNC

            /*
               PUNTAJE(Diagnostico) | CALIFICACIÓN(Puntaje Total)
               1479 | 1480
            */

         FROM cte_resp cr
         WHERE cr.RN_VALOR = 1
         GROUP BY cr.PF_ID_FAMILIA, cr.SF_ID_FASE
      ), cte_partes AS (
         SELECT
            piv.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            piv.SF_ID_FASE AS SF_ID_FASE,
            CASE
               WHEN LENGTH(piv.FEC_EVAL) = 10
                  AND REGEXP_LIKE(piv.FEC_EVAL, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FEC_EVAL, 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS ANIO,
            CASE
               WHEN LENGTH(piv.FEC_EVAL) = 10
                  AND REGEXP_LIKE(piv.FEC_EVAL, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FEC_EVAL, 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS MES,
            CASE
               WHEN LENGTH(piv.FEC_EVAL) = 10
                  AND REGEXP_LIKE(piv.FEC_EVAL, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FEC_EVAL, 1, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS DIA
         FROM cte_piv piv
      ), cte_calendario AS (
         SELECT
            par.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            par.SF_ID_FASE AS SF_ID_FASE,
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
            cal.SF_ID_FASE AS SF_ID_FASE,
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
            END AS FEC_EVAL_DATE
         FROM cte_calendario cal
      ), cte_cod AS (
         SELECT
            cf.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            cf.CF_CODIGO AS CF_CODIGO,
            ROW_NUMBER() OVER (
               PARTITION BY cf.PF_ID_FAMILIA
               ORDER BY cf.CF_ID_CODIGO DESC
            ) AS RN_CODIGO
         FROM SSI_CODIGOS_FAMILIAS cf
         WHERE cf.SI_ID_SERVICIO = v_id_servicio
            AND cf.PF_ID_FAMILIA IS NOT NULL
            AND cf.FI_ID_INTEGRANTE IS NULL
            AND cf.CF_TIPO_CODIGO IN (0, 1)
            AND cf.CF_ESTADO = 1
            AND cf.CF_ELIMINADO = 0
      )
      SELECT
         ROW_NUMBER() OVER (
            ORDER BY zi.ZO_ID_ZONA ASC NULLS LAST,
               piv.PF_ID_FAMILIA ASC, piv.SF_ID_FASE ASC NULLS LAST
         ) AS NUMERO,
         zi.ZO_DESCRIPCION AS ZONA_INTERV,
         cod.CF_CODIGO AS COD_FAM,
         (
            SELECT fi.FI_PRIMER_APE
            FROM SSI_FAMILIA_INTEGRANTES fi
            WHERE fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
               AND fi.FI_CUIDADOR = 1
               AND fi.FI_ELIMINADO = 0
         ) AS PRI_APE_USU,
         (
            SELECT fi.FI_SEGUNDO_APE
            FROM SSI_FAMILIA_INTEGRANTES fi
            WHERE fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
               AND fi.FI_CUIDADOR = 1
               AND fi.FI_ELIMINADO = 0
         ) AS SEG_APE_USU,
         (
            SELECT fi.FI_NOMBRES
            FROM SSI_FAMILIA_INTEGRANTES fi
            WHERE fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
               AND fi.FI_CUIDADOR = 1
               AND fi.FI_ELIMINADO = 0
         ) AS NOM_USU,
         af.SF_NOMBRE AS FASE,
         CAST(CASE
            WHEN LENGTH(TRIM(piv.FEC_EVAL)) = 10
               AND REGEXP_LIKE(TRIM(piv.FEC_EVAL), '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
            THEN CASE
               WHEN TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 9999
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 12
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 1, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND
                     CASE TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
                        WHEN 2 THEN 28 + CASE
                           WHEN MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 400) = 0
                              OR (MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 4) = 0
                                 AND MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 100) <> 0)
                           THEN 1 ELSE 0 END
                        WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30 ELSE 31 END
               THEN TRIM(piv.FEC_EVAL)
               ELSE NULL END
            WHEN LENGTH(TRIM(piv.FEC_EVAL)) = 10
               AND REGEXP_LIKE(TRIM(piv.FEC_EVAL), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', 'c')
            THEN CASE
               WHEN TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 9999
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 12
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 9, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND
                     CASE TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
                        WHEN 2 THEN 28 + CASE
                           WHEN MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 400) = 0
                              OR (MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 4) = 0
                                 AND MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_EVAL), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 100) <> 0)
                           THEN 1 ELSE 0 END
                        WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30 ELSE 31 END
               THEN SUBSTR(TRIM(piv.FEC_EVAL), 9, 2) || '/' || SUBSTR(TRIM(piv.FEC_EVAL), 6, 2) || '/' || SUBSTR(TRIM(piv.FEC_EVAL), 1, 4)
               ELSE NULL END
            ELSE NULL END AS VARCHAR2(10)) AS FEC_EVAL,
         piv.DEC_FAM AS DEC_FAM,
         piv.ARM_CASA AS ARM_CASA,
         piv.RESP_CASA AS RESP_CASA,
         piv.CARINO AS CARINO,
         piv.EXPRES_CLAR AS EXPRES_CLAR,
         piv.SOBRE_DEF AS SOBRE_DEF,
         piv.EXP_FAM AS EXP_FAM,
         piv.AYUDA_FAM AS AYUDA_FAM,
         piv.DISTR_TAREA AS DISTR_TAREA,
         piv.COST_MODIF AS COST_MODIF,
         piv.CONV_NO_TEMOR AS CONV_NO_TEMOR,
         piv.BUSCA_AYUDA AS BUSCA_AYUDA,
         piv.INTER_RESP AS INTER_RESP,
         piv.DEM_CAR AS DEM_CAR,
         piv.PUNT_TOT AS PUNT_TOT,
         piv.DX_FUNC AS DX_FUNC
      FROM cte_piv piv
      JOIN cte_fechas fec
         ON fec.PF_ID_FAMILIA = piv.PF_ID_FAMILIA
         AND (fec.SF_ID_FASE = piv.SF_ID_FASE
              OR (fec.SF_ID_FASE IS NULL AND piv.SF_ID_FASE IS NULL))
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = piv.PF_ID_FAMILIA
         AND pf.SI_ID_SERVICIO = v_id_servicio
      LEFT JOIN SSI_ZONA_INTERVENCION zi
         ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
      LEFT JOIN SSI_ANEXO_FASES af
         ON af.SF_ID_FASE = piv.SF_ID_FASE
      LEFT JOIN cte_cod cod
         ON cod.PF_ID_FAMILIA = piv.PF_ID_FAMILIA
         AND cod.RN_CODIGO = 1
      WHERE pf.PF_ELIMINADO = 0
         AND piv.FILTRO_FECHA_CUMPLE = 1
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
      ORDER BY zi.ZO_ID_ZONA ASC NULLS LAST,
         piv.PF_ID_FAMILIA ASC, piv.SF_ID_FASE ASC NULLS LAST;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'Error en PRC_PUNCHE_FFSIL_LISTAR ['
         || TO_CHAR(v_error_code) || ']: ' || v_error_message;
      -- Acotar en bytes sin partir caracteres multibyte; preservar pila.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_PUNCHE_FFSIL_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- Invocaciones MANUALES: NO EJECUTADAS, totalmente comentadas.
-- DBMS_SQL.RETURN_RESULT requiere Oracle 12c+ y cliente compatible con
-- resultados implicitos. Alternativamente consumir/cerrar el OUT desde
-- el caller, manejando tambien errores durante FETCH. No son tests.
-- =============================================================
-- Caso 1: todas las zonas, sin filtro de fecha (preserva invalidas/NULL).
DECLARE
   v_cursor SYS_REFCURSOR;
BEGIN
   PRC_PUNCHE_FFSIL_LISTAR(
      p_fecha_ini => DATE '2026-01-01',
      p_fecha_fin => DATE '2026-11-05',
      p_id_zona => 370, -- 370	[AYACUCHO]
      p_cursor_out => v_cursor
   );
   DBMS_SQL.RETURN_RESULT(v_cursor);
END;
/
-- Caso 2: dias completos con parametros a medianoche; zona NULL=todas.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_FFSIL_LISTAR(
--       p_fecha_ini => DATE '2026-01-01',
--       p_fecha_fin => DATE '2026-12-31',
--       p_id_zona => NULL,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 3: extremo final abierto; no se inventan IDs validos de zona.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_FFSIL_LISTAR(
--       p_fecha_ini => DATE '2026-01-01',
--       p_fecha_fin => NULL,
--       p_id_zona => -1, -- Sustituir por zona valida solo si se desea filtrar.
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 4: extremo inicial abierto.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_FFSIL_LISTAR(
--       p_fecha_ini => NULL,
--       p_fecha_fin => DATE '2026-12-31',
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
