
/*
*     1. Remplazar palabra `Punche` por `Familias Igualitarias` eb el campo `AP_PREGUNTA` de la tabla `SSI_ANEXOS_PREGUNTAS`
* ======================================================================================================================== */

-- Con Punche Familias → Familias Igualitarias
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET p.AP_PREGUNTA = REGEXP_REPLACE(p.AP_PREGUNTA, 'Con Punche Familias', 'Con Familias Igualitarias', 1, 0, 'i')
WHERE 
   UPPER(p.AP_PREGUNTA) LIKE '%' || UPPER('Punche') || '%'
/

-- ! COMMIT;
ROLLBACK;

-- ! Test
SELECT 
   p.*
   -- COUNT(1)
FROM SSI_ANEXOS_PREGUNTAS p
WHERE 
   -- UPPER(p.AP_PREGUNTA) LIKE '%' || UPPER('Punche') || '%' -- LAG
   UPPER(p.AP_PREGUNTA) LIKE '%' || UPPER('Familias Igualitarias') || '%' -- LEAD
/

-- * ========================================================================================================================


