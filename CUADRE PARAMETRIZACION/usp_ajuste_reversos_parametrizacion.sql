USE db_facturacion
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE usp_ajuste_reversos_parametrizacion --'2021-12-15',1
(
  @FECHA_REVERSION VARCHAR(25),
  @EMPRESA INT
)
AS
BEGIN


  DECLARE @FECHA_CONTABLE VARCHAR(25),
          @ESTADO_REVERSADO VARCHAR(5) = 'R'

  DROP TABLE IF EXISTS #DOCUMENTOS_REVERSADOS

  CREATE TABLE #DOCUMENTOS_REVERSADOS(
  NUM_DOC INT,
  FECHA_CONTABLE DATE,
  EMPRESA INT,
  USUARIO VARCHAR(25)

  )

  INSERT INTO #DOCUMENTOS_REVERSADOS 
  (NUM_DOC, FECHA_CONTABLE, EMPRESA,USUARIO)

  SELECT  R.rp_num_pago, 
          P.p_fecha,
          R.rp_cod_empresa,
		  R.rp_user
	  FROM db_facturacion..tb_reversa_pagos R 
	  INNER JOIN db_facturacion..tb_pagos P ON P.p_numero = R.rp_num_pago
	  WHERE CAST(R.rp_fecha AS DATE) = @FECHA_REVERSION
	  AND R.rp_cod_empresa = @EMPRESA
	 
  UNION ALL

  SELECT RF.rv_num_factura,
         F.fa_fecha,
		 RF.rv_cod_empresa,
		 RF.rv_user
      FROM db_facturacion..tb_reversa_factura RF 
	  INNER JOIN db_facturacion..tb_factura F ON F.fa_numero = RF.rv_num_factura
	  WHERE CAST (RF.rv_fecha AS DATE) = @FECHA_REVERSION
	  AND RF.rv_cod_empresa = @EMPRESA


  UNION ALL --PAGOS INISHROT

   SELECT R.rp_num_pago, 
          P.p_fecha,
          1,
		  R.rp_user
	  FROM db_iniShort..tb_ini_reversa_pagos R 
	  INNER JOIN db_iniShort..tb_ini_pagos P ON P.p_numero = R.rp_num_pago
	  WHERE CAST(R.rp_fecha AS DATE) = @FECHA_REVERSION
	  AND 1 = @EMPRESA


 DROP TABLE IF EXISTS #FECHAS_REVERSADOS

 CREATE TABLE #FECHAS_REVERSADOS(
 ID INT IDENTITY (1,1) ,
 FECHA DATE
 )
    INSERT INTO #FECHAS_REVERSADOS(FECHA)
	SELECT DISTINCT FECHA_CONTABLE --ROW_NUMBER() OVER( ORDER BY NUM_PAGO)
	FROM #DOCUMENTOS_REVERSADOS 
	ORDER BY FECHA_CONTABLE


	 DECLARE REVERSO CURSOR FOR 

	  SELECT FECHA 
	  FROM #FECHAS_REVERSADOS

	 OPEN REVERSO
	 FETCH NEXT FROM REVERSO INTO @FECHA_CONTABLE
	 WHILE (@@FETCH_STATUS = 0 )
		 BEGIN

			 EXEC [usp_entrada_interface_empresas] @FECHA_CONTABLE,'SA',1,1,@ESTADO_REVERSADO
			
	  FETCH NEXT FROM  REVERSO INTO @FECHA_CONTABLE
	  END

	  CLOSE REVERSO
	  DEALLOCATE REVERSO

END
