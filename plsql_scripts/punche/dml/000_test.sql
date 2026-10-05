-- =============================================================================
-- Tipo    : SELECT (test exploratorio, solo lectura)
-- Nombre  : 000_test.sql
-- Propósito: Listar el detalle PATFAM (SSI_DET_PATFAM) de una familia,
--            filtrado por su código de familia
--            (SSI_POTENCIALES_FAMILIAS.PF_COD_FAMILIA).
--            Incluye cabecera SSI_PATFAM como contexto.
-- Autor   : [ REEMPLAZAR: nombre del autor ]
-- Fecha   : 2026-08-15
-- =============================================================================
-- Cadena de joins:
--   SSI_POTENCIALES_FAMILIAS pf  (PF_COD_FAMILIA = '150143-8-0171')
--     -> SSI_PATFAM pa           (pa.PF_ID_FAMILIA = pf.PF_ID_FAMILIA)
--     -> SSI_DET_PATFAM dp       (dp.PA_ID_PATFAM = pa.PA_ID_PATFAM)
-- Notas:
--   * El filtro de estado/eliminado está comentado: descomentar si solo
--     se quieren registros activos.
-- =============================================================================

-- * 1. Detalle PATFAM por código de familia
SELECT
   pf.PF_ID_FAMILIA,
   pf.PF_COD_FAMILIA,
   pa.PA_ID_PATFAM,
   pa.PA_MOTIVO_REFERENCIA,
   pa.PA_DIAGNOSTICO,
   pa.PA_NOMBRE_CUIDADOR,
   pa.PA_ZONA_INTERVENCION,
   dp.DP_ID_DET_PATFAM,
   dp.OE_ID_OBJETIVO,
   dp.MO_ID_MODULO,
   dp.UN_ID_UNIDAD,
   dp.TE_ID_TEMA,
   dp.SE_ID_SESION,
   dp.TA_ID_TALLER,
   dp.DP_FECHA_REGISTRA,
   dp.DP_ESTADO,
   dp.DP_ELIMINADO
FROM SSI_POTENCIALES_FAMILIAS pf
JOIN SSI_PATFAM pa
   ON pa.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
JOIN SSI_DET_PATFAM dp
   ON dp.PA_ID_PATFAM = pa.PA_ID_PATFAM
WHERE
   pf.PF_COD_FAMILIA = '150143-8-0171'
   -- AND pa.PA_ELIMINADO = 0
   -- AND pa.PA_ESTADO    = 1
   -- AND dp.DP_ELIMINADO = 0
   -- AND dp.DP_ESTADO    = 1
ORDER BY
   pa.PA_ID_PATFAM,
   dp.DP_ID_DET_PATFAM
/

-- * 2. Aux: verificar existencia de la familia por código (ejecutar si 1. devuelve 0 filas)
SELECT
   pf.PF_ID_FAMILIA,
   pf.PF_COD_FAMILIA,
   pf.SI_ID_SERVICIO,
   pf.PF_ESTADO,
   pf.PF_ELIMINADO
FROM SSI_POTENCIALES_FAMILIAS pf
WHERE
   pf.PF_COD_FAMILIA = '150143-8-0171'
/


SELECT * FROM SSI_DET_PATFAM
/

SELECT * FROM SSI_PROFESION
/

SELECT * FROM SSI_EQUIPO_TRABAJO
/

SELECT 
   pf.PER_ID_PERSONAL,
   COUNT(1) AS CANTIDAD_DETALLES_PATFAM
FROM SSI_POTENCIALES_FAMILIAS pf
WHERE 
   -- pf.EQ_ID_EQUIPO IS NOT NULL
   pf.PER_ID_PERSONAL IS NOT NULL
   AND pf.SI_ID_SERVICIO = 2
GROUP BY
   pf.PER_ID_PERSONAL
/

-- DP_ESTADO | DP_ELIMINADO


-- =============================================================================
-- Tipo    : DELETE (DML manual, requiere confirmacion del operador)
-- Bloque  : anexo20_servicio2_integrante10214
-- Proposito: Eliminar de SSI_ANEXOS_RESPUESTAS (V1) las respuestas del
--            Anexo 20 (Ficha de derivacion y/o referencia) del servicio
--            2 (PUNCHE) para el integrante FI_ID_INTEGRANTE = 10214.
--            V1 no expone ID_ANEXO: la ruta al anexo/servicio es
--            SSI_ANEXOS_RESPUESTAS.AP_ID_PREGUNTA -> SSI_ANEXOS_PREGUNTAS.
-- Autor   : OpenCode (data-validator)
-- Fecha   : 2026-08-12
-- Alcance : solo lectura en este agente; el COMMIT/ROLLBACK lo decide
--            el operador tras revisar el conteo previo.
-- =============================================================================
-- Notas:
--   * SI_ID_SERVICIO=2 (PUNCHE) y AP_NUM_ANEXO=20 (Ficha derivacion/referencia)
--     ya validados en usps_ssi_inabif_v1.sql lineas 3377-3381.
--   * No se toca SSI_ANEXOS_PREGUNTAS (catalogo maestro de preguntas).
--   * Convencion: EXISTS con subquery, alias ar/ap, identacion 3 espacios,
--     terminador /, marcadores -- ! COMMIT; y -- ? ROLLBACK;.
-- =============================================================================

-- * 1. SELECT de validacion previa (conteo de filas candidatas)
SELECT
   COUNT(1) AS total_a_eliminar
   -- ar.*
FROM SSI_ANEXOS_RESPUESTAS ar
WHERE ar.FI_ID_INTEGRANTE = 10214
   AND EXISTS (
      SELECT 1
      FROM SSI_ANEXOS_PREGUNTAS ap
      WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         AND ap.SI_ID_SERVICIO = 2
         AND ap.AP_NUM_ANEXO  = 20
   )
/

-- * 2. DELETE objetivo (mismo predicado que el conteo previo)
DELETE FROM SSI_ANEXOS_RESPUESTAS ar
WHERE ar.FI_ID_INTEGRANTE = 10214
   AND EXISTS (
      SELECT 1
      FROM SSI_ANEXOS_PREGUNTAS ap
      WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         AND ap.SI_ID_SERVICIO = 2
         AND ap.AP_NUM_ANEXO  = 20
   )
/

-- ! COMMIT;
-- ? ROLLBACK;
/

SELECT * FROM SSI_CODIGOS_FAMILIAS c
WHERE c.CF_TIPO_CODIGO = 'FAMILIA'
/

-- =============================================================================
-- Tipo    : DELETE (DML manual, requiere confirmacion del operador)
-- Bloque  : anexo27_servicio2_global
-- Proposito: Eliminar de SSI_ANEXOS_RESPUESTAS las respuestas del
--            Anexo 27 del servicio 2 (PUNCHE) para TODOS los
--            integrantes (sin filtro por FI_ID_INTEGRANTE).
-- Autor   : OpenCode (procedure-builder)
-- Fecha   : 2026-08-19
-- Alcance : solo lectura en este agente; el COMMIT/ROLLBACK lo decide
--            el operador tras revisar el conteo previo.
-- =============================================================================
-- Notas:
--   * SI_ID_SERVICIO=2 (PUNCHE) y AP_NUM_ANEXO=27 validados en el schema.
--   * No se toca SSI_ANEXOS_PREGUNTAS (catalogo maestro de preguntas).
--   * Convencion: EXISTS con subquery, alias ar/ap, identacion 3 espacios,
--     terminador /, marcadores -- ! COMMIT; y -- ? ROLLBACK;.
-- =============================================================================

-- * 1. SELECT de validacion previa (conteo de filas candidatas)
SELECT
   -- COUNT(1) AS total_a_eliminar
   ar.*
FROM SSI_ANEXOS_RESPUESTAS ar
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXOS_PREGUNTAS ap
   WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
      AND ap.SI_ID_SERVICIO = 2
      AND ap.AP_NUM_ANEXO  = 27
)
/

-- * 2. DELETE objetivo (mismo predicado que el conteo previo)
DELETE FROM SSI_ANEXOS_RESPUESTAS ar
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXOS_PREGUNTAS ap
   WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
      AND ap.SI_ID_SERVICIO = 2
      AND ap.AP_NUM_ANEXO  = 27
)
/


-- ! COMMIT;
-- ? ROLLBACK;
/

-- =============================================================================
-- Tipo    : DELETE (DML manual, requiere confirmacion del operador)
-- Bloque  : anexo27_servicio2_preguntas_catalogo
-- Proposito: Eliminar de SSI_ANEXOS_PREGUNTAS (catalogo maestro) las
--            preguntas del Anexo 27 del servicio 2 (PUNCHE).
--            Previamente se borraron las respuestas (anexo27_servicio2_global).
-- Autor   : OpenCode (procedure-builder)
-- Fecha   : 2026-08-19
-- Alcance : solo lectura en este agente; el COMMIT/ROLLBACK lo decide
--            el operador tras revisar el conteo previo.
-- =============================================================================
-- Notas:
--   * Requiere que el bloque anexo27_servicio2_global haya sido ejecutado
--     y commiteado (sino, ORA-02292 por FK SSI_ANEXOS_RESPUESTAS.AP_ID_PREGUNTA).
--   * SI_ID_SERVICIO=2 (PUNCHE) y AP_NUM_ANEXO=27 validados en el schema.
--   * Convencion: EXISTS con subquery, alias ap, identacion 3 espacios,
--     terminador /, marcadores -- ! COMMIT; y -- ? ROLLBACK;.
-- =============================================================================

-- * 1. SELECT de validacion previa: conteo de preguntas candidatas a borrar
SELECT
   -- COUNT(1) AS total_preguntas_a_eliminar
   ap.*
FROM SSI_ANEXOS_PREGUNTAS ap
WHERE ap.SI_ID_SERVICIO = 2
   AND ap.AP_NUM_ANEXO  = 27
/

-- * 2. SELECT de verificacion de FK residual: debe devolver 0 filas
--    (si devuelve >0, las respuestas NO fueron borradas/commiteadas y el DELETE fallara)
SELECT
   COUNT(1) AS respuestas_residuales
FROM SSI_ANEXOS_RESPUESTAS ar
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXOS_PREGUNTAS ap
   WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
      AND ap.SI_ID_SERVICIO = 2
      AND ap.AP_NUM_ANEXO  = 27
)
/

-- * 3. SELECT de dimensionamiento: cuantas preguntas por grupo dentro del Anexo 27
SELECT
   ap.AP_NUM_GRUPO,
   COUNT(1) AS preguntas_por_grupo
FROM SSI_ANEXOS_PREGUNTAS ap
WHERE ap.SI_ID_SERVICIO = 2
   AND ap.AP_NUM_ANEXO  = 27
GROUP BY ap.AP_NUM_GRUPO
ORDER BY ap.AP_NUM_GRUPO
/

-- * 4. SELECT de detalle: listado completo de preguntas a eliminar (para revision visual)
SELECT
   ap.AP_ID_PREGUNTA,
   ap.AP_NUM_GRUPO,
   ap.AP_NUM_PREGUNTA,
   SUBSTR(ap.AP_PREGUNTA, 1, 80) AS AP_PREGUNTA_PREVIEW,
   ap.AP_TIPO_CONTROL
FROM SSI_ANEXOS_PREGUNTAS ap
WHERE ap.SI_ID_SERVICIO = 2
   AND ap.AP_NUM_ANEXO  = 27
ORDER BY ap.AP_NUM_GRUPO, ap.AP_NUM_PREGUNTA
/

-- * 5. DELETE objetivo (mismo predicado que el conteo previo)
DELETE FROM SSI_ANEXOS_PREGUNTAS ap
WHERE ap.SI_ID_SERVICIO = 2
   AND ap.AP_NUM_ANEXO  = 27
/

-- ! COMMIT;
-- ? ROLLBACK;
/


UPDATE SSI_ANEXOS_PREGUNTAS ap
   SET ap.AP_PREGUNTA = 'OBJETIVO ESPECÍFICO 4'
WHERE 
   ap.AP_ID_PREGUNTA = 1365
/

-- 1349 | Objetivo Específico 1 y 2
-- 1358 | Objetivo Específico 3
-- 1365 | Objetivo Específico 4


SELECT 
   *
FROM SSI_ESP_INTERVENCION i
WHERE 
   -- TRIM(UPPER(i.ESP_NOMBRE)) = 'CAR BASICO IKARO XOBO'
   TRIM(UPPER(i.ESP_NOMBRE)) LIKE '%IKARO'
   -- AND ID_SERVICIO_PADRE = 4;
/




-- * Anexo 26: Seguimiento del progreso de la familia beneficiaria del servicio 2 (PUNCHE)

-- * 1. SELECT de detalle: listado completo de preguntas del Anexo 26 (para revision visual)
SELECT 
   -- ap.*
   ap.AP_ID_PREGUNTA,
   ap.AP_PREGUNTA
FROM SSI_ANEXOS_PREGUNTAS ap
WHERE 
   ap.SI_ID_SERVICIO = 2 -- Punche
   AND ap.AP_NUM_ANEXO  = 26 -- 26 | Anexo 26: Seguimiento del progreso de la familia beneficiaria del servicio 2 (PUNCHE)
/ 

-- * 2. SELECT de detalle: listado completo de respuestas del Anexo 26 (para revision visual)
SELECT
   -- ar.*
   -- ar.PF_ID_FAMILIA,
   ap.AP_ID_PREGUNTA,
   ap.AP_NUM_PREGUNTA,
   ap.AP_PREGUNTA,
   ar.AR_RESPUESTA
FROM SSI_ANEXOS_RESPUESTAS ar
JOIN SSI_ANEXOS_PREGUNTAS ap ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
WHERE 
   ap.SI_ID_SERVICIO = 2
   AND ap.AP_NUM_ANEXO  = 26
   AND ap.AP_NUM_GRUPO > 0
   -- AND ap.AP_NUM_PREGUNTA
ORDER BY
   ar.PF_ID_FAMILIA,
   ap.AP_NUM_GRUPO,
   ap.AP_NUM_PREGUNTA
   -- ap.AP_ID_PREGUNTA
   -- ar.AR_ID_RESPUESTA
/


-- =============================================================================
-- Tipo    : SELECT (reporte pivoteado, solo lectura)
-- Bloque  : anexo26_seguimiento_progreso_pivote
-- Proposito: Reporte pivoteado "Seguimiento del progreso de la familia
--            beneficiaria" del servicio 2 (PUNCHE), anexo 26. Una fila por
--            familia con el valor mas reciente por pregunta.
-- Columnas : N°, Zona de intervencion, Codigo de familia, datos del cuidador
--            principal (integrante con FI_CUIDADOR = 1), Fecha de evaluacion
--            (pregunta 1324), Acompanante familiar (FAMILIA -> TRPERSONAL
--            -> TGPERSONA) y respuestas pivoteadas:
--            I = 1385 Cumplimiento de compromisos objetivos 1 y 2
--            J = 1329 Capacitacion - Emprendimiento
--            K = 1330 Capacitacion - Educacion financiera
--            L = 1331 Capacitacion - Orientacion laboral
--            M = 1332 Capacitacion - (etiqueta por confirmar)
--            N = 1334 Al menos un miembro usa redes de soporte local
--            O = 1336 Participacion en incidencia comunitaria (ECFI)
-- Autor   : OpenCode (build)
-- Fecha   : 2026-09-28
-- Alcance : solo lectura. No ejecutar DML/DDL.
-- =============================================================================
-- Notas / supuestos:
--   * Valor por pregunta = fila con AR_FECHA_REGISTRA mas reciente por
--     (familia, pregunta), desempate AR_ID_RESPUESTA DESC. Se descarto la
--     clave de lote TRUNC(AR_FECHA_REGISTRA): verificado que una misma
--     evaluacion puede tener respuestas con fechas distintas, y el lote
--     descartaba preguntas (columnas vacias). Efecto: cada columna refleja
--     el ultimo valor de SU pregunta, aunque provenga de evaluaciones
--     distintas (mismo criterio de visualizacion de la app).
--   * Filtros inferidos (quitar si se requiere): pf.PF_ELIMINADO = 0,
--     fi.FI_ELIMINADO = 0, NVL(ap.AP_ELIMINADO, 0) = 0.
--   * Si una familia tuviera varios integrantes con FI_CUIDADOR = 1, se toma
--     el de menor FI_ID_INTEGRANTE (ROW_NUMBER en cte_cui).
--   * Cadena acompanante inferida (sin FK documentada en catalogo):
--     pf.PER_ID_PERSONAL = per.IDPERSONAL (TRPERSONAL),
--     per.PRHPERSONA = pe.IDPERSONA (TGPERSONA).
--   * Full table scans probables en SSI_ANEXOS_RESPUESTAS /
--     SSI_FAMILIA_INTEGRANTES si el volumen crece.
-- =============================================================================

-- * 3. Reporte pivoteado del Anexo 26 (una fila por familia, valor mas reciente por pregunta)
WITH cte_resp AS (
   SELECT ar.PF_ID_FAMILIA,
          ar.AP_ID_PREGUNTA,
          ar.AR_RESPUESTA,
          ROW_NUMBER() OVER (
             PARTITION BY ar.PF_ID_FAMILIA, ar.AP_ID_PREGUNTA
             ORDER BY ar.AR_FECHA_REGISTRA DESC, ar.AR_ID_RESPUESTA DESC
          ) AS RN_VALOR
   FROM SSI_ANEXOS_RESPUESTAS ar
   JOIN SSI_ANEXOS_PREGUNTAS ap
     ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
   WHERE ap.SI_ID_SERVICIO = 2
     AND ap.AP_NUM_ANEXO = 26
     AND ap.AP_ID_PREGUNTA IN (1324, 1329, 1330, 1331, 1332, 1334, 1336, 1385)
     AND NVL(ap.AP_ELIMINADO, 0) = 0
     AND ar.AR_ELIMINADO = 0
     AND ar.PF_ID_FAMILIA IS NOT NULL
),
cte_piv AS (
   SELECT cr.PF_ID_FAMILIA,
          MAX(CASE WHEN cr.AP_ID_PREGUNTA = 1324 THEN cr.AR_RESPUESTA END) AS FECHA_EVALUACION,
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
),
cte_cui AS (
   SELECT fi.PF_ID_FAMILIA,
          fi.FI_PRIMER_APE,
          fi.FI_SEGUNDO_APE,
          fi.FI_NOMBRES,
          ROW_NUMBER() OVER (PARTITION BY fi.PF_ID_FAMILIA
                             ORDER BY fi.FI_ID_INTEGRANTE) AS RN_CUIDADOR
   FROM SSI_FAMILIA_INTEGRANTES fi
   WHERE fi.FI_CUIDADOR = 1
     AND fi.FI_ELIMINADO = 0
)
SELECT 
      ROW_NUMBER() OVER (ORDER BY pf.PF_COD_FAMILIA) AS NUMERO,
       zi.ZO_DESCRIPCION                        AS ZONA_INTERVENCION,
       pf.PF_COD_FAMILIA                        AS CODIGO_FAMILIA,
       cui.FI_PRIMER_APE                        AS PRIMER_APELLIDO,
       cui.FI_SEGUNDO_APE                       AS SEGUNDO_APELLIDO,
       cui.FI_NOMBRES                           AS NOMBRES,
       piv.FECHA_EVALUACION                     AS FECHA_EVALUACION,
       pe.PERNOMBRE || ' ' || pe.PERAPEPATERNO || ' ' || pe.PERAPEMATERNO AS ACOMPANANTE_FAMILIAR,
       piv.CUMPLIMIENTO_COMPROMISOS_OBJ_1_2     AS CUMPLIMIENTO_COMPROMISOS_OBJ_1_2,
       piv.CAP_EMPRENDIMIENTO                   AS CAP_EMPRENDIMIENTO,
       piv.CAP_EDUCACION_FINANCIERA             AS CAP_EDUCACION_FINANCIERA,
       piv.CAP_ORIENTACION_LABORAL              AS CAP_ORIENTACION_LABORAL,
       piv.CAP_ARTICULADA_1332                  AS CAP_ARTICULADA_1332,
       piv.USO_REDES_SOPORTE_LOCAL              AS USO_REDES_SOPORTE_LOCAL,
       piv.PARTICIPA_INCIDENCIA_COMUNITARIA     AS PARTICIPA_INCIDENCIA_COMUNITARIA
FROM cte_piv piv
JOIN SSI_POTENCIALES_FAMILIAS pf
  ON pf.PF_ID_FAMILIA = piv.PF_ID_FAMILIA
 AND pf.SI_ID_SERVICIO = 2
LEFT JOIN SSI_ZONA_INTERVENCION zi
  ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
LEFT JOIN cte_cui cui
  ON cui.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
 AND cui.RN_CUIDADOR = 1
LEFT JOIN TRPERSONAL per
  ON per.IDPERSONAL = pf.PER_ID_PERSONAL
LEFT JOIN TGPERSONA pe
  ON pe.IDPERSONA = per.PRHPERSONA
WHERE 
   pf.PF_ELIMINADO = 0
   AND ROWNUM
ORDER BY pf.PF_COD_FAMILIA
/


-- =============================================================================
-- Reporte: Detalle PATFAM eliminados cuya unidad contiene
--          'Promoviendo habilidad(es) para la vida'
-- Tablas : SSI_DET_PATFAM, SSI_UNIDADES (+ enriquecimiento catálogo)
-- Notas  : Borrado lógico por flag DP_ELIMINADO = 1 (convención de proyecto).
--          JOIN principal confirmado por precedente en procedures del repo.
--          JOINs de enriquecimiento por convención de nombres (no FK catálogo).
--          Riesgo FTS en SSI_UNIDADES por LIKE con comodín inicial
--          (tabla catálogo pequeña, impacto despreciable).
-- Bind   : :p_texto_busqueda  (ej. '%HABILIDAD%PARA LA VIDA%')
-- =============================================================================
SELECT
    dp.DP_ID_DET_PATFAM        AS ID_DETALLE_PATFAM,
    dp.PA_ID_PATFAM            AS ID_PATFAM,
    pf.PF_ID_FAMILIA           AS ID_FAMILIA,
    pf.PA_NOMBRE_CUIDADOR      AS NOMBRE_CUIDADOR,
    dp.OE_ID_OBJETIVO          AS ID_OBJETIVO,
    dp.MO_ID_MODULO            AS ID_MODULO,
    mo.MO_NOMBRE               AS NOMBRE_MODULO,
    dp.UN_ID_UNIDAD            AS ID_UNIDAD,
    un.UN_NOMBRE               AS NOMBRE_UNIDAD,
    un.UN_DESCRIPCION          AS DESCRIPCION_UNIDAD,
    dp.TE_ID_TEMA              AS ID_TEMA,
    te.TE_NOMBRE               AS NOMBRE_TEMA,
    dp.SE_ID_SESION            AS ID_SESION,
    se.SE_NOMBRE               AS NOMBRE_SESION,
    dp.TA_ID_TALLER            AS ID_TALLER,
    ta.TA_NOMBRE               AS NOMBRE_TALLER,
    dp.DP_DESCRIPCION          AS DESCRIPCION_DETALLE,
    dp.DP_ESTADO               AS ESTADO_DETALLE,
    dp.DP_ELIMINADO            AS FLAG_ELIMINADO,
    dp.DP_USUARIO_ELIMINA      AS USUARIO_ELIMINA,
    dp.DP_FECHA_ELIMINA        AS FECHA_ELIMINA,
    dp.DP_USU_REGISTRA         AS USUARIO_REGISTRA,
    dp.DP_FECHA_REGISTRA       AS FECHA_REGISTRA
FROM
    SSI_DET_PATFAM dp
    JOIN SSI_UNIDADES un
        ON un.UN_ID_UNIDAD = dp.UN_ID_UNIDAD
    LEFT JOIN SSI_PATFAM pf
        ON pf.PA_ID_PATFAM = dp.PA_ID_PATFAM
    LEFT JOIN SSI_MODULOS mo
        ON mo.MO_ID_MODULO = dp.MO_ID_MODULO
    LEFT JOIN SSI_TEMAS te
        ON te.TE_ID_TEMA = dp.TE_ID_TEMA
    LEFT JOIN SSI_UNIDAD_SESIONES se
        ON se.SE_ID_SESION = dp.SE_ID_SESION
    LEFT JOIN SSI_TALLERES ta
        ON ta.TA_ID_TALLER = dp.TA_ID_TALLER
WHERE
    dp.DP_ELIMINADO = 1
    AND (
         UPPER(un.UN_DESCRIPCION) LIKE '%PROMOVIENDO HABILIDAD%'
      OR UPPER(un.UN_NOMBRE)      LIKE '%PROMOVIENDO HABILIDAD%'
    )
    AND dp.DP_FECHA_REGISTRA >= TO_DATE('2026-09-01', 'YYYY-MM-DD')
    AND d.DP_USU_MODIFICA IS NOT NULL
    -- AND dp.DP_FECHA_ELIMINA >= TO_DATE('2026-09-01', 'YYYY-MM-DD')
ORDER BY
    dp.DP_FECHA_ELIMINA DESC NULLS LAST,
    dp.DP_ID_DET_PATFAM;
/


-- =============================================================================
-- Tipo    : SELECT (helper, solo lectura)
-- Bloque  : helper_busqueda_zonas_descripcion
-- Proposito: Buscar zonas de intervencion por descripcion aproximada
--            (case-insensitive). Devuelve ZO_ID_ZONA para usar como bind
--            en el filtro por zona de la consulta de respuestas.
-- Uso     : :p_descripcion = texto sin comodines (el SQL agrega los %).
--            El filtro ZO_ESTADO = 1 queda comentado por si se necesita.
-- Autor   : OpenCode (build)
-- Fecha   : 2026-09-28
-- Alcance : solo lectura. No ejecutar DML/DDL.
-- =============================================================================
-- Notas:
--   * UPPER en ambos lados: full table scan probable en
--     SSI_ZONA_INTERVENCION (aceptable: tabla maestra de bajo volumen).
-- =============================================================================

-- * Helper: busqueda de zonas por descripcion aproximada
SELECT
   zi.ZO_ID_ZONA AS ZO_ID_ZONA,
   zi.ZO_DESCRIPCION AS ZO_DESCRIPCION,
   zi.SI_ID_SERVICIO AS SI_ID_SERVICIO,
   zi.ZO_ESTADO AS ZO_ESTADO,
   zi.ZO_ELIMINADO AS ZO_ELIMINADO
FROM SSI_ZONA_INTERVENCION zi
WHERE UPPER(zi.ZO_DESCRIPCION) LIKE '%' || UPPER('ayacu') || '%'
   AND NVL(zi.ZO_ELIMINADO, 0) = 0
   -- AND zi.ZO_ESTADO = 1
ORDER BY zi.ZO_DESCRIPCION
/


-- =============================================================================
-- Tipo    : SELECT (exploracion, solo lectura)
-- Bloque  : anexo10_respuestas_por_zona
-- Proposito: Respuestas del anexo 10 (servicio 2, pregunta 932) filtradas
--            por zona de intervencion. Basado en la plantilla del usuario;
--            se agrego JOIN a SSI_POTENCIALES_FAMILIAS y filtro
--            pf.ZO_ID_ZONA = :p_zo_id_zona (valor obtenido del helper).
-- Uso     : :p_zo_id_zona = ZO_ID_ZONA de la zona (numero).
-- Autor   : OpenCode (build)
-- Fecha   : 2026-09-28
-- Alcance : solo lectura. No ejecutar DML/DDL.
-- =============================================================================
-- Notas:
--   * ROWNUM < 100 heredado de la plantilla: sin ORDER BY, devuelve las
--     primeras 100 filas en orden fisico (no determinista).
--   * pf.PF_ELIMINADO y ar.AN_ESTADO no filtrados (no pedidos); agregar si
--     el negocio lo requiere.
--   * Respuestas colgadas solo de integrante (PF_ID_FAMILIA NULL) quedan
--     fuera por diseno de la plantilla.
-- =============================================================================

-- * Respuestas del anexo 10 filtradas por zona de intervencion
SELECT
   ar.PF_ID_FAMILIA AS PF_ID_FAMILIA,
   ar.SF_ID_FASE AS SF_ID_FASE,
   ar.AP_ID_PREGUNTA AS AP_ID_PREGUNTA,
   ar.AR_RESPUESTA AS AR_RESPUESTA,
   zi.ZO_DESCRIPCION AS ZO_DESCRIPCION,
   ar.AR_FECHA_REGISTRA AS AR_FECHA_REGISTRA
   -- COUNT(1) AS total_respuestas
FROM SSI_ANEXOS_RESPUESTAS ar
JOIN SSI_POTENCIALES_FAMILIAS pf
   ON pf.PF_ID_FAMILIA = ar.PF_ID_FAMILIA
LEFT JOIN SSI_ZONA_INTERVENCION zi
   ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
WHERE
   ar.AR_ELIMINADO = 0
   AND ar.PF_ID_FAMILIA IS NOT NULL
   /* AND ar.AP_ID_PREGUNTA IN  (
      4317,
      4319,
      1324,
      932,
      442,
      4332
   ) -- (932) */
   AND pf.ZO_ID_ZONA = 370 -- 370 | AYACUCHO
   /*
      005 — Conductas de riesgo	4317
      007 — Cuestionario de satisfacción	4319
      010 — Seguimiento de progreso	1324
      012 — Funcionamiento familiar FF-SIL	932
      013 — Diagnóstico familiar	442
      014 — TSV	4332
   */
   AND EXISTS (
      SELECT 1
      FROM SSI_ANEXOS_PREGUNTAS ap
      WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         AND ap.SI_ID_SERVICIO = 2
         -- AND ap.AP_NUM_ANEXO = 10 -- ffsil
         AND ap.AP_NUM_ANEXO = 11 -- tsv
         AND NVL(ap.AP_ELIMINADO, 0) = 0
   )
   AND ROWNUM < 100
/



SELECT * FROM SSI_ANEXOS_PREGUNTAS ap
WHERE 
   ap.AP_ID_PREGUNTA IN  (
      4317,
      4319,
      1324,
      932,
      442,
      4332
    ) -- (932)
/

-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_ANEXOS_RESP_ZONA_LISTAR
-- Proposito: Lista anexos con sus respuestas y la zona de intervencion de
--            la familia, para un servicio explicito (1=CEDIF, 2=PUNCHE).
--            Reporte plano; el pivot se realiza despues (Excel).
-- Grano   : Una fila por (PF_ID_FAMILIA, SF_ID_FASE, AP_ID_PREGUNTA) con
--            su ULTIMA respuesta vigente.
-- Parametros:
--   p_id_servicio IN SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE: obligatorio
--      (1=CEDIF, 2=PUNCHE); NULL => ORA-20001 controlado.
--   p_id_zona IN SSI_ZONA_INTERVENCION.ZO_ID_ZONA%TYPE DEFAULT -1:
--      NULL/-1 todas las zonas; otro valor filtra esa zona.
--   p_num_anexo IN SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE DEFAULT -1:
--      NULL/-1 todos los anexos; otro valor filtra ese anexo.
--   p_cursor_out OUT SYS_REFCURSOR: columnas ordenadas por zona, familia,
--      anexo, grupo, pregunta y fase.
-- Autor   : Claude (oracle-plsql-builder)
-- Fecha   : 2026-10-04
-- Alcance : Solo lectura, SELECT estatico, sin control transaccional.
-- =============================================================
-- CONTRATO / TRAZABILIDAD
-- * Fuente: SSI_ANEXOS_RESPUESTAS (V1). No se mezcla con V2.
-- * Sujeto: familia (PF_ID_FAMILIA NOT NULL). Respuestas individuales por
--   FI_ID_INTEGRANTE sin familia quedan fuera (no se deriva familia desde
--   integrante; SUPUESTO por falta de evidencia).
-- * Latest: mayor AR_ID_RESPUESTA por familia/fase/pregunta, calculado
--   sobre respuestas AR_ELIMINADO=0 de preguntas del servicio/anexo
--   solicitados. SF_ID_FASE NULL forma su propio grupo. AR_ID_RESPUESTA
--   mayor no prueba cronologia (criterio aceptado en el plan).
-- * Poblacion: pf.SI_ID_SERVICIO = p_id_servicio, PF_ELIMINADO=0,
--   NVL(AP_ELIMINADO,0)=0. Sin filtros de estado, AN_ESTADO, aptitud ni
--   estado de zona/fase.
-- * Zona CEDIF: mismo vinculo que PUNCHE (pf.ZO_ID_ZONA); INFERENCIA no
--   verificada para CEDIF.
-- * Respuestas: AR_RESPUESTA y AR_PUNTAJE tal cual, sin conversion.
-- * Supuesto: ANX_NOMBRE de SSI_ANEXO no se incluye (sin vinculo probado).
-- * AR_ID_RESPUESTA se agrega como columna de trazabilidad del latest.
-- JOINs INFERIDOS (el catalogo no documenta FK/UNIQUE):
-- * cr.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA: N:1, 95%, INNER (pregunta requerida).
-- * cr.PF_ID_FAMILIA=pf.PF_ID_FAMILIA: N:1, 95%, INNER (familia requerida).
-- * pf.ZO_ID_ZONA=zi.ZO_ID_ZONA: 0:1, 95%, LEFT; zona especifica exige
--   coincidencia (convierte efectivamente a INNER solo con ese filtro).
-- * cr.SF_ID_FASE=af.SF_ID_FASE: 0:1, 95%, LEFT.
--   Evidencia: nombres/tipos NUMBER compatibles y precedentes SP013/014.
-- RIESGOS / REVISION
-- * Posible full scan de SSI_ANEXOS_RESPUESTAS; el ranking (ROW_NUMBER) y el
--   OR-NULL de filtros aumentan costo. Sin indices ni planes verificados.
-- * Con p_num_anexo = todos y servicio CEDIF el volumen puede ser alto.
-- * Si la zona de CEDIF no se vincula por familia, ZONA saldra NULL o
--   filtrara de menos/mas de lo esperado.
-- * Cursor vacio no lanza NO_DATA_FOUND; el caller debe consumir y cerrar el
--   OUT y manejar errores durante FETCH.
-- * Revision exclusivamente estatica; NO compilado ni ejecutado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_ANEXOS_RESP_ZONA_LISTAR (
   p_id_servicio IN SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE,
   p_id_zona     IN SSI_ZONA_INTERVENCION.ZO_ID_ZONA%TYPE DEFAULT -1,
   p_num_anexo   IN SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE DEFAULT -1,
   p_cursor_out  OUT SYS_REFCURSOR
)
IS
   e_servicio_requerido EXCEPTION;
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
   v_diagnostico   VARCHAR2(4000);
BEGIN
   IF p_id_servicio IS NULL THEN
      RAISE e_servicio_requerido;
   END IF;

   OPEN p_cursor_out FOR
      WITH cte_resp AS (
         SELECT
            ar.AR_ID_RESPUESTA AS AR_ID_RESPUESTA,
            ar.PF_ID_FAMILIA AS PF_ID_FAMILIA,
            ar.SF_ID_FASE AS SF_ID_FASE,
            ar.AP_ID_PREGUNTA AS AP_ID_PREGUNTA,
            ar.AR_RESPUESTA AS AR_RESPUESTA,
            ar.AR_PUNTAJE AS AR_PUNTAJE,
            ar.AR_FECHA_REGISTRA AS AR_FECHA_REGISTRA,
            ar.AR_FECHA_MODIFICA AS AR_FECHA_MODIFICA,
            ROW_NUMBER() OVER (
               PARTITION BY ar.PF_ID_FAMILIA, ar.SF_ID_FASE, ar.AP_ID_PREGUNTA
               ORDER BY ar.AR_ID_RESPUESTA DESC
            ) AS RN_VALOR
         FROM SSI_ANEXOS_RESPUESTAS ar
         WHERE ar.AR_ELIMINADO = 0
            AND ar.PF_ID_FAMILIA IS NOT NULL
            AND EXISTS (
               SELECT 1
               FROM SSI_ANEXOS_PREGUNTAS ap
               WHERE ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
                  AND ap.SI_ID_SERVICIO = p_id_servicio
                  AND NVL(ap.AP_ELIMINADO, 0) = 0
                  AND (p_num_anexo IS NULL OR p_num_anexo = -1
                       OR ap.AP_NUM_ANEXO = p_num_anexo)
            )
      )
      SELECT
         zi.ZO_ID_ZONA AS ZO_ID_ZONA,
         zi.ZO_DESCRIPCION AS ZONA_INTERV,
         pf.SI_ID_SERVICIO AS SI_ID_SERVICIO,
         pf.PF_ID_FAMILIA AS PF_ID_FAMILIA,
         pf.PF_COD_FAMILIA AS PF_COD_FAMILIA,
         ap.AP_NUM_ANEXO AS AP_NUM_ANEXO,
         ap.AP_NUM_GRUPO AS AP_NUM_GRUPO,
         ap.AP_ID_PREGUNTA AS AP_ID_PREGUNTA,
         ap.AP_NUM_PREGUNTA AS AP_NUM_PREGUNTA,
         ap.AP_PREGUNTA AS AP_PREGUNTA,
         cr.AR_ID_RESPUESTA AS AR_ID_RESPUESTA,
         cr.AR_RESPUESTA AS AR_RESPUESTA,
         cr.AR_PUNTAJE AS AR_PUNTAJE,
         cr.SF_ID_FASE AS SF_ID_FASE,
         af.SF_NOMBRE AS FASE,
         cr.AR_FECHA_REGISTRA AS AR_FECHA_REGISTRA,
         cr.AR_FECHA_MODIFICA AS AR_FECHA_MODIFICA
      FROM cte_resp cr
      JOIN SSI_ANEXOS_PREGUNTAS ap
         ON ap.AP_ID_PREGUNTA = cr.AP_ID_PREGUNTA
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = cr.PF_ID_FAMILIA
         AND pf.SI_ID_SERVICIO = p_id_servicio
      LEFT JOIN SSI_ZONA_INTERVENCION zi
         ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
      LEFT JOIN SSI_ANEXO_FASES af
         ON af.SF_ID_FASE = cr.SF_ID_FASE
      WHERE cr.RN_VALOR = 1
         AND pf.PF_ELIMINADO = 0
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
      ORDER BY zi.ZO_ID_ZONA ASC NULLS LAST,
         pf.PF_ID_FAMILIA ASC,
         ap.AP_NUM_ANEXO ASC,
         ap.AP_NUM_GRUPO ASC,
         ap.AP_NUM_PREGUNTA ASC,
         cr.SF_ID_FASE ASC NULLS LAST;
EXCEPTION
   WHEN e_servicio_requerido THEN
      RAISE_APPLICATION_ERROR(-20001,
         'PRC_ANEXOS_RESP_ZONA_LISTAR: p_id_servicio es obligatorio (1=CEDIF, 2=PUNCHE).');
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'Error en PRC_ANEXOS_RESP_ZONA_LISTAR ['
         || TO_CHAR(v_error_code) || ']: ' || v_error_message;
      -- Acotar en bytes sin partir caracteres multibyte; preservar pila.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_ANEXOS_RESP_ZONA_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- Invocaciones MANUALES: NO EJECUTADAS, totalmente comentadas.
-- DBMS_SQL.RETURN_RESULT requiere Oracle 12c+ y cliente compatible con
-- resultados implicitos. Alternativamente consumir/cerrar el OUT desde
-- el caller, manejando tambien errores durante FETCH. No son tests.
-- =============================================================
-- Caso 1: PUNCHE (2), todas las zonas y todos los anexos.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_ANEXOS_RESP_ZONA_LISTAR(
--       p_id_servicio => 2,
--       p_id_zona => -1,
--       p_num_anexo => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 2: CEDIF (1), todas las zonas, un anexo (sustituir <num_anexo>).
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_ANEXOS_RESP_ZONA_LISTAR(
--       p_id_servicio => 1,
--       p_id_zona => NULL,
--       p_num_anexo => <num_anexo>, -- Sustituir por numero de anexo valido.
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /
-- Caso 3: PUNCHE (2), una zona (sustituir <id_zona>), todos los anexos.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
-- BEGIN
--    PRC_ANEXOS_RESP_ZONA_LISTAR(
--       p_id_servicio => 2,
--       p_id_zona => <id_zona>, -- Sustituir por zona valida.
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- END;
-- /