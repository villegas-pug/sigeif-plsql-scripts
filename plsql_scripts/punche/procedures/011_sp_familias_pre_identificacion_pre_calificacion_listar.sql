-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_FAMILIAS_PRECALIF_LISTAR
-- Proposito: Familias activas PUNCHE: pre-identificacion y
--            pre-calificacion. UNA FILA POR FAMILIA, incluidas las
--            familias sin cuidador o sin respuestas de evaluacion.
-- Parametros:
--   p_fecha_ini IN DATE DEFAULT NULL: limite inferior incluido de
--      PF_FEC_REGISTRA; conserva la hora recibida, como referencia 003.
--   p_fecha_fin IN DATE DEFAULT NULL: limite superior exclusivo
--      p_fecha_fin + 1; enviar medianoche para incluir el dia completo.
--      NULL abre cada extremo. Rango invertido: cursor vacio.
--      PF_FEC_REGISTRA NULL entra solamente sin limites temporales.
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 = todas las zonas;
--      otro valor filtra PF.ZO_ID_ZONA; ID inexistente: cursor vacio.
--   p_cursor_out OUT SYS_REFCURSOR: 25 columnas, orden A-Y.
--      FECHA_REGISTRO final VARCHAR2(10) DD/MM/YYYY o NULL; DATE interno
--      y hora fisica intactos, formato gregoriano mediante EXTRACT.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-10-01
-- Alcance : Solo lectura; SQL estatico, sin transacciones ni logging DML.
-- =============================================================
-- CONTRATO Y TRAZABILIDAD
-- * Plantilla: 7_reporte_familias_pre-identificacion_pre-calificacion.xlsx,
--   hoja visible FAM_REF, encabezados fila 2. Fila 3 heredada NO define
--   aliases. Categorias es auxiliar/oculta. No se agregan columnas de1
--   adulto mayor/discapacidad, totales, correo o geografia del cuidador.
-- * Poblacion: PF.SI_ID_SERVICIO=2, PF_ESTADO=1, PF_ELIMINADO=0.
--   Zona es enriquecimiento LEFT JOIN, sin exigir actividad ni servicio
--   de zona: no sustituye el servicio de familia ni excluye familias.
-- * Cuidador actual: FI_CUIDADOR=1, FI_ESTADO=1, FI_ELIMINADO=0.
--   Usuario garantiza SOLO UN cuidador por familia: garantia funcional,
--   NO constraint UNIQUE confirmado. Ausencia: datos NULL. No seleccion
--   arbitraria, DISTINCT ocultador ni reconstruccion historica del rol.
-- * Respuestas V1 exclusivamente familiares: PF_ID_FAMILIA presente,
--   FI_ID_INTEGRANTE NULL y AR_DESTINATARIO=1 (consumidor familiar local
--   usps_ssi_inabif_v1.sql). No derivar familia ni mezclar individuales.
--   AR_ELIMINADO=0; preguntas del servicio 2 no eliminadas. No inventar
--   filtro AN_ESTADO o SF_ID_FASE. IDs explicitos definen las preguntas;
--   no imponer AP_NUM_ANEXO=7 a 1537 sin evidencia de su registro actual.
-- * Latest autorizado = mayor AR_ID_RESPUESTA por familia/pregunta;
--   contenido actual de esa fila. NO significa ultima modificacion:
--   productor local permite UPDATE conservando ID. Ninguna fecha ordena
--   respuestas. Filtro de poblacion familiar intacto. Visibilidad del bloque
--   anexo: sin limites o alguna MISMA ultima fila con AR_FECHA_REGISTRA
--   dentro de ambos extremos. Admite incluso texto '0'/NULL; no recorta items
--   ni recupera antiguas. Indicador agrupado: como maximo una fila/familia.
-- * V: 404-416 y 855, esta ultima entre 408 y 409 (orden del formulario
--   confirmado en el handoff). W: 423-432. Solo AR_RESPUESTA='1' afirma;
--   '0'/NULL/otros no afirman. Texto AP_PREGUNTA actual, separador ' | '.
--   Sin afirmativas o sin respuestas: NULL. No usar AR_OBSERVACION.
-- * X: texto original AR_RESPUESTA de 1537; no inventar equivalencia
--   entre valores de estado y APROBADO/DESAPROBADO del ejemplo XLSX.
-- * Y: AR_RESPUESTA de 396 por decision explicita. Seed historico llama
--   a 396 'Profesional que ha referido'; no se usa personal asignado.
-- * T: todos los MR_ID_MOTIVO activos/no eliminados, orden numerico,
--   separados por ' | '. Un motivo repetido se representa una sola vez
--   por su identidad (conjunto de motivos, no ultima fila arbitraria).
-- * A: correlativo del resultado ordenado por zona y PF_ID_FAMILIA;
--   cuatro cifras hasta 9999, sin truncar cantidades mayores. No es
--   codigo persistido y no usa PF_COD_FAMILIA/SSI_CODIGOS_FAMILIAS.
-- * JOINs inferidos, confianza >=90% por mapeo usuario, nombres y tipos:
--   pf.ZO_ID_ZONA=zi.ZO_ID_ZONA; pf.AL_ID_ALIADO=al.AL_ID_ALIADO;
--   al.INS_ID_INSTITUCION=ins.IDINSTITUCION;
--   al.UBI_ID_UBIGEO=ub.U_ID_UBIGEO;
--   fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA; fi.PA_ID_NAC=pa.IDPAIS;
--   ar.PF_ID_FAMILIA=pf.PF_ID_FAMILIA; ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA;
--   fmr.PF_ID_FAMILIA=pf.PF_ID_FAMILIA. No FK/UNIQUE acreditadas por el
--   catalogo de columnas. Maestros esperados N:1 por ID; enriquecimientos
--   ausentes devuelven NULL. No filtrar actividad de aliado/institucion
--   para preservar la fuente referente registrada en la familia.
-- * Nacionalidad: TG_PAIS.PA_NACIONALIDAD (precedente consumidor local),
--   no PA_NOMBRE ni PA_GENTILICIO. Documentos/telefonos conservan texto.
-- * LISTAGG puede exceder limites VARCHAR2 (ORA-01489); no se trunca ni
--   oculta el error. No se garantizan indices: posibles full scans,
--   OR-NULL y ordenamientos analiticos/LISTAGG. No plan medido en Oracle.
-- * Verificacion estatica exclusivamente. El caller consume/cierra el
--   cursor; errores durante FETCH pertenecen al caller. Cursor vacio
--   no lanza NO_DATA_FOUND. Unicidad de IDs maestros requerida.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_FAMILIAS_PRECALIF_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio   SSI_POTENCIALES_FAMILIAS.SI_ID_SERVICIO%TYPE := 2;
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      WITH familias AS (
         SELECT pf.PF_ID_FAMILIA,
            pf.ZO_ID_ZONA,
            pf.AL_ID_ALIADO,
            pf.PF_FEC_REGISTRA,
            pf.PF_OBSERVACIONES
         FROM SSI_POTENCIALES_FAMILIAS pf
         WHERE pf.SI_ID_SERVICIO = v_id_servicio
            AND pf.PF_ESTADO = 1
            AND pf.PF_ELIMINADO = 0
            AND (p_fecha_ini IS NULL OR pf.PF_FEC_REGISTRA >= p_fecha_ini)
            AND (p_fecha_fin IS NULL OR pf.PF_FEC_REGISTRA < p_fecha_fin + 1)
            AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL
                 OR p_fecha_ini <= p_fecha_fin)
            AND (p_id_zona IS NULL OR p_id_zona = -1
                 OR pf.ZO_ID_ZONA = p_id_zona)
      ), respuestas_ordenadas AS (
         SELECT ar.PF_ID_FAMILIA,
            ar.AP_ID_PREGUNTA,
            ar.AR_RESPUESTA,
            ar.AR_FECHA_REGISTRA,
            ROW_NUMBER() OVER (
               PARTITION BY ar.PF_ID_FAMILIA, ar.AP_ID_PREGUNTA
               ORDER BY ar.AR_ID_RESPUESTA DESC
            ) AS ORDEN_RESPUESTA
         FROM SSI_ANEXOS_RESPUESTAS ar
         JOIN familias fam
            ON fam.PF_ID_FAMILIA = ar.PF_ID_FAMILIA
         WHERE ar.FI_ID_INTEGRANTE IS NULL
            AND ar.AR_DESTINATARIO = 1
            AND ar.AR_ELIMINADO = 0
            AND ar.AP_ID_PREGUNTA IN (
               396, 404, 405, 406, 407, 408, 855, 409, 410, 411,
               412, 413, 414, 415, 416, 423, 424, 425, 426, 427,
               428, 429, 430, 431, 432, 1537
            )
            AND EXISTS (
               SELECT 1
               FROM SSI_ANEXOS_PREGUNTAS ap
               WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
                  AND ap.SI_ID_SERVICIO = v_id_servicio
                  AND NVL(ap.AP_ELIMINADO, 0) = 0
            )
      ), ultimas AS (
         SELECT ro.PF_ID_FAMILIA, ro.AP_ID_PREGUNTA, ro.AR_RESPUESTA,
            ro.AR_FECHA_REGISTRA
         FROM respuestas_ordenadas ro
         WHERE ro.ORDEN_RESPUESTA = 1
      ), bloques_admitidos AS (
         SELECT ul.PF_ID_FAMILIA,
            MAX(CASE WHEN (p_fecha_ini IS NULL OR ul.AR_FECHA_REGISTRA >= p_fecha_ini)
               AND (p_fecha_fin IS NULL OR ul.AR_FECHA_REGISTRA < p_fecha_fin + 1)
               THEN 1 ELSE 0 END) AS BLOQUE_ADMITIDO
         FROM ultimas ul
         GROUP BY ul.PF_ID_FAMILIA
      ), evaluaciones AS (
         SELECT ul.PF_ID_FAMILIA,
            LISTAGG(
               CASE
                  WHEN (ul.AP_ID_PREGUNTA BETWEEN 404 AND 416
                        OR ul.AP_ID_PREGUNTA = 855)
                       AND ul.AR_RESPUESTA = '1' THEN ap.AP_PREGUNTA
               END, ' | '
            ) WITHIN GROUP (
               ORDER BY CASE
                  WHEN ul.AP_ID_PREGUNTA = 855 THEN 408.5
                  ELSE ul.AP_ID_PREGUNTA
               END
            ) AS EVALUACION_NNA,
            LISTAGG(
               CASE
                  WHEN ul.AP_ID_PREGUNTA BETWEEN 423 AND 432
                       AND ul.AR_RESPUESTA = '1' THEN ap.AP_PREGUNTA
               END, ' | '
            ) WITHIN GROUP (ORDER BY ul.AP_ID_PREGUNTA) AS EVALUACION_PAREJA
         FROM ultimas ul
         JOIN SSI_ANEXOS_PREGUNTAS ap
            ON ap.AP_ID_PREGUNTA = ul.AP_ID_PREGUNTA
            AND ap.SI_ID_SERVICIO = v_id_servicio
            AND NVL(ap.AP_ELIMINADO, 0) = 0
         WHERE ul.AP_ID_PREGUNTA BETWEEN 404 AND 416
            OR ul.AP_ID_PREGUNTA = 855
            OR ul.AP_ID_PREGUNTA BETWEEN 423 AND 432
         GROUP BY ul.PF_ID_FAMILIA
      ), motivos_unicos AS (
         SELECT fmr.PF_ID_FAMILIA, fmr.MR_ID_MOTIVO
         FROM SSI_FAMILIA_MOTIVO_REFERENCIA fmr
         JOIN familias fam
            ON fam.PF_ID_FAMILIA = fmr.PF_ID_FAMILIA
         WHERE fmr.FMR_ESTADO = 1
            AND fmr.FMR_ELIMINADO = 0
         GROUP BY fmr.PF_ID_FAMILIA, fmr.MR_ID_MOTIVO
      ), motivos AS (
         SELECT mu.PF_ID_FAMILIA,
            LISTAGG(TO_CHAR(mu.MR_ID_MOTIVO, 'TM9'), ' | ')
               WITHIN GROUP (ORDER BY mu.MR_ID_MOTIVO) AS MOTIVO_REFERENCIA
         FROM motivos_unicos mu
         GROUP BY mu.PF_ID_FAMILIA
      ), reporte AS (
         SELECT
            ROW_NUMBER() OVER (
               ORDER BY fam.ZO_ID_ZONA ASC NULLS LAST, fam.PF_ID_FAMILIA
            ) AS CORRELATIVO,
            zi.ZO_DESCRIPCION AS ZONA_INTERVENCION,
            fam.PF_FEC_REGISTRA AS FECHA_REGISTRO,
            ins.INSNOMBRE AS INSTITUCION_REFERENTE,
            al.AL_REPRESENTANTE AS REPRESENTANTE_REFERENTE,
            al.AL_TELEFONO AS TELEFONO_REFERENTE,
            ub.U_DEPARTAMENTO AS DEPARTAMENTO_REFERENTE,
            ub.U_PROVINCIA AS PROVINCIA_REFERENTE,
            ub.U_DISTRITO AS DISTRITO_REFERENTE,
            al.AL_TIPO_ALIADO AS TIPO_ALIADO,
            fi.FI_NUMERO_DOC AS DOCUMENTO_CUIDADOR,
            fi.FI_PRIMER_APE AS PRIMER_APELLIDO_CUIDADOR,
            fi.FI_SEGUNDO_APE AS SEGUNDO_APELLIDO_CUIDADOR,
            fi.FI_NOMBRES AS NOMBRES_CUIDADOR,
            pa.PA_NACIONALIDAD AS NACIONALIDAD_CUIDADOR,
            fi.FI_TELEFONO AS TELEFONO_CUIDADOR,
            fi.FI_DIRECCION AS DIRECCION_CUIDADOR,
            fi.FI_REFERENCIA_DOMICILIARIA AS REFERENCIA_DOMICILIO,
            fi.FI_CENTRO_POBLADO AS CENTRO_POBLADO,
            mot.MOTIVO_REFERENCIA,
            fam.PF_OBSERVACIONES AS OBSERVACION,
            CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
               THEN ev.EVALUACION_NNA END AS EVALUACION_NNA,
            CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
               THEN ev.EVALUACION_PAREJA END AS EVALUACION_PAREJA,
            CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
               THEN est.AR_RESPUESTA END AS ESTADO_IDENTIFICACION_FAMILIAR,
            CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
               THEN aco.AR_RESPUESTA END AS ACOMPANANTE_FAMILIAR
         FROM familias fam
         LEFT JOIN bloques_admitidos blo
            ON blo.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
         LEFT JOIN SSI_ZONA_INTERVENCION zi
            ON zi.ZO_ID_ZONA = fam.ZO_ID_ZONA
         LEFT JOIN SSI_ALIADOS al
            ON al.AL_ID_ALIADO = fam.AL_ID_ALIADO
         LEFT JOIN TGINSTITUCION ins
            ON ins.IDINSTITUCION = al.INS_ID_INSTITUCION
         LEFT JOIN SSI_UBIGEO_NOMBRES ub
            ON ub.U_ID_UBIGEO = al.UBI_ID_UBIGEO
         LEFT JOIN SSI_FAMILIA_INTEGRANTES fi
            ON fi.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
            AND fi.FI_CUIDADOR = 1
            AND fi.FI_ESTADO = 1
            AND fi.FI_ELIMINADO = 0
         LEFT JOIN TG_PAIS pa
            ON pa.IDPAIS = fi.PA_ID_NAC
         LEFT JOIN motivos mot
            ON mot.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
         LEFT JOIN evaluaciones ev
            ON ev.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
         LEFT JOIN ultimas est
            ON est.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
            AND est.AP_ID_PREGUNTA = 1537
         LEFT JOIN ultimas aco
            ON aco.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
            AND aco.AP_ID_PREGUNTA = 396
      )
      SELECT
         CASE
            WHEN rpt.CORRELATIVO <= 9999
               THEN TO_CHAR(rpt.CORRELATIVO, 'FM0000')
            ELSE TO_CHAR(rpt.CORRELATIVO, 'TM9')
         END AS NRO_FAMILIA,
         rpt.ZONA_INTERVENCION,
         CAST(CASE WHEN rpt.FECHA_REGISTRO >= DATE '0001-01-01' THEN
            TO_CHAR(EXTRACT(DAY FROM rpt.FECHA_REGISTRO), 'FM00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '/'
            || TO_CHAR(EXTRACT(MONTH FROM rpt.FECHA_REGISTRO), 'FM00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '/'
            || TO_CHAR(EXTRACT(YEAR FROM rpt.FECHA_REGISTRO), 'FM0000', 'NLS_NUMERIC_CHARACTERS=''.,''')
            ELSE NULL END AS VARCHAR2(10)) AS FECHA_REGISTRO,
         rpt.INSTITUCION_REFERENTE,
         rpt.REPRESENTANTE_REFERENTE,
         rpt.TELEFONO_REFERENTE,
         rpt.DEPARTAMENTO_REFERENTE,
         rpt.PROVINCIA_REFERENTE,
         rpt.DISTRITO_REFERENTE,
         rpt.TIPO_ALIADO,
         rpt.DOCUMENTO_CUIDADOR,
         rpt.PRIMER_APELLIDO_CUIDADOR,
         rpt.SEGUNDO_APELLIDO_CUIDADOR,
         rpt.NOMBRES_CUIDADOR,
         rpt.NACIONALIDAD_CUIDADOR,
         rpt.TELEFONO_CUIDADOR,
         rpt.DIRECCION_CUIDADOR,
         rpt.REFERENCIA_DOMICILIO,
         rpt.CENTRO_POBLADO,
         rpt.MOTIVO_REFERENCIA,
         rpt.OBSERVACION,
         rpt.EVALUACION_NNA,
         rpt.EVALUACION_PAREJA,
         rpt.ESTADO_IDENTIFICACION_FAMILIAR,
         rpt.ACOMPANANTE_FAMILIAR
      FROM reporte rpt
      ORDER BY rpt.CORRELATIVO;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      -- Mensaje acotado a 450 caracteres (<=1800 bytes en AL32UTF8).
      -- TRUE conserva tambien la pila original; no altera transacciones.
      RAISE_APPLICATION_ERROR(
         -20999,
         SUBSTR('PRC_FAMILIAS_PRECALIF_LISTAR ['
            || TO_CHAR(v_error_code, 'TM9') || ']: ' || v_error_message,
            1, 450),
         TRUE
      );
END PRC_FAMILIAS_PRECALIF_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- INVOCACIONES MANUALES: NO EJECUTADAS. Separadas de la creacion.
-- Descomentar SOLO en un flujo de ejecucion autorizado independiente.
-- DBMS_SQL.RETURN_RESULT requiere Oracle 12c+ y cliente compatible con
-- resultados implicitos. El consumidor debe consumir/cerrar el cursor.
-- =============================================================
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_FAMILIAS_PRECALIF_LISTAR(
--       p_fecha_ini  => NULL,
--       p_fecha_fin  => NULL,
--       p_id_zona    => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /

-- Ejemplo con dias completos; fechas ilustrativas, sin IDs inventados.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_FAMILIAS_PRECALIF_LISTAR(
--       p_fecha_ini  => DATE '2026-01-01',
--       p_fecha_fin  => DATE '2026-01-31',
--       p_id_zona    => NULL,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
