USE [db_facturacion]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
--===========================================================--
--AUTOR:"LUIS DEL ORBE" 14-10-2021
--===========================================================--

ALTER PROCEDURE [dbo].[usp_interfase_factura_empresas] --'2021-12-06',1,'SA','R'
(
	@FECHA_CORTE  DATETIME,
	@ID_EMPRESA   INT,
	@USUARIO	  VARCHAR(50),
	@ESTADO       VARCHAR(5)
)
AS 
BEGIN

DECLARE   --@USUARIO  VARCHAR(25) =  'SA'
         --,@ID_EMPRESA INT = 1  
		 --,@FECHA_CORTE DATETIME = '2021-10-01'
		  @PARAM_ITBIS INT = 15                 --ITBIS COBRADO
		 ,@PARAM_CXC INT = 1                    --CUENTAS POR COBRAR CLIENTE
		 ,@PARAM_INGRESOS_DIRECTOS INT = 3      --INGRESO DIRECTO
		 ,@PARAM_INGRESOS_ASEGURADORA INT = 2   --INGRESO ASEGURADORA
		 ,@PARAM_CXC_ASEGURADORA INT = 14       --DESCUENTO ASEGURADORA
		 ,@PARAM_PRIMA_ASEGURADORA INT = 13     --PRIMA
		 ,@PARAM_DESCUENTO INT = 12             --DESCUENTO 
		 ,@PARAM_DESCUENTO_ASEGURADORA INT = 11 --DESCUENTO ASEGURADORA
		 ,@TIPO_DOCUMENTO INT = 6
		 ,@TERMINAL VARCHAR(25) = HOST_NAME()
		 ,@MONEDA INT = 1
	
--SETEO VALORES
-----------------------------------------------------------------------------------------------
	SET @FECHA_CORTE = [dbo].[DateOnly](@FECHA_CORTE)

	DELETE FROM db_facturacion.DBO.tb_interfase_empresas
	WHERE in_tipo_documento = @TIPO_DOCUMENTO
	AND in_cod_empresa = @ID_EMPRESA
------------------------------------------------------------------------------------------------


;WITH CTE AS (

   --ITBIS COBRADO			 --CORRECTO

	    SELECT 
	           DF.de_numero	                                              AS NUMERO_FACTURA
	          ,@TIPO_DOCUMENTO                                            AS TIPO_DOCUMENTO					                              
	          ,'-'                                                        AS COD_FORMA_PAGO
			  ,PF.pf_id_parametro                                         AS ID_PARAMETRO
			  ,(DF.de_itbis *-1)                                          AS VALOR			                              
			  ,PF.pf_cuenta                                               AS CUENTA
			  ,GETDATE()			                                      AS FECHA_INGRESO			  
			  ,DF.de_fecha		                                          AS FECHA_CONTABLE	
			  ,DF.de_estado                                               AS ESTADO
			  ,@TERMINAL		                                          AS TERMINAL			
			  ,@USUARIO			                                          AS USUARIO			       
			  ,DF.de_cotizacion                                           AS COTIZACION
			  ,@MONEDA				                                      AS MONEDA			
			  ,CONVERT(VARCHAR,DF.de_num_linea) + '-' + DF.de_descripcion AS DESCRIPCION
			  ,DF.de_num_linea                                            AS LINEA
			  ,de_cod_empresa                                             AS COD_EMPRESA
		
		FROM [db_facturacion].[dbo].[tb_detalle_factura] DF WITH(NOLOCK) 
		LEFT JOIN [db_facturacion].[dbo].[tb_parametros_contables_facturas] PF WITH(NOLOCK) ON PF.pf_id_producto = DF.de_item AND pf.pf_id_parametro = @PARAM_ITBIS
		WHERE DF.de_cod_empresa = @ID_EMPRESA
		AND CAST(de_fecha AS DATE) = @FECHA_CORTE
		AND DF.de_estado IN(@ESTADO)
				
  UNION ALL

   --CUENTA POR COBRAR CLIENTE  

	     SELECT     
				 DF.de_numero                                               AS NUMERO_FACTURA
				,@TIPO_DOCUMENTO                                            AS TIPO_DOCUMENTO
				,'-'                                                        AS COD_FORMA_PAGO
				,PF.pf_id_parametro                                         AS ID_PARAMETRO
				,DF.de_total                                                AS VALOR
				,PF.pf_cuenta                                               AS CUENTA
				,GETDATE()                                                  AS FECHA_INGRESO
				,DF.de_fecha                                                AS FECHA_CONTABLE
				,DF.de_estado                                               AS ESTADO
				,@TERMINAL                                                  AS TERMINAL 
				,@USUARIO                                                   AS USUARIO
				,DF.de_cotizacion                                           AS COTIZACION
				,@MONEDA                                                    AS MONEDA
				,convert(varchar,DF.de_num_linea) + '-' + DF.de_descripcion AS DESCRIPCION
				,DF.de_num_linea                                            AS LINEA
				,DF.de_cod_empresa                                          AS COD_EMPRESA
		 
		FROM [db_facturacion].[dbo].[tb_detalle_factura] DF WITH (NOLOCK)		
		LEFT JOIN [db_facturacion].[dbo].[tb_parametros_contables_facturas] PF WITH (NOLOCK) ON pf_id_producto = de_item 
		AND [dbo].[DateOnly](DF.de_fecha) = @FECHA_CORTE
		AND de_cod_empresa  = @ID_EMPRESA
		WHERE pf_id_parametro = @PARAM_CXC
		AND DF.de_estado IN(@ESTADO)

 UNION ALL
        
     --INGRESOS DIRECTOS

	     SELECT     
				 DF.de_numero                                               AS NUMERO_FACTURA
				,@TIPO_DOCUMENTO                                            AS TIPO_DOCUMENTO
				,'-'                                                        AS COD_FORMA_PAGO
				,PF.pf_id_parametro                                         AS ID_PARAMETRO
				,(DF.de_subtotal * -1)                                      AS VALOR
				,PF.pf_cuenta                                               AS CUENTA
				,GETDATE()                                                  AS FECHA_INGRESO
				,DF.de_fecha                                                AS FECHA_CONTABLE
				,DF.de_estado                                               AS ESTADO
				,@TERMINAL                                                  AS TERMINAL 
				,@USUARIO                                                   AS USUARIO
				,DF.de_cotizacion                                           AS COTIZACION
				,@MONEDA                                                    AS MONEDA
				,convert(varchar,DF.de_num_linea) + '-' + DF.de_descripcion AS DESCRIPCION
				,DF.de_num_linea                                            AS LINEA
				,DF.de_cod_empresa                                          AS COD_EMPRESA

        FROM [db_facturacion].[dbo].[tb_detalle_factura] DF WITH(NOLOCK) 
		LEFT JOIN [db_facturacion].[dbo].[tb_parametros_contables_facturas] PF WITH(NOLOCK) ON PF.pf_id_producto = DF.de_item 
		AND [dbo].[DateOnly](de_fecha) = @FECHA_CORTE
		AND de_cod_empresa = @ID_EMPRESA
		AND de_descuento_sa = 0
		WHERE pf_id_parametro = @PARAM_INGRESOS_DIRECTOS
		AND DF.de_estado IN(@ESTADO)

 UNION ALL
       
	   --INGRESOS ASEGURADORA

	     SELECT     
				 DF.de_numero                                               AS NUMERO_FACTURA
				,@TIPO_DOCUMENTO                                            AS TIPO_DOCUMENTO
				,'-'                                                        AS COD_FORMA_PAGO
				,PF.pf_id_parametro                                         AS ID_PARAMETRO
				,(DF.de_subtotal * -1)                                      AS VALOR
				,PF.pf_cuenta                                               AS CUENTA
				,GETDATE()                                                  AS FECHA_INGRESO
				,DF.de_fecha                                                AS FECHA_CONTABLE
				,DF.de_estado                                               AS ESTADO
				,@TERMINAL                                                  AS TERMINAL 
				,@USUARIO                                                   AS USUARIO
				,DF.de_cotizacion                                           AS COTIZACION
				,@MONEDA                                                    AS MONEDA
				,convert(varchar,DF.de_num_linea) + '-' + DF.de_descripcion AS DESCRIPCION
				,DF.de_num_linea                                            AS LINEA
				,DF.de_cod_empresa                                          AS COD_EMPRESA

        FROM [db_facturacion].[dbo].[tb_detalle_factura] DF WITH(NOLOCK) 
		LEFT JOIN [db_facturacion].[dbo].[tb_parametros_contables_facturas] PF WITH(NOLOCK) ON PF.pf_id_producto = DF.de_item 
		AND [dbo].[DateOnly](de_fecha) = @FECHA_CORTE
		AND de_cod_empresa = @ID_EMPRESA
		AND de_descuento_sa <> 0
		WHERE pf_id_parametro = @PARAM_INGRESOS_ASEGURADORA
		AND DF.de_estado IN(@ESTADO)

 UNION ALL
      
	  --CXC ASEGURADORA
	  SELECT 
				 DF.de_numero                                               AS NUMERO_FACTURA
				,@TIPO_DOCUMENTO                                            AS TIPO_DOCUMENTO
				,'-'                                                        AS COD_FORMA_PAGO
				,PF.pf_id_parametro                                         AS ID_PARAMETRO
				,DF.de_descuento_sa_bse                                     AS VALOR
				,PF.pf_cuenta                                               AS CUENTA
				,GETDATE()                                                  AS FECHA_INGRESO
				,DF.de_fecha                                                AS FECHA_CONTABLE
				,DF.de_estado                                               AS ESTADO
				,@TERMINAL                                                  AS TERMINAL 
				,@USUARIO                                                   AS USUARIO
				,DF.de_cotizacion                                           AS COTIZACION
				,@MONEDA                                                    AS MONEDA
				,convert(varchar,DF.de_num_linea) + '-' + DF.de_descripcion AS DESCRIPCION
				,DF.de_num_linea                                            AS LINEA
				,DF.de_cod_empresa                                          AS COD_EMPRESA

	  FROM [db_facturacion].[dbo].[tb_detalle_factura] DF WITH (NOLOCK) 
	  LEFT JOIN [db_facturacion].[dbo].[tb_parametros_contables_facturas] PF WITH (NOLOCK) ON PF.pf_id_producto = DF.de_item 
	  INNER JOIN [db_facturacion].[dbo].[tb_factura] F WITH (NOLOCK)  ON DF.de_numero = F.fa_numero
	  INNER JOIN [db_facturacion].[dbo].[tb_ordtra] O WITH (NOLOCK)   ON F.fa_ord_tra = O.ot_codigo	
	  WHERE pf_id_parametro = @PARAM_CXC_ASEGURADORA
	  AND [dbo].[DateOnly](de_fecha) = @FECHA_CORTE
	  AND de_cod_empresa =  @ID_EMPRESA
	  AND pf_aseguradora = ot_cia_seguros
	  AND DF.de_estado IN(@ESTADO)

 UNION ALL
  
  --PRIMA ASEGURADORA

	  SELECT 
				 DF.de_numero                                               AS NUMERO_FACTURA
				,@TIPO_DOCUMENTO                                            AS TIPO_DOCUMENTO
				,'-'                                                        AS COD_FORMA_PAGO
				,PF.pf_id_parametro                                         AS ID_PARAMETRO
				,(DF.de_descuento_sa - DF.de_descuento_sa_bse)              AS VALOR
				,PF.pf_cuenta                                               AS CUENTA
				,GETDATE()                                                  AS FECHA_INGRESO
				,DF.de_fecha                                                AS FECHA_CONTABLE
				,DF.de_estado                                               AS ESTADO
				,@TERMINAL                                                  AS TERMINAL 
				,@USUARIO                                                   AS USUARIO
				,DF.de_cotizacion                                           AS COTIZACION
				,@MONEDA                                                    AS MONEDA
				,convert(varchar,DF.de_num_linea) + '-' + DF.de_descripcion AS DESCRIPCION
				,DF.de_num_linea                                            AS LINEA
				,DF.de_cod_empresa                                          AS COD_EMPRESA

	  FROM [db_facturacion].[dbo].[tb_detalle_factura] DF WITH (NOLOCK)		
	  LEFT JOIN [db_facturacion].[dbo].[tb_parametros_contables_facturas] PF WITH (NOLOCK) ON pf_id_producto = de_item 
	  AND [dbo].[DateOnly](DF.de_fecha) = @FECHA_CORTE
	  AND de_cod_empresa  = @ID_EMPRESA
	  WHERE pf_id_parametro = @PARAM_PRIMA_ASEGURADORA
	  AND DF.de_estado IN(@ESTADO)

 UNION ALL

      --DESCUENTOS

	   SELECT 
				 DF.de_numero                                               AS NUMERO_FACTURA
				,@TIPO_DOCUMENTO                                            AS TIPO_DOCUMENTO
				,'-'                                                        AS COD_FORMA_PAGO
				,PF.pf_id_parametro                                         AS ID_PARAMETRO
				,(DF.de_descuento_lj + DF.de_monto_financiado)              AS VALOR
				,PF.pf_cuenta                                               AS CUENTA
				,GETDATE()                                                  AS FECHA_INGRESO
				,DF.de_fecha                                                AS FECHA_CONTABLE
				,DF.de_estado                                               AS ESTADO
				,@TERMINAL                                                  AS TERMINAL 
				,@USUARIO                                                   AS USUARIO
				,DF.de_cotizacion                                           AS COTIZACION
				,@MONEDA                                                    AS MONEDA
				,convert(varchar,DF.de_num_linea) + '-' + DF.de_descripcion AS DESCRIPCION
				,DF.de_num_linea                                            AS LINEA
				,DF.de_cod_empresa                                          AS COD_EMPRESA

	  FROM [db_facturacion].[dbo].[tb_detalle_factura] DF WITH (NOLOCK)		
	  LEFT JOIN [db_facturacion].[dbo].[tb_parametros_contables_facturas] PF WITH (NOLOCK) ON pf_id_producto = de_item 
	  AND [dbo].[DateOnly](DF.de_fecha) = @FECHA_CORTE
	  AND de_cod_empresa  = @ID_EMPRESA
	  AND DF.de_descuento_sa = 0
	  WHERE pf_id_parametro = @PARAM_DESCUENTO
	  AND DF.de_estado IN(@ESTADO)

 UNION ALL 

  -- DESCUENTO ASEGURADORA

      SELECT 
				 DF.de_numero                                               AS NUMERO_FACTURA
				,@TIPO_DOCUMENTO                                            AS TIPO_DOCUMENTO
				,'-'                                                        AS COD_FORMA_PAGO
				,PF.pf_id_parametro                                         AS ID_PARAMETRO
				,DF.de_descuento_lj                                         AS VALOR
				,PF.pf_cuenta                                               AS CUENTA
				,GETDATE()                                                  AS FECHA_INGRESO
				,DF.de_fecha                                                AS FECHA_CONTABLE
				,DF.de_estado                                               AS ESTADO
				,@TERMINAL                                                  AS TERMINAL 
				,@USUARIO                                                   AS USUARIO
				,DF.de_cotizacion                                           AS COTIZACION
				,@MONEDA                                                    AS MONEDA
				,convert(varchar,DF.de_num_linea) + '-' + DF.de_descripcion AS DESCRIPCION
				,DF.de_num_linea                                            AS LINEA
				,DF.de_cod_empresa                                          AS COD_EMPRESA

	  FROM [db_facturacion].[dbo].[tb_detalle_factura] DF WITH (NOLOCK)		
	  LEFT JOIN [db_facturacion].[dbo].[tb_parametros_contables_facturas] PF WITH (NOLOCK) ON pf_id_producto = de_item 
	  AND [dbo].[DateOnly](DF.de_fecha) = @FECHA_CORTE
	  AND de_cod_empresa  = @ID_EMPRESA
	  AND DF.de_descuento_sa <> 0
	  WHERE pf_id_parametro = @PARAM_DESCUENTO_ASEGURADORA
	  AND DF.de_estado IN(@ESTADO)
  
)

--INSERT

    INSERT INTO [dbo].[tb_interfase_empresas]
			   ([in_num_documento]            ,[in_tipo_documento]           ,[in_cod_forma_pago]
			   ,[in_param]                    ,[in_valor]                    ,[in_cuenta]                   
			   ,[in_fecha_ing]                ,[in_fecha_cont]				 ,[in_estado]                   
			   ,[in_terminal]                 ,[in_operador]				 ,[in_cotizacion]
			   ,[in_moneda]					  ,[in_descripcion_reg]			 ,in_linea
			   ,in_cod_empresa)

    SELECT     NUMERO_FACTURA,                 TIPO_DOCUMENTO,                 COD_FORMA_PAGO,
	           ID_PARAMETRO,                   VALOR,                          CUENTA,
		       FECHA_INGRESO,                  FECHA_CONTABLE,                 ESTADO,
		       TERMINAL,                       USUARIO,                        COTIZACION,
		       MONEDA,                         DESCRIPCION,                    LINEA,
		       COD_EMPRESA		
	FROM CTE 
	WHERE VALOR NOT IN (0)
	
END	
GO