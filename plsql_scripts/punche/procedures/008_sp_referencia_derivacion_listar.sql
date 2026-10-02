-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR
-- Proposito: Anexo 20 PUNCHE (servicio 2), una fila por integrante
--            con respuestas registradas de su unica ficha mutable.
-- Parametros (firma identica a la referencia 003):
--   p_fecha_ini IN DATE DEFAULT NULL: registro >= inicio; NULL abierto.
--   p_fecha_fin IN DATE DEFAULT NULL: registro < fin + 1; NULL abierto.
--   p_id_zona IN NUMBER DEFAULT -1: NULL o -1 todas; otro valor exacto.
--   p_cursor_out OUT SYS_REFCURSOR: 23 columnas, plantilla A-W.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-09-30
-- Alcance : Solo lectura. SQL estatico, sin efectos transaccionales.
-- =============================================================
-- CONTRATO Y EVIDENCIA
-- * XLSX inspeccionado sin modificar: 20_reporte_referencia_derivacion.xlsx,
--   unica hoja Referencia-Derivacion, titulos funcionales fila 2, A-W.
--   Fila 3 tiene aliases heredados desalineados y no define esta interfaz.
-- * Usuario confirma UNA ficha mutable por integrante y serializacion
--   1644 = motivo|seguimiento; OTROS = OTROS;detalle|seguimiento.
-- * Fuente V1: usps_ssi_inabif_v1.sql, reporte Anexo 20 y consulta por
--   integrante; punche/dml/000_test.sql. No se mezclan datos V2.
-- * Si existen versiones, latest por (FI_ID_INTEGRANTE, AP_ID_PREGUNTA):
--   AR_FECHA_REGISTRA DESC NULLS LAST, AR_ID_RESPUESTA DESC para desempate.
--   Filtro temporal ANTES de latest. No se filtra por fecha modificacion
--   ni por la fecha textual 1620. Fechas NULL solo entran sin extremos.
--   No se agrupa por fecha, fase ni aplicaciones supuestas. Distintas
--   preguntas pueden tener distintos instantes de registro. Este resultado
--   es la composicion de respuestas elegibles de UNA ficha mutable, NO una
--   fotografia historica ni un historial de aplicaciones. Una actualizacion
--   in-place puede conservar fecha registro y cambiar el contenido visible.
--   Preguntas sin respuesta en el rango quedan NULL, sin fallback global.
-- * Se considera ficha registrada si existe alguna respuesta del Anexo 20
--   elegible, aunque su texto sea NULL. No se exige 1627 ni un rol cuidador.
--   No se asignan respuestas familiares (FI_ID_INTEGRANTE NULL) a personas.
-- * Familia NULL en respuesta se deriva del integrante; si ambas existen
--   y difieren se rechaza el reporte, no se oculta la discrepancia.
--   Integrantes/familias/zonas ausentes quedan fuera de la poblacion.
--   No se impone estado activo a personas/familias/zonas: el objetivo es
--   tener ficha registrada, no estar actualmente activo. Se excluye borrado
--   logico; NULL en indicadores de borrado se trata como no eliminado.
--   Servicio estricto en preguntas, familia y zona (sin OR multiservicio).
--   No se impone AN_ESTADO, AR_DESTINATARIO ni SF_ID_FASE sin evidencia.
-- * JOINs inferidos (NO FK/UNIQUE confirmadas por catalogo de columnas):
--   ar.AP_ID_PREGUNTA=ap.AP_ID_PREGUNTA; ar.FI_ID_INTEGRANTE=fi.FI_ID_INTEGRANTE;
--   fi.PF_ID_FAMILIA=pf.PF_ID_FAMILIA; pf.ZO_ID_ZONA=zi.ZO_ID_ZONA;
--   cf.PF_ID_FAMILIA=pf.PF_ID_FAMILIA. Confianza estimada >=90% por nombres,
--   tipos compatibles y precedentes. Cardinalidad esperada N:1 a maestros;
--   depende de integridad de sus IDs, no demostrada por este catalogo.
-- * MAX del pivote solo proyecta UNA respuesta ya seleccionada por pregunta;
--   no escoge entre versiones ni oculta multiplicaciones de JOINs.
-- * Codigo familiar actual: servicio 2/tipo 1, activo/no eliminado,
--   FI_ID_INTEGRANTE NULL; fecha DESC NULLS LAST, ID DESC. LEFT JOIN a
--   una fila/familia conserva ausencia. No MAX textual, codigo temporal,
--   PF_COD_FAMILIA legacy ni fallback 1623. Productor de codigos local
--   documenta tipo 1=familia; codigo actual puede diferir del texto 1623.
-- * Mapeo A-W: A numeracion, B zona ID, C descripcion, D codigo;
--   E1628 F1629 G1630 H1632 I1633 J1634 K1635 L1636 M1637 N1638
--   O1627 P1621 Q1620 R1622 S1640 T1641 U1642 V/W1644.
--   No se anaden 1625,1631,puntajes,calificaciones,estados ni archivos.
-- * O: 1=Derivacion, 2=Referencia, evidencia usps_ssi_inabif_v1.sql
--   (cte_ficha_derivacion_referencia). Otros valores se conservan.
--   Resto de respuestas se devuelve como texto original: no se supone
--   que un numero sea indice de AP_OPCIONES o ID de TGCATALOGO. No existe
--   evidencia local suficiente de esas codificaciones. No conversion NLS
--   de edades/fechas/documentos; Q es texto capturado, no serial Excel.
-- * 1644: split por PRIMER '|', preserva vacios inicial/intermedio/final.
--   Sin '|' (legacy incompleto): motivo completo y seguimiento NULL.
--   Mas de un '|' se rechaza (no hay contrato de escapes). Semicolon solo
--   se interpreta cuando el prefijo del motivo es OTROS (case-insensitive).
--   V presenta OTROS: detalle, conservando todo el detalle incluso si tiene
--   ';'; detalle vacio presenta OTROS. Otros motivos conservan su texto.
--   W conserva texto original, sin sustituir vacios por N.A.
-- * Rango invertido devuelve cursor vacio; conservar horas de parametros,
--   para dias completos enviar medianoche. Zona desconocida devuelve vacio.
-- * Prevalidacion y OPEN son SELECT separados: en READ COMMITTED pueden ver
--   snapshots distintos. Guardas del OPEN excluyen conflictos/malformados
--   concurrentes. Caller que requiera snapshot estable debe establecerlo
--   previamente; este SP no modifica aislamiento ni inicia transacciones.
-- * Cursor vacio no lanza NO_DATA_FOUND. Errores durante FETCH se propagan
--   al consumidor, responsable de consumir/cerrar p_cursor_out.
-- * Riesgos: scans, filtros OR-NULL, pivote y ordenamientos analiticos;
--   no se documentan indices/planes verificados. Validacion solo estatica.
--   Nombre solicitado supera 30 bytes: requiere Oracle con identificadores
--   extendidos (12.2+ y COMPATIBLE >=12.2), no Oracle 11g/12.1.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio   SSI_ANEXOS_PREGUNTAS.SI_ID_SERVICIO%TYPE := 2;
   v_num_anexo     SSI_ANEXOS_PREGUNTAS.AP_NUM_ANEXO%TYPE := 20;
   v_conflictos    NUMBER;
   v_malformadas   NUMBER;
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
   v_diagnostico   VARCHAR2(4000);
BEGIN
   WITH candidatas AS (
      SELECT ar.PF_ID_FAMILIA AS FAMILIA_RESPUESTA,
         fi.PF_ID_FAMILIA AS FAMILIA_INTEGRANTE,
         ar.AP_ID_PREGUNTA,
         ar.AR_RESPUESTA,
         ROW_NUMBER() OVER (
            PARTITION BY ar.FI_ID_INTEGRANTE, ar.AP_ID_PREGUNTA
            ORDER BY ar.AR_FECHA_REGISTRA DESC NULLS LAST,
               ar.AR_ID_RESPUESTA DESC
         ) AS RN
      FROM SSI_ANEXOS_RESPUESTAS ar
      JOIN SSI_ANEXOS_PREGUNTAS ap
         ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
      JOIN SSI_FAMILIA_INTEGRANTES fi
         ON fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
      JOIN SSI_ZONA_INTERVENCION zi
         ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
      WHERE ap.SI_ID_SERVICIO = v_id_servicio
         AND ap.AP_NUM_ANEXO = v_num_anexo
         AND pf.SI_ID_SERVICIO = v_id_servicio
         AND zi.SI_ID_SERVICIO = v_id_servicio
         AND NVL(ap.AP_ELIMINADO, 0) = 0
         AND NVL(ar.AR_ELIMINADO, 0) = 0
         AND NVL(fi.FI_ELIMINADO, 0) = 0
         AND NVL(pf.PF_ELIMINADO, 0) = 0
         AND NVL(zi.ZO_ELIMINADO, 0) = 0
         AND (p_fecha_ini IS NULL OR ar.AR_FECHA_REGISTRA >= p_fecha_ini)
         AND (p_fecha_fin IS NULL OR ar.AR_FECHA_REGISTRA < p_fecha_fin + 1)
         AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL
              OR p_fecha_ini <= p_fecha_fin)
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
   )
   SELECT COUNT(CASE WHEN can.FAMILIA_RESPUESTA IS NOT NULL
                         AND can.FAMILIA_RESPUESTA <> can.FAMILIA_INTEGRANTE
                    THEN 1 END),
      COUNT(CASE WHEN can.RN = 1 AND can.AP_ID_PREGUNTA = 1644
                      AND INSTR(can.AR_RESPUESTA, '|', 1, 2) > 0
                 THEN 1 END)
   INTO v_conflictos, v_malformadas
   FROM candidatas can;

   IF v_conflictos > 0 OR v_malformadas > 0 THEN
      RAISE_APPLICATION_ERROR(-20001,
         'Anexo 20 rechazado: familias discordantes=' || TO_CHAR(v_conflictos)
         || '; respuestas 1644 con multiples separadores='
         || TO_CHAR(v_malformadas));
   END IF;

   OPEN p_cursor_out FOR
      WITH candidatas AS (
         SELECT ar.FI_ID_INTEGRANTE,
            fi.PF_ID_FAMILIA,
            zi.ZO_ID_ZONA,
            zi.ZO_DESCRIPCION,
            ar.PF_ID_FAMILIA AS FAMILIA_RESPUESTA,
            ar.AP_ID_PREGUNTA,
            ar.AR_RESPUESTA,
            ROW_NUMBER() OVER (
               PARTITION BY ar.FI_ID_INTEGRANTE, ar.AP_ID_PREGUNTA
               ORDER BY ar.AR_FECHA_REGISTRA DESC NULLS LAST,
                  ar.AR_ID_RESPUESTA DESC
            ) AS RN,
            COUNT(CASE WHEN ar.PF_ID_FAMILIA IS NOT NULL
                             AND ar.PF_ID_FAMILIA <> fi.PF_ID_FAMILIA
                       THEN 1 END) OVER (
               PARTITION BY ar.FI_ID_INTEGRANTE
            ) AS CONFLICTOS
         FROM SSI_ANEXOS_RESPUESTAS ar
         JOIN SSI_ANEXOS_PREGUNTAS ap
            ON ap.AP_ID_PREGUNTA = ar.AP_ID_PREGUNTA
         JOIN SSI_FAMILIA_INTEGRANTES fi
            ON fi.FI_ID_INTEGRANTE = ar.FI_ID_INTEGRANTE
         JOIN SSI_POTENCIALES_FAMILIAS pf
            ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
         JOIN SSI_ZONA_INTERVENCION zi
            ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
         WHERE ap.SI_ID_SERVICIO = v_id_servicio
            AND ap.AP_NUM_ANEXO = v_num_anexo
            AND pf.SI_ID_SERVICIO = v_id_servicio
            AND zi.SI_ID_SERVICIO = v_id_servicio
            AND NVL(ap.AP_ELIMINADO, 0) = 0
            AND NVL(ar.AR_ELIMINADO, 0) = 0
            AND NVL(fi.FI_ELIMINADO, 0) = 0
            AND NVL(pf.PF_ELIMINADO, 0) = 0
            AND NVL(zi.ZO_ELIMINADO, 0) = 0
            AND (p_fecha_ini IS NULL OR ar.AR_FECHA_REGISTRA >= p_fecha_ini)
            AND (p_fecha_fin IS NULL OR ar.AR_FECHA_REGISTRA < p_fecha_fin + 1)
            AND (p_fecha_ini IS NULL OR p_fecha_fin IS NULL
                 OR p_fecha_ini <= p_fecha_fin)
            AND (p_id_zona IS NULL OR p_id_zona = -1
                 OR zi.ZO_ID_ZONA = p_id_zona)
      ), respuestas AS (
         SELECT can.FI_ID_INTEGRANTE,
            can.PF_ID_FAMILIA,
            can.ZO_ID_ZONA,
            can.ZO_DESCRIPCION,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1628 THEN can.AR_RESPUESTA END) AS NOMBRE_INTEGRANTE,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1629 THEN can.AR_RESPUESTA END) AS SEXO,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1630 THEN can.AR_RESPUESTA END) AS EDAD,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1632 THEN can.AR_RESPUESTA END) AS TELEFONO,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1633 THEN can.AR_RESPUESTA END) AS DIRECCION_DOMICILIO,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1634 THEN can.AR_RESPUESTA END) AS DOCUMENTO_IDENTIDAD,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1635 THEN can.AR_RESPUESTA END) AS SEGURO_SALUD,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1636 THEN can.AR_RESPUESTA END) AS GRADO_INSTRUCCION,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1637 THEN can.AR_RESPUESTA END) AS OCUPACION,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1638 THEN can.AR_RESPUESTA END) AS DISCAPACIDAD,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1627 THEN can.AR_RESPUESTA END) AS REQUIERE,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1621 THEN can.AR_RESPUESTA END) AS ENTIDAD_DESTINO,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1620 THEN can.AR_RESPUESTA END) AS FECHA_DERIVACION_REFERENCIA,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1622 THEN can.AR_RESPUESTA END) AS ACOMPANANTE_FAMILIAR,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1640 THEN can.AR_RESPUESTA END) AS NOMBRE_RESPONSABLE,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1641 THEN can.AR_RESPUESTA END) AS DOCUMENTO_RESPONSABLE,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1642 THEN can.AR_RESPUESTA END) AS TELEFONO_FAMILIAR,
            MAX(CASE WHEN can.AP_ID_PREGUNTA = 1644 THEN can.AR_RESPUESTA END) AS MOTIVO_SEGUIMIENTO
         FROM candidatas can
         WHERE can.RN = 1 AND can.CONFLICTOS = 0
         GROUP BY can.FI_ID_INTEGRANTE, can.PF_ID_FAMILIA,
            can.ZO_ID_ZONA, can.ZO_DESCRIPCION
      ), componentes AS (
         SELECT res.FI_ID_INTEGRANTE,
            res.PF_ID_FAMILIA,
            res.ZO_ID_ZONA,
            res.ZO_DESCRIPCION,
            res.NOMBRE_INTEGRANTE,
            res.SEXO,
            res.EDAD,
            res.TELEFONO,
            res.DIRECCION_DOMICILIO,
            res.DOCUMENTO_IDENTIDAD,
            res.SEGURO_SALUD,
            res.GRADO_INSTRUCCION,
            res.OCUPACION,
            res.DISCAPACIDAD,
            res.REQUIERE,
            res.ENTIDAD_DESTINO,
            res.FECHA_DERIVACION_REFERENCIA,
            res.ACOMPANANTE_FAMILIAR,
            res.NOMBRE_RESPONSABLE,
            res.DOCUMENTO_RESPONSABLE,
            res.TELEFONO_FAMILIAR,
            CASE WHEN INSTR(res.MOTIVO_SEGUIMIENTO, '|') > 0
                 THEN SUBSTR(res.MOTIVO_SEGUIMIENTO, 1,
                        INSTR(res.MOTIVO_SEGUIMIENTO, '|') - 1)
                 ELSE res.MOTIVO_SEGUIMIENTO END AS MOTIVO,
            CASE WHEN INSTR(res.MOTIVO_SEGUIMIENTO, '|') > 0
                 THEN SUBSTR(res.MOTIVO_SEGUIMIENTO,
                        INSTR(res.MOTIVO_SEGUIMIENTO, '|') + 1)
            END AS SEGUIMIENTO
         FROM respuestas res
         WHERE NVL(INSTR(res.MOTIVO_SEGUIMIENTO, '|', 1, 2), 0) = 0
      ), codigos AS (
         SELECT cf.PF_ID_FAMILIA,
            cf.CF_CODIGO,
            ROW_NUMBER() OVER (
               PARTITION BY cf.PF_ID_FAMILIA
               ORDER BY cf.CF_FECHA_REGISTRA DESC NULLS LAST,
                  cf.CF_ID_CODIGO DESC
            ) AS RN
         FROM SSI_CODIGOS_FAMILIAS cf
         WHERE cf.SI_ID_SERVICIO = v_id_servicio
            AND cf.CF_TIPO_CODIGO = 1
            AND cf.CF_ESTADO = 1
            AND NVL(cf.CF_ELIMINADO, 0) = 0
            AND cf.FI_ID_INTEGRANTE IS NULL
      )
      SELECT
         ROW_NUMBER() OVER (
            ORDER BY com.ZO_ID_ZONA, com.PF_ID_FAMILIA, com.FI_ID_INTEGRANTE
         ) AS NRO,
         com.ZO_ID_ZONA AS COD_ZON,
         com.ZO_DESCRIPCION AS ZONA_INTERVENCION,
         cod.CF_CODIGO AS CODIGO_FAMILIA,
         com.NOMBRE_INTEGRANTE AS NOMBRE_INTEGRANTE,
         com.SEXO AS SEXO,
         com.EDAD AS EDAD,
         com.TELEFONO AS TELEFONO,
         com.DIRECCION_DOMICILIO AS DIRECCION_DOMICILIO,
         com.DOCUMENTO_IDENTIDAD AS DOCUMENTO_IDENTIDAD,
         com.SEGURO_SALUD AS SEGURO_SALUD,
         com.GRADO_INSTRUCCION AS GRADO_INSTRUCCION,
         com.OCUPACION AS OCUPACION,
         com.DISCAPACIDAD AS DISCAPACIDAD,
         CASE TRIM(com.REQUIERE)
            WHEN '1' THEN 'Derivación'
            WHEN '2' THEN 'Referencia'
            ELSE com.REQUIERE
         END AS REQUIERE,
         com.ENTIDAD_DESTINO AS ENTIDAD_DESTINO,
         com.FECHA_DERIVACION_REFERENCIA AS FECHA_DERIVACION_REFERENCIA,
         com.ACOMPANANTE_FAMILIAR AS ACOMPANANTE_FAMILIAR,
         com.NOMBRE_RESPONSABLE AS NOMBRE_RESPONSABLE,
         com.DOCUMENTO_RESPONSABLE AS DOCUMENTO_RESPONSABLE,
         com.TELEFONO_FAMILIAR AS TELEFONO_FAMILIAR,
         CASE WHEN INSTR(com.MOTIVO, ';') > 0
                    AND UPPER(TRIM(SUBSTR(com.MOTIVO, 1,
                          INSTR(com.MOTIVO, ';') - 1))) = 'OTROS'
              THEN 'OTROS' || CASE
                 WHEN SUBSTR(com.MOTIVO, INSTR(com.MOTIVO, ';') + 1) IS NOT NULL
                 THEN ': ' || SUBSTR(com.MOTIVO, INSTR(com.MOTIVO, ';') + 1)
              END
              ELSE com.MOTIVO
         END AS MOTIVO_DERIVACION_REFERENCIA,
         com.SEGUIMIENTO AS SEGUIMIENTO
      FROM componentes com
      LEFT JOIN codigos cod
         ON cod.PF_ID_FAMILIA = com.PF_ID_FAMILIA AND cod.RN = 1
      ORDER BY com.ZO_ID_ZONA, com.PF_ID_FAMILIA, com.FI_ID_INTEGRANTE;

EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR; SQLCODE='
         || TO_CHAR(v_error_code) || '; ' || v_error_message;
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- INVOCACIONES MANUALES SEPARADAS DE LA CREACION - NO EJECUTADAS
-- Todos los ejemplos estan comentados: no se ejecutan al crear el SP.
-- Descomentar y ejecutar individualmente, de forma manual, en el cliente.
-- DBMS_SQL.RETURN_RESULT requiere Oracle 12c+ y cliente compatible con
-- resultados implicitos. Este objeto requiere Oracle 12.2+ y
-- COMPATIBLE >=12.2 por la longitud del nombre.
-- Las fechas son ilustrativas; no garantizan que existan datos.
-- El cliente recibe, consume y cierra el cursor transferido.
-- =============================================================

-- Caso 1: sin filtros, ultimas respuestas disponibles por integrante/pregunta.
-- DECLARE
--    v_resultado SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR(
--       p_cursor_out => v_resultado
--    );
--    DBMS_SQL.RETURN_RESULT(v_resultado);
-- END;
-- /

-- Caso 2: solo fecha de inicio (incluida).
-- DECLARE
--    v_resultado SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR(
--       p_fecha_ini  => DATE '2026-09-01',
--       p_fecha_fin  => NULL,
--       p_cursor_out => v_resultado
--    );
--    DBMS_SQL.RETURN_RESULT(v_resultado);
-- END;
-- /

-- Caso 3: solo fecha de fin (limite exclusivo fin + 1).
-- DECLARE
--    v_resultado SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR(
--       p_fecha_ini  => NULL,
--       p_fecha_fin  => DATE '2026-09-30',
--       p_cursor_out => v_resultado
--    );
--    DBMS_SQL.RETURN_RESULT(v_resultado);
-- END;
-- /

-- Caso 4: rango, ultimas respuestas DENTRO del rango.
-- DECLARE
--    v_resultado SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR(
--       p_fecha_ini  => DATE '2026-09-01',
--       p_fecha_fin  => DATE '2026-09-30',
--       p_cursor_out => v_resultado
--    );
--    DBMS_SQL.RETURN_RESULT(v_resultado);
-- END;
-- /

-- Caso 5: zona -1, todas las zonas explicitamente.
-- DECLARE
--    v_resultado SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR(
--       p_fecha_ini  => NULL,
--       p_fecha_fin  => NULL,
--       p_id_zona    => -1,
--       p_cursor_out => v_resultado
--    );
--    DBMS_SQL.RETURN_RESULT(v_resultado);
-- END;
-- /

-- Consulta auxiliar de zonas PUNCHE - SOLO EJEMPLO, NO EJECUTADO.
-- Columnas verificadas en oracle_schema_tables_catalog.md.
-- Descomentar/ejecutar manualmente solo mediante un flujo read-only
-- autorizado; esta guia no autoriza consultas contra Oracle.
-- No restringe ZO_ESTADO: el SP incluye zonas no eliminadas aun inactivas.
-- SELECT
--    zi.ZO_ID_ZONA,
--    zi.ZO_DESCRIPCION,
--    zi.SI_ID_SERVICIO,
--    zi.ZO_ESTADO,
--    zi.ZO_ELIMINADO
-- FROM SSI_ZONA_INTERVENCION zi
-- WHERE zi.SI_ID_SERVICIO = 2
--    AND NVL(zi.ZO_ELIMINADO, 0) = 0
-- ORDER BY zi.ZO_ID_ZONA;
-- /

-- Caso 6: zona especifica, SIN ID valido inventado.
-- El cliente debe declarar/asignar el bind numerico :p_id_zona_prueba
-- con un ZO_ID_ZONA de PUNCHE conocido por el operador (no NULL ni -1).
-- DECLARE
--    v_resultado SYS_REFCURSOR;
--    v_id_zona SSI_ZONA_INTERVENCION.ZO_ID_ZONA%TYPE := :p_id_zona_prueba;
-- BEGIN
--    IF v_id_zona IS NULL OR v_id_zona = -1 THEN
--       RAISE_APPLICATION_ERROR(-20002, 'Proveer una zona especifica en el bind');
--    END IF;
--    PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR(
--       p_fecha_ini  => DATE '2026-09-01',
--       p_fecha_fin  => DATE '2026-09-30',
--       p_id_zona    => v_id_zona,
--       p_cursor_out => v_resultado
--    );
--    DBMS_SQL.RETURN_RESULT(v_resultado);
-- END;
-- /

-- Caso 7: zona NULL, equivalente a todas las zonas.
-- DECLARE
--    v_resultado SYS_REFCURSOR;
-- BEGIN
--    PRC_PUNCHE_REFERENCIA_DERIVACION_LISTAR(
--       p_fecha_ini  => NULL,
--       p_fecha_fin  => NULL,
--       p_id_zona    => NULL,
--       p_cursor_out => v_resultado
--    );
--    DBMS_SQL.RETURN_RESULT(v_resultado);
-- END;
-- /

-- ! COMMIT;
