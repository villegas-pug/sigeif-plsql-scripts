-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_DIAGNOSTICO_FAMILIAR_LISTAR
-- Proposito: Diagnostico familiar vigente, Anexo 9 de PUNCHE (2).
-- Grano   : Una ficha vigente por (PF_ID_FAMILIA, SF_ID_FASE),
--           repetida por cada cuidador actual no eliminado. Sin
--           cuidador se conserva una fila con D-F NULL.
-- Plantilla: punche/inputs/reports/templates/9_diagnostico_familiar.xlsx,
--            hoja unica DIAG FAM, encabezados fila 5, A-BY EXCEPTO BU.
-- Parametros (misma firma, orden y defaults que SP003):
--   p_fecha_ini IN DATE DEFAULT NULL: registro de alguna respuesta vigente.
--   p_fecha_fin IN DATE DEFAULT NULL: fin excluido p_fecha_fin + 1.
--      Extremos NULL abiertos; no se truncan las horas de parametros.
--      Ambos informados e inicio > fin: cursor vacio por contrato.
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 todas; otro valor exacto.
--   p_cursor_out OUT SYS_REFCURSOR: 76 columnas, texto persistido salvo
--      NRO (NUMBER) y enriquecimientos con sus tipos originales.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-10-01
-- Alcance : Solo lectura; SELECT estatico, sin efectos transaccionales.
-- =============================================================
-- CONTRATO CONFIRMADO Y EVIDENCIA LOCAL
-- * Plantilla revalidada localmente: DIAG FAM, 77 encabezados A-BY.
--   BU PUNTAJE MAXIMO se OMITE por decision expresa: ni NULL ni calculo.
--   Las cuatro columnas BV-BY pasan a posiciones 73-76 del cursor.
--   No agregar aptitud1539, adjunto926, observaciones ni riesgos por bloque.
-- * Fuente V1 SSI_ANEXOS_RESPUESTAS. El usuario confirma UNA ficha vigente
--   por familia/etapa que el productor ACTUALIZA, no aplicaciones separadas.
--   Coherencia es contrato del productor, NO garantia comprobada en datos.
--   No reconstruir historicos, aplicaciones por dia ni lotes por ID.
-- * Si existen duplicados de una pregunta de la ficha vigente, se selecciona
--   la ultima escritura: NVL(AR_FECHA_MODIFICA, AR_FECHA_REGISTRA) DESC
--   NULLS LAST, AR_ID_RESPUESTA DESC como desempate determinista.
--   Evidencia: usps_ssi_inabif_v1.sql:1647-1687 inserta respuestas y actualiza
--   el mismo ID con AR_FECHA_MODIFICA. El ID no se interpreta como fecha;
--   si ambas fechas faltan, sirve solo de desempate estable. No se buscan
--   respuestas anteriores para sustituir un valor vigente NULL/invalido.
--   Particion: familia/fase/pregunta. Fase NULL forma su propio grupo.
--   Esta resolucion de duplicados NO recupera aplicaciones historicas.
-- * PF_ID_FAMILIA es autoridad expresa, sin filtrar FI_ID_INTEGRANTE ni
--   AR_DESTINATARIO y sin derivar familia desde FI. No fusionar familias.
--   Solo grupos con alguna respuesta proyectada; sin fichas artificiales.
-- * Poblacion: familia SI_ID_SERVICIO=2, PF_ELIMINADO=0; respuestas
--   AR_ELIMINADO=0, familia no NULL; preguntas servicio2/anexo9 con
--   NVL(AP_ELIMINADO,0)=0. EXISTS evita multiplicar por el lookup pregunta.
--   Sin filtros de estado activo, aptitud, aprobacion, egreso ni AN_ESTADO.
--   Servicio de zona no sustituye al de familia mediante OR.
-- * Cuidador actual: FI_CUIDADOR=1 y FI_ELIMINADO=0, sin FI_ESTADO adicional.
--   LEFT JOIN: 0 cuidadores => una fila D-F NULL; 1 => una fila; N => N filas
--   por ficha, autorizadas. No elegir principal por ID, MAX o DISTINCT.
--   Los puntajes se repiten por cuidador: no sumar filas como familias unicas.
-- * Codigo actual: SSI_CODIGOS_FAMILIAS, servicio2, tipos0/1, integrante NULL,
--   CF_ESTADO=1 y CF_ELIMINADO=0; mayor CF_ID_CODIGO vigente por familia.
--   Productor usps_ssi_inabif_v1.sql:1992-2105: temporal0, principal familiar1;
--   consumidor :2725-2737: mayor ID vigente. Precedente SP012 FFSIL.
--   LEFT JOIN tras ranking => ausencia NULL, sin MAX textual ni PF legacy.
-- * Nombres estructurados FI_PRIMER_APE/FI_SEGUNDO_APE/FI_NOMBRES (SP009/012).
--   Zona/fase/codigo ausentes se preservan; no reconstruccion historica de
--   cuidadores, nombres, codigo o zona. Filtro de zona activo exige enlace.
-- * IDs recibidos son autoritativos del productor actual. Seed local
--   dml_insert_preguntas.sql:116,152-297,448-477 aporta evidencia de anexo9,
--   pero no acredita valores ni despliegue real en Oracle.
--   Se conserva AC=498 (no499). Resumen BJ-BT=1493..1502,1477.
-- * Prevalencia EXPRESA del mapeo actual pese al seed :468-474:
--   BV porcentaje proteccion=1666, BW diagnostico proteccion=1665,
--   BX porcentaje riesgo=1664, BY diagnostico riesgo=1503.
--   No invertir estos IDs ni recalcular con las formulas Excel.
-- * Items/puntajes/porcentajes/diagnosticos permanecen AR_RESPUESTA
--   VARCHAR2(4000), sin traduccion ni conversion. Fecha442 final:
--   VARCHAR2(10) DD/MM/YYYY o NULL; TRIM ASCII, DD/MM/YYYY/ISO estrictos
--   gregorianos. Parser/DATE internos intactos; admision/calculos sin cambio.
--   MAX(CASE) es solo pivote DESPUES de RN_VALOR=1, no maximo arbitrario.
-- * Fecha442: DD/MM/YYYY estricto, 10 caracteres ASCII, sin TRIM. Se valida
--   calendario gregoriano (anios0001-9999, meses, dias y bisiestos). Cada
--   conversion numerica esta protegida en CASE con mascara y NLS explicito.
--   DATE interno mediante dias desde DATE '0001-01-01', precedente SP010/012:
--   evita errores de conversion y dependencia de NLS_DATE_FORMAT/CALENDAR.
--   Conversion conservada, sin filtrar: el filtro exterior usa el registro
--   fisico de alguna respuesta vigente que cumple ambos extremos.
--   MAX de 0/1 transporta existencia, no fecha; no se exige442. Sin limites
--   admite registros NULL; con limites, NULL no admite por si solo el grupo.
--   Se conserva la ficha completa, sin filtro temporal por item.
-- * >= inicio y < fin+1 SIN TRUNC; se conserva la hora del registro fisico.
--   Rango invertido => vacio por decision expresa,
--   incluso si inicio < fin+1 (esa validacion no existe en SP003).
--   Zona desconocida => vacio; sin validacion EXISTS de parametros.
-- MAPEO POSICIONAL (los comentarios del SELECT indican columna XLSX)
-- * 01-08 A-H: NRO, ZONA_INTERV, COD_FAM, PRI_APE_USU, SEG_APE_USU,
--   NOM_USU, ETAPA, FEC_APLICACION.
-- * 09-61 I-BI: PREGUNTA_01..53, exactamente en orden de encabezados:
--   I-P 1..8=476..483; Q-W 9..15=485..491;
--   X-AE 16..23=493,494,495,496,497,498,500,501;
--   AF-AH 24..26=502..504; AI-AL 27..30=506..509;
--   AM-AS 31..37=511..517; AT-AW 38..41=519..522;
--   AX-BC 42..47=524..529; BD-BF 48..50=531..533; BG-BI 51..53=535..537.
-- * 62-71 BJ-BS: puntajes cuidado/formadora/afectiva/socializadora/economia/
--   pareja/parentales/familia/libre violencia/promocion derechos=1493..1502.
-- * 72 BT: PUNT_TOTAL=1477; BU omitida; 73-76 BV-BY: PCT_PROTECCION,
--   DIAG_PROTECCION, PCT_RIESGO, DIAG_RIESGO=1666,1665,1664,1503.
-- * Aliases ASCII cortos; no usar textos extensos de preguntas como IDs SQL.
-- INFERENCIAS DE JOIN (NO FK/UNIQUE CONFIRMADAS)
-- * Respuesta/pregunta AP_ID_PREGUNTA (N:1 esperado, confianza95%; EXISTS).
-- * piv.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (N:1,95%; INNER excluye familia
--   ausente/no elegible); pf.ZO_ID_ZONA=zi.ZO_ID_ZONA (N:0..1,95%; LEFT).
-- * piv.SF_ID_FASE=af.SF_ID_FASE (N:0..1,95%; LEFT); union de fecha interna
--   por familia/fase con igualdad NULL-safe (1:1, por agrupacion).
-- * fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (1:0..N cuidadores,95%; LEFT).
-- * cod.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (1:0..1 tras ranking,95%; LEFT).
--   Evidencia: catalogo de columnas, tipos NUMBER compatibles, mapeos del
--   usuario y precedentes citados. Porcentajes no prueban integridad real.
-- RIESGOS / REVISION
-- * IDs de respuestas/familias/zonas/fases/codigos/integrantes deben ser
--   unicos para cardinalidad/orden esperados; catalogo no acredita constraints.
--   Duplicados de maestros pueden multiplicar filas, sin ocultarse con DISTINCT.
-- * Coherencia vigente depende del productor confirmado; no puede comprobarse
--   ni reconstruirse una aplicacion con una clave inexistente en V1.
-- * Posibles full scans, rankings, pivote, OR-NULL, REGEXP y ordenamientos.
--   Indices/planes/volumen no verificados. No se usan secuencias.
-- * p_fecha_fin+1 fuera del dominio DATE puede producir error de rango.
-- * Nombre >30 bytes: soporte de identificadores largos confirmado por usuario
--   (Oracle12.2+ y compatibilidad adecuada), no comprobado mediante conexion.
-- * Cursor vacio no lanza NO_DATA_FOUND; caller consume/cierra y maneja FETCH.
--   EXCEPTION cubre errores del OPEN; diagnostico <=2048 BYTES, conserva pila.
-- * Revision exclusivamente estatica; no ejecutado ni compilado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_DIAGNOSTICO_FAMILIAR_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE := 2;
   v_num_anexo SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE := 9;
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
               ORDER BY NVL(ar.AR_FECHA_MODIFICA, ar.AR_FECHA_REGISTRA)
                  DESC NULLS LAST, ar.AR_ID_RESPUESTA DESC
            ) AS RN_VALOR
         FROM SSI_ANEXOS_RESPUESTAS ar
         WHERE ar.AR_ELIMINADO = 0
            AND ar.PF_ID_FAMILIA IS NOT NULL
            AND ar.AP_ID_PREGUNTA IN (
               442, 476, 477, 478, 479, 480, 481, 482, 483,
               485, 486, 487, 488, 489, 490, 491,
               493, 494, 495, 496, 497, 498, 500, 501,
               502, 503, 504, 506, 507, 508, 509,
               511, 512, 513, 514, 515, 516, 517,
               519, 520, 521, 522, 524, 525, 526, 527, 528, 529,
               531, 532, 533, 535, 536, 537,
               1493, 1494, 1495, 1496, 1497, 1498, 1499, 1500, 1501, 1502,
               1477, 1666, 1665, 1664, 1503
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
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 442 THEN cr.AR_RESPUESTA END) AS FEC_APLICACION,
            MAX(CASE WHEN (p_fecha_ini IS NULL OR cr.AR_FECHA_REGISTRA >= p_fecha_ini)
               AND (p_fecha_fin IS NULL OR cr.AR_FECHA_REGISTRA < p_fecha_fin + 1)
               THEN 1 ELSE 0 END) AS FILTRO_FECHA_CUMPLE,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 476 THEN cr.AR_RESPUESTA END) AS PREGUNTA_01,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 477 THEN cr.AR_RESPUESTA END) AS PREGUNTA_02,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 478 THEN cr.AR_RESPUESTA END) AS PREGUNTA_03,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 479 THEN cr.AR_RESPUESTA END) AS PREGUNTA_04,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 480 THEN cr.AR_RESPUESTA END) AS PREGUNTA_05,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 481 THEN cr.AR_RESPUESTA END) AS PREGUNTA_06,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 482 THEN cr.AR_RESPUESTA END) AS PREGUNTA_07,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 483 THEN cr.AR_RESPUESTA END) AS PREGUNTA_08,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 485 THEN cr.AR_RESPUESTA END) AS PREGUNTA_09,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 486 THEN cr.AR_RESPUESTA END) AS PREGUNTA_10,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 487 THEN cr.AR_RESPUESTA END) AS PREGUNTA_11,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 488 THEN cr.AR_RESPUESTA END) AS PREGUNTA_12,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 489 THEN cr.AR_RESPUESTA END) AS PREGUNTA_13,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 490 THEN cr.AR_RESPUESTA END) AS PREGUNTA_14,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 491 THEN cr.AR_RESPUESTA END) AS PREGUNTA_15,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 493 THEN cr.AR_RESPUESTA END) AS PREGUNTA_16,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 494 THEN cr.AR_RESPUESTA END) AS PREGUNTA_17,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 495 THEN cr.AR_RESPUESTA END) AS PREGUNTA_18,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 496 THEN cr.AR_RESPUESTA END) AS PREGUNTA_19,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 497 THEN cr.AR_RESPUESTA END) AS PREGUNTA_20,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 498 THEN cr.AR_RESPUESTA END) AS PREGUNTA_21,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 500 THEN cr.AR_RESPUESTA END) AS PREGUNTA_22,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 501 THEN cr.AR_RESPUESTA END) AS PREGUNTA_23,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 502 THEN cr.AR_RESPUESTA END) AS PREGUNTA_24,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 503 THEN cr.AR_RESPUESTA END) AS PREGUNTA_25,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 504 THEN cr.AR_RESPUESTA END) AS PREGUNTA_26,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 506 THEN cr.AR_RESPUESTA END) AS PREGUNTA_27,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 507 THEN cr.AR_RESPUESTA END) AS PREGUNTA_28,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 508 THEN cr.AR_RESPUESTA END) AS PREGUNTA_29,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 509 THEN cr.AR_RESPUESTA END) AS PREGUNTA_30,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 511 THEN cr.AR_RESPUESTA END) AS PREGUNTA_31,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 512 THEN cr.AR_RESPUESTA END) AS PREGUNTA_32,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 513 THEN cr.AR_RESPUESTA END) AS PREGUNTA_33,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 514 THEN cr.AR_RESPUESTA END) AS PREGUNTA_34,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 515 THEN cr.AR_RESPUESTA END) AS PREGUNTA_35,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 516 THEN cr.AR_RESPUESTA END) AS PREGUNTA_36,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 517 THEN cr.AR_RESPUESTA END) AS PREGUNTA_37,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 519 THEN cr.AR_RESPUESTA END) AS PREGUNTA_38,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 520 THEN cr.AR_RESPUESTA END) AS PREGUNTA_39,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 521 THEN cr.AR_RESPUESTA END) AS PREGUNTA_40,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 522 THEN cr.AR_RESPUESTA END) AS PREGUNTA_41,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 524 THEN cr.AR_RESPUESTA END) AS PREGUNTA_42,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 525 THEN cr.AR_RESPUESTA END) AS PREGUNTA_43,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 526 THEN cr.AR_RESPUESTA END) AS PREGUNTA_44,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 527 THEN cr.AR_RESPUESTA END) AS PREGUNTA_45,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 528 THEN cr.AR_RESPUESTA END) AS PREGUNTA_46,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 529 THEN cr.AR_RESPUESTA END) AS PREGUNTA_47,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 531 THEN cr.AR_RESPUESTA END) AS PREGUNTA_48,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 532 THEN cr.AR_RESPUESTA END) AS PREGUNTA_49,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 533 THEN cr.AR_RESPUESTA END) AS PREGUNTA_50,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 535 THEN cr.AR_RESPUESTA END) AS PREGUNTA_51,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 536 THEN cr.AR_RESPUESTA END) AS PREGUNTA_52,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 537 THEN cr.AR_RESPUESTA END) AS PREGUNTA_53,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1493 THEN cr.AR_RESPUESTA END) AS PUNT_CUIDADO,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1494 THEN cr.AR_RESPUESTA END) AS PUNT_FORMADORA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1495 THEN cr.AR_RESPUESTA END) AS PUNT_AFECTIVA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1496 THEN cr.AR_RESPUESTA END) AS PUNT_SOCIALIZADORA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1497 THEN cr.AR_RESPUESTA END) AS PUNT_ECONOMICA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1498 THEN cr.AR_RESPUESTA END) AS PUNT_PAREJA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1499 THEN cr.AR_RESPUESTA END) AS PUNT_PARENTAL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1500 THEN cr.AR_RESPUESTA END) AS PUNT_REL_FAMILIA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1501 THEN cr.AR_RESPUESTA END) AS PUNT_LIBRE_VIOLENCIA,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1502 THEN cr.AR_RESPUESTA END) AS PUNT_PROM_DERECHOS,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1477 THEN cr.AR_RESPUESTA END) AS PUNT_TOTAL,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1666 THEN cr.AR_RESPUESTA END) AS PCT_PROTECCION,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1665 THEN cr.AR_RESPUESTA END) AS DIAG_PROTECCION,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1664 THEN cr.AR_RESPUESTA END) AS PCT_RIESGO,
            MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1503 THEN cr.AR_RESPUESTA END) AS DIAG_RIESGO
         FROM cte_resp cr
         WHERE cr.RN_VALOR = 1
         GROUP BY cr.PF_ID_FAMILIA, cr.SF_ID_FASE
      ), cte_partes AS (
         SELECT
            piv.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            piv.SF_ID_FASE AS SF_ID_FASE,
            CASE
               WHEN LENGTH(piv.FEC_APLICACION) = 10
                  AND REGEXP_LIKE(piv.FEC_APLICACION, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FEC_APLICACION, 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS ANIO,
            CASE
               WHEN LENGTH(piv.FEC_APLICACION) = 10
                  AND REGEXP_LIKE(piv.FEC_APLICACION, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FEC_APLICACION, 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS MES,
            CASE
               WHEN LENGTH(piv.FEC_APLICACION) = 10
                  AND REGEXP_LIKE(piv.FEC_APLICACION, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN TO_NUMBER(SUBSTR(piv.FEC_APLICACION, 1, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
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
            END AS FEC_APLICACION_DATE
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
               piv.PF_ID_FAMILIA ASC, piv.SF_ID_FASE ASC NULLS LAST,
               fi.FI_ID_INTEGRANTE ASC NULLS LAST
         ) AS NRO,                                      -- 01 A
         zi.ZO_DESCRIPCION AS ZONA_INTERV,                -- 02 B
         cod.CF_CODIGO AS COD_FAM,                        -- 03 C
         fi.FI_PRIMER_APE AS PRI_APE_USU,                 -- 04 D
         fi.FI_SEGUNDO_APE AS SEG_APE_USU,                -- 05 E
         fi.FI_NOMBRES AS NOM_USU,                        -- 06 F
         af.SF_NOMBRE AS ETAPA,                          -- 07 G
         CAST(CASE
            WHEN LENGTH(TRIM(piv.FEC_APLICACION)) = 10
               AND REGEXP_LIKE(TRIM(piv.FEC_APLICACION), '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
            THEN CASE
               WHEN TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 9999
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 12
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 1, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND
                     CASE TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
                        WHEN 2 THEN 28 + CASE
                           WHEN MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 400) = 0
                              OR (MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 4) = 0
                                 AND MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 100) <> 0)
                           THEN 1 ELSE 0 END
                        WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30 ELSE 31 END
               THEN TRIM(piv.FEC_APLICACION)
               ELSE NULL END
            WHEN LENGTH(TRIM(piv.FEC_APLICACION)) = 10
               AND REGEXP_LIKE(TRIM(piv.FEC_APLICACION), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', 'c')
            THEN CASE
               WHEN TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 9999
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 12
                  AND TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 9, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND
                     CASE TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
                        WHEN 2 THEN 28 + CASE
                           WHEN MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 400) = 0
                              OR (MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 4) = 0
                                 AND MOD(TO_NUMBER(SUBSTR(TRIM(piv.FEC_APLICACION), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 100) <> 0)
                           THEN 1 ELSE 0 END
                        WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30 ELSE 31 END
               THEN SUBSTR(TRIM(piv.FEC_APLICACION), 9, 2) || '/' || SUBSTR(TRIM(piv.FEC_APLICACION), 6, 2) || '/' || SUBSTR(TRIM(piv.FEC_APLICACION), 1, 4)
               ELSE NULL END
            ELSE NULL END AS VARCHAR2(10)) AS FEC_APLICACION,            -- 08 H
         piv.PREGUNTA_01 AS PREGUNTA_01,                  -- 09 I
         piv.PREGUNTA_02 AS PREGUNTA_02,                  -- 10 J
         piv.PREGUNTA_03 AS PREGUNTA_03,                  -- 11 K
         piv.PREGUNTA_04 AS PREGUNTA_04,                  -- 12 L
         piv.PREGUNTA_05 AS PREGUNTA_05,                  -- 13 M
         piv.PREGUNTA_06 AS PREGUNTA_06,                  -- 14 N
         piv.PREGUNTA_07 AS PREGUNTA_07,                  -- 15 O
         piv.PREGUNTA_08 AS PREGUNTA_08,                  -- 16 P
         piv.PREGUNTA_09 AS PREGUNTA_09,                  -- 17 Q
         piv.PREGUNTA_10 AS PREGUNTA_10,                  -- 18 R
         piv.PREGUNTA_11 AS PREGUNTA_11,                  -- 19 S
         piv.PREGUNTA_12 AS PREGUNTA_12,                  -- 20 T
         piv.PREGUNTA_13 AS PREGUNTA_13,                  -- 21 U
         piv.PREGUNTA_14 AS PREGUNTA_14,                  -- 22 V
         piv.PREGUNTA_15 AS PREGUNTA_15,                  -- 23 W
         piv.PREGUNTA_16 AS PREGUNTA_16,                  -- 24 X
         piv.PREGUNTA_17 AS PREGUNTA_17,                  -- 25 Y
         piv.PREGUNTA_18 AS PREGUNTA_18,                  -- 26 Z
         piv.PREGUNTA_19 AS PREGUNTA_19,                  -- 27 AA
         piv.PREGUNTA_20 AS PREGUNTA_20,                  -- 28 AB
         piv.PREGUNTA_21 AS PREGUNTA_21,                  -- 29 AC
         piv.PREGUNTA_22 AS PREGUNTA_22,                  -- 30 AD
         piv.PREGUNTA_23 AS PREGUNTA_23,                  -- 31 AE
         piv.PREGUNTA_24 AS PREGUNTA_24,                  -- 32 AF
         piv.PREGUNTA_25 AS PREGUNTA_25,                  -- 33 AG
         piv.PREGUNTA_26 AS PREGUNTA_26,                  -- 34 AH
         piv.PREGUNTA_27 AS PREGUNTA_27,                  -- 35 AI
         piv.PREGUNTA_28 AS PREGUNTA_28,                  -- 36 AJ
         piv.PREGUNTA_29 AS PREGUNTA_29,                  -- 37 AK
         piv.PREGUNTA_30 AS PREGUNTA_30,                  -- 38 AL
         piv.PREGUNTA_31 AS PREGUNTA_31,                  -- 39 AM
         piv.PREGUNTA_32 AS PREGUNTA_32,                  -- 40 AN
         piv.PREGUNTA_33 AS PREGUNTA_33,                  -- 41 AO
         piv.PREGUNTA_34 AS PREGUNTA_34,                  -- 42 AP
         piv.PREGUNTA_35 AS PREGUNTA_35,                  -- 43 AQ
         piv.PREGUNTA_36 AS PREGUNTA_36,                  -- 44 AR
         piv.PREGUNTA_37 AS PREGUNTA_37,                  -- 45 AS
         piv.PREGUNTA_38 AS PREGUNTA_38,                  -- 46 AT
         piv.PREGUNTA_39 AS PREGUNTA_39,                  -- 47 AU
         piv.PREGUNTA_40 AS PREGUNTA_40,                  -- 48 AV
         piv.PREGUNTA_41 AS PREGUNTA_41,                  -- 49 AW
         piv.PREGUNTA_42 AS PREGUNTA_42,                  -- 50 AX
         piv.PREGUNTA_43 AS PREGUNTA_43,                  -- 51 AY
         piv.PREGUNTA_44 AS PREGUNTA_44,                  -- 52 AZ
         piv.PREGUNTA_45 AS PREGUNTA_45,                  -- 53 BA
         piv.PREGUNTA_46 AS PREGUNTA_46,                  -- 54 BB
         piv.PREGUNTA_47 AS PREGUNTA_47,                  -- 55 BC
         piv.PREGUNTA_48 AS PREGUNTA_48,                  -- 56 BD
         piv.PREGUNTA_49 AS PREGUNTA_49,                  -- 57 BE
         piv.PREGUNTA_50 AS PREGUNTA_50,                  -- 58 BF
         piv.PREGUNTA_51 AS PREGUNTA_51,                  -- 59 BG
         piv.PREGUNTA_52 AS PREGUNTA_52,                  -- 60 BH
         piv.PREGUNTA_53 AS PREGUNTA_53,                  -- 61 BI
         piv.PUNT_CUIDADO AS PUNT_CUIDADO,                -- 62 BJ
         piv.PUNT_FORMADORA AS PUNT_FORMADORA,            -- 63 BK
         piv.PUNT_AFECTIVA AS PUNT_AFECTIVA,              -- 64 BL
         piv.PUNT_SOCIALIZADORA AS PUNT_SOCIALIZADORA,    -- 65 BM
         piv.PUNT_ECONOMICA AS PUNT_ECONOMICA,            -- 66 BN
         piv.PUNT_PAREJA AS PUNT_PAREJA,                  -- 67 BO
         piv.PUNT_PARENTAL AS PUNT_PARENTAL,              -- 68 BP
         piv.PUNT_REL_FAMILIA AS PUNT_REL_FAMILIA,        -- 69 BQ
         piv.PUNT_LIBRE_VIOLENCIA AS PUNT_LIBRE_VIOLENCIA, -- 70 BR
         piv.PUNT_PROM_DERECHOS AS PUNT_PROM_DERECHOS,    -- 71 BS
         piv.PUNT_TOTAL AS PUNT_TOTAL,                  -- 72 BT
         piv.PCT_PROTECCION AS PCT_PROTECCION,            -- 73 BV (BU omitida)
         piv.DIAG_PROTECCION AS DIAG_PROTECCION,          -- 74 BW
         piv.PCT_RIESGO AS PCT_RIESGO,                    -- 75 BX
         piv.DIAG_RIESGO AS DIAG_RIESGO                  -- 76 BY
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
         ON cod.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         AND cod.RN_CODIGO = 1
      LEFT JOIN SSI_FAMILIA_INTEGRANTES fi
         ON fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         AND fi.FI_CUIDADOR = 1
         AND fi.FI_ELIMINADO = 0
      WHERE pf.PF_ELIMINADO = 0
         AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL OR p_fecha_ini <= p_fecha_fin)
         AND piv.FILTRO_FECHA_CUMPLE = 1
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
      ORDER BY zi.ZO_ID_ZONA ASC NULLS LAST,
         piv.PF_ID_FAMILIA ASC, piv.SF_ID_FASE ASC NULLS LAST,
         fi.FI_ID_INTEGRANTE ASC NULLS LAST;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'Error en PRC_PUNCHE_DIAGNOSTICO_FAMILIAR_LISTAR ['
         || TO_CHAR(v_error_code, 'FM9999999990') || ']: ' || v_error_message;
      -- Recortar caracteres completos hasta cumplir limite de 2048 BYTES.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_PUNCHE_DIAGNOSTICO_FAMILIAR_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- INVOCACIONES MANUALES SEPARADAS: COMENTADAS, NO EJECUTADAS
-- Solo documentacion; no habilitan ejecucion Oracle en este flujo.
-- DBMS_SQL.RETURN_RESULT requiere cliente con resultados implicitos;
-- alternativamente obtener OUT desde caller y consumir/cerrar el cursor.
-- Errores durante FETCH corresponden al consumidor. No son tests.
-- Sin IDs ficticios: -1/NULL todas; sustituir solo por una zona conocida.
-- =============================================================

-- Caso 1: sin filtros; fechas ausentes/invalidas dan NULL sin excluir fila.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
--    v_error_code NUMBER;
--    v_error_message VARCHAR2(4000);
-- BEGIN
--    PRC_PUNCHE_DIAGNOSTICO_FAMILIAR_LISTAR(
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- EXCEPTION
--    WHEN OTHERS THEN
--       v_error_code := SQLCODE;
--       v_error_message := SQLERRM;
--       IF v_cursor%ISOPEN THEN
--          CLOSE v_cursor;
--       END IF;
--       RAISE;
-- END;
-- /

-- Caso 2: dias completos con argumentos a medianoche; todas las zonas.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
--    v_error_code NUMBER;
--    v_error_message VARCHAR2(4000);
-- BEGIN
--    PRC_PUNCHE_DIAGNOSTICO_FAMILIAR_LISTAR(
--       p_fecha_ini => DATE '2026-09-01',
--       p_fecha_fin => DATE '2026-09-30',
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- EXCEPTION
--    WHEN OTHERS THEN
--       v_error_code := SQLCODE;
--       v_error_message := SQLERRM;
--       IF v_cursor%ISOPEN THEN
--          CLOSE v_cursor;
--       END IF;
--       RAISE;
-- END;
-- /

-- Caso 3: extremo final abierto, zona NULL equivale a todas.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
--    v_error_code NUMBER;
--    v_error_message VARCHAR2(4000);
-- BEGIN
--    PRC_PUNCHE_DIAGNOSTICO_FAMILIAR_LISTAR(
--       p_fecha_ini => DATE '2026-01-01',
--       p_fecha_fin => NULL,
--       p_id_zona => NULL,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- EXCEPTION
--    WHEN OTHERS THEN
--       v_error_code := SQLCODE;
--       v_error_message := SQLERRM;
--       IF v_cursor%ISOPEN THEN
--          CLOSE v_cursor;
--       END IF;
--       RAISE;
-- END;
-- /

-- Caso 4: extremo inicial abierto; alguna respuesta vigente debe cumplir fin.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
--    v_error_code NUMBER;
--    v_error_message VARCHAR2(4000);
-- BEGIN
--    PRC_PUNCHE_DIAGNOSTICO_FAMILIAR_LISTAR(
--       p_fecha_ini => NULL,
--       p_fecha_fin => DATE '2026-09-30',
--       p_id_zona => -1, -- Sustituir manualmente si se desea una zona conocida.
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- EXCEPTION
--    WHEN OTHERS THEN
--       v_error_code := SQLCODE;
--       v_error_message := SQLERRM;
--       IF v_cursor%ISOPEN THEN
--          CLOSE v_cursor;
--       END IF;
--       RAISE;
-- END;
-- /

-- Rango invertido: p_fecha_ini > p_fecha_fin devuelve cursor vacio,
-- sin sustituir la ficha vigente por alguna respuesta historica.
