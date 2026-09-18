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