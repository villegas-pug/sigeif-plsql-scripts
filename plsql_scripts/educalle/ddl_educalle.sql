-- * 1. Analisis Exploratorio `EDUCALLE`


-- * 1.1 Unidades

-- `USP_LISTAR_UNIDADES`
SELECT DISTINCT
   IDUNIDADORGANICA AS idUnidad,
   ANX_UNIDAD_ORGANICA AS nombreUnidad
FROM SSI_ANEXO
WHERE 
   NVL(ANX_ELIMINADO, 0) = 0
ORDER BY 
   ANX_UNIDAD_ORGANICA
/

-- * 1.1.1 Actualizar `SP`
CREATE OR REPLACE PROCEDURE USP_LISTAR_UNIDADES_V2 (
    p_id_servicio_padre IN NUMBER,
    c_resultado OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN C_RESULTADO FOR
        SELECT DISTINCT
            a.IDUNIDADORGANICA AS idUnidad,
            a.ANX_UNIDAD_ORGANICA AS nombreUnidad
        FROM SSI_ANEXO a
        WHERE 
            NVL(a.ANX_ELIMINADO, 0) = 0
            AND a.ID_SERVICIO_PADRE = p_id_servicio_padre
        ORDER BY a.ANX_UNIDAD_ORGANICA;
END;
/



-- * 1.2 Servicios

-- `USP_LISTAR_UNIDADES_SERVICIOS`

SELECT 
   DISTINCT
   ANX_ID_SERVICIO AS idServicio,
   ANX_SERVICIO AS nombreServicio
FROM SSI_ANEXO
WHERE 
   IDUNIDADORGANICA = P_ID_UNIDAD_ORGANICA
   AND NVL(ANX_ELIMINADO, 0) = 0
ORDER BY 
   ANX_SERVICIO
/

-- * 1.2.1 Actualizar `SP`
CREATE OR REPLACE PROCEDURE USP_LISTAR_UNIDADES_SERVICIOS_V2 (
    P_ID_UNIDAD_ORGANICA IN NUMBER,
    P_ID_SERVICIO_PADRE IN NUMBER,
    C_RESULTADO OUT SYS_REFCURSOR
)
AS
BEGIN
   OPEN C_RESULTADO FOR
      SELECT 
         DISTINCT
         a.ANX_ID_SERVICIO AS idServicio,
         a.ANX_SERVICIO AS nombreServicio
      FROM SSI_ANEXO a
      WHERE a.IDUNIDADORGANICA = P_ID_UNIDAD_ORGANICA
      AND NVL(a.ANX_ELIMINADO, 0) = 0
      AND a.ID_SERVICIO_PADRE = P_ID_SERVICIO_PADRE
      ORDER BY ANX_SERVICIO;
END;
/

-- ! COMMIT;


-- * 1.3 Espaciones Intervencion

-- * 1.3.1
-- `SP_LISTAR_CENTROS`
SELECT

   -- E.ID_ESP_INTERV AS IDUNIDADORGANICA, -- ! Antes
   E.ID_UNIDADORGANICA_PADRE AS IDUNIDADORGANICA, -- ! Despues
   TO_CHAR(E.ESP_NOMBRE) AS UORNOMBRE,
   NULL AS TIPO_CENTRO,
   DEP.UBILOCALIDAD AS DEPARTAMENTO,
   PROV.UBILOCALIDAD AS PROVINCIA,
   DIST.UBILOCALIDAD AS DISTRITO,
   (
      CASE
         WHEN (E.ID_PERSONAL IS NULL) THEN TO_CHAR(E.ESP_NOMBRE_RESPONSABLE) -- ? Columna Aux
         ELSE (
               PER.PERNOMBRE || ' ' || PER.PERAPEPATERNO || ' ' || PER.PERAPEMATERNO
         )
      END
   ) AS DIRECTOR,
   E.ID_PERSONAL AS IDPERSONAL

FROM SSI_ESP_INTERVENCION E
LEFT JOIN TGUBIGEO DEP ON DEP.UBIDEPARTAMENTO = SUBSTR(E.ESP_UBIGEO, 1, 2)
                        AND DEP.UBIPROVINCIA = '00'
                        AND DEP.UBIDISTRITO = '00'
LEFT JOIN TGUBIGEO PROV ON PROV.UBIDEPARTAMENTO = SUBSTR(E.ESP_UBIGEO, 1, 2)
                        AND PROV.UBIPROVINCIA = SUBSTR(E.ESP_UBIGEO, 3, 2)
                        AND PROV.UBIDISTRITO = '00'
LEFT JOIN TGUBIGEO DIST ON DIST.UBIDEPARTAMENTO = SUBSTR(E.ESP_UBIGEO,1 , 2)
                        AND DIST.UBIPROVINCIA = SUBSTR(E.ESP_UBIGEO,3 , 2)
                        AND DIST.UBIDISTRITO = SUBSTR(E.ESP_UBIGEO,5 , 2)
LEFT JOIN TRPERSONAL TP ON E.ID_PERSONAL = TP.IDPERSONAL
LEFT JOIN TGPERSONA PER ON TP.PRHPERSONA = PER.IDPERSONA
WHERE
      E.ESP_ELIMINADO = 0
      AND E.ESP_ESTADO = 1
      AND E.ID_SERVICIO = 5
ORDER BY E.ESP_NOMBRE;
/

-- * 1.3.2 Actualizar `SP`
CREATE OR REPLACE PROCEDURE SP_LISTAR_CENTROS_V2 (
   P_ID_SERVICIO        IN NUMBER,
   P_TIPO_CENTRO        IN VARCHAR2,
   P_ID_SERVICIO_PADRE  IN NUMBER,
   P_CURSOR             OUT SYS_REFCURSOR
)
AS
    V_ID_UNIDAD_PADRE NUMBER;
BEGIN
    V_ID_UNIDAD_PADRE :=
        CASE
            WHEN P_ID_SERVICIO_PADRE = 4 THEN -- * 1. SIGES
                CASE
                    WHEN P_ID_SERVICIO = 4 THEN 73
                    WHEN P_ID_SERVICIO IN (5, 7, 8) THEN 90
                    WHEN P_ID_SERVICIO = 6 THEN 1118
                    WHEN P_ID_SERVICIO = 9 THEN 1146
                    WHEN P_ID_SERVICIO = 10 THEN 1166
                    ELSE NULL
                END

            WHEN P_ID_SERVICIO_PADRE = 5 THEN -- * 2. EDUCALLE
               1146

            ELSE NULL
        END;

    -- CASO 1: SERVICIOS DE INTERVENCIÓN
    IF (
           (
                P_ID_SERVICIO_PADRE = 4
                AND P_ID_SERVICIO IN (7, 8, 9, 10)
           )
           OR P_ID_SERVICIO_PADRE = 5
       )
    THEN
        OPEN P_CURSOR FOR
            SELECT
                E.ID_UNIDADORGANICA_PADRE AS IDUNIDADORGANICA,
                TO_CHAR(E.ESP_NOMBRE) AS UORNOMBRE,
                NULL AS TIPO_CENTRO,
                DEP.UBILOCALIDAD AS DEPARTAMENTO,
                PROV.UBILOCALIDAD AS PROVINCIA,
                DIST.UBILOCALIDAD AS DISTRITO,
                CASE
                    WHEN E.ID_PERSONAL IS NULL THEN
                        TO_CHAR(E.ESP_NOMBRE_RESPONSABLE)
                    ELSE
                        PER.PERNOMBRE || ' ' ||
                        PER.PERAPEPATERNO || ' ' ||
                        PER.PERAPEMATERNO
                END AS DIRECTOR,
                E.ID_PERSONAL AS IDPERSONAL
            FROM SSI_ESP_INTERVENCION E
            LEFT JOIN TGUBIGEO DEP
                   ON DEP.UBIDEPARTAMENTO = SUBSTR(E.ESP_UBIGEO, 1, 2)
                  AND DEP.UBIPROVINCIA = '00'
                  AND DEP.UBIDISTRITO = '00'
            LEFT JOIN TGUBIGEO PROV
                   ON PROV.UBIDEPARTAMENTO = SUBSTR(E.ESP_UBIGEO, 1, 2)
                  AND PROV.UBIPROVINCIA = SUBSTR(E.ESP_UBIGEO, 3, 2)
                  AND PROV.UBIDISTRITO = '00'
            LEFT JOIN TGUBIGEO DIST
                   ON DIST.UBIDEPARTAMENTO = SUBSTR(E.ESP_UBIGEO, 1, 2)
                  AND DIST.UBIPROVINCIA = SUBSTR(E.ESP_UBIGEO, 3, 2)
                  AND DIST.UBIDISTRITO = SUBSTR(E.ESP_UBIGEO, 5, 2)
            LEFT JOIN TRPERSONAL TP
                   ON E.ID_PERSONAL = TP.IDPERSONAL
            LEFT JOIN TGPERSONA PER
                   ON TP.PRHPERSONA = PER.IDPERSONA
            WHERE E.ESP_ELIMINADO = 0
              AND E.ESP_ESTADO = 1
              AND E.ID_SERVICIO = P_ID_SERVICIO
              AND E.ID_UNIDADORGANICA_PADRE = V_ID_UNIDAD_PADRE
            ORDER BY E.ESP_NOMBRE;

    -- CASO 2: SERVICIOS NORMALES
    ELSIF P_ID_SERVICIO_PADRE = 4 THEN -- * SIGES
        OPEN P_CURSOR FOR
            SELECT
                A.IDUNIDADORGANICA,
                A.UORNOMBRE,
                CASE
                    WHEN A.UORNOMBRE LIKE 'CAR%'
                         AND A.UORNOMBRE NOT LIKE '%ESPECIALIZADO%'
                         AND A.UORNOMBRE NOT LIKE '%URGENCIA%'
                         AND A.IDUNIDADORGANICA NOT IN (
                             124, 123, 1047, 538, 534, 571,
                             539, 154, 126, 128, 155, 156
                         )
                    THEN 'BÁSICO'

                    WHEN A.UORNOMBRE LIKE '%ESPECIALIZADO%'
                         OR A.IDUNIDADORGANICA IN (
                             124, 123, 1047, 538, 534, 571,
                             539, 154, 126, 128, 155, 156
                         )
                    THEN 'ESPECIALIZADO'

                    WHEN A.UORNOMBRE LIKE '%URGENCIA%'
                    THEN 'URGENCIA'

                    ELSE NULL
                END AS TIPO_CENTRO,
                DEP.UBILOCALIDAD AS DEPARTAMENTO,
                PROV.UBILOCALIDAD AS PROVINCIA,
                DIST.UBILOCALIDAD AS DISTRITO,
                PER.PERNOMBRE || ' ' ||
                PER.PERAPEPATERNO || ' ' ||
                PER.PERAPEMATERNO AS DIRECTOR,
                TP.IDPERSONAL
            FROM TGUNIDADORGANICA A
            LEFT JOIN TGUBIGEO DEP
                   ON DEP.UBIDEPARTAMENTO = SUBSTR(A.UOR_UBIGEO, 1, 2)
                  AND DEP.UBIPROVINCIA = '00'
                  AND DEP.UBIDISTRITO = '00'
            LEFT JOIN TGUBIGEO PROV
                   ON PROV.UBIDEPARTAMENTO = SUBSTR(A.UOR_UBIGEO, 1, 2)
                  AND PROV.UBIPROVINCIA = SUBSTR(A.UOR_UBIGEO, 3, 2)
                  AND PROV.UBIDISTRITO = '00'
            LEFT JOIN TGUBIGEO DIST
                   ON DIST.UBIDEPARTAMENTO = SUBSTR(A.UOR_UBIGEO, 1, 2)
                  AND DIST.UBIPROVINCIA = SUBSTR(A.UOR_UBIGEO, 3, 2)
                  AND DIST.UBIDISTRITO = SUBSTR(A.UOR_UBIGEO, 5, 2)
            LEFT JOIN TRPERSONAL TP
                   ON TP.IDPERSONAL = A.UOR_DIRECTOR
            LEFT JOIN TGPERSONA PER
                   ON PER.IDPERSONA = TP.PRHPERSONA
            WHERE A.UORELIMINADO = 0
              AND A.UORESTADO = 1
              AND A.UOR_TIPO_CENTRO NOT IN (3857)
              AND A.IDUNIDADORGANICA NOT IN (332, 343, 344, 511)
              AND (
                    A.UOR_UNIDAD_PADRE = V_ID_UNIDAD_PADRE
                    OR (
                        A.IDUNIDADORGANICA = V_ID_UNIDAD_PADRE
                        AND A.UOR_UNIDAD_PADRE IS NULL
                    )
                  )
              AND (
                    P_TIPO_CENTRO = '-1'
                    OR P_TIPO_CENTRO IS NULL
                    OR (
                        P_TIPO_CENTRO = '1'
                        AND A.UORNOMBRE LIKE 'CAR%'
                        AND A.UORNOMBRE NOT LIKE '%ESPECIALIZADO%'
                        AND A.UORNOMBRE NOT LIKE '%URGENCIA%'
                        AND A.IDUNIDADORGANICA NOT IN (
                            124, 123, 1047, 538, 534, 571,
                            539, 154, 126, 128, 155, 156
                        )
                    )
                    OR (
                        P_TIPO_CENTRO = '2'
                        AND (
                            A.UORNOMBRE LIKE '%ESPECIALIZADO%'
                            OR A.IDUNIDADORGANICA IN (
                                124, 123, 1047, 538, 534, 571,
                                539, 154, 126, 128, 155, 156
                            )
                        )
                    )
                    OR (
                        P_TIPO_CENTRO = '3'
                        AND A.UORNOMBRE LIKE '%URGENCIA%'
                    )
                  )
            ORDER BY A.UORNOMBRE;

    ELSE
        -- Cursor vacío para evitar devolver un cursor sin abrir
        OPEN P_CURSOR FOR
            SELECT
                CAST(NULL AS NUMBER) AS IDUNIDADORGANICA,
                CAST(NULL AS VARCHAR2(500)) AS UORNOMBRE,
                CAST(NULL AS VARCHAR2(100)) AS TIPO_CENTRO,
                CAST(NULL AS VARCHAR2(200)) AS DEPARTAMENTO,
                CAST(NULL AS VARCHAR2(200)) AS PROVINCIA,
                CAST(NULL AS VARCHAR2(200)) AS DISTRITO,
                CAST(NULL AS VARCHAR2(500)) AS DIRECTOR,
                CAST(NULL AS NUMBER) AS IDPERSONAL
            FROM DUAL
            WHERE 1 = 0;
    END IF;
END SP_LISTAR_CENTROS_V2;
/

-- ! COMMIT;

-- * 1.4 Anexos

CREATE OR REPLACE PROCEDURE SP_LISTAR_ANEXOS_POR_SERVICIO_V2 (
    P_ID_UNIDAD_ORGANICA IN NUMBER,
    P_ID_SERVICIO        IN NUMBER,
    P_ID_SERVICIO_PADRE IN NUMBER, -- ! Servicios: `SIGES` | `EDUCALLE`
    P_CURSOR             OUT SYS_REFCURSOR
) AS
BEGIN
    -- Abrimos el cursor para devolver los anexos según unidad y servicio
    OPEN P_CURSOR FOR
      SELECT
         a.*
      FROM SSI_ANEXO a
      WHERE 
         a.IDUNIDADORGANICA = P_ID_UNIDAD_ORGANICA
         AND a.ANX_ID_SERVICIO = P_ID_SERVICIO
         AND a.ID_SERVICIO_PADRE = P_ID_SERVICIO_PADRE;
END;
/

-- ! COMMIT;

-- * 1.4 Instrumentos

-- * 1.4.1 Instrumentos
-- * 1.4.2 Actualizar `SP`
CREATE OR REPLACE PROCEDURE USP_BUSCAR_PREGUNTAS_POR_PARAMETROS2_V2
(
   p_servicio IN NUMBER,
   p_anexo IN NUMBER,
   p_grupo IN NUMBER DEFAULT NULL,
   p_servicio_padre IN NUMBER DEFAULT NULL, -- ! Servicios: `SIGES` | `EDUCALLE`
   c_resultado OUT SYS_REFCURSOR
)
IS
BEGIN

   OPEN c_resultado FOR
      SELECT

         p.AP_ID_PREGUNTA AS IDPREGUNTA,
         p.SI_ID_SERVICIO2 AS IDSERVICIO,
         p.AP_NUM_ANEXO AS NUMANEXO,
         p.AP_NUM_GRUPO AS NUMGRUPO,
         p.AP_NUM_PREGUNTA AS NUMPREGUNTA,

         -- * Nuevo
         p.AP_MODO_CONTROL AS MODOCONTROL,
         p.AP_ICONO_CONTROL AS ICONOCONTROL,
         p.AP_VISTA_CONTROL AS VISTACONTROL,
         p.AP_EDITABLE AS EDITABLE,
         p.AP_URL_SERVICIO AS URLSERVICIO,
         p.AP_REQ_DISPARADOR AS REQDISPARADOR,
         p.AP_HTTP_METODO AS HTTPMETODO,
         p.AP_HTTP_PARAMS AS HTTPPARAMS,
         p.AP_EDITABLE_BIFURCACIONES AS EDITABLEBIFURCACIONES,
         p.AP_LONG AS LNG,
         p.AP_LONG_BIFURCACION AS LNGBIFURCACION,
         p.AP_RANGO_LONGITUD AS RANGOLONGITUD,
         p.AP_REQ_ALFNUM AS REQALFNUM,
         p.AP_REQ_CONTADOR AS REQCONTADOR,

         REPLACE(
            REPLACE(
               REPLACE(
                  REPLACE(
                     REPLACE(p.AP_PREGUNTA, CHR(9), ''),
                  CHR(10), ''),
               ' ', '<>'),
            '><', ''),
         '<>', ' ') AS PREGUNTA,

         (
            CASE
               WHEN a.ANX_REQ_OBLIGATORIEDAD = 1 THEN p.AP_OBLIGATORIA1 -- ? Si obligatorieda de anexo es `1`, mantiene de pregunta
               ELSE 0
            END
         )
         AS OBLIGATORIA,
         (
            CASE
               WHEN a.ANX_REQ_OBLIGATORIEDAD = 1 THEN P.AP_OBLIGATORIA2 -- ? Si obligatorieda de anexo es `1`, mantiene de pregunta
               ELSE 0
            END
         ) AS OBLIGATORIA2,

         p.AP_OBLIGATORIA1 AS REQ_OBLIGATORIA1_CIERRE, -- ? Se valida en cierre de ficha
         P.AP_OBLIGATORIA2 AS REQ_OBLIGATORIA2_CIERRE, -- ? Se valida en cierre de ficha

         p.AP_OPCIONES AS OPCIONES,
         p.AP_TIPO_CONTROL AS TIPOCONTROL,
         P.AP_PREGUNTA2 AS PREGUNTA2,
         P.AP_TIPO_CONTROL2 AS TIPO_CONTROL2,
         P.AP_OPCIONES2 AS OPCIONES2,
         P.AP_TIPO_DATO1 AS TIPODATO1,
         P.AP_TIPO_DATO2 AS TIPODATO2,
         P.AP_CONDICION AS CONDICION

      FROM SSI_ANEXOS_PREGUNTAS p
      JOIN SSI_ANEXO a ON p.AP_NUM_ANEXO = a.ID_ANEXO
                       AND p.SI_ID_SERVICIO = p_servicio_padre
      WHERE
         p.SI_ID_SERVICIO2 = p_servicio
         AND p.AP_NUM_ANEXO = p_anexo
         AND (p.AP_NUM_GRUPO = p_grupo OR p_grupo IS NULL)

      ORDER BY
         p.SI_ID_SERVICIO2,
         p.AP_NUM_ANEXO,
         p.AP_NUM_GRUPO,
         p.AP_NUM_PREGUNTA;

END;
/

-- ! COMMIT;



SELECT
   a.*
FROM SSI_ANEXO a
WHERE 
   a.IDUNIDADORGANICA = P_ID_UNIDAD_ORGANICA
   AND a.ANX_ID_SERVICIO  = P_ID_SERVICIO
/

-- * 1.5

-- * 1.5.1
-- * 1.5.2 Actualizar `SP`
CREATE OR REPLACE PROCEDURE USP_LISTAR_ANEXOS_CABECERA_V2
(
   p_id_servicio_padre IN NUMBER,
   p_cursor OUT SYS_REFCURSOR
)
AS
   /*
   * Propósito : Lista las cabeceras de anexos (SSI_ANEXOS_CABECERA) con datos
   *             del anexo (SSI_ANEXO) y centro (TGUNIDADORGANICA), agregando
   *             respuestas de 5 preguntas específicas desde
   *             SSI_ANEXOS_RESPUESTAS_V2 (NOMBRES parseado, EDAD calculada,
   *             GENERO, FECHA_ABORDAJE y FECHA_INGRESO).
   *
   * Parámetros:
   *   p_id_servicio_padre (IN  NUMBER)        -> ID_SERVICIO_PADRE del anexo.
   *   p_cursor            (OUT SYS_REFCURSOR) -> Cursor con el resultset.
   *
   * Autor     : rguevarav
   * Fecha     : 2026-06-20
   *
   * Relación  : SSI_ANEXOS_CABECERA se une a SSI_ANEXOS_RESPUESTAS_V2 por la
   *             tripa ID_ANEXO + ID_CENTRO + CORRELATIVO. Cada pregunta es una
   *             fila distinta (diferenciada por AP_ID_PREGUNTA), por lo que se
   *             requieren 5 LEFT JOINs independientes.
   *
   *             Adicionalmente, AC.ID_RESP_SUPERVISION se resuelve mediante
   *             TRPERSONAL.IDPERSONAL -> TGPERSONA.IDPERSONA para obtener
   *             el ID y nombre del educador de calle (campos ID_EDUCADOR_CALLE
   *             y NOMBRE_EDUCADOR_CALLE). LEFT JOIN para preservar cabeceras
   *             sin educador asignado.
   */
BEGIN
   OPEN p_cursor FOR
      SELECT
         
         /* CABECERA */
        AC.ID_ANEXO_CABECERA,
        AC.ID_ANEXO,
        AC.ID_CENTRO,
        AC.CORRELATIVO,
        AC.USU_REGISTRA,
        AC.ESTADO,
        AC.ELIMINADO,

        /* ANEXO */
        A.ANX_CODIGO2,
        A.ANX_NOMBRE,
        A.ANX_UNIDAD_ORGANICA,
        A.ANX_SERVICIO,          -- ¿ ESTE ES EL SERVICIO

        /* CENTRO */
        NVL(AC.CENTRO, U.UORNOMBRE) AS NOMBRE_CENTRO, -- * Nuevo

        /* ...  */
        AC.PERIODO,
        AC.TIPO,
        A.ANX_REQ_VALIDACION,
        A.ANX_REQ_SUPERVISADOS,
        A.ANX_REQ_DIRECTOR,
         
         /* ===== PREGUNTA 4271 - NOMBRES ===== */
         /* Formato: DNI|APELLIDO_PATERNO|APELLIDO_MATERNO|NOMBRES */
         /*NVL(REGEXP_SUBSTR(R_NOM.AR_RESPUESTA, '[^|]+', 1, 1), NULL) AS NRO_DOCUMENTO,
         NVL(REGEXP_SUBSTR(R_NOM.AR_RESPUESTA, '[^|]+', 1, 2), NULL) AS APELLIDO_PATERNO,
         NVL(REGEXP_SUBSTR(R_NOM.AR_RESPUESTA, '[^|]+', 1, 3), NULL) AS APELLIDO_MATERNO,
         NVL(REGEXP_SUBSTR(R_NOM.AR_RESPUESTA, '[^|]+', 1, 4), NULL) AS NOMBRES,*/
         NVL2(
            REGEXP_SUBSTR(R_NOM.AR_RESPUESTA, '[^|]+', 1, 2),
            TRIM(
               REGEXP_SUBSTR(R_NOM.AR_RESPUESTA, '[^|]+', 1, 2) || ' ' ||
               REGEXP_SUBSTR(R_NOM.AR_RESPUESTA, '[^|]+', 1, 3) || ' ' ||
               REGEXP_SUBSTR(R_NOM.AR_RESPUESTA, '[^|]+', 1, 4)
            ),
            NULL
         ) AS NOMBRECOMPLETO,
         /* ===== PREGUNTA 4273 - EDAD (fecha de nacimiento) ===== */
         /* Formato: YYYY-MM-DD (ISO 8601), ej. 2026-06-19 */
         /* CASE
            WHEN R_EDAD.AR_RESPUESTA IS NOT NULL
            THEN TO_DATE(R_EDAD.AR_RESPUESTA, 'YYYY-MM-DD')
            ELSE NULL
         END AS FECHA_NACIMIENTO, */
         CASE
            WHEN R_EDAD.AR_RESPUESTA IS NOT NULL
            THEN TRUNC(
                    MONTHS_BETWEEN(SYSDATE, TO_DATE(R_EDAD.AR_RESPUESTA, 'YYYY-MM-DD')) / 12
                 )
            ELSE 0
         END AS EDAD,
         /* ===== PREGUNTA 4272 - GENERO ===== */
         R_GEN.AR_RESPUESTA AS GENERO,
         /* ===== PREGUNTA 4263 - FECHA DE ABORDAJE ===== */
         /* Formato: YYYY-MM-DD (ISO 8601) */
         CASE
            WHEN (R_FAB.AR_RESPUESTA IS NOT NULL) THEN TO_DATE(R_FAB.AR_RESPUESTA, 'YYYY-MM-DD')
            ELSE NULL
         END AS FECHAABORDAJE,
         /* ===== PREGUNTA 4264 - FECHA DE INGRESO ===== */
         /* Formato: YYYY-MM-DD (ISO 8601) */
         CASE
            WHEN (R_FING.AR_RESPUESTA IS NOT NULL) THEN TO_DATE(R_FING.AR_RESPUESTA, 'YYYY-MM-DD')
            ELSE AC.FECHA_INSCRIPCION 
         END AS FECHAINGRESO,
         /* ===== Educador de calle (ID_RESP_SUPERVISION) ===== */
         AC.ID_RESP_SUPERVISION AS ID_EDUCADOR_CALLE,
         per_resp.PERNOMBRE || ' ' ||
         per_resp.PERAPEPATERNO || ' ' ||
         per_resp.PERAPEMATERNO AS NOMBRE_EDUCADOR_CALLE
      FROM SSI_ANEXOS_CABECERA AC
      LEFT JOIN SSI_ANEXO A
         ON A.ID_ANEXO = AC.ID_ANEXO
      LEFT JOIN TGUNIDADORGANICA U
         ON U.IDUNIDADORGANICA = AC.ID_CENTRO
      /* ----- Pregunta 4273: NOMBRES ----- */
      LEFT JOIN SSI_ANEXOS_RESPUESTAS_V2 R_NOM
         ON R_NOM.ID_ANEXO    = AC.ID_ANEXO
        AND R_NOM.ID_CENTRO   = AC.ID_CENTRO
        AND R_NOM.CORRELATIVO = AC.CORRELATIVO
        AND R_NOM.AP_ID_PREGUNTA = 4273
        AND R_NOM.AR_ELIMINADO   = 0
      /* ----- Pregunta 4275: EDAD (fecha de nacimiento) ----- */
      LEFT JOIN SSI_ANEXOS_RESPUESTAS_V2 R_EDAD
         ON R_EDAD.ID_ANEXO    = AC.ID_ANEXO
        AND R_EDAD.ID_CENTRO   = AC.ID_CENTRO
        AND R_EDAD.CORRELATIVO = AC.CORRELATIVO
        AND R_EDAD.AP_ID_PREGUNTA = 4275
        AND R_EDAD.AR_ELIMINADO   = 0
      /* ----- Pregunta 4274: GENERO ----- */
      LEFT JOIN SSI_ANEXOS_RESPUESTAS_V2 R_GEN
         ON R_GEN.ID_ANEXO    = AC.ID_ANEXO
        AND R_GEN.ID_CENTRO   = AC.ID_CENTRO
        AND R_GEN.CORRELATIVO = AC.CORRELATIVO
        AND R_GEN.AP_ID_PREGUNTA = 4274
        AND R_GEN.AR_ELIMINADO   = 0
      /* ----- Pregunta 4263: FECHA DE ABORDAJE ----- */
      LEFT JOIN SSI_ANEXOS_RESPUESTAS_V2 R_FAB
         ON R_FAB.ID_ANEXO    = AC.ID_ANEXO
        AND R_FAB.ID_CENTRO   = AC.ID_CENTRO
        AND R_FAB.CORRELATIVO = AC.CORRELATIVO
        AND R_FAB.AP_ID_PREGUNTA = 4263
        AND R_FAB.AR_ELIMINADO   = 0
      /* ----- Pregunta 4264: FECHA DE INGRESO ----- */
      LEFT JOIN SSI_ANEXOS_RESPUESTAS_V2 R_FING
         ON R_FING.ID_ANEXO    = AC.ID_ANEXO
        AND R_FING.ID_CENTRO   = AC.ID_CENTRO
        AND R_FING.CORRELATIVO = AC.CORRELATIVO
        AND R_FING.AP_ID_PREGUNTA = 4264
        AND R_FING.AR_ELIMINADO   = 0
      /* ----- Educador de calle: TRPERSONAL/TGPERSONA ----- */
      LEFT JOIN TRPERSONAL tp_resp
         ON tp_resp.IDPERSONAL = ac.ID_RESP_SUPERVISION
      LEFT JOIN TGPERSONA per_resp
         ON per_resp.IDPERSONA = tp_resp.PRHPERSONA
      WHERE
         AC.ELIMINADO = 0
         AND A.ID_SERVICIO_PADRE = p_id_servicio_padre
      ORDER BY
         AC.ID_ANEXO_CABECERA DESC;

EXCEPTION
   WHEN OTHERS THEN
      IF p_cursor%ISOPEN THEN
         CLOSE p_cursor;
      END IF;
      DBMS_OUTPUT.PUT_LINE('Error en USP_LISTAR_ANEXOS_CABECERA_V2');
      DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
      RAISE;
END;
/

-- ! COMMIT;

-- ! Test
SELECT * FROM SSI_ANEXOS_RESPUESTAS_V2 r
WHERE
   -- r.AP_ID_PREGUNTA = 4275
   r.AP_ID_PREGUNTA = 4273
ORDER BY
   r.AR_ID_RESPUESTA DESC
/

-- * 1.6 Indicadores EDUCALLE

-- * 1.6.1 SP Indicadores
CREATE OR REPLACE PROCEDURE USP_INDICADORES_ANEXOS_CABECERA
(
   p_id_servicio_padre IN NUMBER,
   p_meta_mensual      IN NUMBER DEFAULT 400,
   p_cursor            OUT SYS_REFCURSOR
)
AS
   /*
   * Propósito : Calcula indicadores operativos desde SSI_ANEXOS_CABECERA.
   *
   * Indicadores:
   *   - EDUCADORES_ACTIVOS   : cantidad distinta de ID_RESP_SUPERVISION.
   *   - INTERVENCIONES_HOY   : fichas registradas hoy (FECHA_REGISTRA).
   *   - REGISTROS_ESTE_MES   : fichas registradas en el mes en curso.
   *   - META_MENSUAL_PORCENTAJE : avance (registros_este_mes / meta) * 100.
   *
   * Parámetros:
   *   p_id_servicio_padre (IN  NUMBER) -> ID_SERVICIO_PADRE del anexo.
   *   p_meta_mensual      (IN  NUMBER) -> Meta mensual de registros.
   *   p_cursor            (OUT SYS_REFCURSOR) -> Cursor con una única fila.
   *
   * Autor     : rguevarav
   * Fecha     : 2026-06-20
   */
BEGIN
   OPEN p_cursor FOR
      SELECT
         COUNT(DISTINCT AC.ID_RESP_SUPERVISION) AS "educadoresActivos",
         COUNT(DISTINCT CASE
                           WHEN TRUNC(AC.FECHA_REGISTRA) = TRUNC(SYSDATE)
                           THEN AC.ID_ANEXO_CABECERA
                        END) AS "intervencionesHoy",
         COUNT(DISTINCT CASE
                           WHEN TRUNC(AC.FECHA_REGISTRA, 'MM') = TRUNC(SYSDATE, 'MM')
                           THEN AC.ID_ANEXO_CABECERA
                        END) AS "registrosEsteMes",
         p_meta_mensual AS "metaMensualValor",
         ROUND(
            (COUNT(DISTINCT CASE
                               WHEN TRUNC(AC.FECHA_REGISTRA, 'MM') = TRUNC(SYSDATE, 'MM')
                               THEN AC.ID_ANEXO_CABECERA
                            END) / NULLIF(p_meta_mensual, 0)) * 100,
            2
         ) AS "metaMensualPorcentaje",
         SYSDATE AS "fechaConsulta"
      FROM SSI_ANEXOS_CABECERA AC
      JOIN SSI_ANEXO A ON A.ID_ANEXO = AC.ID_ANEXO
      WHERE
         AC.ELIMINADO = 0
         AND NVL(A.ANX_ELIMINADO, 0) = 0
         AND A.ID_SERVICIO_PADRE = p_id_servicio_padre;

EXCEPTION
   WHEN OTHERS THEN
      IF p_cursor%ISOPEN THEN
         CLOSE p_cursor;
      END IF;
      DBMS_OUTPUT.PUT_LINE('Error en USP_INDICADORES_ANEXOS_CABECERA');
      DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
      RAISE;
END USP_INDICADORES_ANEXOS_CABECERA;
/

-- * 1.6.2 Test SP Indicadores
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   USP_INDICADORES_ANEXOS_CABECERA(5, 400, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/


-- ! COMMIT;



-- * 1.6 **Work Flow**

-- ? 1. Centros
SELECT * FROM SSI_ESP_INTERVENCION i
ORDER BY
   i.ID_ESP_INTERV DESC
/

DELETE FROM SSI_ESP_INTERVENCION i
WHERE
   i.ID_ESP_INTERV BETWEEN 52 AND 223
/

-- ! COMMIT;

-- ? 2. Cabecera de Anexos
SELECT
   a.*
FROM SSI_ANEXO a
ORDER BY
   a.ID_ANEXO DESC
/

UPDATE SSI_ANEXO a
   SET a.ID_SERVICIO_PADRE = 4
WHERE
   a.ID_SERVICIO_PADRE IS NULL
/

SELECT * FROM SSI_ANEXOS_CABECERA ac
ORDER  BY
   ac.ID_ANEXO_CABECERA DESC
/

-- ? 3. Preguntas

SELECT 
   pe.*
FROM TRPERSONAL p
JOIN TGPERSONA pe ON p.PRHPERSONA =  pe.IDPERSONA
WHERE
   p.IDPERSONAL = 21132
/

SELECT * FROM TGPERSONA pe
/
--

-- * 2. **Work Flow DDL** 

-- * 2.1 Registro de `Zonas Intervencion`

-- * 2.1.1 Servicio padre `EDUCALLE`
ALTER TABLE SSI_ESP_INTERVENCION
   ADD ID_SERVICIO_PADRE NUMBER NULL
/

-- ! COMMIT;

-- * 2.1.2 Inserta `Zona Intervencion`
INSERT INTO SSI_ESP_INTERVENCION (ID_ESP_INTERV, ID_SERVICIO, ESP_NOMBRE, ESP_UBIGEO, ESP_NOMBRE_RESPONSABLE, ID_UNIDADORGANICA_PADRE, ID_SERVICIO_PADRE, ESP_ESTADO, ESP_ELIMINADO) 
VALUES (51, 1, 'SEDE CENTRAL', 150121, 'SEDE CENTRAL', 1146, 5, 1, 0);

SELECT * FROM SSI_ESP_INTERVENCION i
ORDER BY
   i.ID_ESP_INTERV DESC
/



-- ! COMMIT;

-- * 2.1.3 Servicio padre `EDUCALLE`
ALTER TABLE SSI_ANEXO
   ADD ID_SERVICIO_PADRE NUMBER NULL
/

-- ! COMMIT;

-- * 2.1.4 Inserta `Anexo`

INSERT INTO SSI_ANEXO(
   ID_ANEXO, 
   ANX_CODIGO, 
   ANX_NOMBRE, 
   ANX_DESCRIPCION, 
   IDUNIDADORGANICA, 
   ANX_UNIDAD_ORGANICA, 
   ANX_ID_SERVICIO, 
   ANX_SERVICIO, 
   ANX_ESTADO, 
   ANX_ELIMINADO, 
   ANX_FEC_REGISTRA, 
   ANX_USU_REGISTRA, 
   ANX_CODIGO2, 
   ANX_REQ_VALIDACION, 
   ANX_REQ_SUPERVISADOS, 
   ANX_REQ_OBLIGATORIEDAD, 
   ANX_REQ_DIRECTOR,
   ID_SERVICIO_PADRE) 
VALUES(
   43, -- ID_ANEXO
   'ANEXO 01', -- ANX_CODIGO
   'FICHA INSCRIPCIÓN DEL NNA',-- ANX_NOMBRE
   'Ficha de Inscripción del NNA', -- ANX_DESCRIPCION
   90, -- IDUNIDADORGANICA
   'EDUCALLE',-- ANX_UNIDAD_ORGANICA
   1, -- ANX_ID_SERVICIO
   'Servicio de Educadores de Calle', -- ANX_SERVICIO
   1, -- ANX_ESTADO
   0, -- ANX_ELIMINADO
   SYSDATE, -- ANX_FEC_REGISTRA
   1, -- ANX_USU_REGISTRA
   'EDUCALLE', -- ANX_CODIGO2
   1, -- ANX_REQ_VALIDACION
   0, -- ANX_REQ_SUPERVISADOS
   1, -- ANX_REQ_OBLIGATORIEDAD
   0, -- ANX_REQ_DIRECTOR
   5 -- EDUCALLE
);
/

UPDATE SSI_ANEXO a
   SET a.IDUNIDADORGANICA = 1
WHERE
   a.ID_ANEXO = 43
/

-- ! COMMIT;


-- * 2.2 Insertar Catalogo preguntas de ANEXO

-- * 2.2.1 Nueva campo `AP_MODO_CONTROL`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_MODO_CONTROL VARCHAR2(55) NULL
/

UPDATE SSI_ANEXOS_PREGUNTAS p
   SET p.AP_MODO_CONTROL = 'editable'
WHERE
   p.SI_ID_SERVICIO = 4
/

-- * 2.2.2 Nueva campo `AP_ICONO_CONTROL`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_ICONO_CONTROL VARCHAR2(55) NULL
/

-- * 2.2.3 Nueva campo `AP_MODO_CONTROL`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_VISTA_CONTROL VARCHAR2(55) NULL
/

UPDATE SSI_ANEXOS_PREGUNTAS p
   SET p.AP_VISTA_CONTROL = 'default'
WHERE
   p.SI_ID_SERVICIO = 4
/

-- * 2.2.4 Nueva campo `AP_EDITABLE`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_EDITABLE VARCHAR2(100) NULL
/

-- * 2.2.5 Nueva campo `AP_URL_`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_URL_SERVICIO VARCHAR2(255) NULL
/


-- * 2.2.7 Nueva campo `AP_REQ_DISPARADOR`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_REQ_DISPARADOR NUMBER(1) NULL
/

-- * 2.2.8 Nueva campo `AP_HTTP_METODO`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_HTTP_METODO VARCHAR2(15) NULL
/

-- * 2.2.9 Nueva campo `AP_HTTP_PARAMS`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_HTTP_PARAMS VARCHAR2(1000) NULL
/

-- * 2.2.10 Nueva campo `AP_EDITABLE_BIFURCACIONES`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_EDITABLE_BIFURCACIONES VARCHAR2(100) NULL
/

-- * 2.2.11 Nuevos campos `AP_LONG & AP_LONG_BIFURCACION`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_LONG NUMBER NULL
/

ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_LONG_BIFURCACION NUMBER NULL
/

-- * 2.2.12 Nuevos campos `AP_RANGO_LONGITUD & AP_REQ_ALFNUM & AP_REQ_CONTADOR`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_RANGO_LONGITUD VARCHAR2(55) NULL
/

ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_REQ_ALFNUM NUMBER(1) NULL
/

ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_REQ_CONTADOR NUMBER(1) NULL
/

-- * 2.2.13 Nuevos campos `AP_RANGO_LONGITUD & AP_REQ_ALFNUM & AP_REQ_CONTADOR`
ALTER TABLE SSI_ANEXOS_PREGUNTAS
   ADD AP_BLOQ_SUBMIT_SI_INVALIDO VARCHAR2(1000) NULL
/

-- ! COMMIT;

-- * 2.3 Getion de `FechaInscripcion` && `CodigoNNA`

-- * 2.3.1
ALTER TABLE SSI_ANEXOS_CABECERA
   ADD FECHA_INSCRIPCION DATE NULL
/


-- * 2.3.2 `USP_SISEC_SAVE_CONFORMIDAD_ANXCABECERA`

-- =============================================================
-- Propósito : Actualizar fecha de inscripción en SSI_ANEXOS_CABECERA.
-- Parámetros:
--   p_id_anexo_cabecera IN SSI_ANEXOS_CABECERA.ID_ANEXO_CABECERA%TYPE
--   p_fecha_inscripcion IN SSI_ANEXOS_CABECERA.FECHA_INSCRIPCION%TYPE
-- Autor     : OpenCode
-- Fecha     : 2026-07-06
-- =============================================================
CREATE OR REPLACE PROCEDURE USP_SISEC_SAVE_CONFORMIDAD_ANXCABECERA (
   p_id_anexo_cabecera IN NUMBER,
   p_fecha_inscripcion IN DATE
)
AS
   v_id_anexo_cabecera NUMBER := p_id_anexo_cabecera;
   v_fecha_inscripcion DATE := p_fecha_inscripcion;
BEGIN
   UPDATE SSI_ANEXOS_CABECERA ac
      SET ac.FECHA_INSCRIPCION = v_fecha_inscripcion,
          ac.FECHA_MODIFICA    = SYSDATE
    WHERE ac.ID_ANEXO_CABECERA = v_id_anexo_cabecera;

   IF SQL%ROWCOUNT = 0 THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(
         -20001,
         'No se encontró SSI_ANEXOS_CABECERA con ID_ANEXO_CABECERA = ' || v_id_anexo_cabecera
      );
   END IF;

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      DBMS_OUTPUT.PUT_LINE('Error en USP_SISEC_SAVE_CONFORMIDAD_ANXCABECERA');
      DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
      RAISE;
END USP_SISEC_SAVE_CONFORMIDAD_ANXCABECERA;
/

-- ! COMMIT;



SELECT * FROM SSI_ESP_INTERVENCION i
WHERE
   i.ESP_UBIGEO = '040000'
ORDER BY
   i.ID_ESP_INTERV DESC
/

-- ? Actualizar 6 digitos de `UBIGEO`
UPDATE SSI_ESP_INTERVENCION i
SET
   i.ESP_UBIGEO = (
                     CASE
                        WHEN i.ESP_UBIGEO IS NOT NULL THEN LPAD(i.ESP_UBIGEO, 6, '0')
                        ELSE i.ESP_UBIGEO
                     END
   )
/

-- ! COMMIT;

-- ! Test:
SELECT * FROM SSI_ANEXOS_CABECERA c
WHERE
   c.ID_ANEXO_CABECERA = 419
/

-- ! Eliminar preguntas

-- ! 1
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 5
/

-- ! COMMIT;

SELECT * FROM SSI_UBIGEO_NOMBRES u
WHERE
   u.U_ID_UBIGEO = '040000'
/





-- ! 2 Eliminar respuestas, si `idPregunta` cambia.
-- 2.1
DELETE FROM SSI_ANEXOS_RESPUESTAS_V2 r
WHERE
   r.AP_ID_PREGUNTA IN (
      SELECT p.AP_ID_PREGUNTA FROM SSI_ANEXOS_PREGUNTAS p
      WHERE
         p.SI_ID_SERVICIO = 5 -- SISEC
   )
/

-- 2.2
-- DELETE FROM SSI_ANEXOS_CABECERA c
SELECT * FROM SSI_ANEXOS_CABECERA c
/* WHERE
   c.ID_ANEXO = 43 */
ORDER BY
   c.ID_ANEXO DESC
/

SELECT * FROM SSI_ANEXO
/

-- ! COMMIT;

SELECT * FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4
/

SELECT * FROM SSI_ANEXOS_RESPUESTAS_V2 r
WHERE
   r.AP_ID_PREGUNTA = 4275
/

-- ! COMMIT;



SELECT * FROM TGCATALOGO c
WHERE
   c.IDCATALOGO IN (
      3021,
      3022,
      3023,
      1278,
      1279,
      1280,
      1281,
      1282,
      1283,
      5581,
      5582,
      5583
   )
/

-- * 1. TIPOS EDUCACION
SELECT * FROM TGCATALOGO c
WHERE
   c.CATGRUPO = 38
   AND c.CATSUBGRUPO = 38
   AND c.catestado = 1
/

-- * 2. NIVEL EDUCATIVO
SELECT * FROM TGCATALOGO c
WHERE
   c.CATGRUPO = 38
   AND c.CATSUBGRUPO = 39
   AND c.catestado = 1
/

















-- ! Test
SELECT * FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 5
ORDER BY
   p.AP_ID_PREGUNTA DESC
/

SELECT * FROM SSI_ANEXOS_RESPUESTAS_V2 r
ORDER BY
   r.AR_ID_RESPUESTA DESC
/

SELECT 
   p.AP_TIPO_CONTROL
FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 5
GROUP BY
   p.AP_TIPO_CONTROL
/

SELECT 
   p.*
FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4
/

SELECT 
   p.*
FROM SSI_UBIGEO_NOMBRES p
/


SELECT * FROM SSI_ANEXO a
WHERE
   a.ID_ANEXO = 43
/

UPDATE SSI_ANEXO a
   SET
      a.ANX_REQ_OBLIGATORIEDAD = 0
WHERE
   a.ID_ANEXO = 43
/

-- ! COMMIT;




-- ! COMMIT;


CREATE OR REPLACE PROCEDURE PRC_SISEC_CATALOGO_LISTAR_NIVEL_EDU
(
   p_id_tipo_edu   IN  NUMBER,
   p_id_nivel_edu  IN  NUMBER,
   p_cursor        OUT SYS_REFCURSOR
)
AS
   v_sql_base   CLOB;
   v_sql_filtro CLOB;
   v_sql_final  CLOB;
BEGIN
   IF p_id_tipo_edu IS NULL AND p_id_nivel_edu IS NULL THEN

      v_sql_base := q'[
         SELECT
            t1.id_t1 AS idcatalogo,
            t1.nombre AS catdescripcion
         FROM (
            SELECT 3018 AS id_t1, 'EBR' AS nombre FROM DUAL
            UNION ALL SELECT 3019, 'EBA' FROM DUAL
            UNION ALL SELECT 1277, 'EDA' FROM DUAL
            UNION ALL SELECT 5580, 'EBE' FROM DUAL
         ) t1
         ORDER BY t1.id_t1
      ]';

      OPEN p_cursor FOR v_sql_base;

   ELSIF p_id_tipo_edu IS NOT NULL THEN

      v_sql_base := q'[
         SELECT
            t2.id_t2 AS idcatalogo,
            t2.nombre AS catdescripcion
         FROM (
            SELECT 3018 AS id_t1, 3021 AS id_t2, 'INICIAL' AS nombre FROM DUAL
            UNION ALL SELECT 3018, 3022, 'PRIMARIA' FROM DUAL
            UNION ALL SELECT 3018, 3023, 'SECUNDARIA' FROM DUAL
            UNION ALL SELECT 3019, 1278, 'INICIAL' FROM DUAL
            UNION ALL SELECT 3019, 1279, 'INTERMEDIO' FROM DUAL
            UNION ALL SELECT 3019, 1280, 'AVANZADO' FROM DUAL
            UNION ALL SELECT 1277, 1281, 'INICIAL' FROM DUAL
            UNION ALL SELECT 1277, 1282, 'INTERMEDIO' FROM DUAL
            UNION ALL SELECT 1277, 1283, 'AVANZADO' FROM DUAL
            UNION ALL SELECT 5580, 5581, 'INICIAL' FROM DUAL
            UNION ALL SELECT 5580, 5582, 'PRIMARIA' FROM DUAL
            UNION ALL SELECT 5580, 5583, 'SECUNDARIA' FROM DUAL
         ) t2
      ]';

      v_sql_filtro := ' WHERE t2.id_t1 = :p_id_tipo_edu ORDER BY t2.id_t2';
      v_sql_final := v_sql_base || v_sql_filtro;

      OPEN p_cursor FOR v_sql_final USING p_id_tipo_edu;

   ELSIF p_id_nivel_edu IS NOT NULL THEN

      v_sql_base := q'[
         SELECT
            t3.id_t3 AS idcatalogo,
            t3.nombre AS catdescripcion
         FROM (
            SELECT 3021 AS id_t2, 1284 AS id_t3, '0-2 AÑOS' AS nombre FROM DUAL
            UNION ALL SELECT 3021, 1285, '3-5 AÑOS' FROM DUAL
            UNION ALL SELECT 3022, 3026, '1RO PRIM' FROM DUAL
            UNION ALL SELECT 3022, 3027, '2DO PRIM' FROM DUAL
            UNION ALL SELECT 3022, 3028, '3RO PRIM' FROM DUAL
            UNION ALL SELECT 3022, 3029, '4TO PRIM' FROM DUAL
            UNION ALL SELECT 3022, 3030, '5TO PRIM' FROM DUAL
            UNION ALL SELECT 3022, 3031, '6TO PRIM' FROM DUAL
            UNION ALL SELECT 3023, 3032, '1RO SEC' FROM DUAL
            UNION ALL SELECT 3023, 3033, '2DO SEC' FROM DUAL
            UNION ALL SELECT 3023, 3034, '3RO SEC' FROM DUAL
            UNION ALL SELECT 3023, 3035, '4TO SEC' FROM DUAL
            UNION ALL SELECT 3023, 3036, '5TO SEC' FROM DUAL
            UNION ALL SELECT 1278, 1286, '1RO INIC' FROM DUAL
            UNION ALL SELECT 1278, 1287, '2DO INIC' FROM DUAL
            UNION ALL SELECT 1279, 1288, '1RO INTER' FROM DUAL
            UNION ALL SELECT 1279, 1289, '2DO INTER' FROM DUAL
            UNION ALL SELECT 1279, 1290, '3RO INTER' FROM DUAL
            UNION ALL SELECT 1280, 1291, '1RO AVANZ' FROM DUAL
            UNION ALL SELECT 1280, 1292, '2DO AVANZ' FROM DUAL
            UNION ALL SELECT 1280, 1293, '3RO AVANZ' FROM DUAL
            UNION ALL SELECT 1280, 1294, '4TO AVANZ' FROM DUAL
            UNION ALL SELECT 1281, 1295, '1RO INIC' FROM DUAL
            UNION ALL SELECT 1281, 1296, '2DO INIC' FROM DUAL
            UNION ALL SELECT 1282, 1297, '3RO INTER' FROM DUAL
            UNION ALL SELECT 1282, 1298, '4TO INTER' FROM DUAL
            UNION ALL SELECT 1282, 1299, '5TO INTER' FROM DUAL
            UNION ALL SELECT 1283, 1300, '1RO AVANZ' FROM DUAL
            UNION ALL SELECT 1283, 1301, '2DO AVANZ' FROM DUAL
            UNION ALL SELECT 1283, 1302, '3RO AVANZ' FROM DUAL
            UNION ALL SELECT 1283, 1303, '4TO AVANZ' FROM DUAL
            UNION ALL SELECT 1283, 1304, '5TO AVANZ' FROM DUAL
            UNION ALL SELECT 5581, 5584, '1RO INIC' FROM DUAL
            UNION ALL SELECT 5581, 5585, '2DO INIC' FROM DUAL
            UNION ALL SELECT 5582, 5586, '1RO PRIM' FROM DUAL
            UNION ALL SELECT 5582, 5587, '2DO PRIM' FROM DUAL
            UNION ALL SELECT 5582, 5588, '3RO PRIM' FROM DUAL
            UNION ALL SELECT 5582, 5589, '4TO PRIM' FROM DUAL
            UNION ALL SELECT 5582, 5590, '5TO PRIM' FROM DUAL
            UNION ALL SELECT 5582, 5591, '6TO PRIM' FROM DUAL
            UNION ALL SELECT 5583, 5592, '1RO SEC' FROM DUAL
            UNION ALL SELECT 5583, 5593, '2DO SEC' FROM DUAL
            UNION ALL SELECT 5583, 5594, '3RO SEC' FROM DUAL
            UNION ALL SELECT 5583, 5595, '4TO SEC' FROM DUAL
            UNION ALL SELECT 5583, 5596, '5TO SEC' FROM DUAL
         ) t3
      ]';

      v_sql_filtro := ' WHERE t3.id_t2 = :p_id_nivel_edu ORDER BY t3.id_t3';
      v_sql_final := v_sql_base || v_sql_filtro;

      OPEN p_cursor FOR v_sql_final USING p_id_nivel_edu;

   ELSE
      OPEN p_cursor FOR
         SELECT
            NULL AS idcatalogo,
            NULL AS catdescripcion
         FROM DUAL
         WHERE 1 = 0;
   END IF;

EXCEPTION
   WHEN OTHERS THEN
      IF p_cursor%ISOPEN THEN
         CLOSE p_cursor;
      END IF;

      DBMS_OUTPUT.PUT_LINE('Error en PRC_SISEC_CATALOGO_LISTAR_NIVEL_EDU');
      DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE);
      DBMS_OUTPUT.PUT_LINE('SQLERRM: ' || SQLERRM);
      RAISE;
END PRC_SISEC_CATALOGO_LISTAR_NIVEL_EDU;
/

-- ! COMMIT;

DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_SISEC_CATALOGO_LISTAR_NIVEL_EDU(1277, NULL, c_resultado_busqueda);
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/


-- =============================================================
-- Tipo      : PROCEDURE
-- Nombre    : USP_ACTUALIZAR_ANEXO_COMPLETO_V2
-- Proposito : Propuesta para unificar la actualizacion e insercion
--             de detalle en SSI_ANEXOS_RESPUESTAS_V2 usando una sola
--             lectura del JSON y la misma logica de busqueda del
--             bloque "Actualizar detalle".
-- Parametros:
--   p_id_cabecera          IN  NUMBER
--   p_id_anexo             IN  NUMBER
--   p_id_centro            IN  NUMBER
--   p_fecha_aplicacion     IN  DATE
--   p_fecha_registro       IN  DATE
--   p_usu_modifica         IN  NUMBER
--   p_id_resp_supervision  IN  NUMBER
--   p_id_director          IN  NUMBER
--   p_id_supervisado       IN  VARCHAR2
--   p_respuestas_json      IN  CLOB
--   p_periodo              IN  VARCHAR2
--   p_tipo                 IN  VARCHAR2
--   p_acreditacion_vigente IN  NUMBER
--   p_fecha_acreditacion   IN  DATE
--   p_modalidad            IN  VARCHAR2
--   p_correlativo          OUT NUMBER
-- Autor     : OpenCode
-- Fecha     : 2026-07-05
-- =============================================================
CREATE OR REPLACE PROCEDURE USP_ACTUALIZAR_ANEXO_COMPLETO_V2 (
   p_id_cabecera          IN NUMBER,
   p_id_anexo             IN NUMBER,
   p_id_centro            IN NUMBER,
   p_fecha_aplicacion     IN DATE,
   p_fecha_registro       IN DATE,
   p_usu_modifica         IN NUMBER,
   p_id_resp_supervision  IN NUMBER,
   p_id_director          IN NUMBER,
   p_id_supervisado       IN VARCHAR2,
   p_respuestas_json      IN CLOB,
   p_periodo              IN VARCHAR2,
   p_tipo                 IN VARCHAR2,
   p_acreditacion_vigente IN NUMBER,
   p_fecha_acreditacion   IN DATE,
   p_modalidad            IN VARCHAR2,
   p_correlativo          OUT NUMBER
)
AS
   v_correlativo NUMBER;
BEGIN
   SELECT ac.CORRELATIVO
     INTO v_correlativo
     FROM SSI_ANEXOS_CABECERA ac
    WHERE ac.ID_ANEXO_CABECERA = p_id_cabecera;

   UPDATE SSI_ANEXOS_CABECERA ac
      SET ac.FECHA_APLICACION      = p_fecha_aplicacion,
          ac.FECHA_REGISTRO        = p_fecha_registro,
          ac.USU_MODIFICA          = p_usu_modifica,
          ac.FECHA_MODIFICA        = SYSDATE,
          ac.ID_RESP_SUPERVISION   = p_id_resp_supervision,
          ac.ID_DIRECTOR           = p_id_director,
          ac.ID_SUPERVISADO        = p_id_supervisado,
          ac.PERIODO               = p_periodo,
          ac.TIPO                  = p_tipo,
          ac.ACREDITACION_VIGENTE  = p_acreditacion_vigente,
          ac.FECHA_ACREDITACION    = p_fecha_acreditacion,
          ac.MODALIDAD             = p_modalidad
    WHERE ac.ID_ANEXO_CABECERA = p_id_cabecera;

   FOR r IN (
      SELECT jt.ap_id_pregunta,
             jt.ar_respuesta,
             jt.ar_respuesta2,
             jt.ar_observacion,
             jt.ar_puntaje
        FROM JSON_TABLE(
                p_respuestas_json,
                '$[*]'
                COLUMNS (
                   ap_id_pregunta NUMBER PATH '$.idPregunta',
                   ar_respuesta   VARCHAR2(4000) PATH '$.respuesta',
                   ar_respuesta2  VARCHAR2(4000) PATH '$.respuesta2',
                   ar_observacion VARCHAR2(4000) PATH '$.observacion',
                   ar_puntaje     NUMBER PATH '$.puntaje'
                )
             ) jt
   ) LOOP
      UPDATE SSI_ANEXOS_RESPUESTAS_V2 ar
         SET ar.AR_RESPUESTA      = r.ar_respuesta,
             ar.AR_RESPUESTA2     = r.ar_respuesta2,
             ar.AR_OBSERVACION    = r.ar_observacion,
             ar.AR_PUNTAJE        = r.ar_puntaje,
             ar.AR_USU_MODIFICA   = p_usu_modifica,
             ar.AR_FECHA_MODIFICA = SYSDATE
       WHERE ar.ID_ANEXO       = p_id_anexo
         AND ar.ID_CENTRO      = p_id_centro
         AND ar.CORRELATIVO    = v_correlativo
         AND ar.AP_ID_PREGUNTA = r.ap_id_pregunta;

      IF SQL%ROWCOUNT = 0 THEN
         INSERT INTO SSI_ANEXOS_RESPUESTAS_V2 (
            AR_ID_RESPUESTA,
            ID_ANEXO,
            ID_CENTRO,
            CORRELATIVO,
            FECHA_APLICACION,
            AP_ID_PREGUNTA,
            AR_RESPUESTA,
            AR_RESPUESTA2,
            AR_OBSERVACION,
            AR_PUNTAJE,
            AR_USU_REGISTRA,
            AR_FECHA_REGISTRA
         )
         VALUES (
            SEQ_SSI_ANEXOS_RESP_V2.NEXTVAL,
            p_id_anexo,
            p_id_centro,
            v_correlativo,
            p_fecha_aplicacion,
            r.ap_id_pregunta,
            r.ar_respuesta,
            r.ar_respuesta2,
            r.ar_observacion,
            r.ar_puntaje,
            p_usu_modifica,
            SYSDATE
         );
      END IF;
   END LOOP;

   p_correlativo := v_correlativo;
   COMMIT;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(
         -20001,
         'No se encontro la cabecera con ID ' || p_id_cabecera
      );
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
END USP_ACTUALIZAR_ANEXO_COMPLETO_V2;
/

-- ! COMMIT;


