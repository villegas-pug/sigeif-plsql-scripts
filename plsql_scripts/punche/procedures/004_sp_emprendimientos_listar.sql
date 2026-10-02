-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_EMPRENDIMIENTOS_LISTAR
-- Proposito: Anexo 12, organizacion de la economia familiar,
--            emprendimiento PUNCHE. Una fila por familia con alguna
--            respuesta elegible, incluso cuando la pregunta 1602 es No.
-- Parametros:
--   p_fecha_ini  IN DATE DEFAULT NULL: limite inferior incluido,
--                conserva la hora recibida, como la referencia 003.
--   p_fecha_fin  IN DATE DEFAULT NULL: limite superior exclusivo
--                p_fecha_fin + 1; para dias completos enviar medianoche.
--   p_id_zona    IN SSI_ZONA_INTERVENCION.ZO_ID_ZONA%TYPE DEFAULT -1:
--                NULL o -1 = todas las zonas; otro valor = zona exacta.
--   p_cursor_out OUT SYS_REFCURSOR: columnas A-K de EMPRENDIMIENTO.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-09-30
-- Alcance : Solo lectura; sin DML, SQL dinamico ni control transaccional.
-- =============================================================
-- CONTRATO / TRAZABILIDAD
-- * Plantilla: 12_reporte_organizacion_economia_familiar_emprendimiento.xlsx.
--   Inspeccion XLSX read-only aportada por Build: hoja EMPRENDIMIENTO,
--   encabezados fila 2, once columnas. Fila 3 heredada y desalineada:
--   NO se utiliza como contrato de aliases. J se entrega como texto
--   original por aprobacion expresa, no como fecha/serial Excel.
-- * Fuente V1 inferida y aceptada: referencia 003 y productor generico
--   usps_ssi_inabif_v1.sql. No se mezclan respuestas V2.
-- * E=4320, F=parentesco del cuidador actual, G=1602, H=1603,
--   I=1604, J=1605, K=1606. E contiene nombres completos originales;
--   no se descompone ni se une por nombre, aun si difiere del cuidador.
-- * Relaciones inferidas, NO FK/UNIQUE confirmadas por este catalogo:
--   ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA; ar.FI_ID_INTEGRANTE=fi.FI_ID_INTEGRANTE;
--   familia resuelta=pf.PF_ID_FAMILIA; pf.ZO_ID_ZONA=zi.ZO_ID_ZONA;
--   fi.CA_ID_PARENTESCO=cat.IDCATALOGO; cf.PF_ID_FAMILIA=pf.PF_ID_FAMILIA.
--   Confianza estimada >=90% por nombres, tipos y precedentes locales.
--   Cardinalidades esperadas: respuesta N:1 pregunta/integrante/familia;
--   familia N:1 zona; cuidador N:1 catalogo. Se requiere integridad de
--   identificadores maestros; el catalogo de columnas no prueba unicidad.
-- * Familias y zonas activas, no eliminadas y del servicio 2. Se usa
--   servicio estricto, no el OR entre servicio familiar/zona de 003.
--   Preguntas del servicio 2/anexo 12 no eliminadas; respuestas no
--   eliminadas. No se agrega filtro AN_ESTADO ni fase sin evidencia.
-- * Sujeto: FI_ID_INTEGRANTE no NULL identifica respuesta individual;
--   solo se admiten integrantes activos, no eliminados y cuidadores.
--   FI_ID_INTEGRANTE NULL identifica respuesta familiar. No se deduce
--   el sujeto del default AR_DESTINATARIO. Si falta PF_ID_FAMILIA,
--   se deriva de la familia estructurada del integrante, sin cambiar
--   el sujeto individual. Discordancia entre ambas familias: error.
--   Respuestas sin familia resoluble / integrantes ausentes y respuestas
--   de otros integrantes no entran en la poblacion del reporte.
-- * Cuidador actual: FI_CUIDADOR=1, FI_ESTADO=1, FI_ELIMINADO=0.
--   Cero cuidadores conserva familia y F NULL; mas de uno causa error
--   para familias con respuestas elegibles en el rango/zona. Nunca se
--   elige arbitrariamente uno. No es reconstruccion historica de roles.
-- * Latest GLOBAL por (familia resuelta, sujeto individual/familiar,
--   pregunta); no se particiona por SF_ID_FASE ni se inventa aplicacion.
--   AR_FECHA_REGISTRA DESC NULLS LAST, AR_ID_RESPUESTA DESC.
--   Los filtros preceden latest. Fechas NULL solo entran sin limites.
--   Rango invertido devuelve cursor vacio; extremos NULL son abiertos.
-- * Precedencia DESPUES de latest por sujeto: si existe respuesta del
--   cuidador a esa pregunta dentro del rango, prevalece sobre la familiar
--   aunque sea mas antigua o su texto sea NULL. No hay fallback por texto
--   vacio. Diferentes columnas pueden provenir de momentos/fases distintos.
-- * Codigo principal familiar: servicio 2, tipo 1 (productor local),
--   activo/no eliminado, FI_ID_INTEGRANTE NULL. Latest por fecha registro
--   DESC NULLS LAST e ID DESC. LEFT JOIN conserva ausencia como NULL;
--   sin codigo temporal ni PF_COD_FAMILIA legacy como fallback.
-- * MAX en el pivote NO elige respuesta: antes hay exactamente una fila
--   seleccionada por familia/pregunta. No DISTINCT ni MAX textual de codigo.
-- * Prevalidacion y OPEN son SELECT separados bajo aislamiento del caller:
--   en READ COMMITTED pueden ver snapshots distintos. Las guardas del
--   SELECT excluyen conflictos y cuidadores multiples aparecidos despues
--   del chequeo, pero una familia podria desaparecer silenciosamente.
--   Si se exige rechazo atomico y vista consistente entre ambos SELECT,
--   el caller debe establecer previamente una transaccion read-only o
--   SERIALIZABLE. Este SP no cambia aislamiento ni inicia transacciones.
-- * Cursor vacio no lanza NO_DATA_FOUND. Errores durante FETCH pertenecen
--   al caller, que debe consumir/cerrar el cursor incluso ante errores.
-- * Riesgos: scans de respuestas/integrantes/codigos (indices no probados),
--   filtros OR-NULL, prevalidacion adicional y ordenamientos analiticos.
--   Validacion exclusivamente estatica; no compilado/ejecutado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_EMPRENDIMIENTOS_LISTAR (
   p_fecha_ini  IN SSI_ANEXOS_RESPUESTAS.AR_FECHA_REGISTRA%TYPE DEFAULT NULL,
   p_fecha_fin  IN SSI_ANEXOS_RESPUESTAS.AR_FECHA_REGISTRA%TYPE DEFAULT NULL,
   p_id_zona    IN SSI_ZONA_INTERVENCION.ZO_ID_ZONA%TYPE DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_ambiguas       NUMBER;
   v_discordantes   NUMBER;
   v_error_code     NUMBER;
   v_error_message  VARCHAR2(4000);
   v_diagnostico    VARCHAR2(4000);
BEGIN
   -- Chequeos restringidos a respuestas candidatas del reporte.
   WITH familias AS (
      SELECT pf.PF_ID_FAMILIA
      FROM SSI_POTENCIALES_FAMILIAS pf
      JOIN SSI_ZONA_INTERVENCION zi
         ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
      WHERE pf.SI_ID_SERVICIO = 2
         AND pf.PF_ESTADO = 1
         AND pf.PF_ELIMINADO = 0
         AND zi.SI_ID_SERVICIO = 2
         AND zi.ZO_ESTADO = 1
         AND zi.ZO_ELIMINADO = 0
         AND (p_id_zona IS NULL OR p_id_zona = -1
              OR zi.ZO_ID_ZONA = p_id_zona)
   ), cuidadores AS (
      SELECT fi.PF_ID_FAMILIA, COUNT(1) AS CANTIDAD
      FROM SSI_FAMILIA_INTEGRANTES fi
      WHERE fi.FI_CUIDADOR = 1
         AND fi.FI_ESTADO = 1
         AND fi.FI_ELIMINADO = 0
      GROUP BY fi.PF_ID_FAMILIA
   ), candidatas AS (
      SELECT fam.PF_ID_FAMILIA,
         CASE
            WHEN ar.PF_ID_FAMILIA IS NOT NULL
               AND fi.PF_ID_FAMILIA IS NOT NULL
               AND ar.PF_ID_FAMILIA <> fi.PF_ID_FAMILIA THEN 1
            ELSE 0
         END AS DISCORDANTE
      FROM SSI_ANEXOS_RESPUESTAS ar
      JOIN SSI_ANEXOS_PREGUNTAS ap
         ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
      LEFT JOIN SSI_FAMILIA_INTEGRANTES fi
         ON fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
      JOIN familias fam
         ON fam.PF_ID_FAMILIA = CASE
            WHEN ar.PF_ID_FAMILIA IS NOT NULL THEN ar.PF_ID_FAMILIA
            ELSE fi.PF_ID_FAMILIA
         END
      WHERE ap.SI_ID_SERVICIO = 2
         AND ap.AP_NUM_ANEXO = 12
         AND ap.AP_ID_PREGUNTA IN (4320, 1602, 1603, 1604, 1605, 1606)
         AND NVL(ap.AP_ELIMINADO, 0) = 0
         AND ar.AR_ELIMINADO = 0
         AND (ar.FI_ID_INTEGRANTE IS NULL
              OR (fi.FI_CUIDADOR = 1 AND fi.FI_ESTADO = 1
                  AND fi.FI_ELIMINADO = 0))
         AND (p_fecha_ini IS NULL OR ar.AR_FECHA_REGISTRA >= p_fecha_ini)
         AND (p_fecha_fin IS NULL OR ar.AR_FECHA_REGISTRA < p_fecha_fin + 1)
         AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL
              OR p_fecha_ini <= p_fecha_fin)
   )
   SELECT
      (SELECT COUNT(1)
       FROM cuidadores cui
       WHERE cui.CANTIDAD > 1
          AND EXISTS (
             SELECT 1 FROM candidatas can
             WHERE can.PF_ID_FAMILIA = cui.PF_ID_FAMILIA
          )),
      (SELECT COUNT(1) FROM candidatas can WHERE can.DISCORDANTE = 1)
   INTO v_ambiguas, v_discordantes
   FROM DUAL;

   IF v_ambiguas > 0 OR v_discordantes > 0 THEN
      RAISE_APPLICATION_ERROR(
         -20001,
         'Reporte rechazado: familias con multiples cuidadores='
            || TO_CHAR(v_ambiguas)
            || '; respuestas con familias discordantes='
            || TO_CHAR(v_discordantes)
      );
   END IF;

   OPEN p_cursor_out FOR
      WITH familias AS (
         SELECT pf.PF_ID_FAMILIA, zi.ZO_ID_ZONA, zi.ZO_DESCRIPCION
         FROM SSI_POTENCIALES_FAMILIAS pf
         JOIN SSI_ZONA_INTERVENCION zi
            ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
         WHERE pf.SI_ID_SERVICIO = 2
            AND pf.PF_ESTADO = 1
            AND pf.PF_ELIMINADO = 0
            AND zi.SI_ID_SERVICIO = 2
            AND zi.ZO_ESTADO = 1
            AND zi.ZO_ELIMINADO = 0
            AND (p_id_zona IS NULL OR p_id_zona = -1
                 OR zi.ZO_ID_ZONA = p_id_zona)
      ), cuidadores AS (
         SELECT fi.PF_ID_FAMILIA, fi.FI_ID_INTEGRANTE, fi.CA_ID_PARENTESCO,
            COUNT(1) OVER (PARTITION BY fi.PF_ID_FAMILIA) AS CANTIDAD
         FROM SSI_FAMILIA_INTEGRANTES fi
         WHERE fi.FI_CUIDADOR = 1
            AND fi.FI_ESTADO = 1
            AND fi.FI_ELIMINADO = 0
      ), base AS (
         SELECT fam.PF_ID_FAMILIA, ar.FI_ID_INTEGRANTE,
            ar.AP_ID_PREGUNTA, ar.AR_RESPUESTA,
            ar.AR_FECHA_REGISTRA, ar.AR_ID_RESPUESTA
         FROM SSI_ANEXOS_RESPUESTAS ar
         JOIN SSI_ANEXOS_PREGUNTAS ap
            ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         LEFT JOIN SSI_FAMILIA_INTEGRANTES fi
            ON fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
         JOIN familias fam
            ON fam.PF_ID_FAMILIA = CASE
               WHEN ar.PF_ID_FAMILIA IS NOT NULL THEN ar.PF_ID_FAMILIA
               ELSE fi.PF_ID_FAMILIA
            END
         WHERE ap.SI_ID_SERVICIO = 2
            AND ap.AP_NUM_ANEXO = 12
            AND ap.AP_ID_PREGUNTA IN (4320, 1602, 1603, 1604, 1605, 1606)
            AND NVL(ap.AP_ELIMINADO, 0) = 0
            AND ar.AR_ELIMINADO = 0
            AND (ar.FI_ID_INTEGRANTE IS NULL
                 OR (fi.FI_CUIDADOR = 1 AND fi.FI_ESTADO = 1
                     AND fi.FI_ELIMINADO = 0))
            AND (ar.PF_ID_FAMILIA IS NULL OR fi.PF_ID_FAMILIA IS NULL
                 OR ar.PF_ID_FAMILIA = fi.PF_ID_FAMILIA)
            AND NOT EXISTS (
               SELECT 1 FROM cuidadores cui
               WHERE cui.PF_ID_FAMILIA = fam.PF_ID_FAMILIA
                  AND cui.CANTIDAD > 1
            )
            AND (p_fecha_ini IS NULL OR ar.AR_FECHA_REGISTRA >= p_fecha_ini)
            AND (p_fecha_fin IS NULL OR ar.AR_FECHA_REGISTRA < p_fecha_fin + 1)
            AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL
                 OR p_fecha_ini <= p_fecha_fin)
      ), por_sujeto AS (
         SELECT bas.PF_ID_FAMILIA, bas.FI_ID_INTEGRANTE,
            bas.AP_ID_PREGUNTA, bas.AR_RESPUESTA,
            ROW_NUMBER() OVER (
               PARTITION BY bas.PF_ID_FAMILIA, bas.FI_ID_INTEGRANTE,
                  bas.AP_ID_PREGUNTA
               ORDER BY bas.AR_FECHA_REGISTRA DESC NULLS LAST,
                  bas.AR_ID_RESPUESTA DESC
            ) AS RN_SUJETO
         FROM base bas
      ), precedencia AS (
         SELECT ps.PF_ID_FAMILIA, ps.AP_ID_PREGUNTA, ps.AR_RESPUESTA,
            ROW_NUMBER() OVER (
               PARTITION BY ps.PF_ID_FAMILIA, ps.AP_ID_PREGUNTA
               ORDER BY CASE WHEN ps.FI_ID_INTEGRANTE IS NOT NULL
                  THEN 0 ELSE 1 END
            ) AS RN_PREGUNTA
         FROM por_sujeto ps
         WHERE ps.RN_SUJETO = 1
      ), respuestas AS (
         SELECT pre.PF_ID_FAMILIA,
            MAX(CASE WHEN pre.AP_ID_PREGUNTA = 4320
               THEN pre.AR_RESPUESTA END) AS NOMBRE_INTEGRANTE,
            MAX(CASE WHEN pre.AP_ID_PREGUNTA = 1602
               THEN pre.AR_RESPUESTA END) AS ACTIVIDAD_EMPRENDIMIENTO,
            MAX(CASE WHEN pre.AP_ID_PREGUNTA = 1603
               THEN pre.AR_RESPUESTA END) AS SECTOR_EMPRENDIMIENTO,
            MAX(CASE WHEN pre.AP_ID_PREGUNTA = 1604
               THEN pre.AR_RESPUESTA END) AS DESCRIPCION_EMPRENDIMIENTO,
            MAX(CASE WHEN pre.AP_ID_PREGUNTA = 1605
               THEN pre.AR_RESPUESTA END) AS MES_ANIO_INICIO,
            MAX(CASE WHEN pre.AP_ID_PREGUNTA = 1606
               THEN pre.AR_RESPUESTA END) AS FAMILIARES_APOYAN
         FROM precedencia pre
         WHERE pre.RN_PREGUNTA = 1
         GROUP BY pre.PF_ID_FAMILIA
      ), codigos AS (
         SELECT cf.PF_ID_FAMILIA, cf.CF_CODIGO,
            ROW_NUMBER() OVER (
               PARTITION BY cf.PF_ID_FAMILIA
               ORDER BY cf.CF_FECHA_REGISTRA DESC NULLS LAST,
                  cf.CF_ID_CODIGO DESC
            ) AS RN_CODIGO
         FROM SSI_CODIGOS_FAMILIAS cf
         WHERE cf.SI_ID_SERVICIO = 2
            AND cf.CF_TIPO_CODIGO = 1
            AND cf.CF_ESTADO = 1
            AND cf.CF_ELIMINADO = 0
            AND cf.FI_ID_INTEGRANTE IS NULL
      )
      SELECT
         ROW_NUMBER() OVER (
            ORDER BY fam.ZO_ID_ZONA, fam.PF_ID_FAMILIA
         ) AS NRO,
         fam.ZO_ID_ZONA AS COD_ZON,
         fam.ZO_DESCRIPCION AS ZONA_INTERVENCION,
         cod.CF_CODIGO AS CODIGO_FAMILIA,
         res.NOMBRE_INTEGRANTE AS NOMBRE_INTEGRANTE,
         cat.CATDESCRIPCION AS PARENTESCO_NNA,
         res.ACTIVIDAD_EMPRENDIMIENTO AS ACTIVIDAD_EMPRENDIMIENTO,
         res.SECTOR_EMPRENDIMIENTO AS SECTOR_EMPRENDIMIENTO,
         res.DESCRIPCION_EMPRENDIMIENTO AS DESCRIPCION_EMPRENDIMIENTO,
         res.MES_ANIO_INICIO AS MES_ANIO_INICIO,
         res.FAMILIARES_APOYAN AS FAMILIARES_APOYAN
      FROM respuestas res
      JOIN familias fam
         ON fam.PF_ID_FAMILIA = res.PF_ID_FAMILIA
      LEFT JOIN cuidadores cui
         ON cui.PF_ID_FAMILIA = res.PF_ID_FAMILIA
         AND cui.CANTIDAD = 1
      LEFT JOIN TGCATALOGO cat
         ON cat.IDCATALOGO = cui.CA_ID_PARENTESCO
      LEFT JOIN codigos cod
         ON cod.PF_ID_FAMILIA = res.PF_ID_FAMILIA
         AND cod.RN_CODIGO = 1
      ORDER BY fam.ZO_ID_ZONA, fam.PF_ID_FAMILIA;

EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'PRC_EMPRENDIMIENTOS_LISTAR; SQLCODE='
         || TO_CHAR(v_error_code) || '; ' || v_error_message;
      -- Recorte por caracteres completos, limitado por bytes multibyte.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_EMPRENDIMIENTOS_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- INVOCACIONES MANUALES SEPARADAS - NO EJECUTADAS
-- Requiere Oracle 12c+ y cliente compatible con resultados implicitos
-- de DBMS_SQL.RETURN_RESULT. El cliente recibe y consume el cursor.
-- Todos los bloques estan comentados: no se ejecutan al crear el SP.
-- Para garantia entre chequeo y OPEN: caller debe establecer antes
-- aislamiento read-only/SERIALIZABLE, fuera de este artefacto.
-- =============================================================
-- Caso 1: sin filtros.
-- DECLARE
--    c_resultado_busqueda SYS_REFCURSOR;
-- BEGIN
--    PRC_EMPRENDIMIENTOS_LISTAR(
--       p_cursor_out => c_resultado_busqueda
--    );
--    DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
-- END;
-- /
--
-- Caso 2: solo fecha de inicio.
-- DECLARE
--    c_resultado_busqueda SYS_REFCURSOR;
-- BEGIN
--    PRC_EMPRENDIMIENTOS_LISTAR(
--       p_fecha_ini  => DATE '2026-09-01',
--       p_cursor_out => c_resultado_busqueda
--    );
--    DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
-- END;
-- /
--
-- Caso 3: solo fecha de fin (incluye el dia completo).
-- DECLARE
--    c_resultado_busqueda SYS_REFCURSOR;
-- BEGIN
--    PRC_EMPRENDIMIENTOS_LISTAR(
--       p_fecha_fin  => DATE '2026-09-30',
--       p_cursor_out => c_resultado_busqueda
--    );
--    DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
-- END;
-- /
--
-- Caso 4: rango de fechas (ultimas respuestas dentro del rango).
DECLARE
   c_resultado_busqueda SYS_REFCURSOR;
BEGIN
   PRC_EMPRENDIMIENTOS_LISTAR(
      p_fecha_ini  => DATE '2026-08-01',
      p_fecha_fin  => DATE '2026-08-30',
      p_id_zona    => 370, -- 370	[AYACUCHO]
      p_cursor_out => c_resultado_busqueda
   );
   DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
END;
/
--
-- Caso 5: zona -1 (todas las zonas, explicito).
-- DECLARE
--    c_resultado_busqueda SYS_REFCURSOR;
-- BEGIN
--    PRC_EMPRENDIMIENTOS_LISTAR(
--       p_id_zona    => -1,
--       p_cursor_out => c_resultado_busqueda
--    );
--    DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
-- END;
-- /
--
-- Caso 6: zona NULL (equivalente a todas las zonas).
-- DECLARE
--    c_resultado_busqueda SYS_REFCURSOR;
-- BEGIN
--    PRC_EMPRENDIMIENTOS_LISTAR(
--       p_id_zona    => NULL,
--       p_cursor_out => c_resultado_busqueda
--    );
--    DBMS_SQL.RETURN_RESULT(c_resultado_busqueda);
-- END;
-- /
-- Para una zona especifica, sustituir -1 del caso 5 por un
-- ZO_ID_ZONA valido de PUNCHE conocido por el operador; no se inventa ID.
