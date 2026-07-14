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
        s.SISURL = 'https://srvapp03.inabif.gob.pe/sisec/#/inicio' -- SISURL
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

-- * 2.2 `INICIO`
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
   'INICIO', -- OPCDESCRIPCION
   554, -- OPCMODULO
   '#', -- OPCENLACE
   1, -- OPCDESTINO
   1, -- OPCNIVEL
   1, -- OPTTIPOENLACE
   NULL, -- OPCPADRE
   1, -- OPCORDEN
   1, -- OPCESTADO
   1, -- OPCUSUREGISTRA
   SYSDATE,
   'home'
)
/


UPDATE TSOPCION o
SET
    -- o.OPCMODULO = 554
   o.OPCORDEN = 9
WHERE
    -- o.IDOPCION IN (2437, 2438)
    o.IDOPCION = 2497
/

UPDATE TSOPCION o
SET
    o.OPCDESCRIPCION = 'INICIO',
    o.OPTTIPOENLACE = 1,
    o.OPCORDEN2 = 1
WHERE
    o.IDOPCION IN (2457)
/

-- ! COMMIT;

INSERT INTO TSACCESO(ACCOPCION, ACCPERFIL, ACCESTADO, ACCUSUREGISTRA, ACCFECHAREGISTRA)
VALUES(
   2437, -- ACCOPCION
   26, -- ACCPERFIL
   1, -- ACCESTADO
   1, -- ACCUSUREGISTRA
   SYSDATE -- ACCFECHAREGISTRA
)
/

-- ? INICIO
INSERT INTO TSACCESO(ACCOPCION, ACCPERFIL, ACCESTADO, ACCUSUREGISTRA, ACCFECHAREGISTRA)
VALUES(
   2457, -- ACCOPCION
   26, -- ACCPERFIL
   1, -- ACCESTADO
   1, -- ACCUSUREGISTRA
   SYSDATE -- ACCFECHAREGISTRA
)
/

-- ! COMMIT;

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
/* WHERE
   o.OPCDESCRIPCION LIKE '%INI%' */
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




-- * 3. Adicionar Sub Menú a INTERVENCION - Familias Igualitarias

-- * 2.1 Opcion: PROMOCIÓN E INCIDENCIA COMUNITARIA

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
   'INICIO', -- OPCDESCRIPCION
   554, -- OPCMODULO
   '#', -- OPCENLACE
   1, -- OPCDESTINO
   1, -- OPCNIVEL
   1, -- OPTTIPOENLACE
   NULL, -- OPCPADRE
   1, -- OPCORDEN
   1, -- OPCESTADO
   1, -- OPCUSUREGISTRA
   SYSDATE,
   'home'
)
/


-- ! Test
-- 126 | SISTEMA DE INFORMACIÓN DE GESTIÓN DE FAMILIAS (SIGEIF)

SELECT * FROM TSSISTEMA s
WHERE
   -- s.IDSISTEMA = 324
   s.SISNOMBRE LIKE '%SIGEIF%'
/

SELECT * FROM TSOPCION o
WHERE
   o.OPCDESCRIPCION LIKE '%INI%'
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
   o.OPCDESCRIPCION LIKE 'INTERVENC%' -- 4
/

SELECT * FROM TSOPCION o
WHERE 
   o.OPCDESCRIPCION LIKE 'Registro de instrumentos'
/



-- * SELECTs READ-ONLY (úsalos primero para entender el estado actual)

-- * 1) Listado de sistemas disponibles
SELECT
   s.IDSISTEMA      AS id_sistema,
   s.SISABREVIATURA AS abreviatura,
   s.SISNOMBRE      AS nombre,
   s.SISURL         AS url,
   s.SISVERSION     AS version,
   DECODE(s.SISESTADO, 1, 'ACTIVO', 5, 'ACTIVO(5)', 0, 'INACTIVO', 'OTRO') AS estado
FROM TSSISTEMA s
ORDER BY NVL(s.SIS_PADRE, -1), s.SIS_ORDEN, s.SISNOMBRE
/

-- * 2) Listado de opciones/páginas de un sistema concreto (bind variable)
SELECT
   s.IDSISTEMA      AS id_sistema,
   s.SISABREVIATURA AS sistema_abrev,
   m.IDMODULO       AS id_modulo,
   m.MODNOMBRE      AS modulo,
   o.IDOPCION       AS id_opcion,
   o.OPCNIVEL       AS nivel,
   o.OPCDESCRIPCION AS descripcion,
   o.OPCPADRE       AS id_padre,
   op.OPCDESCRIPCION AS descripcion_padre,
   o.OPCENLACE      AS enlace_ruta,
   o.OPCORDEN       AS orden,
   o.OPCIMAGEN      AS icono,
   DECODE(o.OPCESTADO, 1, 'ACTIVO', 0, 'INACTIVO', 'OTRO') AS estado
FROM TSSISTEMA s
   INNER JOIN TSMODULO m  ON m.MODSISTEMA = s.IDSISTEMA
   INNER JOIN TSOPCION o  ON o.OPCMODULO  = m.IDMODULO
   LEFT  JOIN TSOPCION op ON op.IDOPCION  = o.OPCPADRE
WHERE 
   s.IDSISTEMA = 126 -- 126 | SISTEMA DE INFORMACIÓN DE GESTIÓN DE FAMILIAS (SIGEIF)
   AND m.IDMODULO = 511 -- 126 | SISTEMA DE INFORMACIÓN DE GESTIÓN DE FAMILIAS (SIGEIF)
   AND o.OPCPADRE = 2240 -- INTERVENCION
   AND m.MODESTADO = 1
ORDER BY m.MOD_ORDEN, o.OPCNIVEL, o.OPCORDEN, o.OPCDESCRIPCION
/

SELECT * FROM TSACCESO a
WHERE
    -- a.IDACCESO IN (3893, 3892)
    a.ACCOPCION = 2240
/

-- ! Test

-- ! V0 — Identificar la secuencia real de TSOPCION (CRÍTICO, correr primero)
SELECT s.OWNER, s.SEQUENCE_NAME, s.LAST_NUMBER
FROM ALL_SEQUENCES s
WHERE s.SEQUENCE_NAME LIKE '%OPCION%'
  AND s.OWNER = USER
ORDER BY s.SEQUENCE_NAME
/

-- V1–V3 — Precondiciones del alta
-- V1: Sistema 126 activo
SELECT IDSISTEMA, SISABREVIATURA, SISNOMBRE, SISESTADO
FROM TSSISTEMA WHERE IDSISTEMA = 126
/

-- V2: Módulo 511 en sistema 126 y activo
SELECT IDMODULO, MODNOMBRE, MODSISTEMA, MODESTADO
FROM TSMODULO WHERE IDMODULO = 511 AND MODSISTEMA = 126
/

-- V3: Padre 2240 pertenece a módulo 511 y está activo
SELECT IDOPCION, OPCDESCRIPCION, OPCMODULO, OPCPADRE, OPCNIVEL, OPCESTADO
FROM TSOPCION WHERE IDOPCION = 2240 AND OPCMODULO = 511 AND OPCESTADO = 1
/

-- V4–V5 — Duplicados
-- V4: ¿Ya existe la descripción bajo el mismo padre?
SELECT IDOPCION, OPCDESCRIPCION, OPCPADRE
FROM TSOPCION
WHERE OPCPADRE = 2240
  AND UPPER(TRIM(OPCDESCRIPCION)) = UPPER('Promoción e Incidencia Comunitaria')
/

-- V5: ¿La ruta 'promocion-incidencia' ya está usada en el módulo 511?
SELECT IDOPCION, OPCDESCRIPCION, OPCENLACE
FROM TSOPCION
WHERE OPCMODULO = 511
  AND UPPER(TRIM(OPCENLACE)) = 'PROMOCION-INCIDENCIA'
/

-- V7 — Verificar orden 4 libre
SELECT OPCPADRE, OPCORDEN, OPCDESCRIPCION
FROM TSOPCION
WHERE OPCPADRE = 2240
ORDER BY OPCORDEN
/





-- ! SCRIPT C — Alta combinada TSOPCION + TSACCESO (RECOMENDADO)

DECLARE
   v_id_opcion_new     TSOPCION.IDOPCION%TYPE;
   v_id_acceso_new     TSACCESO.IDACCESO%TYPE;
   v_error_code        NUMBER;
   v_error_message     VARCHAR2(4000);

   v_sis_id            TSSISTEMA.IDSISTEMA%TYPE       := 126;
   v_mod_id            TSMODULO.IDMODULO%TYPE         := 511;
   v_opc_padre         TSOPCION.OPCPADRE%TYPE         := 2240;
   v_opc_descripcion   TSOPCION.OPCDESCRIPCION%TYPE   := 'Promoción e Incidencia Comunitaria';
   v_opc_enlace        TSOPCION.OPCENLACE%TYPE        := 'promocion-incidencia';
   v_opc_orden         TSOPCION.OPCORDEN%TYPE         := 4;
   v_opc_nivel         TSOPCION.OPCNIVEL%TYPE         := 2;
   v_opc_destino       TSOPCION.OPCDESTINO%TYPE       := 1;
   v_opc_tipo_enlace   TSOPCION.OPTTIPOENLACE%TYPE    := 1;
   v_opc_estado        TSOPCION.OPCESTADO%TYPE        := 1;
   v_opc_usu_registra  TSOPCION.OPCUSUREGISTRA%TYPE   := 1;

   v_acc_perfil        TSACCESO.ACCPERFIL%TYPE        := 221;
   v_acc_estado        TSACCESO.ACCESTADO%TYPE        := 1;
   v_acc_usu_registra  TSACCESO.ACCUSUREGISTRA%TYPE   := 1;
BEGIN
   -- Validaciones de negocio previas
   IF v_opc_nivel = 2 AND v_opc_padre IS NULL THEN
      RAISE_APPLICATION_ERROR(-20010, 'Nivel 2 requiere OPCPADRE no nulo.');
   END IF;

   -- Verificar módulo pertenece al sistema y está activo
   DECLARE
      v_count NUMBER;
   BEGIN
      SELECT COUNT(*) INTO v_count
      FROM TSMODULO m
      WHERE m.IDMODULO = v_mod_id
        AND m.MODSISTEMA = v_sis_id
        AND m.MODESTADO = 1;

      IF v_count = 0 THEN
         DBMS_OUTPUT.PUT_LINE('WARN: IDMODULO='||v_mod_id||' no pertenece a IDSISTEMA='||v_sis_id||' o está inactivo.');
      END IF;
   END;

   -- FASE 1: INSERT TSOPCION (sin ID, asumiendo trigger BEFORE INSERT)
   INSERT INTO TSOPCION (
      OPCDESCRIPCION, OPCMODULO, OPCENLACE, OPCDESTINO,
      OPCNIVEL, OPTTIPOENLACE, OPCPADRE, OPCORDEN,
      OPCIMAGEN, OPCESTADO, OPCUSUREGISTRA, OPCFECHAREGISTRA,
      OPCUSUACTUALIZA, OPCFECHAACTUALIZA, OPCUSUELIMINA, OPCFECHAELIMINA,
      OPCLIGHTBOX, OPCORDEN2, OPCFLGUSUCAR,
      OPC_FLG_SEPARADOR, OPC_FLG_DESHABILITADO, OPC_MSJ_DESHABILITADO,
      OPC_FLG_USUARIO_PERMISO, OPC_FLG_MENU_ABIERTO_DEFECTO
   ) VALUES (
      v_opc_descripcion, v_mod_id, v_opc_enlace, v_opc_destino,
      v_opc_nivel, v_opc_tipo_enlace, v_opc_padre, v_opc_orden,
      NULL, v_opc_estado, v_opc_usu_registra, SYSDATE,
      NULL, NULL, NULL, NULL,
      NULL, NULL, 0,
      0, 0, NULL,
      0, 0
   )
   RETURNING IDOPCION INTO v_id_opcion_new;

   DBMS_OUTPUT.PUT_LINE('TSOPCION: INSERT OK  →  IDOPCION = ' || v_id_opcion_new);

   -- FASE 2: INSERT TSACCESO usando el ID del RETURNING
   INSERT INTO TSACCESO (
      ACCOPCION, ACCPERFIL, ACCESTADO,
      ACCUSUREGISTRA, ACCFECHAREGISTRA,
      ACCUSUACTUALIZA, ACCFECHAACTUALIZA, ACCUSUELIMINA, ACCFECHAELIMINA
   ) VALUES (
      v_id_opcion_new, v_acc_perfil, v_acc_estado,
      v_acc_usu_registra, SYSDATE,
      NULL, NULL, NULL, NULL
   )
   RETURNING IDACCESO INTO v_id_acceso_new;

   DBMS_OUTPUT.PUT_LINE('TSACCESO: INSERT OK  →  IDACCESO = ' || v_id_acceso_new);
   DBMS_OUTPUT.PUT_LINE('===========================================================');
   DBMS_OUTPUT.PUT_LINE('RESUMEN SCRIPT_C (SIN COMMIT)');
   DBMS_OUTPUT.PUT_LINE('  IDOPCION = ' || v_id_opcion_new);
   DBMS_OUTPUT.PUT_LINE('  IDACCESO = ' || v_id_acceso_new);
   DBMS_OUTPUT.PUT_LINE('  ACCPERFIL = ' || v_acc_perfil);
   DBMS_OUTPUT.PUT_LINE('Pendiente: ejecutar COMMIT; o ROLLBACK; para descartar.');

EXCEPTION
   WHEN DUP_VAL_ON_INDEX THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20030, 'Duplicado. ROLLBACK aplicado. ' || SQLERRM);

   WHEN OTHERS THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('ERROR: ' || v_error_code || ' - ' || v_error_message);
      RAISE_APPLICATION_ERROR(-20997, 'SCRIPT_C falló. ROLLBACK aplicado: ' || v_error_message);
END;
/

-- =============================================================
-- COMMIT (descomentar SOLO tras validar manualmente)
-- =============================================================
-- ! COMMIT;


-- SCRIPT D — Verificación READ-ONLY (post-COMMIT)
-- Reemplaza :p_id_opcion_new por el IDOPCION impreso por el SCRIPT C.
-- D.1) Confirmar fila en TSOPCION
SELECT o.IDOPCION, o.OPCDESCRIPCION, o.OPCMODULO, o.OPCPADRE,
       o.OPCENLACE, o.OPCNIVEL, o.OPCORDEN, o.OPCESTADO,
       o.OPCUSUREGISTRA, o.OPCFECHAREGISTRA
FROM TSOPCION o
WHERE o.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
  AND o.OPCMODULO      = 511
  AND o.OPCPADRE       = 2240
  AND o.OPCESTADO      = 1
  AND o.OPCUSUELIMINA IS NULL
/

-- D.2) Confirmar fila en TSACCESO
SELECT a.IDACCESO, a.ACCOPCION, a.ACCPERFIL, a.ACCESTADO,
       a.ACCUSUREGISTRA, a.ACCFECHAREGISTRA
FROM TSACCESO a
WHERE a.ACCOPCION = 2497
  AND a.ACCPERFIL = 221
/

-- D.3) JOIN integrado
SELECT o.IDOPCION, o.OPCDESCRIPCION, o.OPCMODULO, o.OPCPADRE,
       a.IDACCESO, a.ACCPERFIL, a.ACCESTADO
FROM TSOPCION o
JOIN TSACCESO a ON a.ACCOPCION = o.IDOPCION
WHERE o.IDOPCION = 2497
  AND a.ACCPERFIL = 221
/

-- D.4) Verificar que NO hay duplicados
-- 4.1) Duplicados en TSOPCION (por tripleta módulo+padre+descripción)
SELECT m.OPCMODULO, m.OPCPADRE, m.OPCDESCRIPCION, COUNT(*) AS VECES
FROM TSOPCION m
WHERE m.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
  AND m.OPCMODULO      = 511
  AND m.OPCPADRE       = 2240
  AND m.OPCUSUELIMINA IS NULL
GROUP BY m.OPCMODULO, m.OPCPADRE, m.OPCDESCRIPCION
HAVING COUNT(*) > 1
/

-- 4.2) Duplicados en TSACCESO (por ACCOPCION+ACCPERFIL)
SELECT d.ACCOPCION, d.ACCPERFIL, COUNT(*) AS VECES
FROM TSACCESO d
WHERE d.ACCOPCION = 2497
  AND d.ACCPERFIL = 221
GROUP BY d.ACCOPCION, d.ACCPERFIL
HAVING COUNT(*) > 1
/

-- D.5) Resumen ejecutivo
SELECT 'OPCION'  AS TIPO, COUNT(*) AS TOTAL
FROM TSOPCION o
WHERE o.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
  AND o.OPCMODULO      = 511
  AND o.OPCPADRE       = 2240
  AND o.OPCUSUELIMINA IS NULL
UNION ALL
SELECT 'ACCESOS' AS TIPO, COUNT(*) AS TOTAL
FROM TSACCESO a
WHERE a.ACCOPCION = 2497
  AND a.ACCPERFIL = 221
/


ALTER TABLE SSI_PROG_TALLERES
MODIFY PT_TEMA VARCHAR2(1000) NULL
/

-- ! COMMIT;


-- =============================================================
-- * STORED PROCEDURE: PRC_TSOPCION_ALTA_CON_ACCESO
-- -------------------------------------------------------------
-- * Propósito:
--   Da de alta, en una sola unidad transaccional, una nueva
--   opción de menú (TSOPCION) y, a continuación, su acceso
--   asociado para un perfil (TSACCESO). Devuelve los IDs
--   autogenerados por los triggers BEFORE INSERT de cada tabla
--   y reporta éxito/error por parámetros OUT.
--
-- * Tablas afectadas:
--   - TSOPCION  (alta de opción de menú/página)
--   - TSACCESO  (alta de permiso de perfil sobre esa opción)
--
-- * Reglas de negocio (códigos de error en p_codigo_error):
--      0           -> OK
--     -20010       -> nivel=2 sin OPCPADRE, o OPCPADRE inválido
--     -20011       -> nivel=1 con OPCPADRE no nulo
--     -20012       -> módulo no pertenece al sistema o inactivo
--     -20013       -> perfil no existe o inactivo
--     -20014       -> descripción duplicada (módulo+padre+desc)
--     -20015       -> enlace duplicado dentro del módulo
--     -20030       -> DUP_VAL_ON_INDEX (duplicado por índice único)
--     >0           -> SQLCODE (error Oracle genérico)
--
-- * Notas importantes:
--   - Los IDs IDOPCION e IDACCESO son asignados por triggers
--     BEFORE INSERT sobre cada tabla; NO se referencia
--     ninguna secuencia (SEQ_*.NEXTVAL) en los INSERT.
--   - El procedure NO ejecuta COMMIT. El caller decide.
--   - El procedure aplica ROLLBACK en el bloque EXCEPTION
--     para que la transacción quede consistente.
--
-- * Autor  : procedure-builder (orquestado por query-builder)
-- * Fecha  : 2026-07-13
-- * Proyecto: SIGEIF - Módulo de Gestión de Accesos
-- =============================================================

-- !  NO EJECUTAR sin aprobación explícita del usuario.
-- !  Antes de invocar, validar manualmente las precondiciones
-- !  (sistema activo, módulo activo, perfil activo, padre válido).

-- * DROP de seguridad (DESCOMENTAR SOLO para recompilar limpio)
-- DROP PROCEDURE PRC_TSOPCION_ALTA_CON_ACCESO;
-- /

CREATE OR REPLACE PROCEDURE PRC_TSOPCION_ALTA_CON_ACCESO (
   -- ? Contexto (referencial; se usa para validar módulo)
   p_id_sistema          IN  NUMBER,
   -- ? Datos de la nueva opción (TSOPCION)
   p_id_modulo           IN  NUMBER,
   p_id_opcion_padre     IN  NUMBER,         -- ? NULL si es opción raíz
   p_opc_descripcion     IN  VARCHAR2,
   p_opc_enlace          IN  VARCHAR2,
   p_opc_orden           IN  NUMBER,
   p_opc_nivel           IN  NUMBER,         -- ? 1=raíz, 2=submenú
   p_opc_destino         IN  NUMBER,         -- ? 1=interno
   p_opc_tipo_enlace     IN  NUMBER,         -- ? 1=ruta, 3=separador
   p_opc_estado          IN  NUMBER,         -- ? 1=activo
   p_opc_usu_registra    IN  NUMBER,
   -- ? Datos del acceso (TSACCESO)
   p_id_perfil           IN  NUMBER,
   p_acc_estado          IN  NUMBER,         -- ? 1=activo
   p_acc_usu_registra    IN  NUMBER,
   -- ? Salidas
   p_id_opcion_new       OUT NUMBER,
   p_id_acceso_new       OUT NUMBER,
   p_codigo_error        OUT NUMBER,         -- ? 0=OK; <0=negocio; >0=SQLCODE
   p_mensaje_error       OUT VARCHAR2
)
IS
   -- ? Variables de conteo para validaciones de negocio
   v_count_modulo        NUMBER;
   v_count_perfil        NUMBER;
   v_count_padre         NUMBER;
   v_count_desc_dup      NUMBER;
   v_count_enlace_dup    NUMBER;
   -- ? Variables estándar de error
   v_error_code          NUMBER;
   v_error_message       VARCHAR2(4000);
BEGIN
   -- ============================================================
   -- * FASE 0 — Inicialización de salidas
   -- ============================================================
   p_id_opcion_new  := NULL;
   p_id_acceso_new  := NULL;
   p_codigo_error   := 0;
   p_mensaje_error  := NULL;

   -- ============================================================
   -- * FASE 1 — Validaciones de negocio
   -- ============================================================

   -- ? -20010: nivel 2 requiere OPCPADRE no nulo y válido
   IF p_opc_nivel = 2 THEN
      IF p_id_opcion_padre IS NULL THEN
         RAISE_APPLICATION_ERROR(
            -20010,
            'PRC_TSOPCION_ALTA_CON_ACCESO: nivel=2 requiere p_id_opcion_padre no nulo.');
      END IF;

      -- ? Consistencia: padre debe existir, pertenecer al mismo
      -- ? módulo y estar activo/no eliminado
      SELECT COUNT(*)
         INTO v_count_padre
      FROM TSOPCION op
      WHERE op.IDOPCION      = p_id_opcion_padre
        AND op.OPCMODULO     = p_id_modulo
        AND op.OPCESTADO     = 1
        AND op.OPCUSUELIMINA IS NULL;

      IF v_count_padre = 0 THEN
         RAISE_APPLICATION_ERROR(
            -20010,
            'PRC_TSOPCION_ALTA_CON_ACCESO: padre ID=' || p_id_opcion_padre
            || ' no existe, no pertenece al módulo ID=' || p_id_modulo
            || ' o está inactivo/eliminado.');
      END IF;
   END IF;

   -- ? -20011: nivel 1 (raíz) NO debe tener OPCPADRE
   IF p_opc_nivel = 1 AND p_id_opcion_padre IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(
         -20011,
         'PRC_TSOPCION_ALTA_CON_ACCESO: nivel=1 (raíz) no admite p_id_opcion_padre (recibido='
         || p_id_opcion_padre || ').');
   END IF;

   -- ? -20012: módulo debe pertenecer al sistema y estar activo
   SELECT COUNT(*)
      INTO v_count_modulo
   FROM TSMODULO m
   WHERE m.IDMODULO       = p_id_modulo
     AND m.MODSISTEMA     = p_id_sistema
     AND m.MODESTADO      = 1
     AND m.MODUSUELIMINA  IS NULL;

   IF v_count_modulo = 0 THEN
      RAISE_APPLICATION_ERROR(
         -20012,
         'PRC_TSOPCION_ALTA_CON_ACCESO: módulo ID=' || p_id_modulo
         || ' no pertenece al sistema ID=' || p_id_sistema
         || ' o está inactivo/eliminado.');
   END IF;

   -- ? -20013: perfil debe existir y estar activo
   SELECT COUNT(*)
      INTO v_count_perfil
   FROM TSPERFIL p
   WHERE p.IDPERFIL       = p_id_perfil
     AND p.PEFESTADO      = 1
     AND p.PEFUSUELIMINA  IS NULL;

   IF v_count_perfil = 0 THEN
      RAISE_APPLICATION_ERROR(
         -20013,
         'PRC_TSOPCION_ALTA_CON_ACCESO: perfil ID=' || p_id_perfil
         || ' no existe o está inactivo/eliminado.');
   END IF;

   -- ? -20014: no permitir descripción duplicada (módulo+padre+desc)
   -- ? (compara case-insensitive y trimmed)
   SELECT COUNT(*)
      INTO v_count_desc_dup
   FROM TSOPCION o
   WHERE o.OPCMODULO = p_id_modulo
     AND NVL(o.OPCPADRE, -1) = NVL(p_id_opcion_padre, -1)
     AND UPPER(TRIM(o.OPCDESCRIPCION)) = UPPER(TRIM(p_opc_descripcion))
     AND o.OPCUSUELIMINA IS NULL;

   IF v_count_desc_dup > 0 THEN
      RAISE_APPLICATION_ERROR(
         -20014,
         'PRC_TSOPCION_ALTA_CON_ACCESO: ya existe opción con descripción "'
         || p_opc_descripcion || '" bajo el padre ID='
         || NVL(TO_CHAR(p_id_opcion_padre), 'NULL')
         || ' en el módulo ID=' || p_id_modulo || '.');
   END IF;

   -- ? -20015: no permitir enlace duplicado dentro del módulo
   -- ? (solo si se proporcionó un enlace no nulo)
   IF p_opc_enlace IS NOT NULL THEN
      SELECT COUNT(*)
         INTO v_count_enlace_dup
      FROM TSOPCION o
      WHERE o.OPCMODULO = p_id_modulo
        AND UPPER(TRIM(o.OPCENLACE)) = UPPER(TRIM(p_opc_enlace))
        AND o.OPCUSUELIMINA IS NULL;

      IF v_count_enlace_dup > 0 THEN
         RAISE_APPLICATION_ERROR(
            -20015,
            'PRC_TSOPCION_ALTA_CON_ACCESO: el enlace "' || p_opc_enlace
            || '" ya está usado dentro del módulo ID=' || p_id_modulo || '.');
      END IF;
   END IF;

   -- ============================================================
   -- * FASE 2 — INSERT en TSOPCION (ID asignado por trigger)
   -- ============================================================
   INSERT INTO TSOPCION (
      OPCDESCRIPCION, OPCMODULO, OPCENLACE, OPCDESTINO,
      OPCNIVEL, OPTTIPOENLACE, OPCPADRE, OPCORDEN,
      OPCIMAGEN, OPCESTADO, OPCUSUREGISTRA, OPCFECHAREGISTRA,
      OPCUSUACTUALIZA, OPCFECHAACTUALIZA, OPCUSUELIMINA, OPCFECHAELIMINA,
      OPCLIGHTBOX, OPCORDEN2, OPCFLGUSUCAR,
      OPC_FLG_SEPARADOR, OPC_FLG_DESHABILITADO, OPC_MSJ_DESHABILITADO,
      OPC_FLG_USUARIO_PERMISO, OPC_FLG_MENU_ABIERTO_DEFECTO
   ) VALUES (
      p_opc_descripcion, p_id_modulo, p_opc_enlace, p_opc_destino,
      p_opc_nivel, p_opc_tipo_enlace, p_id_opcion_padre, p_opc_orden,
      NULL, p_opc_estado, p_opc_usu_registra, SYSDATE,
      NULL, NULL, NULL, NULL,
      NULL, NULL, 0,
      0, 0, NULL,
      0, 0
   )
   RETURNING IDOPCION INTO p_id_opcion_new;

   -- ============================================================
   -- * FASE 3 — INSERT en TSACCESO (ID asignado por trigger)
   -- ============================================================
   INSERT INTO TSACCESO (
      ACCOPCION, ACCPERFIL, ACCESTADO,
      ACCUSUREGISTRA, ACCFECHAREGISTRA,
      ACCUSUACTUALIZA, ACCFECHAACTUALIZA, ACCUSUELIMINA, ACCFECHAELIMINA
   ) VALUES (
      p_id_opcion_new, p_id_perfil, p_acc_estado,
      p_acc_usu_registra, SYSDATE,
      NULL, NULL, NULL, NULL
   )
   RETURNING IDACCESO INTO p_id_acceso_new;

   -- ============================================================
   -- * FASE 4 — Asignar salidas en caso exitoso
   -- ============================================================
   p_codigo_error  := 0;
   p_mensaje_error := 'OK';

EXCEPTION
   -- ? -20030: violación de índice único
   WHEN DUP_VAL_ON_INDEX THEN
      ROLLBACK;
      p_id_opcion_new  := NULL;
      p_id_acceso_new  := NULL;
      p_codigo_error   := -20030;
      p_mensaje_error  := 'Duplicado (DUP_VAL_ON_INDEX): ' || SQLERRM;
      DBMS_OUTPUT.PUT_LINE('PRC_TSOPCION_ALTA_CON_ACCESO: ' || p_mensaje_error);
      RAISE_APPLICATION_ERROR(-20030, p_mensaje_error);

   -- ? Captura genérica: cualquier otro error Oracle
   WHEN OTHERS THEN
      ROLLBACK;
      v_error_code     := SQLCODE;
      v_error_message  := SQLERRM;
      p_id_opcion_new  := NULL;
      p_id_acceso_new  := NULL;
      p_codigo_error   := v_error_code;
      p_mensaje_error  := v_error_message;
      DBMS_OUTPUT.PUT_LINE(
         'PRC_TSOPCION_ALTA_CON_ACCESO: ERROR [' || v_error_code
         || '] ' || v_error_message);
      RAISE_APPLICATION_ERROR(
         -20997,
         'PRC_TSOPCION_ALTA_CON_ACCESO falló. ROLLBACK aplicado. Error ['
         || v_error_code || ']: ' || v_error_message);
END PRC_TSOPCION_ALTA_CON_ACCESO;
/

-- =============================================================
-- * NOTAS DE USO
-- =============================================================
--
-- ? 1) El procedure NO ejecuta COMMIT. El llamador decide.
--      Si todo es correcto, invocar COMMIT; desde fuera.
--      Si se quiere descartar, invocar ROLLBACK;.
--
-- ? 2) Los IDs (IDOPCION, IDACCESO) los asignan los triggers
--      BEFORE INSERT de TSOPCION y TSACCESO respectivamente.
--      NO se hace referencia a SEQ_*.NEXTVAL en ningún INSERT.
--
-- ? 3) En SQL*Plus / SQL Developer, invocación típica:
--
--      SET SERVEROUTPUT ON
--      VARIABLE v_id_opcion NUMBER
--      VARIABLE v_id_acceso NUMBER
--      VARIABLE v_cod_err   NUMBER
--      VARIABLE v_msg_err   VARCHAR2(4000)
--
--      DECLARE
--         v_id_op_new  NUMBER;
--         v_id_acc_new NUMBER;
--         v_cod_err    NUMBER;
--         v_msg_err    VARCHAR2(4000);
--      BEGIN
--         PRC_TSOPCION_ALTA_CON_ACCESO(
--            p_id_sistema         => 126,        -- SIGEIF
--            p_id_modulo          => 511,
--            p_id_opcion_padre    => 2240,       -- INTERVENCION
--            p_opc_descripcion    => 'Promoción e Incidencia Comunitaria',
--            p_opc_enlace         => 'promocion-incidencia',
--            p_opc_orden          => 4,
--            p_opc_nivel          => 2,
--            p_opc_destino        => 1,
--            p_opc_tipo_enlace    => 1,
--            p_opc_estado         => 1,
--            p_opc_usu_registra   => 1,
--            p_id_perfil          => 221,
--            p_acc_estado         => 1,
--            p_acc_usu_registra   => 1,
--            p_id_opcion_new      => v_id_op_new,
--            p_id_acceso_new      => v_id_acc_new,
--            p_codigo_error       => v_cod_err,
--            p_mensaje_error      => v_msg_err);
--
--         :v_id_opcion := v_id_op_new;
--         :v_id_acceso := v_id_acc_new;
--         :v_cod_err   := v_cod_err;
--         :v_msg_err   := v_msg_err;
--         DBMS_OUTPUT.PUT_LINE('IDOPCION=' || v_id_op_new);
--         DBMS_OUTPUT.PUT_LINE('IDACCESO=' || v_id_acc_new);
--         DBMS_OUTPUT.PUT_LINE('CODERR  =' || v_cod_err);
--         DBMS_OUTPUT.PUT_LINE('MSGERR  =' || v_msg_err);
--      END;
--      /
--
-- ? 4) Desde Java (Spring + SimpleJdbcCall):
--
--      SimpleJdbcCall call = new SimpleJdbcCall(dataSource)
--         .withProcedureName("PRC_TSOPCION_ALTA_CON_ACCESO")
--         .declareParameters(
--            new SqlParameter("p_id_sistema",         Types.NUMERIC),
--            new SqlParameter("p_id_modulo",          Types.NUMERIC),
--            new SqlOutParameter("p_id_opcion_new",    Types.NUMERIC),
--            new SqlOutParameter("p_id_acceso_new",    Types.NUMERIC),
--            new SqlOutParameter("p_codigo_error",     Types.NUMERIC),
--            new SqlOutParameter("p_mensaje_error",    Types.VARCHAR));
--      ...
--
-- ! 5) IMPORTANTE: los triggers BEFORE INSERT de TSOPCION y
--      TSACCESO son los responsables de asignar IDOPCION e
--      IDACCESO. Verificar que existan antes de invocar el SP;
--      de lo contrario, el INSERT fallará con ORA-01400
--      (cannot insert NULL into IDOPCION / IDACCESO).
-- =============================================================


-- =============================================================
-- * Test (READ-ONLY) — ejecutar DESPUÉS de COMMIT del INSERT
-- =============================================================
-- ? Reemplazar :p_id_opcion_new e :p_id_acceso_new por los
-- ? valores devueltos por el procedure (o filtrar por la
-- ? descripción + módulo + padre recién creados).
-- =============================================================

-- * D.1) Confirmar la fila en TSOPCION
SELECT o.IDOPCION, o.OPCDESCRIPCION, o.OPCMODULO, o.OPCPADRE,
       o.OPCENLACE, o.OPCNIVEL, o.OPCORDEN, o.OPCESTADO,
       o.OPCUSUREGISTRA, o.OPCFECHAREGISTRA
FROM TSOPCION o
WHERE o.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
  AND o.OPCMODULO      = 511
  AND o.OPCPADRE       = 2240
  AND o.OPCESTADO      = 1
  AND o.OPCUSUELIMINA IS NULL
ORDER BY o.IDOPCION DESC
/

-- * D.2) Confirmar la fila en TSACCESO
SELECT a.IDACCESO, a.ACCOPCION, a.ACCPERFIL, a.ACCESTADO,
       a.ACCUSUREGISTRA, a.ACCFECHAREGISTRA
FROM TSACCESO a
WHERE a.ACCOPCION = (
      SELECT MAX(o.IDOPCION)
      FROM TSOPCION o
      WHERE o.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
        AND o.OPCMODULO      = 511
        AND o.OPCPADRE       = 2240)
  AND a.ACCPERFIL = 221
ORDER BY a.IDACCESO DESC
/

-- * D.3) JOIN integrado TSOPCION ↔ TSACCESO
SELECT o.IDOPCION, o.OPCDESCRIPCION, o.OPCMODULO, o.OPCPADRE,
       o.OPCENLACE, o.OPCORDEN, o.OPCESTADO,
       a.IDACCESO, a.ACCPERFIL, a.ACCESTADO
FROM TSOPCION o
JOIN TSACCESO a ON a.ACCOPCION = o.IDOPCION
WHERE o.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
  AND o.OPCMODULO      = 511
  AND o.OPCPADRE       = 2240
  AND a.ACCPERFIL      = 221
ORDER BY o.IDOPCION DESC
/

-- * D.4) Verificar NO hay duplicados
-- * 4.1) Duplicados en TSOPCION (tripleta módulo+padre+descripción)
SELECT m.OPCMODULO, m.OPCPADRE, m.OPCDESCRIPCION, COUNT(*) AS VECES
FROM TSOPCION m
WHERE m.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
  AND m.OPCMODULO      = 511
  AND m.OPCPADRE       = 2240
  AND m.OPCUSUELIMINA IS NULL
GROUP BY m.OPCMODULO, m.OPCPADRE, m.OPCDESCRIPCION
HAVING COUNT(*) > 1
/

-- * 4.2) Duplicados en TSACCESO (dupla ACCOPCION+ACCPERFIL)
SELECT d.ACCOPCION, d.ACCPERFIL, COUNT(*) AS VECES
FROM TSACCESO d
WHERE d.ACCOPCION IN (
      SELECT o.IDOPCION
      FROM TSOPCION o
      WHERE o.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
        AND o.OPCMODULO      = 511
        AND o.OPCPADRE       = 2240)
  AND d.ACCPERFIL = 221
GROUP BY d.ACCOPCION, d.ACCPERFIL
HAVING COUNT(*) > 1
/

-- * D.5) Resumen ejecutivo (cuenta por tipo)
SELECT 'OPCION'  AS TIPO, COUNT(*) AS TOTAL
FROM TSOPCION o
WHERE o.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
  AND o.OPCMODULO      = 511
  AND o.OPCPADRE       = 2240
  AND o.OPCUSUELIMINA IS NULL
UNION ALL
SELECT 'ACCESOS' AS TIPO, COUNT(*) AS TOTAL
FROM TSACCESO a
WHERE a.ACCOPCION IN (
      SELECT o.IDOPCION
      FROM TSOPCION o
      WHERE o.OPCDESCRIPCION = 'Promoción e Incidencia Comunitaria'
        AND o.OPCMODULO      = 511
        AND o.OPCPADRE       = 2240)
  AND a.ACCPERFIL = 221
/
