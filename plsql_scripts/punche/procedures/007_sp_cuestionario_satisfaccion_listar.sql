-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_SATISF_LISTAR
-- Proposito: Anexo 27 PUNCHE2; una fila por familia, ultima respuesta
--            por sujeto/pregunta y precedencia del cuidador.
-- Parametros (firma/defaults de 003):
--   p_fecha_ini IN DATE DEFAULT NULL: registro seleccionado >= inicio (con hora).
--   p_fecha_fin IN DATE DEFAULT NULL: registro seleccionado < fin + 1 (con hora).
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 todas; otro ID exacto.
--   p_cursor_out OUT SYS_REFCURSOR: 30 columnas, orden Excel A-AD.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-09-30
-- Correccion: 2026-10-01; fuentes maestras y sujeto mixto, plan aprobado.
-- Alcance : Solo lectura; sin SQL dinamico, DML ni transacciones.
-- =============================================================
-- CONTRATO / EVIDENCIA
-- Plantilla: 27_reporte_cuestionario_satisfaccion.xlsx, hoja unica
-- Cuestionario_Satisfaccion; encabezados funcionales fila 2, A-AD.
-- Fila 3 contiene aliases heredados y no define esta interfaz.
-- Catalogo: oracle_schema_tables_catalog.md, leido en esta sesion.
-- Fuente V1: SSI_ANEXOS_RESPUESTAS, productor en usps_ssi_inabif_v1.sql
-- (guardar respuestas familiares) y consumidor parametrizado Anexo 27.
-- No mezclar V2: V1 no tiene clave documentada de aplicacion.
-- El usuario confirma los IDs actuales: dml_insert_preguntas.sql contiene
-- una version anterior y NO se utiliza para sustituir ese mapeo.
--
-- Sujeto familiar (integrante NULL) o individual de cuidador elegible.
-- Familia = ar.PF_ID_FAMILIA; si falta, fi.PF_ID_FAMILIA. Ambas presentes
-- y distintas: rechazar en familias elegibles; guarda concurrente en OPEN.
-- Integrante ausente/no cuidador/eliminado no es respuesta elegible.
-- No usar AR_DESTINATARIO para atribuir sujetos por su default.
-- Servicio estricto de pregunta y familia = 2. Zona LEFT del servicio 2;
-- ausencia conserva ficha sin filtro. No crear fichas solo con maestros.
-- Excluir borrado logico (NULL = no eliminado); no exigir estado activo
-- actual, AN_ESTADO ni fase por defaults. Una familia necesita alguna
-- respuesta elegible de los IDs proyectados, incluso si su texto es NULL.
--
-- Latest global por familia/sujeto/pregunta: registro DESC NULLS LAST y
-- despues ID DESC (solo desempate). Luego precedencia por familia/pregunta:
-- cuidador antes que familiar, aunque sea mas antiguo o su texto sea NULL.
-- Supuesto aprobado del patron 004: sin fallback por texto NULL.
-- MAX del pivote transporta una unica respuesta en familias no ambiguas,
-- no escoge entre versiones. Texto NULL vigente no recupera el anterior.
-- No fecha de modificacion, lote diario ni separacion por fase. Se acepta
-- que columnas provengan de aplicaciones distintas: NO snapshot historico.
-- El productor puede editar in-place conservando la fecha de registro.
--
-- Filtro de ficha completa: alguna respuesta seleccionada tras latest y
-- precedencia cumple ambos extremos sobre su AR_FECHA_REGISTRA.
-- MAX de 0/1 transporta existencia; no exige4319 ni recupera respuestas viejas.
-- Formatos YYYY-MM-DD y DD/MM/YYYY AUTORIZADOS por el usuario; NO inferidos
-- del control date ni de ejemplos XLSX. Sin TRIM: estructura exacta de
-- 10 caracteres. Calendario gregoriano, anos 0001..9999, con bisiestos.
-- Conversion aritmetica desde DATE '0001-01-01', sin TO_DATE ni NLS implicito.
-- TO_NUMBER solo dentro de CASE con guarda de digitos ASCII y NLS explicito.
-- Conversion conservada, sin filtrar. Sin limites admite registros NULL;
-- con algun limite, un registro NULL no admite por si solo la ficha.
-- H conserva el texto. Parametros conservan horas; usar medianoche para dias.
-- Extremos NULL abiertos; rango invertido -> vacio. No TRUNC de parametros.
--
-- Cuidador = FI_CUIDADOR=1, no eliminado, sin exigir actividad actual.
-- G = parentesco actual de ese integrante; sin cuidador -> NULL.
-- Mas de uno en una familia que pasa el filtro -> rechazar sin elegir por ID.
-- E = nombres + primer apellido + segundo apellido actuales; TRIM de
-- componentes y extremos para evitar espacios de borde, sin REGEXP.
-- F = FI_NUMERO_DOC textual, sin conversion numerica.
-- B/C = ZO_ID_ZONA/ZO_DESCRIPCION del maestro de zona.
-- D = SSI_CODIGOS_FAMILIAS: servicio 2, tipo 1, estado 1, eliminado 0,
-- integrante NULL; una fila por familia elegida por MAYOR CF_ID_CODIGO.
-- No ordenar codigos por fecha ni MAX textual ni fallback a codigo legacy.
-- LEFT JOIN conserva ausencia de codigo/cuidador/zona como NULL.
-- 1345..1348 NO son preguntas persistidas; no leerlas ni pivotarlas.
-- No enlazar cuidador por nombre/documento; no reconstruir roles historicos.
--
-- 1383: separar por primer delimitador exacto ' - '. AC/AD son texto;
-- conservar componentes sin TRIM ni normalizacion. Sin delimitador:
-- AC NULL y AD texto completo. NULL -> ambos NULL. Otros delimitadores
-- posteriores quedan en AD. Vacio Oracle = NULL. Sin SUM, AR_PUNTAJE,
-- reclasificacion ni validacion por rangos (20-33/34-46/47-60 informativos).
--
-- JOINS inferidos, NO FK/UNIQUE demostradas por catalogo de columnas:
-- ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA; familia resuelta=pf.PF_ID_FAMILIA;
-- ar.FI_ID_INTEGRANTE=fi.FI_ID_INTEGRANTE; cf.PF_ID_FAMILIA=pf.PF_ID_FAMILIA;
-- pf.ZO_ID_ZONA=zi.ZO_ID_ZONA; fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA;
-- fi.CA_ID_PARENTESCO=cat.IDCATALOGO. Confianza estimada >=90% por nombres,
-- tipos y precedentes 003/004/006/008. Maestros N:1 esperado; cuidador 0:1
-- tras comprobar cardinalidad. Unicidad de IDs maestros es supuesto
-- funcional, NO constraint acreditada. No DISTINCT para ocultar problemas.
-- Prevalidacion y OPEN son SELECT separados: READ COMMITTED puede ver
-- snapshots distintos. OPEN excluye familias con nuevos conflictos de
-- cuidadores o discordancias; snapshot estable debe establecerlo el caller.
--
-- MAPEO: A NRO; B COD_ZON; C zona; D codigo familiar; E cuidador; F documento;
-- G parentesco; H4319; I-P1350..1357; Q-V1359..1364;
-- W-AB1366..1371; AC/AD1383. Secciones 1386/1349/1358/1365 excluidas.
-- Riesgos: full scans posibles, filtros OR-NULL, REGEXP/calendario,
-- ordenamientos de latest/codigos/resultado y lectura duplicada para validacion.
-- Indices/planes no acreditados. Cursor vacio no lanza NO_DATA_FOUND;
-- errores en FETCH corresponden al caller, responsable de cerrar el cursor.
-- Revision solo estatica: NO compilado ni ejecutado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_SATISF_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio   SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE := 2;
   v_num_anexo     SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE := 27;
   v_conflictos    NUMBER;
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
BEGIN
   -- Validar cuidadores y discordancias en familias que pasan el filtro de ficha.
   WITH base AS (
      SELECT CASE WHEN ar.PF_ID_FAMILIA IS NOT NULL THEN ar.PF_ID_FAMILIA
            ELSE fi.PF_ID_FAMILIA END AS PF_ID_FAMILIA,
         ar.FI_ID_INTEGRANTE, ar.AP_ID_PREGUNTA, ar.AR_RESPUESTA,
         ar.AR_FECHA_REGISTRA, ar.AR_ID_RESPUESTA,
         CASE WHEN ar.PF_ID_FAMILIA IS NOT NULL
            AND fi.PF_ID_FAMILIA IS NOT NULL
            AND ar.PF_ID_FAMILIA <> fi.PF_ID_FAMILIA
            THEN 1 ELSE 0 END AS DISCORDANTE
      FROM SSI_ANEXOS_RESPUESTAS ar
      JOIN SSI_ANEXOS_PREGUNTAS ap
         ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
      LEFT JOIN SSI_FAMILIA_INTEGRANTES fi
         ON fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
      WHERE ap.SI_ID_SERVICIO = v_id_servicio
         AND ap.AP_NUM_ANEXO = v_num_anexo
         AND NVL(ap.AP_ELIMINADO, 0) = 0
         AND NVL(ar.AR_ELIMINADO, 0) = 0
         AND (ar.PF_ID_FAMILIA IS NOT NULL OR fi.PF_ID_FAMILIA IS NOT NULL)
         AND (ar.FI_ID_INTEGRANTE IS NULL
            OR (fi.FI_CUIDADOR = 1 AND NVL(fi.FI_ELIMINADO, 0) = 0))
         AND ar.AP_ID_PREGUNTA IN (
            4319,
            1350, 1351, 1352, 1353, 1354, 1355, 1356, 1357,
            1359, 1360, 1361, 1362, 1363, 1364,
            1366, 1367, 1368, 1369, 1370, 1371, 1383
         )
   ), por_sujeto AS (
      SELECT bas.PF_ID_FAMILIA, bas.FI_ID_INTEGRANTE,
         bas.AP_ID_PREGUNTA, bas.AR_RESPUESTA,
         bas.AR_FECHA_REGISTRA,
         ROW_NUMBER() OVER (
            PARTITION BY bas.PF_ID_FAMILIA, bas.FI_ID_INTEGRANTE, bas.AP_ID_PREGUNTA
            ORDER BY bas.AR_FECHA_REGISTRA DESC NULLS LAST, bas.AR_ID_RESPUESTA DESC
         ) AS RN_SUJETO
      FROM base bas
   ), ordenadas AS (
      SELECT ps.PF_ID_FAMILIA, ps.AP_ID_PREGUNTA, ps.AR_RESPUESTA,
         ps.AR_FECHA_REGISTRA,
         ROW_NUMBER() OVER (
            PARTITION BY ps.PF_ID_FAMILIA, ps.AP_ID_PREGUNTA
            ORDER BY CASE WHEN ps.FI_ID_INTEGRANTE IS NOT NULL THEN 0 ELSE 1 END
         ) AS RN
      FROM por_sujeto ps
      WHERE ps.RN_SUJETO = 1
   ), fichas AS (
      SELECT ord.PF_ID_FAMILIA,
         MAX(CASE WHEN ord.AP_ID_PREGUNTA = 4319
            THEN ord.AR_RESPUESTA END) AS FECHA_TEXTO,
         MAX(CASE WHEN (p_fecha_ini IS NULL OR ord.AR_FECHA_REGISTRA >= p_fecha_ini)
            AND (p_fecha_fin IS NULL OR ord.AR_FECHA_REGISTRA < p_fecha_fin + 1)
            THEN 1 ELSE 0 END) AS FILTRO_FECHA_CUMPLE
      FROM ordenadas ord
      WHERE ord.RN = 1
      GROUP BY ord.PF_ID_FAMILIA
   ), formatos AS (
      SELECT fic.PF_ID_FAMILIA,
         fic.FILTRO_FECHA_CUMPLE,
         CASE
            WHEN LENGTH(fic.FECHA_TEXTO) = 10
               AND REGEXP_LIKE(fic.FECHA_TEXTO, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
            THEN fic.FECHA_TEXTO
            WHEN LENGTH(fic.FECHA_TEXTO) = 10
               AND REGEXP_LIKE(fic.FECHA_TEXTO, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
            THEN SUBSTR(fic.FECHA_TEXTO, 7, 4) || '-'
               || SUBSTR(fic.FECHA_TEXTO, 4, 2) || '-'
               || SUBSTR(fic.FECHA_TEXTO, 1, 2)
         END AS FECHA_ISO
      FROM fichas fic
   ), partes AS (
      SELECT fmt.PF_ID_FAMILIA,
         fmt.FILTRO_FECHA_CUMPLE,
         CASE WHEN REGEXP_LIKE(fmt.FECHA_ISO, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
            THEN TO_NUMBER(SUBSTR(fmt.FECHA_ISO, 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''')
         END AS ANIO,
         CASE WHEN REGEXP_LIKE(fmt.FECHA_ISO, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
            THEN TO_NUMBER(SUBSTR(fmt.FECHA_ISO, 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
         END AS MES,
         CASE WHEN REGEXP_LIKE(fmt.FECHA_ISO, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
            THEN TO_NUMBER(SUBSTR(fmt.FECHA_ISO, 9, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
         END AS DIA
      FROM formatos fmt
   ), calendario AS (
      SELECT par.PF_ID_FAMILIA, par.ANIO, par.MES, par.DIA,
         par.FILTRO_FECHA_CUMPLE,
         CASE WHEN MOD(par.ANIO, 400) = 0
            OR (MOD(par.ANIO, 4) = 0 AND MOD(par.ANIO, 100) <> 0)
            THEN 1 ELSE 0 END AS BISIESTO
      FROM partes par
   ), fechas AS (
      SELECT cal.PF_ID_FAMILIA,
         cal.FILTRO_FECHA_CUMPLE,
         CASE WHEN cal.ANIO BETWEEN 1 AND 9999
            AND cal.MES BETWEEN 1 AND 12
            AND cal.DIA BETWEEN 1 AND CASE
               WHEN cal.MES = 2 THEN 28 + cal.BISIESTO
               WHEN cal.MES IN (4, 6, 9, 11) THEN 30 ELSE 31 END
         THEN DATE '0001-01-01'
            + 365 * (cal.ANIO - 1) + TRUNC((cal.ANIO - 1) / 4)
            - TRUNC((cal.ANIO - 1) / 100) + TRUNC((cal.ANIO - 1) / 400)
            + CASE cal.MES
               WHEN 1 THEN 0 WHEN 2 THEN 31 WHEN 3 THEN 59
               WHEN 4 THEN 90 WHEN 5 THEN 120 WHEN 6 THEN 151
               WHEN 7 THEN 181 WHEN 8 THEN 212 WHEN 9 THEN 243
               WHEN 10 THEN 273 WHEN 11 THEN 304 WHEN 12 THEN 334 END
            + CASE WHEN cal.MES > 2 THEN cal.BISIESTO ELSE 0 END
            + cal.DIA - 1
         END AS FECHA_APLICACION
      FROM calendario cal
   ), cuidadores AS (
      SELECT fi.PF_ID_FAMILIA, COUNT(*) AS CANTIDAD
      FROM SSI_FAMILIA_INTEGRANTES fi
      WHERE fi.FI_CUIDADOR = 1
         AND NVL(fi.FI_ELIMINADO, 0) = 0
      GROUP BY fi.PF_ID_FAMILIA
   )
   SELECT COUNT(*) INTO v_conflictos
   FROM fechas fec
   JOIN SSI_POTENCIALES_FAMILIAS pf
      ON pf.PF_ID_FAMILIA = fec.PF_ID_FAMILIA
   LEFT JOIN SSI_ZONA_INTERVENCION zi
      ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
      AND zi.SI_ID_SERVICIO = v_id_servicio
      AND NVL(zi.ZO_ELIMINADO, 0) = 0
   LEFT JOIN cuidadores cui
      ON cui.PF_ID_FAMILIA = fec.PF_ID_FAMILIA
   WHERE pf.SI_ID_SERVICIO = v_id_servicio
      AND NVL(pf.PF_ELIMINADO, 0) = 0
      AND (cui.CANTIDAD > 1 OR EXISTS (
         SELECT 1 FROM base bas
         WHERE bas.PF_ID_FAMILIA = fec.PF_ID_FAMILIA
            AND bas.DISCORDANTE = 1
      ))
      AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
      AND fec.FILTRO_FECHA_CUMPLE = 1
      AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL OR p_fecha_ini <= p_fecha_fin);

   IF v_conflictos > 0 THEN
      RAISE_APPLICATION_ERROR(-20001,
         'Anexo 27: multiples cuidadores o familias discordantes en '
         || TO_CHAR(v_conflictos) || ' familias del reporte.');
   END IF;

   OPEN p_cursor_out FOR
      WITH base AS (
         SELECT CASE WHEN ar.PF_ID_FAMILIA IS NOT NULL THEN ar.PF_ID_FAMILIA
               ELSE fi.PF_ID_FAMILIA END AS PF_ID_FAMILIA,
            ar.FI_ID_INTEGRANTE, ar.AP_ID_PREGUNTA, ar.AR_RESPUESTA,
            ar.AR_FECHA_REGISTRA, ar.AR_ID_RESPUESTA,
            CASE WHEN ar.PF_ID_FAMILIA IS NOT NULL
               AND fi.PF_ID_FAMILIA IS NOT NULL
               AND ar.PF_ID_FAMILIA <> fi.PF_ID_FAMILIA
               THEN 1 ELSE 0 END AS DISCORDANTE
         FROM SSI_ANEXOS_RESPUESTAS ar
         JOIN SSI_ANEXOS_PREGUNTAS ap
            ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         LEFT JOIN SSI_FAMILIA_INTEGRANTES fi
            ON fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
         WHERE ap.SI_ID_SERVICIO = v_id_servicio
            AND ap.AP_NUM_ANEXO = v_num_anexo
            AND NVL(ap.AP_ELIMINADO, 0) = 0
            AND NVL(ar.AR_ELIMINADO, 0) = 0
            AND (ar.PF_ID_FAMILIA IS NOT NULL OR fi.PF_ID_FAMILIA IS NOT NULL)
            AND (ar.FI_ID_INTEGRANTE IS NULL
               OR (fi.FI_CUIDADOR = 1 AND NVL(fi.FI_ELIMINADO, 0) = 0))
            AND ar.AP_ID_PREGUNTA IN (
               4319,
               1350, 1351, 1352, 1353, 1354, 1355, 1356, 1357,
               1359, 1360, 1361, 1362, 1363, 1364,
               1366, 1367, 1368, 1369, 1370, 1371, 1383
            )
      ), por_sujeto AS (
         SELECT bas.PF_ID_FAMILIA, bas.FI_ID_INTEGRANTE,
            bas.AP_ID_PREGUNTA, bas.AR_RESPUESTA,
            bas.AR_FECHA_REGISTRA,
            ROW_NUMBER() OVER (
               PARTITION BY bas.PF_ID_FAMILIA, bas.FI_ID_INTEGRANTE, bas.AP_ID_PREGUNTA
               ORDER BY bas.AR_FECHA_REGISTRA DESC NULLS LAST, bas.AR_ID_RESPUESTA DESC
            ) AS RN_SUJETO
         FROM base bas
      ), ordenadas AS (
         SELECT ps.PF_ID_FAMILIA, ps.AP_ID_PREGUNTA, ps.AR_RESPUESTA,
            ps.AR_FECHA_REGISTRA,
            ROW_NUMBER() OVER (
               PARTITION BY ps.PF_ID_FAMILIA, ps.AP_ID_PREGUNTA
               ORDER BY CASE WHEN ps.FI_ID_INTEGRANTE IS NOT NULL THEN 0 ELSE 1 END
            ) AS RN
         FROM por_sujeto ps
         WHERE ps.RN_SUJETO = 1
      ), fichas AS (
         SELECT ord.PF_ID_FAMILIA,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 4319 THEN ord.AR_RESPUESTA END) AS FECHA_TEXTO,
            MAX(CASE WHEN (p_fecha_ini IS NULL OR ord.AR_FECHA_REGISTRA >= p_fecha_ini)
               AND (p_fecha_fin IS NULL OR ord.AR_FECHA_REGISTRA < p_fecha_fin + 1)
               THEN 1 ELSE 0 END) AS FILTRO_FECHA_CUMPLE,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1350 THEN ord.AR_RESPUESTA END) AS P01_SESIONES,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1351 THEN ord.AR_RESPUESTA END) AS P02_TALLERES,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1352 THEN ord.AR_RESPUESTA END) AS P03_TRATO_ACOMPANANTE,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1353 THEN ord.AR_RESPUESTA END) AS P04_LENGUAJE_SESIONES,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1354 THEN ord.AR_RESPUESTA END) AS P05_HORARIOS,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1355 THEN ord.AR_RESPUESTA END) AS P06_HABILIDADES_CRIANZA,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1356 THEN ord.AR_RESPUESTA END) AS P07_ROLES_TAREAS,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1357 THEN ord.AR_RESPUESTA END) AS P08_FUNCIONAMIENTO_FAMILIAR,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1359 THEN ord.AR_RESPUESTA END) AS P09_CURSOS_ECONOMIA,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1360 THEN ord.AR_RESPUESTA END) AS P10_TRATO_CAPACITACION,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1361 THEN ord.AR_RESPUESTA END) AS P11_LENGUAJE_CAPACITACION,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1362 THEN ord.AR_RESPUESTA END) AS P12_SOPORTE_PLATAFORMAS,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1363 THEN ord.AR_RESPUESTA END) AS P13_HABILIDADES_ECONOMIA,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1364 THEN ord.AR_RESPUESTA END) AS P14_FUNCIONAMIENTO_ECONOMIA,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1366 THEN ord.AR_RESPUESTA END) AS P15_INFORMACION_REDES,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1367 THEN ord.AR_RESPUESTA END) AS P16_EMPODERAMIENTO,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1368 THEN ord.AR_RESPUESTA END) AS P17_MATERIALES_REDES,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1369 THEN ord.AR_RESPUESTA END) AS P18_TRATO_REDES,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1370 THEN ord.AR_RESPUESTA END) AS P19_IDENTIFICACION_REDES,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1371 THEN ord.AR_RESPUESTA END) AS P20_USO_REDES,
            MAX(CASE WHEN ord.AP_ID_PREGUNTA = 1383 THEN ord.AR_RESPUESTA END) AS RESULTADO_FINAL
         FROM ordenadas ord
         WHERE ord.RN = 1
         GROUP BY ord.PF_ID_FAMILIA
      ), formatos AS (
         SELECT fic.PF_ID_FAMILIA,
            fic.FILTRO_FECHA_CUMPLE,
            CASE
               WHEN LENGTH(fic.FECHA_TEXTO) = 10
                  AND REGEXP_LIKE(fic.FECHA_TEXTO, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
               THEN fic.FECHA_TEXTO
               WHEN LENGTH(fic.FECHA_TEXTO) = 10
                  AND REGEXP_LIKE(fic.FECHA_TEXTO, '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
               THEN SUBSTR(fic.FECHA_TEXTO, 7, 4) || '-'
                  || SUBSTR(fic.FECHA_TEXTO, 4, 2) || '-'
                  || SUBSTR(fic.FECHA_TEXTO, 1, 2)
            END AS FECHA_ISO
         FROM fichas fic
      ), partes AS (
         SELECT fmt.PF_ID_FAMILIA,
            fmt.FILTRO_FECHA_CUMPLE,
            CASE WHEN REGEXP_LIKE(fmt.FECHA_ISO, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
               THEN TO_NUMBER(SUBSTR(fmt.FECHA_ISO, 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS ANIO,
            CASE WHEN REGEXP_LIKE(fmt.FECHA_ISO, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
               THEN TO_NUMBER(SUBSTR(fmt.FECHA_ISO, 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS MES,
            CASE WHEN REGEXP_LIKE(fmt.FECHA_ISO, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
               THEN TO_NUMBER(SUBSTR(fmt.FECHA_ISO, 9, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
            END AS DIA
         FROM formatos fmt
      ), calendario AS (
         SELECT par.PF_ID_FAMILIA, par.ANIO, par.MES, par.DIA,
            par.FILTRO_FECHA_CUMPLE,
            CASE WHEN MOD(par.ANIO, 400) = 0
               OR (MOD(par.ANIO, 4) = 0 AND MOD(par.ANIO, 100) <> 0)
               THEN 1 ELSE 0 END AS BISIESTO
         FROM partes par
      ), fechas AS (
         SELECT cal.PF_ID_FAMILIA,
            cal.FILTRO_FECHA_CUMPLE,
            CASE WHEN cal.ANIO BETWEEN 1 AND 9999
               AND cal.MES BETWEEN 1 AND 12
               AND cal.DIA BETWEEN 1 AND CASE
                  WHEN cal.MES = 2 THEN 28 + cal.BISIESTO
                  WHEN cal.MES IN (4, 6, 9, 11) THEN 30 ELSE 31 END
            THEN DATE '0001-01-01'
               + 365 * (cal.ANIO - 1) + TRUNC((cal.ANIO - 1) / 4)
               - TRUNC((cal.ANIO - 1) / 100) + TRUNC((cal.ANIO - 1) / 400)
               + CASE cal.MES
                  WHEN 1 THEN 0 WHEN 2 THEN 31 WHEN 3 THEN 59
                  WHEN 4 THEN 90 WHEN 5 THEN 120 WHEN 6 THEN 151
                  WHEN 7 THEN 181 WHEN 8 THEN 212 WHEN 9 THEN 243
                  WHEN 10 THEN 273 WHEN 11 THEN 304 WHEN 12 THEN 334 END
               + CASE WHEN cal.MES > 2 THEN cal.BISIESTO ELSE 0 END
               + cal.DIA - 1
            END AS FECHA_APLICACION
         FROM calendario cal
      ), cuidadores AS (
         SELECT fi.PF_ID_FAMILIA, fi.CA_ID_PARENTESCO,
            fi.FI_NOMBRES, fi.FI_PRIMER_APE, fi.FI_SEGUNDO_APE, fi.FI_NUMERO_DOC,
            COUNT(*) OVER (PARTITION BY fi.PF_ID_FAMILIA) AS CANTIDAD
         FROM SSI_FAMILIA_INTEGRANTES fi
         WHERE fi.FI_CUIDADOR = 1
            AND NVL(fi.FI_ELIMINADO, 0) = 0
      ), codigos AS (
         SELECT cf.PF_ID_FAMILIA, cf.CF_CODIGO,
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
      )
      SELECT
         ROW_NUMBER() OVER (
            ORDER BY zi.ZO_ID_ZONA NULLS LAST, fic.PF_ID_FAMILIA
         ) AS NRO,
         zi.ZO_ID_ZONA AS COD_ZON,
         zi.ZO_DESCRIPCION AS ZONA_INTERVENCION,
         cod.CF_CODIGO AS CODIGO_FAMILIA,
         TRIM(TRIM(cui.FI_NOMBRES)
            || CASE WHEN TRIM(cui.FI_PRIMER_APE) IS NOT NULL
               THEN ' ' || TRIM(cui.FI_PRIMER_APE) END
            || CASE WHEN TRIM(cui.FI_SEGUNDO_APE) IS NOT NULL
               THEN ' ' || TRIM(cui.FI_SEGUNDO_APE) END) AS NOMBRE_CUIDADOR,
         cui.FI_NUMERO_DOC AS DNI,
         cat.CATDESCRIPCION AS PARENTESCO_NNA,
         fic.FECHA_TEXTO AS FECHA_APLICACION_FICHA,
         fic.P01_SESIONES,
         fic.P02_TALLERES,
         fic.P03_TRATO_ACOMPANANTE,
         fic.P04_LENGUAJE_SESIONES,
         fic.P05_HORARIOS,
         fic.P06_HABILIDADES_CRIANZA,
         fic.P07_ROLES_TAREAS,
         fic.P08_FUNCIONAMIENTO_FAMILIAR,
         fic.P09_CURSOS_ECONOMIA,
         fic.P10_TRATO_CAPACITACION,
         fic.P11_LENGUAJE_CAPACITACION,
         fic.P12_SOPORTE_PLATAFORMAS,
         fic.P13_HABILIDADES_ECONOMIA,
         fic.P14_FUNCIONAMIENTO_ECONOMIA,
         fic.P15_INFORMACION_REDES,
         fic.P16_EMPODERAMIENTO,
         fic.P17_MATERIALES_REDES,
         fic.P18_TRATO_REDES,
         fic.P19_IDENTIFICACION_REDES,
         fic.P20_USO_REDES,
         CASE WHEN INSTR(fic.RESULTADO_FINAL, ' - ') > 0
            THEN SUBSTR(fic.RESULTADO_FINAL, 1,
               INSTR(fic.RESULTADO_FINAL, ' - ') - 1)
         END AS PUNTAJE,
         CASE WHEN INSTR(fic.RESULTADO_FINAL, ' - ') > 0
            THEN SUBSTR(fic.RESULTADO_FINAL,
               INSTR(fic.RESULTADO_FINAL, ' - ') + 3)
            ELSE fic.RESULTADO_FINAL
         END AS NIVEL
      FROM fichas fic
      JOIN fechas fec
         ON fec.PF_ID_FAMILIA = fic.PF_ID_FAMILIA
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = fic.PF_ID_FAMILIA
      LEFT JOIN SSI_ZONA_INTERVENCION zi
         ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
         AND zi.SI_ID_SERVICIO = v_id_servicio
         AND NVL(zi.ZO_ELIMINADO, 0) = 0
      LEFT JOIN cuidadores cui
         ON cui.PF_ID_FAMILIA = fic.PF_ID_FAMILIA
         AND cui.CANTIDAD = 1
       LEFT JOIN TGCATALOGO cat
          ON cat.IDCATALOGO = cui.CA_ID_PARENTESCO
       LEFT JOIN codigos cod
          ON cod.PF_ID_FAMILIA = fic.PF_ID_FAMILIA
          AND cod.RN_CODIGO = 1
      WHERE pf.SI_ID_SERVICIO = v_id_servicio
         AND NVL(pf.PF_ELIMINADO, 0) = 0
          AND NOT EXISTS (
             SELECT 1 FROM cuidadores cux
             WHERE cux.PF_ID_FAMILIA = fic.PF_ID_FAMILIA
                AND cux.CANTIDAD > 1
          )
          AND NOT EXISTS (
             SELECT 1 FROM base bas
             WHERE bas.PF_ID_FAMILIA = fic.PF_ID_FAMILIA
                AND bas.DISCORDANTE = 1
          )
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
         AND fec.FILTRO_FECHA_CUMPLE = 1
         AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL OR p_fecha_ini <= p_fecha_fin)
      ORDER BY zi.ZO_ID_ZONA NULLS LAST, fic.PF_ID_FAMILIA;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      -- Conservar codigo, mensaje y backtrace; no logging con efectos laterales.
      RAISE;
END PRC_PUNCHE_SATISF_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- INVOCACION MANUAL SEPARADA - NO EJECUTADA
-- Todo el bloque esta comentado; crear el SP no invoca el reporte.
-- DBMS_SQL.RETURN_RESULT requiere Oracle 12c+ y cliente compatible con
-- resultados implicitos. Alternativa: consumir/cerrar el cursor desde
-- el caller. Este requisito del ejemplo NO impone identificadores 12.2.
-- Fechas ilustrativas, sin garantia de datos. Usar argumentos nombrados.
-- =============================================================
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_SATISF_LISTAR(
--       p_fecha_ini  => NULL,
--       p_fecha_fin  => NULL,
--       p_id_zona    => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Para dias completos, sustituir por argumentos DATE a medianoche:
-- p_fecha_ini => DATE '2026-09-01', p_fecha_fin => DATE '2026-09-30'.
