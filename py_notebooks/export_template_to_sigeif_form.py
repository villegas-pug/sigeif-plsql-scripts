from __future__ import annotations

import argparse
import logging
from pathlib import Path

import oracledb
import pandas as pd
from openpyxl import Workbook
from sqlalchemy import create_engine, text
from sqlalchemy.pool import NullPool


logging.basicConfig(
   level=logging.INFO,
   format='%(asctime)s | %(levelname)s | %(message)s'
)
logger = logging.getLogger('export_template_to_sigeif_form')


ORACLE_HOST = '172.19.0.9'
ORACLE_PORT = '1521'
ORACLE_SID = 'INABIF02'
ORACLE_SERVICE_NAME = None
ORACLE_USER = 'USRSEGURIDAD'
ORACLE_PWD = 'QL7nstYOMwxQ'

DEFAULT_SHEET_NAME = 'SIGEIFForm'
DEFAULT_EMPTY_TEMPLATE_ROWS = 100


def make_dsn(host: str, port: str, sid: str | None = None, service_name: str | None = None) -> str:
   port_num = int(port)
   if sid:
      return oracledb.makedsn(host=host, port=port_num, sid=sid)
   if service_name:
      return oracledb.makedsn(host=host, port=port_num, service_name=service_name)
   raise ValueError('Debes definir SID o SERVICE_NAME para la conexion Oracle.')


def get_engine():
   dsn = make_dsn(
      host=ORACLE_HOST,
      port=ORACLE_PORT,
      sid=ORACLE_SID,
      service_name=ORACLE_SERVICE_NAME
   )
   connection_string = f'oracle+oracledb://{ORACLE_USER}:{ORACLE_PWD}@{dsn}'
   return create_engine(connection_string, poolclass=NullPool, echo=False)


def execute_query(query: str) -> pd.DataFrame:
   engine = None
   try:
      engine = get_engine()
      with engine.connect() as conn:
         df = pd.read_sql_query(sql=text(query), con=conn)
      logger.info('Consulta ejecutada exitosamente, filas encontradas: %s', len(df))
      return df
   finally:
      if engine is not None:
         engine.dispose()


def autosize_worksheet_columns(worksheet) -> None:
   for column_cells in worksheet.columns:
      max_length = 0
      column_letter = column_cells[0].column_letter
      for cell in column_cells:
         cell_value = '' if cell.value is None else str(cell.value)
         if len(cell_value) > max_length:
            max_length = len(cell_value)
      worksheet.column_dimensions[column_letter].width = min(max(max_length + 2, 12), 60)


def build_question_headers(df: pd.DataFrame) -> pd.DataFrame:
   df = df.copy()
   df.columns = [str(column).strip().upper() for column in df.columns]

   required_columns = ['AP_ID_PREGUNTA', 'AP_PREGUNTA']
   missing_columns = [column for column in required_columns if column not in df.columns]
   if missing_columns:
      raise ValueError(f'La consulta debe devolver las columnas: {missing_columns}')

   question_headers = df.loc[:, ['AP_ID_PREGUNTA', 'AP_PREGUNTA']].copy()
   question_headers['AP_ID_PREGUNTA'] = question_headers['AP_ID_PREGUNTA'].fillna('').astype(str).str.strip()
   question_headers['AP_PREGUNTA'] = question_headers['AP_PREGUNTA'].fillna('').astype(str).str.strip()
   question_headers = question_headers.drop_duplicates(subset=['AP_ID_PREGUNTA'], keep='first')
   question_headers = question_headers[question_headers['AP_ID_PREGUNTA'] != '']

   if question_headers.empty:
      raise ValueError('La consulta no devolvio preguntas para construir la plantilla.')

   return question_headers.reset_index(drop=True)


def export_template(question_headers: pd.DataFrame, output_path: Path, empty_rows: int, sheet_name: str) -> None:
   workbook = Workbook()
   worksheet = workbook.active
   worksheet.title = sheet_name

   fixed_headers = ['N°', 'COD_FAMILIA', 'AR_FECHA_REGISTRA', 'SF_ID_FASE']
   worksheet.append(['', '', '', ''] + question_headers['AP_PREGUNTA'].tolist())
   worksheet.append(fixed_headers + question_headers['AP_ID_PREGUNTA'].tolist())

   for row_number in range(1, empty_rows + 1):
      worksheet.append([row_number, '', '', ''] + [''] * len(question_headers))

   worksheet.freeze_panes = 'E3'
   autosize_worksheet_columns(worksheet)
   output_path.parent.mkdir(parents=True, exist_ok=True)
   workbook.save(output_path)
   logger.info('Plantilla generada: %s', output_path)


def parse_args() -> argparse.Namespace:
   parser = argparse.ArgumentParser(
      description='Genera una plantilla Excel SIGEIF pivotada desde un SELECT.'
   )
   parser.add_argument(
      '--sql-query',
      required=True,
      help='Sentencia SELECT fuente. Debe devolver AP_ID_PREGUNTA y AP_PREGUNTA.'
   )
   parser.add_argument(
      '--output-dir',
      required=True,
      help='Directorio de salida donde se generara el template Excel.'
   )
   parser.add_argument(
      '--output-file',
      required=True,
      help='Nombre del archivo de salida. Debe terminar en .xlsx.'
   )
   parser.add_argument(
      '--sheet-name',
      default=DEFAULT_SHEET_NAME,
      help=f'Nombre de la hoja Excel. Default: {DEFAULT_SHEET_NAME}'
   )
   parser.add_argument(
      '--empty-template-rows',
      type=int,
      default=DEFAULT_EMPTY_TEMPLATE_ROWS,
      help=f'Cantidad de filas vacias numeradas. Default: {DEFAULT_EMPTY_TEMPLATE_ROWS}'
   )
   args = parser.parse_args()

   if not args.sql_query.strip().upper().startswith('SELECT'):
      raise ValueError('El parametro --sql-query debe ser una sentencia SELECT.')

   if not args.output_file.lower().endswith('.xlsx'):
      raise ValueError('El parametro --output-file debe terminar en .xlsx.')

   if args.empty_template_rows < 1:
      raise ValueError('El parametro --empty-template-rows debe ser mayor o igual a 1.')

   return args


def main() -> None:
   args = parse_args()
   output_dir = Path(args.output_dir).expanduser()
   output_path = output_dir / args.output_file
   sheet_name = args.sheet_name.strip() or DEFAULT_SHEET_NAME

   df = execute_query(args.sql_query)
   question_headers = build_question_headers(df)
   export_template(question_headers, output_path, args.empty_template_rows, sheet_name)
   logger.info('Total columnas pivotadas: %s', len(question_headers))


if __name__ == '__main__':
   main()
