-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_FAMILIAS_SEGUIMIENTO_LISTAR
-- Proposito: Anexo 25 PUNCHE, seguimiento del servicio a la familia.
-- Grano   : UNA FILA POR FAMILIA con alguna ultima respuesta elegible.
-- Parametros (firma identica a 003):
--   p_fecha_ini IN DATE DEFAULT NULL: registro >= limite, incluida hora.
--   p_fecha_fin IN DATE DEFAULT NULL: registro < limite + 1, sin TRUNC.
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 todas; otro valor zona exacta.
--   p_cursor_out OUT SYS_REFCURSOR: 32 columnas, orden A-AF de plantilla.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-09-30
-- Alcance : Solo lectura; SELECT estatico, sin efectos laterales.
-- =============================================================
-- CONTRATO Y EVIDENCIA
-- Plantilla: 25_reporte_seguimiento_servicio_brinda_familia.xlsx.
-- Hoja unica: Seguimiento al servicio. Encabezados descriptivos fila 2.
-- Fila 3 contiene identificadores heredados desalineados: no se utiliza.
-- XLSX inspeccionado localmente mediante ZIP/XML, sin modificarlo.
-- Fuente V1: SSI_ANEXOS_RESPUESTAS, sustentada por referencia 003 y
-- productor/consumidor generico usps_ssi_inabif_v1.sql. No se mezcla V2.
-- Usuario: solo ficha familiar; una aplicacion por familia; se permiten
-- las ultimas respuestas. PF_ID_FAMILIA no NULL y FI_ID_INTEGRANTE NULL
-- delimitan este reporte. No se incorporan respuestas individuales,
-- ni se deriva familia desde integrantes. AR_DESTINATARIO nullable no
-- se usa para atribuir el sujeto a partir de su default.
--
-- LATEST (inferencia tecnica, no confirmacion especifica del usuario):
-- Por familia/pregunta sobre respuestas no eliminadas del anexo/servicio.
-- AR_FECHA_REGISTRA DESC NULLS LAST; AR_ID_RESPUESTA DESC solo desempata.
-- El ID no representa fecha. No se agrupa por dia ni se inventa fase.
-- Latest precede el filtro: una version antigua no reaparece cuando la
-- ultima queda fuera del rango. Cada pregunta se filtra por su propio
-- registro; las columnas fuera del rango quedan NULL y una familia sin
-- ninguna ultima respuesta elegible no aparece. No es filtro por una
-- fecha unica de aplicacion (V1 no aporta aqui una clave de aplicacion).
-- Una ultima respuesta con texto NULL no recupera el texto anterior.
-- G=4318 se entrega como texto original; no conversion NLS ni mascara
-- inventada. G NO es la fecha del filtro.
--
-- TEMPORALIDAD: mismos predicados efectivos de 003, sin TRUNC:
-- registro >= p_fecha_ini; registro < p_fecha_fin + 1. Para dias completos
-- enviar parametros a medianoche. NULL abre el extremo correspondiente.
-- Registro NULL solo entra sin ambos limites. No se agrega validacion de
-- rango invertido: el +1 de 003 puede admitir fechas cuando ini > fin
-- por menos de un dia; su comentario legacy no describe siempre su SQL.
-- Zona NULL/-1 = todas; ID inexistente = cursor vacio.
--
-- CUIDADOR: FI_CUIDADOR=1, activo/no eliminado, datos actuales.
-- Usuario confirma un unico integrante cuidador por familia: supuesto
-- de integridad funcional, NO constraint catalogada. LEFT JOIN conserva
-- ausencia con D/E NULL; no ROW_NUMBER, menor ID ni MAX de cuidadores.
-- Si la integridad declarada se incumple, el JOIN puede multiplicar filas.
-- No se reconstruyen cuidador/acompanante historicos.
-- Acompanante actual: pf.PER_ID_PERSONAL -> TRPERSONAL -> TGPERSONA.
-- Codigo: MAX(CF_CODIGO) autorizado expresamente, NO ultimo codigo.
-- Servicio 2, tipo principal familiar 1, activo/no eliminado, sin sujeto
-- individual. LEFT JOIN agregado conserva ausencia, sin PF_COD_FAMILIA.
-- Servicio estricto de familia y zona = 2: no copiar defensa OR de 003.
-- Estados de familias/zonas y preguntas/respuestas siguen precedentes;
-- no se agrega AN_ESTADO ni SF_ID_FASE sin evidencia funcional.
--
-- JOINS INFERIDOS, NO FK/UNIQUE CONFIRMADAS POR EL CATALOGO:
-- ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA (N:1, confianza 95%).
-- ar.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (N:1, confianza 95%).
-- pf.ZO_ID_ZONA=zi.ZO_ID_ZONA (N:1, confianza 95%).
-- fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (0:1 cuidador declarado, 95%).
-- fi.CA_ID_PARENTESCO=cat.IDCATALOGO (N:0/1, confianza 90%).
-- pf.PER_ID_PERSONAL=per.IDPERSONAL (N:0/1, confianza 95%).
-- per.PRHPERSONA=pe.IDPERSONA (N:0/1, confianza 95%).
-- cf.PF_ID_FAMILIA=pf.PF_ID_FAMILIA (0:1 tras agregacion, 95%).
-- Evidencia: nombres/tipos del catalogo, 001/003 y productor V1.
-- Pregunta/familia/zona son INNER JOIN; datos de enriquecimiento LEFT.
-- Se presupone unicidad de IDs maestros; NOT NULL no prueba unicidad.
-- MAX en pivote solo transforma una fila seleccionada por pregunta;
-- no decide entre respuestas. No DISTINCT para ocultar multiplicaciones.
--
-- MAPEO fila 2 / posicion XLSX:
-- A Nro; B ZONA DE INTERVENCION; C CODIGO DE FAMILIA;
-- D Nombre del Cuidador principal; E Parentesco con el NNA;
-- F Nombr de Acompanante familiar responsable;
-- G Fecha de seguimiento=4318;
-- H Desarrolla las sesiones segun programacion=1294;
-- I Ha participado de los talleres segun lo programado=1295;
-- J Tema tratado en la ultima sesion=1296;
-- K Tiempo de duracion de la ultima sesion=1297;
-- L Recibio informacion acerca las redes de su comunidad/funciones=1299;
-- M Cuenta con un directorio de las redes de apoyo=1300;
-- N Si su respuesta fue NO, Por que=1301;
-- O Nombre de la red local que usa con mayor frecuencia=1302;
-- P Recibio/viene recibiendo capacitacion de economia familiar=1304;
-- Q Si SI, detalle los temas recibidos=1305;
-- R Institucion o red que brindo la capacitacion=1306;
-- S Principales dificultades durante capacitacion=1307;
-- T Acompanante llega a la hora programada=1309;
-- U Se entendio el tema de la sesion=1310;
-- V Acompanante emplea materiales para la sesion=1311;
-- W Acompanante dinamico y motivador=1312;
-- X Tema responde a necesidades de la familia=1313;
-- Y Satisfaccion con informacion brindada=1314;
-- Z Acompanante motiva poner en practica compromisos=1315;
-- AA Cumple compromisos propuestos en consejeria=1316;
-- AB Si NO, explique por que=1317; AC Si SI, describa cuales=1318;
-- AD Acompanante motiva participacion del grupo en talleres=1319;
-- AE Lo que mas gusta de talleres=1320;
-- AF Acciones de mejora implementadas por familia=1322.
-- Secciones 1289/1293/1298/1303/1308/1321 no son respuestas.
-- Auxiliares 1337/1339/1340/1542 no exigidos: no se proyectan.
--
-- RIESGOS: posibles full scans, filtros OR-NULL, ordenamiento de latest
-- y resultado; indices/planes no verificados. Enriquecimiento actual.
-- Cursor vacio no lanza NO_DATA_FOUND. Errores en FETCH son del caller,
-- responsable de consumir/cerrar el cursor. RAISE conserva diagnostico
-- original; SQLCODE/SQLERRM se capturan sin DML ni control transaccional.
-- Revision exclusivamente estatica, sin compilacion/ejecucion Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_FAMILIAS_SEGUIMIENTO_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_servicio      SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE := 2;
   v_anexo         SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE := 25;
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      WITH familias AS (
         SELECT pf.PF_ID_FAMILIA, pf.PER_ID_PERSONAL,
            zi.ZO_ID_ZONA, zi.ZO_DESCRIPCION
         FROM SSI_POTENCIALES_FAMILIAS pf
         JOIN SSI_ZONA_INTERVENCION zi
            ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
         WHERE pf.SI_ID_SERVICIO = v_servicio
            AND pf.PF_ESTADO = 1
            AND pf.PF_ELIMINADO = 0
            AND zi.SI_ID_SERVICIO = v_servicio
            AND zi.ZO_ESTADO = 1
            AND zi.ZO_ELIMINADO = 0
            AND (p_id_zona IS NULL OR p_id_zona = -1
                 OR zi.ZO_ID_ZONA = p_id_zona)
      ), ordenadas AS (
         SELECT ar.PF_ID_FAMILIA, ar.AP_ID_PREGUNTA,
            ar.AR_RESPUESTA, ar.AR_FECHA_REGISTRA,
            ROW_NUMBER() OVER (
               PARTITION BY ar.PF_ID_FAMILIA, ar.AP_ID_PREGUNTA
               ORDER BY ar.AR_FECHA_REGISTRA DESC NULLS LAST,
                  ar.AR_ID_RESPUESTA DESC
            ) AS RN_RESPUESTA
         FROM SSI_ANEXOS_RESPUESTAS ar
         JOIN SSI_ANEXOS_PREGUNTAS ap
            ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         JOIN familias fam
            ON fam.PF_ID_FAMILIA = ar.PF_ID_FAMILIA
         WHERE ap.SI_ID_SERVICIO = v_servicio
            AND ap.AP_NUM_ANEXO = v_anexo
            AND NVL(ap.AP_ELIMINADO, 0) = 0
            AND ar.AR_ELIMINADO = 0
            AND ar.PF_ID_FAMILIA IS NOT NULL
            AND ar.FI_ID_INTEGRANTE IS NULL
            AND ap.AP_ID_PREGUNTA IN (
               4318, 1294, 1295, 1296, 1297, 1299, 1300, 1301, 1302,
               1304, 1305, 1306, 1307, 1309, 1310, 1311, 1312, 1313,
               1314, 1315, 1316, 1317, 1318, 1319, 1320, 1322
            )
      ), elegibles AS (
         SELECT ord.PF_ID_FAMILIA, ord.AP_ID_PREGUNTA, ord.AR_RESPUESTA
         FROM ordenadas ord
         WHERE ord.RN_RESPUESTA = 1
            AND (p_fecha_ini IS NULL
                 OR ord.AR_FECHA_REGISTRA >= p_fecha_ini)
            AND (p_fecha_fin IS NULL
                 OR ord.AR_FECHA_REGISTRA < p_fecha_fin + 1)
      ), respuestas AS (
         SELECT ele.PF_ID_FAMILIA,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 4318 THEN ele.AR_RESPUESTA END) AS FECHA_SEGUIMIENTO,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1294 THEN ele.AR_RESPUESTA END) AS SESIONES_PROGRAMACION,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1295 THEN ele.AR_RESPUESTA END) AS TALLERES_PROGRAMACION,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1296 THEN ele.AR_RESPUESTA END) AS TEMA_ULTIMA_SESION,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1297 THEN ele.AR_RESPUESTA END) AS DURACION_ULTIMA_SESION,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1299 THEN ele.AR_RESPUESTA END) AS INFORMACION_REDES,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1300 THEN ele.AR_RESPUESTA END) AS DIRECTORIO_REDES,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1301 THEN ele.AR_RESPUESTA END) AS MOTIVO_SIN_DIRECTORIO,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1302 THEN ele.AR_RESPUESTA END) AS RED_MAS_FRECUENTE,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1304 THEN ele.AR_RESPUESTA END) AS CAPACITACION_ECONOMIA,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1305 THEN ele.AR_RESPUESTA END) AS TEMAS_RECIBIDOS,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1306 THEN ele.AR_RESPUESTA END) AS INSTITUCION_CAPACITADORA,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1307 THEN ele.AR_RESPUESTA END) AS DIFICULTADES_CAPACITACION,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1309 THEN ele.AR_RESPUESTA END) AS PUNTUALIDAD_ACOMPANANTE,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1310 THEN ele.AR_RESPUESTA END) AS COMPRENSION_TEMA,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1311 THEN ele.AR_RESPUESTA END) AS MATERIALES_SESION,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1312 THEN ele.AR_RESPUESTA END) AS DINAMICO_MOTIVADOR,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1313 THEN ele.AR_RESPUESTA END) AS RESPONDE_NECESIDADES,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1314 THEN ele.AR_RESPUESTA END) AS SATISFACCION_INFORMACION,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1315 THEN ele.AR_RESPUESTA END) AS MOTIVA_COMPROMISOS,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1316 THEN ele.AR_RESPUESTA END) AS CUMPLE_COMPROMISOS,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1317 THEN ele.AR_RESPUESTA END) AS EXPLICACION_NO_CUMPLE,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1318 THEN ele.AR_RESPUESTA END) AS DESCRIPCION_COMPROMISOS,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1319 THEN ele.AR_RESPUESTA END) AS MOTIVA_PARTICIPACION,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1320 THEN ele.AR_RESPUESTA END) AS GUSTA_TALLERES,
            MAX(CASE WHEN ele.AP_ID_PREGUNTA = 1322 THEN ele.AR_RESPUESTA END) AS MEJORAS_FAMILIA
         FROM elegibles ele
         GROUP BY ele.PF_ID_FAMILIA
      ), codigos AS (
         SELECT cf.PF_ID_FAMILIA, MAX(cf.CF_CODIGO) AS CODIGO_FAMILIA
         FROM SSI_CODIGOS_FAMILIAS cf
         WHERE cf.SI_ID_SERVICIO = v_servicio
            AND cf.CF_TIPO_CODIGO = 1
            AND cf.CF_ESTADO = 1
            AND cf.CF_ELIMINADO = 0
            AND cf.FI_ID_INTEGRANTE IS NULL
         GROUP BY cf.PF_ID_FAMILIA
      )
      SELECT
         ROW_NUMBER() OVER (ORDER BY fam.ZO_ID_ZONA, fam.PF_ID_FAMILIA) AS NRO,
         fam.ZO_DESCRIPCION AS ZONA_INTERVENCION,
         cod.CODIGO_FAMILIA AS CODIGO_FAMILIA,
         TRIM(fi.FI_NOMBRES || ' ' || fi.FI_PRIMER_APE || ' '
            || fi.FI_SEGUNDO_APE) AS NOMBRE_CUIDADOR,
         cat.CATDESCRIPCION AS PARENTESCO_NNA,
         TRIM(pe.PERNOMBRE || ' ' || pe.PERAPEPATERNO || ' '
            || pe.PERAPEMATERNO) AS ACOMPANANTE_RESPONSABLE,
         res.FECHA_SEGUIMIENTO,
         res.SESIONES_PROGRAMACION,
         res.TALLERES_PROGRAMACION,
         res.TEMA_ULTIMA_SESION,
         res.DURACION_ULTIMA_SESION,
         res.INFORMACION_REDES,
         res.DIRECTORIO_REDES,
         res.MOTIVO_SIN_DIRECTORIO,
         res.RED_MAS_FRECUENTE,
         res.CAPACITACION_ECONOMIA,
         res.TEMAS_RECIBIDOS,
         res.INSTITUCION_CAPACITADORA,
         res.DIFICULTADES_CAPACITACION,
         res.PUNTUALIDAD_ACOMPANANTE,
         res.COMPRENSION_TEMA,
         res.MATERIALES_SESION,
         res.DINAMICO_MOTIVADOR,
         res.RESPONDE_NECESIDADES,
         res.SATISFACCION_INFORMACION,
         res.MOTIVA_COMPROMISOS,
         res.CUMPLE_COMPROMISOS,
         res.EXPLICACION_NO_CUMPLE,
         res.DESCRIPCION_COMPROMISOS,
         res.MOTIVA_PARTICIPACION,
         res.GUSTA_TALLERES,
         res.MEJORAS_FAMILIA
      FROM respuestas res
      JOIN familias fam
         ON fam.PF_ID_FAMILIA = res.PF_ID_FAMILIA
      LEFT JOIN SSI_FAMILIA_INTEGRANTES fi
         ON fi.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
         AND fi.FI_CUIDADOR = 1
         AND fi.FI_ESTADO = 1
         AND fi.FI_ELIMINADO = 0
      LEFT JOIN TGCATALOGO cat
         ON cat.IDCATALOGO = fi.CA_ID_PARENTESCO
      LEFT JOIN TRPERSONAL per
         ON per.IDPERSONAL = fam.PER_ID_PERSONAL
      LEFT JOIN TGPERSONA pe
         ON pe.IDPERSONA = per.PRHPERSONA
      LEFT JOIN codigos cod
         ON cod.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
      ORDER BY fam.ZO_ID_ZONA, fam.PF_ID_FAMILIA;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      -- Propaga codigo, mensaje y backtrace originales sin reemplazarlos.
      RAISE;
END PRC_FAMILIAS_SEGUIMIENTO_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- INVOCACIONES MANUALES SEPARADAS - NO EJECUTADAS
-- Todo el bloque esta comentado: instalar no invoca el reporte.
-- El consumidor debe FETCH y CLOSE el SYS_REFCURSOR.
-- =============================================================
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_FAMILIAS_SEGUIMIENTO_LISTAR(
--       p_fecha_ini  => NULL,
--       p_fecha_fin  => NULL,
--       p_id_zona    => -1,
--       p_cursor_out => v_cursor
--    );
--    -- Ejemplo de apertura/cierre, sin consumir resultados.
--    CLOSE v_cursor;
-- EXCEPTION
--    WHEN OTHERS THEN
--       IF v_cursor%ISOPEN THEN
--          CLOSE v_cursor;
--       END IF;
--       RAISE;
-- END;
-- /
-- Para un rango, sustituir los argumentos nombrados, por ejemplo:
-- p_fecha_ini => DATE '2026-09-01', p_fecha_fin => DATE '2026-09-30'.
-- Para una zona, usar un ZO_ID_ZONA real del servicio 2; no se inventa ID.
