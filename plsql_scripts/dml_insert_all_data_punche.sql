


/*
*     1. Registro de Zonas:
* ======================================================================================================================== */

INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'050000',1,'AYACUCHO',1);
INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'070101',1,'CALLAO',1);
INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'130000',1,'LA LIBERTAD',1);
INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'',1,'LIMA CENTRO',1);
INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'',1,'LIMA ESTE ',1);
INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'',1,'LIMA NORTE',1);
INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'',1,'LIMA SUR',1);
INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'160000',1,'LORETO',1);
INSERT INTO SSI_ZONA_INTERVENCION(SI_ID_SERVICIO, UBI_ID_UBIGEO, ZO_COD_TIPO, ZO_DESCRIPCION, ZO_USU_REGISTRA) VALUES(2,'170000',1,'MADRE DE DIOS',1);

-- COMMIT;
ROLLBACK;

-- ! Test
SELECT * FROM SSI_ZONA_INTERVENCION z
WHERE 
   z.SI_ID_SERVICIO = 2
   AND z.ZO_FEC_REGISTRA BETWEEN TO_DATE('2025-11-21 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
   AND TO_DATE('2025-11-21 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY z.ZO_ID_ZONA DESC
/

-- * ========================================================================================================================


/*
*     2. Registro de potenciales familias
* ======================================================================================================================== */

-- * 2.1
-- INSERT INTO SSI_POTENCIALES_FAMILIAS(PF_COD_FAMILIA, ZO_ID_ZONA, SI_ID_SERVICIO, PF_USU_REGISTRA) VALUES(568,2,1);

-- COMMIT;

-- ! Test
DELETE FROM SSI_POTENCIALES_FAMILIAS f
WHERE 
   f.SI_ID_SERVICIO = 2
   AND f.PF_FEC_REGISTRA BETWEEN TO_DATE('2025-11-21 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
   AND TO_DATE('2025-11-21 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
/
ROLLBACK;

SELECT 
   -- COUNT(1)
   f.*
FROM SSI_POTENCIALES_FAMILIAS f
WHERE 
   f.SI_ID_SERVICIO = 2
   AND f.PF_FEC_REGISTRA BETWEEN TO_DATE('2025-11-21 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
   AND TO_DATE('2025-11-21 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY f.PF_ID_FAMILIA DESC
/

-- * 2.2 Actualzar fecha ingreso al servicio
-- UPDATE SSI_POTENCIALES_FAMILIAS f SET f.PF_FEC_REGISTRA = TO_DATE('', 'DD/MM/YYYY') WHERE PF_ID_FAMILIA = ?
-- COMMIT;

-- * 2.3 Actualizar estado `PF_FAMILIA_APTA`
-- UPDATE SSI_POTENCIALES_FAMILIAS f SET f.PF_FAMILIA_APTA = ? WHERE PF_ID_FAMILIA = ?


-- COMMIT;


ROLLBACK;
-- * ========================================================================================================================


/*
*     3. Registro Código familia
* ======================================================================================================================== */

-- * 3.1 Listar códigos familias
SELECT 
   TRIM(f.PF_COD_FAMILIA) AS PF_COD_FAMILIA,
   f.PF_ID_FAMILIA
FROM SSI_POTENCIALES_FAMILIAS f
WHERE 
   f.SI_ID_SERVICIO = 2
   AND f.PF_FEC_REGISTRA BETWEEN TO_DATE('2025-11-21 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
   AND TO_DATE('2025-11-21 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY f.PF_ID_FAMILIA DESC
/

-- * 3.2 Bulk
-- INSERT INTO SSI_CODIGOS_FAMILIAS(SI_ID_SERVICIO, PF_ID_FAMILIA, CF_CODIGO, CF_TIPO_CODIGO) VALUES()
-- COMMIT;
ROLLBACK;

-- ! Test
SELECT 
   COUNT(1)
   -- c.*
FROM SSI_CODIGOS_FAMILIAS c
WHERE 
   c.SI_ID_SERVICIO = 2
   AND c.CF_FECHA_REGISTRA BETWEEN TO_DATE('2025-11-21 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
   AND TO_DATE('2025-11-21 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
ORDER BY c.CF_ID_CODIGO DESC
/

-- ======================================================================================================================== */




/*
*     4. Registro de Integrantes (Cuidador principal)
* ======================================================================================================================== */

-- * 4.1 
/*

"INSERT INTO SSI_FAMILIA_INTEGRANTES(PF_ID_FAMILIA, FI_TELEFONO, CA_ID_TIPDOC, FI_NUMERO_DOC, FI_PRIMER_APE, FI_SEGUNDO_APE, FI_NOMBRES, CA_ID_SEXO, FI_FEC_NAC, FI_EDAD, CA_ID_ESTADO_CIVIL, CA_ID_PARENTESCO, CA_TIENE_DISCAPACIDAD, CA_ID_DISCAPACIDAD, CA_ID_LENGUA_MATERNA, CA_ID_GRADO_INST, CA_ID_OCUPACION, CA_ID_TIPO_SEGURO, FI_CUIDADOR, FI_USU_REGISTRA)
VALUES("&[@[PF_ID_FAMILIA]]&",'"&[@[NRO_TLF]]&","&[@[ID_TIP_DOC]]&"','"&[@[NRO_DOC]]&"','"&[@[PRI_APE_FAM]]&"','"&[@[SEG_APE_FAM]]&"','"&[@[NOM_FAM]]&"',"&[@[ID_SEXO]]&",'"&[@[FEC_NAC]]&"',"&[@[EDAD_USU]]&","&[@[ID_EST_CIV]]&","&[@[ID_PAR_FAM]]&",'"&[@[ID_TIE_DIS_FAM]]&"',"&[@[ID_TIP_DISC]]&","&[@[ID_LEN_MAT_FAM]]&","&[@[ID_GRAD_INST]]&","&[@[ID_OCU_FAM]]&","&[@[ID_TIP_SEG_SAL]]&", 1, 1);"

*/


-- COMMIT;
ROLLBACK;
-- INSERT INTO SSI_FAMILIA_INTEGRANTES(PF_ID_FAMILIA, FI_TELEFONO, CA_ID_TIPDOC, FI_NUMERO_DOC, FI_PRIMER_APE, FI_SEGUNDO_APE, FI_NOMBRES, CA_ID_SEXO, FI_FEC_NAC, FI_EDAD, CA_ID_ESTADO_CIVIL, CA_ID_PARENTESCO, CA_TIENE_DISCAPACIDAD, CA_ID_DISCAPACIDAD, CA_ID_LENGUA_MATERNA, CA_ID_GRADO_INST, CA_ID_OCUPACION, CA_ID_TIPO_SEGURO, FI_CUIDADOR, FI_USU_REGISTRA) VALUES(7650,'944321744',4589,'16765818','Cruz','Alarcon','	Beatriz Del Carmen',345,TO_DATE('17/07/1976', 'DD/MM/YYYY'),48,365,556,0,1016,2947,379,1026,414, 1, 1);


-- ! Test
SELECT 
   COUNT(1)
FROM SSI_FAMILIA_INTEGRANTES i
WHERE 
   i.FI_FEC_REGISTRA BETWEEN TO_DATE('2025-11-21 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
   AND TO_DATE('2025-11-21 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
   -- AND i.PF_ID_FAMILIA = 7650
ORDER BY i.FI_ID_INTEGRANTE DESC
/



-- * ========================================================================================================================


/*
*     5. Registro fichas: ANEXO 9 DIAGNÓSTICO FAMILIAR → 200,404
* ======================================================================================================================== */

-- * 5.1 Insert ...
-- INSERT INTO SSI_ANEXOS_RESPUESTAS(PF_ID_FAMILIA, AP_ID_PREGUNTA, AR_RESPUESTA, SF_ID_FASE, AR_USU_REGISTRA) VALUES()
   
-- COMMIT;
ROLLBACK;


SELECT name, value FROM v$parameter WHERE name = 'service_names';

-- ! Test
/* SELECT 
   COUNT(1)
   -- r.*
FROM SSI_ANEXOS_RESPUESTAS r */
DELETE FROM SSI_ANEXOS_RESPUESTAS r
WHERE
   r.AR_FECHA_REGISTRA BETWEEN TO_DATE('2025-11-22 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
   AND TO_DATE('2025-11-22 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
/

-- * ========================================================================================================================

/*
*     6. Registro fichas: ANEXO 10
* ======================================================================================================================== */

-- * 6.1 Insert ...
-- INSERT INTO SSI_ANEXOS_RESPUESTAS(PF_ID_FAMILIA, AP_ID_PREGUNTA, AR_RESPUESTA, SF_ID_FASE, AR_USU_REGISTRA) VALUES()
   
-- COMMIT;
ROLLBACK;


SELECT name, value FROM v$parameter WHERE name = 'service_names'
/

-- ! Test:
-- ! 1.
SELECT 
   MAX(f.AR_ID_RESPUESTA), -- 961,088
   MIN(f.AR_ID_RESPUESTA) -- 760,685
FROM (

   SELECT r.*
   FROM SSI_ANEXOS_RESPUESTAS r
   ORDER BY r.AR_ID_RESPUESTA DESC
   OFFSET 0 ROWS FETCH NEXT 200404 ROWS ONLY

) f
/

-- ! 2.
SELECT r.*
FROM SSI_ANEXOS_RESPUESTAS r
WHERE
   r.AR_ID_RESPUESTA = 760685
ORDER BY 
   r.AR_ID_RESPUESTA DESC
/

-- * ========================================================================================================================