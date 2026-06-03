/* Cleanup:                */

-- =============================================================
-- Cleanup servicio 2: zonas, equipos, aliados, familias,
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
                  AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
)
OR EXISTS (
            SELECT 1 FROM SSI_FAMILIA_INTEGRANTES fi
            JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
            LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
            WHERE 
               fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
               AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
)
OR EXISTS (
            SELECT 1 FROM SSI_ANEXOS_PREGUNTAS ap
            WHERE 
               ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
               AND ap.SI_ID_SERVICIO = 2
)
/

-- ! COMMIT;

-- 2. Integrantes en ejecucion de sesiones
DELETE FROM SSI_EJEC_SESION_INTEGRANTES esi
WHERE EXISTS (
   SELECT 1
   FROM SSI_FAMILIA_INTEGRANTES fi
   JOIN SSI_POTENCIALES_FAMILIAS pf ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
   LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
   WHERE 
      fi.FI_ID_INTEGRANTE = esi.FI_ID_INTEGRANTE
      AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
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
                  AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
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
                  AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
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
     AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
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
                  AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
)
/
-- ! COMMIT;

-- 7. Motivos de referencia por familia
SELECT * FROM SSI_MOTIVO_REFERENCIA
/

DELETE FROM SSI_FAMILIA_MOTIVO_REFERENCIA fmr
WHERE EXISTS (
               SELECT 1
               FROM SSI_POTENCIALES_FAMILIAS pf
               LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               WHERE 
                  pf.PF_ID_FAMILIA = fmr.PF_ID_FAMILIA
                  AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
)
/
-- ! COMMIT;

-- 8. Codigos de familia / integrantes
DELETE FROM SSI_CODIGOS_FAMILIAS cf
WHERE cf.SI_ID_SERVICIO = 2
OR EXISTS (
            SELECT 1
            FROM SSI_POTENCIALES_FAMILIAS pf
            LEFT JOIN SSI_ZONA_INTERVENCION zi ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
            WHERE 
               pf.PF_ID_FAMILIA = cf.PF_ID_FAMILIA
               AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
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
                  AND (pf.SI_ID_SERVICIO = 2 OR zi.SI_ID_SERVICIO = 2)
)
/
-- ! COMMIT;

-- 10. Familias
DELETE FROM SSI_POTENCIALES_FAMILIAS pf
WHERE pf.SI_ID_SERVICIO = 2
OR EXISTS (
            SELECT 1
            FROM SSI_ZONA_INTERVENCION zi
            WHERE 
               zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
               AND zi.SI_ID_SERVICIO = 2
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
                  AND zi.SI_ID_SERVICIO = 2
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
                  AND zi.SI_ID_SERVICIO = 2
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
                  AND zi.SI_ID_SERVICIO = 2
)
/

-- 14. Equipo de trabajo
DELETE FROM SSI_EQUIPO_TRABAJO et
WHERE EXISTS (
               SELECT 1
               FROM SSI_ZONA_INTERVENCION zi
               WHERE 
                  zi.ZO_ID_ZONA = et.ZO_ID_ZONA
                  AND zi.SI_ID_SERVICIO = 2
)
/

-- 15. Zonas de intervencion
DELETE FROM SSI_ZONA_INTERVENCION zi
WHERE zi.SI_ID_SERVICIO = 2
/



-- ! COMMIT;
-- ? ROLLBACK;


-- ! Test

SELECT * FROM SSI_ZONA_INTERVENCION z
WHERE
   z.SI_ID_SERVICIO = 2
ORDER BY z.ZO_ID_ZONA DESC
/

SELECT * FROM SSI_ALIADOS
/

SELECT * FROM SSI_EQUIPO_TRABAJO
/

SELECT * FROM SSI_CONTACTO
/

SELECT * FROM SSI_POTENCIALES_FAMILIAS
/

SELECT * FROM SSI_POTENCIALES_FAMILIAS
/

SELECT 
   -- COUNT(1) 
   ap.*
FROM SSI_ANEXOS_PREGUNTAS ap
WHERE
   ap.SI_ID_SERVICIO = 2
   AND ap.AP_NUM_ANEXO = 7
/

TRUNCATE TABLE SSI_ZONA_INTERVENCION
TRUNCATE TABLE SSI_ALIADOS
TRUNCATE TABLE SSI_EQUIPO_TRABAJO
TRUNCATE TABLE SSI_CONTACTO
TRUNCATE TABLE SSI_POTENCIALES_FAMILIAS
/




