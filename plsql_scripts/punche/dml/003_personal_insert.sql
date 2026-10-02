-- ============================================================
-- Script: 003_personal_insert.sql
-- Propósito: DML INSERTs en TGPERSONA y TRPERSONAL
--            desde TRPERSONAL.xlsx (Acompañantes Familiares)
-- Fuente : plsql_scripts/punche/inputs/TRPERSONAL.xlsx
-- Fecha  : 2026-07-26
-- Autor  : SIGEIF
-- ============================================================
-- Notas:
--   - PERDOCUMENTO = 347 (tipo de documento, consistente con test.sql)
--   - PERSEXO: 1=MASCULINO, 2=FEMENINO
--   - PERESTADOCIVIL: 1=Soltero(a), 365=Casado(a)
--   - PRHCARGO = 5509 = 'ACOMPAÑANTE FAMILIAR'
--   - PRHPROFESION: NULL (ID de Psicología no disponible en seed,
--                    requiere consulta TG_CARRERA_PROFESIONAL)
--   - PRHCONTRATO: NULL (ID de 'Orden de servicio' no disponible en
--                   seed, requiere consulta TGCATALOGO)
--   - PRH_ULTIMA_ORDEN: truncado a ≤10 chars (columna VARCHAR2(10))
--   - IDs de persona/personal: correlativos proporcionados por el usuario
--   - COMMIT comentado: descomentar al ejecutar
--
-- ADVERTENCIAS PREVIAS A LA EJECUCIÓN:
--   1. Ejecutar las queries de pre-validación (sección 3) antes del DML
--   2. Verificar que los IDCATALOGO existen y están activos
--   3. Verificar que los IDs de persona/personal no colisionan
--   4. Ajustar PRHPROFESION y PRHCONTRATO según catálogos de la BD
-- ============================================================

-- ============================================================
-- 1. INSERTS EN TGPERSONA (datos personales)
-- ============================================================

INSERT INTO TGPERSONA (
   IDPERSONA,
   PERDOCUMENTO,
   PERNRODOCUMENTO,
   PERAPEPATERNO,
   PERAPEMATERNO,
   PERNOMBRE,
   PERESTADOCIVIL,
   PERFECNACIMIENTO,
   PERSEXO,
   PERTELEFONO,
   PERCORREO,
   PERDIRECCION,
   PERDIRUBIGEO,
   PERESTADO,
   PERUSUREGISTRA,
   PERFECHAREGISTRA
) VALUES (
   122636,
   347,
   '45506350',
   'YAURIVILCA',
   'TORPOCO',
   'GABRIELA XIOMARA',
   365,
   TO_DATE('19/12/1988', 'DD/MM/YYYY'),
   2,
   '953261236',
   'xiomara.yt.psicologa@gmail.com',
   'Celle Monjas 248, Santa Felicia',
   '150114',
   1,
   1,
   SYSDATE
)
/

INSERT INTO TGPERSONA (
   IDPERSONA,
   PERDOCUMENTO,
   PERNRODOCUMENTO,
   PERAPEPATERNO,
   PERAPEMATERNO,
   PERNOMBRE,
   PERESTADOCIVIL,
   PERFECNACIMIENTO,
   PERSEXO,
   PERTELEFONO,
   PERCORREO,
   PERDIRECCION,
   PERDIRUBIGEO,
   PERESTADO,
   PERUSUREGISTRA,
   PERFECHAREGISTRA
) VALUES (
   122637,
   347,
   '72503907',
   'QUISPE',
   'MANRIQUE',
   'MARTHA INES',
   365,
   TO_DATE('26/05/1994', 'DD/MM/YYYY'),
   2,
   '962318455',
   'marthaquispe526@gmail.com',
   'Av. Lurigancho 1068',
   '150132',
   1,
   1,
   SYSDATE
)
/

INSERT INTO TGPERSONA (
   IDPERSONA,
   PERDOCUMENTO,
   PERNRODOCUMENTO,
   PERAPEPATERNO,
   PERAPEMATERNO,
   PERNOMBRE,
   PERESTADOCIVIL,
   PERFECNACIMIENTO,
   PERSEXO,
   PERTELEFONO,
   PERCORREO,
   PERDIRECCION,
   PERDIRUBIGEO,
   PERESTADO,
   PERUSUREGISTRA,
   PERFECHAREGISTRA
) VALUES (
   122638,
   347,
   '70311301',
   'SAAVEDRA',
   'REVATTA',
   'KATHERINE CRISTELL',
   1,
   TO_DATE('23/03/1995', 'DD/MM/YYYY'),
   2,
   '992690623',
   'revattakatherine@gmail.com',
   'Jr. Las Grosellas 1912 - Urb. San Hilarion',
   '150132',
   1,
   1,
   SYSDATE
)
/

INSERT INTO TGPERSONA (
   IDPERSONA,
   PERDOCUMENTO,
   PERNRODOCUMENTO,
   PERAPEPATERNO,
   PERAPEMATERNO,
   PERNOMBRE,
   PERESTADOCIVIL,
   PERFECNACIMIENTO,
   PERSEXO,
   PERTELEFONO,
   PERCORREO,
   PERDIRECCION,
   PERDIRUBIGEO,
   PERESTADO,
   PERUSUREGISTRA,
   PERFECHAREGISTRA
) VALUES (
   122639,
   347,
   '77202920',
   'CIRINEO',
   'BALLESTEROS',
   'ARLETH RAQUEL',
   1,
   TO_DATE('18/01/1997', 'DD/MM/YYYY'),
   2,
   '958367195',
   'raquel.ballesteros.psicologia@gmail.com',
   'Calle Ricardo Bentin',
   '170101',
   1,
   1,
   SYSDATE
)
/

INSERT INTO TGPERSONA (
   IDPERSONA,
   PERDOCUMENTO,
   PERNRODOCUMENTO,
   PERAPEPATERNO,
   PERAPEMATERNO,
   PERNOMBRE,
   PERESTADOCIVIL,
   PERFECNACIMIENTO,
   PERSEXO,
   PERTELEFONO,
   PERCORREO,
   PERDIRECCION,
   PERDIRUBIGEO,
   PERESTADO,
   PERUSUREGISTRA,
   PERFECHAREGISTRA
) VALUES (
   122640,
   347,
   '42886524',
   'YUCA',
   'MASIAS',
   'NOHEMY',
   365,
   TO_DATE('31/01/1985', 'DD/MM/YYYY'),
   2,
   '973050016',
   'nohemyyucamasias@gmail.com',
   'Av. dos de mayo 712',
   '170101',
   1,
   1,
   SYSDATE
)
/

INSERT INTO TGPERSONA (
   IDPERSONA,
   PERDOCUMENTO,
   PERNRODOCUMENTO,
   PERAPEPATERNO,
   PERAPEMATERNO,
   PERNOMBRE,
   PERESTADOCIVIL,
   PERFECNACIMIENTO,
   PERSEXO,
   PERTELEFONO,
   PERCORREO,
   PERDIRECCION,
   PERDIRUBIGEO,
   PERESTADO,
   PERUSUREGISTRA,
   PERFECHAREGISTRA
) VALUES (
   123467,
   347,
   '43475601',
   'RUIZ',
   'ORBE',
   'AZUCENA DEL PILAR',
   365,
   TO_DATE('31/01/1985', 'DD/MM/YYYY'),
   2,
   '966295317',
   'azucenaruizorbe@gmail.com',
   'Calle Arequipa 202 – Huacho',
   '170101',
   1,
   1,
   SYSDATE
)
/

-- AZUCENA DEL PILAR RUIZ ORBE  DNI : 43475601 TELEFONO: 966295317 CORREO: azucenaruizorbe@gmail.com Dirección : Calle Arequipa 202 – Huacho

-- ============================================================
-- 2. INSERTS EN TRPERSONAL (datos laborales)
--    PRHPERSONA referencia al IDPERSONA insertado arriba
-- ============================================================

INSERT INTO TRPERSONAL (
   IDPERSONAL,
   PRHPERSONA,
   PRHCARGO,
   PRHESTADO,
   PRHUSUREGISTRA,
   PRHFECREGISTRA,
   PRH_TELEFONO,
   PRHCORREOINSTITUCIONAL,
   PRH_ULTIMA_ORDEN
) VALUES (
   22773,
   123467,
   5509,
   1,
   1,
   SYSDATE,
   '966295317',
   NULL,
   '3010-2026'
)
/

INSERT INTO TRPERSONAL (
   IDPERSONAL,
   PRHPERSONA,
   PRHCARGO,
   PRHESTADO,
   PRHUSUREGISTRA,
   PRHFECREGISTRA,
   PRH_TELEFONO,
   PRHCORREOINSTITUCIONAL,
   PRH_ULTIMA_ORDEN
) VALUES (
   22554,
   122636,
   5509,
   1,
   1,
   SYSDATE,
   '953261236',
   NULL,
   '3010-2026'
)
/

INSERT INTO TRPERSONAL (
   IDPERSONAL,
   PRHPERSONA,
   PRHCARGO,
   PRHESTADO,
   PRHUSUREGISTRA,
   PRHFECREGISTRA,
   PRH_TELEFONO,
   PRHCORREOINSTITUCIONAL,
   PRH_ULTIMA_ORDEN
) VALUES (
   22555,
   122637,
   5509,
   1,
   1,
   SYSDATE,
   '962318455',
   NULL,
   '1812-2026'
)
/

INSERT INTO TRPERSONAL (
   IDPERSONAL,
   PRHPERSONA,
   PRHCARGO,
   PRHESTADO,
   PRHUSUREGISTRA,
   PRHFECREGISTRA,
   PRH_TELEFONO,
   PRHCORREOINSTITUCIONAL,
   PRH_ULTIMA_ORDEN
) VALUES (
   22556,
   122638,
   5509,
   1,
   1,
   SYSDATE,
   '992690623',
   NULL,
   '3018-2026'
)
/

INSERT INTO TRPERSONAL (
   IDPERSONAL,
   PRHPERSONA,
   PRHCARGO,
   PRHESTADO,
   PRHUSUREGISTRA,
   PRHFECREGISTRA,
   PRH_TELEFONO,
   PRHCORREOINSTITUCIONAL,
   PRH_ULTIMA_ORDEN
) VALUES (
   22557,
   122639,
   5509,
   1,
   1,
   SYSDATE,
   '958367195',
   NULL,
   '03126-2026'
)
/

INSERT INTO TRPERSONAL (
   IDPERSONAL,
   PRHPERSONA,
   PRHCARGO,
   PRHESTADO,
   PRHUSUREGISTRA,
   PRHFECREGISTRA,
   PRH_TELEFONO,
   PRHCORREOINSTITUCIONAL,
   PRH_ULTIMA_ORDEN
) VALUES (
   22558,
   122640,
   5509,
   1,
   1,
   SYSDATE,
   '973050016',
   NULL,
   '03120-2026'
)
/

-- ============================================================
-- 3. PRE-VALIDACION (ejecutar ANTES del DML para verificar integridad)
-- ============================================================

-- 3.1 Verificar que los IDs de catálogo existen y están activos
SELECT 'PERDOCUMENTO=347'  AS catalogo, c.CATDESCRIPCION
  FROM TGCATALOGO c
 WHERE c.IDCATALOGO = 347 AND c.CATESTADO = 1
UNION ALL
SELECT 'PERESTADOCIVIL=1', c.CATDESCRIPCION
  FROM TGCATALOGO c
 WHERE c.IDCATALOGO = 1 AND c.CATESTADO = 1
UNION ALL
SELECT 'PERESTADOCIVIL=365', c.CATDESCRIPCION
  FROM TGCATALOGO c
 WHERE c.IDCATALOGO = 365 AND c.CATESTADO = 1
UNION ALL
SELECT 'PRHCARGO=5509', c.CATDESCRIPCION
  FROM TGCATALOGO c
 WHERE c.IDCATALOGO = 5509 AND c.CATESTADO = 1
/
-- Si alguna fila retorna NULL en CATDESCRIPCION, corregir antes del INSERT

-- 3.2 Verificar que los ubigeos existen
SELECT u.ID_UBIGEO, u.UBI_LOCALIDAD
  FROM TG_UBIGEO u
 WHERE u.ID_UBIGEO IN ('150114', '150132', '170101')
   AND u.UBI_ESTADO = '1'
/
-- Deben retornar 3 filas. Si falta alguna, insertar en TG_UBIGEO primero

-- 3.3 Detectar colisiones de IDs (debe retornar 0 filas)
SELECT 'TGPERSONA' AS tabla, IDPERSONA
  FROM TGPERSONA
 WHERE IDPERSONA BETWEEN 122636 AND 122640
UNION ALL
SELECT 'TRPERSONAL', IDPERSONAL
  FROM TRPERSONAL
 WHERE IDPERSONAL BETWEEN 22554 AND 22558
UNION ALL
SELECT 'TRPERSONAL(FK)', PRHPERSONA
  FROM TRPERSONAL
 WHERE PRHPERSONA BETWEEN 122636 AND 122640
/

-- 3.4 Verificar el resultado post-INSERT (descomentar tras ejecutar DML)
/*
SELECT p.IDPERSONA,
       p.PERNRODOCUMENTO AS DNI,
       p.PERAPEPATERNO || ' ' || p.PERAPEMATERNO || ', ' || p.PERNOMBRE
          AS NOMBRE_COMPLETO,
       pe.IDPERSONAL,
       c.CATDESCRIPCION AS CARGO,
       pe.PRH_ULTIMA_ORDEN AS ORDEN_SERVICIO
  FROM TGPERSONA p
  JOIN TRPERSONAL pe ON pe.PRHPERSONA = p.IDPERSONA
  LEFT JOIN TGCATALOGO c ON c.IDCATALOGO = pe.PRHCARGO
 WHERE p.IDPERSONA BETWEEN 122636 AND 122640
 ORDER BY p.IDPERSONA
/
*/

-- COMMIT;   -- <-- Descomentar para confirmar los cambios

SELECT * FROM MP_USUARIO u
WHERE
   u.USU_NOMBRE = 'villegas.pug@gmail.com'
/

UPDATE MP_USUARIO u
   SET u.USU_CONTRASENIA = '$2a$10$wN9iLd4E/8bK1j.J2hYmmeWnC7uFk8wY5j3pX8z9v0q1w2e3r4t5y'
WHERE
   u.USU_NOMBRE = 'villegas.pug@gmail.com'
/

-- TRPERSONAL
-- TSUSUARIO
-- ? ROLLBACK;
-- ! COMMIT;