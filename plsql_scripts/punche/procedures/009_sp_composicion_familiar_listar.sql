-- =============================================================
-- Tipo    : PROCEDURE
-- Nombre  : PRC_PUNCHE_COMPOSICION_FAMILIAR_LISTAR
-- Proposito: Reporte de composicion familiar de PUNCHE (servicio 2).
-- Grano   : UNA FILA POR INTEGRANTE ACTIVO, incluidos cuidadores,
--           con datos actuales del integrante, su familia y zona.
-- Parametros (firma identica a 003_sp_capacitaciones_listar.sql):
--   p_fecha_ini IN DATE DEFAULT NULL: FI_FEC_REGISTRA >= inicio.
--   p_fecha_fin IN DATE DEFAULT NULL: FI_FEC_REGISTRA < fin + 1.
--   p_id_zona IN NUMBER DEFAULT -1: NULL o -1 todas; otro valor exacto.
--   p_cursor_out OUT SYS_REFCURSOR: 24 columnas, plantilla A-X.
-- Autor   : OpenCode (oracle-plsql-builder)
-- Fecha   : 2026-09-30
-- Alcance : Solo lectura; SELECT estatico, sin efectos transaccionales.
-- =============================================================
-- CONTRATO, EVIDENCIA Y DECISIONES DERIVADAS
-- * Plantilla inspeccionada localmente, sin modificar ni recalcular:
--   punche/inputs/reports/templates/9_reporte_composicion_familiar.xlsx,
--   hoja COMP FAM, aliases fila 6. Categorias es auxiliar. Se excluyen
--   Y-Z por confirmacion del usuario; A se denomina NRO.
-- * Fuente: SSI_FAMILIA_INTEGRANTES, NO historial de anexos. No se filtra
--   por cuidador, edad, parentesco, NNA, aptitud, aprobacion ni egreso.
--   Familia y zona deben existir, estar activas y no eliminadas.
-- * Flags: FI/PF/ZO_ESTADO = 1 y FI/PF/ZO_ELIMINADO = 0, estrictos.
--   En codigos: CF_ESTADO = 1 y CF_ELIMINADO = 0, tambien estrictos.
--   NULL en cualquiera de esos flags EXCLUYE la fila de su conjunto.
--   Politica derivada de los predicados de los reportes locales 001/003
--   y acercandonos/rpts_acercandonos_v1.sql, NO de defaults del catalogo.
-- * Servicio de la poblacion: pf.SI_ID_SERVICIO = 2 obligatorio.
--   El servicio de la zona no sustituye al de la familia mediante OR;
--   no se agrega una restriccion de servicio de zona no solicitada.
-- * Fechas: ambos extremos NULL abiertos; se conserva exactamente >=
--   inicio y < fin + 1, SIN TRUNC ni nuevas validaciones de rangos.
--   Se conservan horas: enviar medianoche para dias completos. Un rango
--   sin interseccion efectiva devuelve cursor vacio, sin excepcion.
--   En particular inicio >= fin + 1 no admite filas; inicio > fin dentro
--   del mismo dia puede admitirlas por la semantica legacy de fin + 1.
--   FI_FEC_REGISTRA NULL entra solo cuando ambos extremos son NULL.
--   Zona desconocida devuelve cursor vacio, no se valida con EXISTS.
-- * Codigo familiar actual: servicio 2, tipo 1, activo/no eliminado;
--   ROW_NUMBER por PF_ID_FAMILIA, CF_FECHA_REGISTRA DESC NULLS LAST,
--   CF_ID_CODIGO DESC para desempate. Latest se elige entre codigos
--   elegibles, sin filtro temporal; no MAX textual ni PF_COD_FAMILIA.
--   LEFT JOIN con RN = 1 conserva familias sin codigo como NULL.
-- * Residencia del PROPIO integrante: TGUBIGEO por departamento,
--   provincia y distrito; niveles superiores usan componentes '00'.
--   Evidencia: usps_ssi_inabif_v1.sql (consultas de ubigeo) y productor
--   de SSI_UBIGEO_NOMBRES en ddl_ssi_inabif_v1.sql. Sin fallback a otro
--   integrante; un nivel no resoluble queda NULL. Departamento/provincia
--   pueden resolverse aunque falte un nivel inferior. No se inventan
--   filtros sobre los estados CHAR de TGUBIGEO.
-- * Lookups CA_ID_*: TGCATALOGO.IDCATALOGO -> CATDESCRIPCION.
--   Precedentes: usps_ssi_inabif_v1.sql, cte_informacion_cuidador_principal,
--   y acercandonos/rpts_acercandonos_v1.sql, cte_gestion_nna.
--   LEFT JOIN sin filtros de vigencia del lookup: se describe el valor
--   registrado incluso si su opcion dejo de estar activa; ID sin lookup
--   queda NULL. No se excluye a la persona por datos descriptivos ausentes.
-- * Lengua: CA_ID_LENGUA_MATERNA si FI_CUIDADOR = 1; CA_ID_IDIOMA en
--   los demas casos (incluido FI_CUIDADOR NULL), sin fallback entre ambos.
-- * Discapacidad S: CA_TIENE_DISCAPACIDAD es indicador, NO IDCATALOGO.
--   Evidencia: productor TIENEDISCAPACIDAD NUMBER y CASE = 1 de reportes
--   en usps_ssi_inabif_v1.sql; carga local dml_insert_all_data_punche.sql
--   usa 0. Se muestra 1=SI, 0=NO; NULL/otros=desconocido (NULL).
--   No se deduce discapacidad por presencia de CA_ID_DISCAPACIDAD.
-- * T: FI_CONADIS original SOLO si hay discapacidad (=1) y cuidador (=1),
--   conforme al encabezado; en los demas casos NULL, sin filtrar personas.
--   Es VARCHAR2; no hay evidencia local que lo vincule a un ID de catalogo.
--   No se reemplaza por FI_INSCRIPCION_CONADIS ni se inventa SI/NO.
-- * U: descripcion de CA_ID_DISCAPACIDAD SOLO si indicador = 1.
-- * V: FI_GRADO_DISCAPACIDAD original SOLO si indicador = 1, cualquier rol.
--   Catalogo y productor GRADODISCAPACIDAD lo tipan como VARCHAR2(200).
--   El consumidor antiguo de Acercandonos lo compara con IDCATALOGO
--   NUMBER, con conversion implicita riesgosa: no demuestra que PUNCHE
--   almacene IDs. Los catalogos de grado locales tienen varios grupos;
--   no se copia esa conversion ni se asume ID/CATTIPO/indice de opciones.
--   T/V conservan el texto almacenado, no normalizan ni decodifican
--   posibles codificaciones legacy sin un contrato especifico de estas.
-- * G/N son DATE nativos, sin formato/NLS implicito. M es VARCHAR2(50),
--   conserva ceros iniciales. O usa FI_EDAD, sin recalculo.
-- * Mapeo A-X:
--   A ROW_NUMBER; B CF_CODIGO; C ZO_DESCRIPCION;
--   D/E/F TGUBIGEO.UBILOCALIDAD por nivel; G FI_FEC_REGISTRA;
--   H FI_PRIMER_APE; I FI_SEGUNDO_APE; J FI_NOMBRES;
--   K/L descripciones CA_ID_PARENTESCO/CA_ID_TIPDOC; M FI_NUMERO_DOC;
--   N FI_FEC_NAC; O FI_EDAD; P descripcion CA_ID_SEXO;
--   Q lengua segun rol; R descripcion CA_ID_GRADO_INST;
--   S indicador SI/NO/NULL; T FI_CONADIS condicionado;
--   U descripcion CA_ID_DISCAPACIDAD condicionada;
--   V FI_GRADO_DISCAPACIDAD condicionado;
--   W/X descripciones CA_ID_OCUPACION/CA_ID_TIPO_SEGURO.
-- =============================================================
-- INFERENCIAS DE JOIN Y CARDINALIDAD (NO FK CONFIRMADAS)
-- * fi.PF_ID_FAMILIA = pf.PF_ID_FAMILIA y pf.ZO_ID_ZONA = zi.ZO_ID_ZONA:
--   confianza estimada 95%, nombres/tipos NUMBER y precedentes 001/003.
--   N:1 esperado; INNER excluye vinculos ausentes, zona NULL y maestros
--   ineligibles. Catalogo de columnas no confirma PK/FK/UNIQUE vigentes.
-- * cf.PF_ID_FAMILIA = pf.PF_ID_FAMILIA: 95%, mismo nombre/tipo y 003;
--   0..N codigos se reducen a 0..1 por latest contractual ANTES del JOIN.
-- * fi.CA_ID_PARENTESCO/TIPDOC/SEXO/GRADO_INST/OCUPACION/TIPO_SEGURO/
--   DISCAPACIDAD y lengua segun rol = TGCATALOGO.IDCATALOGO: 95%, tipos
--   NUMBER y precedentes citados; N:0..1 esperado, LEFT conserva NULL.
-- * fi.UBI_ID_* = TGUBIGEO.UBIDEPARTAMENTO/UBIPROVINCIA/UBIDISTRITO,
--   con jerarquia completa y componentes '00': 90%, CHAR(2) y productor
--   citado; N:0..1 esperado por nivel, LEFT conserva datos incompletos.
-- * Una fila por integrante y orden determinista presuponen unicidad de
--   IDs de integrante/familia/zona/codigo/catalogo y de claves geograficas
--   por nivel. Si maestros duplicados violan esa integridad, los JOINs
--   pueden multiplicar filas; no se oculta con DISTINCT/MAX/primera fila.
--   No se declaran constraints ni indices como verificados en Oracle.
-- * Orden y NRO comparten ZO_ID_ZONA, PF_ID_FAMILIA, FI_ID_INTEGRANTE.
-- * No se requieren secuencias ni tipos SQL personalizados para el SP.
--   Las secuencias de los defaults del catalogo no se invocan.
-- * Riesgos: posibles full scans con filtros OR-NULL y rangos abiertos;
--   ordenamiento de codigos para latest y del conjunto final para NRO;
--   costo de lookups y cardinalidad dependiente de integridad de maestros.
--   Sin plan de ejecucion ni disponibilidad de indices comprobados.
-- * Nombre acordado supera 30 bytes: Oracle 12.2+ con COMPATIBLE >= 12.2.
-- * Cursor vacio no lanza NO_DATA_FOUND. El consumidor es responsable
--   del FETCH/cierre; errores diferidos al FETCH ocurren en el consumidor.
--   Diagnostico del OPEN <= 2048 BYTES; se conserva la pila original.
-- * Revision exclusivamente estatica; no ejecutado ni compilado en Oracle.
-- =============================================================

CREATE OR REPLACE PROCEDURE PRC_PUNCHE_COMPOSICION_FAMILIAR_LISTAR (
   p_fecha_ini  IN DATE DEFAULT NULL,
   p_fecha_fin  IN DATE DEFAULT NULL,
   p_id_zona    IN NUMBER DEFAULT -1,
   p_cursor_out OUT SYS_REFCURSOR
)
IS
   v_id_servicio   SSI_POTENCIALES_FAMILIAS.SI_ID_SERVICIO%TYPE := 2;
   v_tipo_codigo   SSI_CODIGOS_FAMILIAS.CF_TIPO_CODIGO%TYPE := 1;
   v_error_code    NUMBER;
   v_error_message VARCHAR2(4000);
   v_diagnostico   VARCHAR2(4000);
BEGIN
   OPEN p_cursor_out FOR
      WITH codigos_ordenados AS (
         SELECT
            cf.PF_ID_FAMILIA,
            cf.CF_CODIGO,
            ROW_NUMBER() OVER (
               PARTITION BY cf.PF_ID_FAMILIA
               ORDER BY cf.CF_FECHA_REGISTRA DESC NULLS LAST,
                  cf.CF_ID_CODIGO DESC
            ) AS RN
         FROM SSI_CODIGOS_FAMILIAS cf
         WHERE cf.SI_ID_SERVICIO = v_id_servicio
            AND cf.CF_TIPO_CODIGO = v_tipo_codigo
            AND cf.CF_ESTADO = 1
            AND cf.CF_ELIMINADO = 0
      )
      SELECT
         ROW_NUMBER() OVER (
            ORDER BY zi.ZO_ID_ZONA, pf.PF_ID_FAMILIA, fi.FI_ID_INTEGRANTE
         )                                          AS NRO,
         cf.CF_CODIGO                                AS COD_FAM,
         zi.ZO_DESCRIPCION                           AS ZONA_INTERV,
         dep.UBILOCALIDAD                            AS DEP_RES,
         prov.UBILOCALIDAD                           AS PROV_RES,
         dist.UBILOCALIDAD                           AS DIS_RES,
         fi.FI_FEC_REGISTRA                          AS FEC_DX,
         fi.FI_PRIMER_APE                            AS PRI_APE_USU,
         fi.FI_SEGUNDO_APE                           AS SEG_APE_USU,
         fi.FI_NOMBRES                               AS NOM_USU,
         par.CATDESCRIPCION                          AS PARENT_USU,
         doc.CATDESCRIPCION                          AS TIP_DOC_USU,
         fi.FI_NUMERO_DOC                            AS NRO_DOC_USU,
         fi.FI_FEC_NAC                               AS FECHA_NAC,
         fi.FI_EDAD                                  AS EDAD_USU,
         sex.CATDESCRIPCION                          AS SEX_USU,
         leng.CATDESCRIPCION                         AS LENG_MAT,
         inst.CATDESCRIPCION                         AS NIV_INST,
         CASE fi.CA_TIENE_DISCAPACIDAD
            WHEN 1 THEN 'SI'
            WHEN 0 THEN 'NO'
            ELSE NULL
         END                                        AS TIE_DIS_FAM,
         CASE
            WHEN fi.CA_TIENE_DISCAPACIDAD = 1 AND fi.FI_CUIDADOR = 1
               THEN fi.FI_CONADIS
            ELSE NULL
         END                                        AS CARN_CONADIS,
         CASE
            WHEN fi.CA_TIENE_DISCAPACIDAD = 1 THEN disc.CATDESCRIPCION
            ELSE NULL
         END                                        AS TIPO_DISCAP,
         CASE
            WHEN fi.CA_TIENE_DISCAPACIDAD = 1 THEN fi.FI_GRADO_DISCAPACIDAD
            ELSE NULL
         END                                        AS GRAV_DISC,
         ocup.CATDESCRIPCION                         AS OCUP,
         seg.CATDESCRIPCION                          AS AFIL_SEG
      FROM SSI_FAMILIA_INTEGRANTES fi
      JOIN SSI_POTENCIALES_FAMILIAS pf
         ON pf.PF_ID_FAMILIA = fi.PF_ID_FAMILIA
      JOIN SSI_ZONA_INTERVENCION zi
         ON zi.ZO_ID_ZONA = pf.ZO_ID_ZONA
      LEFT JOIN codigos_ordenados cf
         ON cf.PF_ID_FAMILIA = pf.PF_ID_FAMILIA
         AND cf.RN = 1
      LEFT JOIN TGUBIGEO dep
         ON dep.UBIDEPARTAMENTO = fi.UBI_ID_DEPARTAMENTO
         AND dep.UBIPROVINCIA = '00'
         AND dep.UBIDISTRITO = '00'
      LEFT JOIN TGUBIGEO prov
         ON prov.UBIDEPARTAMENTO = fi.UBI_ID_DEPARTAMENTO
         AND prov.UBIPROVINCIA = fi.UBI_ID_PROVINCIA
         AND prov.UBIDISTRITO = '00'
      LEFT JOIN TGUBIGEO dist
         ON dist.UBIDEPARTAMENTO = fi.UBI_ID_DEPARTAMENTO
         AND dist.UBIPROVINCIA = fi.UBI_ID_PROVINCIA
         AND dist.UBIDISTRITO = fi.UBI_ID_DISTRITO
      LEFT JOIN TGCATALOGO par
         ON par.IDCATALOGO = fi.CA_ID_PARENTESCO
      LEFT JOIN TGCATALOGO doc
         ON doc.IDCATALOGO = fi.CA_ID_TIPDOC
      LEFT JOIN TGCATALOGO sex
         ON sex.IDCATALOGO = fi.CA_ID_SEXO
      LEFT JOIN TGCATALOGO leng
         ON leng.IDCATALOGO = CASE
            WHEN fi.FI_CUIDADOR = 1 THEN fi.CA_ID_LENGUA_MATERNA
            ELSE fi.CA_ID_IDIOMA
         END
      LEFT JOIN TGCATALOGO inst
         ON inst.IDCATALOGO = fi.CA_ID_GRADO_INST
      LEFT JOIN TGCATALOGO disc
         ON disc.IDCATALOGO = fi.CA_ID_DISCAPACIDAD
         AND fi.CA_TIENE_DISCAPACIDAD = 1
      LEFT JOIN TGCATALOGO ocup
         ON ocup.IDCATALOGO = fi.CA_ID_OCUPACION
      LEFT JOIN TGCATALOGO seg
         ON seg.IDCATALOGO = fi.CA_ID_TIPO_SEGURO
      WHERE pf.SI_ID_SERVICIO = v_id_servicio
         AND fi.FI_ESTADO = 1
         AND fi.FI_ELIMINADO = 0
         AND pf.PF_ESTADO = 1
         AND pf.PF_ELIMINADO = 0
         AND zi.ZO_ESTADO = 1
         AND zi.ZO_ELIMINADO = 0
         AND (p_fecha_ini IS NULL OR fi.FI_FEC_REGISTRA >= p_fecha_ini)
         AND (p_fecha_fin IS NULL OR fi.FI_FEC_REGISTRA < p_fecha_fin + 1)
         AND (p_id_zona IS NULL OR p_id_zona = -1 OR zi.ZO_ID_ZONA = p_id_zona)
      ORDER BY zi.ZO_ID_ZONA, pf.PF_ID_FAMILIA, fi.FI_ID_INTEGRANTE;
EXCEPTION
   WHEN OTHERS THEN
      v_error_code := SQLCODE;
      v_error_message := SQLERRM;
      v_diagnostico := 'Error en PRC_PUNCHE_COMPOSICION_FAMILIAR_LISTAR ['
         || TO_CHAR(v_error_code, 'FM9999999990') || ']: ' || v_error_message;
      -- Recortar por caracteres completos hasta satisfacer el limite BYTES.
      WHILE LENGTHB(v_diagnostico) > 2048 LOOP
         v_diagnostico := SUBSTR(v_diagnostico, 1, LENGTH(v_diagnostico) - 1);
      END LOOP;
      RAISE_APPLICATION_ERROR(-20999, v_diagnostico, TRUE);
END PRC_PUNCHE_COMPOSICION_FAMILIAR_LISTAR;
/

-- ! COMMIT;

-- =============================================================
-- INVOCACIONES MANUALES SEPARADAS - COMENTADAS, NO EJECUTADAS
-- Requieren Oracle 12c+ y cliente compatible con resultados implicitos
-- de DBMS_SQL.RETURN_RESULT; este SP por su nombre requiere 12.2+.
-- Descomentar SOLO un bloque al invocar manualmente en un flujo autorizado.
-- El consumidor maneja errores durante FETCH y cierre del resultado.
-- No hay IDs de zona ficticios: usar -1/NULL o un ID conocido por el caller.
-- =============================================================

-- Caso 1: sin filtros; defaults conservados, notacion nombrada.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
--    v_error_code NUMBER;
--    v_error_message VARCHAR2(4000);
-- BEGIN
--    PRC_PUNCHE_COMPOSICION_FAMILIAR_LISTAR(
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- EXCEPTION
--    WHEN OTHERS THEN
--       v_error_code := SQLCODE;
--       v_error_message := SQLERRM;
--       IF v_cursor%ISOPEN THEN
--          CLOSE v_cursor;
--       END IF;
--       RAISE;
-- END;
-- /

-- Caso 2: fechas de ejemplo a medianoche; todas las zonas (-1).
-- DECLARE
--    v_cursor SYS_REFCURSOR;
--    v_error_code NUMBER;
--    v_error_message VARCHAR2(4000);
-- BEGIN
--    PRC_PUNCHE_COMPOSICION_FAMILIAR_LISTAR(
--       p_fecha_ini => DATE '2026-09-01',
--       p_fecha_fin => DATE '2026-09-30',
--       p_id_zona => -1,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- EXCEPTION
--    WHEN OTHERS THEN
--       v_error_code := SQLCODE;
--       v_error_message := SQLERRM;
--       IF v_cursor%ISOPEN THEN
--          CLOSE v_cursor;
--       END IF;
--       RAISE;
-- END;
-- /

-- Caso 3: extremo inicial abierto; zona NULL equivale a todas.
-- DECLARE
--    v_cursor SYS_REFCURSOR;
--    v_error_code NUMBER;
--    v_error_message VARCHAR2(4000);
-- BEGIN
--    PRC_PUNCHE_COMPOSICION_FAMILIAR_LISTAR(
--       p_fecha_ini => NULL,
--       p_fecha_fin => DATE '2026-09-30',
--       p_id_zona => NULL,
--       p_cursor_out => v_cursor
--    );
--    DBMS_SQL.RETURN_RESULT(v_cursor);
-- EXCEPTION
--    WHEN OTHERS THEN
--       v_error_code := SQLCODE;
--       v_error_message := SQLERRM;
--       IF v_cursor%ISOPEN THEN
--          CLOSE v_cursor;
--       END IF;
--       RAISE;
-- END;
-- /
