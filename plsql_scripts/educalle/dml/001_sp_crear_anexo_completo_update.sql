-- * 1. Adiciona campo `CODIGO_NNA`
ALTER TABLE SSI_ANEXOS_CABECERA
   ADD CODIGO_NNA VARCHAR2(25) NULL
/

-- ! COMMIT;

-- * 2.  ...
/*
* Propósito : Crea de forma integral un anexo: genera el correlativo por
*             (ID_ANEXO, ID_CENTRO), genera el código NNA con formato
*             SEC[ubigeo dp+prov]-[año]-[correlativo 4 cifras] a partir de
*             SSI_ESP_INTERVENCION y SSI_ANEXO, inserta la cabecera en
*             SSI_ANEXOS_CABECERA (incluyendo CODIGO_NNA) y el detalle de
*             respuestas en SSI_ANEXOS_RESPUESTAS_V2 vía JSON_TABLE.
*
* Parámetros:
*   p_id_anexo            (IN  NUMBER)   -> ID_ANEXO del anexo.
*   p_id_centro           (IN  NUMBER)   -> ID_CENTRO del centro.
*   p_fecha_aplicacion    (IN  DATE)     -> Fecha de aplicación del anexo.
*   p_fecha_registro      (IN  DATE)     -> Fecha de registro (nuevo campo).
*   p_usu_registra        (IN  NUMBER)   -> Usuario que registra.
*   p_respuestas_json     (IN  CLOB)     -> Respuestas en formato JSON.
*   p_id_resp_supervision (IN  NUMBER)   -> Responsable de supervisión.
*   p_id_director         (IN  NUMBER)   -> Director.
*   p_id_supervisado      (IN  VARCHAR2) -> Supervisado.
*   p_periodo             (IN  VARCHAR2) -> Periodo.
*   p_tipo                (IN  VARCHAR2) -> Tipo.
*   p_acreditacion_vigente(IN  NUMBER)   -> Acreditación vigente.
*   p_fecha_acreditacion  (IN  DATE)     -> Fecha de acreditación.
*   p_modalidad           (IN  VARCHAR2) -> Modalidad.
*   p_centro              (IN  VARCHAR2) -> Nombre del centro (ESP_NOMBRE).
*   p_id_servicio_padre   (IN  NUMBER)   -> ID_SERVICIO_PADRE del anexo.
*   p_id_cabecera         (OUT NUMBER)   -> ID_ANEXO_CABECERA generado.
*   p_correlativo         (OUT NUMBER)   -> Correlativo generado.
*
* Autor     : OpenCode
* Fecha     : 2026-08-12
*
* Relación  : SSI_ESP_INTERVENCION (ubigeo por centro/servicio),
*             SSI_ANEXO (ID_SERVICIO_PADRE del anexo),
*             SSI_ANEXOS_CABECERA (cabecera), SSI_ANEXOS_RESPUESTAS_V2 (detalle).
* Nota     : Si p_centro no existe en SSI_ESP_INTERVENCION, se usa ubigeo
*             fallback '0000' y CODIGO_NNA queda como 'SEC0000-...' para
*             identificación y migración posterior.
*/
create or replace PROCEDURE USP_CREAR_ANEXO_COMPLETO (
    p_id_anexo           IN NUMBER,
    p_id_centro          IN NUMBER,
    p_fecha_aplicacion   IN DATE,
    p_fecha_registro     IN DATE,   -- NUEVO PARAMETRO
    p_usu_registra       IN NUMBER,
    p_respuestas_json    IN CLOB,
    p_id_resp_supervision IN NUMBER,
    p_id_director       IN NUMBER,
    p_id_supervisado    IN VARCHAR2,
    p_periodo IN VARCHAR2,
    p_tipo IN VARCHAR2,
    p_acreditacion_vigente IN NUMBER,
    p_fecha_acreditacion IN DATE,
    p_modalidad IN VARCHAR2,
    p_centro IN VARCHAR2, -- * Nuevo
    p_id_servicio_padre IN NUMBER, -- * Nuevo
    p_id_cabecera        OUT NUMBER,
    p_correlativo        OUT NUMBER
)
AS
    v_id_cabecera      NUMBER;
    v_correlativo      NUMBER;
    v_ubigeo_dp_prov   VARCHAR2(4);
    v_anio_curso       VARCHAR2(4);
    v_corr_nna         NUMBER;
    v_codigo_nna       VARCHAR2(25);
BEGIN

    -- Generar código NNA: SEC[ubigeo dp+prov]-[año]-[correlativo 4 cifras]
    -- 1) Ubigeo (departamento + provincia) desde SSI_ESP_INTERVENCION
    -- * Fallback: si el centro no existe, usar '0000' como marcador explícito
    BEGIN
       SELECT SUBSTR(ei.ESP_UBIGEO, 1, 4)
       INTO v_ubigeo_dp_prov
       FROM SSI_ESP_INTERVENCION ei
       WHERE ei.ESP_NOMBRE = p_centro
          AND ei.ID_SERVICIO_PADRE = p_id_servicio_padre
          AND NVL(ei.ESP_ELIMINADO, 0) = 0
          AND ROWNUM = 1;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN
          v_ubigeo_dp_prov := '0000';  -- * Centro no registrado: marcador explícito para migración posterior
    END;

    -- 2) Año en curso
    v_anio_curso := TO_CHAR(SYSDATE, 'YYYY');

    -- 3) Correlativo global por servicio padre
    SELECT COUNT(*) + 1
    INTO v_corr_nna
    FROM SSI_ANEXOS_CABECERA cab
    JOIN SSI_ANEXO a
      ON a.ID_ANEXO = cab.ID_ANEXO
    WHERE a.ID_SERVICIO_PADRE = p_id_servicio_padre;

    -- 4) Concatenar código NNA
    v_codigo_nna := 'SEC' || v_ubigeo_dp_prov || '-' || v_anio_curso
                 || '-' || LPAD(TO_CHAR(v_corr_nna), 4, '0');

    -- Generar correlativo por anexo + centro
    SELECT NVL(MAX(CORRELATIVO), 0) + 1
    INTO v_correlativo
    FROM SSI_ANEXOS_CABECERA
    WHERE
        ID_ANEXO = p_id_anexo
        AND ID_CENTRO = p_id_centro;

    -- Insertar cabecera
    INSERT INTO SSI_ANEXOS_CABECERA (
        ID_ANEXO_CABECERA,
        ID_ANEXO,
        ID_CENTRO,
        CORRELATIVO,
        FECHA_APLICACION,
        FECHA_REGISTRO,      -- NUEVO CAMPO
        USU_REGISTRA,
        FECHA_REGISTRA,
        ID_RESP_SUPERVISION,
        ID_DIRECTOR,
        ID_SUPERVISADO,
        PERIODO,
        TIPO,
        ACREDITACION_VIGENTE,
        FECHA_ACREDITACION,
        MODALIDAD,
        CENTRO, -- * Nuevo
        CODIGO_NNA -- * Nuevo
    )
    VALUES (
        SEQ_SSI_ANEXOS_CAB.NEXTVAL,
        p_id_anexo,
        p_id_centro,
        v_correlativo,
        p_fecha_aplicacion,
        p_fecha_registro,    -- NUEVO VALOR
        p_usu_registra,
        SYSDATE,
        p_id_resp_supervision,
        p_id_director,
        p_id_supervisado,
        p_periodo,
        p_tipo,
        p_acreditacion_vigente,
        p_fecha_acreditacion,
        p_modalidad,
        p_centro, -- * Nuevo
        v_codigo_nna -- * Nuevo
    )
    RETURNING ID_ANEXO_CABECERA INTO v_id_cabecera;


    -- Insertar detalle
    FOR r IN (
        SELECT *
        FROM JSON_TABLE(
            p_respuestas_json,
            '$[*]'
            COLUMNS (
                pf_id_familia       NUMBER PATH '$.idFamilia',
                fi_id_integrante    NUMBER PATH '$.idIntegrante',
                ap_id_pregunta      NUMBER PATH '$.idPregunta',
                ar_respuesta        VARCHAR2(4000) PATH '$.respuesta',
                ar_respuesta2       VARCHAR2(4000) PATH '$.respuesta2',
                ar_observacion      VARCHAR2(4000) PATH '$.observacion',
                ar_puntaje          NUMBER PATH '$.puntaje'
            )
        )
    ) LOOP

        INSERT INTO SSI_ANEXOS_RESPUESTAS_V2 (
            AR_ID_RESPUESTA,
            ID_ANEXO,
            ID_CENTRO,
            CORRELATIVO,
            FECHA_APLICACION,
            PF_ID_FAMILIA,
            FI_ID_INTEGRANTE,
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
            r.pf_id_familia,
            r.fi_id_integrante,
            r.ap_id_pregunta,
            r.ar_respuesta,
            r.ar_respuesta2,
            r.ar_observacion,
            r.ar_puntaje,
            p_usu_registra,
            SYSDATE
        );

    END LOOP;

    p_id_cabecera := v_id_cabecera;
    p_correlativo := v_correlativo;

EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20001,
         'USP_CREAR_ANEXO_COMPLETO: ' || SQLERRM
         || ' (SQLCODE=' || SQLCODE || ')');
END;
/

-- ! `

SELECT 
    i.ID_SERVICIO_PADRE,
    i.*
FROM SSI_ESP_INTERVENCION i
ORDER BY
    i.ID_ESP_INTERV ASC
/

UPDATE SSI_ESP_INTERVENCION i
    SET 
        i.ID_SERVICIO_PADRE = 4
WHERE
    i.ID_SERVICIO_PADRE IS NULL
/

-- ? ROLLBACK;