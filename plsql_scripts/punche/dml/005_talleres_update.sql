-- =============================================================================
-- Tipo    : DML (UPDATE)
-- Nombre  : 005_talleres_update.sql
-- Propósito: Actualizar TA_DESCRIPCION de 8 talleres PUNCHE en SSI_TALLERES
--            (TE_ID_TEMA 4, 5 y 6), reemplazando las descripciones antiguas
--            por los nuevos nombres oficiales. NO incluye el prefijo
--            "Taller N:" en los textos nuevos.
-- Autor   : [ REEMPLAZAR: nombre del autor ]
-- Fecha   : 2026-08-15
-- =============================================================================
-- Notas de implementación:
--   * Un solo UPDATE con CASE (decisión del usuario).
--   * El WHERE usa la tripleta (TE_ID_TEMA, TA_NOMBRE, TA_DESCRIPCION actual)
--     como protección doble: solo actualiza si la descripción vigente
--     coincide exactamente con la esperada. Si la data cambió, el UPDATE
--     afecta 0 filas y se detecta sin riesgo.
--   * Fila 7 (TE_ID_TEMA=6, 'Taller 3'): el INSERT original tiene un
--     espacio inicial (' Prácticas saludables...'), por eso se usa
--     TRIM(t.TA_DESCRIPCION) en esa condición.
--   * AUDITORÍA: SSI_TALLERES NO tiene columnas TA_USU_ACTUALIZA ni
--     TA_FEC_ACTUALIZA (ver ddl_ssi_inabif_v1.sql líneas 697-712), por
--     lo que el UPDATE solo modifica TA_DESCRIPCION. La trazabilidad
--     queda en este script.
--   * Las comillas dobles de "matriz de coherencia" son válidas dentro
--     de un literal Oracle sin escape adicional.
-- =============================================================================

-- =============================================================================
-- * 1. VALIDACIÓN PREVIA (ejecutar ANTES del UPDATE, solo lectura)
-- =============================================================================

-- * 1.1 V1: Existencia y unicidad de los 8 registros objetivo
--     Esperado: 8 filas, cada una con TOTAL_COINCIDENCIAS = 1.
--     Si devuelve < 8 filas o alguna <> 1 -> ABORTAR (revisar tildes/data).
SELECT
   t.TE_ID_TEMA,
   t.TA_NOMBRE,
   t.TA_DESCRIPCION,
   COUNT(1) AS TOTAL_COINCIDENCIAS
FROM SSI_TALLERES t
WHERE
   t.TA_ELIMINADO = 0
   AND t.TA_ESTADO = 1
   AND (
         (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Fortalecimiento de la empatía')
      OR (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 2' AND t.TA_DESCRIPCION = 'Estableciendo nuestras convicciones')
      OR (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 3' AND t.TA_DESCRIPCION = 'Descubriendo mi FODA personal')
      OR (t.TE_ID_TEMA = 5 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Promoviendo el pensamiento reflexivo')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = '¿Cómo llegamos hasta aquí?')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 2' AND t.TA_DESCRIPCION = '¿Qué nos toca hacer?')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 3' AND TRIM(t.TA_DESCRIPCION) = 'Prácticas saludables para la resolución de conflictos')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 4' AND t.TA_DESCRIPCION = 'Fortaleciendo mi autoconocimiento y cuidado personal')
   )
GROUP BY
   t.TE_ID_TEMA,
   t.TA_NOMBRE,
   t.TA_DESCRIPCION
ORDER BY
   t.TE_ID_TEMA,
   t.TA_NOMBRE
/

-- * 1.2 V2: Detalle de TA_ID_TALLER a afectar
--     Esperado: exactamente 8 filas con 8 IDs únicos.
--     Si devuelve 16 filas -> hay duplicados -> ABORTAR y depurar.
SELECT
   t.TA_ID_TALLER,
   t.TE_ID_TEMA,
   t.TA_NOMBRE,
   t.TA_DESCRIPCION AS DESCRIPCION_ACTUAL,
   t.TA_FECHA_REGISTRA
FROM SSI_TALLERES t
WHERE
   t.TA_ELIMINADO = 0
   AND t.TA_ESTADO = 1
   AND (
         (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Fortalecimiento de la empatía')
      OR (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 2' AND t.TA_DESCRIPCION = 'Estableciendo nuestras convicciones')
      OR (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 3' AND t.TA_DESCRIPCION = 'Descubriendo mi FODA personal')
      OR (t.TE_ID_TEMA = 5 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Promoviendo el pensamiento reflexivo')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = '¿Cómo llegamos hasta aquí?')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 2' AND t.TA_DESCRIPCION = '¿Qué nos toca hacer?')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 3' AND TRIM(t.TA_DESCRIPCION) = 'Prácticas saludables para la resolución de conflictos')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 4' AND t.TA_DESCRIPCION = 'Fortaleciendo mi autoconocimiento y cuidado personal')
   )
ORDER BY
   t.TE_ID_TEMA,
   t.TA_NOMBRE
/

-- * 1.3 V3: Detección de duplicados por combinación (TE_ID_TEMA, TA_NOMBRE)
--     Esperado: 0 filas. CUALQUIER fila devuelta -> ABORTAR el UPDATE.
--     Nota: dml_insert_catalogos_objetivos_especificos.sql contiene estos
--     8 INSERTs duplicados (líneas 241-248 y 252-259); si ese script se
--     ejecutó completo, habrá 2 filas por taller.
SELECT
   t.TE_ID_TEMA,
   t.TA_NOMBRE,
   COUNT(1) AS TOTAL
FROM SSI_TALLERES t
WHERE
   t.TA_ELIMINADO = 0
   AND t.TA_ESTADO = 1
   AND t.TE_ID_TEMA IN (4, 5, 6)
GROUP BY
   t.TE_ID_TEMA,
   t.TA_NOMBRE
HAVING COUNT(1) > 1
ORDER BY
   t.TE_ID_TEMA,
   t.TA_NOMBRE
/


-- =============================================================================
-- * 2. UPDATE (un solo statement con CASE)
--     Esperado: 8 filas afectadas (SQL%ROWCOUNT = 8).
-- =============================================================================
UPDATE SSI_TALLERES t
SET
   t.TA_DESCRIPCION =
      CASE
         WHEN t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 1'
            THEN 'Fortaleciendo la conducta empática en adolescentes'
         WHEN t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 2'
            THEN 'Estableciendo nuestras convicciones'
         WHEN t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 3'
            THEN 'Descubriendo mi FODA personal'
         WHEN t.TE_ID_TEMA = 5 AND t.TA_NOMBRE = 'Taller 1'
            THEN 'Promoviendo el desarrollo del pensamiento reflexivo en los adolescentes'
         WHEN t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 1'
            THEN 'Promovemos habilidades para la resolución de conflictos'
         WHEN t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 2'
            THEN 'Fortalecemos nuestro autoconocimiento y nuestro adecuado desarrollo personal social (1)'
         WHEN t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 3'
            THEN 'Proyecto de vida por una cultura de paz "matriz de coherencia"'
         WHEN t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 4'
            THEN 'Fortalecer nuestro autoconocimiento y nuestro adecuado desarrollo personal social (2)'
         ELSE t.TA_DESCRIPCION
      END
WHERE
   t.TA_ELIMINADO = 0
   AND t.TA_ESTADO = 1
   AND (
         (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Fortalecimiento de la empatía')
      OR (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 2' AND t.TA_DESCRIPCION = 'Estableciendo nuestras convicciones')
      OR (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 3' AND t.TA_DESCRIPCION = 'Descubriendo mi FODA personal')
      OR (t.TE_ID_TEMA = 5 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Promoviendo el pensamiento reflexivo')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = '¿Cómo llegamos hasta aquí?')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 2' AND t.TA_DESCRIPCION = '¿Qué nos toca hacer?')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 3' AND TRIM(t.TA_DESCRIPCION) = 'Prácticas saludables para la resolución de conflictos')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 4' AND t.TA_DESCRIPCION = 'Fortaleciendo mi autoconocimiento y cuidado personal')
   )
/

-- ! COMMIT;
-- ? ROLLBACK;


-- =============================================================================
-- * 3. VALIDACIÓN POST-UPDATE (ejecutar DESPUÉS, solo lectura)
--     Esperado: 8 filas con las nuevas descripciones.
-- =============================================================================
SELECT
   t.TA_ID_TALLER,
   t.TE_ID_TEMA,
   t.TA_NOMBRE,
   t.TA_DESCRIPCION AS DESCRIPCION_NUEVA
FROM SSI_TALLERES t
WHERE
   t.TA_ELIMINADO = 0
   AND t.TA_ESTADO = 1
   AND (
         (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Fortaleciendo la conducta empática en adolescentes')
      OR (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 2' AND t.TA_DESCRIPCION = 'Estableciendo nuestras convicciones')
      OR (t.TE_ID_TEMA = 4 AND t.TA_NOMBRE = 'Taller 3' AND t.TA_DESCRIPCION = 'Descubriendo mi FODA personal')
      OR (t.TE_ID_TEMA = 5 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Promoviendo el desarrollo del pensamiento reflexivo en los adolescentes')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 1' AND t.TA_DESCRIPCION = 'Promovemos habilidades para la resolución de conflictos')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 2' AND t.TA_DESCRIPCION = 'Fortalecemos nuestro autoconocimiento y nuestro adecuado desarrollo personal social (1)')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 3' AND t.TA_DESCRIPCION = 'Proyecto de vida por una cultura de paz "matriz de coherencia"')
      OR (t.TE_ID_TEMA = 6 AND t.TA_NOMBRE = 'Taller 4' AND t.TA_DESCRIPCION = 'Fortalecer nuestro autoconocimiento y nuestro adecuado desarrollo personal social (2)')
   )
ORDER BY
   t.TE_ID_TEMA,
   t.TA_NOMBRE
/


-- =============================================================================
-- * 4. Talleres "No aplica" para temas sin talleres propios
--     Temas: 1 (Promoción del Emprendimiento Familiar)
--            3 (Orientación laboral)
-- =============================================================================

-- * 4.1 Validación previa: confirmar IDs y nombres de tema
--     Esperado: 2 filas (TE_ID_TEMA 1 y 3)
SELECT
   te.TE_ID_TEMA,
   te.TE_NOMBRE,
   te.UN_ID_UNIDAD
FROM SSI_TEMAS te
WHERE
   te.TE_ID_TEMA IN (1, 3)
/

-- * 4.2 Anti-duplicado: verificar que no exista ya "No aplica" en esos temas
--     Esperado: 0 filas. Si devuelve filas -> NO insertar (ya existe).
SELECT
   t.TA_ID_TALLER,
   t.TE_ID_TEMA,
   t.TA_NOMBRE,
   t.TA_DESCRIPCION
FROM SSI_TALLERES t
WHERE
   t.TE_ID_TEMA IN (1, 3)
   AND UPPER(TRIM(t.TA_NOMBRE)) = 'NO APLICA'
   AND t.TA_ELIMINADO = 0
/

-- * 4.3 INSERTs (1 taller por tema)
INSERT INTO SSI_TALLERES(TE_ID_TEMA, TA_NOMBRE, TA_DESCRIPCION, TA_USU_REGISTRA)
VALUES(1, 'No aplica', 'No aplica', 1)
/

INSERT INTO SSI_TALLERES(TE_ID_TEMA, TA_NOMBRE, TA_DESCRIPCION, TA_USU_REGISTRA)
VALUES(3, 'No aplica', 'No aplica', 1)
/

-- ! COMMIT;
-- ? ROLLBACK;

-- * 4.4 Validación post: confirmar los 2 talleres creados
--     Esperado: 2 filas
SELECT
   t.TA_ID_TALLER,
   t.TE_ID_TEMA,
   t.TA_NOMBRE,
   t.TA_DESCRIPCION,
   t.TA_FECHA_REGISTRA
FROM SSI_TALLERES t
WHERE
   t.TE_ID_TEMA IN (1, 3)
   AND UPPER(TRIM(t.TA_NOMBRE)) = 'NO APLICA'
   AND t.TA_ELIMINADO = 0
ORDER BY
   t.TA_ID_TALLER DESC
/
