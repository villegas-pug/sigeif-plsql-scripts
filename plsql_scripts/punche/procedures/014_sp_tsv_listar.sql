-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_TSV_LISTAR
-- Proposito: Anexo 11 TSV familiar de PUNCHE (servicio 2), respuestas V1.
-- Grano   : Una fila por (PF_ID_FAMILIA, SF_ID_FASE) con cuidador presente.
-- Plantilla: 11_tsv.xlsx, unica hoja TSV; 51 columnas reales A-AY.
--            Fila 2: encabezados; fila 3: etiquetas, excepto G3='Pre'.
-- Parametros (firma identica a SP003, mismo orden/tipos/defaults):
--   p_fecha_ini IN DATE DEFAULT NULL: registro de alguna respuesta vigente.
--   p_fecha_fin IN DATE DEFAULT NULL: fin excluido p_fecha_fin + 1.
--      NULL abre cada extremo; se preservan horas, sin TRUNC.
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 todas; otro valor filtra zona.
--   p_cursor_out OUT SYS_REFCURSOR: columnas A-AY, respuestas/fecha texto.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-10-01
-- Alcance : Solo lectura, SELECT estatico, sin control transaccional.
-- =============================================================
-- CONTRATO / TRAZABILIDAD
-- * Sujeto: PF_ID_FAMILIA, nunca derivado de FI_ID_INTEGRANTE. No se
--   impone filtro extra de destinatario/integrante a respuestas familiares.
--   Fuente: SSI_ANEXOS_RESPUESTAS (V1); nunca se mezcla con V2.
-- * Latest confirmado: mayor AR_ID_RESPUESTA por familia/fase/pregunta,
--   ANTES de filtros temporales. AR_FECHA_REGISTRA no ordena el ranking.
--   SF_ID_FASE NULL forma un grupo propio, enlazado con igualdad null-safe.
--   Solo se crean filas para familia/fase con alguna respuesta proyectada;
--   no se exige completitud de items ni se inventan aplicaciones.
--   Cada pregunta puede venir de una aplicacion distinta dentro de fase.
-- * Poblacion minima inferida y aceptada: familia SI_ID_SERVICIO=2,
--   PF_ELIMINADO=0; respuestas AR_ELIMINADO=0; preguntas servicio2/anexo11,
--   NVL(AP_ELIMINADO,0)=0. No filtros extra de estado, aptitud, AN_ESTADO,
--   estado de zona/fase, ni defensa OR entre servicio de familia y zona.
-- * Cuidador actual: FI_CUIDADOR=1 y FI_ELIMINADO=0. Usuario garantiza uno
--   por familia; NO hay UNIQUE acreditado por catalogo. EXISTS excluye
--   familias sin cuidador; subconsultas escalares de datos estructurados
--   hacen fallar duplicados con ORA-01427 (posiblemente durante FETCH).
--   No seleccion arbitraria, MAX, DISTINCT ni reconstruccion historica.
-- * Codigo actual: LEFT JOIN a una fila por familia, servicio2, tipos (0,1),
--   FI_ID_INTEGRANTE NULL, CF_ESTADO=1, CF_ELIMINADO=0, mayor CF_ID_CODIGO.
--   Inferencia sustentada en productor local usps_ssi_inabif_v1.sql:
--   1992-2105 (tipo0 temporal / tipo1 principal familiar) y consumidor:
--   2725-2737 (mayor ID vigente). No politica universal, prioridad extra
--   por tipo, mayor fecha ni MAX textual; ausencia => NULL sin fallback
--   a PF_COD_FAMILIA. Ranking previo al JOIN evita multiplicar filas.
-- * Mapeo A-H: NUMERO, ZONA_INTERV, COD_FAM, PRI_APE_USU, SEG_APE_USU,
--   NOM_USU, ETAPA (SF_NOMBRE, no constante 'Pre'), FEC_EVAL (4332).
--   A usa alias ASCII NUMERO para numeracion; G usa ETAPA del encabezado G2.
-- * I-S: 953 DES_HOG, 954 ENTR_RELAC, 955 MUJER_TRAB, 956 ING_VARON,
--   957 MUJ_GRIT, 958 CUMP_ROL, 959 APR_PAC, 960 CORRESP_TAREAS,
--   961 VARON_ORDEN, 962 JEFE_HOG, 963 DES_IMP.
--   T-AF: 964 EXPR_INSULT, 965 GOLP_MAL, 966 CAST_JUST, 967 FALT_RESP,
--   968 REPR_ESP, 969 VAR_MAD, 970 SIEMP_ESP, 971 CONTR_ESP, 972 DISP_REL,
--   973 PERM_ESP, 974 MUJ_CED, 975 AMIST_APROB, 976 PREG_INGR.
--   AG-AQ: 977 MUJ_SUM, 978 VAR_DOM, 979 PUB_PROD, 980 MUJ_PER,
--   981 DER_FUER, 982 INF_CAST, 983 MUJ_DESC, 984 PAR_VI, 985 CAM_COND,
--   986 VAR_CEL, 987 VEST_PROV.
--   AR-AY: 1483 PJ_1, 1667 DIM_1, 1484 PJ_2, 1668 DIM_2,
--   1485 PJ_3, 1669 DIM_3, 1481 PUNT_TOTAL, 1482 NIVEL_GENERAL.
-- * Evidencia IDs: items en dml_insert_preguntas.sql:333-367 y XLSX local
--   py_notebooks/data/SSI_ANEXOS_PREGUNTAS.xlsx; resultados en ese XLSX.
--   4332 es mapeo EXPRESO DEL USUARIO, no corroborado por seed/XLSX local.
--   No sustituir IDs por antiguos 988/991-993; salida fecha4332 textual.
-- * Salida final fecha4332: VARCHAR2(10) DD/MM/YYYY o NULL; TRIM ASCII,
--   DD/MM/YYYY/ISO estrictos gregorianos. Parser/DATE internos intactos;
--   invalidos/ausentes no cambian admision ni calculos.
-- * Las demas respuestas y resultados: AR_RESPUESTA tal cual, sin TRIM,
--   traduccion, conversion numerica, recalculo ni uso de AR_PUNTAJE.
--   MAX(CASE) solo pivota DESPUES de RN_VALOR=1, no elige textos latest.
-- * Direccion, distrito, instrucciones y adjunto NO existen en plantilla:
--   no se proyectan, no JOIN de ubigeo, no pregunta1001 como fila base.
-- * Fecha4332: DD/MM/YYYY estricto, 10 caracteres ASCII, sin TRIM.
--   CASE valida formato, anios 0001-9999, meses, dias y bisiestos antes
--   de formar DATE gregoriano por dias desde DATE '0001-01-01'.
--   Sin TO_DATE, NLS_DATE_FORMAT ni NLS_CALENDAR; TO_NUMBER con mascara
--   y NLS numerico explicitos, solo sobre digitos ya validados.
--   Sin limites: conservar fila aunque fecha ausente/NULL/invalida.
--   Filtro de ficha completa: alguna respuesta vigente cumple ambos extremos
--   sobre AR_FECHA_REGISTRA; MAX de 0/1 transporta existencia, no fecha.
--   No se exige4332; conversion conservada sin filtrar. Con limites, un
--   registro NULL no admite por si solo la evaluacion.
--   No recuperar una fecha anterior; solo normalizar fecha en SELECT final.
-- * Limites confirmados: >= p_fecha_ini y < p_fecha_fin+1, sin truncar.
--   Se conserva la hora del registro fisico. No nueva validacion
--   de rango: inicio>fin puede retornar filas si inicio<fin+1.
--   p_fecha_fin+1 fuera del dominio DATE puede producir error de rango.
-- * Orden/numeracion: zona ID, familia ID, fase ID, NULLS LAST.
-- JOINs INFERIDOS (no FK ni UNIQUE confirmadas por catalogo de columnas):
-- * ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA: N:1 esperado, confianza 95%;
--   se implementa EXISTS para validar pregunta sin multiplicar respuestas.
-- * piv.PF_ID_FAMILIA=pf.PF_ID_FAMILIA: N:1 esperado, 95%, familia requerida.
-- * pf.ZO_ID_ZONA=zi.ZO_ID_ZONA: 0:1 por familia, 95%, LEFT preserva ausencia;
--   filtro de zona especifica exige coincidencia; NULL/-1 no restringe.
-- * piv.SF_ID_FASE=af.SF_ID_FASE: 0:1 por fila, 95%, LEFT preserva ausencia.
-- * fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA: 1 cuidador por familia incluida, 95%.
-- * cod.PF_ID_FAMILIA=pf.PF_ID_FAMILIA: 0:1 despues de ranking, 95%, LEFT.
--   Evidencia: nombres/tipos NUMBER compatibles, mapeos y productor/
--   consumidor local. Confianza no prueba integridad: unicidad de IDs de
--   maestros/respuestas/codigos es requisito esperado, no constraint probado.
-- RIESGOS / REVISION
-- * Posibles full scans de respuestas, codigos e integrantes; rankings,
--   pivote, REGEXP, OR-NULL, escalares de cuidador y ordenamientos aumentan
--   costo. No indices, planes ni volumen verificados; no usa secuencias.
-- * Cursor vacio no lanza NO_DATA_FOUND. Caller debe consumir/cerrar OUT
--   y manejar errores durante FETCH, fuera del EXCEPTION de OPEN.
-- * Revision exclusivamente estatica; NO compilado ni ejecutado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_TSV_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE := 2;
   v_num_anexo SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE := 11;
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
               4332, 953, 954, 955, 956, 957, 958, 959, 960, 961, 962, 963,
               964, 965, 966, 967, 968, 969, 970, 971, 972, 973, 974, 975, 976,
               977, 978, 979, 980, 981, 982, 983, 984, 985, 986, 987,
               1483, 1667, 1484, 1668, 1485, 1669, 1481, 1482
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
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 4332 THEN cr.AR_RESPUESTA END) AS FEC_EVAL,
            MAX(CASE WHEN (p_fecha_ini IS NULL OR cr.AR_FECHA_REGISTRA >= p_fecha_ini)
               AND (p_fecha_fin IS NULL OR cr.AR_FECHA_REGISTRA < p_fecha_fin + 1)
               THEN 1 ELSE 0 END) AS FILTRO_FECHA_CUMPLE,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 953 THEN cr.AR_RESPUESTA END) AS DES_HOG,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 954 THEN cr.AR_RESPUESTA END) AS ENTR_RELAC,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 955 THEN cr.AR_RESPUESTA END) AS MUJER_TRAB,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 956 THEN cr.AR_RESPUESTA END) AS ING_VARON,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 957 THEN cr.AR_RESPUESTA END) AS MUJ_GRIT,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 958 THEN cr.AR_RESPUESTA END) AS CUMP_ROL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 959 THEN cr.AR_RESPUESTA END) AS APR_PAC,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 960 THEN cr.AR_RESPUESTA END) AS CORRESP_TAREAS,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 961 THEN cr.AR_RESPUESTA END) AS VARON_ORDEN,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 962 THEN cr.AR_RESPUESTA END) AS JEFE_HOG,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 963 THEN cr.AR_RESPUESTA END) AS DES_IMP,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 964 THEN cr.AR_RESPUESTA END) AS EXPR_INSULT,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 965 THEN cr.AR_RESPUESTA END) AS GOLP_MAL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 966 THEN cr.AR_RESPUESTA END) AS CAST_JUST,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 967 THEN cr.AR_RESPUESTA END) AS FALT_RESP,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 968 THEN cr.AR_RESPUESTA END) AS REPR_ESP,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 969 THEN cr.AR_RESPUESTA END) AS VAR_MAD,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 970 THEN cr.AR_RESPUESTA END) AS SIEMP_ESP,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 971 THEN cr.AR_RESPUESTA END) AS CONTR_ESP,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 972 THEN cr.AR_RESPUESTA END) AS DISP_REL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 973 THEN cr.AR_RESPUESTA END) AS PERM_ESP,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 974 THEN cr.AR_RESPUESTA END) AS MUJ_CED,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 975 THEN cr.AR_RESPUESTA END) AS AMIST_APROB,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 976 THEN cr.AR_RESPUESTA END) AS PREG_INGR,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 977 THEN cr.AR_RESPUESTA END) AS MUJ_SUM,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 978 THEN cr.AR_RESPUESTA END) AS VAR_DOM,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 979 THEN cr.AR_RESPUESTA END) AS PUB_PROD,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 980 THEN cr.AR_RESPUESTA END) AS MUJ_PER,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 981 THEN cr.AR_RESPUESTA END) AS DER_FUER,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 982 THEN cr.AR_RESPUESTA END) AS INF_CAST,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 983 THEN cr.AR_RESPUESTA END) AS MUJ_DESC,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 984 THEN cr.AR_RESPUESTA END) AS PAR_VI,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 985 THEN cr.AR_RESPUESTA END) AS CAM_COND,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 986 THEN cr.AR_RESPUESTA END) AS VAR_CEL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 987 THEN cr.AR_RESPUESTA END) AS VEST_PROV,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1483 THEN cr.AR_RESPUESTA END) AS PJ_1,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1667 THEN cr.AR_RESPUESTA END) AS DIM_1,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1484 THEN cr.AR_RESPUESTA END) AS PJ_2,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1668 THEN cr.AR_RESPUESTA END) AS DIM_2,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1485 THEN cr.AR_RESPUESTA END) AS PJ_3,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1669 THEN cr.AR_RESPUESTA END) AS DIM_3,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1481 THEN cr.AR_RESPUESTA END) AS PUNT_TOTAL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1482 THEN cr.AR_RESPUESTA END) AS NIVEL_GENERAL
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
      ), cte_cuidador AS (
         SELECT
            fi.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            fi.FI_PRIMER_APE AS FI_PRIMER_APE,
            fi.FI_SEGUNDO_APE AS FI_SEGUNDO_APE,
            fi.FI_NOMBRES AS FI_NOMBRES
         FROM SSI_FAMILIA_INTEGRANTES fi
         WHERE fi.FI_CUIDADOR = 1
            AND fi.FI_ELIMINADO = 0
      )
      SELECT
         ROW_NUMBER() OVER (
            ORDER BY zi.ZO_ID_ZONA ASC NULLS LAST,
               piv.PF_ID_FAMILIA ASC, piv.SF_ID_FASE ASC NULLS LAST
         ) AS NUMERO,
         zi.ZO_DESCRIPCION AS ZONA_INTERV,
         cod.CF_CODIGO AS COD_FAM,
         (
            SELECT cui.FI_PRIMER_APE
            FROM cte_cuidador cui
            WHERE cui.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         ) AS PRI_APE_USU,
         (
            SELECT cui.FI_SEGUNDO_APE
            FROM cte_cuidador cui
            WHERE cui.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         ) AS SEG_APE_USU,
         (
            SELECT cui.FI_NOMBRES
            FROM cte_cuidador cui
            WHERE cui.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         ) AS NOM_USU,
         af.SF_NOMBRE AS ETAPA,
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
         piv.DES_HOG AS DES_HOG,
         piv.ENTR_RELAC AS ENTR_RELAC,
         piv.MUJER_TRAB AS MUJER_TRAB,
         piv.ING_VARON AS ING_VARON,
         piv.MUJ_GRIT AS MUJ_GRIT,
         piv.CUMP_ROL AS CUMP_ROL,
         piv.APR_PAC AS APR_PAC,
         piv.CORRESP_TAREAS AS CORRESP_TAREAS,
         piv.VARON_ORDEN AS VARON_ORDEN,
         piv.JEFE_HOG AS JEFE_HOG,
         piv.DES_IMP AS DES_IMP,
         piv.EXPR_INSULT AS EXPR_INSULT,
         piv.GOLP_MAL AS GOLP_MAL,
         piv.CAST_JUST AS CAST_JUST,
         piv.FALT_RESP AS FALT_RESP,
         piv.REPR_ESP AS REPR_ESP,
         piv.VAR_MAD AS VAR_MAD,
         piv.SIEMP_ESP AS SIEMP_ESP,
         piv.CONTR_ESP AS CONTR_ESP,
         piv.DISP_REL AS DISP_REL,
         piv.PERM_ESP AS PERM_ESP,
         piv.MUJ_CED AS MUJ_CED,
         piv.AMIST_APROB AS AMIST_APROB,
         piv.PREG_INGR AS PREG_INGR,
         piv.MUJ_SUM AS MUJ_SUM,
         piv.VAR_DOM AS VAR_DOM,
         piv.PUB_PROD AS PUB_PROD,
         piv.MUJ_PER AS MUJ_PER,
         piv.DER_FUER AS DER_FUER,
         piv.INF_CAST AS INF_CAST,
         piv.MUJ_DESC AS MUJ_DESC,
         piv.PAR_VI AS PAR_VI,
         piv.CAM_COND AS CAM_COND,
         piv.VAR_CEL AS VAR_CEL,
         piv.VEST_PROV AS VEST_PROV,
         piv.PJ_1 AS PJ_1,
         piv.DIM_1 AS DIM_1,
         piv.PJ_2 AS PJ_2,
         piv.DIM_2 AS DIM_2,
         piv.PJ_3 AS PJ_3,
         piv.DIM_3 AS DIM_3,
         piv.PUNT_TOTAL AS PUNT_TOTAL,
         piv.NIVEL_GENERAL AS NIVEL_GENERAL
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
         AND EXISTS (
            SELECT 1
            FROM cte_cuidador cui
            WHERE cui.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         )
         AND piv.FILTRO_FECHA_CUMPLE = 1
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
      ORDER BY zi.ZO_ID_ZONA ASC NULLS LAST,
         piv.PF_ID_FAMILIA ASC, piv.SF_ID_FASE ASC NULLS LAST;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'Error en PRC_PUNCHE_TSV_LISTAR ['
         || TO_CHAR(v_error_code) || ']: ' || v_error_message;
      -- Acotar en bytes sin partir caracteres multibyte; preservar pila.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_PUNCHE_TSV_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- Invocaciones MANUALES: NO EJECUTADAS, totalmente comentadas.
-- DBMS_SQL.RETURN_RESULT requiere Oracle 12c+ y cliente compatible con
-- resultados implicitos. Alternativamente consumir/cerrar el OUT desde
-- el caller, manejando tambien errores durante FETCH. No son tests.
-- =============================================================
-- Caso 1: todas las zonas, sin fechas; conserva fechas invalidas/NULL.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_TSV_LISTAR(
--       p_fecha_ini => NULL,
--       p_fecha_fin => NULL,
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 2: dias completos con parametros a medianoche; zona NULL=todas.
-- Requiere alguna respuesta vigente en rango; no recupera respuestas anteriores.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_TSV_LISTAR(
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
--    PRC_PUNCHE_TSV_LISTAR(
--       p_fecha_ini => DATE '2026-01-01',
--       p_fecha_fin => NULL,
--       p_id_zona => -1, -- Sustituir por zona valida si se desea filtrar.
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 4: extremo inicial abierto.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_TSV_LISTAR(
--       p_fecha_ini => NULL,
--       p_fecha_fin => DATE '2026-12-31',
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
