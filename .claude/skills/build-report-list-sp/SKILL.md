---
name: build-report-list-sp
description: Genera SP Oracle de reporte read-only con SYS_REFCURSOR para PUNCHE/CEDIF desde servicio explícito, objetivo y output SQL, con plantilla XLSX opcional; exclusiva del builder PL/SQL.
compatibility: claude-code
metadata:
  harness-sync:
    version: 1
    origin: {harness: opencode, name: build-report-list-sp, path: .opencode/skills/build-report-list-sp/SKILL.md}
    source_sha256: d24212c5428dc2c3a0e99e27bc5469c63389d61bdd1ada541c7a95a3576de1ae
    transformations: [adapt-compatibility, normalize-instructions, relay-inputs-to-main, literalize-input-labels]
    losses: [native-specialist-question-tool]
    generated_sha256: 5103ae2d906bd0f9808602e5e5e407ba1c19470870485c93cfc4e3d5875d6f49
    synced_at: "2026-10-04T12:27:02Z"
---

# Build Report List SP

Guía exclusivamente a `oracle-plsql-builder` para generar SP de reporte
read-only con salida SYS_REFCURSOR desde tablas de negocio o respuestas de
anexos. Admite PUNCHE y CEDIF; ampliar servicios requiere cambiar explícitamente
el contrato. No presupone servicio2, pregunta1614, sujetos familiares, historial
completo ni una firma universal.

El principal delega la implementación; el builder carga esta Skill y no delega.
En planificación, el principal y el analyst pueden leer el contrato sin cargar
operativamente la Skill. No cubre DML, exportación, ejecución Oracle ni configuración.

## Three Required Inputs and Optional Template

Los números son etiquetas conversacionales, no sustituciones de argumentos
Claude ni parámetros de ejecución Oracle. No exigir que el usuario los escriba.

| Orden | Input | Validación |
|---|---|---|
| 1 | SERVICIO | Obligatorio. PUNCHE o CEDIF indicado explícitamente; no deducir de rutas, template, SQL o IDs |
| 2 | PLANTILLA_REPORTE | Opcional. XLSX adjunto o ruta inequívoca accesible del resultado esperado; pedir hoja si hay varias candidatas |
| 3 | OBJETIVO | Obligatorio. Registros, resultado y reglas de negocio; no exigir tablas/mapeos derivables |
| 4 | OUTPUT_SP | Obligatorio. Directorio o .sql, nuevo o existente, explícitamente autorizado bajo plsql_scripts/ |

Con plantilla, sus columnas y orden definen el resultado. Sin ella, derivar
columnas, orden y alias de OBJETIVO, catálogo y las referencias SQL/SP o lista de
columnas que aporte el usuario; registrarlos en `assumptions` y devolver al
principal solo si columnas o grano son ambiguos. No crear columnas sin fuente
verificada en catálogo.

OUTPUT_SP no es la ubicación de una Skill. Si SERVICIO, OBJETIVO u OUTPUT_SP
faltan, están vacíos, son ambiguos o inválidos, o si una PLANTILLA_REPORTE
entregada es ilegible o inválida: detener antes de generar, devolver en
`missing_inputs` con motivo, conservar las recibidas y pedir solo faltantes o
inválidas en orden mediante el principal. No inferir SERVICIO, OBJETIVO ni OUTPUT_SP.

Ante una solicitud sin contexto, reportar SERVICIO, OBJETIVO y OUTPUT_SP como
faltantes e indicar que la plantilla es opcional. No preguntar
si el SP consulta o modifica: esta capacidad es exclusivamente read-only; si
requiere DML, devolver para routing a otra capacidad.

## Output Gate

Normalizar respecto de raíz y verificar permanencia bajo plsql_scripts/, sin
escapes `..` ni externos. Archivo: extensión .sql y padre existente. Directorio:
existencia y nombre final acordado antes de generar; se puede proponer nombre
o correlativo, pero el principal debe obtener aprobación, no asignarlo solo.

Un directorio inexistente bloquea; devolver al principal para resolver creación
autorizada o elegir otra ruta. Si OUTPUT_SP es un .sql existente, añadir el SP al
final sin eliminar ni modificar el contenido previo (línea en blanco de separación;
añadir salto de línea final previo si falta). Leerlo antes y, si ya contiene un
procedimiento con el mismo nombre, devolver el conflicto al principal en lugar de
duplicar o reemplazar. Reemplazar o borrar contenido exige confirmación explícita. Resolver antes de generar
archivo final, existencia del padre y permisos; no dejar escritura pendiente
como sustituto del gate ni entregar solo código en respuesta sin OUTPUT_SP.

## Conditional and Optional Inputs

Preguntar solo si necesario y ambiguo: grano, fuentes/mapeos alternativos,
histórico/latest, fecha y dimensiones temporales; cuidador singular/múltiple/
ausente y sujeto familiar/individual/mixto; serialización, orden/cantidad,
delimitadores/escapes/vacíos/malformed; máscaras y política de fechas inválidas;
firma/compatibilidad, JOIN bajo el umbral y nombre/permisos del output.

No es cuestionario fijo: una fila por capacitación define el grano y una
plantilla legible aporta orden. No pedir mapeos exhaustivos inequívocos.
Opcionales: plantilla XLSX, nombre exacto, SQL/SP/documentación/código productor-consumidor
y ejemplos anonimizados. Con plantilla manda ella; sin ella las referencias guían
columnas y orden, verificados en catálogo. Valores de fecha y
zona son parámetros del consumidor, no inputs obligatorios de generación.

## Workflow

1. Validar alcance, los tres inputs obligatorios y la plantilla si se entregó, sin iniciar implementación parcial.
2. Cargar read-schema, oracle-syntax y exception-handler; leer catálogo y
   referencias pertinentes en esta sesión.
3. Resolver ID técnico del servicio explícito con evidencia, sin cambiarlo.
   Resolver sujeto, grano, fuentes, tipos, columnas, JOIN, filtros, temporalidad
   y firma; comentarios no prueban constraints.
4. Devolver únicamente bloqueos reales al principal, con impacto y decisión.
5. Generar solo con contrato resuelto y escribir en .sql final autorizado.
6. Revisar estáticamente, entregar mapeo, inferencias, riesgos y ejemplos manuales
   separados, sin afirmar compilación o equivalencia de resultados.

Ante bloqueo devolver capability, required_inputs, resolved_inputs,
missing_inputs, assumptions y risks. El principal centraliza preguntas; el
builder no sustituye decisiones por supuestos silenciosos.

## Catalog, JOIN and Grain

- Nombres, tipos y nulabilidad exactos. No inventar PK/FK/UNIQUE/índices/
  secuencias; NOT NULL no prueba unicidad.
- JOIN inferido >=70% requiere evidencia semántica, nombres, tipos, catálogo y
  precedentes; registrar condición, evidencia, confianza, cardinalidad esperada
  y nulos. Bajo 70% pedir condición explícita; nunca llamarlo FK confirmada.
- No ocultar multiplicación con DISTINCT/MAX/primera fila arbitrarios.
  Mantener grano y revisar filtros que convierten LEFT JOIN en INNER.
- Resolver estados, eliminación y servicios con evidencia funcional; defaults
  no determinan política. No copiar filtros OR entre servicio de familia y zona.

## Caregiver

El precedente de rol CUIDADOR se resuelve con
`SSI_FAMILIA_INTEGRANTES.FI_CUIDADOR = 1` (fi), sujeto a catálogo verificado;
no inventar una columna CUIDADOR ni pedir otra definición si esa evidencia resuelve.

Separar rol/sujeto/población: enriquecimiento de cuidador no excluye familias
sin cuidador ni lo convierte en destinatario. Evaluar 0/1/N. No inferir
principalidad, vigencia, asistencia ni elegir menor ID; si hace falta uno único
sin criterio, devolver ambigüedad. No sumar siempre un cuidador a asistentes.

## Family, Individual and Mixed Annexes

Verificar en catálogo PF_ID_FAMILIA y FI_ID_INTEGRANTE nullable de
SSI_ANEXOS_RESPUESTAS. Considerar ambos y clasificar por evidencia de reporte,
pregunta y productor/consumidor, no columnas o default AR_DESTINATARIO. Versiones
V1 y V2 no son intercambiables por costumbre.

Evaluar JOIN `ar.FI_ID_INTEGRANTE = fi.FI_ID_INTEGRANTE`; familia NULL puede
derivarse de fi.PF_ID_FAMILIA solo con evidencia, sin convertir sujeto individual
en familiar. Si ambas familias discrepan, no esconder con NVL/COALESCE; resolver
conflictos/vínculos ausentes que afecten el resultado. No aplicar FI_CUIDADOR=1
a destinatarios individuales salvo requerimiento explícito del rol.

## History and Dates

No fijar todo histórico ni última respuesta por familia por default. Latest:
separar sujetos familiares/individuales; particionar por identidad y pregunta
y dimensiones justificadas (servicio/fase/aplicación). No competir integrantes
distintos en una partición familiar.

Resolver fecha, NULL, desempate y filtro antes/después de latest; ID máximo no
demuestra cronología ni TRUNC(fecha) reconstruye evaluaciones. Datos actuales
no prueban quién era cuidador históricamente.

Resolver primero significado temporal: rango medioabierto de días completos
solo si es contrato; TRUNC(ini) y TRUNC(fin)+1 son precedentes para días, no
instantes. No truncar ni sumar días arbitrariamente a instantes, ni cambiar
legacy sin compatibilidad. Resolver extremos abiertos/invertidos, DATE/TIMESTAMP
y sentinelas de zona.

## Family Code

Cuando corresponda, LEFT JOIN a códigos agregados de SSI_CODIGOS_FAMILIAS a la
clave del reporte para conservar ausencia y no multiplicar. Resolver servicio,
tipo y vigencia con evidencia; no universalizar CF_TIPO_CODIGO=1 ni sustituir
silenciosamente por PF_COD_FAMILIA legacy.

MAX(CF_CODIGO) es máximo textual, no último registro. Solo usar con política
sustentada. Latest exige fecha/nulos/desempate y conjunto único por clave antes
del JOIN.

## Serialization

- Resolver campos/separadores/vacíos con evidencia; un ejemplo no prueba contrato.
- Extraer posiciones conservando vacíos iniciales/intermedios/finales. Para
  formato simple `;` sin escapes, `(.*?)(;|$)` subexpresión1 es precedente;
  no `[^;]+`, que desplaza vacíos.
- Correlacionar split a cada respuesta; definir vacíos/malformed y evitar fila
  fantasma de capacitación del nodo raíz CONNECT BY.
- Aislar nombre antes de normalizar; nunca normalizar todo el registro como
  miembro_capacitado.
- No universalizar últimas dos palabras como apellidos. Preferir estructura;
  división textual exige regla/casos límite.
- No enlazar por nombre ni convertir documentos a número sin justificación.
- Fechas de texto requieren máscaras/política explícitas, no NLS implícito.
- Oracle trata cadena vacía como NULL: comprobar nulidad, no `= ''`/`<> ''`.

## Construction and Errors

- Firma conforme a consumidores; no imponer posición del cursor. Invocaciones
  nombradas (`p_cursor_out => variable_cursor`).
- PRC_, p_, v_, header con propósito/grano/parámetros/autor/fecha, tres espacios
  y Oracle nativo. %TYPE/%ROWTYPE cuando aplique; no registros sin uso ni DECLARE
  al nivel IS/AS.
- SELECT estático, columnas explícitas y orden/alias/tipos acordados; numeración
  y orden consistentes. No columna sin fuente NULL sin decisión sustentada.
- WHEN OTHERS con SQLCODE/SQLERRM, propagación compatible y error acotado a2048
  bytes al usar RAISE_APPLICATION_ERROR, considerando multibyte.
- Adaptar exception-handler: no ROLLBACK ni logging DML. Ningún COMMIT,
  transacción autónoma ni función con efectos laterales.
- Cursor vacío no lanza NO_DATA_FOUND; errores de fetch pueden ocurrir en caller,
  que consume y cierra el cursor.
- Ejemplos manuales separados, NO EJECUTADOS, sin IDs inventados. Indicar
  requisitos de cliente de DBMS_SQL.RETURN_RESULT; no es universal.

## Security and References

Crear un artefacto CREATE OR REPLACE PROCEDURE no es ejecutar DDL. Nunca ejecutar
Oracle SELECT/DDL/PLSQL ni pruebas de invocación. No DML, SQL dinámico, FOR UPDATE,
credenciales ni conexiones. Confirmación no habilita acciones prohibidas.
Sobrescritura/reversión manual requiere confirmación; cambios de interfaz exigen
compatibilidad resuelta. No ejecutar pruebas, builds, instalaciones, servidores,
deploy ni Git de publicación automáticamente.

Exportar es otra capacidad: devolver al principal para el flujo query-builder
→ excel-template-builder → export_oracle_query_results.py; no ejecutar SP ni
reutilizar pivot/unpivot como atajo.

Referencias (guías, no plantillas ciegas):
- plsql_scripts/punche/procedures/001_sp_sesiones_listar.sql: eventos/participantes.
- plsql_scripts/punche/procedures/002_sp_prog_talleres_listar.sql: programación/familias.
- plsql_scripts/punche/procedures/003_sp_capacitaciones_listar.sql: serialización/códigos.
- plsql_scripts/punche/dml/000_test.sql: Anexo26/latest por pregunta.

No copiar invocaciones posicionales incompatibles de002 ni normalización del
registro entero como nombre de003 ni decisiones locales como reglas multiservicio.

## Acceptance Checklist

Validar inputs obligatorios (y plantilla si se entregó; sin ella, columnas derivadas registradas como supuestos) y output (si era archivo existente, SP añadido al final sin alterar contenido ni duplicar nombre), catálogo leído y hechos/inferencias separados, servicio/
sujeto/grano/cardinalidad/mapeos, cuidador0/1/N y alcance mixto, latest/fechas/
nulos/conflictos, códigos sin multiplicación, MAX textual correctamente rotulado,
parser posicional sin fantasmas, firma compatible, ejemplos separados, header/
tipos/excepciones estáticos y ausencia de ejecución/efectos/transacciones.

Advertir full scans, OR-NULL, ordenamientos, REGEXP/split y límites LISTAGG
cuando afecten; no inventar índices ni planes. Entregar contrato, ruta/artefacto,
mapeo, inferencias, riesgos y ejemplos. Declarar revisión estática: no afirmar
compilado o probado en Oracle sin evidencia real.
