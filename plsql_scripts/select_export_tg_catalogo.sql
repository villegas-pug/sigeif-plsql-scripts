SELECT cat.ID_CATALOGO,
       cat.CAT_GRUPO,
       cat.CAT_SUBGRUPO,
       cat.CAT_TIPO,
       cat.CAT_DESCRIPCION,
       cat.CAT_ESTADO,
       cat.CAT_USU_REGISTRA,
       cat.CAT_FEC_REGISTRA,
       cat.CAT_USU_ACTUALIZA,
       cat.CAT_FEC_ACTUALIZA,
       cat.CAT_USU_ELIMINA,
       cat.CAT_FEC_ELIMINA,
       cat.CAT_ELIMINADO,
       cat.CAT_ABREVIATURA,
       cat.CAT_ORDEN
  FROM TG_CATALOGO cat
 ORDER BY cat.CAT_GRUPO, cat.CAT_SUBGRUPO, cat.CAT_TIPO
