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