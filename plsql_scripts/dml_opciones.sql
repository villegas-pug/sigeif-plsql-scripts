-- * 1. Crear MENU y SUBMENUs: `Reportes` y ...

-- * 1.1 `Reportes`
INSERT INTO TSOPCION(
               OPCDESCRIPCION, 
               OPCMODULO, 
               OPCENLACE,
               OPCDESTINO,
               OPCNIVEL,
               OPTTIPOENLACE,
               OPCPADRE,
               OPCORDEN,
               OPCESTADO,
               OPCUSUREGISTRA,
               OPCFECHAREGISTRA
            )
VALUES(
   'REPORTES', -- OPCDESCRIPCION
   4, -- OPCMODULO
   '#', -- OPCENLACE
   1, -- OPCDESTINO
   1, -- OPCNIVEL
   3, -- OPTTIPOENLACE
   NULL, -- OPCPADRE
   2, -- OPCORDEN
   1, -- OPCESTADO
   1, -- OPCUSUREGISTRA
   SYSDATE
);
/

UPDATE TSOPCION o
   SET
      o.OPCIMAGEN = 'assignment'
WHERE
   o.IDOPCION = 2418
/


INSERT INTO TSACCESO(ACCOPCION, ACCPERFIL, ACCESTADO, ACCUSUREGISTRA, ACCFECHAREGISTRA)
VALUES(
   2418, -- ACCOPCION
   26, -- ACCPERFIL
   1, -- ACCESTADO
   1, -- ACCUSUREGISTRA
   SYSDATE -- ACCFECHAREGISTRA
)
/

-- ! COMMIT;

-- * 1.2 Submenu → `Asistencia Económica` | path → `asistencia-economica`
INSERT INTO TSOPCION(
               OPCDESCRIPCION, 
               OPCMODULO, 
               OPCENLACE,
               OPCDESTINO,
               OPCNIVEL,
               OPTTIPOENLACE,
               OPCPADRE,
               OPCORDEN,
               OPCESTADO,
               OPCUSUREGISTRA,
               OPCFECHAREGISTRA
            )
VALUES(
   'Asistencia Económica', -- OPCDESCRIPCION
   4, -- OPCMODULO
   'asistencia-economica', -- OPCENLACE
   1, -- OPCDESTINO
   2, -- OPCNIVEL
   1, -- OPTTIPOENLACE
   2418, -- OPCPADRE
   1, -- OPCORDEN
   1, -- OPCESTADO
   1, -- OPCUSUREGISTRA
   SYSDATE
);
/


INSERT INTO TSACCESO(ACCOPCION, ACCPERFIL, ACCESTADO, ACCUSUREGISTRA, ACCFECHAREGISTRA)
VALUES(
   2419, -- ACCOPCION
   26, -- ACCPERFIL
   1, -- ACCESTADO
   1, -- ACCUSUREGISTRA
   SYSDATE -- ACCFECHAREGISTRA
)
/

-- ! COMMIT;

-- * 1.3 Submenu → `SIGEIR` | path → `sigeir`
INSERT INTO TSOPCION(
               OPCDESCRIPCION, 
               OPCMODULO, 
               OPCENLACE,
               OPCDESTINO,
               OPCNIVEL,
               OPTTIPOENLACE,
               OPCPADRE,
               OPCORDEN,
               OPCESTADO,
               OPCUSUREGISTRA,
               OPCFECHAREGISTRA
            )
VALUES(
   'SIGEIR', -- OPCDESCRIPCION
   4, -- OPCMODULO
   'sigeir', -- OPCENLACE
   1, -- OPCDESTINO
   2, -- OPCNIVEL
   1, -- OPTTIPOENLACE
   2418, -- OPCPADRE
   2, -- OPCORDEN
   1, -- OPCESTADO
   1, -- OPCUSUREGISTRA
   SYSDATE
);
/


INSERT INTO TSACCESO(ACCOPCION, ACCPERFIL, ACCESTADO, ACCUSUREGISTRA, ACCFECHAREGISTRA)
VALUES(
   2420, -- ACCOPCION
   26, -- ACCPERFIL
   1, -- ACCESTADO
   1, -- ACCUSUREGISTRA
   SYSDATE -- ACCFECHAREGISTRA
)
/









-- ! Test

-- ! 1.
SELECT * FROM TSACCESO o
WHERE
   o.ACCOPCION = 66
/

-- ! 2. 
SELECT * FROM TSOPCION o
ORDER BY
   o.IDOPCION DESC
/

-- ! 3. MENUs
SELECT * FROM TSOPCION o
WHERE 
   -- o.OPCDESCRIPCION LIKE 'INSTRUMENTOS DE MEDICION' -- 4
   -- o.OPCDESCRIPCION LIKE 'INSTRUMENTOS DE MEDICION' -- 4
   -- o.OPCDESCRIPCION LIKE 'Diagnóstico Familiar' -- 4
   -- o.OPCDESCRIPCION LIKE 'DIAGNÓSTICO' -- 4
   o.OPCDESCRIPCION LIKE '%PRE SELECCIÓN%' -- 4
/

SELECT * FROM TSOPCION o
WHERE 
   o.OPCDESCRIPCION LIKE 'Registro de instrumentos'
/

   
-- ! COMMIT;






-- Content-Disposition: form-data; name="attachment"; filename="rpt-asistencia-economica-2026-06-11-143643.xlsx"