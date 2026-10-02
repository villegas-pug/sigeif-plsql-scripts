-- =============================================================
-- Tipo   : DML UPDATE (cleanup / restauracion logica)
-- Nombre : 006_restore_det_patfam_lima_este_goleando.sql
-- Proposito: Restaurar detalles PATFAM eliminados (DP_ELIMINADO 1 -> 0)
--            filtrados por servicio PUNCHE (SI_ID_SERVICIO = 2),
--            zona 'Lima Este' y taller 'Goleando a mis deudas'.
-- Autor  : [REEMPLAZAR: nombre del autor]
-- Fecha  : [REEMPLAZAR: fecha de creacion]
-- Alcance: Tabla SSI_DET_PATFAM (solo flag DP_ELIMINADO).
--          No se tocan DP_USUARIO_ELIMINA / DP_FECHA_ELIMINA ni
--          DP_USU_MODIFICA / DP_FECHA_MODIFICA. No se tocan tablas hijas.
-- Supuestos:
--   - :p_id_zona y :p_id_taller se confirman en Fase 1 (1.1 y 1.2)
--     antes de ejecutar la Fase 2; son IDs literales, no subconsultas.
--   - Duplicados conocidos: zona 'LIMA ESTE' (con/sin espacio final) y
--     taller 'Goleando a mis deudas' x2 (dml_insert_catalogos_objetivos_especificos.sql
--     L239/L250); por eso la Fase 1 es gate obligatorio.
--   - Sin triggers en SSI_DET_PATFAM: los registros seran visibles de
--     inmediato en los SPs al COMMIT (filtran DP_ELIMINADO = 0).
--   - DP_FECHA_ELIMINA NULL queda fuera del bucket mensual (1.3).
--   - No se filtra por PA_ELIMINADO / PF_ELIMINADO (decision aprobada);
--     estado asimetrico se reporta en 1.4(d).
-- Riesgos:
--   - Si 1.1/1.2 devuelven varios IDs, ejecutar Fase 2 por cada par
--     confirmado, nunca con todos los IDs de golpe sin validacion funcional.
--   - Riesgo de visibilidad asimetrica: candidatos con cabeceras
--     PA_ELIMINADO=1 o PF_ELIMINADO=1 se restauraran pero podrian no
--     mostrarse en pantallas que filtren sus cabeceras (ver 1.4d).
--   - Ejecutar en ventana de bajo uso; COMMIT comentado hasta validacion
--     operativa.
-- =============================================================

-- =============================================================
-- FASE 1 - PREVALIDACION (SELECTs solo lectura)
-- =============================================================

-- 1.1 Identificar ID(s) de zona 'Lima Este' (servicio PUNCHE = 2).
-- ? 375 | [LIMA ESTE]
SELECT z.ZO_ID_ZONA, '[' || z.ZO_DESCRIPCION || ']' AS DESC_DELIMITADA,
       z.SI_ID_SERVICIO, z.ZO_ELIMINADO
  FROM SSI_ZONA_INTERVENCION z
 WHERE 
   z.SI_ID_SERVICIO = 2
   -- AND TRIM(UPPER(z.ZO_DESCRIPCION)) = 'LIMA ESTE'
   AND TRIM(UPPER(z.ZO_DESCRIPCION)) LIKE '%AYA%'
 ORDER BY z.ZO_ID_ZONA
/

-- 1.2 Identificar ID(s) de taller 'Goleando a mis deudas'.
-- ? 50 | Taller 1 | Goleando a mis deudas
SELECT ta.TA_ID_TALLER, ta.TA_NOMBRE, ta.TA_DESCRIPCION,
       ta.TE_ID_TEMA, ta.SI_ID_SERVICIO, ta.TA_ELIMINADO
  FROM SSI_TALLERES ta
 WHERE TRIM(UPPER(ta.TA_DESCRIPCION)) = 'GOLEANDO A MIS DEUDAS'
 ORDER BY ta.TA_ID_TALLER
/

-- 1.3 Conteo mensual de candidatos por mes de eliminacion
--     (mismo predicado que 1.4b y Fase 2; binds :p_id_zona / :p_id_taller).
SELECT 
   TRUNC(dp.DP_FECHA_REGISTRA, 'MM') AS MES_ELIMINACION,
   COUNT(*) AS CANTIDAD_REGISTROS
FROM SSI_DET_PATFAM dp
JOIN SSI_PATFAM pa ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
WHERE 
   dp.DP_ELIMINADO = 1
   AND pf.SI_ID_SERVICIO = 2
   -- AND pf.ZO_ID_ZONA = 375
   AND pf.ZO_ID_ZONA = 370 -- 370 | [AYACUCHO]
   -- AND dp.TA_ID_TALLER = 50
GROUP BY TRUNC(dp.DP_FECHA_REGISTRA, 'MM')
ORDER BY MES_ELIMINACION
/

-- 1.4a Control: total global de eliminados en SSI_DET_PATFAM.
SELECT 
   COUNT(*) AS TOTAL_GLOBAL_ELIMINADOS
FROM SSI_DET_PATFAM dp
WHERE 
   dp.DP_ELIMINADO = 1
/

-- 1.4b Control: total filtrado (predicado exacto igual a 1.3 y Fase 2).
SELECT 
   COUNT(*) AS TOTAL_FILTRADO_ELIMINADOS
FROM SSI_DET_PATFAM dp
JOIN SSI_PATFAM pa ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
WHERE 
   dp.DP_ELIMINADO = 1
   AND pf.SI_ID_SERVICIO = 2
   AND pf.ZO_ID_ZONA = 375
   AND dp.TA_ID_TALLER = 50
/

-- 1.4c Control: candidatos con TA_ID_TALLER NULL dentro de zona + servicio.
--     Verifica que el filtro por taller no excluya de forma no intencional.
SELECT 
   -- COUNT(*) AS CANDIDATOS_SIN_TALLER_EN_ZONA
   dp.*
FROM SSI_DET_PATFAM dp
JOIN SSI_PATFAM pa ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
WHERE 
   dp.DP_ELIMINADO = 1
   -- AND dp.TA_ID_TALLER IS NULL
   AND pf.SI_ID_SERVICIO = 2
   -- AND pf.ZO_ID_ZONA = 375
   AND pf.ZO_ID_ZONA = 370 -- 370 | [AYACUCHO]
ORDER BY
   dp.DP_ID_DET_PATFAM DESC
/

-- 1.4d Control: estado de cabeceras de los candidatos filtrados.
--     Riesgo de visibilidad asimetrica (PA_ELIMINADO=1 / PF_ELIMINADO=1);
--     el UPDATE restaura solo el detalle, no las cabeceras.
SELECT SUM(CASE WHEN pa.PA_ELIMINADO = 1 THEN 1 ELSE 0 END) AS CAB_PA_ELIMINADAS,
       SUM(CASE WHEN pf.PF_ELIMINADO = 1 THEN 1 ELSE 0 END) AS CAB_PF_ELIMINADAS,
       COUNT(*) AS TOTAL_CANDIDATOS
  FROM SSI_DET_PATFAM dp
  JOIN SSI_PATFAM pa ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
  JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
 WHERE dp.DP_ELIMINADO = 1
   AND pf.SI_ID_SERVICIO = 2
   AND pf.ZO_ID_ZONA = 375
   AND dp.TA_ID_TALLER = 50
/

-- 1.4e Muestreo de 20 filas candidatas para revision del area funcional.
SELECT dp.DP_ID_DET_PATFAM, dp.PA_ID_PATFAM, dp.UN_ID_UNIDAD,
       dp.TA_ID_TALLER, dp.DP_FECHA_REGISTRA, dp.DP_FECHA_ELIMINA
  FROM SSI_DET_PATFAM dp
  JOIN SSI_PATFAM pa ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
  JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
 WHERE dp.DP_ELIMINADO = 1
   AND pf.SI_ID_SERVICIO = 2
   AND pf.ZO_ID_ZONA = 375
   AND dp.TA_ID_TALLER = 50
 ORDER BY dp.DP_ID_DET_PATFAM
 FETCH FIRST 20 ROWS ONLY
/

-- =============================================================
-- FASE 2 - UPDATE (mismo predicado exacto que 1.3 / 1.4b)
--   Ejecutar SOLO tras confirmar :p_id_zona y :p_id_taller en Fase 1.
--   SET limitado a DP_ELIMINADO = 0 (decision aprobada).
-- =============================================================

UPDATE SSI_DET_PATFAM dp
   SET dp.DP_ELIMINADO = 0
WHERE dp.DP_ELIMINADO = 1
AND dp.PA_ID_PATFAM IN (
      SELECT pa.PA_ID_PATFAM
         FROM SSI_PATFAM pa
         JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
      WHERE pf.SI_ID_SERVICIO = 2
         AND pf.ZO_ID_ZONA = 375)
AND dp.TA_ID_TALLER = 50
/

-- ? ROLLBACK;  -- Comentado hasta validacion operativa.
-- ! COMMIT;  -- Comentado hasta validacion operativa.

-- =============================================================
-- FASE 3 - VERIFICACION POST-EJECUCION
--   Ejecutar tras el UPDATE (sin COMMIT o tras ROLLBACK de prueba):
--   el conteo con DP_ELIMINADO = 0 debe ser igual al conteo previo 1.4b.
-- =============================================================

SELECT COUNT(*) AS TOTAL_FILTRADO_RESTAURADOS
  FROM SSI_DET_PATFAM dp
  JOIN SSI_PATFAM pa ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
  JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
WHERE dp.DP_ELIMINADO = 0
   AND pf.SI_ID_SERVICIO = 2
   AND pf.ZO_ID_ZONA = 375
AND dp.TA_ID_TALLER = 50
/
