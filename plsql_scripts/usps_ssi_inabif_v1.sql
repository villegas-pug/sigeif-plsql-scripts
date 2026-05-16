-- Active: 1776982575153@@@443@XE@USRSEGURIDAD
/*
*  ░  1. Catalogos
* ============================================================================================================================== */


-- 1.1 Definir el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_LISTAR_CATALOGO_POR_GRUPOS
(
   p_catgrupo NUMBER,
   p_catsubgrupo NUMBER,
   c_resultado_busqueda OUT SYS_REFCURSOR
) 
AS
BEGIN

   IF(p_catgrupo IS NOT NULL AND p_catsubgrupo IS NOT NULL) THEN -- Filtro por grupo y subgrupo
      BEGIN
         OPEN c_resultado_busqueda FOR
            SELECT 
               c.IDCATALOGO,
               c.CATGRUPO AS GRUPO,
               c.CATSUBGRUPO AS SUBGRUPO,
               c.CATDESCRIPCION,
               c.CATABREVIATURA
            FROM TGCATALOGO c
            WHERE 
               c.CATGRUPO = p_catgrupo 
               AND c.CATSUBGRUPO = p_catsubgrupo
               AND c.CATTIPO > 0;
      END;
   ELSIF (p_catgrupo IS NOT NULL AND p_catsubgrupo IS NULL) THEN -- Filtro por grupo
      BEGIN
         OPEN c_resultado_busqueda FOR
            SELECT 
               c.IDCATALOGO,
               c.CATGRUPO AS GRUPO,
               c.CATSUBGRUPO AS SUBGRUPO,
               c.CATDESCRIPCION,
               c.CATABREVIATURA
            FROM TGCATALOGO c
            WHERE 
               c.CATGRUPO = p_catgrupo 
               AND c.CATSUBGRUPO > 0
               AND c.CATTIPO = 0;
      END;
   END IF;

END;
/


-- 1.2 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_LISTAR_CATALOGO_POR_GRUPOS(105, NULL, c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

SELECT * FROM SSI_FAMILIA_INTEGRANTES i
WHERE i.FI_ID_INTEGRANTE = 127
/


-- ==============================================================================================================================


/*
*  ░  2. Equipos de trabajo
* ============================================================================================================================== */

-- 2.2 Crea un procedimiento almacenado para listar al personal por nombres:
CREATE OR REPLACE PROCEDURE USP_LISTAR_PERSONAL_POR_DOCUMENTO
(
   p_numero_documento IN VARCHAR2,
   c_resultado_busqueda OUT SYS_REFCURSOR
)
IS
BEGIN

   OPEN c_resultado_busqueda FOR
      SELECT 
         p.IDPERSONA,
         u.IDPERSONAL,
         p.PERNOMBRE AS NOMBRES,
         p.PERAPEPATERNO AS PRIMERAPE,
         p.PERAPEMATERNO AS SEGUNDOAPE,
         c2.CATDESCRIPCION AS DOCUMENTO,
         p.PERNRODOCUMENTO AS NUMERODOC,
         pa.PA_NACIONALIDAD AS NACIONALIDAD,
         c.CATDESCRIPCION AS ESTADOCIVIL,
         p.PERFECNACIMIENTO AS FECNACIMIENTO,
         CASE
            WHEN p.PERSEXO = 1 THEN 'MASCULINO'
            WHEN p.PERSEXO = 2 THEN 'FEMENINO'
            ELSE 'NO DEFINIDO'
         END AS SEXO,
         p.PERDIRECCION AS DIRECCION,
         p.PERREFERENCIA AS REFERENCIA,
         p.PERTELEFONO AS TELEFONO,
         p.PERCORREO AS CORREO,
         ca.CP_NOMBRE AS CARRERA
      FROM TGPERSONA p
      JOIN TGCATALOGO c ON p.PERESTADOCIVIL = c.IDCATALOGO -- ESTADO CIVIL
      JOIN TGCATALOGO c2 ON p.PERDOCUMENTO = c2.IDCATALOGO -- TIPO DOCUMENTO
      JOIN TRPERSONAL u ON p.IDPERSONA = u.PRHPERSONA
      LEFT JOIN TG_CARRERA_PROFESIONAL ca ON u.PRHPROFESION = ca.IDCARRERA_PROFESIONAL
      LEFT JOIN TG_PAIS pa ON p.PERNACPAIS = pa.IDPAIS
      WHERE
         p.PERNRODOCUMENTO = p_numero_documento;

END;
/

-- 2.3 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_LISTAR_PERSONAL_POR_DOCUMENTO('46392613', c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- ==============================================================================================================================



/*
*  ░  3. Buscar Departamento, Provincia y Distrito
* ============================================================================================================================== */

-- 3.1 Crea un procedimiento almacenado para buscar la divicion territorial por ubigeo:
CREATE OR REPLACE PROCEDURE USP_BUSCAR_DIVICION_TERRITORIAL_POR_UBIGEO
(
  p_ubigeo IN VARCHAR2,
  c_resultado_busqueda OUT SYS_REFCURSOR
)
AS
   id_dep VARCHAR(2) := SUBSTR(p_ubigeo,1,2);
   id_prov VARCHAR(2) := SUBSTR(p_ubigeo,3,2);
   id_dist VARCHAR(2) := SUBSTR(p_ubigeo,5,2);

   o_id_dep CHAR(2);
   o_departamento VARCHAR2(100);
   o_id_prov CHAR(2);
   o_provincia VARCHAR2(100);
   o_id_dist CHAR(2);
   o_distrito VARCHAR2(100);
BEGIN

   BEGIN

      SELECT u.UBIDEPARTAMENTO, u.UBILOCALIDAD INTO o_id_dep, o_departamento FROM TGUBIGEO u WHERE u.UBIDEPARTAMENTO = id_dep AND u.UBIPROVINCIA = '00' AND u.UBIDISTRITO = '00';
      SELECT u.UBIPROVINCIA, u.UBILOCALIDAD INTO o_id_prov, o_provincia FROM TGUBIGEO u WHERE u.UBIDEPARTAMENTO = id_dep AND u.UBIPROVINCIA = id_prov AND u.UBIDISTRITO = '00';
      SELECT u.UBIDISTRITO, u.UBILOCALIDAD INTO o_id_dist, o_distrito FROM TGUBIGEO u WHERE u.UBIDEPARTAMENTO = id_dep AND u.UBIPROVINCIA = id_prov AND u.UBIDISTRITO = id_dist;

      OPEN c_resultado_busqueda FOR
         SELECT 
            o_id_dep AS IDDEPARTAMENTO,
            o_departamento AS DEPARTAMENTO,
            o_id_prov AS IDPROVINCIA,
            o_provincia AS PROVINCIA,
            o_id_dist AS IDDISTRITO,
            o_distrito AS DISTRITO
         FROM DUAL;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         OPEN c_resultado_busqueda FOR
            SELECT '-' AS IDDEPARTAMENTO, '-' AS DEPARTAMENTO, '-' AS IDPROVINCIA, '-' AS PROVINCIA, '-' AS IDDISTRITO, '-' AS DISTRITO
            FROM DUAL;
   END;

END;
/

-- 3.2 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_DIVICION_TERRITORIAL_POR_UBIGEO('010302', c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- ==============================================================================================================================



/*
*  ░  4. Buscar el Centro de referencia
* ============================================================================================================================== */

-- 4.1 Crea un procedimiento almacenado para buscar el Centro de Referencia por parametros:
CREATE OR REPLACE PROCEDURE USP_BUSCAR_CENTRO_REFERENCIA_POR_PARAMETROS
(
   p_tipo IN NUMBER,
   p_centro_ref IN VARCHAR2,
   c_resultado_busqueda OUT SYS_REFCURSOR
)
AS
BEGIN
   IF (p_tipo = 1) THEN -- CEDIF

      OPEN c_resultado_busqueda FOR
         SELECT

            o.IDUNIDADORGANICA AS IDCENTROREFERENCIA,
            o.UORNOMBRE AS NOMBRE,
            o.UORDIRECCION AS DIRECCION,
            u1.UBILOCALIDAD AS DEPERTAMENTO,
            u2.UBILOCALIDAD AS PROVINCIA,
            u3.UBILOCALIDAD AS DISTRITO

         FROM TGUNIDADORGANICA o
         JOIN TGUBIGEO u1 ON SUBSTR(o.UOR_UBIGEO, 1, 2) = u1.UBIDEPARTAMENTO 
                        AND SUBSTR(o.UOR_UBIGEO, 3, 2) = '00' 
                        AND SUBSTR(o.UOR_UBIGEO, 5, 2) = '00'
         JOIN TGUBIGEO u2 ON SUBSTR(o.UOR_UBIGEO, 1, 2) = u2.UBIDEPARTAMENTO 
                        AND SUBSTR(o.UOR_UBIGEO, 3, 2) = u2.UBIDISTRITO
                        AND SUBSTR(o.UOR_UBIGEO, 5, 2) = '00'
         JOIN TGUBIGEO u3 ON SUBSTR(o.UOR_UBIGEO, 1, 2) = u3.UBIDEPARTAMENTO 
                        AND SUBSTR(o.UOR_UBIGEO, 3, 2) = u3.UBIDISTRITO
                        AND SUBSTR(o.UOR_UBIGEO, 5, 2) = u3.UBIPROVINCIA
         WHERE
            o.UORESTADO = 1
            AND o.UORNOMBRE LIKE '%' || p_centro_ref || '%';

   ELSIF (p_tipo = 2) THEN -- OTROS
      
      OPEN c_resultado_busqueda FOR
         SELECT

            i.INSUBIGEO,
            i.IDINSTITUCION AS IDCENTROREFERENCIA,
            i.INSNOMBRE AS NOMBRE
            /* i.INSDIRECCION AS DIRECCION,
            u1.UBILOCALIDAD AS DEPERTAMENTO,
            u2.UBILOCALIDAD AS PROVINCIA,
            u3.UBILOCALIDAD AS DISTRITO */

         FROM TGINSTITUCION i
         LEFT JOIN TGUBIGEO u1 ON SUBSTR(i.INSUBIGEO, 1, 2) = u1.UBIDEPARTAMENTO -- Departamento
                               AND u1.UBIPROVINCIA = '00'
                               AND u1.UBIDISTRITO = '00'
         LEFT JOIN TGUBIGEO u2 ON SUBSTR(i.INSUBIGEO, 1, 2) = u2.UBIDEPARTAMENTO -- Provincia
                               AND SUBSTR(i.INSUBIGEO, 3, 2) = u2.UBIPROVINCIA
                               AND u2.UBIDISTRITO = '00'
         LEFT JOIN TGUBIGEO u3 ON SUBSTR(i.INSUBIGEO, 1, 2) = u3.UBIDEPARTAMENTO -- Distrito
                               AND SUBSTR(i.INSUBIGEO, 3, 2) = u3.UBIPROVINCIA
                               AND SUBSTR(i.INSUBIGEO, 5, 2) = u3.UBIDISTRITO
         WHERE
            -- i.INSESTADO = 1
            -- AND i.INSNOMBRE LIKE '%' || 'U' || '%'
            i.INSUBIGEO IS NOT NULL;

   END IF;

END;
/

-- 4.2 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_CENTRO_REFERENCIA(1, 'CED', c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- ==============================================================================================================================


/*
*  ░  5. Buscar provincias por departamento
* ============================================================================================================================== */

-- 4.1 Crea un procedimiento almacenado para buscar el Centro de Referencia por parametros:
CREATE OR REPLACE PROCEDURE USP_BUSCAR_PROVINCIA_POR_DEPARTAMENTO
(
   p_ubigeo_dep IN VARCHAR2,
   c_resultado_busqueda OUT SYS_REFCURSOR
)
AS
   id_dep VARCHAR(2) := SUBSTR(p_ubigeo_dep, 1, 2);
BEGIN

      OPEN c_resultado_busqueda FOR
         SELECT
            u.IDUBIGEO,
            u.UBIPROVINCIA AS IDPROVINCIA,
            u.UBILOCALIDAD AS NOMBRE
         FROM TGUBIGEO u
         WHERE
            u.UBIESTADO = 1
            AND u.UBIDEPARTAMENTO = id_dep
            AND u.UBIPROVINCIA != '00'
            AND u.UBIDISTRITO = '00';

END;
/

-- 4.2 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_PROVINCIA_POR_DEPARTAMENTO('040000', c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/


/*
*  ░  6. Buscar distritos por provincia
* ============================================================================================================================== */

-- 4.1 Crea un procedimiento para buscar un distrito por provincia:
CREATE OR REPLACE PROCEDURE USP_BUSCAR_DISTRITO_POR_PROVINCIA
(
   p_ubigeo_prov IN VARCHAR2,
   c_resultado_busqueda OUT SYS_REFCURSOR
)
AS
   id_dep VARCHAR(2) := SUBSTR(p_ubigeo_prov, 1, 2);
   id_prov VARCHAR(2) := SUBSTR(p_ubigeo_prov, 3, 2);
BEGIN

      OPEN c_resultado_busqueda FOR
         SELECT
            u.IDUBIGEO,
            u.UBIDISTRITO AS IDDISTRITO,
            u.UBILOCALIDAD AS NOMBRE
         FROM TGUBIGEO u
         WHERE
            u.UBIESTADO = 1
            AND u.UBIDEPARTAMENTO = id_dep
            AND u.UBIPROVINCIA = id_prov
            AND u.UBIDISTRITO != '00';

END;
/

-- 6.2 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_DISTRITO_POR_PROVINCIA('150101', c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- ==============================================================================================================================


/*
*  ░  7. Listar departamentos
* ============================================================================================================================== */

-- 4.1 Crea un procedimiento para buscar un distrito por provincia:
CREATE OR REPLACE PROCEDURE USP_LISTAR_DEPARTAMENTOS
(
   c_resultado_busqueda OUT SYS_REFCURSOR
)
AS
BEGIN

      OPEN c_resultado_busqueda FOR
         SELECT
            u.IDUBIGEO,
            u.UBIDEPARTAMENTO AS IDDEPARTAMENTO,
            u.UBILOCALIDAD AS NOMBRE
         FROM TGUBIGEO u
         WHERE
            u.UBIESTADO = 1
            AND u.UBIPROVINCIA = '00'
            AND u.UBIDISTRITO = '00';

END;
/

-- 7.2 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_LISTAR_DEPARTAMENTOS(c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- ==============================================================================================================================


/*
*     ░  8. Guarda Centro de Referencia
* ============================================================================================================================== */

-- 8.1 Crear tipo objeto
CREATE OR REPLACE TYPE O_CENTRO_REFERENCIA AS OBJECT
(
   NOMBRE VARCHAR2(350),
   RUC VARCHAR2(11) NULL,
   REPRESENTANTE VARCHAR2(350) NULL,
   DIRECCION VARCHAR2(350) NULL,
   REFERENCIA VARCHAR2(500) NULL,
   TELEFONO VARCHAR2(25) NULL,
   CORREO VARCHAR2(70) NULL,
   USER_REGISTRA NUMBER NULL,
   UBIGEO VARCHAR2(6) NULL,
   CONTACTO VARCHAR2(200) NULL
);
/

-- 8.2 Crear procedimiento
CREATE OR REPLACE PROCEDURE USP_GUARDAR_CENTRO_REFERENCIA
(
   p_tipo_ref IN NUMBER, -- 1 = CEDIF, 2 = Institución
   p_centro_ref IN O_CENTRO_REFERENCIA
)
IS
   id_centro_ref NUMBER;
BEGIN

   BEGIN

      -- Validar tipo de referencia
      IF p_tipo_ref NOT IN (1, 2) THEN
         RAISE_APPLICATION_ERROR(-20001, 'Tipo de Centro de Referencia inválido. Valores permitidos: 1 (CEDIF), 2 (Institución)');
      END IF;

      SAVEPOINT GUARDAR_CENTRO_REFERENCIA;

      IF(p_tipo_ref = 1) THEN -- CEDIF

         -- calcula `Id`
         SELECT NVL(MAX(IDUNIDADORGANICA), 0) + 1  INTO id_centro_ref FROM TGUNIDADORGANICA;

         INSERT INTO TGUNIDADORGANICA
         (
            IDUNIDADORGANICA,
            UORNOMBRE,
            UORTELEFONO,
            UORDIRECCION,
            UOR_REFERENCIA,
            UOR_CORREO_ELECTRONICO,
            UORUSUREGISTRA,
            UORUSUELIMINA,
            UOR_UBIGEO,
            UORESTADO,
            UORELIMINADO,
            UORFECREGISTRA
         ) VALUES (
            id_centro_ref,
            p_centro_ref.NOMBRE,
            p_centro_ref.TELEFONO,
            p_centro_ref.DIRECCION,
            p_centro_ref.REFERENCIA,
            p_centro_ref.CORREO,
            p_centro_ref.USER_REGISTRA,
            0,
            p_centro_ref.UBIGEO,
            1,
            0,
            SYSDATE
         );

      ELSIF(p_tipo_ref = 2) THEN -- Institución

         -- calcula `Id`
         SELECT NVL(MAX(IDINSTITUCION), 0) + 1  INTO id_centro_ref FROM TGINSTITUCION;

         INSERT INTO TGINSTITUCION
         (
            IDINSTITUCION,
            INSNOMBRE,
            INSRUC,
            INSREPRESENTANTE,
            INSTELEFONO1,
            INSDIRECCION,
            INSREFERENCIA,
            INSCORREO,
            INSUSUREGISTRA,
            INSUBIGEO,
            INSESTADO,
            INSELIMINADO,
            INSFECREGISTRA,
            INSCLASIFICACION,
            INSCATEGORIA,
            INSPAIS,
            INSCONTACTO
         ) VALUES (
            id_centro_ref,
            p_centro_ref.NOMBRE,
            p_centro_ref.RUC,
            p_centro_ref.REPRESENTANTE,
            p_centro_ref.TELEFONO,
            p_centro_ref.DIRECCION,
            p_centro_ref.REFERENCIA,
            p_centro_ref.CORREO,
            p_centro_ref.USER_REGISTRA,
            p_centro_ref.UBIGEO,
            1,
            0,
            SYSDATE,
            1,
            1,
            1,
            p_centro_ref.CONTACTO
         );

      END IF;

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT GUARDAR_CENTRO_REFERENCIA;
         DBMS_OUTPUT.PUT_LINE('Error al guardar el Centro de Referencia: ' || SQLERRM);
         RAISE;
   END;

END USP_GUARDAR_CENTRO_REFERENCIA;
/

-- 8.3 Llamar al procedimiento almacenado:
DECLARE
   p_centro_ref O_CENTRO_REFERENCIA;
BEGIN
   p_centro_ref := O_CENTRO_REFERENCIA(
      'Centro de Referencia 1',
      'Calle 1',
      'Referencia 1',
      '123456',
      'l4t6o@example.com',
      1,
      '010101'
   );

   USP_GUARDAR_CENTRO_REFERENCIA(2, p_centro_ref);
END;
/

-- ==============================================================================================================================


/*
*     ░  9. Guarda Zona Intervencion
* ============================================================================================================================== */

-- 9.1 Crea objeto para guardar Zona de Intervencion
-- DROP TYPE O_ZONA_INTERVENCION;
-- COMMIT;

CREATE OR REPLACE TYPE O_ZONA_INTERVENCION AS OBJECT
(
   IDINSTITUCION NUMBER,
   IDUNIDADORG NUMBER,
   IDSERVICIO NUMBER,
   IDUBIGEO CHAR(6),
   CODTIPO NUMBER(1),
   DESCRIPCION VARCHAR2(350),
   USUREGISTRA NUMBER
);

CREATE OR REPLACE TYPE O_EQUIPO_TRABAJO AS OBJECT
(
   IDPERSONAL NUMBER,
   IDPROFESION NUMBER,
   USUREGISTRA NUMBER
);

CREATE OR REPLACE TYPE T_EQUIPOS_TRABAJO AS TABLE OF O_EQUIPO_TRABAJO;

CREATE OR REPLACE TYPE O_CONTACTO AS OBJECT
(
   IDTIPDOC NUMBER,
   IDNACIONALIDAD NUMBER,
   NUMERO_DOC VARCHAR2(15),
   NOMBRES VARCHAR2(350),
   PRIMER_APE VARCHAR2(350),
   SEGUNDO_APE VARCHAR2(350),
   CORREO VARCHAR2(255),
   TELEFONO VARCHAR2(50),
   DIRECCION VARCHAR2(250),
   USUREGISTRA NUMBER
);

COMMIT;

CREATE OR REPLACE TYPE T_CONTACTOS AS TABLE OF O_CONTACTO;

CREATE OR REPLACE TYPE O_ALIADO AS OBJECT
(
   IDINSTITUCION NUMBER,
   IDGRUPOSOCIAL NUMBER,
   GRADOINFLUENCIA NUMBER(1),
   INTERESSERVICIO NUMBER(1),
   RESULTADO NUMBER(2),
   POSICION VARCHAR2(50),

   -- * Nuevo
   IDUBIGEO CHAR(6),
   TIPOALIADO VARCHAR2(55),
   DIRECCION VARCHAR2(500),
   TELEFONO VARCHAR2(55),
   CORREO VARCHAR2(150),
   REPRESENTANTE VARCHAR2(200),

   USUREGISTRA NUMBER,
   CONTACTOS T_CONTACTOS
);

-- DROP TYPE T_ALIADOS;
CREATE OR REPLACE TYPE T_ALIADOS AS TABLE OF O_ALIADO;

-- ! COMMIT;

-- 9.2 Crea el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_GUARDAR_ZONA_INTERVENCION
(
   p_zona_intervencion IN O_ZONA_INTERVENCION,
   p_equipos_trabajo IN T_EQUIPOS_TRABAJO,
   p_aliados IN T_ALIADOS
)
IS
   id_zona_intervencion NUMBER;
   id_equipo_trabajo NUMBER;
   id_aliado NUMBER;
BEGIN
   BEGIN
      SAVEPOINT GUARDAR_ZONA_INTERVENCION;

      -- Inicializar secuencia
      -- id_zona_intervencion := SEQ_ZONA_INTERVENCION.NEXTVAL;

      -- 1. Guardar Zona de Intervencion
      INSERT INTO SSI_ZONA_INTERVENCION (
         INS_ID_INSTITUCION,
         UOR_ID_UNIDADORG,
         SI_ID_SERVICIO,
         UBI_ID_UBIGEO,
         ZO_COD_TIPO,
         ZO_DESCRIPCION,
         ZO_USU_REGISTRA
      )
      VALUES
      (
         p_zona_intervencion.IDINSTITUCION,
         p_zona_intervencion.IDUNIDADORG,
         p_zona_intervencion.IDSERVICIO,
         p_zona_intervencion.IDUBIGEO,
         p_zona_intervencion.CODTIPO,
         p_zona_intervencion.DESCRIPCION,
         p_zona_intervencion.USUREGISTRA
      ) RETURNING ZO_ID_ZONA INTO id_zona_intervencion;

      -- 2. Guardar Equipos de Trabajo
      FOR i IN p_equipos_trabajo.FIRST..p_equipos_trabajo.LAST LOOP
         INSERT INTO SSI_EQUIPO_TRABAJO (
            ZO_ID_ZONA,
            PER_ID_PERSONAL,
            PR_ID_PROFESION,
            EQ_USU_REGISTRA
         )
         VALUES
         (
            id_zona_intervencion,
            p_equipos_trabajo(i).IDPERSONAL,
            p_equipos_trabajo(i).IDPROFESION,
            p_equipos_trabajo(i).USUREGISTRA
         );
      END LOOP;

      -- 3. Aliados
      -- 3.1 Guardar Aliados
      FOR i IN p_aliados.FIRST..p_aliados.LAST LOOP
         INSERT INTO SSI_ALIADOS (
            ZO_ID_ZONA,
            INS_ID_INSTITUCION,
            GR_ID_GRUPO_SOCIAL,
            AL_GRADO_INFLUENCIA,
            AL_INTERES_SERVICIO,
            AL_RESULTADO,
            AL_POSICION,

            UBI_ID_UBIGEO,
            AL_TIPO_ALIADO,
            AL_DIRECCION,
            AL_TELEFONO,
            AL_CORREO,
            AL_REPRESENTANTE,
            AL_USU_REGISTRA
         )
         VALUES
         (
            id_zona_intervencion,
            p_aliados(i).IDINSTITUCION,
            p_aliados(i).IDGRUPOSOCIAL,
            p_aliados(i).GRADOINFLUENCIA,
            p_aliados(i).INTERESSERVICIO,
            p_aliados(i).RESULTADO,
            p_aliados(i).POSICION,
            -- * Nuevo
            p_aliados(i).IDUBIGEO,
            p_aliados(i).TIPOALIADO,
            p_aliados(i).DIRECCION,
            p_aliados(i).TELEFONO,
            p_aliados(i).CORREO,
            p_aliados(i).REPRESENTANTE,
            p_aliados(i).USUREGISTRA

         ) RETURNING AL_ID_ALIADO INTO id_aliado;

         -- 3.2 Guardar Contactos
         FOR j IN 1..p_aliados(i).CONTACTOS.COUNT LOOP

            INSERT INTO SSI_CONTACTO(
               AL_ID_ALIADO,
               ID_TIPDOC,
               PA_ID_NACIONALIDAD,
               CO_NUMERO_DOC,
               CO_NOMBRES,
               CO_PRIMER_APE,
               CO_SEGUNDO_APE,
               CO_TELEFONO,
               CO_DIRECCION,
               CO_CORREO,
               CO_USU_REGISTRA
            )
            VALUES
            (
               id_aliado,
               p_aliados(i).CONTACTOS(j).IDTIPDOC,
               p_aliados(i).CONTACTOS(j).IDNACIONALIDAD,
               p_aliados(i).CONTACTOS(j).NUMERO_DOC,
               p_aliados(i).CONTACTOS(j).NOMBRES,
               p_aliados(i).CONTACTOS(j).PRIMER_APE,
               p_aliados(i).CONTACTOS(j).SEGUNDO_APE,
               p_aliados(i).CONTACTOS(j).TELEFONO,
               p_aliados(i).CONTACTOS(j).DIRECCION,
               p_aliados(i).CONTACTOS(j).CORREO,
               p_aliados(i).CONTACTOS(j).USUREGISTRA
            );

         END LOOP;
      END LOOP;
      

      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT GUARDAR_ZONA_INTERVENCION;
         DBMS_OUTPUT.PUT_LINE('Error al guardar la Zona de Intervencion: ' || SQLERRM);
         RAISE;
   END;

END USP_GUARDAR_ZONA_INTERVENCION;
/

-- ! COMMIT;

-- 9.3 Llamar al procedimiento almacenado
DECLARE
   zona_intervencion O_ZONA_INTERVENCION;
   equipos_trabajo T_EQUIPOS_TRABAJO;
   aliados T_ALIADOS;
BEGIN
   zona_intervencion := O_ZONA_INTERVENCION(1, NULL, 2, '010101', 1, 'Zona de Intervencion 1', 1);
   equipos_trabajo := T_EQUIPOS_TRABAJO(
      O_EQUIPO_TRABAJO(1, 1, 1),
      O_EQUIPO_TRABAJO(2, 2, 1),
      O_EQUIPO_TRABAJO(3, 3, 1)
   );
   aliados := T_ALIADOS(
      O_ALIADO(
         1, 1, 1, 1, 5, 'Posicion 1', 1,
         T_CONTACTOS()
      ),
      O_ALIADO(
         1, 1, 1, 1, 5, 'Posicion 1', 1,
         T_CONTACTOS(
            O_CONTACTO(1, 1, '12345678', 'Nombres 1', 'Apellido 1', 'Apellido 2', 'test@test.com', '123456789', 'Direccion 1', 1)
         )
      )
   );
   USP_GUARDAR_ZONA_INTERVENCION(zona_intervencion, equipos_trabajo, aliados);
END;
/

COMMIT;
-- ==============================================================================================================================


/*
*     ░  10. Buscar Zona Intervencion por descripcion
* ============================================================================================================================== */

-- 10.1 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_BUSCAR_ZONA_INTERVENCION_POR_DESCRIPCION(
   p_descripcion IN VARCHAR2 DEFAULT '',
   p_id_servicio IN NUMBER,
   p_resultado_busqueda OUT SYS_REFCURSOR
)  
AS
BEGIN

   OPEN p_resultado_busqueda FOR
      SELECT
         z.ZO_ID_ZONA AS IDZONA,
         z.ZO_FEC_REGISTRA AS FECHAREGISTRA,
         z.ZO_DESCRIPCION AS DESCRIPCION,
         z.SI_ID_SERVICIO AS IDSERVICIO,
         z.UBI_ID_UBIGEO AS IDUBIGEO,
         u1.UBIDEPARTAMENTO AS IDDEPARTAMENTO,
         u1.UBILOCALIDAD AS DEPARTAMENTO,
         u2.UBIPROVINCIA AS IDPROVINCIA,
         u2.UBILOCALIDAD AS PROVINCIA,
         u3.UBIDISTRITO AS IDDISTRITO,
         u3.UBILOCALIDAD AS DISTRITO,
         -- pf.PF_ID_FAMILIA AS IDFAMILIA,
         z.ZO_ESTADO AS ESTADO,
         z.ZO_ELIMINADO AS ELIMINADO
      FROM SSI_ZONA_INTERVENCION z
      LEFT JOIN TGUBIGEO u1 ON u1.UBIDEPARTAMENTO = SUBSTR(z.UBI_ID_UBIGEO, 1, 2)
                            AND u1.UBIPROVINCIA = '00'
                            AND u1.UBIDISTRITO = '00'
      LEFT JOIN TGUBIGEO u2 ON u2.UBIDEPARTAMENTO = SUBSTR(z.UBI_ID_UBIGEO, 1, 2)
                            AND u2.UBIPROVINCIA = SUBSTR(z.UBI_ID_UBIGEO, 3, 2)
                            AND u2.UBIDISTRITO = '00'
      LEFT JOIN TGUBIGEO u3 ON u3.UBIDEPARTAMENTO = SUBSTR(z.UBI_ID_UBIGEO, 1, 2)
                            AND u3.UBIPROVINCIA = SUBSTR(z.UBI_ID_UBIGEO, 3, 2)
                            AND u3.UBIDISTRITO = SUBSTR(z.UBI_ID_UBIGEO, 5, 2)
      WHERE
         z.ZO_ESTADO = 1
         AND z.ZO_ELIMINADO = 0
         AND z.SI_ID_SERVICIO = p_id_servicio
         AND LOWER(z.ZO_DESCRIPCION) LIKE '%' || LOWER(p_descripcion) || '%'
         -- AND (EXTRACT(YEAR FROM z.ZO_FEC_REGISTRA) = p_anio OR p_anio IS NULL)
         -- AND (EXTRACT(MONTH FROM z.ZO_FEC_REGISTRA) = p_mes OR p_mes = -1 OR p_mes IS NULL)
      ORDER BY z.ZO_ID_ZONA DESC;

END;
/

-- 10.2 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_ZONA_INTERVENCION_POR_DESCRIPCION('aa', 2, c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- COMMIT;
SELECT EXTRACT(MONTH FROM SYSDATE) AS ANIO FROM DUAL;
SELECT TO_CHAR(SYSDATE, 'MM') AS ANIO FROM DUAL;
-- ==============================================================================================================================


/*
*     ░  11. Guardar potencial familia: 11.2.1 CEDIF | 11.2.2 PUCHE
* ============================================================================================================================== */

-- * V1

-- 11.1 Crea tipo objetos u arrays asociativos

-- O_FAMILIA_MOTIVO_REFERENCIA
CREATE OR REPLACE TYPE O_FAMILIA_MOTIVO_REFERENCIA AS OBJECT (
   IDMOTIVO NUMBER
)
/

-- T_FAMILIA_MOTIVOS_REFERENCIA
CREATE OR REPLACE TYPE T_FAMILIA_MOTIVOS_REFERENCIA AS TABLE OF O_FAMILIA_MOTIVO_REFERENCIA
/

-- COMMIT;
-- O_FAMILIA_INTEGRANTE
-- ! DROP TYPE O_FAMILIA_INTEGRANTE;
CREATE OR REPLACE TYPE O_FAMILIA_INTEGRANTE AS OBJECT (
   IDTIPDOC NUMBER,-- (FK)
   IDGRADOINST NUMBER,-- (FK)
   IDTIPOSEGURO NUMBER,-- (FK)
   IDNAC NUMBER,-- (FK)
   IDPAISNACIMIENTO NUMBER,-- (FK)
   IDPARENTESCO NUMBER,-- (FK)
   IDESTADOCIVIL NUMBER,-- (FK)
   IDSEXO NUMBER,-- (FK)
   IDIDIOMA NUMBER,
   IDDISCAPACIDAD NUMBER,
   IDDERIVADOPOR NUMBER,
   IDSERVICIOCUIDADOR NUMBER,
   IDCENTROPOBLA NUMBER,
   IDOCUPACION NUMBER,
   NUMERODOC VARCHAR2(50),
   NOMBRES VARCHAR2(250),
   PRIMERAPE VARCHAR2(250),
   SEGUNDOAPE VARCHAR2(250),
   APELLIDOCASADO VARCHAR2(250),
   FECNAC DATE,
   EDAD NUMBER,
   TELEFONO VARCHAR2(50),
   CORREO VARCHAR2(250),
   IDDEPARTAMENTO CHAR(2),-- (FK)
   IDPROVINCIA CHAR(2),-- (FK)
   IDDISTRITO CHAR(2),-- (FK)
   DIRECCION VARCHAR2(250),
   REFERENCIADOMICILIARIA VARCHAR2(450),
   GRADOSECCIONNNA VARCHAR2(25),
   ANIOANTERIORPROMOVIDO NUMBER(1),
   NOMBREINSTITUCIONEDUCATIVA VARCHAR2(250),
   PESO VARCHAR(25),
   TALLA VARCHAR(25),
   INGRESOSSOLES NUMBER(10, 2),
   GASTOSSOLES NUMBER(10, 2),
   IDDEPARTAMENTONAC CHAR(2),
   IDPROVINCIANAC CHAR(2),
   IDDISTRITONAC CHAR(2),
   OBSERVACIONES VARCHAR2(1000),
   DIAGNOSTICOMEDICO VARCHAR2(600),
   ESTABLECIMIENTOSALUD VARCHAR(250),

   PORCOSTUMBRESSECONSIDERA VARCHAR2(200),
   SITUACIONLABORAL VARCHAR2(200),
   TIENECERTMEDICO VARCHAR2(200),
   GRADODISCAPACIDAD VARCHAR2(200),
   PERFILINGRESONNA VARCHAR2(200),
   TIPOEDUCACION VARCHAR2(200),
   VICTIMAINDIRECTAFEMINICIDIO VARCHAR2(200),
   GESTANTE VARCHAR2(200),
   LACTANTE VARCHAR2(200),
   INSCRIPCIONCONADIS VARCHAR2(200),
   GRADOINSTRUCCION VARCHAR2(200),
   TIPODISCAPACIDAD VARCHAR2(200),
   TIENEDISCAPACIDAD NUMBER,
   
   -- * Nuevo
   ALGUNINTEGRANTETIENEPROBLEMASALUD NUMBER(1),
   VIAINGRESONNACEDIF VARCHAR2(200),
   MEDIOINGRESONNACEDIF VARCHAR2(200),
   OCUPACION VARCHAR2(200),

   CUIDADOR NUMBER,
   USUREGISTRA NUMBER
)
/

-- T_FAMILIA_INTEGRANTES
-- ! DROP TYPE T_FAMILIA_INTEGRANTES;
CREATE OR REPLACE TYPE T_FAMILIA_INTEGRANTES AS TABLE OF O_FAMILIA_INTEGRANTE
/

-- O_POTENCIAL_FAMILIA
-- ! DROP TYPE O_POTENCIAL_FAMILIA
CREATE OR REPLACE TYPE O_POTENCIAL_FAMILIA AS OBJECT
(
   CODFAMILIA VARCHAR2(50),
   IDZONA NUMBER, -- Para Punche
   IDALIADO NUMBER, -- Para Punche
   IDUNIDADORGANICA NUMBER, -- Para Cedif
   IDSERVICIO NUMBER,
   OBSERVACIONES VARCHAR2(500), -- Para Punche
   USUREGISTRA NUMBER,
   FECREGISTRA DATE,
   MOTIVOSREF T_FAMILIA_MOTIVOS_REFERENCIA,
   INTEGRANTES T_FAMILIA_INTEGRANTES
)
/

-- ! COMMIT;

-- O_ANEXO_RESPUESTA
CREATE OR REPLACE TYPE O_ANEXO_RESPUESTA AS OBJECT
(
   IDPREGUNTA NUMBER,
   RESPUESTA VARCHAR2(4000),
   OBSERVACION VARCHAR2(4000),
   IDPERSONAL NUMBER,
   USUREGISTRA NUMBER
)
/

-- ! DROP TYPE T_ANEXO_RESPUESTAS;
CREATE OR REPLACE TYPE T_ANEXO_RESPUESTAS AS TABLE OF O_ANEXO_RESPUESTA
/

-- ! COMMIT;

-- 11.2 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_GUARDAR_POTENCIAL_FAMILIA
(
   p_servicio IN NUMBER, -- 1 ↔ CEDIF | 2 ↔ PUNCHE
   p_potencial_familia IN O_POTENCIAL_FAMILIA,
   p_fichas_respuestas IN T_ANEXO_RESPUESTAS DEFAULT NULL -- Opcional: Si servicio es CEDIF, recibe fichas de respuestas
)
IS
   id_familia NUMBER;
   id_integrante NUMBER;
   cod_familia VARCHAR2(50);
BEGIN 

   BEGIN
      
      SAVEPOINT SP_GUARDAR_POTENCIAL_FAMILIA;

      -- * 1. Guardar potencial familia
      INSERT INTO SSI_POTENCIALES_FAMILIAS(
         PF_COD_FAMILIA,
         ZO_ID_ZONA, -- Para Punche
         AL_ID_ALIADO, -- Para Punche
         UO_ID_UNIDADORGANICA, -- Para Cedif
         SI_ID_SERVICIO,
         PF_OBSERVACIONES,
         PF_USU_REGISTRA,
         PF_FEC_REGISTRA
      ) VALUES (
         p_potencial_familia.CODFAMILIA,
         p_potencial_familia.IDZONA,
         p_potencial_familia.IDALIADO,
         p_potencial_familia.IDUNIDADORGANICA,
         p_potencial_familia.IDSERVICIO,
         p_potencial_familia.OBSERVACIONES,
         p_potencial_familia.USUREGISTRA,
         p_potencial_familia.FECREGISTRA
      )
      RETURNING PF_ID_FAMILIA INTO id_familia;

      -- * 2. Guardar motivos de referencia
      FOR i IN 1..p_potencial_familia.MOTIVOSREF.COUNT LOOP
         INSERT INTO SSI_FAMILIA_MOTIVO_REFERENCIA(PF_ID_FAMILIA, MR_ID_MOTIVO, FMR_ESTADO) VALUES (
            id_familia,
            p_potencial_familia.MOTIVOSREF(i).IDMOTIVO,
            1
         );
      END LOOP;

      -- * 3. Guardar integrantes familia
      FOR i IN 1..p_potencial_familia.INTEGRANTES.COUNT LOOP

         INSERT INTO SSI_FAMILIA_INTEGRANTES(
            PF_ID_FAMILIA,
            CA_ID_TIPDOC,
            CA_ID_GRADO_INST,
            CA_ID_TIPO_SEGURO,
            PA_ID_NAC,
            PA_ID_PAIS_NACIMIENTO,
            CA_ID_PARENTESCO,
            CA_ID_ESTADO_CIVIL,
            CA_ID_SEXO,
            CA_ID_IDIOMA,
            CA_ID_DISCAPACIDAD,
            CA_ID_DERIVADO_POR,
            CA_ID_SERVICIO_CUIDADOR,
            CP_ID_CENTRO_POBLA,
            CA_ID_OCUPACION,
            FI_NUMERO_DOC,
            FI_NOMBRES,
            FI_PRIMER_APE,
            FI_SEGUNDO_APE,
            FI_APELLIDO_CASADO,
            FI_FEC_NAC,
            FI_EDAD,
            FI_TELEFONO,
            FI_CORREO,
            UBI_ID_UBIGEO,
            UBI_ID_DEPARTAMENTO,
            UBI_ID_PROVINCIA,
            UBI_ID_DISTRITO,
            FI_DIRECCION,
            FI_REFERENCIA_DOMICILIARIA,
            FI_GRADO_SECCION_NNA,
            FI_ANIO_ANTERIOR_PROMOVIDO,
            FI_NOMBRE_INSTITUCION_EDUCATIVA,
            FI_PESO,
            FI_TALLA,
            FI_INGRESOS_SOLES,
            FI_GASTOS_SOLES,
            UBI_ID_UBIGEO_NAC,
            UBI_ID_DEPARTAMENTO_NAC,
            UBI_ID_PROVINCIA_NAC,
            UBI_ID_DISTRITO_NAC,
            FI_OBSERVACIONES,
            FI_DIAGNOSTICO_MEDICO,
            FI_ESTABLECIMIENTO_SALUD,
            FI_POR_COSTUMBRES_SE_CONSIDERA,
            FI_SITUACION_LABORAL,
            FI_TIENE_CERT_MEDICO,
            FI_GRADO_DISCAPACIDAD,
            FI_PERFIL_INGRESO_NNA,
            FI_TIPO_EDUCACION,
            FI_VICTIMA_INDIRECTA_FEMINICIDIO,
            FI_GESTANTE,
            FI_LACTANTE,
            FI_INSCRIPCION_CONADIS,
            FI_GRADO_INSTRUCCION,
            FI_TIPO_DISCAPACIDAD,
            CA_TIENE_DISCAPACIDAD,

            -- * Nuevo
            FI_ALGUN_INTEGRANTE_TIENE_PROBLEMA_SALUD,
            FI_VIA_INGRESO_NNA_CEDIF,
            FI_MEDIO_INGRESO_NNA_CEDIF,
            FI_OCUPACION,

            FI_CUIDADOR,
            FI_USU_REGISTRA
         ) VALUES (
            id_familia,
            p_potencial_familia.INTEGRANTES(i).IDTIPDOC,
            p_potencial_familia.INTEGRANTES(i).IDGRADOINST,
            p_potencial_familia.INTEGRANTES(i).IDTIPOSEGURO,
            p_potencial_familia.INTEGRANTES(i).IDNAC,
            p_potencial_familia.INTEGRANTES(i).IDPAISNACIMIENTO,
            p_potencial_familia.INTEGRANTES(i).IDPARENTESCO,
            p_potencial_familia.INTEGRANTES(i).IDESTADOCIVIL,
            p_potencial_familia.INTEGRANTES(i).IDSEXO,
            p_potencial_familia.INTEGRANTES(i).IDIDIOMA,
            p_potencial_familia.INTEGRANTES(i).IDDISCAPACIDAD,
            p_potencial_familia.INTEGRANTES(i).IDDERIVADOPOR,
            p_potencial_familia.INTEGRANTES(i).IDSERVICIOCUIDADOR,
            p_potencial_familia.INTEGRANTES(i).IDCENTROPOBLA,
            p_potencial_familia.INTEGRANTES(i).IDOCUPACION,
            p_potencial_familia.INTEGRANTES(i).NUMERODOC,
            p_potencial_familia.INTEGRANTES(i).NOMBRES,
            p_potencial_familia.INTEGRANTES(i).PRIMERAPE,
            p_potencial_familia.INTEGRANTES(i).SEGUNDOAPE,
            p_potencial_familia.INTEGRANTES(i).APELLIDOCASADO,
            p_potencial_familia.INTEGRANTES(i).FECNAC,
            p_potencial_familia.INTEGRANTES(i).EDAD,
            p_potencial_familia.INTEGRANTES(i).TELEFONO,
            p_potencial_familia.INTEGRANTES(i).CORREO,
            (p_potencial_familia.INTEGRANTES(i).IDDEPARTAMENTO || p_potencial_familia.INTEGRANTES(i).IDPROVINCIA || p_potencial_familia.INTEGRANTES(i).IDDISTRITO), -- UBI_ID_UBIGEO
            p_potencial_familia.INTEGRANTES(i).IDDEPARTAMENTO,
            p_potencial_familia.INTEGRANTES(i).IDPROVINCIA,
            p_potencial_familia.INTEGRANTES(i).IDDISTRITO,
            p_potencial_familia.INTEGRANTES(i).DIRECCION,
            p_potencial_familia.INTEGRANTES(i).REFERENCIADOMICILIARIA,
            p_potencial_familia.INTEGRANTES(i).GRADOSECCIONNNA,
            p_potencial_familia.INTEGRANTES(i).ANIOANTERIORPROMOVIDO,
            p_potencial_familia.INTEGRANTES(i).NOMBREINSTITUCIONEDUCATIVA,
            p_potencial_familia.INTEGRANTES(i).PESO,
            p_potencial_familia.INTEGRANTES(i).TALLA,
            p_potencial_familia.INTEGRANTES(i).INGRESOSSOLES,
            p_potencial_familia.INTEGRANTES(i).GASTOSSOLES,
            (p_potencial_familia.INTEGRANTES(i).IDDEPARTAMENTONAC || p_potencial_familia.INTEGRANTES(i).IDPROVINCIANAC || p_potencial_familia.INTEGRANTES(i).IDDISTRITONAC), -- UBI_ID_UBIGEO_NAC
            p_potencial_familia.INTEGRANTES(i).IDDEPARTAMENTONAC,
            p_potencial_familia.INTEGRANTES(i).IDPROVINCIANAC,
            p_potencial_familia.INTEGRANTES(i).IDDISTRITONAC,
            p_potencial_familia.INTEGRANTES(i).OBSERVACIONES,
            p_potencial_familia.INTEGRANTES(i).DIAGNOSTICOMEDICO,
            p_potencial_familia.INTEGRANTES(i).ESTABLECIMIENTOSALUD,
            p_potencial_familia.INTEGRANTES(i).PORCOSTUMBRESSECONSIDERA,
            p_potencial_familia.INTEGRANTES(i).SITUACIONLABORAL,
            p_potencial_familia.INTEGRANTES(i).TIENECERTMEDICO,
            p_potencial_familia.INTEGRANTES(i).GRADODISCAPACIDAD,
            p_potencial_familia.INTEGRANTES(i).PERFILINGRESONNA,
            p_potencial_familia.INTEGRANTES(i).TIPOEDUCACION,
            p_potencial_familia.INTEGRANTES(i).VICTIMAINDIRECTAFEMINICIDIO,
            p_potencial_familia.INTEGRANTES(i).GESTANTE,
            p_potencial_familia.INTEGRANTES(i).LACTANTE,
            p_potencial_familia.INTEGRANTES(i).INSCRIPCIONCONADIS,
            p_potencial_familia.INTEGRANTES(i).GRADOINSTRUCCION,
            p_potencial_familia.INTEGRANTES(i).TIPODISCAPACIDAD,
            p_potencial_familia.INTEGRANTES(i).TIENEDISCAPACIDAD,

            -- * Nuevo
            p_potencial_familia.INTEGRANTES(i).ALGUNINTEGRANTETIENEPROBLEMASALUD,
            p_potencial_familia.INTEGRANTES(i).VIAINGRESONNACEDIF,
            p_potencial_familia.INTEGRANTES(i).MEDIOINGRESONNACEDIF,
            p_potencial_familia.INTEGRANTES(i).OCUPACION,

            p_potencial_familia.INTEGRANTES(i).CUIDADOR,
            p_potencial_familia.INTEGRANTES(i).USUREGISTRA
         )
         RETURNING FI_ID_INTEGRANTE INTO id_integrante;

         -- * Genera código de integrante
         USP_GENERAR_CODIGO_FAMILIA(p_servicio, NULL, id_integrante, cod_familia);

      END LOOP;

      -- 4. Guardar respuestas
      IF p_servicio = 1 THEN -- CEDIF

         FOR i IN 1..p_fichas_respuestas.COUNT LOOP
            INSERT INTO SSI_ANEXOS_RESPUESTAS(
               PF_ID_FAMILIA,
               AP_ID_PREGUNTA,
               AR_RESPUESTA,
               AR_OBSERVACION,
               PR_ID_PERSONAL,
               AR_USU_REGISTRA
            ) VALUES (
               id_familia,
               p_fichas_respuestas(i).IDPREGUNTA,
               p_fichas_respuestas(i).RESPUESTA,
               p_fichas_respuestas(i).OBSERVACION,
               p_fichas_respuestas(i).IDPERSONAL,
               p_fichas_respuestas(i).USUREGISTRA
            );
         END LOOP;
         
      END IF;

      -- * 5. Genera código de familia
      USP_GENERAR_CODIGO_FAMILIA(p_servicio, id_familia, NULL, cod_familia);
         
      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT SP_GUARDAR_POTENCIAL_FAMILIA;
         DBMS_OUTPUT.PUT_LINE('Error al guardar la Potencial Familia: ' || SQLERRM);
         RAISE;
   END;

END;
/

-- ! COMMIT;

-- 11.3 Llamar al procedimiento almacenado:
-- SELECT * FROM TGUNIDADORGANICA;
BEGIN
   USP_GUARDAR_POTENCIAL_FAMILIA(
      1, -- CEDIF
      -- 2, -- PUNCHE
      O_POTENCIAL_FAMILIA(
         'TMP0001-0001', 205, 197, 4, 1, '', 1, SYSDATE,
         T_FAMILIA_MOTIVOS_REFERENCIA(
            O_FAMILIA_MOTIVO_REFERENCIA(1),
            O_FAMILIA_MOTIVO_REFERENCIA(2)
         ),
         T_FAMILIA_INTEGRANTES(
            O_FAMILIA_INTEGRANTE(
               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
               '46392613',
               'NOMBRES',
               'PRIMERAPE',
               'SEGUNDOAPE',
               'APELLIDOCASADO',
               SYSDATE,
               15,
               'TELEFONO',
               'CORREO',
               '01',
               '01',
               '01',
               'DIRECCION',
               'REFERENCIADOMICILIARIA',
               'GRADOSECCIONNNA',
               1,
               'NOMBREINSTITUCIONEDUCATIVA',
               'PESO',
               'TALLA',
               22.5,
               60.5,
               1,
               1
            )
         )
      ),
      T_ANEXO_RESPUESTAS(
         O_ANEXO_RESPUESTA(1, 'RESPUESTA 1', 'OBSERVACION 1', 1),
         O_ANEXO_RESPUESTA(2, 'RESPUESTA 2', 'OBSERVACION 2', 1)
      )
   );
END;
/

-- * v2 
-- 11.4.1 Crea tipo objetos u arrays asociativos
-- O_FAMILIA_MOTIVO_REFERENCIA
CREATE OR REPLACE TYPE O_FAMILIA_MOTIVO_REFERENCIA_V2 AS OBJECT (
   IDMOTIVO NUMBER
)
/

-- T_FAMILIA_MOTIVOS_REFERENCIA
CREATE OR REPLACE TYPE T_FAMILIA_MOTIVOS_REFERENCIA_V2 AS TABLE OF O_FAMILIA_MOTIVO_REFERENCIA_V2
/

-- ! DROP TYPE T_FAMILIA_INTEGRANTES;
CREATE OR REPLACE TYPE O_FAMILIA_INTEGRANTE_V2 AS OBJECT (

   IDINTEGRANTE NUMBER,

   IDTIPDOC NUMBER,-- (FK)
   IDGRADOINST NUMBER,-- (FK)
   IDTIPOSEGURO NUMBER,-- (FK)
   IDNAC NUMBER,-- (FK)
   IDPAISNACIMIENTO NUMBER,-- (FK)
   IDPARENTESCO NUMBER,-- (FK)
   IDESTADOCIVIL NUMBER,-- (FK)
   IDSEXO NUMBER,-- (FK)
   IDIDIOMA NUMBER,
   IDDISCAPACIDAD NUMBER,
   IDDERIVADOPOR NUMBER,
   IDSERVICIOCUIDADOR NUMBER,
   IDCENTROPOBLA NUMBER,
   IDOCUPACION NUMBER,
   NUMERODOC VARCHAR2(50),
   NOMBRES VARCHAR2(250),
   PRIMERAPE VARCHAR2(250),
   SEGUNDOAPE VARCHAR2(250),
   APELLIDOCASADO VARCHAR2(250),
   FECNAC DATE,
   TELEFONO VARCHAR2(50),
   CORREO VARCHAR2(250),
   IDDEPARTAMENTO CHAR(2),-- (FK)
   IDPROVINCIA CHAR(2),-- (FK)
   IDDISTRITO CHAR(2),-- (FK)
   DIRECCION VARCHAR2(250),
   REFERENCIADOMICILIARIA VARCHAR2(450),
   GRADOSECCIONNNA VARCHAR2(25),

   -- * Nuevo
   CENTROPOBLADO VARCHAR2(500),

   CUIDADOR NUMBER,
   USUREGISTRA NUMBER
)
/

-- T_FAMILIA_INTEGRANTES
-- ! DROP TYPE T_FAMILIA_INTEGRANTES_V2;
CREATE OR REPLACE TYPE T_FAMILIA_INTEGRANTES_V2 AS TABLE OF O_FAMILIA_INTEGRANTE_V2
/

-- O_POTENCIAL_FAMILIA
-- ! DROP TYPE O_POTENCIAL_FAMILIA_V2
CREATE OR REPLACE TYPE O_POTENCIAL_FAMILIA_V2 AS OBJECT
(
   IDFAMILIA NUMBER,
   CODFAMILIA VARCHAR2(50),
   IDZONA NUMBER, -- Para Punche
   IDALIADO NUMBER, -- Para Punche
   IDUNIDADORGANICA NUMBER, -- Para Cedif
   IDSERVICIO NUMBER,
   OBSERVACIONES VARCHAR2(500), -- Para Punche
   USUREGISTRA NUMBER,
   FECREGISTRA DATE,
   MOTIVOSREF T_FAMILIA_MOTIVOS_REFERENCIA_V2,
   INTEGRANTES T_FAMILIA_INTEGRANTES_V2
)
/

-- ! COMMIT;

-- O_ANEXO_RESPUESTA
CREATE OR REPLACE TYPE O_ANEXO_RESPUESTA_V2 AS OBJECT
(
   IDRESPUESTA NUMBER,
   IDPREGUNTA NUMBER,
   RESPUESTA VARCHAR2(4000),
   OBSERVACION VARCHAR2(4000),
   USUREGISTRA NUMBER
)
/

CREATE OR REPLACE TYPE T_ANEXO_RESPUESTAS_V2 AS TABLE OF O_ANEXO_RESPUESTA_V2
/

-- ! COMMIT;

-- 11.2 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_GUARDAR_POTENCIAL_FAMILIA_V2
(
   -- p_servicio IN NUMBER, -- * 1 ↔ CEDIF | 2 ↔ PUNCHE
   p_potencial_familia IN O_POTENCIAL_FAMILIA_V2,
   p_fichas_respuestas IN T_ANEXO_RESPUESTAS_V2 DEFAULT NULL -- Opcional: Si servicio es CEDIF, recibe fichas de respuestas
)
IS
   id_familia NUMBER;
   id_integrante NUMBER;
   id_respuesta NUMBER;
   cod_familia VARCHAR2(50);
BEGIN 

   BEGIN
      
      SAVEPOINT SP_GUARDAR_POTENCIAL_FAMILIA;

      -- * 1. Guardar potencial familia

      -- * 1.2 Evalua si la familia ya existe
      BEGIN
         SELECT 
            p.PF_ID_FAMILIA 
            INTO id_familia 
         FROM SSI_POTENCIALES_FAMILIAS p 
         WHERE p.PF_ID_FAMILIA = p_potencial_familia.IDFAMILIA;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            id_familia := NULL;
      END;


      IF id_familia IS NULL THEN -- * Nueva potencial familia
         BEGIN
            INSERT INTO SSI_POTENCIALES_FAMILIAS(
               PF_COD_FAMILIA,
               ZO_ID_ZONA, -- Para Punche
               AL_ID_ALIADO, -- Para Punche
               UO_ID_UNIDADORGANICA, -- Para Cedif
               SI_ID_SERVICIO,
               PF_OBSERVACIONES,
               PF_USU_REGISTRA,
               PF_FEC_REGISTRA
            ) VALUES (
               p_potencial_familia.CODFAMILIA,
               p_potencial_familia.IDZONA,
               p_potencial_familia.IDALIADO,
               p_potencial_familia.IDUNIDADORGANICA,
               p_potencial_familia.IDSERVICIO,
               p_potencial_familia.OBSERVACIONES,
               p_potencial_familia.USUREGISTRA,
               p_potencial_familia.FECREGISTRA
            )
            RETURNING PF_ID_FAMILIA INTO id_familia;

            -- * Genera código de familia
            USP_GENERAR_CODIGO_FAMILIA(p_potencial_familia.IDSERVICIO, id_familia, NULL, cod_familia);

         END;
      ELSE -- * Actualizar potencial familia
         BEGIN
            UPDATE SSI_POTENCIALES_FAMILIAS
               SET 
                  PF_COD_FAMILIA = p_potencial_familia.CODFAMILIA,
                  ZO_ID_ZONA = p_potencial_familia.IDZONA, -- Para Punche
                  AL_ID_ALIADO = p_potencial_familia.IDALIADO, -- Para Punche
                  UO_ID_UNIDADORGANICA = p_potencial_familia.IDUNIDADORGANICA, -- Para Cedif
                  SI_ID_SERVICIO = p_potencial_familia.IDSERVICIO,
                  PF_OBSERVACIONES = p_potencial_familia.OBSERVACIONES,
                  PF_USU_ACTUALIZA = p_potencial_familia.USUREGISTRA, -- Crea y actualiza
                  PF_FEC_ACTUALIZA = SYSDATE
            
            WHERE PF_ID_FAMILIA = id_familia;
            
         END;
      END IF;


      -- * 2. Guardar motivos de referencia

      IF p_potencial_familia.MOTIVOSREF.COUNT > 0 THEN -- * Elimina y reemplaza motivos
         DELETE FROM SSI_FAMILIA_MOTIVO_REFERENCIA mr
         WHERE mr.PF_ID_FAMILIA = id_familia;

         FORALL i IN INDICES OF p_potencial_familia.MOTIVOSREF
            INSERT INTO SSI_FAMILIA_MOTIVO_REFERENCIA(PF_ID_FAMILIA, MR_ID_MOTIVO, FMR_ESTADO)
            VALUES (
               id_familia,
               p_potencial_familia.MOTIVOSREF(i).IDMOTIVO,
               1
            );
      END IF;

      -- * 3. Guardar integrantes familia
      FOR i IN 1..p_potencial_familia.INTEGRANTES.COUNT LOOP

         -- * 3.1 Evalua si el integrante ya existe
         BEGIN
            SELECT 
               p.FI_ID_INTEGRANTE INTO id_integrante 
            FROM SSI_FAMILIA_INTEGRANTES p 
            WHERE p.FI_ID_INTEGRANTE = p_potencial_familia.INTEGRANTES(i).IDINTEGRANTE;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               id_integrante := NULL;
         END;

         IF id_integrante IS NULL THEN -- Nuevo integrante
            BEGIN
               INSERT INTO SSI_FAMILIA_INTEGRANTES(
                  PF_ID_FAMILIA,
                  CA_ID_TIPDOC,
                  CA_ID_GRADO_INST,
                  CA_ID_TIPO_SEGURO,
                  PA_ID_NAC,
                  PA_ID_PAIS_NACIMIENTO,
                  CA_ID_PARENTESCO,
                  CA_ID_ESTADO_CIVIL,
                  CA_ID_SEXO,
                  CA_ID_IDIOMA,
                  CA_ID_DISCAPACIDAD,
                  CA_ID_DERIVADO_POR,
                  CA_ID_SERVICIO_CUIDADOR,
                  CP_ID_CENTRO_POBLA,
                  CA_ID_OCUPACION,
                  FI_NUMERO_DOC,
                  FI_NOMBRES,
                  FI_PRIMER_APE,
                  FI_SEGUNDO_APE,
                  FI_APELLIDO_CASADO,
                  FI_FEC_NAC,
                  FI_TELEFONO,
                  FI_CORREO,
                  UBI_ID_UBIGEO,
                  UBI_ID_DEPARTAMENTO,
                  UBI_ID_PROVINCIA,
                  UBI_ID_DISTRITO,
                  FI_DIRECCION,
                  FI_REFERENCIA_DOMICILIARIA,
                  FI_GRADO_SECCION_NNA,
                  FI_CENTRO_POBLADO,
                  FI_CUIDADOR,
                  FI_USU_REGISTRA
               ) VALUES (
                  id_familia,
                  p_potencial_familia.INTEGRANTES(i).IDTIPDOC,
                  p_potencial_familia.INTEGRANTES(i).IDGRADOINST,
                  p_potencial_familia.INTEGRANTES(i).IDTIPOSEGURO,
                  p_potencial_familia.INTEGRANTES(i).IDNAC,
                  p_potencial_familia.INTEGRANTES(i).IDPAISNACIMIENTO,
                  p_potencial_familia.INTEGRANTES(i).IDPARENTESCO,
                  p_potencial_familia.INTEGRANTES(i).IDESTADOCIVIL,
                  p_potencial_familia.INTEGRANTES(i).IDSEXO,
                  p_potencial_familia.INTEGRANTES(i).IDIDIOMA,
                  p_potencial_familia.INTEGRANTES(i).IDDISCAPACIDAD,
                  p_potencial_familia.INTEGRANTES(i).IDDERIVADOPOR,
                  p_potencial_familia.INTEGRANTES(i).IDSERVICIOCUIDADOR,
                  p_potencial_familia.INTEGRANTES(i).IDCENTROPOBLA,
                  p_potencial_familia.INTEGRANTES(i).IDOCUPACION,
                  p_potencial_familia.INTEGRANTES(i).NUMERODOC,
                  p_potencial_familia.INTEGRANTES(i).NOMBRES,
                  p_potencial_familia.INTEGRANTES(i).PRIMERAPE,
                  p_potencial_familia.INTEGRANTES(i).SEGUNDOAPE,
                  p_potencial_familia.INTEGRANTES(i).APELLIDOCASADO,
                  p_potencial_familia.INTEGRANTES(i).FECNAC,
                  p_potencial_familia.INTEGRANTES(i).TELEFONO,
                  p_potencial_familia.INTEGRANTES(i).CORREO,
                  (p_potencial_familia.INTEGRANTES(i).IDDEPARTAMENTO || p_potencial_familia.INTEGRANTES(i).IDPROVINCIA || p_potencial_familia.INTEGRANTES(i).IDDISTRITO), -- UBI_ID_UBIGEO
                  p_potencial_familia.INTEGRANTES(i).IDDEPARTAMENTO,
                  p_potencial_familia.INTEGRANTES(i).IDPROVINCIA,
                  p_potencial_familia.INTEGRANTES(i).IDDISTRITO,
                  p_potencial_familia.INTEGRANTES(i).DIRECCION,
                  p_potencial_familia.INTEGRANTES(i).REFERENCIADOMICILIARIA,
                  p_potencial_familia.INTEGRANTES(i).GRADOSECCIONNNA,
                  p_potencial_familia.INTEGRANTES(i).CENTROPOBLADO,
                  p_potencial_familia.INTEGRANTES(i).CUIDADOR,
                  p_potencial_familia.USUREGISTRA
               );
               
            END;
         ELSE -- Actualizar integrante
            BEGIN
               UPDATE SSI_FAMILIA_INTEGRANTES
                  SET
                     PF_ID_FAMILIA = id_familia,
                     CA_ID_TIPDOC = p_potencial_familia.INTEGRANTES(i).IDTIPDOC,
                     CA_ID_GRADO_INST = p_potencial_familia.INTEGRANTES(i).IDGRADOINST,
                     CA_ID_TIPO_SEGURO = p_potencial_familia.INTEGRANTES(i).IDTIPOSEGURO,
                     PA_ID_NAC = p_potencial_familia.INTEGRANTES(i).IDNAC,
                     PA_ID_PAIS_NACIMIENTO = p_potencial_familia.INTEGRANTES(i).IDPAISNACIMIENTO,
                     CA_ID_PARENTESCO = p_potencial_familia.INTEGRANTES(i).IDPARENTESCO,
                     CA_ID_ESTADO_CIVIL = p_potencial_familia.INTEGRANTES(i).IDESTADOCIVIL,
                     CA_ID_SEXO = p_potencial_familia.INTEGRANTES(i).IDSEXO,
                     CA_ID_IDIOMA = p_potencial_familia.INTEGRANTES(i).IDIDIOMA,
                     CA_ID_DISCAPACIDAD = p_potencial_familia.INTEGRANTES(i).IDDISCAPACIDAD,
                     CA_ID_DERIVADO_POR = p_potencial_familia.INTEGRANTES(i).IDDERIVADOPOR,
                     CA_ID_SERVICIO_CUIDADOR = p_potencial_familia.INTEGRANTES(i).IDSERVICIOCUIDADOR,
                     CP_ID_CENTRO_POBLA = p_potencial_familia.INTEGRANTES(i).IDCENTROPOBLA,
                     CA_ID_OCUPACION = p_potencial_familia.INTEGRANTES(i).IDOCUPACION,
                     FI_NUMERO_DOC = p_potencial_familia.INTEGRANTES(i).NUMERODOC,
                     FI_NOMBRES = p_potencial_familia.INTEGRANTES(i).NOMBRES,
                     FI_PRIMER_APE = p_potencial_familia.INTEGRANTES(i).PRIMERAPE,
                     FI_SEGUNDO_APE = p_potencial_familia.INTEGRANTES(i).SEGUNDOAPE,
                     FI_APELLIDO_CASADO = p_potencial_familia.INTEGRANTES(i).APELLIDOCASADO,
                     FI_FEC_NAC = p_potencial_familia.INTEGRANTES(i).FECNAC,
                     FI_TELEFONO = p_potencial_familia.INTEGRANTES(i).TELEFONO,
                     FI_CORREO = p_potencial_familia.INTEGRANTES(i).CORREO,

                     UBI_ID_UBIGEO = (p_potencial_familia.INTEGRANTES(i).IDDEPARTAMENTO || p_potencial_familia.INTEGRANTES(i).IDPROVINCIA || p_potencial_familia.INTEGRANTES(i).IDDISTRITO), -- UBI_ID_UBIGEO

                     UBI_ID_DEPARTAMENTO = p_potencial_familia.INTEGRANTES(i).IDDEPARTAMENTO,
                     UBI_ID_PROVINCIA = p_potencial_familia.INTEGRANTES(i).IDPROVINCIA,
                     UBI_ID_DISTRITO = p_potencial_familia.INTEGRANTES(i).IDDISTRITO,
                     FI_DIRECCION = p_potencial_familia.INTEGRANTES(i).DIRECCION,
                     FI_REFERENCIA_DOMICILIARIA = p_potencial_familia.INTEGRANTES(i).REFERENCIADOMICILIARIA,
                     FI_GRADO_SECCION_NNA = p_potencial_familia.INTEGRANTES(i).GRADOSECCIONNNA,
                     FI_CENTRO_POBLADO = p_potencial_familia.INTEGRANTES(i).CENTROPOBLADO,
                     FI_CUIDADOR = p_potencial_familia.INTEGRANTES(i).CUIDADOR,
                     FI_USU_ACTUALIZA = p_potencial_familia.USUREGISTRA,
                     FI_FEC_ACTUALIZA = SYSDATE
                  
               WHERE FI_ID_INTEGRANTE = id_integrante;

            END;

         END IF;
         
         -- ! Cleanup:
         id_integrante := NULL;

      END LOOP;

      -- * 4. Guardar respuestas
      FOR i IN 1..p_fichas_respuestas.COUNT LOOP

         -- * 4.1 Evalua si la respuesta ya existe
         BEGIN
            SELECT 
               p.AR_ID_RESPUESTA INTO id_respuesta 
            FROM SSI_ANEXOS_RESPUESTAS p 
            WHERE p.AR_ID_RESPUESTA = p_fichas_respuestas(i).IDRESPUESTA;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               id_respuesta := NULL;
         END;
         IF id_respuesta IS NULL THEN -- Nueva respuesta
            BEGIN
               INSERT INTO SSI_ANEXOS_RESPUESTAS(
                  PF_ID_FAMILIA,
                  AP_ID_PREGUNTA,
                  AR_RESPUESTA,
                  AR_OBSERVACION,
                  AR_USU_REGISTRA
               ) VALUES (
                  id_familia,
                  p_fichas_respuestas(i).IDPREGUNTA,
                  p_fichas_respuestas(i).RESPUESTA,
                  p_fichas_respuestas(i).OBSERVACION,
                  p_potencial_familia.USUREGISTRA
               );
            
            END;
            ELSE -- Actualizar respuesta
               BEGIN
                  UPDATE SSI_ANEXOS_RESPUESTAS
                     SET
                        PF_ID_FAMILIA = id_familia,
                        AP_ID_PREGUNTA = p_fichas_respuestas(i).IDPREGUNTA,
                        AR_RESPUESTA = p_fichas_respuestas(i).RESPUESTA,
                        AR_OBSERVACION = p_fichas_respuestas(i).OBSERVACION,
                        AR_USU_MODIFICA = p_potencial_familia.USUREGISTRA,
                        AR_FECHA_MODIFICA = SYSDATE
                  WHERE AR_ID_RESPUESTA = id_respuesta;

               END;
            END IF;

            -- ! Cleanup:
            id_respuesta := NULL;

      END LOOP;

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT SP_GUARDAR_POTENCIAL_FAMILIA;
         DBMS_OUTPUT.PUT_LINE('Error al guardar la Potencial Familia: ' || SQLERRM);
         RAISE;
   END;

END;
/

-- ! COMMIT;

-- 11.3 Llamar al procedimiento almacenado:
BEGIN
   USP_GUARDAR_POTENCIAL_FAMILIA_V2(
      -- 1, -- SEDIF
      -- 2, -- PUNCHE
      O_POTENCIAL_FAMILIA_V2(
         NULL, 'TMP0002-0002', 205, 197, 1, 1, '', 2, SYSDATE, -- Nuevo
         T_FAMILIA_MOTIVOS_REFERENCIA_V2(
            O_FAMILIA_MOTIVO_REFERENCIA_V2(1),
            O_FAMILIA_MOTIVO_REFERENCIA_V2(2)
         ),
         T_FAMILIA_INTEGRANTES_V2(
            O_FAMILIA_INTEGRANTE_V2(
               NULL, -- Nuevo
               1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
               '46392613',
               'NOMBRES',
               'PRIMERAPE',
               'SEGUNDOAPE',
               'APELLIDOCASADO',
               SYSDATE,
               'TELEFONO',
               'CORREO',
               '01',
               '01',
               '01',
               'DIRECCION',
               'REFERENCIADOMICILIARIA',
               'GRADOSECCIONNNA',
               1,
               1
            )
         )
      ),
      T_ANEXO_RESPUESTAS_V2(
         O_ANEXO_RESPUESTA_V2(NULL, 1, 'RESPUESTA 1', 'OBSERVACION 1', 1), -- Nuevo
         O_ANEXO_RESPUESTA_V2(1525, 2, 'RESPUESTA 3', 'OBSERVACION 3', 2) -- NUevo
      )
   );
END;
/
-- ==============================================================================================================================


/*
*     ░  12. Buscar pregutas por servicios, anexo y grupo(opcional)
* ============================================================================================================================== */

-- 12.1 Crea procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_BUSCAR_PREGUNTAS_POR_PARAMETROS
(
   p_servicio IN NUMBER,
   p_anexo IN NUMBER,
   p_grupo IN NUMBER DEFAULT NULL,
   c_resultado OUT SYS_REFCURSOR
)
IS
BEGIN

   OPEN c_resultado FOR
      SELECT 

         p.AP_ID_PREGUNTA AS IDPREGUNTA,
         p.SI_ID_SERVICIO AS IDSERVICIO,
         p.AP_NUM_ANEXO AS NUMANEXO,
         p.AP_NUM_GRUPO AS NUMGRUPO,
         p.AP_NUM_PREGUNTA AS NUMPREGUNTA,
         REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(p.AP_PREGUNTA, CHR(9), ''), CHR(10), ''), ' ', '<>'), '><', ''), '<>', ' ') AS PREGUNTA,
         UPPER(p.AP_OPCIONES) AS OPCIONES,
         p.AP_TIPO_CONTROL AS TIPOCONTROL,
         p.AP_CONDICION_SI AS CONDICIONSI,
         p.AP_CONDICION_NO AS CONDICIONNO

      FROM SSI_ANEXOS_PREGUNTAS p
      WHERE 
         p.SI_ID_SERVICIO = p_servicio
         AND p.AP_NUM_ANEXO = p_anexo
         AND (p.AP_NUM_GRUPO = p_grupo OR p_grupo IS NULL)
      ORDER BY SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA;


END;
/

-- 12.2 Llama procedimiento almacenado
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_PREGUNTAS_POR_PARAMETROS(1, 5, 3, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ==============================================================================================================================


/*
*     ░  13. Buscar repuestas por familia, anexo y grupo(opcional)
* ============================================================================================================================== */

-- 13.1 Crea procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_BUSCAR_RESPUESTAS_POR_PARAMETROS
(
   p_id_familia IN NUMBER,
   p_anexo IN NUMBER,
   p_grupo IN NUMBER DEFAULT NULL,
   c_resultado OUT SYS_REFCURSOR
)
IS
BEGIN

   OPEN c_resultado FOR
      SELECT 

         p.AP_ID_PREGUNTA AS IDPREGUNTA,
         p.AP_NUM_ANEXO AS NUMANEXO,
         p.AP_NUM_GRUPO AS NUMGRUPO,
         p.AP_NUM_PREGUNTA AS NUMPREGUNTA,
         REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(p.AP_PREGUNTA, CHR(9), ''), CHR(10), ''), ' ', '<>'), '><', ''), '<>', ' ') AS PREGUNTA,
         p.AP_OPCIONES AS OPCIONES,
         p.AP_TIPO_CONTROL AS TIPOCONTROL,
         r.AR_ID_RESPUESTA AS IDRESPUESTA,
         r.SF_ID_FASE AS IDFASE,
         r.PR_ID_PERSONAL AS IDPERSONAL,
         TRIM((p.PERNOMBRE || ' ' || p.PERAPEPATERNO || ' ' || p.PERAPEMATERNO)) AS PERSONAL,
         r.AR_RESPUESTA AS RESPUESTA,
         r.AR_OBSERVACION AS OBSERVACION,
         r.AR_FECHA_REGISTRA AS FECHAREGISTRA

      FROM SSI_ANEXOS_RESPUESTAS r
      JOIN SSI_ANEXOS_PREGUNTAS p ON r.AP_ID_PREGUNTA = p.AP_ID_PREGUNTA
      LEFT JOIN TRPERSONAL pe ON r.PR_ID_PERSONAL = pe.IDPERSONAL
      LEFT JOIN TGPERSONA p ON pe.PRHPERSONA = p.IDPERSONA
      WHERE 
         r.AR_DESTINATARIO = 1 -- Familia
         AND r.PF_ID_FAMILIA = p_id_familia
         AND p.AP_NUM_ANEXO = p_anexo
         AND (p.AP_NUM_GRUPO = p_grupo OR p_grupo IS NULL)
      ORDER BY p.AP_NUM_ANEXO, p.AP_NUM_GRUPO, p.AP_NUM_PREGUNTA;


END;
/

-- ! COMMIT;

-- 13.2 Llama procedimiento almacen
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_RESPUESTAS_POR_PARAMETROS(494, 16, NULL, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ==============================================================================================================================


/*
*     ░  14. Buscar repuestas por integrante, anexo y grupo(opcional)
* ============================================================================================================================== */

-- 13.1 Crea procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_BUSCAR_INTEGRANTE_RESPUESTAS_POR_PARAMETROS
(
   p_id_integrante IN NUMBER,
   p_anexo IN NUMBER,
   p_grupo IN NUMBER DEFAULT NULL,
   c_resultado OUT SYS_REFCURSOR
)
IS
BEGIN

   OPEN c_resultado FOR
      SELECT 

         p.AP_ID_PREGUNTA AS IDPREGUNTA,
         p.AP_NUM_ANEXO AS NUMANEXO,
         p.AP_NUM_GRUPO AS NUMGRUPO,
         p.AP_NUM_PREGUNTA AS NUMPREGUNTA,
         REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(p.AP_PREGUNTA, CHR(9), ''), CHR(10), ''), ' ', '<>'), '><', ''), '<>', ' ') AS PREGUNTA,
         p.AP_OPCIONES AS OPCIONES,
         p.AP_TIPO_CONTROL AS TIPOCONTROL,
         r.AR_ID_RESPUESTA AS IDRESPUESTA,
         r.SF_ID_FASE AS IDFASE,
         r.PR_ID_PERSONAL AS IDPERSONAL,
         TRIM((p.PERNOMBRE || ' ' || p.PERAPEPATERNO || ' ' || p.PERAPEMATERNO)) AS PERSONAL,
         r.AR_RESPUESTA AS RESPUESTA,
         r.AR_OBSERVACION AS OBSERVACION,
         r.AR_FECHA_REGISTRA AS FECHAREGISTRA

      FROM SSI_ANEXOS_RESPUESTAS r
      JOIN SSI_ANEXOS_PREGUNTAS p ON r.AP_ID_PREGUNTA = p.AP_ID_PREGUNTA
      LEFT JOIN TRPERSONAL pe ON r.PR_ID_PERSONAL = pe.IDPERSONAL
      LEFT JOIN TGPERSONA p ON pe.PRHPERSONA = p.IDPERSONA
      WHERE 
         r.AR_DESTINATARIO = 2 -- NNA
         AND r.FI_ID_INTEGRANTE = p_id_integrante
         AND p.AP_NUM_ANEXO = p_anexo
         AND (p.AP_NUM_GRUPO = p_grupo OR p_grupo IS NULL)
      ORDER BY p.AP_NUM_ANEXO, p.AP_NUM_GRUPO, p.AP_NUM_PREGUNTA;


END;
/

-- ! COMMIT;

-- 13.2 Llama procedimiento almacen
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_INTEGRANTE_RESPUESTAS_POR_PARAMETROS(40, 2, NULL, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ==============================================================================================================================



/*
*     ░  15. Genera código de familia
* ============================================================================================================================== */

-- 15.1 Crea procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_GENERAR_CODIGO_FAMILIA
(
   p_id_servicio IN NUMBER,
   p_id_familia IN NUMBER DEFAULT NULL,
   p_id_integrante IN NUMBER DEFAULT NULL,
   o_codigo_familia OUT VARCHAR2
)
IS
   prefix_tmp VARCHAR2(3) := 'TMP';
   prefix_principal VARCHAR2(1) := 'F';
   codigo_familia VARCHAR2(55);
   id_referencia NUMBER; -- * Id: Punche → Zona; Cedif → Unidad Organica
   id_ubigeo_referencia VARCHAR2(6);
   secuencia_tmp VARCHAR(55); -- * Indice temporal
   secuencia_principal VARCHAR(55); -- * Indice principal
   secuencia_nna VARCHAR(3); -- * Indice NNA
   len_secuencia NUMBER := 5;
   id_familia NUMBER := 5; -- * Para listar integrantes y generar correlativo

   -- ? Aux
   actual_tipo_cod NUMBER(1);
   total_cod NUMBER(1);
BEGIN

   BEGIN

      SAVEPOINT TRAN_GENERAR_CODIGO_FAMILIA;

      -- * 1. Extrae ubigeo y id de referencia: Punche → Zona; Cedif → Unidad Organica
      IF (p_id_servicio = 1) THEN -- ? CEDIF
         SELECT 
            uo.UOR_UBIGEO, UO.IDUNIDADORGANICA, f.PF_ID_FAMILIA
            INTO id_ubigeo_referencia, id_referencia, id_familia
         FROM SSI_POTENCIALES_FAMILIAS f
         JOIN SSI_FAMILIA_INTEGRANTES i ON f.PF_ID_FAMILIA = i.PF_ID_FAMILIA
         LEFT JOIN TGUNIDADORGANICA uo ON f.UO_ID_UNIDADORGANICA = uo.IDUNIDADORGANICA
         WHERE 
            f.PF_ID_FAMILIA = p_id_familia 
            OR i.FI_ID_INTEGRANTE = p_id_integrante
         ORDER BY f.PF_ID_FAMILIA ASC
         OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY;
      END IF;

      IF (p_id_servicio = 2) THEN -- ? PUNCHE
         SELECT 
            z.UBI_ID_UBIGEO, z.ZO_ID_ZONA 
            INTO id_ubigeo_referencia, id_referencia
         FROM SSI_ZONA_INTERVENCION z
         JOIN SSI_POTENCIALES_FAMILIAS pf ON z.ZO_ID_ZONA = pf.ZO_ID_ZONA
         WHERE 
            pf.PF_ID_FAMILIA = p_id_familia;
      END IF;

      -- * 2. Correlativos:

      -- * 2.1 Genera secuencia temporal
         SELECT 
            LPAD(COUNT(1) + 1, len_secuencia, '0') INTO secuencia_tmp -- Secuencia temporal
         FROM SSI_CODIGOS_FAMILIAS c
         WHERE 
            c.CF_ELIMINADO = 0
            AND c.SI_ID_SERVICIO = p_id_servicio
            AND c.CF_TIPO_CODIGO = 0; -- * Tipo temporal

      -- * 2.2 Genera secuencia principal
         SELECT LPAD(COUNT(1) + 1, 5, '0') INTO secuencia_principal -- Secuencia principal
         FROM SSI_CODIGOS_FAMILIAS c
         WHERE 
            c.CF_ELIMINADO = 0
            AND c.SI_ID_SERVICIO = p_id_servicio
            AND c.CF_TIPO_CODIGO = (
                                       CASE
                                          WHEN (p_id_familia IS NOT NULL) THEN 1 -- Familia
                                          WHEN (p_id_integrante IS NOT NULL) THEN 2 -- Integrante
                                       END
            );

      -- * 2.3 Genera secuencia NNA
      IF (p_id_integrante IS NOT NULL) THEN
         SELECT 
            LPAD(f.ORDEN, 3, 'N0') INTO secuencia_nna
         FROM (
            SELECT 
               i.FI_ID_INTEGRANTE,
               ROW_NUMBER() OVER (ORDER BY i.FI_ID_INTEGRANTE) AS ORDEN
            FROM SSI_FAMILIA_INTEGRANTES i
            WHERE 
               i.FI_ELIMINADO = 0
               AND i.PF_ID_FAMILIA = id_familia
         ) f
         WHERE f.FI_ID_INTEGRANTE = p_id_integrante;
      END IF;


      -- * 3. Casos de uso para generar código:
      /*
      ?  a. Si no hay registros, entonces debe generar un código temporal.
      ?  b. Si ya tiene 1 registro y es el código temporal, debe generar el código principal.
      ?  c. Si tiene ambos no hacer nada.                                                                */

      -- * 3.1 ...
      SELECT 
         MAX(c.CF_TIPO_CODIGO), COUNT(1)
         INTO actual_tipo_cod, total_cod
      FROM SSI_CODIGOS_FAMILIAS c
      WHERE
         c.CF_ELIMINADO = 0
         AND c.SI_ID_SERVICIO = p_id_servicio
         AND (c.PF_ID_FAMILIA = p_id_familia OR c.FI_ID_INTEGRANTE = p_id_integrante);

      -- * 3.2 Si no hay registros, entonces debe generar un código temporal.
      IF (total_cod = 0) THEN
         codigo_familia := id_ubigeo_referencia || id_referencia || prefix_tmp || secuencia_tmp || CASE
                                                                                                      WHEN (p_id_integrante IS NOT NULL) THEN secuencia_nna
                                                                                                      ELSE ''
                                                                                                   END;
         INSERT INTO SSI_CODIGOS_FAMILIAS(SI_ID_SERVICIO, PF_ID_FAMILIA, FI_ID_INTEGRANTE, CF_CODIGO, CF_TIPO_CODIGO, CF_USU_REGISTRA, CF_FECHA_REGISTRA)
         VALUES(p_id_servicio, p_id_familia, p_id_integrante, codigo_familia, 0, 1, SYSDATE);
      END IF;

      -- * 3.2 Si ya tiene 1 registro y es el código temporal, debe generar el código principal.
      IF (total_cod = 1 AND actual_tipo_cod = 0) THEN

         -- * 3.2.1 Inserta código principal
         codigo_familia := id_ubigeo_referencia || id_referencia || prefix_principal || secuencia_principal || CASE
                                                                                                                  WHEN (p_id_integrante IS NOT NULL) THEN secuencia_nna
                                                                                                                  ELSE ''
                                                                                                               END;
         INSERT INTO SSI_CODIGOS_FAMILIAS(SI_ID_SERVICIO, PF_ID_FAMILIA, FI_ID_INTEGRANTE, CF_CODIGO, CF_TIPO_CODIGO, CF_USU_REGISTRA, CF_FECHA_REGISTRA)
         VALUES(
            p_id_servicio, 
            p_id_familia, 
            p_id_integrante, 
            codigo_familia,
            CASE
               WHEN (p_id_familia IS NOT NULL) THEN 1 -- Familia
               WHEN (p_id_integrante IS NOT NULL) THEN 2 -- Integrante
            END,
            1, 
            SYSDATE);

         -- * 3.2.2 Actualiza familia o integrante si es apta
         IF (p_id_familia IS NOT NULL) THEN
            UPDATE SSI_POTENCIALES_FAMILIAS
               SET PF_FAMILIA_APTA = 1 -- Apta
            WHERE PF_ID_FAMILIA = p_id_familia;
         END IF;

         IF (p_id_integrante IS NOT NULL) THEN
            UPDATE SSI_FAMILIA_INTEGRANTES
               SET PF_INTEGRANTE_APTO = 1 -- Apta
            WHERE FI_ID_INTEGRANTE = p_id_integrante;
         END IF;

      END IF;

      -- * 3.2 Si tiene ambos no hacer nada, devolver el código de familia.
      IF (total_cod = 2) THEN
         SELECT c.CF_CODIGO INTO codigo_familia -- Secuencia principal
         FROM SSI_CODIGOS_FAMILIAS c
         WHERE 
            c.CF_ELIMINADO = 0
            AND (c.PF_ID_FAMILIA = p_id_familia OR c.FI_ID_INTEGRANTE = p_id_integrante)
            AND c.CF_TIPO_CODIGO = (
                                       CASE
                                          WHEN (p_id_familia IS NOT NULL) THEN 1 -- Familia
                                          WHEN (p_id_integrante IS NOT NULL) THEN 2 -- Integrante
                                       END
            );
      END IF;

      -- * 4. Final: Devuelve el código de familia.
      o_codigo_familia := codigo_familia;

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT TRAN_GENERAR_CODIGO_FAMILIA;
         DBMS_OUTPUT.PUT_LINE('Error al generar código de familia: ' || SQLERRM);
         RAISE;
   END;

END;
/

-- 15.2 Llama procedimiento almacenado 
DECLARE
   cod_familia VARCHAR2(50);
BEGIN
   -- USP_GENERAR_CODIGO_FAMILIA(1, 296, NULL, cod_familia);
   USP_GENERAR_CODIGO_FAMILIA(1, NULL, 865, cod_familia);
   DBMS_OUTPUT.PUT_LINE(cod_familia);
END;
/

-- COMMIT;

-- ==============================================================================================================================

/*
*     ░  16. Buscar programción de talleres por servicio, año y mes registro
* ============================================================================================================================== */

-- 16.1 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_BUSCAR_PROGRAMACION_TALLERES_POR_PARAMETROS(
   p_id_servicio NUMBER,
   p_anio NUMBER,
   p_mes NUMBER,
   p_resultado_busqueda OUT SYS_REFCURSOR
)  
AS
BEGIN

      -- * 1. CEDIF: 1
      IF (p_id_servicio = 1) THEN
         OPEN p_resultado_busqueda FOR
            SELECT 
               pt.PT_ID_PROG_TALLER AS IDPROGTALLER,
               pt.PT_TEMA AS TEMA,
               t.TA_NOMBRE AS NOMBRETALLER,
               t.TA_DESCRIPCION AS DESCRIPCIONTALLER,
               pt.PT_FEC_HORA_INI AS FECHORAINICIO,
               pt.PT_FEC_HORA_FIN AS FECHORAFIN,
               pt.PT_FECHA_REGISTRA AS FECHAREGISTRA,

               -- * Dictado por
               (
                  CASE
                     WHEN (p.IDPERSONA IS NOT NULL) THEN TRIM(p.PERAPEPATERNO || N' ' || p.PERAPEMATERNO || N', ' || p.PERNOMBRE)
                     ELSE TRIM(uo.UORNOMBRE)
                  END 
               ) AS DICTADOPOR,

               ( -- * Contar familias
                  SELECT COUNT(1) FROM SSI_PROG_TALLER_FAMILIAS pf
                  WHERE 
                     pf.PD_ELIMINADO = 0
                     AND pf.PT_ID_PROG_TALLER = pt.PT_ID_PROG_TALLER
               ) AS TOTALFAMILIAS,
               pt.PT_ESTADO AS ESTADO,
               pt.PT_ELIMINADO AS ELIMINADO
            FROM SSI_PROG_TALLERES pt
            LEFT JOIN TRPERSONAL pe ON pt.PE_ID_PERSONAL = pe.IDPERSONAL
            LEFT JOIN TGPERSONA p ON pe.PRHPERSONA = p.IDPERSONA
            LEFT JOIN TGUNIDADORGANICA uo ON pt.UO_ID_UNIDADORG = uo.IDUNIDADORGANICA
            JOIN SSI_TALLERES t ON pt.TA_ID_TALLER = t.TA_ID_TALLER
            JOIN SSI_MODULOS m ON t.MO_ID_MODULO = m.MO_ID_MODULO
            JOIN SSI_OBJETIVOS_ESPECIFICOS o ON m.OE_ID_OBJETIVO = o.OE_ID_OBJETIVO
            WHERE
               pt.PT_ELIMINADO = 0
               AND o.SI_ID_SERVICIO = p_id_servicio -- * CEDIF: 1
               AND TO_CHAR(pt.PT_FECHA_REGISTRA, 'YYYY') = p_anio
               AND (TO_CHAR(pt.PT_FECHA_REGISTRA, 'MM') = p_mes OR p_mes = -1)
            ORDER BY pt.PT_ID_PROG_TALLER DESC;

      END IF;

      -- * 2. PUNCHE: 2
      IF (p_id_servicio = 2) THEN
         OPEN p_resultado_busqueda FOR
            SELECT 
               pt.PT_ID_PROG_TALLER AS IDPROGTALLER,
               pt.PT_TEMA AS TEMA,
               t.TA_NOMBRE AS NOMBRETALLER,
               t.TA_DESCRIPCION AS DESCRIPCIONTALLER,
               pt.PT_FEC_HORA_INI AS FECHORAINICIO,
               pt.PT_FEC_HORA_FIN AS FECHORAFIN,
               pt.PT_FECHA_REGISTRA AS FECHAREGISTRA,
               
               -- * Dictado por
               (
                  CASE
                     WHEN (p.IDPERSONA IS NOT NULL) THEN TRIM(p.PERAPEPATERNO || N' ' || p.PERAPEMATERNO || N', ' || p.PERNOMBRE)
                     ELSE TRIM(uo.UORNOMBRE)
                  END 
               ) AS DICTADOPOR,

               ( -- * Contar familias
                  SELECT COUNT(1) FROM SSI_PROG_TALLER_FAMILIAS pf
                  WHERE 
                     pf.PD_ELIMINADO = 0
                     AND pf.PT_ID_PROG_TALLER = pt.PT_ID_PROG_TALLER
               ) AS TOTALFAMILIAS,
               pt.PT_ESTADO AS ESTADO,
               pt.PT_ELIMINADO AS ELIMINADO
            FROM SSI_PROG_TALLERES pt
            LEFT JOIN TRPERSONAL pe ON pt.PE_ID_PERSONAL = pe.IDPERSONAL
            LEFT JOIN TGPERSONA p ON pe.PRHPERSONA = p.IDPERSONA
            LEFT JOIN TGUNIDADORGANICA uo ON pt.UO_ID_UNIDADORG = uo.IDUNIDADORGANICA
            JOIN SSI_TALLERES t ON pt.TA_ID_TALLER = t.TA_ID_TALLER
            JOIN SSI_UNIDAD_SESIONES s ON t.SE_ID_SESION = s.SE_ID_SESION
            JOIN SSI_UNIDADES u ON s.UN_ID_UNIDAD = u.UN_ID_UNIDAD
            JOIN SSI_MODULOS m ON u.MO_ID_MODULO = m.MO_ID_MODULO
            JOIN SSI_OBJETIVOS_ESPECIFICOS o ON m.OE_ID_OBJETIVO = o.OE_ID_OBJETIVO
            WHERE
               pt.PT_ELIMINADO = 0
               AND o.SI_ID_SERVICIO = p_id_servicio -- * PUNCHE: 2
               AND TO_CHAR(pt.PT_FECHA_REGISTRA, 'YYYY') = p_anio
               AND (TO_CHAR(pt.PT_FECHA_REGISTRA, 'MM') = p_mes OR p_mes = -1)
            ORDER BY pt.PT_ID_PROG_TALLER DESC;

      END IF;

      -- * 3. ACERCANDONOS: 3
      IF (p_id_servicio = 3) THEN
         OPEN p_resultado_busqueda FOR
            SELECT 
               pt.PT_ID_PROG_TALLER AS IDPROGTALLER,
               pt.PT_TEMA AS TEMA,
               t.TA_NOMBRE AS NOMBRETALLER,
               t.TA_DESCRIPCION AS DESCRIPCIONTALLER,
               pt.PT_FEC_HORA_INI AS FECHORAINICIO,
               pt.PT_FEC_HORA_FIN AS FECHORAFIN,
               pt.PT_FECHA_REGISTRA AS FECHAREGISTRA,
               -- * Dictado por
               (
                  CASE
                     WHEN (p.IDPERSONA IS NOT NULL) THEN TRIM(p.PERAPEPATERNO || N' ' || p.PERAPEMATERNO || N', ' || p.PERNOMBRE)
                     ELSE TRIM(uo.UORNOMBRE)
                  END 
               ) AS DICTADOPOR,
               
               ( -- Contar familias
                  SELECT COUNT(1) FROM SSI_PROG_TALLER_FAMILIAS pf
                  WHERE 
                     pf.PD_ELIMINADO = 0
                     AND pf.PT_ID_PROG_TALLER = pt.PT_ID_PROG_TALLER
               ) AS TOTALFAMILIAS,
               pt.PT_ESTADO AS ESTADO,
               pt.PT_ELIMINADO AS ELIMINADO
            FROM SSI_PROG_TALLERES pt
            LEFT JOIN TRPERSONAL pe ON pt.PE_ID_PERSONAL = pe.IDPERSONAL
            LEFT JOIN TGPERSONA p ON pe.PRHPERSONA = p.IDPERSONA
            LEFT JOIN TGUNIDADORGANICA uo ON pt.UO_ID_UNIDADORG = uo.IDUNIDADORGANICA
            JOIN SSI_TALLERES t ON pt.TA_ID_TALLER = t.TA_ID_TALLER
            -- JOIN SSI_UNIDAD_SESIONES s ON t.SE_ID_SESION = s.SE_ID_SESION
            JOIN SSI_OBJETIVOS_ESPECIFICOS o ON t.OE_ID_OBJETIVO = o.OE_ID_OBJETIVO
            WHERE
               pt.PT_ELIMINADO = 0
               AND o.SI_ID_SERVICIO = p_id_servicio -- * ACERCANDONOS: 3
               AND TO_CHAR(pt.PT_FECHA_REGISTRA, 'YYYY') = p_anio
               AND (TO_CHAR(pt.PT_FECHA_REGISTRA, 'MM') = p_mes OR p_mes = -1)
            ORDER BY pt.PT_ID_PROG_TALLER DESC;

      END IF;

END;
/

-- COMMIT;

-- 16.2 Llamar al procedimiento almacenado
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_PROGRAMACION_TALLERES_POR_PARAMETROS(1, 2025, 10, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ==============================================================================================================================


/*
*  ░  17. Buscar personal por parametros
* ============================================================================================================================== */

-- * 17.1 Crea un procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_LISTAR_PERSONAL_POR_DYNAMIC_PARAM
(
   p_tipo_busqueda IN NUMBER,
   p_dynamic_param IN VARCHAR2 DEFAULT '',
   c_resultado_busqueda OUT SYS_REFCURSOR
)
IS
BEGIN

      OPEN c_resultado_busqueda FOR
         SELECT 
            p.IDPERSONA,
            u.IDPERSONAL,
            p.PERNOMBRE || ', ' || p.PERAPEPATERNO || ' ' || p.PERAPEMATERNO AS NOMBRES,
            c2.CATDESCRIPCION AS DOCUMENTO,
            p.PERNRODOCUMENTO AS NUMERODOC,
            pa.PA_NACIONALIDAD AS NACIONALIDAD,
            c.CATDESCRIPCION AS ESTADOCIVIL,
            p.PERFECNACIMIENTO AS FECNACIMIENTO,
            CASE
               WHEN p.PERSEXO = 1 THEN 'MASCULINO'
               WHEN p.PERSEXO = 2 THEN 'FEMENINO'
               ELSE 'NO DEFINIDO'
            END AS SEXO,
            p.PERDIRECCION AS DIRECCION,
            p.PERREFERENCIA AS REFERENCIA,
            p.PERTELEFONO AS TELEFONO,
            p.PERCORREO AS CORREO,
            ca.CP_NOMBRE AS CARRERA
         FROM TGPERSONA p
         JOIN TRPERSONAL u ON p.IDPERSONA = u.PRHPERSONA
         LEFT JOIN TGCATALOGO c ON p.PERESTADOCIVIL = c.IDCATALOGO -- ESTADO CIVIL
         LEFT JOIN TGCATALOGO c2 ON p.PERDOCUMENTO = c2.IDCATALOGO -- TIPO DOCUMENTO
         LEFT JOIN TG_CARRERA_PROFESIONAL ca ON u.PRHPROFESION = ca.IDCARRERA_PROFESIONAL
         LEFT JOIN TG_PAIS pa ON p.PERNACPAIS = pa.IDPAIS
         WHERE
            (
               CASE
                  WHEN (p_tipo_busqueda = 1) THEN ( -- * DNI
                        CASE 
                           WHEN (p.PERNRODOCUMENTO = p_dynamic_param) THEN 1
                           ELSE 0
                        END
                  )
                  WHEN (p_tipo_busqueda = 2) THEN ( -- * Nombres
                        CASE 
                           WHEN (
                                    UPPER(p.PERNOMBRE) LIKE '%' || TRIM(UPPER(p_dynamic_param)) || '%'
                                    OR UPPER(p.PERAPEPATERNO) LIKE '%' || TRIM(UPPER(p_dynamic_param)) || '%'
                                    OR UPPER(p.PERAPEMATERNO) LIKE '%' || TRIM(UPPER(p_dynamic_param)) || '%'
                                 ) THEN 1
                           ELSE 0
                        END
                  )
                  ELSE 0
               END
            ) = 1;
   
END;
/

-- 17.2 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   USP_LISTAR_PERSONAL_POR_DYNAMIC_PARAM(2, 'ROO', c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- ==============================================================================================================================



/*
*     ░  18. Buscar detalle PATFAM por taller
* ============================================================================================================================== */

-- 18.1 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_BUSCAR_DET_PATFAM_POR_TALLER(
   p_id_taller NUMBER,
   p_resultado_busqueda OUT SYS_REFCURSOR
)  
AS
BEGIN

   OPEN p_resultado_busqueda FOR
      SELECT 
         -- * CEDIF, PUNCHE, ACERCANDONOS
         COALESCE(oc.OE_ID_OBJETIVO, op.OE_ID_OBJETIVO, oa.OE_ID_OBJETIVO) AS IDOBJETIVO,
         COALESCE(oc.OE_DESCRIPCION, op.OE_DESCRIPCION, oa.OE_DESCRIPCION) AS NOMBREOBJETIVO,

         -- * CEDIF Y PUNCHE
         COALESCE(mc.MO_ID_MODULO, mp.MO_ID_MODULO) AS IDMODULO,
         COALESCE(mc.MO_DESCRIPCION, mp.MO_DESCRIPCION) AS NOMBREMODULO,

         -- * PUNCHE
         unp.UN_ID_UNIDAD  AS IDUNIDAD,
         unp.UN_DESCRIPCION  AS NOMBREUNIDAD,
         sp.SE_ID_SESION AS IDSESION,
         sp.SE_DESCRIPCION AS NOMBRESESION,

         -- * COMÚN
         t.TA_ID_TALLER AS IDTALLER,
         t.TA_NOMBRE AS NOMBRETALLER
         
      FROM SSI_TALLERES t 
      -- * 1 ↔ CEDIF
      LEFT JOIN SSI_MODULOS mc ON t.MO_ID_MODULO = mc.MO_ID_MODULO
      LEFT JOIN SSI_OBJETIVOS_ESPECIFICOS oc ON mc.OE_ID_OBJETIVO = oc.OE_ID_OBJETIVO
      -- * 2 ↔ PUNCHE
      LEFT JOIN SSI_UNIDAD_SESIONES sp ON t.SE_ID_SESION = sp.SE_ID_SESION
      LEFT JOIN SSI_UNIDADES unp ON sp.UN_ID_UNIDAD = unp.UN_ID_UNIDAD
      LEFT JOIN SSI_MODULOS mp ON unp.MO_ID_MODULO = mp.MO_ID_MODULO
      LEFT JOIN SSI_OBJETIVOS_ESPECIFICOS op ON mp.OE_ID_OBJETIVO = op.OE_ID_OBJETIVO
      -- * 3 ↔ ACERCANDONOS
      LEFT JOIN SSI_OBJETIVOS_ESPECIFICOS oa ON t.OE_ID_OBJETIVO = oa.OE_ID_OBJETIVO
      WHERE
         t.TA_ELIMINADO = 0
         AND t.TA_ID_TALLER  = p_id_taller;

END;
/

-- COMMIT;

-- 18.2 Llamar al procedimiento almacenado
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_BUSCAR_DET_PATFAM_POR_TALLER(123, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ==============================================================================================================================

/*
*     ░  19. Buscar estados de fichas por familia o integrante
* ============================================================================================================================== */

-- 19.1 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_LISTAR_ESTADOS_FICHAS_POR_PARAMS(
   p_id_servicio IN NUMBER,
   p_id_familia IN NUMBER DEFAULT NULL,
   p_id_integrante IN NUMBER DEFAULT NULL,
   p_resultado_busqueda OUT SYS_REFCURSOR
)
AS
   id_servicio NUMBER;
BEGIN

   OPEN p_resultado_busqueda FOR
      SELECT 
         e.AP_NUM_ANEXO AS NUMANEXO,
         e.AP_NUM_GRUPO AS NUMGRUPO,
         e.AP_ID_PREGUNTA AS IDPREGUNTA,
         e.AP_PREGUNTA AS PREGUNTA,
         r2.SF_ID_FASE AS IDFASE,
         (
            CASE
               WHEN (e.AP_NUM_GRUPO = -5) THEN (
                  CASE
                     WHEN (VALIDATE_CONVERSION(r2.AR_RESPUESTA AS NUMBER) = 1) THEN TO_NUMBER(r2.AR_RESPUESTA)
                     ELSE NULL
                  END
               )
               ELSE ( -- Grupo Estados
                  CASE
                     WHEN (r2.AP_ID_PREGUNTA IS NOT NULL) THEN 1
                     ELSE 0
                  END
               )
            END
         ) AS ESTADO
      FROM (

         -- * 1. Anexos por servicio
         SELECT 
            p.AP_NUM_ANEXO,
            p.AP_NUM_GRUPO,
            p.AP_ID_PREGUNTA,
            p.AP_PREGUNTA
         FROM SSI_ANEXOS_PREGUNTAS p
         WHERE
            p.SI_ID_SERVICIO = p_id_servicio
            -- * Estados: Familia(0); Integrante(-1)
            AND p.AP_NUM_GRUPO = (
                                    CASE
                                       WHEN (p_id_familia IS NOT NULL) THEN 0
                                       WHEN (p_id_integrante IS NOT NULL) THEN -1
                                       ELSE 0
                                    END
            ) 
         
         UNION ALL

         -- * 2. Grupo Archivos(-3) por servicio
         SELECT 
            p.AP_NUM_ANEXO,
            p.AP_NUM_GRUPO,
            p.AP_ID_PREGUNTA,
            p.AP_PREGUNTA
         FROM SSI_ANEXOS_PREGUNTAS p
         WHERE
            p.SI_ID_SERVICIO = p_id_servicio
            AND p.AP_NUM_GRUPO = -3 -- * Archivos
            AND p.AP_NUM_PREGUNTA > 1

         UNION ALL

         -- * 3. Grupo Apto(-5) por servicio
         SELECT 
            p.AP_NUM_ANEXO,
            p.AP_NUM_GRUPO,
            p.AP_ID_PREGUNTA,
            p.AP_PREGUNTA
         FROM SSI_ANEXOS_PREGUNTAS p
         WHERE
            p.SI_ID_SERVICIO = p_id_servicio
            AND p.AP_NUM_GRUPO = -5 -- * Apto

      ) e
      LEFT JOIN (

         SELECT 
            p1.AP_ID_PREGUNTA,
            r1.SF_ID_FASE,
            r1.AR_RESPUESTA
         FROM SSI_ANEXOS_RESPUESTAS r1
         JOIN SSI_ANEXOS_PREGUNTAS p1 ON r1.AP_ID_PREGUNTA = p1.AP_ID_PREGUNTA
         WHERE 
            (r1.PF_ID_FAMILIA = p_id_familia OR r1.FI_ID_INTEGRANTE = p_id_integrante)
            AND (
                  p1.AP_NUM_GRUPO IN (-3, -5) -- * Grupos: Archivos(-3) | Ficha apta(-5)
                  OR p1.AP_NUM_GRUPO = ( -- * Grupo Estados: Familia(0) | Integrante(-1)
                                          CASE
                                             WHEN (p_id_familia IS NOT NULL) THEN 0
                                             WHEN (p_id_integrante IS NOT NULL) THEN -1
                                             ELSE 0
                                          END
                  ) 
            )

      ) r2 ON e.AP_ID_PREGUNTA = r2.AP_ID_PREGUNTA
      ORDER BY e.AP_NUM_ANEXO, e.AP_NUM_GRUPO, e.AP_ID_PREGUNTA;

END;
/


-- 19.2 Llamar al procedimiento almacenado
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_LISTAR_ESTADOS_FICHAS_POR_PARAMS(1, NULL, 308, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/


-- ============================================================================================================================== */



/*
*     ░  20. Generar reporte comparativo de fases de fichas
* ============================================================================================================================== */

-- 20.1 Crear el procedimiento almacenado
-- ! v2
CREATE OR REPLACE PROCEDURE USP_GENERAR_REPORTE_COMPARATIVO_FASES_DE_FICHAS_PARAMETRIZADO(
   p_id_servicio IN NUMBER,
   p_num_anexo IN NUMBER,
   p_id_familia IN NUMBER DEFAULT NULL,
   p_id_integrante IN NUMBER DEFAULT NULL,
   p_resultado_busqueda OUT SYS_REFCURSOR
)
AS
   id_servicio NUMBER;
BEGIN

      OPEN p_resultado_busqueda FOR
         SELECT
            r.AR_ID_RESPUESTA,
            af.SF_ID_FASE AS IDFASE,
            af.SF_ORDEN AS ORDEN,
            af.SF_NOMBRE AS OPORTUNIDAD,
            p.AP_PREGUNTA AS CAMPO,
            r.AR_RESPUESTA AS VALOR
         FROM SSI_ANEXOS_PREGUNTAS p
         JOIN SSI_ANEXOS_RESPUESTAS r ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
         JOIN SSI_ANEXO_FASES af ON r.SF_ID_FASE = af.SF_ID_FASE
         /* JOIN SSI_ANEXO_FASES af ON p.SI_ID_SERVICIO = af.SF_ID_SERVICIO
                                 AND (p.AP_NUM_ANEXO = af.SF_NUM_ANEXO OR af.SF_NUM_ANEXO = 0)
                                 AND r.SF_ID_FASE = af.SF_ID_FASE */
         WHERE 
            p.SI_ID_SERVICIO = p_id_servicio
            AND (r.PF_ID_FAMILIA = p_id_familia OR r.FI_ID_INTEGRANTE = p_id_integrante)
            AND p.AP_NUM_ANEXO = p_num_anexo
            AND p.AP_NUM_GRUPO = -4 -- * Grupo Archivo: Resultado Ficha
         ORDER BY af.SF_ORDEN, p.AP_NUM_PREGUNTA;

END;
/


-- 19.2 Llamar al procedimiento almacenado
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   -- USP_GENERAR_REPORTE_COMPARATIVO_FASES_DE_FICHAS_PARAMETRIZADO(2, 9, 116, NULL, c_resultado);
   USP_GENERAR_REPORTE_COMPARATIVO_FASES_DE_FICHAS_PARAMETRIZADO(2, 28, NULL, 10689, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/



-- ============================================================================================================================== */


/*
*     ░  21. Eliminar anexo respuestas por familia o integrante
* ============================================================================================================================== */

-- * 21.1 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_ELIMINAR_ANEXO_RESPUESTAS_PARAMETRIZADO
(
   p_id_servicio IN NUMBER,
   p_num_anexo IN NUMBER,
   p_fase IN NUMBER,
   p_id_familia IN NUMBER DEFAULT NULL,
   p_id_integrante IN NUMBER DEFAULT NULL
)
AS
BEGIN

   BEGIN

      SAVEPOINT TRAN_ELIMINAR_ANEXO_RESPUESTAS_PARAMETRIZADO;

      DELETE FROM SSI_ANEXOS_RESPUESTAS r
         WHERE
            EXISTS ( -- * ...
               SELECT 1 FROM SSI_ANEXOS_PREGUNTAS p
               WHERE
                  p.SI_ID_SERVICIO = p_id_servicio
                  AND p.AP_NUM_ANEXO = p_num_anexo
                  AND p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
            )
            AND r.SF_ID_FASE = p_fase
            AND (r.PF_ID_FAMILIA = p_id_familia OR r.FI_ID_INTEGRANTE = p_id_integrante);

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT TRAN_ELIMINAR_ANEXO_RESPUESTAS_PARAMETRIZADO;
         DBMS_OUTPUT.PUT_LINE('Error al eliminar las respuestas: ' || SQLERRM);
         RAISE;
   END;

END;
/

-- * 21.2 Llamar al procedimiento almacenado
DECLARE
BEGIN
   USP_ELIMINAR_ANEXO_RESPUESTAS_PARAMETRIZADO(2, 1, 1, 116, NULL);
END;
/

--

-- ============================================================================================================================== 


/*
*     ░  22. Reporte de matríz de atenciones e intervenciones estrategia Familias Igualitarias
* ============================================================================================================================== */

-- * 22.1 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_GENERAR_REPORTE_INTERVENCIONES_ESTRATEGICA_FAMILIAS_IGUALITARIAS(
   p_resultado OUT SYS_REFCURSOR
)
AS
   v_id_servicio NUMBER := 2;
   v_preguntas_resultado_agg CLOB := '';
   v_query_pivot CLOB := '';
BEGIN

      -- * 1. Convierte las preguntas de resutados del grupo(-4) en un string csv.
      SELECT 
         -- LISTAGG('''Ficha-' || LPAD(p.AP_NUM_ANEXO, 2, '0') || ': ' || UPPER(TRIM(af.SF_NOMBRE)) || ' ' || UPPER(TRIM(p.AP_PREGUNTA)) || '''', ',') 
         LISTAGG('''' || p.AP_NUM_ANEXO || '-' || af.SF_ID_FASE || '-' || UPPER(TRIM(p.AP_PREGUNTA) || ''''), ',') 
         WITHIN GROUP(ORDER BY af.SF_ID_FASE, p.AP_NUM_PREGUNTA)

         INTO v_preguntas_resultado_agg
      FROM SSI_ANEXOS_PREGUNTAS p
      JOIN SSI_ANEXO_FASES af ON p.AP_NUM_ANEXO = af.SF_NUM_ANEXO
                              AND af.SF_ID_SERVICIO = v_id_servicio
      WHERE
         p.SI_ID_SERVICIO = v_id_servicio -- * PUNCHE
         AND p.AP_NUM_ANEXO IN (9, 10, 11) -- * Diagnostico familiar, FFSIL y TSV
         AND p.AP_NUM_GRUPO = -4 -- * Grupo resultados
         AND (
            p.AP_ID_PREGUNTA = 1666 -- * Pregunta: Diagnóstico - Ficha 9
            OR p.AP_ID_PREGUNTA = 1480 -- * Pregunta: Diagnóstico - Ficha 10
            OR p.AP_ID_PREGUNTA = 1482 -- * Pregunta: Diagnóstico - Ficha 11
         );


      -- * 2. Final: ...
      v_query_pivot := '
               SELECT pv.* FROM (

                     SELECT
                        (
                           SELECT cf2.CF_CODIGO FROM (

                              SELECT 
                                 cf.CF_CODIGO,
                                 ROW_NUMBER() OVER (ORDER BY cf.CF_ID_CODIGO DESC) AS ORDEN_COD
                              FROM SSI_CODIGOS_FAMILIAS cf 
                              WHERE 
                                 cf.PF_ID_FAMILIA = f.PF_ID_FAMILIA
                                 AND cf.CF_ESTADO = 1
                                 AND cf.CF_ELIMINADO = 0

                           ) cf2
                           WHERE cf2.ORDEN_COD = 1

                        ) AS COD_FAM,

                        ''-'' AS NRO_VIV,

                        (
                           SELECT COUNT(1) FROM SSI_FAMILIA_INTEGRANTES i
                           WHERE 
                              i.FI_ESTADO = 1
                              AND i.FI_ELIMINADO = 0
                              AND i.FI_CUIDADOR != 1
                              AND i.PF_ID_FAMILIA = f.PF_ID_FAMILIA
                        ) AS NUM_MIEM_FAM,

                        tf.CATDESCRIPCION AS TIP_FAM,
                        i.FI_TELEFONO AS NRO_TLF,	
                        td.CATDESCRIPCION AS TIP_DOC,	
                        i.FI_NUMERO_DOC AS NRO_DOC,	
                        i.FI_PRIMER_APE AS PRI_APE_FAM,	
                        i.FI_SEGUNDO_APE AS SEG_APE_FAM,	
                        i.FI_NOMBRES AS NOM_FAM,	
                        ts.CATDESCRIPCION AS SEXO,	
                        i.FI_FEC_NAC AS FEC_NAC,	
                        i.FI_EDAD AS EDAD_USU,	
                        ec.CATDESCRIPCION AS EST_CIV,
                        tp.CATDESCRIPCION AS PAR_FAM,	
                        ''-'' AS PAI_FAM,	

                        (
                           CASE
                              WHEN CA_TIENE_DISCAPACIDAD = 1 THEN ''SI''
                              ELSE ''NO''
                           END
                        ) AS TIE_DIS_FAM,	

                        ''-'' AS REG_CONADIS,
                        cd.CATDESCRIPCION AS TIP_DISC,
                        lm.CATDESCRIPCION AS LEN_MAT_FAM,	
                        ''-'' AS LEN_MAT_ESP_FAM,	
                        ''-'' AS AUT_IDE_ET_FAM,	
                        ''-'' AS AUT_IDE_ET_ESP_FAM,	
                        gi.CATDESCRIPCION AS GRAD_INST,	
                        co .CATDESCRIPCION AS OCU_FAM,	
                        ss .CATDESCRIPCION AS TIP_SEG_SAL,

                        -- (''Ficha-'' || LPAD(p.AP_NUM_ANEXO, 2, ''0'') || '': '' || UPPER(TRIM(af.SF_NOMBRE)) || '' '' || UPPER(TRIM(p.AP_PREGUNTA))) AS PREGUNTA,
                        ('''' || p.AP_NUM_ANEXO || ''-'' || af.SF_ID_FASE || ''-'' || UPPER(TRIM(p.AP_PREGUNTA)) || '''') AS PREGUNTA,
                        r.AR_RESPUESTA AS RESPUESTA,
                        TO_CHAR(f.PF_FEC_REGISTRA, ''DD/MM/YYYY'') AS FEC_REGISTRO_FAMILIA

                     FROM SSI_ZONA_INTERVENCION z
                     JOIN SSI_POTENCIALES_FAMILIAS f ON z.ZO_ID_ZONA = f.ZO_ID_ZONA
                     JOIN SSI_FAMILIA_INTEGRANTES i ON f.PF_ID_FAMILIA = i.PF_ID_FAMILIA
                     LEFT JOIN TGCATALOGO tf ON i.CA_ID_TIPO_FAMILIA = tf.IDCATALOGO
                     LEFT JOIN TGCATALOGO td ON i.CA_ID_TIPDOC = td.IDCATALOGO
                     LEFT JOIN TGCATALOGO ts ON i.CA_ID_SEXO = ts.IDCATALOGO
                     LEFT JOIN TGCATALOGO ec ON i.CA_ID_ESTADO_CIVIL = ec.IDCATALOGO
                     LEFT JOIN TGCATALOGO tp ON i.CA_ID_PARENTESCO = tp.IDCATALOGO
                     LEFT JOIN TGCATALOGO cd ON i.CA_ID_DISCAPACIDAD = cd.IDCATALOGO
                     LEFT JOIN TGCATALOGO lm ON i.CA_ID_LENGUA_MATERNA = lm.IDCATALOGO
                     LEFT JOIN TGCATALOGO gi ON i.CA_ID_GRADO_INST = gi.IDCATALOGO
                     LEFT JOIN TGCATALOGO co ON i.CA_ID_OCUPACION = co.IDCATALOGO
                     LEFT JOIN TGCATALOGO ss ON i.CA_ID_TIPO_SEGURO = ss.IDCATALOGO
                     JOIN SSI_ANEXOS_RESPUESTAS r ON f.PF_ID_FAMILIA = r.PF_ID_FAMILIA
                     JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
                     JOIN SSI_ANEXO_FASES af ON r.SF_ID_FASE = af.SF_ID_FASE
                     WHERE 
                        f.PF_ESTADO = 1
                        AND f.PF_ELIMINADO = 0
                        AND i.FI_ESTADO = 1
                        AND i.FI_ELIMINADO = 0
                        AND i.FI_CUIDADOR = 1
                        AND p.SI_ID_SERVICIO = ' || v_id_servicio || '
                        AND p.AP_NUM_ANEXO IN (9, 10, 11)
                        AND p.AP_NUM_GRUPO = -4

                  ) f
                  PIVOT (
                     MAX(RESPUESTA)
                     FOR PREGUNTA IN (' || v_preguntas_resultado_agg || ') 
                  ) pv
                  ORDER BY pv.FEC_REGISTRO_FAMILIA ASC';

      OPEN p_resultado FOR v_query_pivot;

END;
/


-- ! COMMIT;


-- * 22.2 Llamar al procedimiento almacenado
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_GENERAR_REPORTE_INTERVENCIONES_ESTRATEGIA_FAMILIAS_IGUALITARIAS(c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ? Test
DECLARE
   v_agg CLOB := '';
BEGIN
   SELECT 
      LISTAGG('''' || p.AP_PREGUNTA || '''', ',') WITHIN GROUP(ORDER BY p.AP_NUM_PREGUNTA ASC) INTO v_agg
   FROM SSI_ANEXOS_PREGUNTAS p
   WHERE
      p.SI_ID_SERVICIO = 2
      AND p.AP_NUM_ANEXO IN (9, 10, 11)
      AND p.AP_NUM_GRUPO = -4
      AND (
         p.AP_ID_PREGUNTA = 1666 -- * Pregunta: Diagnostico - Ficha 9
         OR p.AP_ID_PREGUNTA = 1480 -- * Pregunta: Diagnostico - Ficha 10
         OR p.AP_ID_PREGUNTA = 1482 -- * Pregunta: Diagnostico - Ficha 10
      );

   DBMS_OUTPUT.PUT_LINE(v_agg);
END;
/

-- ============================================================================================================================== 



/*
*     ░  23. Reporte de fichas parametrizadas
* ============================================================================================================================== */

-- * 23.1 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_GENERAR_REPORTE_FICHA_PARAMETRIZADO(
   p_id_Servicio IN NUMBER,
   p_num_anexo IN NUMBER,
   p_resultado OUT SYS_REFCURSOR
)
AS
   v_preguntas_agg CLOB := '';
   v_query_pivot CLOB := '';
BEGIN

      -- * 1. Convierte las preguntas de resutados del grupo(-4) en un string csv.
      SELECT 
         LISTAGG(p.AP_ID_PREGUNTA, ',') WITHIN GROUP(ORDER BY p.AP_ID_PREGUNTA)
         INTO v_preguntas_agg
      FROM SSI_ANEXOS_PREGUNTAS p
      WHERE
         p.SI_ID_SERVICIO = p_id_servicio
         AND p.AP_NUM_ANEXO = p_num_anexo
         AND p.AP_NUM_GRUPO NOT IN (0, -1, -2, -3, -5);

      v_query_pivot := '
               SELECT pv.* FROM (

                  SELECT
                     (
                        SELECT cf2.CF_CODIGO FROM (

                           SELECT 
                              cf.CF_CODIGO,
                              ROW_NUMBER() OVER (ORDER BY cf.CF_ID_CODIGO DESC) AS ORDEN_COD
                           FROM SSI_CODIGOS_FAMILIAS cf 
                           WHERE 
                              cf.PF_ID_FAMILIA = r.PF_ID_FAMILIA
                              AND cf.CF_ESTADO = 1
                              AND cf.CF_ELIMINADO = 0

                        ) cf2
                        WHERE cf2.ORDEN_COD = 1

                     ) AS COD_FAMILIA,
                     p.AP_ID_PREGUNTA AS ID_PREGUNTA,
                     r.AR_RESPUESTA AS RESPUESTA,
                     r.SF_ID_FASE AS ID_FASE,
                     TO_CHAR(r.AR_FECHA_REGISTRA, ''DD/MM/YYYY'') AS FEC_APLICACION

                  FROM SSI_ANEXOS_RESPUESTAS r 
                  JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
                  WHERE
                     p.SI_ID_SERVICIO = ' || p_id_servicio ||
                     ' AND p.AP_NUM_ANEXO = ' || p_num_anexo ||

               ' ) f
               PIVOT (
                  MAX(RESPUESTA)
                  FOR ID_PREGUNTA IN (' || v_preguntas_agg || ') 
               ) pv
               ORDER BY pv.COD_FAMILIA, pv.ID_FASE';

      -- * 2. ...
      OPEN p_resultado FOR v_query_pivot;

END;
/


-- ! COMMIT;

-- * 22.2 Llamar al procedimiento almacenado
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_GENERAR_REPORTE_FICHA_PARAMETRIZADO(2, 27, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ============================================================================================================================== 


/*
*  ░  24. Buscar personal por parametros
* ============================================================================================================================== */

-- * 24.2 Crea un procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_LISTAR_PERSONAL_POR_PARAMETROS
(
   p_numero_documento IN VARCHAR2,
   p_nombres IN VARCHAR2,
   c_resultado_busqueda OUT SYS_REFCURSOR
)
IS
BEGIN

   OPEN c_resultado_busqueda FOR
      SELECT 
         p.IDPERSONA,
         u.IDPERSONAL,
         p.PERNOMBRE AS NOMBRES,
         p.PERAPEPATERNO AS PRIMERAPE,
         p.PERAPEMATERNO AS SEGUNDOAPE,
         c2.CATDESCRIPCION AS DOCUMENTO,
         p.PERNRODOCUMENTO AS NUMERODOC,
         pa.PA_NACIONALIDAD AS NACIONALIDAD,
         c.CATDESCRIPCION AS ESTADOCIVIL,
         p.PERFECNACIMIENTO AS FECNACIMIENTO,
         CASE
            WHEN p.PERSEXO = 1 THEN 'MASCULINO'
            WHEN p.PERSEXO = 2 THEN 'FEMENINO'
            ELSE 'NO DEFINIDO'
         END AS SEXO,
         p.PERDIRECCION AS DIRECCION,
         p.PERREFERENCIA AS REFERENCIA,
         p.PERTELEFONO AS TELEFONO,
         p.PERCORREO AS CORREO,
         ca.CP_NOMBRE AS CARRERA
      FROM TGPERSONA p
      JOIN TRPERSONAL u ON p.IDPERSONA = u.PRHPERSONA
      LEFT JOIN TGCATALOGO c ON p.PERESTADOCIVIL = c.IDCATALOGO -- * Estado Civil
      LEFT JOIN TGCATALOGO c2 ON p.PERDOCUMENTO = c2.IDCATALOGO -- * Tipo Documento
      LEFT JOIN TG_CARRERA_PROFESIONAL ca ON u.PRHPROFESION = ca.IDCARRERA_PROFESIONAL
      LEFT JOIN TG_PAIS pa ON p.PERNACPAIS = pa.IDPAIS
      WHERE
         (p.PERNRODOCUMENTO = TRIM(p_numero_documento) OR p_numero_documento IS NULL)
         AND (
            UPPER(p.PERNOMBRE) LIKE '%' || UPPER(TRIM(p_nombres)) || '%'
            OR UPPER(p.PERAPEPATERNO) LIKE '%' || UPPER(TRIM(p_nombres)) || '%'
            OR UPPER(p.PERAPEMATERNO) LIKE '%' || UPPER(TRIM(p_nombres)) || '%'
            OR p_nombres IS NULL
         );

END;
/

-- ! COMMIT;

-- 24.3 Llamar al procedimiento almacenado:
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   -- USP_LISTAR_PERSONAL_POR_PARAMETROS('46392613', NULL, c_resultado_busqueda);
   USP_LISTAR_PERSONAL_POR_PARAMETROS(NULL, 'rooy', c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/

-- ==============================================================================================================================




/*
?     12/01/2026
*
*     ░  25. Reporte de matríz de Familias Igualitarias
* ============================================================================================================================== */

-- * 25.1 Crear el procedimiento almacenado
CREATE OR REPLACE PROCEDURE USP_GENERAR_REPORTE_MATRIZ_FAMILIAS_IGUALITARIAS(
   p_resultado OUT SYS_REFCURSOR
)
AS
   v_id_servicio NUMBER := 2;
BEGIN

      OPEN p_resultado FOR
         WITH cte_zonas_intervencion AS ( -- * 1. Zona Intervención

            SELECT
               (
                  LPAD(ROW_NUMBER() OVER (ORDER BY z.ZO_ID_ZONA ASC), 5, '0')
               ) AS "N°",
               z.ZO_DESCRIPCION AS ZONA,
               z.UBI_ID_UBIGEO AS UBIGEO_ZONA,
               uz.U_DEPARTAMENTO AS DEPARTAMENTO_ZONA,
               uz.U_PROVINCIA AS PROVINCIA_ZONA,
               uz.U_DISTRITO AS DISTRITO_ZONA,
               '-' AS TEL_ZONA,
               i.FI_CENTRO_POBLADO AS CENTRO_POBLADO,

               -- * 2. Aliados
               a.AL_TIPO_ALIADO AS TIPO_INS_ALIADO,
               ia.INSNOMBRE AS NOM_INST_ALIADO,
               ua.U_DEPARTAMENTO AS DEP_INST_ALIADO,
               ua.U_PROVINCIA AS PROV_INST_ALIADO,
               ua.U_DISTRITO AS DIST_INST_ALIADO,
               a.AL_TELEFONO AS TEL_INST_ALIADO,

               -- * Aux
               f.PF_ID_FAMILIA,
               i.FI_ID_INTEGRANTE

            FROM SSI_ZONA_INTERVENCION z
            JOIN SSI_POTENCIALES_FAMILIAS f ON z.ZO_ID_ZONA = f.ZO_ID_ZONA
            JOIN SSI_FAMILIA_INTEGRANTES i ON f.PF_ID_FAMILIA = i.PF_ID_FAMILIA
            LEFT JOIN SSI_UBIGEO_NOMBRES uz ON z.UBI_ID_UBIGEO = uz.U_ID_UBIGEO
            LEFT JOIN SSI_ALIADOS a ON f.AL_ID_ALIADO = a.AL_ID_ALIADO
            LEFT JOIN TGINSTITUCION ia ON a.INS_ID_INSTITUCION = ia.IDINSTITUCION
            LEFT JOIN SSI_UBIGEO_NOMBRES ua ON a.UBI_ID_UBIGEO = ua.U_ID_UBIGEO
            WHERE 
               f.PF_ESTADO = 1
               AND f.PF_ELIMINADO = 0
               AND i.FI_ESTADO = 1
               AND i.FI_ELIMINADO = 0
               AND i.FI_CUIDADOR = 1 -- * Cuidador
               AND z.SI_ID_SERVICIO = v_id_servicio

         ), cte_ficha_identificacion_familia AS (-- * 2. FICHA DE IDENTIFICACIÓN DE FAMILIA
         
               SELECT pv.* FROM (

                  SELECT

                     TRIM(UPPER(p.AP_PREGUNTA)) AS PREGUNTA,
                     (
                        CASE 
                           WHEN (r.AR_RESPUESTA = 1) THEN 'SI'
                           ELSE 'NO'
                        END
                        
                     ) AS RESPUESTA,
                     TO_CHAR(r.AR_FECHA_REGISTRA, 'DD/MM/YYYY') AS FEC_REGISTRO_IDENTIFICACION_FAMILIA,

                     -- Aux
                     r.PF_ID_FAMILIA

                  FROM SSI_ANEXOS_RESPUESTAS r
                  JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
                  WHERE 
                     p.AP_ID_PREGUNTA IN (410, 414, 415, 416, 423)

               ) fi
               PIVOT (
                  MAX(RESPUESTA)
                  FOR PREGUNTA IN (
                     'NEGLIGENCIA O DESCUIDO', -- 410
                     'BAJO SOPORTE ESCOLAR', -- 414
                     'INADECUADA ORGANIZACIÓN FAMILIAR', -- 415
                     'CONFLICTO ENTRE LOS INTEGRANTES DE LA FAMILIA', -- 416
                     'CARENCIA DE RED FAMILIAR Y SOCIAL.' -- 423
                  )
               ) pv

         ), cte_informacion_cuidador_principal AS ( -- * 3 ...

            SELECT
               (
                  SELECT cf2.CF_CODIGO FROM (

                     SELECT 
                        cf.CF_CODIGO,
                        ROW_NUMBER() OVER (ORDER BY cf.CF_ID_CODIGO DESC) AS ORDEN_COD
                     FROM SSI_CODIGOS_FAMILIAS cf 
                     WHERE 
                        cf.PF_ID_FAMILIA = f.PF_ID_FAMILIA
                        AND cf.CF_ESTADO = 1
                        AND cf.CF_ELIMINADO = 0

                  ) cf2
                  WHERE cf2.ORDEN_COD = 1

               ) AS COD_FAM,
               i.FI_NOMBRES AS NOM_CUIDADOR,
               i.FI_PRIMER_APE AS PRI_APE_ACUIDADOR,	
               i.FI_SEGUNDO_APE AS SEG_APE_ACUIDADOR,	
               td.CATDESCRIPCION AS TIP_DOC_CUIDADOR,
               i.FI_NUMERO_DOC AS NRO_DOC_CUIDADOR,
               ts.CATDESCRIPCION AS SEXO_CUIDADOR,
               i.FI_FEC_NAC AS FEC_NAC_CUIDADOR,
               i.FI_EDAD AS EDAD_CUIDADOR,
               i.FI_TELEFONO AS NRO_TLF_CUIDADOR,
               ec.CATDESCRIPCION AS EST_CIV_CUIDADOR,
               tp.CATDESCRIPCION AS PAR_FAM_CUIDADOR,
               /* (
                  CASE
                     WHEN cd.CATDESCRIPCION IS NOT NULL THEN 'SI'
                     ELSE 'NO'
                  END
               )  AS TIE_DIS_FAM, */
               (
                  CASE
                     WHEN CA_TIENE_DISCAPACIDAD = 1 THEN 'SI'
                     ELSE 'NO'
                  END
               ) AS TIE_DIS_FAM,
               '-' AS REG_CONADIS,
               cd.CATDESCRIPCION AS TIP_DISC,
               lm.CATDESCRIPCION AS LEN_MAT_FAM,	
               '-' AS LEN_MAT_ESP_FAM,	
               '-' AS AUT_IDE_ET_FAM,	
               '-' AS AUT_IDE_ET_ESP_FAM,	
               gi.CATDESCRIPCION AS GRAD_INST,
               co .CATDESCRIPCION AS OCU_FAM,
               ss .CATDESCRIPCION AS TIP_SEG_SAL,
               (
                  SELECT COUNT(1) FROM SSI_FAMILIA_INTEGRANTES i
                  WHERE 
                     i.FI_ESTADO = 1
                     AND i.FI_ELIMINADO = 0
                     AND i.FI_CUIDADOR != 1
                     AND i.PF_ID_FAMILIA = f.PF_ID_FAMILIA
               ) AS NUM_MIEM_FAM,
               tf.CATDESCRIPCION AS TIP_FAM,

               -- Aux
               f.PF_ID_FAMILIA,
               i.FI_ID_INTEGRANTE

            FROM SSI_POTENCIALES_FAMILIAS f
            JOIN SSI_FAMILIA_INTEGRANTES i ON f.PF_ID_FAMILIA = i.PF_ID_FAMILIA
            LEFT JOIN TGCATALOGO tf ON i.CA_ID_TIPO_FAMILIA = tf.IDCATALOGO
            LEFT JOIN TGCATALOGO td ON i.CA_ID_TIPDOC = td.IDCATALOGO
            LEFT JOIN TGCATALOGO ts ON i.CA_ID_SEXO = ts.IDCATALOGO
            LEFT JOIN TGCATALOGO ec ON i.CA_ID_ESTADO_CIVIL = ec.IDCATALOGO
            LEFT JOIN TGCATALOGO tp ON i.CA_ID_PARENTESCO = tp.IDCATALOGO
            LEFT JOIN TGCATALOGO cd ON i.CA_ID_DISCAPACIDAD = cd.IDCATALOGO
            LEFT JOIN TGCATALOGO lm ON i.CA_ID_LENGUA_MATERNA = lm.IDCATALOGO
            LEFT JOIN TGCATALOGO gi ON i.CA_ID_GRADO_INST = gi.IDCATALOGO
            LEFT JOIN TGCATALOGO co ON i.CA_ID_OCUPACION = co.IDCATALOGO
            LEFT JOIN TGCATALOGO ss ON i.CA_ID_TIPO_SEGURO = ss.IDCATALOGO
            WHERE f.SI_ID_SERVICIO = v_id_servicio

         ), cte_ficha_diagnostico_familiar AS (-- * 4. FICHA DIAGNÓSTICO DE LA FAMILIAR
         
               SELECT pv.* FROM (

                  SELECT

                     ('DIAGFAM - ' || UPPER(TRIM(af.SF_NOMBRE)) || ': ' || UPPER(TRIM(p.AP_PREGUNTA))) AS PREGUNTA,
                     r.AR_RESPUESTA AS RESPUESTA,
                     TO_CHAR(r.AR_FECHA_REGISTRA, 'DD/MM/YYYY') AS FEC_REGISTRO_DIAGNOSTICO_FAMILIAR,

                     -- Aux
                     r.PF_ID_FAMILIA

                  FROM SSI_ANEXOS_RESPUESTAS r
                  JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
                  JOIN SSI_ANEXO_FASES af ON r.SF_ID_FASE = af.SF_ID_FASE
                  WHERE 
                     p.SI_ID_SERVICIO = v_id_servicio -- * PUNCHE
                     -- AND p.AP_NUM_ANEXO IN (9, 10, 11) -- * Diagnostico familiar, FFSIL y TSV
                     AND p.AP_NUM_ANEXO = 9 -- * Diagnostico familiar
                     AND p.AP_NUM_GRUPO = -4 -- * Grupo resultados */

               ) fi
               PIVOT (
                  MAX(RESPUESTA)
                  FOR PREGUNTA IN (

                     -- Pre evaluación
                     'DIAGFAM - PRE EVALUACIÓN: FUNCIÓN DE CUIDADO',
                     'DIAGFAM - PRE EVALUACIÓN: FUNCIÓN FORMADORA',
                     'DIAGFAM - PRE EVALUACIÓN: FUNCIÓN AFECTIVA',
                     'DIAGFAM - PRE EVALUACIÓN: FUNCIÓN SOCIALIZADORA',
                     'DIAGFAM - PRE EVALUACIÓN: FUNCIÓN DE SEGURIDAD ECONÓMICA',
                     'DIAGFAM - PRE EVALUACIÓN: RELACIONES DE PAREJA',
                     'DIAGFAM - PRE EVALUACIÓN: RELACIONES PARENTALES',
                     'DIAGFAM - PRE EVALUACIÓN: RELACIONES ENTRE PARIENTES',
                     'DIAGFAM - PRE EVALUACIÓN: ENTORNO COMUNITARIO LIBRE DE VIOLENCIA',
                     'DIAGFAM - PRE EVALUACIÓN: ENTORNO COMUNITARIO LIBRE QUE PROMUEVE EJERCICIO DE DERECHOS',
                     'DIAGFAM - PRE EVALUACIÓN: DIAGNOSTICO PROTECCION',
                     'DIAGFAM - PRE EVALUACIÓN: % PROTECCION',
                     'DIAGFAM - PRE EVALUACIÓN: DIAGNOSTICO RIESGO',
                     'DIAGFAM - PRE EVALUACIÓN: % RIESGO',
                     'DIAGFAM - PRE EVALUACIÓN: PUNTAJE',

                     -- Post evaluación
                     'DIAGFAM - POST EVALUACIÓN: FUNCIÓN DE CUIDADO',
                     'DIAGFAM - POST EVALUACIÓN: FUNCIÓN FORMADORA',
                     'DIAGFAM - POST EVALUACIÓN: FUNCIÓN AFECTIVA',
                     'DIAGFAM - POST EVALUACIÓN: FUNCIÓN SOCIALIZADORA',
                     'DIAGFAM - POST EVALUACIÓN: FUNCIÓN DE SEGURIDAD ECONÓMICA',
                     'DIAGFAM - POST EVALUACIÓN: RELACIONES DE PAREJA',
                     'DIAGFAM - POST EVALUACIÓN: RELACIONES PARENTALES',
                     'DIAGFAM - POST EVALUACIÓN: RELACIONES ENTRE PARIENTES',
                     'DIAGFAM - POST EVALUACIÓN: ENTORNO COMUNITARIO LIBRE DE VIOLENCIA',
                     'DIAGFAM - POST EVALUACIÓN: ENTORNO COMUNITARIO LIBRE QUE PROMUEVE EJERCICIO DE DERECHOS',
                     'DIAGFAM - POST EVALUACIÓN: DIAGNOSTICO PROTECCION',
                     'DIAGFAM - POST EVALUACIÓN: % PROTECCION',
                     'DIAGFAM - POST EVALUACIÓN: DIAGNOSTICO RIESGO',
                     'DIAGFAM - POST EVALUACIÓN: % RIESGO',
                     'DIAGFAM - POST EVALUACIÓN: PUNTAJE'
                  )
               ) pv

         ), cte_ficha_ffsil AS (-- * 5. FICHA FFSIL
         
               SELECT pv.* FROM (

                  SELECT

                     ('FFSIL - ' || UPPER(TRIM(af.SF_NOMBRE)) || ': ' || UPPER(TRIM(p.AP_PREGUNTA))) AS PREGUNTA,
                     r.AR_RESPUESTA AS RESPUESTA,
                     TO_CHAR(r.AR_FECHA_REGISTRA, 'DD/MM/YYYY') AS FEC_REGISTRO_FFSIL,

                     -- Aux
                     r.PF_ID_FAMILIA

                  FROM SSI_ANEXOS_RESPUESTAS r
                  JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
                  JOIN SSI_ANEXO_FASES af ON r.SF_ID_FASE = af.SF_ID_FASE
                  WHERE 
                     p.SI_ID_SERVICIO = v_id_servicio -- * PUNCHE
                     -- AND p.AP_NUM_ANEXO IN (9, 10, 11) -- * Diagnostico familiar, FFSIL y TSV
                     AND p.AP_NUM_ANEXO = 10 -- * FFSIL
                     AND p.AP_NUM_GRUPO = -4 -- * Grupo resultados

               ) fi
               PIVOT (
                  MAX(RESPUESTA)
                  FOR PREGUNTA IN (
                     -- Pre evaluación
                     'FFSIL - PRE EVALUACIÓN: PUNTAJE',
                     'FFSIL - PRE EVALUACIÓN: CALIFICACIÓN',
                     'FFSIL - PRE EVALUACIÓN: COHESIÓN',
                     'FFSIL - PRE EVALUACIÓN: ARMONÍA',
                     'FFSIL - PRE EVALUACIÓN: COMUNICACIÓN',
                     'FFSIL - PRE EVALUACIÓN: PERMEABILIDAD',
                     'FFSIL - PRE EVALUACIÓN: AFECTIVIDAD',
                     'FFSIL - PRE EVALUACIÓN: ROLES',
                     'FFSIL - PRE EVALUACIÓN: ADAPTABILIDAD',

                     -- Post evaluación
                     'FFSIL - POST EVALUACIÓN: PUNTAJE',
                     'FFSIL - POST EVALUACIÓN: CALIFICACIÓN',
                     'FFSIL - POST EVALUACIÓN: COHESIÓN',
                     'FFSIL - POST EVALUACIÓN: ARMONÍA',
                     'FFSIL - POST EVALUACIÓN: COMUNICACIÓN',
                     'FFSIL - POST EVALUACIÓN: PERMEABILIDAD',
                     'FFSIL - POST EVALUACIÓN: AFECTIVIDAD',
                     'FFSIL - POST EVALUACIÓN: ROLES',
                     'FFSIL - POST EVALUACIÓN: ADAPTABILIDAD'
                  )
               ) pv

         ), cte_ficha_tsv AS (-- * 6. FICHA TSV
         
               SELECT pv.* FROM (

                  SELECT

                     ('TSV - ' ||UPPER(TRIM(af.SF_NOMBRE)) || ': ' || UPPER(TRIM(p.AP_PREGUNTA))) AS PREGUNTA,
                     r.AR_RESPUESTA AS RESPUESTA,
                     TO_CHAR(r.AR_FECHA_REGISTRA, 'DD/MM/YYYY') AS FEC_REGISTRO_TSV,

                     -- Aux
                     r.PF_ID_FAMILIA

                  FROM SSI_ANEXOS_RESPUESTAS r
                  JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
                  JOIN SSI_ANEXO_FASES af ON r.SF_ID_FASE = af.SF_ID_FASE
                  WHERE 
                     p.SI_ID_SERVICIO = v_id_servicio -- * PUNCHE
                     -- AND p.AP_NUM_ANEXO IN (9, 10, 11) -- * Diagnostico familiar, FFSIL y TSV
                     AND p.AP_NUM_ANEXO = 11 -- * TSV
                     AND p.AP_NUM_GRUPO = -4 -- * Grupo resultados

               ) fi
               PIVOT (
                  MAX(RESPUESTA)
                  FOR PREGUNTA IN (
                     -- Pre evaluación
                     'TSV - PRE EVALUACIÓN: PUNTAJE',
                     'TSV - PRE EVALUACIÓN: CALIFICACIÓN',
                     'TSV - PRE EVALUACIÓN: DIMENSIÓN DE ACTITUDES (PUNTUACIÓN)',
                     'TSV - PRE EVALUACIÓN: DIMENSIÓN DE ACTITUDES (NIVEL)',
                     'TSV - PRE EVALUACIÓN: DIMENSIÓN DE CREENCIAS  (PUNTUACIÓN)',
                     'TSV - PRE EVALUACIÓN: DIMENSIÓN DE CREENCIAS  (NIVEL)',
                     'TSV - PRE EVALUACIÓN: DIMENSIÓN IMAGINARIOS (PUNTUACIÓN)',
                     'TSV - PRE EVALUACIÓN: DIMENSIÓN IMAGINARIOS (NIVEL)',

                     -- Post evaluación
                     'TSV - POST EVALUACIÓN: PUNTAJE',
                     'TSV - POST EVALUACIÓN: CALIFICACIÓN',
                     'TSV - POST EVALUACIÓN: DIMENSIÓN DE ACTITUDES (PUNTUACIÓN)',
                     'TSV - POST EVALUACIÓN: DIMENSIÓN DE ACTITUDES (NIVEL)',
                     'TSV - POST EVALUACIÓN: DIMENSIÓN DE CREENCIAS  (PUNTUACIÓN)',
                     'TSV - POST EVALUACIÓN: DIMENSIÓN DE CREENCIAS  (NIVEL)',
                     'TSV - POST EVALUACIÓN: DIMENSIÓN IMAGINARIOS (PUNTUACIÓN)',
                     'TSV - POST EVALUACIÓN: DIMENSIÓN IMAGINARIOS (NIVEL)'
                  )
               ) pv

         ), cte_det_patfam AS ( -- * 7. Sesiones y Talleres

            SELECT
            
               (
                  SELECT COUNT(1) FROM SSI_PATFAM p
                  JOIN SSI_DET_PATFAM dp ON p.PA_ID_PATFAM = dp.PA_ID_PATFAM
                  WHERE
                     dp.DP_ESTADO = 1
                     AND dp.DP_ELIMINADO = 0
                     AND dp.SE_ID_SESION IS NOT NULL
                     AND p.PF_ID_FAMILIA = f.PF_ID_FAMILIA
               ) AS TOTAL_SESIONES,
               (
                  SELECT COUNT(1) FROM SSI_PATFAM p
                  JOIN SSI_DET_PATFAM dp ON p.PA_ID_PATFAM = dp.PA_ID_PATFAM
                  LEFT JOIN SSI_TALLERES t ON dp.TA_ID_TALLER = t.TA_ID_TALLER
                  WHERE
                     dp.DP_ESTADO = 1
                     AND dp.DP_ELIMINADO = 0
                     AND (t.TA_ID_TALLER IS NOT NULL AND t.TA_NOMBRE != 'No aplica')
                     AND p.PF_ID_FAMILIA = f.PF_ID_FAMILIA
               ) AS TOTAL_TALLERES,

               -- * Aux
               f.PF_ID_FAMILIA

            FROM SSI_POTENCIALES_FAMILIAS f
            WHERE 
               f.SI_ID_SERVICIO = v_id_servicio -- * PUNCHE
            
         ), cte_ficha_emprendimiento AS (-- * 8. Ficha de emprendimiento y capacitacion
         
               SELECT

                  COUNT(1) AS TOTAL_FICHA_EMPRENDIMIENTO,

                  -- * Aux
                  g.PF_ID_FAMILIA
               FROM (

                  SELECT
                     r.PF_ID_FAMILIA,
                     r.FI_ID_INTEGRANTE
                  FROM SSI_ANEXOS_RESPUESTAS r
                  JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
                  WHERE 
                     p.SI_ID_SERVICIO = v_id_servicio -- * PUNCHE
                     AND p.AP_NUM_ANEXO = 12 -- * Ficha Emprendimiento
                  GROUP BY
                     r.PF_ID_FAMILIA,
                     r.FI_ID_INTEGRANTE

               ) g
               GROUP BY
                  g.PF_ID_FAMILIA

         ), cte_ficha_derivacion_referencia AS (-- * 9. Ficha de derivación y/o referencia
         
               SELECT
                  pv.*
               FROM (

                  SELECT
                     r.PF_ID_FAMILIA,
                     r.FI_ID_INTEGRANTE,
                     (
                        CASE 
                           WHEN r.AR_RESPUESTA = '1' THEN 'TOTAL FICHA DERIVACIÓN'
                           WHEN r.AR_RESPUESTA = '2' THEN 'TOTAL FICHA REFERENCIA'
                        END
                     ) AS AR_RESPUESTA
                  FROM SSI_ANEXOS_RESPUESTAS r
                  JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
                  WHERE 
                     p.SI_ID_SERVICIO = v_id_servicio -- * PUNCHE
                     AND p.AP_NUM_ANEXO = 20 -- * Ficha de derivación y/o referencia
                     AND r.AP_ID_PREGUNTA = 1627 -- * IDENTIFICACIÓN DEL INTEGRANTE DE LA FAMILIA QUE REQUIERE:

               ) f1
               PIVOT (
                  COUNT(FI_ID_INTEGRANTE)
                  FOR AR_RESPUESTA IN (
                     'TOTAL FICHA DERIVACIÓN', -- ? 1 DERIVACIÓN
                     'TOTAL FICHA REFERENCIA' -- ? 2 REFERENCIA
                  )
               ) pv


         ), cte_ficha_compromiso AS ( -- * ?. Ficha de compromiso

            SELECT
            
               (
                  CASE
                     WHEN f.PF_FAMILIA_APTA = 1 THEN 'SI'
                     ELSE 'NO'
                  END
               ) AS FAM_APTA,
               (TO_CHAR(SYSDATE, 'DD/MM/YYYY')) AS FEC_COMPROMISO,

               -- * Aux
               f.PF_ID_FAMILIA

            FROM SSI_POTENCIALES_FAMILIAS f
            /* FROM SSI_ANEXOS_RESPUESTAS r
            JOIN SSI_ANEXOS_PREGUNTAS p ON p.AP_ID_PREGUNTA = r.AP_ID_PREGUNTA
            JOIN SSI_ANEXO_FASES af ON r.SF_ID_FASE = af.SF_ID_FASE */
            WHERE 
               f.SI_ID_SERVICIO = v_id_servicio -- * PUNCHE
               -- AND p.AP_NUM_ANEXO IN (9, 10, 11) -- * Diagnostico familiar, FFSIL y TSV
               /* AND p.AP_NUM_ANEXO = 11 -- * TSV
               AND p.AP_NUM_GRUPO = -4 -- * Grupo resultados */
            
            
         ) -- * Final
         SELECT 
            *
         FROM cte_zonas_intervencion cte_1
         LEFT JOIN cte_ficha_identificacion_familia cte_2 ON cte_1.PF_ID_FAMILIA = cte_2.PF_ID_FAMILIA
         LEFT JOIN cte_informacion_cuidador_principal cte_3 ON cte_1.PF_ID_FAMILIA = cte_3.PF_ID_FAMILIA
                                                            AND cte_1.FI_ID_INTEGRANTE = cte_3.FI_ID_INTEGRANTE
         LEFT JOIN cte_ficha_diagnostico_familiar cte_4 ON cte_1.PF_ID_FAMILIA = cte_4.PF_ID_FAMILIA
         LEFT JOIN cte_ficha_ffsil cte_5 ON cte_1.PF_ID_FAMILIA = cte_5.PF_ID_FAMILIA
         LEFT JOIN cte_ficha_tsv cte_6 ON cte_1.PF_ID_FAMILIA = cte_6.PF_ID_FAMILIA
         LEFT JOIN cte_det_patfam cte_7 ON cte_1.PF_ID_FAMILIA = cte_7.PF_ID_FAMILIA
         LEFT JOIN cte_ficha_emprendimiento cte_8 ON cte_1.PF_ID_FAMILIA = cte_8.PF_ID_FAMILIA
         LEFT JOIN cte_ficha_derivacion_referencia cte_9 ON cte_1.PF_ID_FAMILIA = cte_9.PF_ID_FAMILIA
         LEFT JOIN cte_ficha_compromiso cte_10 ON cte_1.PF_ID_FAMILIA = cte_10.PF_ID_FAMILIA;

END;
/

-- ! COMMIT;

SELECT * FROM SSI_POTENCIALES_FAMILIAS f
WHERE f.PF_ID_FAMILIA = 101;

-- * 22.2 Llamar al procedimiento almacenado
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_GENERAR_REPORTE_MATRIZ_FAMILIAS_IGUALITARIAS(c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/

-- ? Test
DECLARE
   v_agg CLOB := '';
BEGIN
   SELECT 
      LISTAGG('''' || p.AP_PREGUNTA || '''', ',') WITHIN GROUP(ORDER BY p.AP_NUM_PREGUNTA ASC) INTO v_agg
   FROM SSI_ANEXOS_PREGUNTAS p
   WHERE
      p.SI_ID_SERVICIO = 2
      AND p.AP_NUM_ANEXO IN (9, 10, 11)
      AND p.AP_NUM_GRUPO = -4
      AND (
         p.AP_ID_PREGUNTA = 1666 -- * Pregunta: Diagnostico - Ficha 9
         OR p.AP_ID_PREGUNTA = 1480 -- * Pregunta: Diagnostico - Ficha 10
         OR p.AP_ID_PREGUNTA = 1482 -- * Pregunta: Diagnostico - Ficha 10
      );

   DBMS_OUTPUT.PUT_LINE(v_agg);
END;
/

-- ============================================================================================================================== 