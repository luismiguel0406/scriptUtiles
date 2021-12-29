--SELECT * FROM db_facturacion..tb_parametros_contables_pagos P ORDER BY P.pp_id_empresa, pp_id_param

INSERT INTO db_facturacion..tb_parametros_contables_pagos
(pp_cuenta, pp_descripcion_cta,                         pp_fecha, pp_id_empresa, pp_id_param)

VALUES
('1121001','CTAS X COBRAR CLIENTES',                         GETDATE(),  2,                 1),
('1142005','ITBIS RETENIDO CARDNET',                         GETDATE(),  2,                 2),
('5800004','COMISIONES CARDNET',                             GETDATE(),  2,                 3),														     
('1112003','PRIMA CTA AHORRO US$',                           GETDATE(),  2,                 6),
('4900002','DESC. POR  N/C A  FACT. EN SERV. DE SEGURIDAD',  GETDATE(),  2,                 7), 
('2141004','INSTALACIONES PENDIENTES / PAGOS ANTICIPADOS',   GETDATE(),  2,                 8),
('2131003','ITBIS COBRADO',                                  GETDATE(),  2,                 10),
('2141005','DEPOSITOS EN CTAS. BCO. NO IDENTIFICADOS',       GETDATE(),  2,                 14)


SELECT * FROM tl_contabilidad..co_cuenta  C WHERE C.cu_cuenta
IN (
'1111005',
'1121001',
'1142011',
'2131003',
'2141004',
'4100001',
'4900002')
AND C.cu_uni_neg = 'HSI'

