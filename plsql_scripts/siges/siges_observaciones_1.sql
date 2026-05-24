-- * I. Levantamiento de observaciones de Excel.

-- * Anexo 13: Falta agregar el campo en  la ficha, sólo se activa si la respuesta es la opción "Si" en la pgta. 2.4

-- * 13.1 Actualizar `AP_NUM_PREGUNTA` → `2705`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET p.AP_NUM_PREGUNTA = 6
WHERE 
   p.AP_ID_PREGUNTA = 2705
/

-- ! COMMIT;
-- ! ROLLBACK;

-- * 13.2 ...
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = NULL,
      p.AP_OBLIGATORIA1 = 0,
      p.AP_TIPO_CONTROL2 = NULL,
      p.AP_PREGUNTA2 = NULL
WHERE 
   p.AP_ID_PREGUNTA = 2705
/

UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_OBLIGATORIA1 = 1,
      p.SI_ID_SERVICIO2 = 5
WHERE 
   p.AP_ID_PREGUNTA IN (4242, 4243)
/

-- ! COMMIT;
-- ! ROLLBACK;

-- * 13.3 ...

INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, SI_ID_SERVICIO2) 
VALUES (4242,4,13,1,7,'Nombre de servicio', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'{"id":2705,"valor":"Sí"}',5);
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, SI_ID_SERVICIO2) 
VALUES (4243,4,13,1,8,'Tiempo al elegir', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'{"id":2705,"valor":"Sí"}',5);
-- ! COMMIT;
-- ! ROLLBACK;

-- * Anexo 15: ...
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      2891, 2892, 2893, 2894, 2895, 2896
   )
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * Anexo 16: ...
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3010, 3011, 3012, 3013, 3014, 3015
   )
/
-- ! COMMIT;
-- ! ROLLBACK;

INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4244,4,15,1,63,'Comentarios:', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'',0,5);
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4245,4,16,2,113,'Comentarios:', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'',0,5);
-- ! COMMIT;
-- ! ROLLBACK;

-- * Anexo 21: ...

-- * 21.1
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3154
   )
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * Anexo 22: ...

-- * 22.1
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4246,4,22,1,28,'Detalle:', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'{"id":3183,"valor":"Otro"}',0,6);
-- ! COMMIT;
-- ! ROLLBACK;

-- * 22.1

-- * 22.1 Actualizado en frontend

-- * 22.2
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
   p.AP_TIPO_CONTROL = 'label'
WHERE
   p.AP_ID_PREGUNTA = 3192
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 22.3 Eliminar pregunta `Total`
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3214
   )
/
-- ! COMMIT;
-- ! ROLLBACK;


-- * Anexo 26: ...

-- * 26.1  Modificar pregunta por `II. INFORMACIÓN PERSONAL`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
   p.AP_PREGUNTA = 'II. INFORMACIÓN PERSONAL'
WHERE
   p.AP_ID_PREGUNTA = 3292
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 26.2 
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4247,4,26,1,16,'Detalle:', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'{"id":3298,"valor":"OTROS"}',0,7);
-- ! COMMIT;
-- ! ROLLBACK;


-- * 26.2 Cambiar la pregunta por `label`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_TIPO_CONTROL = 'label',
      p.AP_OPCIONES = NULL,
      p.AP_OBLIGATORIA1 = 0
WHERE
   p.AP_ID_PREGUNTA = 3319
/

UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_OPCIONES = 'Sí | No | No sé'
WHERE
   p.AP_ID_PREGUNTA = 2089
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 26.3 Eliminar pregunta `Total`
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3340
   )
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * Anexo 27: ...

-- * 27.1 Adicionar pregunta opcional
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4248,4,27,1,15,'Detalle:', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'{"id":3352,"valor":"OTROS"}',0,7)
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 27.2 Eliminar pregunta
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3379
   )
/
-- ! COMMIT;
-- ! ROLLBACK;


-- * Anexo 30: ...

-- * 30.1 Eliminar espacios
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_TIPO_CONTROL = TRIM(p.AP_TIPO_CONTROL)
WHERE
   p.AP_ID_PREGUNTA = 3430
/
-- ! COMMIT;
-- ! ROLLBACK;


-- * Anexo 31: ...

-- * 31.1 Actualizar obligatoriedad a `0`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_OBLIGATORIA2 = 0
WHERE
   p.AP_ID_PREGUNTA IN (
      3466, 3467, 3468, 3469, 3470, 3472, 3473, 3474, 3475, 3476, 3477, 3478, 3479, 3480, 3482, 3483, 3484, 3485, 3486, 3487, 3488, 3489
   )
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 31.2 Eliminar pregunta `Total`
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3491
   )
/
-- ! COMMIT;
-- ! ROLLBACK;


-- * Anexo 32: ...

-- * 32.1 Eliminar pregunta `Total`
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3517
   )
/
-- ! COMMIT;
-- ! ROLLBACK;


-- * Anexo 33: ...

-- * 33.1 Inserta la pregunta que mustra las secciones
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4249,4,33,2,0,'ELIGE LA SECCIÓN A MOSTRAR:', SYSDATE, NULL, 0, NULL,'A|B','select',-1,-1,'',1,9);
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 33.2 Sección a mostrar

-- * 33.2.1 `A`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4249,"valor":"A"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3527, 3528, 3529, 3530, 3531, 3532, 3533
   )
/

-- * 33.2.1 `B`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4249,"valor":"B"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3534, 3535, 3536, 3537, 3538, 3539, 3540, 3541, 3542, 3543
   )
/

-- ! COMMIT;
-- ! ROLLBACK;


-- * Anexo 34: ...

-- * 34.1 Inserta la pregunta que mustra las secciones
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4250,4,34,2,0,'ELIGE LA SECCIÓN A MOSTRAR:', SYSDATE, NULL, 0, NULL,'A | B','select',-1,-1,'',1,9);
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 34.2 Sección a mostrar

-- * 34.2.1 `A`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4250,"valor":"A"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3553, 3554, 3555, 3556, 3557
   )
/

-- * 34.2.1 `B`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4250,"valor":"B"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3558, 3559, 3560, 3561, 3562, 3564, 3566, 3567, 3569
   )
/


-- * Anexo 37: ...

-- * 37.1 Inserta la pregunta que mustra las secciones
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4251,4,37,3,1,'ELIGE LA SECCIÓN A MOSTRAR:', SYSDATE, NULL, 0, NULL,'SUPERVISOR|ACOMPAÑANTE PROFESIONAL','select',-1,-1,'',1,9);
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 37.2 Sección a mostrar

-- * 37.2.1 `A`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4251,"valor":"SUPERVISOR"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3638, 3639, 3640, 3641, 3642, 3643, 3644, 3645
   )
/

-- * 37.2.1 `B`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4251,"valor":"ACOMPAÑANTE PROFESIONAL"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3647, 3648, 3649, 3650, 3651, 3652, 3653, 3654, 3655, 3656, 3657, 3658, 3659, 3660, 3661, 3662, 3663, 3664, 3665, 3666, 3668, 3669, 3670, 3671, 3672, 3673, 3675, 3676, 3677, 3678, 3679, 3680, 3681
   )
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 37.3 ...
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4252,4,37,1,15,'Detalle Otro:', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'{"id":3634,"valor":"OTRO"}',0,9);
/
-- ! COMMIT;
-- ! ROLLBACK;


-- * 37.4 Eliminar pregunta `total`
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3683
   )
/
-- ! COMMIT;
-- ! ROLLBACK;


-- * Anexo 38: ...

-- * 38.1 Inserta la pregunta que mustra las secciones
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4254,4,38,3,1,'ELIGE LA SECCIÓN A MOSTRAR:', SYSDATE, NULL, 0, NULL,'ESPECIALISTA DE SEGUIMIENTO|ESPECIALISTA DE ACOMPAÑAMIENTO|ESPECIALISTA EN GESTION DE PADRON','select',-1,-1,'',0,9);
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * 38.2 Sección a mostrar

-- * 38.2.1 `A`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4254,"valor":"ESPECIALISTA DE SEGUIMIENTO"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3695, 3696, 3697, 3698, 3699, 3700, 3701, 3702
   )
/

-- * 38.2.2 `B`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4254,"valor":"ESPECIALISTA DE ACOMPAÑAMIENTO"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3704, 3705, 3706, 3707, 3708, 3709, 3710, 3711, 3712, 3713
   )
/

-- * 38.2.3 `C`
UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      p.AP_CONDICION = '{"id":4254,"valor":"ESPECIALISTA EN GESTION DE PADRON"}'
WHERE 
   p.AP_ID_PREGUNTA IN (
      3715, 3716, 3717, 3718, 3719, 3720, 3721, 3722, 3723, 3724, 3725, 3726, 3727, 3728, 3729, 3731, 3732, 3733
   )
/
-- ! COMMIT;
-- ! ROLLBACK;


-- * ANEXO 40: ...

-- * 40.1 
INSERT INTO SSI_ANEXOS_PREGUNTAS(AP_ID_PREGUNTA, SI_ID_SERVICIO, AP_NUM_ANEXO, AP_NUM_GRUPO, AP_NUM_PREGUNTA, AP_PREGUNTA, AP_FECHA_REGISTRO, AP_FECHA_ELIMINACION,  AP_ELIMINADO, AP_TIPOCAMPO, AP_OPCIONES, AP_TIPO_CONTROL, AP_CONDICION_SI, AP_CONDICION_NO, AP_CONDICION, AP_OBLIGATORIA1, SI_ID_SERVICIO2) 
VALUES (4253,4,40,1,8,'Detalle:', SYSDATE, NULL, 0, NULL,'','text',-1,-1,'{"id":3809,"valor":"OTRO"}',0,10);
/
-- ! COMMIT;
-- ! ROLLBACK;

-- * ANEXO 42: ...

-- * 42.1 Eliminar campo `total`
DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_ID_PREGUNTA IN
   (
      3890
   )
/
-- ! COMMIT;
-- ! ROLLBACK;



-- * II. Levantamiento de observaciones de reunión.


-- * 2.1 Actualizar ubigeo y nombre

-- * 2.1.1 Actualizar ubigeo y nombre
UPDATE SSI_ESP_INTERVENCION i
   SET 
      i.ESP_NOMBRE = 'SEDE CENTRAL',
      i.ESP_UBIGEO = '150121', -- Sede Central Pueblo libre
      i.ESP_NOMBRE_RESPONSABLE = 'SEDE CENTRAL'
WHERE
   i.ID_ESP_INTERV = 23
/

-- * 2.1.2 Actualizar ubigeo y nombre
INSERT INTO SSI_ESP_INTERVENCION (ID_ESP_INTERV, ID_SERVICIO, ESP_NOMBRE, ESP_UBIGEO, ESP_NOMBRE_RESPONSABLE, ID_UNIDADORGANICA_PADRE) 
VALUES (23, 9, 'SEDE CENTRAL 1', 150121, 'SEDE CENTRAL 2', 1146);
/

INSERT INTO SSI_ESP_INTERVENCION (ID_ESP_INTERV, ID_SERVICIO, ESP_NOMBRE, ESP_UBIGEO, ESP_NOMBRE_RESPONSABLE, ID_UNIDADORGANICA_PADRE) 
VALUES (24, 10, 'SEDE CENTRAL 2', 150121, 'SEDE CENTRAL 2', 1166);
/

SELECT * FROM SSI_ESP_INTERVENCION i
ORDER BY
   i.ID_ESP_INTERV DESC
/

/* DELETE SSI_ESP_INTERVENCION i
WHERE
   i.ID_ESP_INTERV IN (23, 24, 25) 
/ */

-- ! COMMIT;
-- ! ROLLBACK;

-- * 2.2 Cambiar de tipo NUMBER a VARCHAR2
ALTER TABLE SSI_ANEXOS_CABECERA
   DROP COLUMN ID_SUPERVISADO
/

ALTER TABLE SSI_ANEXOS_CABECERA
   ADD ID_SUPERVISADO VARCHAR2(500) NULL
/

-- ! COMMIT;
-- ! ROLLBACK;


-- * 2.3 Validación de la fichas (🕜)

-- * 2.3.1 Adicionar columna que de los usuarios que validan la ficha
ALTER TABLE SSI_ANEXOS_CABECERA
   ADD IDS_PERSONAL_VALIDA VARCHAR2(255) NULL
/
-- ! COMMIT;


-- * 2.3.2 Actualiza personal que valida la ficha

CREATE OR REPLACE PROCEDURE USP_SAVE_PERSONAL_VALIDA_ANEXO
(
   p_id_anexo_cabecera IN NUMBER,
   p_ids_personal IN VARCHAR2
)
IS
   id_centro_ref NUMBER;
BEGIN

   BEGIN

      SAVEPOINT SAVE_PERSONAL_VALIDA_ANEXO;

      UPDATE SSI_ANEXOS_CABECERA ac
         SET ac.IDS_PERSONAL_VALIDA = (
            CASE
               WHEN (p_ids_personal = '' OR p_ids_personal IS NULL) THEN ''
               ELSE (
                  CASE
                     WHEN (ac.IDS_PERSONAL_VALIDA = '' OR ac.IDS_PERSONAL_VALIDA IS NULL) THEN p_ids_personal
                     ELSE (ac.IDS_PERSONAL_VALIDA || '|' || p_ids_personal)
                  END
               )
            END
         )
      WHERE
         ac.ID_ANEXO_CABECERA = p_id_anexo_cabecera;

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT SAVE_PERSONAL_VALIDA_ANEXO;
         DBMS_OUTPUT.PUT_LINE('Error al actualizar el personal que valida el anexo: ' || SQLERRM);
         RAISE;
   END;

END USP_SAVE_PERSONAL_VALIDA_ANEXO;
/

-- Llamar al procedimiento almacenado:
BEGIN
   USP_SAVE_PERSONAL_VALIDA_ANEXO(103, '1642');
END;
/

-- ! COMMIT;


-- * 2.3.3 Conformidad a la ficha

CREATE OR REPLACE PROCEDURE USP_SAVE_CONFORMIDAD_ANEXO_CABECERA
(
   p_id_anexo_cabecera IN NUMBER,
   p_estado IN NUMBER -- ? (1) → REGISTRADO | (2) → CERRADO 
)
IS
   id_centro_ref NUMBER;
BEGIN

   BEGIN

      SAVEPOINT SAVE_CONFORMIDAD_ANEXO_CABECERA;

      UPDATE SSI_ANEXOS_CABECERA ac
         SET ac.ESTADO = p_estado
      WHERE
         ac.ID_ANEXO_CABECERA = p_id_anexo_cabecera;

      COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK TO SAVEPOINT SAVE_CONFORMIDAD_ANEXO_CABECERA;
         DBMS_OUTPUT.PUT_LINE('Error al dar la conformidad al anexo: ' || SQLERRM);
         RAISE;
   END;

END USP_SAVE_CONFORMIDAD_ANEXO_CABECERA;
/

-- Llamar al procedimiento almacenado:
BEGIN
   USP_SAVE_CONFORMIDAD_ANEXO_CABECERA(103, 2);
END;
/
-- ! COMMIT;


-- * 2.4 Carga de 5 audios. (🕜)

-- * 2.4.1 
CREATE SEQUENCE SEQ_ACA_ID_AUDIO START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE
/

CREATE TABLE SSI_ANEXO_CABECERA_AUDIO
(
   ACA_ID_AUDIO NUMBER PRIMARY KEY,
   ID_ANEXO_CABECERA NUMBER NOT NULL,
   ACA_AUDIO BLOB NOT NULL,
   ACA_NOMBRE_ARCHIVO VARCHAR2(500) NOT NULL,
   ACA_FECHA_REGISTRO DATE DEFAULT SYSDATE,
   ACA_ESTADO NUMBER(1) DEFAULT 1,
   ACA_ELIMINADO NUMBER(1) DEFAULT 0 CHECK (ACA_ELIMINADO IN (0, 1))
)
/

-- ! COMMIT;

-- * 2.4.2 
CREATE OR REPLACE PROCEDURE USP_CRUD_ANEXO_CABECERA_AUDIO
(
   p_operacion           IN NUMBER,    -- ? (1) INSERTAR | (2) ACTUALIZAR | (3) ELIMINAR | (4) CONSULTAR
   p_id_audio            IN NUMBER,    -- Requerido para UPDATE, DELETE, SELECT
   p_id_anexo_cabecera   IN NUMBER,    -- Requerido para INSERT
   p_audio               IN BLOB,      -- Requerido para INSERT, UPDATE
   p_nombre_archivo      IN VARCHAR2,  -- Requerido para INSERT, UPDATE
   p_estado              IN NUMBER,    -- Requerido para UPDATE
   p_cursor              OUT SYS_REFCURSOR
)
IS
BEGIN

   -- ========================
   -- (1) INSERTAR
   -- ========================
   IF p_operacion = 1 THEN
      BEGIN
         SAVEPOINT SAVE_INSERT_ANEXO_CABECERA_AUDIO;

         INSERT INTO SSI_ANEXO_CABECERA_AUDIO
         (
            ACA_ID_AUDIO,
            ID_ANEXO_CABECERA,
            ACA_AUDIO,
            ACA_NOMBRE_ARCHIVO
         )
         VALUES
         (
            SEQ_ACA_ID_AUDIO.NEXTVAL,
            p_id_anexo_cabecera,
            p_audio,
            p_nombre_archivo
         );

         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT SAVE_INSERT_ANEXO_CABECERA_AUDIO;
            DBMS_OUTPUT.PUT_LINE('Error al insertar el audio del anexo: ' || SQLERRM);
            RAISE;
      END;

   -- ========================
   -- (2) ACTUALIZAR
   -- ========================
   ELSIF p_operacion = 2 THEN
      BEGIN
         SAVEPOINT SAVE_UPDATE_ANEXO_CABECERA_AUDIO;

         UPDATE SSI_ANEXO_CABECERA_AUDIO
            SET ACA_AUDIO          = p_audio,
                ACA_NOMBRE_ARCHIVO = p_nombre_archivo,
                ACA_ESTADO         = p_estado
         WHERE
            ACA_ID_AUDIO    = p_id_audio
            AND ACA_ELIMINADO = 0;

         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT SAVE_UPDATE_ANEXO_CABECERA_AUDIO;
            DBMS_OUTPUT.PUT_LINE('Error al actualizar el audio del anexo: ' || SQLERRM);
            RAISE;
      END;

   -- ========================
   -- (3) ELIMINAR (lógico)
   -- ========================
   ELSIF p_operacion = 3 THEN
      BEGIN
         SAVEPOINT SAVE_DELETE_ANEXO_CABECERA_AUDIO;

         UPDATE SSI_ANEXO_CABECERA_AUDIO
            SET ACA_ELIMINADO = 1
         WHERE
            ACA_ID_AUDIO = p_id_audio;

         COMMIT;
      EXCEPTION
         WHEN OTHERS THEN
            ROLLBACK TO SAVEPOINT SAVE_DELETE_ANEXO_CABECERA_AUDIO;
            DBMS_OUTPUT.PUT_LINE('Error al eliminar el audio del anexo: ' || SQLERRM);
            RAISE;
      END;

   -- ========================
   -- (4) CONSULTAR
   -- ========================
   ELSIF p_operacion = 4 THEN
      OPEN p_cursor FOR
         SELECT
            ACA_ID_AUDIO,
            ID_ANEXO_CABECERA,
            ACA_AUDIO,
            ACA_NOMBRE_ARCHIVO,
            ACA_FECHA_REGISTRO,
            ACA_ESTADO
         FROM SSI_ANEXO_CABECERA_AUDIO
         WHERE
            ID_ANEXO_CABECERA = p_id_anexo_cabecera
            AND ACA_ELIMINADO      = 0;

   ELSE
      DBMS_OUTPUT.PUT_LINE('Operación no válida: ' || p_operacion);

   END IF;

END USP_CRUD_ANEXO_CABECERA_AUDIO;
/

-- ! COMMIT;

-- * 2.5 Considerar registro de campos `PERIRIO` y `TIPO` al registrar la FICHA. (🕜)


-- * 2.5.1 Crear campos `PERIRIO` | `TIPO`. (🕜)

ALTER TABLE SSI_ANEXOS_CABECERA
   ADD PERIODO VARCHAR2(55) NULL
/

ALTER TABLE SSI_ANEXOS_CABECERA
   ADD TIPO VARCHAR2(55) NULL
/

-- ! COMMIT;

-- * 2.5.2 Agrear columna que indica si anexo requiere validación 
ALTER TABLE SSI_ANEXO
   ADD ANX_REQ_VALIDACION NUMBER DEFAULT 1
/
-- ! COMMIT;

-- * 2.5.3 Agrear columna que indica si anexo requiere supervisados 
ALTER TABLE SSI_ANEXO
   ADD ANX_REQ_SUPERVISADOS NUMBER DEFAULT 1
/
-- ! COMMIT;

SELECT 
   a.*
FROM SSI_ANEXO a
/


-- ! Test
UPDATE SSI_ANEXO
   -- SET ANX_REQ_VALIDACION = 1
   SET ANX_REQ_SUPERVISADOS = 1
/

SELECT 
   COUNT(1)
FROM TGUNIDADORGANICA U
INNER JOIN TRPERSONAL TR ON U.IDUNIDADORGANICA = TR.PRHUNIDADORGANICA
INNER JOIN TGPERSONA PER ON PER.IDPERSONA = TR.PRHPERSONA
WHERE 
   U.UORNOMBRE = 'UNIDAD DE ADMINISTRACIÓN' -- 647
   -- u.UOR_UNIDAD_PADRE = 90 -- ? 'SEDE CENTRAL'
/


SELECT * FROM SSI_ANEXO_CABECERA_AUDIO ac
/

SELECT * FROM SSI_ANEXOS_CABECERA ac
ORDER BY
   ac.ID_ANEXO_CABECERA DESC
/

SELECT * FROM SSI_ANEXOS_CABECERA ac
WHERE
   ac.ID_ANEXO_CABECERA = 1
/

SELECT * FROM ALL_TAB_COLS c
WHERE 
   c.TABLE_NAME = 'SSI_ANEXOS_CABECERA'
   -- AND c.COLUMN_NAME LIKE'%PRO%'
/



SELECT * FROM SSI_ESP_INTERVENCION
/

SELECT * FROM SSI_ESP_INTERVENCION i
ORDER BY
   i.ID_ESP_INTERV DESC
/


SELECT 
   pe.*
   -- p.*
   -- u.*
FROM TGPERSONA p 
JOIN TSUSUARIO u ON p.IDPERSONA = u.USUPERSONA
JOIN TRPERSONAL pe ON p.IDPERSONA = pe.PRHPERSONA
WHERE
   p.PERNRODOCUMENTO = '46392613'
/

SELECT * FROM TRPERSONAL
/

SELECT * FROM TSUSUARIO
/

SELECT * FROM TSUSUARIO
/

SELECT * FROM SSI_ESP_INTERVENCION i
ORDER BY 
   i.ID_ESP_INTERV DESC
/

SELECT * FROM SSI_UBIGEO_NOMBRES un
WHERE
   un.U_DISTRITO LIKE '%PUEBLO%'
/














-- ! Test

-- ! 1. Eliminar pregunta
/* DELETE FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.AP_ID_PREGUNTA = 4254 */
/

-- ! 1. Actualizar correlativo de pregunta
/* UPDATE SSI_ANEXOS_PREGUNTAS p
   SET p.AP_NUM_PREGUNTA = p.AP_NUM_PREGUNTA + 1
WHERE
   p.AP_ID_PREGUNTA IN (
      3695, 3696, 3697, 3698, 3699, 3700, 3701, 3702, 3704, 3705, 3706, 3707, 3708, 3709, 3710, 3711, 3712, 3713, 3715, 3716, 3717, 3718, 3719, 3720, 3721, 3722, 3723, 3724, 3725, 3726, 3727, 3728, 3729, 3731, 3732, 3733, 3736
   ) */
/


/* UPDATE SSI_ANEXOS_PREGUNTAS p
   SET 
      -- p.AP_CONDICION = NULL
      -- p.AP_OBLIGATORIA1 = 0,
      -- p.AP_TIPO_CONTROL2 = NULL,
      p.AP_TIPO_CONTROL = 'selectM'
      -- p.AP_PREGUNTA2 = NULL
      -- p.AP_PREGUNTA = 'Tiempo' -- Tiempo
WHERE 
   -- p.AP_ID_PREGUNTA = 4242
   p.AP_ID_PREGUNTA = 3183
/ */

-- ! 2. Identificar anexos en preguntas
SELECT 
   p.* 
   -- p.Si_ID_SERVICIO
   -- (p.AP_ID_PREGUNTA || '-' || p.AP_NUM_PREGUNTA) AS KEY
FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_NUM_ANEXO = 1
   -- AND p.AP_ID_PREGUNTA = 4254
   -- AND p.AP_NUM_GRUPO = 2
   -- AND p.AP_NUM_PREGUNTA BETWEEN 1 AND 10
ORDER BY
   -- p.AP_ID_PREGUNTA
   p.AP_NUM_GRUPO,
   p.AP_NUM_PREGUNTA
   -- p.AP_NUM_ANEXO;
/

-- ! 3. ...
SELECT 
   ac.* 
   -- COUNT(1)
FROM SSI_ANEXOS_CABECERA ac
WHERE 
   ac.ID_ANEXO = 1
/


-- ! 4. Obtener ANX_CODIGO2 por anexo
SELECT
   a.ANX_CODIGO2,
   a.* 
FROM SSI_ANEXO a
WHERE
   -- a.ANX_NOMBRE  LIKE '%ASISTENC%'
   -- LOWER(a.ANX_SERVICIO)  LIKE '%sistenc%'
   -- a.ANX_ID_SERVICIO = 5
   a.ID_ANEXO = 1
/

-- ! 2 Preguntas por servicio SIGES
SELECT 
   -- p.SI_ID_SERVICIO2
   -- p.* 
   -- p.SI_ID_SERVICIO
   p.AP_PREGUNTA2,
   COUNT(1)
FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   -- p.SI_ID_SERVICIO = 4 -- SIGES
   -- AND p.AP_NUM_ANEXO = 13
   -- p.SI_ID_SERVICIO2 = 9
   -- p.SI_ID_SERVICIO2 IS NOT NULL
   p.AP_PREGUNTA2 IS NOT NULL
GROUP BY
   p.AP_PREGUNTA2
   -- p.SI_ID_SERVICIO2
   -- p.SI_ID_SERVICIO
ORDER BY 2 DESC
/

-- ! 3. Servicios SIGES
SELECT 
   -- a.ANX_ID_SERVICIO
   a.*
FROM SSI_ANEXO a
/* WHERE
   a.ANX_CODIGO2 = 'GE_INA01' */
/* GROUP BY
   a.ANX_ID_SERVICIO */
/

UPDATE SSI_ANEXO a
   SET 
      a.ANX_NOMBRE = 'Guía de Entrevista al Equipo Técnico de Inabif en Acción'
WHERE
   a.ID_ANEXO = 41
/

-- ! COMMIT;

-- ! 4. Anexos cabecera SIGES
SELECT 
   ac.* 
   -- COUNT(1)
FROM SSI_ANEXOS_CABECERA ac
/* WHERE 
   ac.ID_ANEXO = 13 */
/

SELECT * FROM TGUBIGEO
/

-- ! 5. Analiza preguntas condicionales

SELECT 
   p.AP_CONDICION
   -- p.* 
FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   -- p.SI_ID_SERVICIO = 4 -- SIGES
   -- AND p.AP_NUM_ANEXO = 13
   p.AP_CONDICION IS NOT NULL
   -- AND TRIM(p.AP_TIPO_CONTROL) = 'text'
ORDER BY
   p.AP_CONDICION
/


-- ! 6. Obtener el ultimo `idPregunta`
SELECT 
   -- MAX(p.AP_ID_PREGUNTA) -- DEV: 4241 | TEST: 1751 | PROD: 1791
   -- p.AP_ID_PREGUNTA
   p.*
FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.AP_ID_PREGUNTA IN (4242, 4243)
/

-- ! 7. Obtener el `AP_TIPO_CONTROL`
SELECT 
   -- TRIM(p.AP_TIPO_CONTROL) AS AP_TIPO_CONTROL
   p.AP_TIPO_CONTROL,
   -- p.AP_TIPO_CONTROL2,
   p.AP_OPCIONES,
   COUNT(1)
FROM SSI_ANEXOS_PREGUNTAS p
WHERE 
   p.SI_ID_SERVICIO = 4 -- SIGES
   -- AND p.AP_TIPO_CONTROL IS NOT NULL
   -- AND p.AP_TIPO_CONTROL2 IS NOT NULL 
   AND p.AP_OPCIONES IS NOT NULL
GROUP BY
   -- p.AP_TIPO_CONTROL2
   -- p.AP_TIPO_CONTROL,
   p.AP_OPCIONES
ORDER BY 3 DESC
/

-- ! 8. Obtener options de select
SELECT 
   -- p.* 
   AP_OPCIONES
FROM SSI_ANEXOS_PREGUNTAS p
WHERE
   p.SI_ID_SERVICIO = 4 -- SIGES
   AND p.AP_NUM_ANEXO = 38
   AND p.AP_TIPO_CONTROL = 'select'
   -- AND p.AP_ID_PREGUNTA = 4254
/


-- ! 9. Listar anexos respuestas SIGES
SELECT * FROM SSI_ANEXOS_CABECERA ac
ORDER BY ac.ID_ANEXO_CABECERA DESC
/

SELECT * FROM SSI_ANEXOS_RESPUESTAS_V2 ar
ORDER BY ar.AR_ID_RESPUESTA DESC
/



SELECT 
   u.UOR_DIRECTOR,
   u.*
   /* TR.IDPERSONAL,
   U.UORNOMBRE,
   U.UORABREVIATURA,
   PER.PERNOMBRE || ' ' ||
   PER.PERAPEPATERNO || ' ' ||
   PER.PERAPEMATERNO AS NOMBRES */
FROM TGUNIDADORGANICA U
-- INNER JOIN TRPERSONAL TR ON U.IDUNIDADORGANICA = TR.PRHUNIDADORGANICA
-- INNER JOIN TGPERSONA PER ON PER.IDPERSONA = TR.PRHPERSONA
WHERE 
   -- U.UORNOMBRE = 'CEDIF AÑO NUEVO' 
   -- U.UORNOMBRE = 'CAR ARCO IRIS' 
   U.IDUNIDADORGANICA = 90
   -- AND TR.PRHESTADO = 1
-- ORDER BY NOMBRES
/


SELECT 
      TR.IDPERSONAL AS IDPERSONAL,
      U.UORNOMBRE AS UORNOMBRE,
      U.UORABREVIATURA AS UORABREVIATURA,
      (
            PER.PERNOMBRE || ' ' ||
            PER.PERAPEPATERNO || ' ' ||
            PER.PERAPEMATERNO
      ) AS NOMBRES,
      u.*
   FROM TGUNIDADORGANICA U
   INNER JOIN TRPERSONAL TR ON U.IDUNIDADORGANICA = TR.PRHUNIDADORGANICA
   INNER JOIN TGPERSONA PER ON PER.IDPERSONA = TR.PRHPERSONA
   WHERE 
      TR.PRHESTADO = 1
      -- AND u.IDUNIDADORGANICA = 140
      -- AND u.IDUNIDADORGANICA = 1146 -- SEDE CENTRO 1
      AND u.IDUNIDADORGANICA = 1166 -- SEDE CENTRO 1
   ORDER BY NOMBRES
/

SELECT * FROM TGUNIDADORGANICA u
WHERE
   -- UORNOMBRE LIKE '%ASISTENCIA%' -- 1. SEDE CENTRO 1
   UORNOMBRE LIKE '%EMERGENCIA%'
/

-- INNER JOIN TRPERSONAL TR ON U.IDUNIDADORGANICA = TR.PRHUNIDADORGANICA


/* AND (
   PER.PERNOMBRE || ' ' ||
   PER.PERAPEPATERNO || ' ' ||
   PER.PERAPEMATERNO
) LIKE '%' || UPPER(p_nombre_persona)  || '%' */


/* [
   {
      "idPersonal": 1205,
      "nombre": "ABDIAS LISANDRO PARRA FIGUEROA"
   }
] */


-- COMMIT;


SELECT * FROM SSI_ANEXOS_CABECERA a
ORDER BY
   a.ID_ANEXO_CABECERA DESC
/


ROLLBACK;


SELECT
    column_name,
    data_type,
    data_length
FROM
    all_tab_columns
WHERE
    table_name = 'SSI_ANEXOS_CABECERA'
    AND column_name = 'IDS_SUPERVISADOS';


SELECT trigger_name, trigger_type, triggering_event
FROM all_triggers
WHERE table_name = 'SSI_ANEXOS_CABECERA';

SELECT constraint_name, search_condition
FROM all_constraints
WHERE table_name = 'SSI_ANEXOS_CABECERA' AND constraint_type = 'C';



SELECT object_name, object_type, status, last_ddl_time
FROM user_objects
WHERE object_name = 'USP_CREAR_ANEXO_COMPLETO';


-- * Datos para el registro de `FICHAS`

-- * 1. Consultan `Unidad` y `Servicio`
SELECT * FROM SSI_ANEXO a
/

-- * 2. ...
SELECT * FROM SSI_ESP_INTERVENCION i
ORDER BY
   i.ID_ESP_INTERV DESC
/

SELECT * FROM TGUNIDADORGANICA u
WHERE
   u.UOR_UNIDAD_PADRE = 90
/

-- 1166 | 24 | 948
-- 1146 | 23 | 17980
-- 90 | * | 835
UPDATE SSI_ESP_INTERVENCION i
   SET 
      i.ID_PERSONAL = 835
WHERE
   i.ID_ESP_INTERV NOT IN (23, 24)
/

-- ! COMMIT;



/* WHERE
   -- a.ANX_NOMBRE = UPPER('Servicio de atención de emergencias y urgencias "INABIF EN ACCIÓN')
   a.ANX_SERVICIO LIKE 'Servicio de atención de emergencias y urgencias%'
/ */


-- * III. Consulta solicitada: join de tablas relacionadas a SSI_CODIGOS_FAMILIAS
SELECT
   ser.SI_NOMBRE AS NOMBRE_SERVICIO,
   fam.PF_COD_FAMILIA AS CODIGO_FAMILIA,
   (
      intg.FI_NOMBRES || ' ' ||
      intg.FI_PRIMER_APE || ' ' ||
      intg.FI_SEGUNDO_APE
   ) AS NOMBRE_INTEGRANTE
FROM SSI_CODIGOS_FAMILIAS codf
INNER JOIN SSI_SERVICIOS_INABIF ser
   ON ser.SI_ID_SERVICIO = codf.SI_ID_SERVICIO
LEFT JOIN SSI_POTENCIALES_FAMILIAS fam
   ON fam.PF_ID_FAMILIA = codf.PF_ID_FAMILIA
LEFT JOIN SSI_FAMILIA_INTEGRANTES intg
   ON intg.FI_ID_INTEGRANTE = codf.FI_ID_INTEGRANTE
ORDER BY
   ser.SI_NOMBRE,
   fam.PF_COD_FAMILIA,
   NOMBRE_INTEGRANTE
/

-- * IV. Consulta solicitada: listar ZONAS, EQUIPOS y ALIADOS
WITH equipos_por_zona AS (
   SELECT
      et.ZO_ID_ZONA,
      LISTAGG(TO_CHAR(et.EQ_ID_EQUIPO), ', ') WITHIN GROUP (ORDER BY et.EQ_ID_EQUIPO) AS EQUIPOS
   FROM SSI_EQUIPO_TRABAJO et
   WHERE
      et.EQ_ELIMINADO = 0
      AND et.EQ_ESTADO = 1
   GROUP BY
      et.ZO_ID_ZONA
),
aliados_por_zona AS (
   SELECT
      al.ZO_ID_ZONA,
      LISTAGG(TO_CHAR(al.AL_ID_ALIADO), ', ') WITHIN GROUP (ORDER BY al.AL_ID_ALIADO) AS ALIADOS
   FROM SSI_ALIADOS al
   WHERE
      al.AL_ELIMINADO = 0
      AND al.AL_ESTADO = 1
   GROUP BY
      al.ZO_ID_ZONA
)
SELECT
   zo.ZO_ID_ZONA,
   zo.ZO_DESCRIPCION AS ZONA,
   NVL(epz.EQUIPOS, 'SIN EQUIPOS') AS EQUIPOS,
   NVL(apz.ALIADOS, 'SIN ALIADOS') AS ALIADOS
FROM SSI_ZONA_INTERVENCION zo
LEFT JOIN equipos_por_zona epz
   ON epz.ZO_ID_ZONA = zo.ZO_ID_ZONA
LEFT JOIN aliados_por_zona apz
   ON apz.ZO_ID_ZONA = zo.ZO_ID_ZONA
WHERE
   zo.ZO_ELIMINADO = 0
   AND zo.ZO_ESTADO = 1
ORDER BY
   zo.ZO_ID_ZONA
/

-- =============================================================
-- Tipo      : PROCEDURE
-- Nombre    : PRC_SSI_ANEXO_CAB_AUDIO_CRUD
-- Proposito : Ejecutar operaciones CRUD sobre la tabla
--             SSI_ANEXO_CABECERA_AUDIO.
-- Parametros:
--    p_accion             IN  VARCHAR2   -- C: Crear, R: Consultar, U: Actualizar, D: Eliminar logico
--    p_aca_id_audio       IN  SSI_ANEXO_CABECERA_AUDIO.ACA_ID_AUDIO%TYPE
--    p_id_anexo_cabecera  IN  SSI_ANEXO_CABECERA_AUDIO.ID_ANEXO_CABECERA%TYPE
--    p_aca_audio          IN  SSI_ANEXO_CABECERA_AUDIO.ACA_AUDIO%TYPE
--    p_aca_nombre_archivo IN  SSI_ANEXO_CABECERA_AUDIO.ACA_NOMBRE_ARCHIVO%TYPE
--    p_aca_estado         IN  SSI_ANEXO_CABECERA_AUDIO.ACA_ESTADO%TYPE
--    p_resultado_out      OUT NUMBER
--    p_mensaje_out        OUT VARCHAR2
--    p_cursor_out         OUT SYS_REFCURSOR
-- Autor     : ChatGPT
-- Fecha     : 23/05/2026
-- =============================================================
CREATE OR REPLACE PROCEDURE PRC_SSI_ANEXO_CAB_AUDIO_CRUD
(
   p_accion              IN  VARCHAR2,
   p_aca_id_audio        IN  SSI_ANEXO_CABECERA_AUDIO.ACA_ID_AUDIO%TYPE DEFAULT NULL,
   p_id_anexo_cabecera   IN  SSI_ANEXO_CABECERA_AUDIO.ID_ANEXO_CABECERA%TYPE DEFAULT NULL,
   p_aca_audio           IN  SSI_ANEXO_CABECERA_AUDIO.ACA_AUDIO%TYPE DEFAULT NULL,
   p_aca_nombre_archivo  IN  SSI_ANEXO_CABECERA_AUDIO.ACA_NOMBRE_ARCHIVO%TYPE DEFAULT NULL,
   p_aca_estado          IN  SSI_ANEXO_CABECERA_AUDIO.ACA_ESTADO%TYPE DEFAULT NULL,
   p_resultado_out       OUT NUMBER,
   p_mensaje_out         OUT VARCHAR2,
   p_cursor_out          OUT SYS_REFCURSOR
)
AS
   v_aca_id_audio     SSI_ANEXO_CABECERA_AUDIO.ACA_ID_AUDIO%TYPE;
   v_error_code       NUMBER;
   v_error_message    VARCHAR2(4000);
BEGIN
   p_resultado_out := 0;
   p_mensaje_out   := NULL;
   p_cursor_out    := NULL;

   IF UPPER(TRIM(p_accion)) = 'C' THEN
      v_aca_id_audio := NVL(p_aca_id_audio, SEQ_ACA_ID_AUDIO.NEXTVAL);

      INSERT INTO SSI_ANEXO_CABECERA_AUDIO
      (
         ACA_ID_AUDIO,
         ID_ANEXO_CABECERA,
         ACA_AUDIO,
         ACA_NOMBRE_ARCHIVO,
         ACA_FECHA_REGISTRO,
         ACA_ESTADO,
         ACA_ELIMINADO
      )
      VALUES
      (
         v_aca_id_audio,
         p_id_anexo_cabecera,
         p_aca_audio,
         p_aca_nombre_archivo,
         SYSDATE,
         NVL(p_aca_estado, 1),
         0
      );

      COMMIT;

      p_resultado_out := 1;
      p_mensaje_out   := 'Registro creado correctamente. ACA_ID_AUDIO=' || v_aca_id_audio;

   ELSIF UPPER(TRIM(p_accion)) = 'R' THEN
      OPEN p_cursor_out FOR
         SELECT
            aca.ACA_ID_AUDIO,
            aca.ID_ANEXO_CABECERA,
            aca.ACA_AUDIO,
            aca.ACA_NOMBRE_ARCHIVO,
            aca.ACA_FECHA_REGISTRO,
            aca.ACA_ESTADO,
            aca.ACA_ELIMINADO
         FROM SSI_ANEXO_CABECERA_AUDIO aca
         WHERE
            aca.ACA_ELIMINADO = 0
            AND (p_aca_id_audio IS NULL OR aca.ACA_ID_AUDIO = p_aca_id_audio);

      p_resultado_out := 1;
      p_mensaje_out   := 'Consulta ejecutada correctamente.';

   ELSIF UPPER(TRIM(p_accion)) = 'U' THEN
      IF p_aca_id_audio IS NULL THEN
         RAISE_APPLICATION_ERROR(-20010, 'Para actualizar, p_aca_id_audio es obligatorio.');
      END IF;

      UPDATE SSI_ANEXO_CABECERA_AUDIO aca
         SET
            aca.ID_ANEXO_CABECERA  = NVL(p_id_anexo_cabecera, aca.ID_ANEXO_CABECERA),
            aca.ACA_AUDIO          = CASE
                                        WHEN p_aca_audio IS NOT NULL THEN p_aca_audio
                                        ELSE aca.ACA_AUDIO
                                     END,
            aca.ACA_NOMBRE_ARCHIVO = NVL(p_aca_nombre_archivo, aca.ACA_NOMBRE_ARCHIVO),
            aca.ACA_ESTADO         = NVL(p_aca_estado, aca.ACA_ESTADO)
      WHERE
         aca.ACA_ID_AUDIO = p_aca_id_audio
         AND aca.ACA_ELIMINADO = 0;

      IF SQL%ROWCOUNT = 0 THEN
         RAISE_APPLICATION_ERROR(-20011, 'No se encontro registro activo para actualizar.');
      END IF;

      COMMIT;

      p_resultado_out := 1;
      p_mensaje_out   := 'Registro actualizado correctamente.';

   ELSIF UPPER(TRIM(p_accion)) = 'D' THEN
      IF p_aca_id_audio IS NULL THEN
         RAISE_APPLICATION_ERROR(-20012, 'Para eliminar, p_aca_id_audio es obligatorio.');
      END IF;

      UPDATE SSI_ANEXO_CABECERA_AUDIO aca
         SET
            aca.ACA_ELIMINADO = 1,
            aca.ACA_ESTADO    = 0
      WHERE
         aca.ACA_ID_AUDIO = p_aca_id_audio
         AND aca.ACA_ELIMINADO = 0;

      IF SQL%ROWCOUNT = 0 THEN
         RAISE_APPLICATION_ERROR(-20013, 'No se encontro registro activo para eliminar.');
      END IF;

      COMMIT;

      p_resultado_out := 1;
      p_mensaje_out   := 'Registro eliminado logicamente correctamente.';

   ELSE
      RAISE_APPLICATION_ERROR(-20014, 'Accion no valida. Use C, R, U o D.');
   END IF;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      ROLLBACK;
      p_resultado_out := 0;
      p_mensaje_out   := 'NO_DATA_FOUND [' || v_error_code || ']: ' || v_error_message;
      RAISE_APPLICATION_ERROR(-20001, p_mensaje_out);

   WHEN TOO_MANY_ROWS THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      ROLLBACK;
      p_resultado_out := 0;
      p_mensaje_out   := 'TOO_MANY_ROWS [' || v_error_code || ']: ' || v_error_message;
      RAISE_APPLICATION_ERROR(-20002, p_mensaje_out);

   WHEN DUP_VAL_ON_INDEX THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      ROLLBACK;
      p_resultado_out := 0;
      p_mensaje_out   := 'DUP_VAL_ON_INDEX [' || v_error_code || ']: ' || v_error_message;
      RAISE_APPLICATION_ERROR(-20003, p_mensaje_out);

   WHEN OTHERS THEN
      v_error_code    := SQLCODE;
      v_error_message := SQLERRM;
      ROLLBACK;
      p_resultado_out := 0;
      p_mensaje_out   := 'Error en PRC_SSI_ANEXO_CAB_AUDIO_CRUD [' || v_error_code || ']: ' || v_error_message;
      RAISE_APPLICATION_ERROR(-20999, p_mensaje_out);
END PRC_SSI_ANEXO_CAB_AUDIO_CRUD;
/
