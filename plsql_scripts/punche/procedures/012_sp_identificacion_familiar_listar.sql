-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_IDENT_FAMILIAR_LISTAR
-- Proposito: Identificacion familiar PUNCHE (servicio 2).
-- Grano   : UNA FILA POR FAMILIA activa/no eliminada, incluidas
--           familias sin cuidador, codigo, respuestas o maestros.
-- Parametros (mismo orden, tipos y defaults que referencia 003):
--   p_fecha_ini IN DATE DEFAULT NULL: PF_FEC_REGISTRA >= inicio.
--   p_fecha_fin IN DATE DEFAULT NULL: PF_FEC_REGISTRA < fin + 1.
--      NULL abre cada extremo. Se conserva la hora recibida;
--      enviar medianoche para dias completos. Inicio > fin: vacio.
--      Fecha de familia NULL entra solo sin limites temporales.
--   p_id_zona IN NUMBER DEFAULT -1: NULL/-1 todas; otro valor exacto
--      sobre PF.ZO_ID_ZONA. Zona inexistente: cursor vacio.
--   p_cursor_out OUT SYS_REFCURSOR: 60 columnas, orden A-BH.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-10-01
-- Alcance : Solo lectura; SELECT estatico, sin control transaccional.
-- =============================================================
-- PLANTILLA Y CONTRATO RESUELTO
-- * inputs/reports/templates/identificacion_familiar.xlsx.
--   Evidencia de inspeccion local entregada por Build: hoja visible
--   IDENT FAM, dimension A1:BH12; Categorias oculta es auxiliar.
--   Encabezados funcionales fila 2, opciones fila 3; NO tomar aliases
--   legacy de fila 4 como semantica (AP=Columna1, BE=FEC_ING).
-- * Poblacion: PF.SI_ID_SERVICIO=2, PF_ESTADO=1, PF_ELIMINADO=0.
--   Zona LEFT, sin exigir estado/servicio de zona ni OR multiservicio.
-- * Cuidador actual: FI_CUIDADOR=1, FI_ESTADO=1, FI_ELIMINADO=0.
--   Usuario garantiza <=1 por familia, NO UNIQUE acreditado. Si falta,
--   personales NULL. No escoger menor ID ni reconstruir rol historico.
-- * Respuestas V1 exclusivamente familiares: PF_ID_FAMILIA presente,
--   FI_ID_INTEGRANTE NULL y AR_DESTINATARIO=1; AR_ELIMINADO=0.
--   Productor familiar: usps_ssi_inabif_v1.sql, guardado por familia;
--   consumidor USP_BUSCAR_RESPUESTAS_POR_PARAMETROS identifica rol 1.
--   Filas individuales/mixtas/incompatibles NO compiten en latest;
--   no derivar familia desde integrante ni ocultar conflictos con NVL.
--   Preguntas del servicio 2, NVL(AP_ELIMINADO,0)=0. No imponer fase,
--   AN_ESTADO o numero de anexo a 1537 sin evidencia de su registro.
-- * Latest autorizado: mayor AR_ID_RESPUESTA por familia/pregunta,
--   despues de elegibilidad; independiente del filtro de fecha familiar.
--   No equivale a ultima modificacion: UPDATE local puede conservar ID.
--   Poblacion/fecha familiar intactas. Bloque anexo visible sin limites o
--   si alguna MISMA ultima fila satisface ambos limites por AR_FECHA_REGISTRA,
--   incluso con texto '0'/NULL. Indicador agrupado: una fila/familia como maximo.
--   No recortar items/resumenes ni recuperar antiguas; ocultar solo proyeccion.
-- * J: codigo principal familiar, servicio 2/tipo 1, activo/no eliminado,
--   FI_ID_INTEGRANTE NULL; mayor CF_ID_CODIGO entre elegibles. Ausente
--   NULL. Sin MAX textual, PF_COD_FAMILIA ni formula de ejemplo Excel.
--   Tipos de codigo: USP_GENERAR_CODIGO_FAMILIA, fuente local V1.
-- * A: correlativo del resultado por zona NULLS LAST y PF_ID_FAMILIA,
--   cuatro cifras hasta 9999, sin truncar numeros mayores. No persistido.
-- * Descripciones CA_ID_*: TGCATALOGO.IDCATALOGO -> CATDESCRIPCION,
--   conforme consumidor de cuidador local y reporte 009. Sin filtro de
--   vigencia del maestro: describir el valor registrado, no excluirlo.
--   AL usa CA_ID_OCUPACION, no ordinales contradictorios del Excel.
-- * AA/BH: 1=SI, 0=NO, NULL/otros=NULL; no inventar valores desconocidos.
--   BH usa PF_FAMILIA_APTA, NO PF_INTEGRANTE_APTO ni resultado de riesgos.
--   Codificacion: consumidor indicador discapacidad y productor codigo
--   principal (PF_FAMILIA_APTA=1) en usps_ssi_inabif_v1.sql.
-- * AB: FI_CONADIS texto original, NO FI_INSCRIPCION_CONADIS ni ID de
--   catalogo. AC: descripcion CA_ID_DISCAPACIDAD. AD: texto original
--   FI_GRADO_DISCAPACIDAD VARCHAR2(200); productor GRADODISCAPACIDAD
--   tambien textual. AB/AC/AD solo si CA_TIENE_DISCAPACIDAD=1, como 009.
--   No copiar conversion implicita de gravedad del reporte Acercandonos.
-- * AH/AJ: FI_OTRA_LENGUA_MATERNA/FI_OTRA_COSTUMBRE originales, segun
--   productor local OTRALENGUAMATERNA/OTRACOSTUMBRE. Sin condicionar a
--   ordinales Excel ni fallback a FI_OTRO_IDIOMA/FI_OTRO_ETNIA legacy.
-- * AP/AV repiten AL_REPRESENTANTE por mapeo explicito; AU/AX usan
--   AL_DIRECCION/AL_CORREO. AY repite H=FI_CENTRO_POBLADO por mapeo
--   usuario confirmado por Build; NO inventar centro poblado institucional.
-- * AZ: conjunto de motivos activos/no eliminados de la familia, una
--   entrada por MR_ID_MOTIVO; MR_DESCRIPCION actual, orden por ID,
--   separador ' | '. Maestro ausente aporta NULL; no filtrar su vigencia
--   para describir el vinculo registrado. No usar muestras numericas de BA.
--   BA=PF_OBSERVACIONES por mapeo explicito, no FI_OBSERVACIONES.
-- * BB: preguntas 404..416 y 855, esta entre 408/409. BC: 423..432.
--   Solo AR_RESPUESTA='1' afirma (consumidor local de ficha de familia).
--   Resumen AP_PREGUNTA actual en orden formulario, separado por ' | '.
--   '0'/NULL/otros no afirman; sin afirmativas/respuestas, resumen NULL.
--   No incluir preguntas 417..422, adjunto 924 ni columnas de totales.
-- * BD: AR_RESPUESTA1537 original. DESAPROBADO del Excel no acredita
--   codificacion numerica: no traducir ni calcular el estado.
-- * BE: fuente AR_RESPUESTA1719, NO PF_FECHA_COMPROMISO. Solo salida final:
--   VARCHAR2(10) DD/MM/YYYY o NULL; TRIM ASCII, DD/MM/YYYY e ISO estrictos
--   con calendario gregoriano. Visibilidad del bloque intacta, sin TO_DATE.
--   N/AO: DATE internos y horas intactos; salida VARCHAR2(10) gregoriana
--   mediante EXTRACT, dominio positivo. Invalidos/ausentes -> NULL.
-- * BF: 396 original si contiene caracteres no whitespace; si no,
--   nombre completo del personal PF.PER_ID_PERSONAL -> TRPERSONAL ->
--   TGPERSONA. BG: PERNRODOCUMENTO SOLO si BF usa ese respaldo con nombre
--   disponible. BF desde 396 implica BG=NULL; nunca enlazar por nombre.
--   Documento textual conservado; no inferir tipo DNI por su longitud.
--   Si 396 es valida pero bloque oculto: BF/BG NULL, sin activar respaldo.
--   Si 396 realmente falta/NULL/whitespace: respaldo original independiente
--   de visibilidad. El JOIN y la decision de existencia usan 396 global.
--
-- MAPEO POSICIONAL A-BH (catalogos = CATDESCRIPCION)
-- A correlativo; B ZO_DESCRIPCION; C PF.ZO_ID_ZONA; D ZO.UBI_ID_UBIGEO;
-- E/F/G geografia zona; H FI_CENTRO_POBLADO; I FI_DIRECCION; J CF_CODIGO.
-- K FI_PRIMER_APE; L FI_SEGUNDO_APE; M FI_NOMBRES; N FI_FEC_NAC;
-- O FI_EDAD; P CA_ID_SEXO; Q FI_CANT_INTEGRANTES; R FI_CANT_NNA;
-- S CA_ID_TIPO_FAMILIA; T FI_TELEFONO; U FI_CORREO; V CA_ID_TIPDOC;
-- W FI_NUMERO_DOC; X PA_ID_PAIS_NACIMIENTO -> PA_NOMBRE;
-- Y CA_ID_ESTADO_CIVIL; Z CA_ID_PARENTESCO; AA CA_TIENE_DISCAPACIDAD;
-- AB FI_CONADIS; AC CA_ID_DISCAPACIDAD; AD FI_GRADO_DISCAPACIDAD;
-- AE CA_ID_UBICACION_VIVIENDA; AF CA_ID_TIPO_VIVIENDA;
-- AG CA_ID_LENGUA_MATERNA; AH FI_OTRA_LENGUA_MATERNA; AI CA_ID_ETNIA;
-- AJ FI_OTRA_COSTUMBRE; AK CA_ID_GRADO_INST; AL CA_ID_OCUPACION;
-- AM CA_ID_TIPO_SEGURO; AN AL_TIPO_ALIADO; AO PF_FEC_REGISTRA;
-- AP AL_REPRESENTANTE; AQ INSNOMBRE; AR/AS/AT geografia aliado;
-- AU AL_DIRECCION; AV AL_REPRESENTANTE; AW AL_TELEFONO; AX AL_CORREO;
-- AY FI_CENTRO_POBLADO; AZ motivos; BA PF_OBSERVACIONES;
-- BB resumen NNA; BC resumen pareja; BD 1537; BE 1719; BF 396/respaldo;
-- BG documento solo del respaldo; BH PF_FAMILIA_APTA SI/NO/NULL.
--
-- INFERENCIAS Y CARDINALIDAD: NO FK/UNIQUE ACREDITADAS POR CATALOGO
-- * Confianza estimada >=90% por nombres, tipos, mapeo y precedentes:
--   pf.ZO_ID_ZONA=zi.ZO_ID_ZONA; fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA;
--   cf.PF_ID_FAMILIA=pf.PF_ID_FAMILIA; ar.PF_ID_FAMILIA=pf.PF_ID_FAMILIA;
--   ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA; CA_ID_*=TGCATALOGO.IDCATALOGO;
--   fi.PA_ID_PAIS_NACIMIENTO=pa.IDPAIS;
--   pf.AL_ID_ALIADO=al.AL_ID_ALIADO; al.INS_ID_INSTITUCION=ins.IDINSTITUCION;
--   zi/al.UBI_ID_UBIGEO=SSI_UBIGEO_NOMBRES.U_ID_UBIGEO;
--   fmr.PF_ID_FAMILIA=pf.PF_ID_FAMILIA; fmr.MR_ID_MOTIVO=mr.MR_ID_MOTIVO;
--   pf.PER_ID_PERSONAL=per.IDPERSONAL; per.PRHPERSONA=pe.IDPERSONA.
-- * D-G geografia de zona, no residencia del cuidador: consumidor local
--   cte_zonas_intervencion y bloque inicial Excel; AY del cuidador por
--   mapeo explicito aunque este dentro del bloque institucional.
-- * LEFT enriquecimientos conservan nulos; N:0..1 esperado a maestros,
--   cuidador 0..1 por garantia usuario. Latest respuestas/codigos y
--   resumenes de motivos/riesgos se reducen ANTES del JOIN final.
-- * Unicidad de IDs maestros/familia/respuesta/codigo y U_ID_UBIGEO es
--   prerrequisito de integridad no demostrado por catalogo de columnas.
--   Duplicados pueden multiplicar filas; no ocultar con DISTINCT/MAX
--   o primera fila arbitraria. No se declaran indices ni constraints.
-- * Riesgos: posibles full scans, filtros OR-NULL, ordenamientos latest,
--   ROW_NUMBER/LISTAGG y lookups. LISTAGG puede lanzar ORA-01489; no
--   truncar silenciosamente resumenes. No hay plan medido en Oracle.
-- * Cursor vacio no lanza NO_DATA_FOUND. Caller consume/cierra cursor;
--   errores durante FETCH pueden ocurrir fuera del handler del OPEN.
--   Handler captura SQLCODE/SQLERRM, limita diagnostico a 2048 BYTES
--   por caracteres completos y conserva pila original, sin logging DML.
-- * Validacion exclusivamente estatica: NO compilado/ejecutado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_IDENT_FAMILIAR_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio   SSI_POTENCIALES_FAMILIAS.SI_ID_SERVICIO%TYPE := 2;
   v_tipo_codigo   SSI_CODIGOS_FAMILIAS.CF_TIPO_CODIGO%TYPE := 1;
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
   v_diagnostico   VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      WITH familias AS (
         SELECT pf.PF_ID_FAMILIA,
            pf.ZO_ID_ZONA,
            pf.AL_ID_ALIADO,
            pf.PER_ID_PERSONAL,
            pf.PF_FEC_REGISTRA,
            pf.PF_OBSERVACIONES,
            pf.PF_FAMILIA_APTA,
            ROW_NUMBER() OVER (
               ORDER BY pf.ZO_ID_ZONA ASC NULLS LAST, pf.PF_ID_FAMILIA
            ) AS CORRELATIVO
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
      ), codigos_ordenados AS (
         SELECT cf.PF_ID_FAMILIA,
            cf.CF_CODIGO,
            ROW_NUMBER() OVER (
               PARTITION BY cf.PF_ID_FAMILIA
               ORDER BY cf.CF_ID_CODIGO DESC
            ) AS ORDEN_CODIGO
         FROM SSI_CODIGOS_FAMILIAS cf
         JOIN familias fam
            ON fam.PF_ID_FAMILIA = cf.PF_ID_FAMILIA
         WHERE cf.SI_ID_SERVICIO = v_id_servicio
            AND cf.CF_TIPO_CODIGO = v_tipo_codigo
            AND cf.CF_ESTADO = 1
            AND cf.CF_ELIMINADO = 0
            AND cf.FI_ID_INTEGRANTE IS NULL
      ), codigos AS (
         SELECT co.PF_ID_FAMILIA, co.CF_CODIGO
         FROM codigos_ordenados co
         WHERE co.ORDEN_CODIGO = 1
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
         WHERE ar.PF_ID_FAMILIA IS NOT NULL
            AND ar.FI_ID_INTEGRANTE IS NULL
            AND ar.AR_DESTINATARIO = 1
            AND ar.AR_ELIMINADO = 0
            AND ar.AP_ID_PREGUNTA IN (
               396, 404, 405, 406, 407, 408, 855, 409, 410, 411,
               412, 413, 414, 415, 416, 423, 424, 425, 426, 427,
               428, 429, 430, 431, 432, 1537, 1719
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
                  WHEN ul.AP_ID_PREGUNTA BETWEEN 404 AND 416
                       OR ul.AP_ID_PREGUNTA = 855 THEN ap.AP_PREGUNTA
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
                     THEN ap.AP_PREGUNTA
               END, ' | '
            ) WITHIN GROUP (
               ORDER BY ul.AP_ID_PREGUNTA
            ) AS EVALUACION_PAREJA
         FROM ultimas ul
         JOIN SSI_ANEXOS_PREGUNTAS ap
            ON ap.AP_ID_PREGUNTA = ul.AP_ID_PREGUNTA
            AND ap.SI_ID_SERVICIO = v_id_servicio
            AND NVL(ap.AP_ELIMINADO, 0) = 0
         WHERE ul.AR_RESPUESTA = '1'
            AND (ul.AP_ID_PREGUNTA BETWEEN 404 AND 416
                 OR ul.AP_ID_PREGUNTA = 855
                 OR ul.AP_ID_PREGUNTA BETWEEN 423 AND 432)
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
            LISTAGG(mr.MR_DESCRIPCION, ' | ')
               WITHIN GROUP (ORDER BY mu.MR_ID_MOTIVO) AS MOTIVO_REFERENCIA
         FROM motivos_unicos mu
         LEFT JOIN SSI_MOTIVO_REFERENCIA mr
            ON mr.MR_ID_MOTIVO = mu.MR_ID_MOTIVO
         GROUP BY mu.PF_ID_FAMILIA
      ), personal AS (
         SELECT per.IDPERSONAL,
            TRIM(pe.PERNOMBRE || ' ' || pe.PERAPEPATERNO
               || ' ' || pe.PERAPEMATERNO) AS NOMBRE_COMPLETO,
            pe.PERNRODOCUMENTO
         FROM TRPERSONAL per
         LEFT JOIN TGPERSONA pe
            ON pe.IDPERSONA = per.PRHPERSONA
      )
      SELECT
         -- A (01)
         CASE
            WHEN fam.CORRELATIVO <= 9999
               THEN TO_CHAR(fam.CORRELATIVO, 'FM0000')
            ELSE TO_CHAR(fam.CORRELATIVO, 'TM9')
         END AS NRO_FAMILIA,
         -- B (02)
         zi.ZO_DESCRIPCION AS ZONA_INTERVENCION,
         -- C (03)
         fam.ZO_ID_ZONA AS CODIGO_ZONA,
         -- D (04)
         zi.UBI_ID_UBIGEO AS UBIGEO,
         -- E (05)
         uz.U_DEPARTAMENTO AS DEPARTAMENTO,
         -- F (06)
         uz.U_PROVINCIA AS PROVINCIA,
         -- G (07)
         uz.U_DISTRITO AS DISTRITO,
         -- H (08)
         fi.FI_CENTRO_POBLADO AS CENTRO_POBLADO,
         -- I (09)
         fi.FI_DIRECCION AS DIRECCION,
         -- J (10)
         cod.CF_CODIGO AS CODIGO_FAMILIA,
         -- K (11)
         fi.FI_PRIMER_APE AS PRIMER_APELLIDO_CUIDADOR,
         -- L (12)
         fi.FI_SEGUNDO_APE AS SEGUNDO_APELLIDO_CUIDADOR,
         -- M (13)
         fi.FI_NOMBRES AS NOMBRES_CUIDADOR,
         -- N (14)
         CAST(CASE WHEN fi.FI_FEC_NAC >= DATE '0001-01-01' THEN
            TO_CHAR(EXTRACT(DAY FROM fi.FI_FEC_NAC), 'FM00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '/'
            || TO_CHAR(EXTRACT(MONTH FROM fi.FI_FEC_NAC), 'FM00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '/'
            || TO_CHAR(EXTRACT(YEAR FROM fi.FI_FEC_NAC), 'FM0000', 'NLS_NUMERIC_CHARACTERS=''.,''')
            ELSE NULL END AS VARCHAR2(10)) AS FECHA_NACIMIENTO,
         -- O (15)
         fi.FI_EDAD AS EDAD,
         -- P (16)
         sex.CATDESCRIPCION AS SEXO,
         -- Q (17)
         fi.FI_CANT_INTEGRANTES AS NUMERO_MIEMBROS_FAMILIA,
         -- R (18)
         fi.FI_CANT_NNA AS NUMERO_NNA,
         -- S (19)
         tf.CATDESCRIPCION AS TIPO_FAMILIA,
         -- T (20)
         fi.FI_TELEFONO AS TELEFONO_CUIDADOR,
         -- U (21)
         fi.FI_CORREO AS CORREO_CUIDADOR,
         -- V (22)
         doc.CATDESCRIPCION AS TIPO_DOCUMENTO,
         -- W (23)
         fi.FI_NUMERO_DOC AS NUMERO_DOCUMENTO,
         -- X (24)
         pa.PA_NOMBRE AS PAIS_NACIMIENTO,
         -- Y (25)
         civ.CATDESCRIPCION AS ESTADO_CIVIL,
         -- Z (26)
         par.CATDESCRIPCION AS PARENTESCO,
         -- AA (27)
         CASE fi.CA_TIENE_DISCAPACIDAD
            WHEN 1 THEN 'SI'
            WHEN 0 THEN 'NO'
            ELSE NULL
         END AS TIENE_DISCAPACIDAD,
         -- AB (28)
         CASE WHEN fi.CA_TIENE_DISCAPACIDAD = 1
            THEN fi.FI_CONADIS END AS REGISTRO_CONADIS,
         -- AC (29)
         disc.CATDESCRIPCION AS TIPO_DISCAPACIDAD,
         -- AD (30)
         CASE WHEN fi.CA_TIENE_DISCAPACIDAD = 1
            THEN fi.FI_GRADO_DISCAPACIDAD END AS GRAVEDAD_DISCAPACIDAD,
         -- AE (31)
         uv.CATDESCRIPCION AS UBICACION_VIVIENDA,
         -- AF (32)
         tv.CATDESCRIPCION AS TIPO_VIVIENDA,
         -- AG (33)
         leng.CATDESCRIPCION AS LENGUA_MATERNA,
         -- AH (34)
         fi.FI_OTRA_LENGUA_MATERNA AS LENGUA_MATERNA_ESPECIFICAR,
         -- AI (35)
         etn.CATDESCRIPCION AS AUTOIDENTIFICACION_ETNICA,
         -- AJ (36)
         fi.FI_OTRA_COSTUMBRE AS ETNIA_ESPECIFICAR,
         -- AK (37)
         inst.CATDESCRIPCION AS GRADO_INSTRUCCION,
         -- AL (38)
         ocup.CATDESCRIPCION AS OCUPACION,
         -- AM (39)
         seg.CATDESCRIPCION AS TIPO_SEGURO_SALUD,
         -- AN (40)
         al.AL_TIPO_ALIADO AS TIPO_ALIADO,
         -- AO (41)
         CAST(CASE WHEN fam.PF_FEC_REGISTRA >= DATE '0001-01-01' THEN
            TO_CHAR(EXTRACT(DAY FROM fam.PF_FEC_REGISTRA), 'FM00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '/'
            || TO_CHAR(EXTRACT(MONTH FROM fam.PF_FEC_REGISTRA), 'FM00', 'NLS_NUMERIC_CHARACTERS=''.,''') || '/'
            || TO_CHAR(EXTRACT(YEAR FROM fam.PF_FEC_REGISTRA), 'FM0000', 'NLS_NUMERIC_CHARACTERS=''.,''')
            ELSE NULL END AS VARCHAR2(10)) AS FECHA_REGISTRO_REFERENCIA,
         -- AP (42)
         al.AL_REPRESENTANTE AS REPRESENTANTE_REFERENTE,
         -- AQ (43)
         ins.INSNOMBRE AS INSTITUCION_REFERENTE,
         -- AR (44)
         ua.U_DEPARTAMENTO AS DEPARTAMENTO_INSTITUCION,
         -- AS (45)
         ua.U_PROVINCIA AS PROVINCIA_INSTITUCION,
         -- AT (46)
         ua.U_DISTRITO AS DISTRITO_INSTITUCION,
         -- AU (47)
         al.AL_DIRECCION AS DIRECCION_INSTITUCION,
         -- AV (48)
         al.AL_REPRESENTANTE AS PROFESIONAL_REFIERE,
         -- AW (49)
         al.AL_TELEFONO AS TELEFONO_PROFESIONAL_REFIERE,
         -- AX (50)
         al.AL_CORREO AS CORREO_PROFESIONAL_REFIERE,
         -- AY (51)
         fi.FI_CENTRO_POBLADO AS CENTRO_POBLADO_REFERENCIADO,
         -- AZ (52)
         mot.MOTIVO_REFERENCIA AS MOTIVO_REFERENCIA,
         -- BA (53)
         fam.PF_OBSERVACIONES AS OBSERVACION,
         -- BB (54)
         CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
            THEN ev.EVALUACION_NNA END AS EVALUACION_NNA,
         -- BC (55)
         CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
            THEN ev.EVALUACION_PAREJA END AS EVALUACION_PAREJA,
         -- BD (56)
         CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
            THEN est.AR_RESPUESTA END AS ESTADO_IDENTIFICACION_FAMILIAR,
         -- BE (57)
         CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
            THEN CAST(CASE
               WHEN LENGTH(TRIM(comp.AR_RESPUESTA)) = 10
                  AND REGEXP_LIKE(TRIM(comp.AR_RESPUESTA), '^[0-9]{2}/[0-9]{2}/[0-9]{4}$', 'c')
               THEN CASE
                  WHEN TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 9999
                     AND TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 12
                     AND TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 1, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND
                        CASE TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 4, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
                           WHEN 2 THEN 28 + CASE
                              WHEN MOD(TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 400) = 0
                                 OR (MOD(TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 4) = 0
                                    AND MOD(TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 7, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 100) <> 0)
                              THEN 1 ELSE 0 END
                           WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30 ELSE 31 END
                  THEN TRIM(comp.AR_RESPUESTA)
                  ELSE NULL END
               WHEN LENGTH(TRIM(comp.AR_RESPUESTA)) = 10
                  AND REGEXP_LIKE(TRIM(comp.AR_RESPUESTA), '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', 'c')
               THEN CASE
                  WHEN TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 9999
                     AND TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND 12
                     AND TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 9, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 1 AND
                        CASE TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 6, 2), '99', 'NLS_NUMERIC_CHARACTERS=''.,''')
                           WHEN 2 THEN 28 + CASE
                              WHEN MOD(TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 400) = 0
                                 OR (MOD(TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 4) = 0
                                    AND MOD(TO_NUMBER(SUBSTR(TRIM(comp.AR_RESPUESTA), 1, 4), '9999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 100) <> 0)
                              THEN 1 ELSE 0 END
                           WHEN 4 THEN 30 WHEN 6 THEN 30 WHEN 9 THEN 30 WHEN 11 THEN 30 ELSE 31 END
                  THEN SUBSTR(TRIM(comp.AR_RESPUESTA), 9, 2) || '/' || SUBSTR(TRIM(comp.AR_RESPUESTA), 6, 2) || '/' || SUBSTR(TRIM(comp.AR_RESPUESTA), 1, 4)
                  ELSE NULL END
               ELSE NULL END AS VARCHAR2(10)) END AS FECHA_COMPROMISO_FAMILIAR,
         -- BF (58)
         CASE WHEN REGEXP_LIKE(aco.AR_RESPUESTA, '[^[:space:]]')
            THEN CASE WHEN (p_fecha_ini IS NULL AND p_fecha_fin IS NULL) OR blo.BLOQUE_ADMITIDO = 1
               THEN aco.AR_RESPUESTA END
            ELSE per.NOMBRE_COMPLETO
         END AS ACOMPANANTE_FAMILIAR,
         -- BG (59)
         CASE WHEN REGEXP_LIKE(aco.AR_RESPUESTA, '[^[:space:]]')
            THEN NULL
            WHEN per.NOMBRE_COMPLETO IS NOT NULL THEN per.PERNRODOCUMENTO
            ELSE NULL
         END AS DNI_ACOMPANANTE_FAMILIAR,
         -- BH (60)
         CASE fam.PF_FAMILIA_APTA
            WHEN 1 THEN 'SI'
            WHEN 0 THEN 'NO'
            ELSE NULL
         END AS APTO
      FROM familias fam
      LEFT JOIN bloques_admitidos blo
         ON blo.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
      LEFT JOIN SSI_ZONA_INTERVENCION zi
         ON zi.ZO_ID_ZONA = fam.ZO_ID_ZONA
      LEFT JOIN SSI_UBIGEO_NOMBRES uz
         ON uz.U_ID_UBIGEO = zi.UBI_ID_UBIGEO
      LEFT JOIN SSI_FAMILIA_INTEGRANTES fi
         ON fi.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
         AND fi.FI_CUIDADOR = 1
         AND fi.FI_ESTADO = 1
         AND fi.FI_ELIMINADO = 0
      LEFT JOIN codigos cod
         ON cod.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
      LEFT JOIN TGCATALOGO sex
         ON sex.IDCATALOGO = fi.CA_ID_SEXO
      LEFT JOIN TGCATALOGO tf
         ON tf.IDCATALOGO = fi.CA_ID_TIPO_FAMILIA
      LEFT JOIN TGCATALOGO doc
         ON doc.IDCATALOGO = fi.CA_ID_TIPDOC
      LEFT JOIN TG_PAIS pa
         ON pa.IDPAIS = fi.PA_ID_PAIS_NACIMIENTO
      LEFT JOIN TGCATALOGO civ
         ON civ.IDCATALOGO = fi.CA_ID_ESTADO_CIVIL
      LEFT JOIN TGCATALOGO par
         ON par.IDCATALOGO = fi.CA_ID_PARENTESCO
      LEFT JOIN TGCATALOGO disc
         ON disc.IDCATALOGO = fi.CA_ID_DISCAPACIDAD
         AND fi.CA_TIENE_DISCAPACIDAD = 1
      LEFT JOIN TGCATALOGO uv
         ON uv.IDCATALOGO = fi.CA_ID_UBICACION_VIVIENDA
      LEFT JOIN TGCATALOGO tv
         ON tv.IDCATALOGO = fi.CA_ID_TIPO_VIVIENDA
      LEFT JOIN TGCATALOGO leng
         ON leng.IDCATALOGO = fi.CA_ID_LENGUA_MATERNA
      LEFT JOIN TGCATALOGO etn
         ON etn.IDCATALOGO = fi.CA_ID_ETNIA
      LEFT JOIN TGCATALOGO inst
         ON inst.IDCATALOGO = fi.CA_ID_GRADO_INST
      LEFT JOIN TGCATALOGO ocup
         ON ocup.IDCATALOGO = fi.CA_ID_OCUPACION
      LEFT JOIN TGCATALOGO seg
         ON seg.IDCATALOGO = fi.CA_ID_TIPO_SEGURO
      LEFT JOIN SSI_ALIADOS al
         ON al.AL_ID_ALIADO = fam.AL_ID_ALIADO
      LEFT JOIN TGINSTITUCION ins
         ON ins.IDINSTITUCION = al.INS_ID_INSTITUCION
      LEFT JOIN SSI_UBIGEO_NOMBRES ua
         ON ua.U_ID_UBIGEO = al.UBI_ID_UBIGEO
      LEFT JOIN motivos mot
         ON mot.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
      LEFT JOIN evaluaciones ev
         ON ev.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
      LEFT JOIN ultimas est
         ON est.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
         AND est.AP_ID_PREGUNTA = 1537
      LEFT JOIN ultimas comp
         ON comp.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
         AND comp.AP_ID_PREGUNTA = 1719
      LEFT JOIN ultimas aco
         ON aco.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
         AND aco.AP_ID_PREGUNTA = 396
      LEFT JOIN personal per
         ON per.IDPERSONAL = fam.PER_ID_PERSONAL
      ORDER BY fam.CORRELATIVO;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'PRC_IDENT_FAMILIAR_LISTAR [SQLCODE='
         || TO_CHAR(v_error_code, 'TM9') || ']: ' || v_error_message;
      -- Recortar caracteres completos, no bytes que partan multibyte.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_IDENT_FAMILIAR_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- INVOCACION MANUAL SEPARADA - COMENTADA, NO EJECUTADA
-- Descomentar solo en un flujo de ejecucion autorizado independiente.
-- DBMS_SQL.RETURN_RESULT requiere Oracle 12c+ y cliente compatible con
-- resultados implicitos; el receptor consume/cierra el cursor.
-- No se inventan IDs de zona: NULL/-1 todas o ID conocido por el caller.
-- =============================================================
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_IDENT_FAMILIAR_LISTAR(
--       p_fecha_ini => NULL,
--       p_fecha_fin => NULL,
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
