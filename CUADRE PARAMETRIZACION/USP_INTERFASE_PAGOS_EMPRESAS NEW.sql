USE [db_facturacion]
GO
/****** Object:  StoredProcedure [dbo].[usp_interfase_pagos_empresas]    Script Date: 8/20/2021 3:25:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
-- ======================================
-- Modification: LUIS DEL ORBE, 25-08-2021
-- ======================================

ALTER PROCEDURE [dbo].[usp_interfase_pagos_empresas] --'2021-12-06',1,'SA','R'
(
	@FECHA_CORTE  DATETIME,
	@ID_EMPRESA   INT,
	@USUARIO	  VARCHAR(50),
	@ESTADO       VARCHAR(5)
)
AS 

BEGIN	 

DECLARE 
      @TERMINAL VARCHAR(25) = HOST_NAME()
	 ,@MONEDA_LOCAL INT = 1
	 ,@MONEDA_EXT INT = 2
	 ,@CXC_CLIENTES INT = 1
	 ,@ITBIS_CARDNET INT = 2
	 ,@COMISON_CARDNET INT = 3
	 ,@NO_IDENTIFICADO INT  = 14
	 ,@DEPOSITO_CTA_NO_IDENTIFICADO VARCHAR(25) = '2141005'
	 ,@CTA_BHD_EFECTIVO VARCHAR(25)='1111005'
	 ,@EFECTIVO_US  INT = 12
	 ,@CTA_BPD_EFECTIVO_US VARCHAR(25)= '1112002'
	 ,@PRIMA INT = 6
	 ,@NOTAS_CREDITO INT = 7
	 ,@ITBIS_COBRADO INT = 10
	 ,@INST_PENDIENTES_PAGOS_ANTICIPADOS INT = 8
	 ,@RETENCION_30 INT  = 9
	 ,@RETENCION_100 INT = 24
	 ,@RETENCION_5 INT = 13
	 ,@INST_PENDIENTES_2 INT = 15
	 ,@DESCRIPCION_CTA_BHD VARCHAR(25) = 'CTA CTE BANCO BHD'
	 ,@ID_EMPRESA_INISHORT INT = 1
	
	 ,@COMISION_HC_HSI FLOAT = 0.04
	 ,@ITBIS_RET_HUNTER_C FLOAT = 0.02
	 ,@VALOR_TARJETA_HUNTER_C FLOAT = 0.06

	 ,@COMISION_HUNTER_P FLOAT = 0.035
	 ,@ITBIS_RET_HUNTER_P FLOAT = 0.02
	 ,@VALOR_TARJETA_HUNTER_P FLOAT = 0.055

	 ,@COMISION FLOAT 
	 ,@ITBIS_RETENIDO FLOAT
	 ,@VALOR_TARJETA FLOAT
	 
	 --=======================================================--
	 --=======SETEO POR CIENTO DE TARJETA SEGUN EMPRESA=======--

	 SELECT @COMISION = CASE 
	                 WHEN @ID_EMPRESA = 3 THEN @COMISION_HUNTER_P
				     ELSE @COMISION_HC_HSI
				     END
     SELECT @ITBIS_RETENIDO = CASE  
	                 WHEN @ID_EMPRESA = 3 THEN @ITBIS_RET_HUNTER_P
					 ELSE @ITBIS_RET_HUNTER_C
					 END
	 SELECT @VALOR_TARJETA = CASE
	                    WHEN @ID_EMPRESA = 3 THEN @VALOR_TARJETA_HUNTER_P
						ELSE @VALOR_TARJETA_HUNTER_C
						END
	 


	SET @fecha_corte = [dbo].[DateOnly](@fecha_corte)

	DELETE FROM [db_facturacion].[dbo].[tb_interfase_empresas]
    WHERE [in_tipo_documento] <> 6
	AND [in_cod_empresa] = @ID_EMPRESA
							 
	
;WITH CTE AS (

------CUENTAS POR COBRAR CLIENTE--------

	    SELECT 
		       P.p_numero                                  AS NUMERO_PAGO
		      ,P.p_tipo_docum                              AS TIPO_DOCUMENTO
		      ,'-'                                         AS COD_FORMA_PAGO
			  ,@CXC_CLIENTES                               AS ID_PARAMETRO			
			  ,(DP.dp_valor * -1)		                   AS VALOR
			  ,PC.pp_cuenta			                       AS CUENTA		  
			  ,GETDATE()			                       AS FECHA_INGRESO
			  ,P.p_fecha			                       AS FECHA_CONTABLE
			  ,P.p_estado							       AS ESTADO
			  ,@TERMINAL				                   AS TERMINAL
    		  ,@USUARIO					                   AS USUARIO
			  ,p_cotizacion                                AS COTIZACION
			  ,@MONEDA_LOCAL					           AS MONEDA
			  ,F.fa_fecha				                   AS FECHA_FACTURA      
			  ,dp_linea                                    AS LINEA
			  ,dp_cod_empresa		                       AS COD_EMPRESA
			  ,PC.pp_descripcion_cta                       AS DESCRIPCION_CTA

		  FROM  db_facturacion.dbo.tb_detalle_pagos DP	  WITH(NOLOCK) 
	      INNER JOIN [db_facturacion].[dbo].[tb_pagos] P  WITH(NOLOCK) ON P.p_numero = DP.dp_num_pago
		  INNER JOIN db_facturacion.dbo.tb_factura  F     WITH(NOLOCK) ON F.fa_numero = DP.dp_num_factura	
		  INNER JOIN db_facturacion..tb_parametros_contables_pagos PC WITH(NOLOCK) ON PC.pp_id_param = @CXC_CLIENTES AND PC.pp_id_empresa = @ID_EMPRESA
		  WHERE P.p_tipo_docum  NOT IN (4,5,6)
		  AND dbo.dateonly(dp_fecha_documento) = @FECHA_CORTE
		  AND P.p_cod_empresa  = F.fa_cod_empresa
		  AND F.fa_cod_empresa = @ID_EMPRESA
		  AND P.p_estado  IN (@ESTADO)

 UNION ALL

 --ITBIS RETENIDO CARNET

		 SELECT 
		        FP.fp_num_pago                     AS NUMERO_PAGO
		       ,0								   AS TIPO_DOCUMENTO
			   ,FP.fp_forma_pago				   AS COD_FORMA_PAGO
			   ,@ITBIS_CARDNET					   AS ID_PARAMETRO		
			   ,(FP.fp_valor * @ITBIS_RETENIDO)	   AS VALOR
			   ,PC.pp_cuenta					   AS CUENTA		  
			   ,GETDATE()						   AS FECHA_INGRESO
			   ,FP.fp_fecha						   AS FECHA_CONTABLE
			   ,FP.fp_estado					   AS ESTADO	  
			   ,@TERMINAL						   AS TERMINAL
			   ,@USUARIO						   AS USUARIO
			   ,FP.fp_cotizacion				   AS COTIZACION
			   ,FP.fp_moneda					   AS MONEDA
			   ,FP.fp_fecha         			   AS FECHA_FACTURA     
			   ,1								   AS LINEA
			   ,FP.fp_cod_empresa   			   AS COD_EMPRESA
			   ,PC.pp_descripcion_cta              AS DESCRIPCION_CTA

	     FROM [db_facturacion].[dbo].[tb_formas_pagos] FP with(nolock) 
		 INNER JOIN db_facturacion..tb_parametros_contables_pagos PC WITH(NOLOCK) ON PC.pp_id_param = @ITBIS_CARDNET AND PC.pp_id_empresa = @ID_EMPRESA
	     WHERE FP.fp_forma_pago IN('TRJ')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	     AND FP.fp_cod_empresa = @ID_EMPRESA
		 AND FP.fp_estado  IN (@ESTADO)

 UNION ALL

 --COMISION CARNET
 
		SELECT  
		     FP.fp_num_pago	                        AS NUMERO_PAGO
		    ,0										AS TIPO_DOCUMENTO
		    ,FP.fp_forma_pago						AS COD_FORMA_PAGO
			,@COMISON_CARDNET						AS ID_PARAMETRO		
			,(FP.fp_valor * @COMISION)  			AS VALOR
			,PC.pp_cuenta							AS CUENTA		  
			,GETDATE()								AS FECHA_INGRESO
			,FP.fp_fecha							AS FECHA_CONTABLE
			,FP.fp_estado						  	AS ESTADO	  
			,@TERMINAL								AS TERMINAL
			,@USUARIO								AS USUARIO
			,FP.fp_cotizacion						AS COTIZACION
			,FP.fp_moneda							AS MONEDA
			,FP.fp_fecha           					AS FECHA_FACTURA     
			,1										AS LINEA
			,FP.fp_cod_empresa     					AS COD_EMPRESA
			,PC.pp_descripcion_cta                  AS DESCRIPCION_CTA

	     FROM [db_facturacion].[dbo].[tb_formas_pagos] FP with(nolock) 
		 INNER JOIN db_facturacion..tb_parametros_contables_pagos PC WITH(NOLOCK) ON PC.pp_id_param = @COMISON_CARDNET AND PC.pp_id_empresa = @ID_EMPRESA
	     WHERE FP.fp_forma_pago IN ('TRJ')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	     AND FP.fp_cod_empresa = @ID_EMPRESA
		 AND FP.fp_estado IN (@ESTADO)

 UNION ALL

  -- INGRESOS TARJETA

		 SELECT  
		      FP.fp_num_pago		                         AS NUMERO_PAGO
		     ,0											     AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							     AS COD_FORMA_PAGO
			 ,BP.bp_id 			                             AS ID_PARAMETRO                                                   
			 ,(FP.fp_valor - (FP.fp_valor * @VALOR_TARJETA)) AS VALOR
			 ,BP.bp_cuenta_contable 					     AS CUENTA
			 ,GETDATE()				                         AS FECHA_INGRESO
			 ,FP.fp_fecha								     AS FECHA_CONTABLE
			 ,FP.fp_estado							  	     AS ESTADO	  
			 ,@TERMINAL									     AS TERMINAL
			 ,@USUARIO									     AS USUARIO
			 ,FP.fp_cotizacion							     AS COTIZACION
			 ,FP.fp_moneda								     AS MONEDA
			 ,FP.fp_fecha       						     AS FECHA_FACTURA  
			 ,1											     AS LINEA
			 ,FP.fp_cod_empresa   						     AS COD_EMPRESA
			 ,C.cu_descripcion							     AS DESCRIPCION_CTA

	     FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
	     INNER JOIN [db_facturacion].PARAMETRIZACION.tb_banco_parametrizacion BP ON FP.fp_id_banco_cuenta = BP.bp_id 
		 INNER JOIN tl_contabilidad..co_cuenta C ON C.cu_cuenta = BP.bp_cuenta_contable AND C.cu_uni_neg = BP.bp_uni_neg
	     WHERE fp_forma_pago IN ('TRJ')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	     AND FP.fp_moneda = @MONEDA_LOCAL
	     AND FP.fp_cod_empresa = @ID_EMPRESA
		 AND FP.fp_estado IN (@ESTADO)
		
 UNION ALL

 --INGRESO DEPOSITOS Y CHEQUES BANCO RD

		 SELECT  
		      FP.fp_num_pago		                                                          AS NUMERO_PAGO
		     ,0																				  AS TIPO_DOCUMENTO
		     ,fp.fp_forma_pago																  AS COD_FORMA_PAGO
			 ,CASE 
			    WHEN fp_forma_pago IN ('DPC') 
				AND (MONTH(fp_fecha_deposito) <> MONTH(fp_fecha) 
				OR YEAR(fp_fecha) <> YEAR(fp_fecha_deposito)) THEN @NO_IDENTIFICADO
				ELSE BP.bp_id END				                                              AS ID_PARAMETRO                                                   
			,FP.fp_valor				                                                      AS VALOR
			,CASE 
			    WHEN fp_forma_pago IN ('DPC') 
				AND (MONTH(fp_fecha_deposito) <> MONTH(fp_fecha) 
				OR YEAR(fp_fecha) <> YEAR(fp_fecha_deposito)) THEN @DEPOSITO_CTA_NO_IDENTIFICADO
				ELSE BP.bp_cuenta_contable END						                          AS CUENTA
			 ,GETDATE()				                                                          AS FECHA_INGRESO
			 ,FP.fp_fecha																	  AS FECHA_CONTABLE
			 ,FP.fp_estado							  										  AS ESTADO	  
			 ,@TERMINAL																		  AS TERMINAL
			 ,@USUARIO																		  AS USUARIO
			 ,FP.fp_cotizacion																  AS COTIZACION
			 ,FP.fp_moneda																	  AS MONEDA
			 ,FP.fp_fecha       															  AS FECHA_FACTURA  
			 ,1																				  AS LINEA
			 ,FP.fp_cod_empresa   															  AS COD_EMPRESA
			 ,CASE 
			    WHEN fp_forma_pago IN ('DPC') 
				AND (MONTH(fp_fecha_deposito) <> MONTH(fp_fecha) 
				OR YEAR(fp_fecha) <> YEAR(fp_fecha_deposito)) THEN P.pp_descripcion_cta
				ELSE C.cu_descripcion END                                                     AS DESCRIPCION_CTA

	     FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
	     INNER JOIN [db_facturacion].PARAMETRIZACION.tb_banco_parametrizacion BP ON FP.fp_id_banco_cuenta = BP.bp_id 
		 INNER JOIN tl_contabilidad..co_cuenta C ON C.cu_cuenta = BP.bp_cuenta_contable AND C.cu_uni_neg = BP.bp_uni_neg
		 INNER JOIN db_facturacion..tb_parametros_contables_pagos P ON  P.pp_cuenta = @DEPOSITO_CTA_NO_IDENTIFICADO AND P.pp_id_empresa = @ID_EMPRESA
	     WHERE FP.fp_forma_pago IN ('DPC','CHQ')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	     AND FP.fp_moneda = @MONEDA_LOCAL
	     AND FP.fp_cod_empresa = @ID_EMPRESA
		 AND FP.fp_estado IN (@ESTADO)
		  
 UNION ALL
      
	  --EFECTIVO

		 SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,0     			                         AS ID_PARAMETRO                                                   
			 ,FP.fp_valor				                 AS VALOR
			 ,@CTA_BHD_EFECTIVO                 		 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,@DESCRIPCION_CTA_BHD				         AS DESCRIPCION_CTA

	     FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
	     WHERE fp_forma_pago IN ('EFE')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	     AND FP.fp_moneda = @MONEDA_LOCAL
	     AND FP.fp_cod_empresa = @ID_EMPRESA
		 AND FP.fp_estado IN (@ESTADO)

 --UNION ALL

 ----INGRESO DEPOSITOS ,CHEQUES Y TARJETAS BANCO US

	--  	 SELECT  
	--	      FP.fp_num_pago		                     AS NUMERO_PAGO
	--	     ,0											 AS TIPO_DOCUMENTO
	--	     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
	--		 ,BP.bp_id 			                         AS ID_PARAMETRO                                                   
	--		 ,FP.fp_valor_bse				             AS VALOR
	--		 ,BP.bp_cuenta_contable 					 AS CUENTA
	--		 ,GETDATE()				                     AS FECHA_INGRESO
	--		 ,FP.fp_fecha								 AS FECHA_CONTABLE
	--		 ,FP.fp_estado							  	 AS ESTADO	  
	--		 ,@TERMINAL									 AS TERMINAL
	--		 ,@USUARIO									 AS USUARIO
	--		 ,FP.fp_cotizacion							 AS COTIZACION
	--		 ,FP.fp_moneda								 AS MONEDA
	--		 ,FP.fp_fecha       						 AS FECHA_FACTURA  
	--		 ,1											 AS LINEA
	--		 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
	--		 ,BP.bp_descripcion							 AS DESCRIPCION_CTA

	--     FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
	--     INNER JOIN [db_facturacion].PARAMETRIZACION.tb_banco_parametrizacion BP ON FP.fp_id_banco_cuenta = BP.bp_id 
	--     WHERE fp_forma_pago IN ('DPC','CHQ','TRJ')
	--     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	--     AND FP.fp_moneda = @MONEDA_EXT
	--     AND FP.fp_cod_empresa = @ID_EMPRESA
	--	 AND FP.fp_estado IN ('G')

 UNION ALL

    --EFECTIVO EN  US

        	 SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,@EFECTIVO_US		                         AS ID_PARAMETRO                                                   
			 ,FP.fp_valor_bse				             AS VALOR
			 ,@CTA_BPD_EFECTIVO_US                		 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA

	     FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
		  INNER JOIN db_facturacion..tb_parametros_contables_pagos PC WITH(NOLOCK) ON PC.pp_id_param = @EFECTIVO_US AND PC.pp_id_empresa = @ID_EMPRESA
	     WHERE fp_forma_pago IN ('EFE')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	     AND FP.fp_moneda = @MONEDA_EXT
	     AND FP.fp_cod_empresa = @ID_EMPRESA
		 AND FP.fp_estado IN (@ESTADO)

 --UNION ALL

 --  --PRIMA PAGO EN DOLARES

	--		SELECT  
	--	      FP.fp_num_pago		                     AS NUMERO_PAGO
	--	     ,0											 AS TIPO_DOCUMENTO
	--	     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
	--		 ,@PRIMA   			                         AS ID_PARAMETRO                                                   
	--		 ,(FP.fp_valor - FP.fp_valor_bse)	         AS VALOR
	--		 ,PC.pp_cuenta             					 AS CUENTA
	--		 ,GETDATE()				                     AS FECHA_INGRESO
	--		 ,FP.fp_fecha								 AS FECHA_CONTABLE
	--		 ,FP.fp_estado							  	 AS ESTADO	  
	--		 ,@TERMINAL									 AS TERMINAL
	--		 ,@USUARIO									 AS USUARIO
	--		 ,FP.fp_cotizacion							 AS COTIZACION
	--		 ,FP.fp_moneda								 AS MONEDA
	--		 ,FP.fp_fecha       						 AS FECHA_FACTURA  
	--		 ,1											 AS LINEA
	--		 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
	--		 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA

 --       FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
	--	INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @PRIMA
	--    WHERE FP.fp_forma_pago IN ('TRJ','EFE','DPC','CHQ')
	--    AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	--    AND FP.fp_moneda = @MONEDA_EXT
	--    AND FP.fp_cod_empresa = @ID_EMPRESA
	--	AND FP.fp_estado IN ('G')

 UNION ALL

	--NOTAS CREDITO SIN ITBIS

		SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,@NOTAS_CREDITO	                         AS ID_PARAMETRO                                                   
			 ,(FP.fp_valor / 1.18)	                     AS VALOR
			 ,PC.pp_cuenta             					 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA

	    FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
		INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @NOTAS_CREDITO AND PC.pp_id_empresa = @ID_EMPRESA
	    WHERE FP.fp_forma_pago IN ('NC')
	    AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	    AND FP.fp_moneda = @MONEDA_LOCAL
	    AND FP.fp_cod_empresa = @ID_EMPRESA
		AND FP.fp_estado IN (@ESTADO)

 UNION ALL

	--ITBIS NOTAS CREDITO

			SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,@ITBIS_COBRADO	                         AS ID_PARAMETRO                                                   
			 ,(FP.fp_valor / 1.18) * 0.18                AS VALOR
			 ,PC.pp_cuenta             					 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA

	    FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
		INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @ITBIS_COBRADO AND PC.pp_id_empresa = @ID_EMPRESA
		WHERE fp_forma_pago IN ('NC')
	    AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	    AND FP.fp_moneda = @MONEDA_LOCAL
	    AND FP.fp_cod_empresa = @ID_EMPRESA
		AND FP.fp_estado IN (@ESTADO)

 UNION ALL 

     --PAGOS ANTICIPADOS. RECIBIDOS

	          SELECT  
	           P.p_numero                               AS NUMERO_PAGO
	          ,P.p_tipo_docum 							AS TIPO_DOCUMENTO
	          ,'-'										AS COD_FORMA_PAGO
			  ,@INST_PENDIENTES_PAGOS_ANTICIPADOS     	AS ID_PARAMETRO   
			  ,(P.p_valor * -1)							AS VALOR
			  ,PC.pp_cuenta				 				AS CUENTA
			  ,GETDATE()								AS FECHA_INGRESO
			  ,P.p_fecha								AS FECHA_CONTABLE
			  ,P.p_estado								AS ESTADO	  
			  ,@TERMINAL								AS TERMINAL
			  ,@USUARIO									AS USUARIO
			  ,P.p_cotizacion							AS COTIZACION
			  ,@MONEDA_LOCAL							AS MONEDA
			  ,P.p_fecha								AS FECHA_FACTURA  
			  ,1										AS LINEA
			  ,P.p_cod_empresa     						AS COD_EMPRESA
			  ,PC.pp_descripcion_cta                    AS DESCRIPCION_CTA

	    FROM [db_facturacion].[dbo].[tb_pagos] P WITH(NOLOCK)
		INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @INST_PENDIENTES_PAGOS_ANTICIPADOS AND PC.pp_id_empresa = @ID_EMPRESA
	    WHERE P.p_tipo_docum  = 4 --PAGO ANTICIPADO
	    AND [dbo].[DateOnly](p_fecha) = @FECHA_CORTE
	    AND P.p_cod_empresa = @ID_EMPRESA
		AND P.p_estado IN (@ESTADO)

 UNION ALL

  --PAGOS ANTICIPADOS. APLICADOS

       	 SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,@INST_PENDIENTES_PAGOS_ANTICIPADOS         AS ID_PARAMETRO                                                   
			 ,FP.fp_valor				                 AS VALOR
			 ,PC.pp_cuenta             					 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA   

        FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
		INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @INST_PENDIENTES_PAGOS_ANTICIPADOS AND PC.pp_id_empresa = @ID_EMPRESA
	    WHERE FP.fp_forma_pago IN ('CRC')
	    AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	    AND FP.fp_moneda = @MONEDA_LOCAL
	    AND FP.fp_cod_empresa = @ID_EMPRESA
		AND FP.fp_estado IN (@ESTADO)

  UNION ALL

 --RETENCIONES 30%
   	
       	 SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,@RETENCION_30  	                         AS ID_PARAMETRO                                                   
			 ,FP.fp_valor				                 AS VALOR
			 ,PC.pp_cuenta             					 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA  

        FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
		INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @RETENCION_30 AND PC.pp_id_empresa = @ID_EMPRESA
	    WHERE FP.fp_forma_pago IN ('RTC')
	    AND [dbo].[DateOnly](fp_fecha) =@FECHA_CORTE
	    AND FP.fp_moneda = @MONEDA_LOCAL
	    AND FP.fp_cod_empresa = @ID_EMPRESA
		AND FP.fp_estado IN (@ESTADO)

  UNION ALL

   --RETENCIONES AL 100
  
     	 SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,@RETENCION_100                             AS ID_PARAMETRO                                                   
			 ,FP.fp_valor				                 AS VALOR
			 ,PC.pp_cuenta             					 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA  

        FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
		INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @RETENCION_100 AND PC.pp_id_empresa = @ID_EMPRESA
	    WHERE FP.fp_forma_pago IN ('RT1')
	    AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	    AND FP.fp_moneda = @MONEDA_LOCAL
	    AND FP.fp_cod_empresa = @ID_EMPRESA
		AND FP.fp_estado IN (@ESTADO)

 UNION ALL

	--RETENCION 5%
    
	     SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,@RETENCION_5    	                         AS ID_PARAMETRO                                                   
			 ,FP.fp_valor				                 AS VALOR
			 ,PC.pp_cuenta             					 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA  

        FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
		INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @RETENCION_5 AND PC.pp_id_empresa = @ID_EMPRESA
	    WHERE FP.fp_forma_pago IN ('R5%')
	    AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	    AND FP.fp_moneda = @MONEDA_LOCAL
	    AND FP.fp_cod_empresa = @ID_EMPRESA
		AND FP.fp_estado IN (@ESTADO)

 UNION ALL

	--CASTIGO

	     SELECT  
		      FP.fp_num_pago		                     AS NUMERO_PAGO
		     ,0											 AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							 AS COD_FORMA_PAGO
			 ,@INST_PENDIENTES_2                         AS ID_PARAMETRO                                                   
			 ,FP.fp_valor				                 AS VALOR
			 ,PC.pp_cuenta             					 AS CUENTA
			 ,GETDATE()				                     AS FECHA_INGRESO
			 ,FP.fp_fecha								 AS FECHA_CONTABLE
			 ,FP.fp_estado							  	 AS ESTADO	  
			 ,@TERMINAL									 AS TERMINAL
			 ,@USUARIO									 AS USUARIO
			 ,FP.fp_cotizacion							 AS COTIZACION
			 ,FP.fp_moneda								 AS MONEDA
			 ,FP.fp_fecha       						 AS FECHA_FACTURA  
			 ,1											 AS LINEA
			 ,FP.fp_cod_empresa   						 AS COD_EMPRESA
			 ,PC.pp_descripcion_cta                      AS DESCRIPCION_CTA   

        FROM [db_facturacion].[dbo].[tb_formas_pagos] FP WITH(NOLOCK)
		INNER JOIN db_facturacion..tb_parametros_contables_pagos PC  WITH(NOLOCK) ON PC.pp_id_param = @INST_PENDIENTES_2 AND PC.pp_id_empresa = @ID_EMPRESA
	    WHERE FP.fp_forma_pago IN ('CCA')
	    AND [dbo].[DateOnly](fp_fecha) =@FECHA_CORTE
	    AND FP.fp_moneda = @MONEDA_LOCAL
	    AND FP.fp_cod_empresa = @ID_EMPRESA
		AND FP.fp_estado IN (@ESTADO)

--========================================================================================--
--====================================== INISHORT ========================================--

    UNION ALL

	-- INGRESO DEPOSITOS INISHORT EN HUNTER DEL CARIBE

       SELECT  
		      FP.fp_num_pago		                                                          AS NUMERO_PAGO
		     ,0																				  AS TIPO_DOCUMENTO
		     ,fp.fp_forma_pago																  AS COD_FORMA_PAGO
			 ,CASE 
			    WHEN fp_forma_pago IN ('DPC') 
				AND (MONTH(fp_fecha_deposito) <> MONTH(fp_fecha) 
				OR YEAR(fp_fecha) <> YEAR(fp_fecha_deposito)) THEN @NO_IDENTIFICADO
				ELSE BP.bp_id END				                                              AS ID_PARAMETRO                                                   
			,FP.fp_valor				                                                      AS VALOR
			,CASE 
			    WHEN fp_forma_pago IN ('DPC') 
				AND (MONTH(fp_fecha_deposito) <> MONTH(fp_fecha) 
				OR YEAR(fp_fecha) <> YEAR(fp_fecha_deposito)) THEN @DEPOSITO_CTA_NO_IDENTIFICADO
				ELSE BP.bp_cuenta_contable END						                          AS CUENTA
			 ,GETDATE()				                                                          AS FECHA_INGRESO
			 ,FP.fp_fecha																	  AS FECHA_CONTABLE
			 ,FP.fp_estado							  										  AS ESTADO	  
			 ,@TERMINAL																		  AS TERMINAL
			 ,@USUARIO																		  AS USUARIO
			 ,FP.fp_cotizacion																  AS COTIZACION
			 ,FP.fp_moneda																	  AS MONEDA
			 ,FP.fp_fecha       															  AS FECHA_FACTURA  
			 ,1																				  AS LINEA
			 ,@ID_EMPRESA_INISHORT       													  AS COD_EMPRESA
			 ,CASE 
			    WHEN fp_forma_pago IN ('DPC') 
				AND (MONTH(fp_fecha_deposito) <> MONTH(fp_fecha) 
				OR YEAR(fp_fecha) <> YEAR(fp_fecha_deposito)) THEN P.pp_descripcion_cta
				ELSE C.cu_descripcion END                                                     AS DESCRIPCION_CTA

		 FROM  db_iniShort.dbo.tb_ini_formas_pagos FP WITH (NOLOCK)
		 INNER JOIN [db_facturacion].PARAMETRIZACION.tb_banco_parametrizacion BP ON FP.fp_id_banco_cuenta = BP.bp_id 
		 INNER JOIN tl_contabilidad..co_cuenta C ON C.cu_cuenta = BP.bp_cuenta_contable AND C.cu_uni_neg = BP.bp_uni_neg
		 INNER JOIN db_facturacion..tb_parametros_contables_pagos P ON  P.pp_cuenta = @DEPOSITO_CTA_NO_IDENTIFICADO AND P.pp_id_empresa = @ID_EMPRESA_INISHORT
		 WHERE FP.fp_forma_pago IN ('DPC','CHQ')
		 AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	     AND FP.fp_moneda = @MONEDA_LOCAL
		 AND FP.fp_estado IN (@ESTADO)
	
	UNION ALL

	--ITBIS CARDNET INISHORT

		 SELECT 
		        FP.fp_num_pago                     AS NUMERO_PAGO
		       ,0								   AS TIPO_DOCUMENTO
			   ,FP.fp_forma_pago				   AS COD_FORMA_PAGO
			   ,@ITBIS_CARDNET					   AS ID_PARAMETRO		
			   ,(FP.fp_valor * @ITBIS_RETENIDO)	   AS VALOR
			   ,PC.pp_cuenta					   AS CUENTA		  
			   ,GETDATE()						   AS FECHA_INGRESO
			   ,FP.fp_fecha						   AS FECHA_CONTABLE
			   ,FP.fp_estado					   AS ESTADO	  
			   ,@TERMINAL						   AS TERMINAL
			   ,@USUARIO						   AS USUARIO
			   ,FP.fp_cotizacion				   AS COTIZACION
			   ,FP.fp_moneda					   AS MONEDA
			   ,FP.fp_fecha         			   AS FECHA_FACTURA     
			   ,1								   AS LINEA
			   ,@ID_EMPRESA_INISHORT	           AS COD_EMPRESA
			   ,PC.pp_descripcion_cta              AS DESCRIPCION_CTA

	     FROM db_iniShort.dbo.tb_ini_formas_pagos FP with(nolock) 
		 INNER JOIN db_facturacion..tb_parametros_contables_pagos PC WITH(NOLOCK) ON PC.pp_id_param = @ITBIS_CARDNET AND PC.pp_id_empresa = @ID_EMPRESA_INISHORT
	     WHERE FP.fp_forma_pago IN('TRJ')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
		 AND FP.fp_estado  IN (@ESTADO)

	UNION ALL

	--COMISION CARNET INISHORT

		 SELECT  
		     FP.fp_num_pago	                        AS NUMERO_PAGO
		    ,0										AS TIPO_DOCUMENTO
		    ,FP.fp_forma_pago						AS COD_FORMA_PAGO
			,@COMISON_CARDNET						AS ID_PARAMETRO		
			,(FP.fp_valor * @COMISION)          	AS VALOR
			,PC.pp_cuenta							AS CUENTA		  
			,GETDATE()								AS FECHA_INGRESO
			,FP.fp_fecha							AS FECHA_CONTABLE
			,FP.fp_estado						  	AS ESTADO	  
			,@TERMINAL								AS TERMINAL
			,@USUARIO								AS USUARIO
			,FP.fp_cotizacion						AS COTIZACION
			,FP.fp_moneda							AS MONEDA
			,FP.fp_fecha           					AS FECHA_FACTURA     
			,1										AS LINEA
			,@ID_EMPRESA_INISHORT  					AS COD_EMPRESA
			,PC.pp_descripcion_cta                  AS DESCRIPCION_CTA

	     FROM db_iniShort.dbo.tb_ini_formas_pagos FP with(nolock) 
		 INNER JOIN db_facturacion..tb_parametros_contables_pagos PC WITH(NOLOCK) ON PC.pp_id_param = @COMISON_CARDNET AND PC.pp_id_empresa = @ID_EMPRESA_INISHORT
	     WHERE FP.fp_forma_pago IN ('TRJ')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
		 AND FP.fp_estado IN (@ESTADO)

   UNION ALL

		 --PAGOS TARJETA INISHORT 

		  SELECT  
		      FP.fp_num_pago		                         AS NUMERO_PAGO
		     ,0											     AS TIPO_DOCUMENTO
		     ,FP.fp_forma_pago							     AS COD_FORMA_PAGO
			 ,BP.bp_id 			                             AS ID_PARAMETRO                                                   
			 ,(FP.fp_valor - (FP.fp_valor * @VALOR_TARJETA)) AS VALOR
			 ,BP.bp_cuenta_contable 					     AS CUENTA
			 ,GETDATE()				                         AS FECHA_INGRESO
			 ,FP.fp_fecha								     AS FECHA_CONTABLE
			 ,FP.fp_estado							  	     AS ESTADO	  
			 ,@TERMINAL									     AS TERMINAL
			 ,@USUARIO									     AS USUARIO
			 ,FP.fp_cotizacion							     AS COTIZACION
			 ,FP.fp_moneda								     AS MONEDA
			 ,FP.fp_fecha       						     AS FECHA_FACTURA  
			 ,1                                              AS LINEA
			 ,@ID_EMPRESA_INISHORT				    	     AS COD_EMPRESA
			 ,C.cu_descripcion							     AS DESCRIPCION_CTA

	     FROM db_iniShort.dbo.tb_ini_formas_pagos FP WITH(NOLOCK)
	     INNER JOIN [db_facturacion].PARAMETRIZACION.tb_banco_parametrizacion BP ON FP.fp_id_banco_cuenta = BP.bp_id 
		 INNER JOIN tl_contabilidad..co_cuenta C ON C.cu_cuenta = BP.bp_cuenta_contable AND C.cu_uni_neg = BP.bp_uni_neg
	     WHERE fp_forma_pago IN ('TRJ')
	     AND [dbo].[DateOnly](fp_fecha) = @FECHA_CORTE
	     AND FP.fp_moneda = @MONEDA_LOCAL
		 AND FP.fp_estado IN (@ESTADO)
--========================================================================================--
--========================================================================================--


)

       INSERT INTO [dbo].[tb_interfase_empresas]
			   ([in_num_documento]            ,[in_tipo_documento]           ,[in_cod_forma_pago]
			   ,[in_param]                    ,[in_valor]		             ,[in_cuenta]                   
			   ,[in_fecha_ing]                ,[in_fecha_cont]				 ,[in_estado]                   
			   ,[in_terminal]                 ,[in_operador]				 ,[in_cotizacion]
			   ,[in_moneda]					  ,in_fecha_facturaCXC			 ,in_linea
			   ,[in_cod_empresa]              ,[in_descripcion_cta])

         SELECT  NUMERO_PAGO                  ,TIPO_DOCUMENTO                ,COD_FORMA_PAGO
		        ,ID_PARAMETRO                 ,VALOR                         ,CUENTA
				,FECHA_INGRESO                ,FECHA_CONTABLE                ,ESTADO
				,TERMINAL                     ,USUARIO                       ,COTIZACION
				,MONEDA                       ,FECHA_FACTURA                 ,LINEA
				,COD_EMPRESA                  ,DESCRIPCION_CTA
		 
		 FROM CTE




		DELETE FROM [dbo].[tb_interfase_empresas] 
		WHERE [in_tipo_documento] <> 6 AND [in_num_documento] in 
		(
			SELECT p_numero FROM tb_pagos WITH(NOLOCK) WHERE [dbo].[DateOnly]([p_fecha]) = @FECHA_CORTE
			AND p_tipo_docum = 5
		)

	   DELETE FROM [dbo].[tb_interfase_empresas] 
	   WHERE in_valor  = 0 
	   And [in_tipo_documento] <> 6
	   AND [in_cod_empresa] = @id_empresa

----PAGOS FIN---------------------------------------------------------------------------------------------------------------------------------------

END
