-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_CONDUCTAS_RIESGO_LISTAR
-- Proposito: Reporte Anexo 28 PUNCHE, cuestionario de conductas de
--            riesgo. Una fila por integrante y fase con respuestas
--            elegibles, sin seleccionar latest ni mezclar fases.
-- Parametros (firma literal de la referencia 003):
--   p_fecha_ini IN DATE DEFAULT NULL: inicio incluido; conserva hora.
--   p_fecha_fin IN DATE DEFAULT NULL: fin exclusivo p_fecha_fin + 1;
--               conserva hora. Para dias completos enviar medianoche.
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 = todas; otro = zona exacta.
--   p_cursor_out OUT SYS_REFCURSOR: 31 columnas, orden Excel A-AE.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-09-30
-- Alcance : Solo lectura; sin DML, SQL dinamico ni transacciones.
-- =============================================================
-- CONTRATO RESUELTO / EVIDENCIA
-- * Plantilla 28_cuestionario_conductas_riesgo.xlsx, unica hoja
--   Cuestionario_Cond_Ries, encabezados funcionales fila 2, A-AE.
--   Fila 3 y ejemplos E-G heredados no definen los aliases del cursor.
-- * Ultima aclaracion: SI existen fases (I = Etapa); fecha = 4317.
--   Fuente V1 sustentada por el consumidor del servicio 2/anexo 28
--   en usps_ssi_inabif_v1.sql, seccion comparativo de fases de fichas.
--   No se mezclan respuestas V2 ni se utiliza la pregunta 1620.
-- * Usuario garantiza unicidad funcional de respuestas por pregunta.
--   Se agrupa por FI_ID_INTEGRANTE y SF_ID_FASE; MAX del pivote solo
--   transporta la unica respuesta, NO decide latest ni resuelve
--   duplicados. Una violacion de esa garantia requiere revisar datos.
-- * Todas las fichas elegibles; solo integrantes FI_ESTADO=1 y
--   FI_ELIMINADO=0. Sin FI_CUIDADOR ni filtro AN_ESTADO inventado.
--   Preguntas servicio 2/anexo 28 y no eliminadas; respuestas no
--   eliminadas (NULL de eliminado se considera no eliminado).
-- * Familia estructurada del integrante define pertenencia PUNCHE,
--   codigo familiar y zona: fi.PF_ID_FAMILIA, no ar.PF_ID_FAMILIA.
--   No se hace fallback ni se reconcilian familias de respuestas.
--   Familia del servicio 2 obligatoria, sin exigir actividad actual.
--   Zona LEFT JOIN del servicio 2; sin exigir actividad actual.
--   No se copia el OR de servicio de 003. Una zona ausente conserva
--   la ficha sin filtro de zona, y no satisface una zona especifica.
-- * Relaciones inferidas, NO FK/UNIQUE acreditadas por el catalogo:
--   ar.FI_ID_INTEGRANTE=fi.FI_ID_INTEGRANTE; ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA;
--   fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA; pf.ZO_ID_ZONA=zi.ZO_ID_ZONA;
--   ar.SF_ID_FASE=af.SF_ID_FASE; fi.CA_ID_PARENTESCO=cat.IDCATALOGO;
--   cf.PF_ID_FAMILIA=pf.PF_ID_FAMILIA. Confianza estimada >=90% por
--   nombres, tipos del catalogo y precedentes 001/003/consumidor V1.
--   Cardinalidad esperada N:1 para maestros; codigos preagregados
--   una fila por familia. LEFT conserva fase/parentesco/codigo ausentes
--   como NULL. Una fase NULL permanece como grupo propio, sin default.
-- * Nombre completo actual: FI_NOMBRES, FI_PRIMER_APE, FI_SEGUNDO_APE.
--   Parentesco actual del PROPIO integrante, no del cuidador.
--   Sexo/edad de la ficha: 1551/1552, sin fallback al maestro.
-- * D: MAX textual del codigo familiar servicio 2, tipo 1, activo y
--   no eliminado, expresamente autorizado. No significa ultimo codigo.
-- * J: fecha 4317. Formatos aprobados YYYY-MM-DD y DD/MM/YYYY (dia/mes).
--   TRIM solo sobre el texto de fecha; estructura exacta de 10 caracteres
--   y calendario gregoriano (incluye bisiestos y anos 0001..9999).
--   Conversion por dias desde DATE '0001-01-01': no depende de NLS,
--   TO_DATE, DEFAULT ON CONVERSION ERROR ni version reciente de Oracle.
--   TO_NUMBER esta dentro de CASE con guardas de digitos ASCII y usa
--   mascara/NLS explicitos. No se confia en el orden de filtros WHERE.
--   Fecha textual invalida/ausente -> NULL. DATE interno intacto; J final
--   VARCHAR2(10) DD/MM/YYYY por EXTRACT gregoriano, sin mostrar hora.
--   El filtro admite la ficha completa si alguna respuesta elegible cumple
--   ambos extremos sobre su AR_FECHA_REGISTRA, sin exigir pregunta4317.
--   Sin limites admite tambien registros NULL; con limites, un registro
--   NULL no admite por si solo. MAX de 0/1 transporta existencia, no fecha.
--   La unicidad de los maestros enlazados no esta comprobada en Oracle.
--   No se modifican ni truncan los parametros. Rango invertido -> vacio.
-- * K/L=1554/1555; M-AC=1557..1573. Excel tiene 19 conductas:
--   omite 1556 (peleas colegio). No se agregan Grado 1553 ni APTA 1662.
--   AD/AE=1658/1659 originales, sin recalcular ni sustituir por AR_PUNTAJE.
--   Respuestas ausentes/vacias permanecen NULL: no se convierten a cero.
-- * Un integrante sin ninguna respuesta elegible no genera ficha fantasma.
-- * Fase y dimensiones personales son datos actuales, no reconstruccion
--   de sus descripciones historicas. Integrantes inactivos no se listan.
-- * Riesgos: scans de respuestas/codigos (indices no acreditados),
--   filtros OR-NULL, REGEXP por fecha y ordenamiento completo para NRO.
--   Integridad/unicidad de identificadores maestros asumida por su uso
--   funcional, no probada por constraints de este catalogo de columnas.
-- * Validacion solo estatica. No compilado ni ejecutado en Oracle.
--   Errores durante FETCH corresponden al caller, que cierra el cursor.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_CONDUCTAS_RIESGO_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio   SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE := 2;
   v_num_anexo     SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE := 28;
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
   v_diagnostico   VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      WITH fichas AS (
         SELECT
            ar.FI_ID_INTEGRANTE,
            ar.SF_ID_FASE,
            MAX(CASE WHEN (p_fecha_ini IS NULL OR ar.AR_FECHA_REGISTRA >= p_fecha_ini)
               AND (p_fecha_fin IS NULL OR ar.AR_FECHA_REGISTRA < p_fecha_fin + 1)
               THEN 1 ELSE 0 END) AS FILTRO_FECHA_CUMPLE,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1551 THEN ar.AR_RESPUESTA END) AS SEXO_ADOLESCENTE,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1552 THEN ar.AR_RESPUESTA END) AS EDAD_ADOLESCENTE,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 4317 THEN ar.AR_RESPUESTA END) AS FECHA_TEXTO,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1554 THEN ar.AR_RESPUESTA END) AS P01_PANDILLAS,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1555 THEN ar.AR_RESPUESTA END) AS P02_PELEAS_ARMAS,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1557 THEN ar.AR_RESPUESTA END) AS P03_LLEVA_ARMA,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1558 THEN ar.AR_RESPUESTA END) AS P04_MARIHUANA,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1559 THEN ar.AR_RESPUESTA END) AS P05_BEBIDAS,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1560 THEN ar.AR_RESPUESTA END) AS P06_ACEPTA_ALCOHOL,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1561 THEN ar.AR_RESPUESTA END) AS P07_PASTA_COCAINA,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1562 THEN ar.AR_RESPUESTA END) AS P08_RELACIONES_INTIMAS,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1563 THEN ar.AR_RESPUESTA END) AS P09_OTRA_RELACION,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1564 THEN ar.AR_RESPUESTA END) AS P10_ANTICONCEPTIVO,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1565 THEN ar.AR_RESPUESTA END) AS P11_ENCUENTRO_REDES,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1566 THEN ar.AR_RESPUESTA END) AS P12_VENDE_COSAS_CASA,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1567 THEN ar.AR_RESPUESTA END) AS P13_COSAS_AMIGOS,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1568 THEN ar.AR_RESPUESTA END) AS P14_ROBA_CON_AMIGOS,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1569 THEN ar.AR_RESPUESTA END) AS P15_CAMINA_SIN_RUMBO,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1570 THEN ar.AR_RESPUESTA END) AS P16_TIEMPO_REDES,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1571 THEN ar.AR_RESPUESTA END) AS P17_NECESIDAD_REDES,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1572 THEN ar.AR_RESPUESTA END) AS P18_VIDEOJUEGOS,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1573 THEN ar.AR_RESPUESTA END) AS P19_AMISTAD_REDES,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1658 THEN ar.AR_RESPUESTA END) AS PUNTAJE_TOTAL,
            MAX(CASE WHEN ar.AP_ID_PREGUNTA = 1659 THEN ar.AR_RESPUESTA END) AS NIVEL
         FROM SSI_ANEXOS_RESPUESTAS ar
         JOIN SSI_ANEXOS_PREGUNTAS ap
            ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         JOIN SSI_FAMILIA_INTEGRANTES fi
            ON fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
         JOIN SSI_POTENCIALES_FAMILIAS pf
            ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
         WHERE ap.SI_ID_SERVICIO = v_id_servicio
            AND ap.AP_NUM_ANEXO = v_num_anexo
            AND NVL(ap.AP_ELIMINADO, 0) = 0
            AND NVL(ar.AR_ELIMINADO, 0) = 0
            AND fi.FI_ESTADO = 1
            AND fi.FI_ELIMINADO = 0
            AND pf.SI_ID_SERVICIO = v_id_servicio
            AND ar.AP_ID_PREGUNTA IN (
               1551, 1552, 4317, 1554, 1555,
               1557, 1558, 1559, 1560, 1561, 1562, 1563, 1564,
               1565, 1566, 1567, 1568, 1569, 1570, 1571, 1572,
               1573, 1658, 1659
            )
         GROUP BY ar.FI_ID_INTEGRANTE, ar.SF_ID_FASE
      ), formatos AS (
         SELECT
            fic.FI_ID_INTEGRANTE,
            fic.SF_ID_FASE,
            CASE
               WHEN LENGTH(TRIM(fic.FECHA_TEXTO)) = 10
                  AND REGEXP_LIKE(TRIM(fic.FECHA_TEXTO), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
               THEN TRIM(fic.FECHA_TEXTO)
               WHEN LENGTH(TRIM(fic.FECHA_TEXTO)) = 10
                  AND REGEXP_LIKE(TRIM(fic.FECHA_TEXTO), '^[0-9]{2}/[0-9]{2}/[0-9]{4}$')
               THEN SUBSTR(TRIM(fic.FECHA_TEXTO), 7, 4) || '-'
                  || SUBSTR(TRIM(fic.FECHA_TEXTO), 4, 2) || '-'
                  || SUBSTR(TRIM(fic.FECHA_TEXTO), 1, 2)
            END AS FECHA_ISO
         FROM fichas fic
      ), partes AS (
         SELECT
            fmt.FI_ID_INTEGRANTE,
            fmt.SF_ID_FASE,
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
         SELECT
            par.FI_ID_INTEGRANTE,
            par.SF_ID_FASE,
            par.ANIO,
            par.MES,
            par.DIA,
            CASE
               WHEN MOD(par.ANIO, 400) = 0
                  OR (MOD(par.ANIO, 4) = 0 AND MOD(par.ANIO, 100) <> 0)
               THEN 1
               ELSE 0
            END AS BISIESTO
         FROM partes par
      ), fechas AS (
         SELECT
            cal.FI_ID_INTEGRANTE,
            cal.SF_ID_FASE,
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
            END AS FECHA_APLICACION_FICHA
         FROM calendario cal
      ), codigos AS (
         SELECT
            cf.PF_ID_FAMILIA,
            MAX(cf.CF_CODIGO) AS CODIGO_FAMILIA
         FROM SSI_CODIGOS_FAMILIAS cf
         WHERE cf.SI_ID_SERVICIO = v_id_servicio
            AND cf.CF_TIPO_CODIGO = 1
            AND cf.CF_ESTADO = 1
            AND cf.CF_ELIMINADO = 0
         GROUP BY cf.PF_ID_FAMILIA
      )
      SELECT
         ROW_NUMBER() OVER (
            ORDER BY zi.ZO_ID_ZONA NULLS LAST,
               fi.PF_ID_FAMILIA,
               fic.FI_ID_INTEGRANTE,
               fic.SF_ID_FASE NULLS LAST
         ) AS NRO,
         zi.ZO_ID_ZONA AS COD_ZON,
         zi.ZO_DESCRIPCION AS ZONA_INTERVENCION,
         cod.CODIGO_FAMILIA,
         TRIM(fi.FI_NOMBRES) AS NOMBRE_ADOLESCENTE,
         TRIM(fi.FI_PRIMER_APE) AS PRI_APE_ADOLESCENTE,
         TRIM(fi.FI_SEGUNDO_APE) AS SEG_APE_ADOLESCENTE,
         fic.SEXO_ADOLESCENTE,
         fic.EDAD_ADOLESCENTE,
         cat.CATDESCRIPCION AS PARENTESCO_CON_NNA,
         af.SF_NOMBRE AS ETAPA,
         CAST(CASE WHEN fec.FECHA_APLICACION_FICHA >= DATE '0001-01-01' THEN
            TO_CHAR(EXTRACT(DAY FROM fec.FECHA_APLICACION_FICHA), 'FM00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '/'
            || TO_CHAR(EXTRACT(MONTH FROM fec.FECHA_APLICACION_FICHA), 'FM00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '/'
            || TO_CHAR(EXTRACT(YEAR FROM fec.FECHA_APLICACION_FICHA), 'FM0000', 'NLS_NUMERIC_CHARACTERS=''.,''')
            ELSE NULL END AS VARCHAR2(10)) AS FECHA_APLICACION_FICHA,
         fic.P01_PANDILLAS,
         fic.P02_PELEAS_ARMAS,
         fic.P03_LLEVA_ARMA,
         fic.P04_MARIHUANA,
         fic.P05_BEBIDAS,
         fic.P06_ACEPTA_ALCOHOL,
         fic.P07_PASTA_COCAINA,
         fic.P08_RELACIONES_INTIMAS,
         fic.P09_OTRA_RELACION,
         fic.P10_ANTICONCEPTIVO,
         fic.P11_ENCUENTRO_REDES,
         fic.P12_VENDE_COSAS_CASA,
         fic.P13_COSAS_AMIGOS,
         fic.P14_ROBA_CON_AMIGOS,
         fic.P15_CAMINA_SIN_RUMBO,
         fic.P16_TIEMPO_REDES,
         fic.P17_NECESIDAD_REDES,
         fic.P18_VIDEOJUEGOS,
         fic.P19_AMISTAD_REDES,
         fic.PUNTAJE_TOTAL,
         fic.NIVEL
      FROM fichas fic
      JOIN fechas fec
         ON fec.FI_ID_INTEGRANTE = fic.FI_ID_INTEGRANTE
         AND (fec.SF_ID_FASE = fic.SF_ID_FASE
            OR (fec.SF_ID_FASE IS NULL AND fic.SF_ID_FASE IS NULL))
      JOIN SSI_FAMILIA_INTEGRANTES fi
         ON fi.FI_ID_INTEGRANTE = fic.FI_ID_INTEGRANTE
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
      LEFT JOIN SSI_ZONA_INTERVENCION zi
         ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
         AND zi.SI_ID_SERVICIO = v_id_servicio
      LEFT JOIN SSI_ANEXO_FASES af
         ON af.SF_ID_FASE = fic.SF_ID_FASE
      LEFT JOIN TGCATALOGO cat
         ON cat.IDCATALOGO = fi.CA_ID_PARENTESCO
      LEFT JOIN codigos cod
         ON cod.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
      WHERE fic.FILTRO_FECHA_CUMPLE = 1
         AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL OR p_fecha_ini <= p_fecha_fin)
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
      ORDER BY zi.ZO_ID_ZONA NULLS LAST,
         fi.PF_ID_FAMILIA,
         fic.FI_ID_INTEGRANTE,
         fic.SF_ID_FASE NULLS LAST;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'Error en PRC_CONDUCTAS_RIESGO_LISTAR ['
         || TO_CHAR(v_error_code) || ']: ' || v_error_message;
      -- Limite en BYTES, sin partir caracteres multibyte.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_CONDUCTAS_RIESGO_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- Ejemplos manuales separados de la creacion: NO EJECUTADOS.
-- Todo el bloque esta comentado; no forma parte de la instalacion.
-- DBMS_SQL.RETURN_RESULT requiere cliente/Oracle compatibles; si no
-- esta disponible, consumir y cerrar el SYS_REFCURSOR desde el caller.
-- Sin filtros:
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_CONDUCTAS_RIESGO_LISTAR(p_cursor_out => v_cursor);
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Rango de dias completos (parametros a medianoche):
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_CONDUCTAS_RIESGO_LISTAR(
--       p_fecha_ini => DATE '2026-01-01',
--       p_fecha_fin => DATE '2026-12-31',
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
