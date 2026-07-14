/* Cleanup: CEDIF               */

-- =============================================================
-- Cleanup servicio 1: zonas, equipos, aliados, familias,
-- integrantes, anexos respuestas y dependencias.
-- Nota: no se elimina SSI_ANEXOS_PREGUNTAS.
-- =============================================================

-- 1. Respuestas de anexos
DELETE FROM SSI_ANEXOS_RESPUESTAS ar
WHERE EXISTS (
               SELECT 1 FROM SSI_POTENCIALES_FAMILIAS pf
               LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               WHERE 
                  pf.PF_ID_FAMILIA = ar.PF_ID_FAMILIA
                  AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
OR EXISTS (
            SELECT 1 FROM SSI_FAMILIA_INTEGRANTES fi
            JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
            LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
            WHERE 
               fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
               AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
OR EXISTS (
            SELECT 1 FROM SSI_ANEXOS_PREGUNTAS ap
            WHERE 
               ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
               AND ap.SI_ID_SERVICIO = 1
)
/

-- ! COMMIT;
-- ? ROLLBACK;

-- 2. Integrantes en ejecucion de sesiones
DELETE FROM SSI_EJEC_SESION_INTEGRANTES esi
WHERE EXISTS (
   SELECT 1
   FROM SSI_FAMILIA_INTEGRANTES fi
   JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
   LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
   WHERE 
      fi.FI_ID_INTEGRANTE = esi.FI_ID_INTEGRANTE
      AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
/

-- ! COMMIT;

-- 3. Ejecucion de sesiones
DELETE FROM SSI_EJECUCION_SESIONES es
WHERE EXISTS (
               SELECT 1
               FROM SSI_DET_PATFAM dp
               JOIN SSI_PATFAM pa ON pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
               JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
               LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               WHERE 
                  dp.DP_ID_DET_PATFAM = es.DP_ID_DET_PATFAM
                  AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
/
-- ! COMMIT;

-- 4. Programacion de talleres por familia
DELETE FROM SSI_PROG_TALLER_FAMILIAS ptf
WHERE EXISTS (
               SELECT 1
               FROM SSI_POTENCIALES_FAMILIAS pf
               LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               WHERE 
                  pf.PF_ID_FAMILIA = ptf.PF_ID_FAMILIA
                  AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
/
-- ! COMMIT;

-- 5. Detalle PATFAM
DELETE FROM SSI_DET_PATFAM dp
WHERE EXISTS (
   SELECT 1
   FROM SSI_PATFAM pa
   JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
   LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
   WHERE pa.PA_ID_PATFAM = dp.PA_ID_PATFAM
     AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
/
-- ! COMMIT;

-- 6. Cabecera PATFAM
DELETE FROM SSI_PATFAM pa
WHERE EXISTS (
               SELECT 1
               FROM SSI_POTENCIALES_FAMILIAS pf
               LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               WHERE 
                  pf.PF_ID_FAMILIA = pa.PF_ID_FAMILIA
                  AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
/
-- ! COMMIT;

-- 7. Motivos de referencia por familia
DELETE FROM SSI_FAMILIA_MOTIVO_REFERENCIA fmr
WHERE EXISTS (
               SELECT 1
               FROM SSI_POTENCIALES_FAMILIAS pf
               LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               WHERE 
                  pf.PF_ID_FAMILIA = fmr.PF_ID_FAMILIA
                  AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
/
-- ! COMMIT;

-- 8. Codigos de familia / integrantes
DELETE FROM SSI_CODIGOS_FAMILIAS cf
WHERE cf.SI_ID_SERVICIO = 1
OR EXISTS (
            SELECT 1
            FROM SSI_POTENCIALES_FAMILIAS pf
            LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
            WHERE 
               pf.PF_ID_FAMILIA = cf.PF_ID_FAMILIA
               AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
/
-- ! COMMIT;


-- 9. Integrantes
DELETE FROM SSI_FAMILIA_INTEGRANTES fi
WHERE EXISTS (
               SELECT 1
               FROM SSI_POTENCIALES_FAMILIAS pf
               LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               WHERE 
                  pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
                  AND (pf.SI_ID_SERVICIO = 1 OR zi.SI_ID_SERVICIO = 1)
)
/
-- ! COMMIT;

-- 10. Familias
DELETE FROM SSI_POTENCIALES_FAMILIAS pf
WHERE pf.SI_ID_SERVICIO = 1
OR EXISTS (
            SELECT 1
            FROM SSI_ZONA_INTERVENCION zi
            WHERE 
               zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               AND zi.SI_ID_SERVICIO = 1
)
/
-- ! COMMIT;

-- 11. Contactos de aliados
DELETE FROM SSI_CONTACTO co
WHERE EXISTS (
               SELECT 1
               FROM SSI_ALIADOS al
               JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = al.ZO_ID_ZONA
               WHERE 
                  al.AL_ID_ALIADO = co.AL_ID_ALIADO
                  AND zi.SI_ID_SERVICIO = 1
)
/
-- ! COMMIT;

-- 12. Actas de aliados
DELETE FROM SSI_ACTAS ac
WHERE EXISTS (
               SELECT 1
               FROM SSI_ALIADOS al
               JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = al.ZO_ID_ZONA
               WHERE 
                  al.AL_ID_ALIADO = ac.AL_ID_ALIADO
                  AND zi.SI_ID_SERVICIO = 1
)
/
-- ! COMMIT;

-- 13. Aliados
DELETE FROM SSI_ALIADOS al
WHERE EXISTS (
               SELECT 1
               FROM SSI_ZONA_INTERVENCION zi
               WHERE 
                  zi.ZO_ID_ZONA = al.ZO_ID_ZONA
                  AND zi.SI_ID_SERVICIO = 1
)
/

-- 14. Equipo de trabajo
DELETE FROM SSI_EQUIPO_TRABAJO et
WHERE EXISTS (
               SELECT 1
               FROM SSI_ZONA_INTERVENCION zi
               WHERE 
                  zi.ZO_ID_ZONA = et.ZO_ID_ZONA
                  AND zi.SI_ID_SERVICIO = 1
)
/

-- 15. Zonas de intervencion
DELETE FROM SSI_ZONA_INTERVENCION zi
WHERE zi.SI_ID_SERVICIO = 1
/


-- ============================================================
-- DELETE: Programación de talleres y dependencias → CEDIF
-- Servicio objetivo: SI_ID_SERVICIO = 1  (CEDIF)
-- Esquema: USRSEGURIDAD (XE)
-- Orden: nietos → hijos → padre (respetando FKs)
-- ============================================================

/* ---------- 0. VALIDACIÓN PREVIA (SELECT COUNT) ---------- */
SELECT 'A.ASIS'  AS tabla, COUNT(*) AS filas_a_borrar
  FROM SSI_PROGRAMACION_TALLERES_FECHAS_ASISTENCIA tasis
 WHERE tasis.TF_ID_PROG_FEC IN (
       SELECT fec.TF_ID_PROG_FEC
         FROM SSI_PROGRAMACION_TALLERES_FECHAS fec
         JOIN SSI_PROGRAMACION_TALLERES pt ON pt.PT_ID_PROG = fec.PT_ID_PROG
         JOIN SSI_TALLERES t               ON t.TA_ID_TALLER = pt.TA_ID_TALLER
        WHERE t.SI_ID_SERVICIO = 1)
UNION ALL
SELECT 'B.FECH'  AS tabla, COUNT(*)
  FROM SSI_PROGRAMACION_TALLERES_FECHAS fec
 WHERE fec.PT_ID_PROG IN (
       SELECT pt.PT_ID_PROG
         FROM SSI_PROGRAMACION_TALLERES pt
         JOIN SSI_TALLERES t ON t.TA_ID_TALLER = pt.TA_ID_TALLER
        WHERE t.SI_ID_SERVICIO = 1)
UNION ALL
SELECT 'C.PART'  AS tabla, COUNT(*)
  FROM SSI_PROGRAMACION_TALLERES_PARTICIPANTES par
 WHERE par.PT_ID_PROG IN (
       SELECT pt.PT_ID_PROG
         FROM SSI_PROGRAMACION_TALLERES pt
         JOIN SSI_TALLERES t ON t.TA_ID_TALLER = pt.TA_ID_TALLER
        WHERE t.SI_ID_SERVICIO = 1)
UNION ALL
SELECT 'D.PROG'  AS tabla, COUNT(*)
  FROM SSI_PROGRAMACION_TALLERES pt
 WHERE EXISTS (
       SELECT 1
         FROM SSI_TALLERES t
        WHERE t.TA_ID_TALLER = pt.TA_ID_TALLER
          AND t.SI_ID_SERVICIO = 1)
/

/* ---------- 1. EJECUCIÓN DENTRO DE SAVEPOINT ---------- */
-- Ejecutar en SQL*Plus / SQL Developer con AUTOCOMMIT OFF.
-- Cada bloque es informativo; ajustar a un único script transaccional.

SAVEPOINT sp_pre_delete_cedif;

-- 1.1 Nietos: asistencia por fecha
DELETE FROM SSI_PROGRAMACION_TALLERES_FECHAS_ASISTENCIA tasis
 WHERE tasis.TF_ID_PROG_FEC IN (
       SELECT fec.TF_ID_PROG_FEC
         FROM SSI_PROGRAMACION_TALLERES_FECHAS fec
         JOIN SSI_PROGRAMACION_TALLERES pt ON pt.PT_ID_PROG = fec.PT_ID_PROG
         JOIN SSI_TALLERES t               ON t.TA_ID_TALLER = pt.TA_ID_TALLER
        WHERE t.SI_ID_SERVICIO = 1)
/

-- 1.2 Hijos: fechas de programación
DELETE FROM SSI_PROGRAMACION_TALLERES_FECHAS fec
 WHERE fec.PT_ID_PROG IN (
       SELECT pt.PT_ID_PROG
         FROM SSI_PROGRAMACION_TALLERES pt
         JOIN SSI_TALLERES t ON t.TA_ID_TALLER = pt.TA_ID_TALLER
        WHERE t.SI_ID_SERVICIO = 1)
/

-- 1.3 Hijos: participantes
DELETE FROM SSI_PROGRAMACION_TALLERES_PARTICIPANTES par
 WHERE par.PT_ID_PROG IN (
       SELECT pt.PT_ID_PROG
         FROM SSI_PROGRAMACION_TALLERES pt
         JOIN SSI_TALLERES t ON t.TA_ID_TALLER = pt.TA_ID_TALLER
        WHERE t.SI_ID_SERVICIO = 1)
/

-- 1.4 Padre: programación de talleres
DELETE FROM SSI_PROGRAMACION_TALLERES pt
 WHERE EXISTS (
       SELECT 1
         FROM SSI_TALLERES t
        WHERE t.TA_ID_TALLER = pt.TA_ID_TALLER
          AND t.SI_ID_SERVICIO = 1)
/

-- Confirmar o deshacer:
-- ! COMMIT;          -- aplica definitivamente
-- ? ROLLBACK TO sp_pre_delete_cedif;  -- revierte todo


-- 17. Actualizar Familias con `Ficha de Compromiso`, estado `PF_FAMILIA_APTA` a 1
UPDATE  SSI_POTENCIALES_FAMILIAS f
SET
   f.PF_FAMILIA_APTA = 1
WHERE
  f.SI_ID_SERVICIO = 1
  AND f.PF_FAMILIA_APTA = 0
/

-- ! COMMIT;
-- ? ROLLBACK;


-- ! Test

-- ! 1. Zonas
SELECT * FROM SSI_ZONA_INTERVENCION z
WHERE
   z.SI_ID_SERVICIO = 1
ORDER BY z.ZO_ID_ZONA DESC
/


-- ! 2. Familias
SELECT 
   -- f.* 
   COUNT(1)
FROM SSI_POTENCIALES_FAMILIAS f
WHERE
  f.SI_ID_SERVICIO = 1
  -- AND f.PF_FAMILIA_APTA = 0
/

-- ! 3. Otros

SELECT
   -- COUNT(1)
   ap.*
   -- ap.AP_ID_PREGUNTA,
   -- ap.AP_PREGUNTA
FROM SSI_ANEXOS_PREGUNTAS ap
WHERE
   -- ap.SI_ID_SERVICIO = 1
   -- AND ap.AP_NUM_GRUPO = -5
   -- AND ap.AP_NUM_ANEXO = 7
   -- AND ap.AP_NUM_ANEXO = 10 -- FFSIL
   -- AND ap.AP_NUM_ANEXO = 9 -- DIAGNOSTICO
   -- AND ap.AP_NUM_ANEXO = 11 -- TSV
   ap.AP_ID_PREGUNTA = 396
/

SELECT 
   -- ap.*
   ap.AP_ID_PREGUNTA,
   ap.AP_PREGUNTA,
   r.AR_RESPUESTA,
   r.SF_ID_FASE
FROM SSI_ANEXOS_PREGUNTAS ap
JOIN SSI_ANEXOS_RESPUESTAS r ON ap.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
WHERE
   ap.SI_ID_SERVICIO = 2
   -- AND ap.AP_NUM_ANEXO = 7
   AND ap.AP_NUM_ANEXO = 14
ORDER BY
   r.AR_ID_RESPUESTA DESC
/

SELECT COUNT(1) FROM SSI_ANEXOS_RESPUESTAS r
WHERE
   EXISTS (
      SELECT 1
      FROM SSI_ANEXOS_PREGUNTAS ap
      WHERE
         ap.SI_ID_SERVICIO = 1
         -- AND ap.AP_NUM_ANEXO = 10 -- FFSIL
         AND ap.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
   )
/

-- ? ROLLBACK;

SELECT * FROM SSI_DET_PATFAM
/



