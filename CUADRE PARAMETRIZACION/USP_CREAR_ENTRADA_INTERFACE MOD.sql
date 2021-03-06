USE [db_facturacion]
GO
/****** Object:  StoredProcedure [dbo].[usp_entrada_interface_empresas]    Script Date: 10/12/2021 12:14:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[usp_entrada_interface_empresas] --'2021-11-09','LUIS',1,2
(
	@fecha_corte   AS DATETIME,
	@usuario	   AS VARCHAR(50),
	@crear_entrada AS INT,
	@empresa	   AS INT,
	@ESTADO_DOC    AS VARCHAR(25) = 'G'
)
AS
BEGIN
    DECLARE 
	    @ESTADO_NO_DESEADO            VARCHAR(5),
	    @CTA_CXC                      VARCHAR(25) = '1121001', 
		@VALOR_CXC                    MONEY,
		@CTA_INSTALACION_PENDIENTE_2  VARCHAR(25) = '2141009',
		@ID_EMPRESA_INISHORT          INT = 1,
        @num_entrada_contable	      INT,
        @w_fecha_contable		      INT,
        @cuenta					      INT,
        @moneda					      INT,
        @cont_linea_entrada		      INT,
        @cont_linea_factura		      INT,
        @centro_costo			      INT,
        @id_renglon				      INT,
        @_debito_RD				      MONEY,
        @_credito_RD			      MONEY,
        @_debito_US				      MONEY,
        @_credito_US			      MONEY,
        @_valor					      MONEY,
        @_compra				      MONEY,
        @_venta					      MONEY,
        @fa_impuesto			      MONEY,
        @w_cotizacion			      MONEY,
        @diferencia_entrada		      MONEY,
        @estado					      VARCHAR(1),
        @origen_entrada			      VARCHAR(3),
        @tipo					      VARCHAR(3),
        @unidad_neg				      VARCHAR(10),
        @terminal				      VARCHAR(50),
        @comentario				      VARCHAR(150),
        @anio_detalle                 INT,
        @mes_detalle                  INT

	SET @fecha_corte = dbo.dateonly(@fecha_corte)

	DELETE FROM [db_facturacion].[dbo].[tb_interfase_empresas]

	--CARGA INTERFACE FACTURAS
	EXEC usp_interfase_factura_empresas @FECHA_CORTE, @empresa ,@usuario, @ESTADO_DOC
	
	--CARGA INTERFACE PAGOS
	EXEC usp_interfase_pagos_empresas @FECHA_CORTE, @empresa ,@usuario, @ESTADO_DOC

	IF(@ESTADO_DOC = 'G')
	 BEGIN
	    SET @ESTADO_NO_DESEADO = 'R'
		SET @comentario = 'PARAMETRIZACION'

	  END
	  ELSE
	 BEGIN
	    SET @ESTADO_NO_DESEADO = 'G'
		SET @comentario = 'REVERSO'
	  END

	IF @crear_entrada = 0 
		BEGIN
			SELECT 'LA ENTRADA CONTABLE NO SE HA CREADO. SOLO SE HAN PRECARGADO LOS DATOS'
			RETURN 1
		END

	IF ((SELECT count(*) 
	     FROM [db_facturacion].[dbo].[tb_interfase_empresas] WITH(NOLOCK)
		 WHERE [in_operador] = @usuario
		   AND [dbo].[DateOnly]([in_fecha_cont]) = @fecha_corte) = 0)
		BEGIN
			SELECT 'NO HAY DATOS PARA GENERAR UNA ENTRADA CONTABLE EN ESTE DIA'
			RETURN 1
		END

--BORRANDO LA CUENTA POR COBRAR DE LOS PAGOS DE CONTADO
		DELETE FROM [dbo].[tb_interfase_empresas] WHERE [in_tipo_documento] IN (1,2) AND in_cuenta = @CTA_CXC

		DELETE FROM [dbo].[tb_interfase_empresas] WHERE in_id IN
		(
			SELECT in_id 
			FROM [dbo].[tb_interfase_empresas] WITH(NOLOCK)
			INNER JOIN dbo.tb_detalle_pagos WITH(NOLOCK) ON in_num_documento = dp_num_pago
			INNER JOIN tb_detalle_factura WITH(NOLOCK) ON de_numero = dp_num_factura
			WHERE [in_tipo_documento] <> 6 and in_cuenta = @CTA_CXC --CUENTA CONTABLE CTAS X COBRAR DE HUNTER DEL CARIBE
			AND in_cod_empresa = @empresa
			AND dbo.dateonly([in_fecha_cont]) = dbo.dateonly(de_fecha)
			AND [dbo].[DateOnly]([in_fecha_facturaCXC]) = @fecha_corte
	)
--BORRANDO LA CUENTA POR COBRAR DE LOS PAGOS DE CONTADO
 

-----------------------------------CREACION DE LA ENTRADA CONTABLE--------------------------------------------
    EXEC tl_contabilidad.[dbo].[usp_Obtener_cotizacion]
		@i_fecha = @fecha_corte,
		@_compra = @_compra OUTPUT,
		@_venta	 = @_venta OUTPUT


		SELECT TOP 1 @unidad_neg = un_abreviatura 
		FROM tl_contabilidad.[dbo].cl_unineg
		WHERE un_id_empresa = @empresa

--SET @unidad_neg			= 'CONTAB'

        SET @_debito_US			= 0
        SET @_credito_US		= 0
        SET @usuario			= 'sa'
        SET @terminal			= 'Appserver'
        SET	@estado				= 'E'
        SET @tipo				= '01'
        SET @unidad_neg			= @unidad_neg
        SET @origen_entrada		= 'FAC'
        SET @comentario			= @comentario +' FACTURAS/PAGOS LUIS: ' +@unidad_neg+', '+CONVERT(VARCHAR(10),@fecha_corte, 101)
        SET @cont_linea_entrada = 1
        SET @anio_detalle       = YEAR(@fecha_corte)
        SET @mes_detalle        = MONTH(@fecha_corte)
--------------------------------------------------HEADER ENTRADAS CONTABLES---------------------------------------------
	    EXEC tl_contabilidad..usp_entrada_diario 
	    @s_user				= @usuario,
	    @s_term				= @terminal,
	    @i_operacion		= 'C',
	    @i_uni_neg			= @unidad_neg,
	    @i_tipo				= @tipo,
	    @i_ano				= 2016,
	    @i_mes				= 1,
	    @i_fecha_con		= @fecha_corte,
	    @i_glosa			= @comentario,
	    @i_tot_debito		= 0,
	    @i_tot_credito		= 0,
	    @i_tot_dbse			= 0,
	    @i_tot_cbse			= 0,
	    @i_moneda			= 1,
	    @i_moneda_bse		= 2,
	    @i_cotizacion		= @_venta,
	    @i_origen			= @origen_entrada,
	    @i_estado			= @estado,
	    @i_cuenta			= '-',
	    @i_dpto				= '-',
	    @i_producto			= '-',
	    @i_proyecto			= '-',
	    @i_openitem			= '-',
	    @i_linea			= 0,
	    @o_numero			= @num_entrada_contable OUTPUT 

	    SELECT @num_entrada_contable AS NUMEROENTRADA
	
--------------------------------------------------HEADER ENTRADAS CONTABLES---------------------------------------------
--------------------------------------------------DETALLE ENTRADAS CONTABLES---------------------------------------------

--CHEQUE, EFECTIVO, CXC ETC
     DROP TABLE IF EXISTS #CHQ_EFE_CXC_TEMP

	     SELECT in_cuenta          AS CUENTA,		
		       SUM([in_valor])     AS DEBITO,        
			   0                   AS CREDITO,			         
	    	   0                   AS CENTRO_COSTO,		
			   'DEBITO'			   AS COMENTARIO	
			   INTO #CHQ_EFE_CXC_TEMP
	    FROM [dbo].[tb_interfase_empresas] WITH(NOLOCK)
	    WHERE [in_valor] > 0
	    AND in_cod_forma_pago NOT IN ('DPC','TRJ','RTC','RT1','R5%')  
	    AND [dbo].[DateOnly]([in_fecha_cont]) = @FECHA_CORTE
	    AND in_cod_empresa = @empresa
	    GROUP BY in_cuenta, in_cod_forma_pago
    	  
--=========================================================================--
--========================= BUSCO PAGOS DEL DIA ===========================-- 

;WITH CTE_CXC AS ( 
		     SELECT 1 AS UNO,
		     ISNULL(( SELECT SUM(dp_valor) FROM dbo.tb_pagos 
			 INNER JOIN dbo.tb_detalle_pagos ON p_numero = dp_num_pago  AND dp_cod_empresa = p_cod_empresa
			 WHERE dp_num_factura = F.fa_numero AND dbo.DateOnly(dp_fecha_documento) <= dbo.DateOnly(@FECHA_CORTE)
			 AND p_cod_empresa = @empresa
			 AND p_estado NOT IN (@ESTADO_NO_DESEADO)
			 AND dbo.DateOnly(ISNULL(p_fecha_reversion,DATEADD(d,1,@FECHA_CORTE))) > dbo.DateOnly(@FECHA_CORTE)		
			),0.00) AS CTA_X_COBRAR
			FROM [db_facturacion]..tb_factura F  WITH(NOLOCK)
			WHERE CAST(F.fa_fecha AS DATE) = @FECHA_CORTE
			AND F.fa_cod_empresa = @empresa
          )


--========================================================================--
--==================== TOMO VALOR DE CXC DEL DIA =========================--

		    SELECT @VALOR_CXC =  SUM(CTA_X_COBRAR) FROM CTE_CXC

--========================================================================--
--=== ACTUALIZO VALOR DE CUENTAS POR COBRAR , MENOS LOS PAGOS DEL DIA ====--

	    UPDATE #CHQ_EFE_CXC_TEMP
	    SET DEBITO   = (DEBITO - @VALOR_CXC)
	    WHERE CUENTA = @CTA_CXC

--========================================================================--
--====================== PASIVO INISHORT =================================--

DROP TABLE IF EXISTS #PASIVO_INISHORT

           SELECT 
		     @CTA_INSTALACION_PENDIENTE_2 AS CUENTA,
             0                            AS DEBITO,
		     COALESCE(SUM(FP.fp_valor),0) AS CREDITO,
		     0                            AS CENTRO_COSTO,
		     'CREDITO'                    AS COMENTARIO		
			 INTO #PASIVO_INISHORT
		   FROM db_iniShort..tb_ini_formas_pagos FP WITH(NOLOCK)
		   WHERE CAST(FP.fp_fecha AS DATE) = @fecha_corte
		   AND FP.fp_estado NOT IN (@ESTADO_NO_DESEADO)
		   AND FP.fp_forma_pago NOT IN('CRC','EFE')
		   AND @ID_EMPRESA_INISHORT = @empresa -- SOLO A HUNTER DEL CARIBE

--========================================================================--
--================ INICIO DEL CURSOR PARA INSERTAR =======================--

  DECLARE Entrada_contable CURSOR FOR

	    --DEPOSITOS ,RETENCIONES
		    SELECT
		       in_cuenta          AS CUENTA,
		       [in_valor]	      AS DEBITO,        
			   0                  AS CREDITO,			         
	    	   0                  AS CENTRO_COSTO,		
			   'DEBITO'			  AS COMENTARIO	
			FROM [dbo].[tb_interfase_empresas] I  WITH(NOLOCK)
			WHERE [in_valor] > 0
			AND in_cod_forma_pago IN ('DPC','RTC','RT1','R5%')
			AND [dbo].[DateOnly]([in_fecha_cont]) = @fecha_corte
			AND in_cod_empresa = @empresa
	    
	  UNION ALL

	  --PASIVO DE INISHORT TOTAL DE VENTAS 
	     
		    SELECT 
								 CUENTA
								,DEBITO
								,CREDITO
								,CENTRO_COSTO
								,COMENTARIO
								
			FROM #PASIVO_INISHORT
			WHERE CREDITO > 0
		   
     
	 UNION ALL

	  --TARJETA(ITBIS Y COMISION)

	       SELECT
	  	       in_cuenta          AS CUENTA,
		       SUM([in_valor])    AS DEBITO,        
			   0                  AS CREDITO,			         
	    	   0                  AS CENTRO_COSTO,		
			   'DEBITO'			  AS COMENTARIO	
			FROM [dbo].[tb_interfase_empresas] I  WITH(NOLOCK)
			WHERE [in_valor] > 0
			AND in_cod_forma_pago IN ('TRJ')
			AND [dbo].[DateOnly]([in_fecha_cont]) = @fecha_corte
			AND in_cod_empresa = @empresa
			GROUP BY in_cuenta

	  UNION ALL

	  --CHEQUE, EFECTIVO, CXC ETC

	    SELECT         
		                  CUENTA
	                     ,DEBITO
			             ,CREDITO
			             ,CENTRO_COSTO
			             ,COMENTARIO
      
	     FROM #CHQ_EFE_CXC_TEMP
	   	
     UNION ALL

	    --ITBIS COBRADO, CXC, INGRESOS

	    SELECT	
		        in_cuenta           AS CUENTA,	  
		        0				    AS DEBITO,     
				SUM([in_valor])*-1  AS CREDITO,					
	    		0                   AS CENTRO_COSTO,    
				'CREDITO'		    AS COMENTARIO 
			FROM [dbo].[tb_interfase_empresas] I WITH(NOLOCK)
			WHERE [in_valor] < 0
			AND [dbo].[DateOnly]([in_fecha_cont]) = @fecha_corte
			AND in_cod_empresa = @empresa
			GROUP BY in_cuenta
			ORDER BY in_cuenta
	
		  OPEN Entrada_contable

			  FETCH NEXT FROM Entrada_contable
			  INTO @cuenta,
				   @_debito_RD,
				   @_credito_RD,
				   @centro_costo,
				   @comentario		
	
				WHILE @@FETCH_STATUS = 0
				BEGIN
					--VALOR EN EL TIEMPO DE LA CUENTA POR COBRAR
					--IF @cuenta = 1121001 and @_debito_RD <> 0
					--	BEGIN
					--		SELECT @_debito_RD = sum([dbo].[saldo_factura_tiempo](fa_numero, fa_fecha,@empresa)) 
					--		FROM tb_factura WITH(NOLOCK) 
					--		WHERE dbo.dateonly(fa_fecha) = @fecha_corte
					--		AND NOT EXISTS
					--		(
					--			--SEGUN EL TIEMPO
					--			SELECT 1 
					--			FROM dbo.tb_reversa_factura WITH(NOLOCK)
					--			WHERE rv_cod_empresa = @empresa
					--			AND [dbo].[DateOnly](rv_fecha) <= @fecha_corte
					--			AND rv_num_factura = fa_numero
					--		)
					--	END 		

	    IF @_debito_RD <> 0
	    	BEGIN 
	    		SET @_debito_US = @_debito_RD / @_venta
	    	END 
	    
	    IF @_credito_RD <> 0 
	    	BEGIN 
	    		SET @_credito_US = @_credito_RD / @_venta
	    	END 
	    					SELECT @cuenta
	    EXEC tl_contabilidad..usp_entrada_diario 
	    @s_user			    = @usuario,
	    @s_term				= @terminal,
	    @i_operacion		= 'D',    
	    @i_uni_neg			= @unidad_neg,
	    @i_tipo				= @tipo,
	    @i_ano				= @anio_detalle,--2011,
	    @i_mes				= @mes_detalle,--1,
	    @i_fecha_con		= @fecha_corte,
	    @i_glosa			= @comentario,
	    @i_tot_debito		= @_debito_RD,
	    @i_tot_credito		= @_credito_RD,
	    @i_tot_dbse			= @_debito_US,
	    @i_tot_cbse			= @_credito_US,
	    @i_moneda			= 1,
	    @i_moneda_bse		= 2,
	    @i_cotizacion		= @_venta,
	    @i_origen			= @origen_entrada,
	    @i_estado			= @estado,              
	    @i_cuenta			= @cuenta,
	    @i_dpto				= @centro_costo,
	    @i_producto			= '-',
	    @i_proyecto			= '-',
	    @i_openitem			= '-',
	    @i_linea			= @cont_linea_entrada,
	    @o_numero			= @num_entrada_contable OUTPUT
	    SELECT @cuenta

		SET @cont_linea_entrada   = @cont_linea_entrada + 1

		SET @_debito_RD  = 0 
		SET @_credito_RD = 0
		SET @_debito_US  = 0
		SET @_credito_US = 0

	    FETCH NEXT FROM Entrada_contable
			INTO @cuenta,
			  @_debito_RD,
			  @_credito_RD,
			  @centro_costo,
			  @comentario		
			END

		CLOSE Entrada_contable		
		DEALLOCATE Entrada_contable
--------------------------------------------------DETALLE ENTRADAS CONTABLES---------------------------------------------

		UPDATE tl_contabilidad..co_det_diario 
		SET de_debito_bse  = ROUND((de_debito/@_venta),4),
			de_credito_bse = ROUND((de_credito/@_venta),4)
		WHERE de_seq = @num_entrada_contable
		AND de_cuenta NOT IN (
							 SELECT cu_cuenta 
							 FROM tl_contabilidad..co_cuenta 
							 WHERE cu_uni_neg = @unidad_neg
							 AND cu_moneda = 2
							 )

		UPDATE tl_contabilidad..co_det_diario 
		SET de_debito_bse  = de_debito,
			de_credito_bse = de_credito
		WHERE de_seq = @num_entrada_contable
		AND de_cuenta IN (
							SELECT cu_cuenta 
							FROM tl_contabilidad..co_cuenta 
							WHERE cu_uni_neg = @unidad_neg
							AND cu_moneda = 2
							AND cu_clase <> 'p'
							 )

		UPDATE tl_contabilidad..co_det_diario 
		SET de_debito_bse  = 0,
			de_credito_bse = 0
		WHERE de_seq = @num_entrada_contable
		AND de_cuenta IN (
							SELECT cu_cuenta 
							FROM tl_contabilidad..co_cuenta 
							WHERE cu_uni_neg = @unidad_neg
							AND cu_moneda = 2
							AND cu_clase = 'p'
							)
									 
									 
		EXEC tl_contabilidad..usp_verifico_entrada_sin_centro_costo
		--
END

--NO BORRAR
--INSERT INTO dbo.tb_parametros_contables_facturas
--   (pf_id_producto,			pf_id_parametro,	pf_cuenta,	pf_cliente_asegurado, 
--	pf_descripcion_cuenta,	pf_aseguradora)

--	select ID, 15, '2131003', 0, '', 0 from db_inventario_new.dbo.vw_Productos where TIPO_INVETARIO like '%PAINT%'
--	and id <> 1827


