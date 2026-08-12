/* =====================================================================
 * Cleanup: EDUCALLE (ID_SERVICIO_PADRE = 5)
 * ---------------------------------------------------------------------
 * Propósito : Eliminación física de respuestas (detalle) y cabeceras de
 *             anexos del servicio EDUCALLE, filtrando por
 *             SSI_ANEXO.ID_SERVICIO_PADRE = 5.
 *
 *             Tablas afectadas (SOLO ESTAS DOS):
 *               - SSI_ANEXOS_RESPUESTAS_V2  (detalle / hijo)
 *               - SSI_ANEXOS_CABECERA       (cabecera / padre)
 *
 *             No se elimina SSI_ANEXO (catálogo) ni otras dependencias.
 *
 *             ADVERTENCIA: SSI_ANEXO_CABECERA_AUDIO referencia
 *             ID_ANEXO_CABECERA sin FK física; sus registros quedarán
 *             huérfanos. Se reporta aquí, pero NO se incluye en el DELETE
 *             (alcance restringido a 2 tablas).
 *
 * Autor     : OpenCode
 * Fecha     : 2026-08-12
 * ===================================================================== */

-- =============================================================
-- 0. VALIDACIÓN PREVIA (solo lectura, sin DML)
-- =============================================================

-- 0.1 Conteo de anexos SSI_ANEXO con ID_SERVICIO_PADRE = 5
SELECT COUNT(*) AS CANT_ANEXOS_EDUCALLE
FROM SSI_ANEXO a
WHERE a.ID_SERVICIO_PADRE = 5
/

-- 0.2 Conteo de cabeceras SSI_ANEXOS_CABECERA (ID_SERVICIO_PADRE = 5)
SELECT COUNT(*) AS CANT_CABECERAS_EDUCALLE
FROM SSI_ANEXOS_CABECERA ac
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXO a
   WHERE a.ID_ANEXO = ac.ID_ANEXO
     AND a.ID_SERVICIO_PADRE = 5
)
/

-- 0.3 Conteo de respuestas SSI_ANEXOS_RESPUESTAS_V2 (ID_SERVICIO_PADRE = 5)
SELECT COUNT(*) AS CANT_RESPUESTAS_EDUCALLE
FROM SSI_ANEXOS_RESPUESTAS_V2 rv
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXO a
   WHERE a.ID_ANEXO = rv.ID_ANEXO
     AND a.ID_SERVICIO_PADRE = 5
)
/

-- 0.4 (ADVERTENCIA / opcional) Huérfanos potenciales en SSI_ANEXO_CABECERA_AUDIO
--     No se eliminan; solo se informa cuántos quedarían sin cabecera.
-- SELECT COUNT(*) AS CANT_AUDIO_HUERFANOS
-- FROM SSI_ANEXO_CABECERA_AUDIO au
-- WHERE EXISTS (
--    SELECT 1
--    FROM SSI_ANEXOS_CABECERA ac
--    JOIN SSI_ANEXO a ON a.ID_ANEXO = ac.ID_ANEXO
--    WHERE ac.ID_ANEXO_CABECERA = au.ID_ANEXO_CABECERA
--      AND a.ID_SERVICIO_PADRE = 5
-- )
-- /


-- =============================================================
-- 1. DELETE FÍSICO (hijo primero, luego padre)
-- =============================================================

-- 1.1 Respuestas (hijo) SSI_ANEXOS_RESPUESTAS_V2
DELETE FROM SSI_ANEXOS_RESPUESTAS_V2 rv
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXO a
   WHERE a.ID_ANEXO = rv.ID_ANEXO
     AND a.ID_SERVICIO_PADRE = 5
)
/

-- ! COMMIT;

-- 1.2 Cabeceras (padre) SSI_ANEXOS_CABECERA
DELETE FROM SSI_ANEXOS_CABECERA ac
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXO a
   WHERE a.ID_ANEXO = ac.ID_ANEXO
     AND a.ID_SERVICIO_PADRE = 5
)
/

-- ! COMMIT;
-- ? ROLLBACK;


-- =============================================================
-- 2. VERIFICACIÓN POSTERIOR (se espera 0 en cada conteo)
-- =============================================================

-- 2.1 Cabeceras SSI_ANEXOS_CABECERA (debe ser 0)
SELECT COUNT(*) AS CANT_CABECERAS_RESTANTES
FROM SSI_ANEXOS_CABECERA ac
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXO a
   WHERE a.ID_ANEXO = ac.ID_ANEXO
     AND a.ID_SERVICIO_PADRE = 5
)
/

-- 2.2 Respuestas SSI_ANEXOS_RESPUESTAS_V2 (debe ser 0)
SELECT COUNT(*) AS CANT_RESPUESTAS_RESTANTES
FROM SSI_ANEXOS_RESPUESTAS_V2 rv
WHERE EXISTS (
   SELECT 1
   FROM SSI_ANEXO a
   WHERE a.ID_ANEXO = rv.ID_ANEXO
     AND a.ID_SERVICIO_PADRE = 5
)
/
