/* ============================================================================
   Panel Financiero - Datos de prueba
   ----------------------------------------------------------------------------
   Genera datos ficticios y deterministas. Se puede ejecutar varias veces:
   borra los datos anteriores (no el esquema) y vuelve a cargar.

   Usa IDs explicitos (IDENTITY_INSERT) para que los resultados sean siempre
   los mismos, aunque la identidad de las tablas haya quedado desfasada.

   Ejecutar:
     sqlcmd -S .\SQLEXPRESS -E -b -f 65001 -i sql\002_datos_prueba.sql
   ============================================================================ */

USE PanelFinanciero;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DELETE FROM dbo.AuditoriaPropuesta;
DELETE FROM dbo.Movimiento;
DELETE FROM dbo.Propuesta;
DELETE FROM dbo.Cuenta;
DELETE FROM dbo.Cliente;
DELETE FROM dbo.TipoEstado;

/* ----------------------------------------------------------------------------
   Estados de propuesta
   ---------------------------------------------------------------------------- */
INSERT dbo.TipoEstado (idEstado, codigo, nombre, orden) VALUES
    (1, 'PEND', 'Pendiente',   1),
    (2, 'APRO', 'Aprobada',    2),
    (3, 'RECH', 'Rechazada',   3),
    (4, 'ANUL', 'Anulada',     4),
    (5, 'REVI', 'En revisión', 5);

/* ----------------------------------------------------------------------------
   Clientes (24)
   ---------------------------------------------------------------------------- */
SET IDENTITY_INSERT dbo.Cliente ON;

INSERT dbo.Cliente (idCliente, rutCliente, nombreCliente, segmento, ejecutivo, email, flgPep) VALUES
    (1,  '12.345.678-9', 'CARLOS MENDOZA RIQUELME',  'PERSONA', 'VALERIA DIAZ',   'carlos.mendoza@correo.cl',   'N'),
    (2,  '9.876.543-2',  'ANA MARIA SOTO VEGA',      'PERSONA', 'ROBERTO SILVA',  'ana.soto@correo.cl',         'N'),
    (3,  '16.432.987-5', 'MARIA GONZALEZ PEREZ',     'PERSONA', 'PAULA ROJAS',    'maria.gonzalez@correo.cl',   'N'),
    (4,  '7.654.321-8',  'PEDRO ALVAREZ MUNOZ',      'PERSONA', 'DIEGO PEREZ',    'pedro.alvarez@correo.cl',    'N'),
    (5,  '76.111.222-3', 'EMPRESAS ANDINAS SPA',     'EMPRESA', 'CAMILA REYES',   'tesoreria@andinas.cl',       'N'),
    (6,  '10.111.222-3', 'JUAN PABLO LOPEZ FUENTES', 'PERSONA', 'VALERIA DIAZ',   'juan.lopez@correo.cl',       'N'),
    (7,  '15.222.333-4', 'SOFIA TORRES DIAZ',        'PYME',    'ROBERTO SILVA',  'sofia.torres@correo.cl',     'S'),
    (8,  '76.444.555-6', 'INVERSIONES DEL SUR LTDA', 'EMPRESA', 'PAULA ROJAS',    'finanzas@delsur.cl',         'N'),
    (9,  '8.888.777-6',  'ROBERTO SILVA CASTILLO',   'PERSONA', 'DIEGO PEREZ',    'roberto.silva@correo.cl',    'N'),
    (10, '17.333.444-5', 'CAMILA REYES MORALES',     'PYME',    'CAMILA REYES',   'camila.reyes@correo.cl',     'N'),
    (11, '11.222.333-4', 'DIEGO PEREZ SANTOS',       'PERSONA', 'VALERIA DIAZ',   'diego.perez@correo.cl',      'N'),
    (12, '13.555.666-7', 'VALERIA DIAZ ROJAS',       'PYME',    'ROBERTO SILVA',  'valeria.diaz@correo.cl',     'N'),
    (13, '6.777.888-9',  'FERNANDO ROJAS LIRA',      'PERSONA', 'PAULA ROJAS',    'fernando.rojas@correo.cl',   'N'),
    (14, '77.222.333-4', 'CONSTRUCTORA MIRADOR SA',  'EMPRESA', 'DIEGO PEREZ',    'pagos@mirador.cl',           'N'),
    (15, '14.888.999-0', 'PAULA CONTRERAS NUNEZ',    'PERSONA', 'CAMILA REYES',   'paula.contreras@correo.cl',  'N'),
    (16, '19.111.222-3', 'ANDRES MUNOZ GALLARDO',    'PYME',    'VALERIA DIAZ',   'andres.munoz@correo.cl',     'S'),
    (17, '78.333.444-5', 'TECNOLOGIA AUSTRAL SPA',   'EMPRESA', 'ROBERTO SILVA',  'admin@austral.cl',           'N'),
    (18, '18.555.666-7', 'CAROLINA ESPINOZA RIOS',   'PERSONA', 'PAULA ROJAS',    'carolina.espinoza@correo.cl', 'N'),
    (19, '20.777.888-9', 'SEBASTIAN VARGAS TAPIA',   'PYME',    'DIEGO PEREZ',    'sebastian.vargas@correo.cl',  'N'),
    (20, '79.111.000-1', 'COMERCIAL PACIFICO LTDA',  'EMPRESA', 'CAMILA REYES',   'compras@pacifico.cl',        'N'),
    (21, '21.222.333-4', 'NATALIA HERRERA PINTO',    'PERSONA', 'VALERIA DIAZ',   'natalia.herrera@correo.cl',  'N'),
    (22, '22.444.555-6', 'MATIAS FUENTES ARAYA',     'PYME',    'ROBERTO SILVA',  'matias.fuentes@correo.cl',   'N'),
    (23, '80.555.666-7', 'AGRICOLA LOS ROBLES SPA',  'EMPRESA', 'PAULA ROJAS',    'contabilidad@robles.cl',     'N'),
    (24, '23.777.888-9', 'ISABEL CORTES MEZA',       'PERSONA', 'DIEGO PEREZ',    'isabel.cortes@correo.cl',    'N');

SET IDENTITY_INSERT dbo.Cliente OFF;

/* ----------------------------------------------------------------------------
   Cuentas (40)
   ---------------------------------------------------------------------------- */
SET IDENTITY_INSERT dbo.Cuenta ON;

;WITH n AS (
    SELECT TOP (40) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects
)
INSERT dbo.Cuenta (idCuenta, idCliente, numeroCuenta, tipoCuenta, moneda, saldo, estado, fechaApertura)
SELECT
    i,
    ((i - 1) % 24) + 1,
    CONCAT('CTA-', RIGHT('0000' + CAST(i AS VARCHAR(4)), 4)),
    CHOOSE((i % 4) + 1, 'CORRIENTE', 'VISTA', 'INVERSION', 'AHORRO'),
    CASE WHEN i % 7 = 0 THEN 'USD' ELSE 'CLP' END,
    CAST(CASE WHEN i % 7 = 0
              THEN 1500 + (i * 731) % 45000
              ELSE 1200000 + (i * 987654) % 38000000
         END AS DECIMAL(18,2)),
    CASE WHEN i % 13 = 0 THEN 'BLOQUEADA'
         WHEN i % 17 = 0 THEN 'CERRADA'
         ELSE 'ACTIVA' END,
    DATEADD(DAY, -((i * 97) % 2000), CAST(GETDATE() AS DATE))
FROM n;

SET IDENTITY_INSERT dbo.Cuenta OFF;

/* ----------------------------------------------------------------------------
   Propuestas (600, distribuidas en los ultimos 120 dias)
   ---------------------------------------------------------------------------- */
SET IDENTITY_INSERT dbo.Propuesta ON;

;WITH n AS (
    SELECT TOP (600) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects
),
base AS (
    SELECT
        i,
        (i - 1) % 120 AS dia,
        (i - 1) / 120 AS slot,
        /* Se combinan dia y slot para que las 5 propuestas de un mismo dia
           tengan clientes, productos y estados distintos. */
        (((i - 1) % 120) * 13 + ((i - 1) / 120) * 7) % 40 + 1 AS idCuenta,
        CASE
            WHEN (((i - 1) % 120) * 37 + ((i - 1) / 120) * 11) % 100 < 42 THEN 1
            WHEN (((i - 1) % 120) * 37 + ((i - 1) / 120) * 11) % 100 < 72 THEN 2
            WHEN (((i - 1) % 120) * 37 + ((i - 1) / 120) * 11) % 100 < 86 THEN 3
            WHEN (((i - 1) % 120) * 37 + ((i - 1) / 120) * 11) % 100 < 96 THEN 4
            ELSE 5
        END AS idEstado,
        DATEADD(
            MINUTE,
            (i * 37) % 600,
            CAST(DATEADD(DAY, -((i - 1) % 120), CAST(GETDATE() AS DATE)) AS DATETIME2(0))
        ) AS fechaSolicitud
    FROM n
)
INSERT dbo.Propuesta
    (idPropuesta, idCuenta, idEstado, tipoProducto, monto, plazoDias, tasaAnual, observacion,
     asesor, fechaSolicitud, fechaResolucion, usuarioResolucion)
SELECT
    b.i,
    b.idCuenta,
    b.idEstado,
    CHOOSE((b.dia + b.slot * 3) % 4 + 1, 'ACCIONES', 'FONDOS_MUTUOS', 'RENTA_FIJA', 'DEPOSITO_PLAZO'),
    CAST((500000 + ((b.dia * 37 + b.slot * 19) % 60) * 250000)
         / CASE WHEN cu.moneda = 'USD' THEN 900.0 ELSE 1 END AS DECIMAL(18,2)),
    CHOOSE((b.dia + b.slot) % 3 + 1, 30, 90, 180),
    CAST(3.5 + (b.i % 45) * 0.1 AS DECIMAL(6,3)),
    CASE
        WHEN b.idEstado = 1 THEN 'Pendiente de revisión por mesa de dinero'
        WHEN b.idEstado = 3 THEN 'No cumple el perfil de riesgo del cliente'
        WHEN b.idEstado = 4 THEN 'Anulada por solicitud del cliente'
        ELSE NULL
    END,
    CHOOSE((b.dia + b.slot * 2) % 5 + 1, 'VALERIA DIAZ', 'ROBERTO SILVA', 'PAULA ROJAS', 'DIEGO PEREZ', 'CAMILA REYES'),
    b.fechaSolicitud,
    CASE
        WHEN b.idEstado <> 1 AND DATEDIFF(DAY, b.fechaSolicitud, GETDATE()) >= 1
        THEN DATEADD(HOUR, 2 + (b.i % 30), b.fechaSolicitud)
    END,
    CASE
        WHEN b.idEstado <> 1 AND DATEDIFF(DAY, b.fechaSolicitud, GETDATE()) >= 1
        THEN 'analista.demo'
    END
FROM base AS b
INNER JOIN dbo.Cuenta AS cu ON cu.idCuenta = b.idCuenta;

SET IDENTITY_INSERT dbo.Propuesta OFF;

/* ----------------------------------------------------------------------------
   Movimientos (2000, ultimos 90 dias)
   ---------------------------------------------------------------------------- */
SET IDENTITY_INSERT dbo.Movimiento ON;

;WITH n AS (
    SELECT TOP (2000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
    FROM sys.all_objects
)
INSERT dbo.Movimiento (idMovimiento, idCuenta, fecha, tipo, concepto, monto, referencia)
SELECT
    i,
    ((i - 1) % 40) + 1,
    DATEADD(
        MINUTE,
        (i * 53) % 1440,
        CAST(DATEADD(DAY, -(i % 90), CAST(GETDATE() AS DATE)) AS DATETIME2(0))
    ),
    CASE WHEN i % 3 = 0 THEN 'C' ELSE 'D' END,
    CHOOSE((i % 8) + 1,
        'Transferencia recibida',
        'Pago de proveedor',
        'Compra de instrumento',
        'Rescate de fondo',
        'Dividendo',
        'Comision mensual',
        'Deposito en efectivo',
        'Transferencia enviada'),
    CAST(50000 + ((i * 7717) % 1950000) AS DECIMAL(18,2)),
    CONCAT('REF-', RIGHT('000000' + CAST(i AS VARCHAR(6)), 6))
FROM n;

SET IDENTITY_INSERT dbo.Movimiento OFF;

/* Deja la identidad en el maximo actual para futuras inserciones. */
DBCC CHECKIDENT ('dbo.Cliente', RESEED) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Cuenta', RESEED) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Propuesta', RESEED) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.Movimiento', RESEED) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.AuditoriaPropuesta', RESEED, 0) WITH NO_INFOMSGS;

COMMIT TRANSACTION;
GO

PRINT 'Datos de prueba cargados.';
