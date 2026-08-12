-- * ░ Registro de Unidades Funcionales por Zonas de Intervención

-- * 1. Crear columnas en TGUNIDADORGANICA

ALTER TABLE TGUNIDADORGANICA
   ADD UOR_SERVICIO_PADRE NUMBER NULL
/

ALTER TABLE TGUNIDADORGANICA
   ADD ZO_ID_ZONA NUMBER NULL
/

SELECT 
   uo.UOR_PUBLICADO,
   uo.UOR_NIVEL,
   uo.UOR_FLG_INVENTARIO,
   uo.* 
FROM TGUNIDADORGANICA uo
WHERE
   uo.IDUNIDADORGANICA BETWEEN 1173 AND 1196
   -- uo.UORJERARQUIA IS NOT NULL
   -- uo.UORNOMBRE LIKE '%ORGANO%' -- 0102000000
   -- OR uo.UORNOMBRE LIKE '%ASISTE%' -- 0102000000
   -- uo.UORJERARQUIA = '0102000000'
   -- SUBSTR(uo.UORJERARQUIA, 1, 6) = '010112'
   -- SUBSTR(uo.UORJERARQUIA, 1, 6) = '010200'
   /* SUBSTR(uo.UORJERARQUIA, 7, 4) = '0000'
   AND uo.UOR_NIVEL IS NOT NULL
   AND uo.UOR_NIVEL = 1
   AND uo.UORESTADO = 1 */
ORDER BY
   -- uo.IDUNIDADORGANICA DESC
   -- SUBSTR(uo.UORJERARQUIA, 1, 6) DESC
   SUBSTR(uo.UORJERARQUIA, 7, 4) ASC
/

-- ! COMMIT;

-- * 2. TG_UNIDAD_FUNCIONAL

SELECT * FROM TG_UNIDAD_FUNCIONAL uf
ORDER BY
   uf.ID_UNIDAD_FUNCIONAL DESC
/

SELECT * FROM TG_UNIDAD_ORGANICA_GRUPO g
ORDER BY 
   g.ID_UNIDAD_ORGANICA_GRUPO DESC
/

-- ! COMMIT;
-- ? ROLLBACK;

-- * 3. Buscar Unidades Funcionales por Usuario

-- * 3.1. Procedure: Buscar Unidades Funcionales por Usuario
-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_UNIDAD_FUNCIONAL_POR_USUARIO
-- Propósito: Retorna las unidades funcionales (centros) asignados
--            a un usuario específico, incluyendo nombre del centro,
--            unidad orgánica y zona de intervención asociada.
-- Parámetros:
--   p_id_usuario IN  NUMBER        — ID del usuario a consultar.
--   p_cursor_out OUT SYS_REFCURSOR — cursor con el resultado.
-- Autor   : [ REEMPLAZAR: nombre del autor ]
-- Fecha   : [ REEMPLAZAR: fecha de creación ]
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_UNIDAD_FUNCIONAL_POR_USUARIO (
   p_id_usuario IN  NUMBER,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      SELECT
         u.IDUSUARIO,
         u.CENTRO_NOMBRE,
         uo.IDUNIDADORGANICA,
         uo.UORNOMBRE,
         uo.UORABREVIATURA,
         uo.UOR_SERVICIO_PADRE,
         uo.ZO_ID_ZONA,
         zi.ZO_DESCRIPCION
      FROM TSUSUCAR          u
      JOIN TGUNIDADORGANICA  uo ON u.IDCENTRO = uo.IDUNIDADORGANICA
      LEFT JOIN SSI_ZONA_INTERVENCION zi ON uo.ZO_ID_ZONA = zi.ZO_ID_ZONA
      WHERE u.IDUSUARIO = p_id_usuario
         AND u.ESTADO = 1
         AND u.ELIMINADO = 0
         AND uo.UORESTADO = 1
         AND uo.UORELIMINADO = 0;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      RAISE_APPLICATION_ERROR(-20001, 'Error en PRC_UNIDAD_FUNCIONAL_POR_USUARIO: ' || v_error_message);
END PRC_UNIDAD_FUNCIONAL_POR_USUARIO;
/

-- ! COMMIT;

-- * 3.2. Test Procedure: Buscar Unidades Funcionales por Usuario
DECLARE
   c_resultado SYS_REFCURSOR;
BEGIN
   PRC_UNIDAD_FUNCIONAL_POR_USUARIO(8555, c_resultado);
   DBMS_SQL.RETURN_RESULT(c_resultado);
END;
/





-- ! Test
SELECT * FROM TSUSUCAR u
ORDER BY
   u.IDUSUARIO DESC
/

SELECT * FROM TSUSUARIO p
/

-- ! 1.
DELETE FROM TG_UNIDAD_FUNCIONAL uf
WHERE
   uf.ID_UNIDAD_FUNCIONAL BETWEEN 1503 AND 1525
/

DELETE FROM TGUNIDADORGANICA uo
WHERE
   uo.IDUNIDADORGANICA BETWEEN 1173 AND 1196
/

-- ! 2
SELECT 
   (1172 + 1) AS IDUNIDADORGANICA,
   z.ZO_DESCRIPCION AS UORNOMBRE,
   z.ZO_ESTADO AS UORESTADO,
   z.ZO_ELIMINADO AS UORELIMINADO, 
   z.SI_ID_SERVICIO AS UOR_SERVICIO_PADRE,
   z.ZO_ID_ZONA
FROM SSI_ZONA_INTERVENCION z
/

SELECT * FROM SSI_ZONA_INTERVENCION z
/