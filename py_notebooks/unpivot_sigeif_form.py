from __future__ import annotations

import argparse
import logging
from pathlib import Path

import pandas as pd


logging.basicConfig(
   level=logging.INFO,
   format='%(asctime)s | %(levelname)s | %(message)s'
)
logger = logging.getLogger('unpivot_sigeif_form')


DEFAULT_SHEET_NAME = 'SIGEIFUnpivot'
DEFAULT_FAMILY_MAP_FILE_NAME = 'cod_familia_+_id_Familia.xlsx'
FIXED_COLUMN_COUNT = 4
FIXED_OUTPUT_COLUMNS = ['PF_ID_FAMILIA', 'AR_FECHA_REGISTRA', 'SF_ID_FASE', 'AP_ID_PREGUNTA', 'AR_RESPUESTA', 'AR_USU_REGISTRA']


def normalize_label(value: object) -> str:
   return str(value).strip().upper() if value is not None and not pd.isna(value) else ''


def normalize_key(value: object) -> str:
   if value is None or pd.isna(value):
      return ''

   text_value = str(value).strip()
   if text_value.endswith('.0'):
      try:
         numeric_value = float(text_value)
         if numeric_value.is_integer():
            return str(int(numeric_value))
      except ValueError:
         pass
   return text_value


def normalize_question_id(value: object) -> int | str:
   normalized_value = normalize_key(value)
   if normalized_value == '':
      return ''

   if normalized_value.isdigit():
      return int(normalized_value)

   return normalized_value


def build_family_map_path(input_file: Path, family_map_file: str | None) -> Path:
   if family_map_file:
      return Path(family_map_file).expanduser()
   return input_file.parent / DEFAULT_FAMILY_MAP_FILE_NAME


def parse_args() -> argparse.Namespace:
   parser = argparse.ArgumentParser(
      description='Despivota una plantilla Excel SIGEIF y la deja lista para posterior carga.'
   )
   parser.add_argument(
      '--input-file',
      required=True,
      help='Archivo Excel origen generado desde la plantilla pivotada.'
   )
   parser.add_argument(
      '--output-file',
      required=True,
      help='Ruta completa del archivo Excel de salida. Debe terminar en .xlsx.'
   )
   parser.add_argument(
      '--family-map-file',
      required=False,
      help='Archivo Excel maestro con columnas COD_FAMILIA y PF_ID_FAMILIA. Si no se indica, se busca en la misma carpeta del input.'
   )
   parser.add_argument(
      '--sheet-name',
      default=DEFAULT_SHEET_NAME,
      help=f'Nombre de la hoja Excel de salida. Default: {DEFAULT_SHEET_NAME}'
   )
   args = parser.parse_args()

   if not args.input_file.lower().endswith('.xlsx'):
      raise ValueError('El parametro --input-file debe terminar en .xlsx.')

   if not args.output_file.lower().endswith('.xlsx'):
      raise ValueError('El parametro --output-file debe terminar en .xlsx.')

   return args


def read_source_template(input_file: Path) -> tuple[pd.DataFrame, list[object]]:
   source_df = pd.read_excel(input_file, header=None)
   if len(source_df.index) < 2:
      raise ValueError('El archivo origen debe tener al menos dos filas de cabecera.')

   header_row = source_df.iloc[1].tolist()
   normalized_headers = [normalize_label(value) for value in header_row[:FIXED_COLUMN_COUNT]]
   expected_headers = ['N°', 'COD_FAMILIA', 'AR_FECHA_REGISTRA', 'SF_ID_FASE']
   if normalized_headers != [normalize_label(value) for value in expected_headers]:
      raise ValueError('La fila 2 del archivo origen no coincide con la estructura esperada del template SIGEIF.')

   question_ids = header_row[FIXED_COLUMN_COUNT:]
   if not any(normalize_key(value) for value in question_ids):
      raise ValueError('No se encontraron columnas pivotadas de AP_ID_PREGUNTA en la fila 2.')

   data_df = source_df.iloc[2:].reset_index(drop=True)
   data_df.columns = header_row
   return data_df, question_ids


def read_family_map(family_map_file: Path) -> pd.DataFrame:
   if not family_map_file.exists():
      raise FileNotFoundError(f'No existe el archivo maestro de familias: {family_map_file}')

   family_df = pd.read_excel(family_map_file)
   family_df.columns = [normalize_label(column) for column in family_df.columns]

   required_columns = ['COD_FAMILIA', 'PF_ID_FAMILIA']
   missing_columns = [column for column in required_columns if column not in family_df.columns]
   if missing_columns:
      raise ValueError(
         f'El archivo maestro de familias debe contener las columnas: {missing_columns}. Archivo recibido: {family_map_file}'
      )

   family_df = family_df.loc[:, required_columns].copy()
   family_df['COD_FAMILIA'] = family_df['COD_FAMILIA'].map(normalize_key)
   family_df = family_df[family_df['COD_FAMILIA'] != '']
   family_df = family_df.drop_duplicates(subset=['COD_FAMILIA'], keep='first')
   return family_df


def is_non_empty_cell(value: object) -> bool:
   if value is None or pd.isna(value):
      return False
   return str(value).strip() != ''


def is_non_empty_source_row(row: pd.Series, question_columns: list[object]) -> bool:
   # La columna N° siempre viene numerada en la plantilla y no debe marcar por si sola una fila como util.
   fixed_data_columns = list(row.index[1:FIXED_COLUMN_COUNT])
   if any(is_non_empty_cell(row.get(column)) for column in fixed_data_columns):
      return True
   return any(is_non_empty_cell(row.get(column)) for column in question_columns)


def build_unpivot_rows(data_df: pd.DataFrame, question_ids: list[object], family_df: pd.DataFrame) -> list[dict[str, object]]:
   family_map = dict(zip(family_df['COD_FAMILIA'], family_df['PF_ID_FAMILIA']))
   output_rows: list[dict[str, object]] = []

   for row_index, row in data_df.iterrows():
      if not is_non_empty_source_row(row, question_ids):
         continue

      source_excel_row = row_index + 3
      cod_familia = normalize_key(row.get('COD_FAMILIA'))
      if cod_familia == '':
         raise ValueError(f'La fila {source_excel_row} no tiene COD_FAMILIA y no se puede resolver PF_ID_FAMILIA.')

      pf_id_familia = family_map.get(cod_familia)
      if pf_id_familia is None or (isinstance(pf_id_familia, float) and pd.isna(pf_id_familia)):
         raise ValueError(f'No se encontro PF_ID_FAMILIA para COD_FAMILIA={cod_familia} en la fila {source_excel_row}.')

      for question_column in question_ids:
         normalized_question_id = normalize_question_id(question_column)
         if normalized_question_id == '':
            continue

         response_value = row.get(question_column)
         if response_value is None or pd.isna(response_value):
            response_value = ''
         else:
            response_value = str(response_value)

         output_rows.append({
            'PF_ID_FAMILIA': pf_id_familia,
            'AR_FECHA_REGISTRA': row.get('AR_FECHA_REGISTRA'),
            'SF_ID_FASE': row.get('SF_ID_FASE'),
            'AP_ID_PREGUNTA': normalized_question_id,
            'AR_RESPUESTA': response_value,
            'AR_USU_REGISTRA': 1,
         })

   return output_rows


def autosize_worksheet_columns(worksheet) -> None:
   for column_cells in worksheet.columns:
      max_length = 0
      column_letter = column_cells[0].column_letter
      for cell in column_cells:
         cell_value = '' if cell.value is None else str(cell.value)
         if len(cell_value) > max_length:
            max_length = len(cell_value)
      worksheet.column_dimensions[column_letter].width = min(max(max_length + 2, 14), 40)


def export_output(output_rows: list[dict[str, object]], output_file: Path, sheet_name: str) -> None:
   output_df = pd.DataFrame(output_rows, columns=FIXED_OUTPUT_COLUMNS)
   output_file.parent.mkdir(parents=True, exist_ok=True)

   with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
      output_df.to_excel(writer, index=False, sheet_name=sheet_name)
      worksheet = writer.book[sheet_name]
      worksheet.freeze_panes = 'A2'
      autosize_worksheet_columns(worksheet)

   logger.info('Archivo unpivot generado: %s', output_file)


def main() -> None:
   args = parse_args()
   input_file = Path(args.input_file).expanduser()
   output_file = Path(args.output_file).expanduser()
   family_map_file = build_family_map_path(input_file, args.family_map_file)
   sheet_name = args.sheet_name.strip() or DEFAULT_SHEET_NAME

   if not input_file.exists():
      raise FileNotFoundError(f'No existe el archivo origen: {input_file}')

   data_df, question_ids = read_source_template(input_file)
   family_df = read_family_map(family_map_file)
   output_rows = build_unpivot_rows(data_df, question_ids, family_df)
   export_output(output_rows, output_file, sheet_name)

   logger.info('Total filas generadas: %s', len(output_rows))
   logger.info('Archivo maestro de familias usado: %s', family_map_file)


if __name__ == '__main__':
   main()
