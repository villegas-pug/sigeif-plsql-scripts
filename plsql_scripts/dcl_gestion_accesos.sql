-- * 1. Crea sistema de intranet
INSERT INTO TSSISTEMA (
   IDSISTEMA,
   SISNOMBRE,
   SISURL,
   SISABREVIATURA,
   SISESTADO,
   SISUSUREGISTRA,
   SISFECREGISTRA,
   SISVERSION,
   SIS_MIGRADO,
   SIS_FEC_INICIO,
   SIS_PADRE,
   SIS_ORDEN,
   SIS_ICONO
) VALUES (
   TSSISTEMA_SEQ.NEXTVAL, -- IDSISTEMA (secuencia)
   'SISTEMA DEL SERVICIO DE EDUCADORES DE CALLE (SISEC)', -- SISNOMBRE
   'https://srvapp03.inabif.gob.pe/sisec/#/inicio', -- SISURL
   'SISEC', -- SISABREVIATURA
   5, -- SISESTADO (1=activo)
   7496, -- SISUSUREGISTRA
   SYSDATE, -- SISFECREGISTRA
   '1.0', -- SISVERSION
   0, -- SIS_MIGRADO (default)
   SYSDATE, -- SIS_FEC_INICIO
   8, -- SIS_PADRE
   22, -- SIS_ORDEN
   'groups' -- SIS_ICONO
)
/

UPDATE TSSISTEMA s
    SET
        s.SISURL = 'https://srvapp03.inabif.gob.pe/sisec/#' -- SISURL
WHERE
   s.IDSISTEMA = 324
/

-- ! COMMIT;

SELECT * FROM TSSISTEMA s
WHERE
   s.IDSISTEMA = 324
/* ORDER BY
   s.IDSISTEMA DESC */
/

-- * 2. Opciones: Crear MENU y SUBMENUs

-- * 2.1 `SERVICIO EDUCADORES DE CALLE`
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
               OPCFECHAREGISTRA,
               OPCIMAGEN
            )
VALUES(
   'SERVICIO EDUCADORES DE CALLE', -- OPCDESCRIPCION
   4, -- OPCMODULO
   '#', -- OPCENLACE
   1, -- OPCDESTINO
   1, -- OPCNIVEL
   3, -- OPTTIPOENLACE
   NULL, -- OPCPADRE
   2, -- OPCORDEN
   1, -- OPCESTADO
   1, -- OPCUSUREGISTRA
   SYSDATE,
   'assignment'
)
/


UPDATE TSOPCION o
SET
    o.OPCMODULO = 554
WHERE
    o.IDOPCION IN (2437, 2438)
/

INSERT INTO TSACCESO(ACCOPCION, ACCPERFIL, ACCESTADO, ACCUSUREGISTRA, ACCFECHAREGISTRA)
VALUES(
   2437, -- ACCOPCION
   26, -- ACCPERFIL
   1, -- ACCESTADO
   1, -- ACCUSUREGISTRA
   SYSDATE -- ACCFECHAREGISTRA
)
/

UPDATE TSACCESO a
SET
    a.ACCPERFIL = 1821
WHERE
    a.IDACCESO IN (3893, 3892)
/

-- ! COMMIT;

-- * 2.2 Submenu → `Asistencia Económica` | path → `asistencia-economica`
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
   'Registro NNA', -- OPCDESCRIPCION
   4, -- OPCMODULO
   'registro-nna', -- OPCENLACE
   1, -- OPCDESTINO
   2, -- OPCNIVEL
   1, -- OPTTIPOENLACE
   2437, -- OPCPADRE
   1, -- OPCORDEN
   1, -- OPCESTADO
   1, -- OPCUSUREGISTRA
   SYSDATE
)
/


INSERT INTO TSACCESO(ACCOPCION, ACCPERFIL, ACCESTADO, ACCUSUREGISTRA, ACCFECHAREGISTRA)
VALUES(
   2438, -- ACCOPCION
   26, -- ACCPERFIL
   1, -- ACCESTADO
   1, -- ACCUSUREGISTRA
   SYSDATE -- ACCFECHAREGISTRA
)
/

-- ! COMMIT;






-- ! Test

-- ! 1.
SELECT * FROM TSOPCION o
ORDER BY
   o.IDOPCION DESC
/

-- ! 2. 
SELECT * FROM TSACCESO a
ORDER BY
    a.IDACCESO DESC
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

-- ! COMMIT;

-- ! Test
SELECT * FROM TSSISTEMA s
WHERE
    s.SISABREVIATURA IN ('SIGES', 'SIGEIF', 'SISEC')
    -- s.SISABREVIATURA IN ('SISEC')
    -- s.SIS_PADRE = 8
/

-- ! Antes: http://172.19.0.44:3004/?#/inicio
-- ? Ahota: https://srvapp03.inabif.gob.pe/siges/#/inicio
UPDATE TSSISTEMA s
    SET 
        -- s.SISURL = 'https://srvapp03.inabif.gob.pe/siges/#/inicio'
        s.SIS_ICONO = 'groups'
WHERE
    -- s.IDSISTEMA = 166
    s.IDSISTEMA = 166
/


SELECT * FROM TSMODULO m
WHERE
    m.IDMODULO = 554
/

UPDATE TSMODULO m
SET
    m.MODNOMBRE = 'SISEC'
WHERE
    m.IDMODULO = 554
/

-- ! COMMIT;