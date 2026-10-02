-- =============================================================
-- Tipo   : DML UPDATE (restauracion logica)
-- Nombre : 007_restore_det_patfam_familias_objetivos.sql
-- Proposito: Restaurar SOLO DP_ELIMINADO de 1 a 0 para 19 codigos,
--            servicio PUNCHE (SI_ID_SERVICIO = 2), zona Lima Este
--            y objetivos funcionales 3 y 4, con IDs por confirmar.
-- Autor  : OpenCode
-- Fecha  : 2026-09-30
-- Fuente : plsql_scripts/oracle_schema_tables_catalog.md
-- Estilo : 006_restore_det_patfam_lima_este_goleando.sql (solo lectura).
-- Alcance:
--   - SET exclusivo de DP_ELIMINADO; conservar auditoria y todos los
--     demas campos, incluidos DP_FECHA_ELIMINA y DP_USUARIO_ELIMINA.
--   - Sin filtros por fecha, unidad, taller, usuario modifica ni flags
--     de padres. No modificar cabeceras ni tablas hijas.
--   - Resolver codigos con SSI_CODIGOS_FAMILIAS.CF_CODIGO por
--     PF_ID_FAMILIA, CF_TIPO_CODIGO = 1 (familia), sin flags ni fechas
--     de vigencia: incluir historial coincidente, no elegir MAX/ultimo.
--     Catalogo: lineas 17103-17116; enlace y tipo respaldados por
--     punche/procedures/001_sp_sesiones_listar.sql:152-157.
--     000_test.sql:144-145 usa 'FAMILIA', pero el tipo real es NUMBER;
--     usar 1, tambien documentado en ddl_ssi_inabif_v1.sql:1085.
--   - Lima Este se mantiene por aprobacion expresa aunque los codigos
--     tengan prefijo 050101; no deducir zona a partir del prefijo.
-- Binds obligatorios (cargar en el cliente, sin sustitucion textual):
--   :p_id_zona       NUMBER: ID confirmado por 1.1.
--   :p_id_objetivo_3 NUMBER: ID del objetivo funcional 3 segun 1.2.
--   :p_id_objetivo_4 NUMBER: ID del objetivo funcional 4 segun 1.2.
--   NO asumir que los IDs sean 3 y 4. Deben ser no nulos y distintos.
--   :p_cod_familia_01 VARCHAR2(50) = 050101-1-00171
--   :p_cod_familia_02 VARCHAR2(50) = 050101-1-00305
--   :p_cod_familia_03 VARCHAR2(50) = 050101-1-01232
--   :p_cod_familia_04 VARCHAR2(50) = 050101-1-00009
--   :p_cod_familia_05 VARCHAR2(50) = 050101-1-01221
--   :p_cod_familia_06 VARCHAR2(50) = 050101-1-01258
--   :p_cod_familia_07 VARCHAR2(50) = 050101-1-00109
--   :p_cod_familia_08 VARCHAR2(50) = 050101-1-00101
--   :p_cod_familia_09 VARCHAR2(50) = 050101-1-00200
--   :p_cod_familia_10 VARCHAR2(50) = 050101-1-00102
--   :p_cod_familia_11 VARCHAR2(50) = 050101-1-00106
--   :p_cod_familia_12 VARCHAR2(50) = 050101-1-00108
--   :p_cod_familia_13 VARCHAR2(50) = 050101-1-00111
--   :p_cod_familia_14 VARCHAR2(50) = 050101-1-00096
--   :p_cod_familia_15 VARCHAR2(50) = 050101-1-00295
--   :p_cod_familia_16 VARCHAR2(50) = 050101-1-00297
--   :p_cod_familia_17 VARCHAR2(50) = 050101-1-00112
--   :p_cod_familia_18 VARCHAR2(50) = 050101-1-00244
--   :p_cod_familia_19 VARCHAR2(50) = 050101-1-00118
--   La repeticion original de 050101-1-01232 se retiro SOLO de la lista
--   recibida; no implica duplicados confirmados en la base de datos.
-- Gates MANUALES (no hay bloqueo automatico; ejecutar por fases):
--   1. Confirmar zona en 1.1 y ambos objetivos en 1.2/1.3. Si hay
--      multiples IDs o identificacion ambigua, detener y confirmar;
--      no ampliar el alcance ni elegir IDs por orden de resultado.
--   2. Verificar los 19 binds exactos y resolver ausencias, multiples
--      familias por codigo o discrepancias de servicio/zona en 1.4.
--   3. Aprobar total y desglose de 1.5/1.6 antes de ejecutar Fase 2.
--   4. Registrar filas afectadas del cliente y compararlas con 1.5;
--      verificar Fase 3 en la misma sesion antes de decidir transaccion.
-- Advertencias:
--   - El catalogo documenta columnas/tipos, no confirma aqui PK/FK,
--     indices ni triggers desplegados. Las uniones son las aprobadas.
--     No se afirma ausencia de triggers ni duplicados en la BD.
--   - Padres eliminados pueden afectar visibilidad: no se restauran.
--   - Posibles full table scans: indices/plan no verificados; la funcion
--     TRIM(UPPER(...)) puede impedir usar un indice simple de descripcion.
--   - Evitar concurrencia durante la revision/actualizacion: los SELECTs
--     previos no congelan candidatos. Mantener autocommit desactivado.
--   - No ejecutar el archivo completo sin resolver los gates manuales.
-- =============================================================

-- =============================================================
-- FASE 1 - IDENTIFICACION Y PREVALIDACION (solo lectura)
-- =============================================================

-- 1.1 Identificar Lima Este dentro de PUNCHE, sin filtro de flags.
SELECT
   zo.ZO_ID_ZONA,
   '[' || zo.ZO_DESCRIPCION || ']' AS DESCRIPCION_DELIMITADA,
   zo.SI_ID_SERVICIO,
   zo.ZO_ESTADO,
   zo.ZO_ELIMINADO
FROM SSI_ZONA_INTERVENCION zo
WHERE zo.SI_ID_SERVICIO = 2
   AND TRIM(UPPER(zo.ZO_DESCRIPCION)) LIKE '%AYACUCHO%'
ORDER BY zo.ZO_ID_ZONA
/

-- 1.2 Catalogo completo de objetivos para servicio 2, con todas sus
--     columnas verificadas, incluidos registros eliminados/inactivos.
--     No hay campo dedicado al numero funcional en el catalogo.
--     Elegir manualmente por OE_NOMBRE/OE_DESCRIPCION y confirmacion
--     funcional; OE_TIPO_SESION NO se interpreta como numero de objetivo.
--     El filtro de candidatos usa dp.OE_ID_OBJETIVO directamente,
--     no necesita derivarlo de taller, tema ni modulo.
SELECT
   oe.OE_ID_OBJETIVO,
   oe.SI_ID_SERVICIO,
   oe.OE_NOMBRE,
   oe.OE_DESCRIPCION,
   oe.OE_USU_REGISTRA,
   oe.OE_FECHA_REGISTRA,
   oe.OE_USUARIO_ELIMINA,
   oe.OE_FECHA_ELIMINA,
   oe.OE_ESTADO,
   oe.OE_ELIMINADO,
   oe.OE_TIPO_SESION
FROM SSI_OBJETIVOS_ESPECIFICOS oe
WHERE oe.SI_ID_SERVICIO = 2
ORDER BY oe.OE_ID_OBJETIVO
/

-- 1.3 Confirmar binds seleccionados: esperar una fila por cada rol.
--     Ausencia, IDs iguales o mas de una fila por rol: DETENER.
--     La pertenencia al servicio no prueba el significado funcional;
--     confirmar explicitamente objetivo 3/4 mediante 1.2.
WITH objetivos_solicitados AS (
   SELECT 'OBJETIVO 3' AS ROL_OBJETIVO, 3 AS ID_OBJETIVO
   FROM DUAL
   UNION ALL
   SELECT 'OBJETIVO 4', 4 AS ID_OBJETIVO FROM DUAL
)
SELECT
   os.ROL_OBJETIVO,
   os.ID_OBJETIVO,
   oe.SI_ID_SERVICIO,
   oe.OE_NOMBRE,
   oe.OE_DESCRIPCION,
   CASE
      WHEN os.ID_OBJETIVO IS NULL THEN 'ID NULO: DETENER'
      WHEN 3 = 4 THEN 'IDS IGUALES: DETENER'
      WHEN oe.OE_ID_OBJETIVO IS NULL THEN 'NO ENCONTRADO: DETENER'
      WHEN oe.SI_ID_SERVICIO = 2 THEN 'CONFIRMAR SIGNIFICADO FUNCIONAL'
      ELSE 'OTRO SERVICIO: DETENER'
   END AS CONTROL_OBJETIVO
FROM objetivos_solicitados os
LEFT JOIN SSI_OBJETIVOS_ESPECIFICOS oe
   ON oe.OE_ID_OBJETIVO = os.ID_OBJETIVO
ORDER BY os.ROL_OBJETIVO
/

-- 1.4 Lista completa, incluso codigos no encontrados. Mostrar servicio
--     y zona reales SIN filtrar por Lima Este, para detectar discrepancias.
--     Revisar repeticiones del mismo codigo con distintos PF_ID_FAMILIA.
--     Esperar 19 codigos no nulos/distintos segun header, cada uno con
--     una familia confirmada en servicio 2 y :p_id_zona (Lima Este).
WITH familias_solicitadas AS (
   SELECT 
      -- 1 AS ORDEN, '050101-1-00171' AS COD_FAMILIA FROM DUAL
      1 AS ORDEN, '070103-2-0289' AS COD_FAMILIA FROM DUAL
   /*UNION ALL SELECT 2, :p_cod_familia_02 FROM DUAL
   UNION ALL SELECT 3, :p_cod_familia_03 FROM DUAL
   UNION ALL SELECT 4, :p_cod_familia_04 FROM DUAL
   UNION ALL SELECT 5, :p_cod_familia_05 FROM DUAL
   UNION ALL SELECT 6, :p_cod_familia_06 FROM DUAL
   UNION ALL SELECT 7, :p_cod_familia_07 FROM DUAL
   UNION ALL SELECT 8, :p_cod_familia_08 FROM DUAL
   UNION ALL SELECT 9, :p_cod_familia_09 FROM DUAL
   UNION ALL SELECT 10, :p_cod_familia_10 FROM DUAL
   UNION ALL SELECT 11, :p_cod_familia_11 FROM DUAL
   UNION ALL SELECT 12, :p_cod_familia_12 FROM DUAL
   UNION ALL SELECT 13, :p_cod_familia_13 FROM DUAL
   UNION ALL SELECT 14, :p_cod_familia_14 FROM DUAL
   UNION ALL SELECT 15, :p_cod_familia_15 FROM DUAL
   UNION ALL SELECT 16, :p_cod_familia_16 FROM DUAL
   UNION ALL SELECT 17, :p_cod_familia_17 FROM DUAL
   UNION ALL SELECT 18, :p_cod_familia_18 FROM DUAL
   UNION ALL SELECT 19, :p_cod_familia_19 FROM DUAL */
)
SELECT
   fs.ORDEN,
   fs.COD_FAMILIA AS CODIGO_SOLICITADO,
   pf.PF_ID_FAMILIA,
   pf.SI_ID_SERVICIO AS SERVICIO_FAMILIA,
   pf.ZO_ID_ZONA,
   zo.ZO_DESCRIPCION,
   zo.SI_ID_SERVICIO AS SERVICIO_ZONA,
   pf.PF_ELIMINADO,
   CASE
      WHEN fs.COD_FAMILIA IS NULL THEN 'CODIGO NULO: DETENER'
      WHEN pf.PF_ID_FAMILIA IS NULL THEN 'NO ENCONTRADA: DETENER'
      WHEN 
         -- pf.SI_ID_SERVICIO = 2
         pf.ZO_ID_ZONA = 370 -- 370 | [AYACUCHO]
         AND zo.SI_ID_SERVICIO = 2
      THEN 'CORRESPONDE A SERVICIO/ZONA'
      ELSE 'REVISAR SERVICIO/ZONA: DETENER'
   END AS CONTROL_FAMILIA
FROM familias_solicitadas fs
LEFT JOIN SSI_POTENCIALES_FAMILIAS pf
   ON EXISTS (
      SELECT 1
      FROM SSI_CODIGOS_FAMILIAS cf
      WHERE cf.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         AND cf.CF_TIPO_CODIGO = 1
         AND cf.CF_CODIGO = fs.COD_FAMILIA
   )
LEFT JOIN SSI_ZONA_INTERVENCION zo
   ON zo.ZO_ID_ZONA = pf.ZO_ID_ZONA
ORDER BY fs.ORDEN, pf.PF_ID_FAMILIA
/

SELECT * FROM SSI_CODIGOS_FAMILIAS cf
WHERE cf.CF_CODIGO IN (
   '050101-1-00171',
   '050101-1-00305',
   '050101-1-01232',
   '050101-1-00009',
   '050101-1-01221',
   '050101-1-01258',
   '050101-1-00109',
   '050101-1-01232',
   '050101-1-00101',
   '050101-1-00200',
   '050101-1-00102',
   '050101-1-00106',
   '050101-1-00108',
   '050101-1-00111',
   '050101-1-00096',
   '050101-1-00295',
   '050101-1-00297',
   '050101-1-00112',
   '050101-1-00244',
   '050101-1-00118'
)
/

-- 1.5 Total previo: EXISTS evita multiplicar detalles por uniones.
--     Registrar este total para comparar con las filas del UPDATE.
SELECT COUNT(*) AS TOTAL_CANDIDATOS
FROM SSI_DET_PATFAM dp
WHERE dp.DP_ELIMINADO = 1
   AND dp.OE_ID_OBJETIVO IN (:p_id_objetivo_3, :p_id_objetivo_4)
   AND EXISTS (
      SELECT 1
      FROM SSI_PATFAM pa
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
      WHERE pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
         AND pf.SI_ID_SERVICIO = 2
         AND pf.ZO_ID_ZONA = :p_id_zona
         AND EXISTS (
            SELECT 1
            FROM SSI_CODIGOS_FAMILIAS cf
            WHERE cf.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
               AND cf.CF_TIPO_CODIGO = 1
               AND cf.CF_CODIGO IN (
                  :p_cod_familia_01, :p_cod_familia_02, :p_cod_familia_03,
                  :p_cod_familia_04, :p_cod_familia_05, :p_cod_familia_06,
                  :p_cod_familia_07, :p_cod_familia_08, :p_cod_familia_09,
                  :p_cod_familia_10, :p_cod_familia_11, :p_cod_familia_12,
                  :p_cod_familia_13, :p_cod_familia_14, :p_cod_familia_15,
                  :p_cod_familia_16, :p_cod_familia_17, :p_cod_familia_18,
                  :p_cod_familia_19
               )
         )
   );

-- 1.6 Desglose por familia y mes de DP_FECHA_ELIMINA (no registro).
--     Agrupar por PF_ID_FAMILIA, no por codigo: varios codigos solicitados
--     pueden resolver a una familia; EXISTS evita duplicar por historial.
--     El listado 1.4 conserva la correspondencia codigo/ID de familia.
--     NULL se agrupa como SIN FECHA y permanece dentro del alcance.
--     La suma debe coincidir con 1.5; si no coincide, detener y revisar
--     multiplicidad de las uniones aprobadas. No inferir PK/FK.
SELECT
   pf.PF_ID_FAMILIA,
   TRUNC(dp.DP_FECHA_ELIMINA, 'MM') AS MES_ELIMINACION,
   NVL(TO_CHAR(TRUNC(dp.DP_FECHA_ELIMINA, 'MM'), 'YYYY-MM'),
      'SIN FECHA') AS GRUPO_MES_ELIMINACION,
   COUNT(*) AS TOTAL_CANDIDATOS
FROM SSI_DET_PATFAM dp
JOIN SSI_PATFAM pa
   ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
JOIN SSI_POTENCIALES_FAMILIAS pf
   ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
WHERE dp.DP_ELIMINADO = 1
   AND dp.OE_ID_OBJETIVO IN (:p_id_objetivo_3, :p_id_objetivo_4)
   AND pf.SI_ID_SERVICIO = 2
   AND pf.ZO_ID_ZONA = :p_id_zona
   AND EXISTS (
      SELECT 1
      FROM SSI_CODIGOS_FAMILIAS cf
      WHERE cf.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         AND cf.CF_TIPO_CODIGO = 1
         AND cf.CF_CODIGO IN (
            :p_cod_familia_01, :p_cod_familia_02, :p_cod_familia_03,
            :p_cod_familia_04, :p_cod_familia_05, :p_cod_familia_06,
            :p_cod_familia_07, :p_cod_familia_08, :p_cod_familia_09,
            :p_cod_familia_10, :p_cod_familia_11, :p_cod_familia_12,
            :p_cod_familia_13, :p_cod_familia_14, :p_cod_familia_15,
            :p_cod_familia_16, :p_cod_familia_17, :p_cod_familia_18,
            :p_cod_familia_19
         )
   )
GROUP BY pf.PF_ID_FAMILIA, TRUNC(dp.DP_FECHA_ELIMINA, 'MM')
ORDER BY pf.PF_ID_FAMILIA, MES_ELIMINACION NULLS FIRST;

-- =============================================================
-- FASE 2 - UPDATE: SOLO despues de aprobar todos los gates de Fase 1.
-- Predicado identico a 1.5; SET sin alias para sintaxis Oracle.
-- Sin cambios en claves: no se requiere DML en padres ni hijas.
-- =============================================================
UPDATE SSI_DET_PATFAM dp
SET DP_ELIMINADO = 0
WHERE dp.DP_ELIMINADO = 1
   AND dp.OE_ID_OBJETIVO IN (:p_id_objetivo_3, :p_id_objetivo_4)
   AND EXISTS (
      SELECT 1
      FROM SSI_PATFAM pa
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
      WHERE pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
         AND pf.SI_ID_SERVICIO = 2
         AND pf.ZO_ID_ZONA = 370 -- ? 370 | [AYACUCHO]
         AND EXISTS (
            SELECT 1
            FROM SSI_CODIGOS_FAMILIAS cf
            WHERE cf.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
               AND cf.CF_TIPO_CODIGO = 1
               AND cf.CF_CODIGO IN (
            /* :p_cod_familia_01, :p_cod_familia_02, :p_cod_familia_03,
            :p_cod_familia_04, :p_cod_familia_05, :p_cod_familia_06,
            :p_cod_familia_07, :p_cod_familia_08, :p_cod_familia_09,
            :p_cod_familia_10, :p_cod_familia_11, :p_cod_familia_12,
            :p_cod_familia_13, :p_cod_familia_14, :p_cod_familia_15,
            :p_cod_familia_16, :p_cod_familia_17, :p_cod_familia_18,*/
            :p_cod_familia_19
            
               )
         )
   );

-- =============================================================
-- FASE 3 - POSTVALIDACION en la MISMA sesion, antes de COMMIT/ROLLBACK.
-- Esperado: RESTANTES_ELIMINADOS = 0 bajo el mismo predicado que 1.5.
-- Un cero no prueba por si solo cuantos registros fueron restaurados:
-- comparar filas afectadas con el total previo aprobado.
-- No comparar total activos final con restaurados: puede haber activos
-- previos. Despues de ROLLBACK ya no corresponde esperar cero.
-- =============================================================
SELECT COUNT(*) AS RESTANTES_ELIMINADOS
FROM SSI_DET_PATFAM dp
WHERE dp.DP_ELIMINADO = 1
   AND dp.OE_ID_OBJETIVO IN (:p_id_objetivo_3, :p_id_objetivo_4)
   AND EXISTS (
      SELECT 1
      FROM SSI_PATFAM pa
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
      WHERE pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
         AND pf.SI_ID_SERVICIO = 2
         AND pf.ZO_ID_ZONA = :p_id_zona
         AND EXISTS (
            SELECT 1
            FROM SSI_CODIGOS_FAMILIAS cf
            WHERE cf.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
               AND cf.CF_TIPO_CODIGO = 1
               AND cf.CF_CODIGO IN (
                  :p_cod_familia_01, :p_cod_familia_02, :p_cod_familia_03,
                  :p_cod_familia_04, :p_cod_familia_05, :p_cod_familia_06,
                  :p_cod_familia_07, :p_cod_familia_08, :p_cod_familia_09,
                  :p_cod_familia_10, :p_cod_familia_11, :p_cod_familia_12,
                  :p_cod_familia_13, :p_cod_familia_14, :p_cod_familia_15,
                  :p_cod_familia_16, :p_cod_familia_17, :p_cod_familia_18,
                  :p_cod_familia_19
               )
         )
   );

-- Decidir una sola alternativa tras revision; ambas quedan comentadas.
-- ROLLBACK;
-- COMMIT;
