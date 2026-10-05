---
name: build-report-list-sp
description: Use ONLY when generating read-only Oracle report procedures with SYS_REFCURSOR output for PUNCHE or CEDIF from explicit service, objective and SQL output inputs, plus an optional report XLSX template. Owned by oracle-plsql-builder; never executes Oracle or exports results.
compatibility: opencode
---

## Qué hago y quién me usa

Guío a `oracle-plsql-builder` para generar SP Oracle de reporte de solo lectura
con salida `SYS_REFCURSOR`, desde tablas de negocio o respuestas de anexos.
Admito PUNCHE y CEDIF; ampliar los servicios requiere actualizar explícitamente
el contrato. No presupongo servicio 2, pregunta 1614, sujetos familiares,
historial completo ni una firma universal.

Build delega la implementación al builder, que carga esta Skill. El builder no
delega. Plan no carga Skills operativas. No cubro DML, exportaciones, ejecución
Oracle ni integración de configuración de agentes.
El analyst de Plan y Build pueden leer el contrato descriptivo de este archivo
sin cargar ni ejecutar la Skill. Solo el builder la carga operativamente.

## Inputs y gate obligatorio

### Tres inputs obligatorios y una plantilla opcional

Recibir del usuario o de un handoff confirmado `$1`, `$3` y `$4` antes de
generar; `$2` es opcional. Las etiquetas `$1` a `$4` son del contrato conversacional,
no parámetros de ejecución Oracle; el usuario no está obligado a escribir las etiquetas.

| Orden | Input | Información y validación |
|---|---|---|
| `$1` | `SERVICIO` | Obligatorio. PUNCHE o CEDIF, indicado explícitamente. No deducirlo de rutas, plantilla, SQL o IDs. |
| `$2` | `PLANTILLA_REPORTE` | **Opcional.** Archivo XLSX adjunto o ruta inequívoca y accesible de la plantilla del resultado esperado. Pedir hoja si hay varias candidatas. No es código SQL ni un SP existente. |
| `$3` | `OBJETIVO` | Obligatorio. Qué registros debe listar, qué resultado se espera y reglas de negocio conocidas. No exigir tablas ni mapeos técnicos derivables después del análisis. |
| `$4` | `OUTPUT_SP` | Obligatorio. Directorio o archivo .sql, nuevo o existente, explícitamente autorizado bajo plsql_scripts/. No es la ubicación de una nueva Skill. |

Si `$1`, `$3` o `$4` faltan, están vacíos, son ambiguos o inválidos, detenerse
antes de generar y devolverlos en `missing_inputs` con el motivo. Si `$2` se
entrega pero es ilegible, ambiguo o inválido, también detener y devolverlo. No
inventar ni deducir `$1`, `$3` ni `$4` de referencias. Conservar los recibidos y
pedir solo los faltantes o inválidos, en orden `$1` a `$4`, por medio del agente principal.

Con plantilla, sus columnas y orden definen el resultado. Sin plantilla, derivar
columnas, orden y alias de `OBJETIVO`, del catálogo y de las referencias SQL/SP o
la lista de columnas que aporte el usuario; registrar la lista propuesta en
`assumptions` y devolver al principal solo si columnas o grano son ambiguos. No
crear columnas sin fuente verificada en el catálogo.

### Formulario para solicitudes sin contexto

Ante «Quiero crear un SP, ¿qué necesitas?», reportar como faltantes para que el
agente principal solicite explícitamente:

1. **$1 SERVICIO:** PUNCHE o CEDIF.
2. **$3 OBJETIVO:** qué información devolver, registros a incluir y reglas conocidas.
3. **$4 OUTPUT_SP:** directorio o archivo .sql (nuevo o existente) de destino bajo plsql_scripts/.

Informar además que **$2 PLANTILLA_REPORTE** es opcional: si el usuario tiene el XLSX
del resultado esperado, que lo adjunte o indique su ruta (y hoja si es ambigua).

No preguntar «¿consultará o insertará/actualizará/eliminará?»: esta capacidad es
exclusivamente read-only. Si la solicitud exige DML, devolverla para otra capacidad.

### Validación del output

Normalizar la ruta respecto de la raíz del proyecto y verificar que permanezca
bajo `plsql_scripts/`, sin escapes mediante `..` ni destinos externos.
Si es archivo, exigir extensión `.sql` y comprobar su directorio padre.
Si es directorio, comprobar existencia y resolver el nombre final antes de generar:
se permite proponer nombre/correlativo según convención, pero obtener acuerdo
del usuario mediante el agente principal, no asignarlo unilateralmente.

Un directorio inexistente bloquea la generación: devolver a Build para resolver
su creación autorizada o pedir otra ruta. Comprobar si el archivo final existe.
Si `OUTPUT_SP` es un archivo `.sql` existente, el SP se **añade al final** sin
eliminar ni modificar su contenido previo (separar con una línea en blanco; si el
archivo no termina en salto de línea, añadirlo primero). Antes de añadir, leer el
archivo y verificar que no contenga ya un procedimiento con el mismo nombre; si
existe, devolver el conflicto a Build en lugar de duplicarlo o reemplazarlo.
Reemplazar o borrar contenido existente sigue requiriendo confirmación explícita.
Antes de generar deben quedar resueltos el archivo final acordado, la existencia
del directorio y los permisos aplicables; no generar y dejar solo la escritura pendiente.

### Condicionales: preguntar solo si son necesarios y no están claros

- Qué representa una fila (grano), fuente y mapeos con alternativas distintas.
- Históricos o latest; fecha del filtro y dimensiones de selección temporal.
- Cuidador singular/múltiple/ausente, sujeto familiar/individual/mixto y conflictos.
- Serialización: orden/cantidad de campos, delimitadores, escapes o sustituciones,
  vacíos y registros malformados. Si se convierten fechas, formato y política de inválidos.
- Firma y compatibilidad si existen consumidores o referencias contradictorias.
- Condición de JOIN si la evidencia no alcanza el umbral definido abajo.
- Nombre final y permisos de escritura/sobrescritura, conforme al output obligatorio.

No son un cuestionario fijo. Por ejemplo, «una fila por capacitación» ya define
el grano; una plantilla legible ya aporta el orden de columnas. No exigir al
usuario un mapeo exhaustivo cuando los campos se resuelvan inequívocamente.

### Opcionales

Plantilla XLSX del resultado esperado, nombre exacto del SP, SQL/SP de referencia,
documentación, código productor/consumidor y ejemplos anonimizados. El output ya
es obligatorio. Con plantilla, esta manda sobre columnas y orden; sin ella, las
referencias SQL son guías técnicas para derivarlos, siempre verificadas en catálogo.
Los valores de fechas y zona no son inputs necesarios para generar el SP:
son argumentos de ejecución del consumidor.

## Flujo

1. Validar alcance: generar un artefacto read-only, no ejecutarlo ni exportarlo.
   Validar primero `$1`, `$3`, `$4` y `$2` si se entregó. Si falla el gate, devolver
   los faltantes sin generar un SP; no iniciar una implementación parcial.
2. Cargar `read-schema`, `oracle-syntax` y `exception-handler`. Leer en la sesión
   `plsql_scripts/oracle_schema_tables_catalog.md` y las referencias pertinentes.
3. Resolver el identificador técnico del servicio recibido con evidencia, sin
   inventarlo ni elegir otro servicio. Resolver sujeto, grano, fuentes, tipos, columnas, JOINs, filtros,
   temporalidad y firma usando evidencia; no confundir comentarios con constraints.
4. Revisar ambigüedades antes de implementar. Devolver a Build únicamente los
   faltantes bloqueantes, su impacto y la decisión requerida; no repetir preguntas.
5. Generar solo con el contrato resuelto. Escribir únicamente en el archivo final
   autorizado `.sql` bajo `plsql_scripts/` (añadiendo al final si ya existe, sin
   alterar su contenido). La ausencia de `OUTPUT_SP` bloquea
   esta capacidad; no sustituir el destino con una entrega de código en respuesta.
6. Revisar estáticamente y entregar mapeo, inferencias, riesgos e invocaciones
   manuales separadas. No afirmar compilación o equivalencia de resultados.

Ante un bloqueo devolver `capability`, `required_inputs`, `resolved_inputs`,
`missing_inputs`, `assumptions` y `risks`. Build centraliza las preguntas sobre
inputs y decisiones. El builder solo pregunta por bloqueos técnicos nuevos según
su contrato; no sustituye decisiones bloqueantes con supuestos silenciosos.

## Inferencia responsable y reglas de negocio

### Catálogo, JOINs y cardinalidad

- Usar nombres, tipos y nulabilidad exactos. No afirmar PK, FK, UNIQUE, índices
  o secuencias que el catálogo no documente. `NOT NULL` no demuestra unicidad.
- Proponer JOINs inferidos solo con confianza >=70 %, sustentada en semántica,
  nombres, tipos compatibles, catálogo y precedentes. Registrar condición,
  evidencia, confianza estimada, cardinalidad esperada y política de nulos.
- Bajo ese umbral, pedir condición explícita. Nunca rotular un JOIN inferido
  como FK confirmada; los porcentajes no prueban integridad de datos.
- No ocultar multiplicaciones con `DISTINCT`, `MAX` o primera fila arbitrarios.
  Mantener el grano resuelto y revisar filtros que conviertan LEFT JOIN en INNER.
- Estados, eliminación y servicios se resuelven según evidencia funcional:
  sus defaults no definen por sí solos la política del reporte. No copiar
  indiscriminadamente filtros OR entre servicio de familia y zona.

### Cuidador

Cuando se solicite el rol CUIDADOR, resolverlo sin volver a preguntar mediante
`SSI_FAMILIA_INTEGRANTES.FI_CUIDADOR = 1` (alias `fi`). No existe una autorización
para inventar una columna llamada `CUIDADOR`.

Separar rol, sujeto y población: datos del cuidador como enriquecimiento no
implican excluir familias sin cuidador ni que este sea el destinatario del anexo.
Evaluar 0/1/N cuidadores. No inferir principalidad, vigencia, asistencia ni
seleccionar uno por menor ID. Si se necesita uno único y no hay criterio claro,
devolver esa ambigüedad. No sumar siempre un cuidador al conteo de asistentes.

### Anexos familiares, individuales o mixtos

`SSI_ANEXOS_RESPUESTAS` permite `PF_ID_FAMILIA` y `FI_ID_INTEGRANTE` nullable.
Considerar ambos; clasificar el alcance por evidencia del reporte, pregunta y
productor/consumidor, no por la mera existencia de columnas ni por el default
de `AR_DESTINATARIO`. Verificar la versión de almacenamiento: V1 y V2 no son
intercambiables por costumbre.

- Considerar el JOIN candidato `ar.FI_ID_INTEGRANTE = fi.FI_ID_INTEGRANTE`.
- Si la familia de la respuesta es NULL, evaluar derivarla de `fi.PF_ID_FAMILIA`
  con evidencia y trazabilidad; no convertir el sujeto individual en familiar.
- Si ambas familias existen y discrepan, no ocultarlo con `NVL`/`COALESCE`.
  Resolver explícitamente conflictos y vínculos ausentes si afectan el resultado.
- No aplicar `FI_CUIDADOR = 1` a todos los destinatarios individuales: sólo
  cuando el requerimiento solicite ese rol.

### Históricos, latest y fechas

No fijar «todos los históricos» o «última respuesta por familia» como default.
Para latest, separar sujetos familiares e individuales y particionar por identidad
del sujeto y pregunta, más dimensiones justificadas (servicio, fase, aplicación).
No hacer competir respuestas de integrantes diferentes en una partición familiar.

Resolver fecha, tratamiento explícito de NULL, desempate determinista y filtro
antes/después de latest. No suponer que ID máximo es último cronológico ni
reconstruir evaluaciones por `TRUNC(fecha)` sin evidencia. Datos personales actuales
no prueban quién era cuidador al momento histórico.

Si aplica filtro temporal, resolver primero su significado. Rango medioabierto
para días completos sólo cuando sea el contrato; `TRUNC(p_fecha_ini)` y
`TRUNC(p_fecha_fin) + 1` pueden expresar días completos. Para instantes no truncar
ni sumar días arbitrariamente. No cambiar semántica legacy sin resolver compatibilidad.
Definir extremos abiertos, rangos invertidos, DATE/TIMESTAMP y sentinelas de zona.

### Código de familia

Cuando aplique, resolverlo con LEFT JOIN a códigos agregados de
`SSI_CODIGOS_FAMILIAS`, a la clave del reporte, para preservar ausencia y no
multiplicar filas. Resolver servicio, tipo y vigencia por evidencia; no universalizar
`CF_TIPO_CODIGO = 1`. No sustituir silenciosamente por `PF_COD_FAMILIA` legacy.

`MAX(CF_CODIGO)` selecciona un máximo textual, no el último código registrado.
Usarlo sólo si la política está sustentada. Si se requiere latest, resolver fecha,
nulos y desempate y formar un conjunto de una fila por clave antes del JOIN.

### Serialización

- Resolver el contrato de campos/separadores/vacíos; un único ejemplo no lo demuestra.
- Extraer por posición preservando campos vacíos iniciales, intermedios y finales.
  Para formato simple sin escapes por `;`, el patrón `(.*?)(;|$)` con subexpresión 1
  es un precedente; no usar `[^;]+` que omite vacíos y desplaza campos.
- Correlacionar el split a cada respuesta. Definir registros vacíos/malformados
  y evitar una capacitación fantasma por el nodo raíz de `CONNECT BY`.
- Extraer únicamente el campo nombre antes de normalizar espacios. Nunca
  normalizar toda la capacitación como si fuese `miembro_capacitado`.
- No universalizar «últimas dos palabras = apellidos». Preferir datos estructurados;
  separación textual requiere regla documentada y casos límite.
- No enlazar personas por nombre ni convertir documentos a número sin justificación.
- Fechas de texto no se convierten con NLS implícito ni máscaras inventadas.
- Oracle trata cadena vacía como NULL: usar comprobaciones de nulidad adecuadas,
  no comparaciones `= ''` o `<> ''`.

## Construcción, errores y ejemplos

- Firma según referencias y consumidores; no imponer cursor primero/último.
  Usar siempre notación nombrada en invocaciones: `p_cursor_out => variable_cursor`.
- Prefijos `PRC_`, `p_`, `v_`, header (propósito, grano, parámetros, autor, fecha),
  indentación de tres espacios y sintaxis Oracle. Usar `%TYPE`/`%ROWTYPE` cuando
  corresponda; no declarar registros sin uso ni `DECLARE` al nivel de `IS`/`AS`.
- SELECT estático, columnas explícitas con orden/alias/tipos acordados; numeración
  y orden coherentes. Columna sin fuente no se deja NULL sin decisión sustentada.
- `WHEN OTHERS` con `SQLCODE`/`SQLERRM`; propagación compatible y diagnóstico
  acotado a 2048 bytes si se usa `RAISE_APPLICATION_ERROR`, considerando multibyte.
- Adaptar `exception-handler`: NO copiar su ROLLBACK ni logs mediante DML.
  Ningún COMMIT, ROLLBACK, transacción autónoma o función con efectos laterales.
- Cursor vacío no lanza `NO_DATA_FOUND`. Errores durante fetch pueden ocurrir
  en el caller, que es responsable de consumir/cerrar el cursor.
- Separar invocaciones manuales del script de creación y marcar NO EJECUTADAS.
  No inventar IDs válidos. Indicar requisitos del cliente si se usa
  `DBMS_SQL.RETURN_RESULT`; no es universal para todas las versiones/clientes.

## Seguridad y confirmaciones

Generar `CREATE OR REPLACE PROCEDURE` como artefacto no es ejecutar DDL.
Esta Skill nunca ejecuta Oracle: SELECT, DDL, PL/SQL o invocaciones de prueba.
La confirmación no habilita operaciones prohibidas por las reglas del proyecto.
No DML, SQL dinámico, `FOR UPDATE`, credenciales ni conexiones.

Sobrescribir/revertir cambios del usuario requiere confirmación explícita.
Cambiar una interfaz existente requiere resolver la compatibilidad, no hacerlo
silenciosamente. No ejecutar automáticamente tests, builds, compilaciones,
despliegues, instalaciones o servidores. Commit, push y operaciones de Git
sujetas a confirmación conservan los gates globales; esta Skill no las realiza.

Una exportación es otra capacidad: devolver a Build para el flujo
`oracle-query-builder -> excel-template-builder -> export_oracle_query_results.py`.
No reutilizar pivot/unpivot ni ejecutar un SP como atajo de exportación.

## Referencias: guías, no plantillas ciegas

- `plsql_scripts/punche/procedures/001_sp_sesiones_listar.sql`: eventos y participantes.
- `plsql_scripts/punche/procedures/002_sp_prog_talleres_listar.sql`: programación/familias.
- `plsql_scripts/punche/procedures/003_sp_capacitaciones_listar.sql`: serialización y códigos.
- `plsql_scripts/punche/dml/000_test.sql`, reporte Anexo 26: latest por pregunta.

No copiar invocaciones posicionales incompatibles de 002, normalización del registro
completo como nombre de 003 ni decisiones locales como reglas multiservicio.

## Checklist y criterios de éxito

- [ ] `$1`, `$3` y `$4` son válidos (y `$2` si se entregó); ningún faltante asumido o inventado.
- [ ] Sin plantilla, columnas/orden/alias derivados quedan registrados como supuestos.
- [ ] Output bajo plsql_scripts/, nombre final acordado y permisos resueltos.
- [ ] Si el output era un archivo existente, el SP se añadió al final sin alterar el contenido previo ni duplicar el nombre.
- [ ] Catálogo leído; nombres/tipos verificados; inferencias registradas, no FK ficticias.
- [ ] Servicio, sujeto, grano, cardinalidad y mapeo de salida sustentados.
- [ ] Cuidador 0/1/N y alcance familiar/individual/mixto tratados cuando apliquen.
- [ ] Históricos/latest, fechas, nulos y conflictos definidos sin mezclar sujetos.
- [ ] Código familiar vía JOIN sin multiplicar filas; MAX textual no llamado latest.
- [ ] Parser conserva posiciones; nombre aislado; sin eventos fantasma.
- [ ] Firma compatible; ejemplos con `=>` y separados, NO EJECUTADOS.
- [ ] Header, sintaxis, tipos y excepciones revisados estáticamente.
- [ ] Sin ejecución, DML, control transaccional ni efectos laterales.
- [ ] Advertencias pertinentes: full scans, OR-NULL, ordenamientos, REGEXP/split,
      límites de LISTAGG; no inventar índices ni planes de ejecución verificados.

Entregar contrato resuelto, artefacto/ruta, mapeo, registro de inferencias,
advertencias y ejemplos manuales pertinentes. Declarar la validación como
estática: no afirmar «compilado» o «probado en Oracle» sin evidencia real.
