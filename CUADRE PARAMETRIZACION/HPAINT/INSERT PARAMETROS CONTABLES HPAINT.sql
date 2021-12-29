--SELECT * FROM db_facturacion..tb_parametros_contables_pagos P ORDER BY P.pp_id_empresa, pp_id_param

INSERT INTO db_facturacion..tb_parametros_contables_pagos
(pp_cuenta, pp_descripcion_cta,                         pp_fecha, pp_id_empresa, pp_id_param)

VALUES
('1121001','CTAS X COBRAR CLIENTES',                         GETDATE(),  3,                 1),
('1142005','ITBIS RETENIDO CARDNET',                         GETDATE(),  3,                 2),
('5800004','COMISIONES CARDNET',                             GETDATE(),  3,                 3),														     
('1112003','PRIMA CTA AHORRO US$',                           GETDATE(),  3,                 6),
('4900001','DESC. POR N/C SERV.DEL PINTADO',                 GETDATE(),  3,                 7), 
('2141006','AVANCES DE CLIENTES',                            GETDATE(),  3,                 8),
('2131003','ITBIS COBRADO',                                  GETDATE(),  3,                 10),
('2141005','DEPOSITOS EN CTAS. BCO. NO IDENTIFICADOS',       GETDATE(),  3,                 14)





