/* ============================================================================
   Panel Financiero - Esquema base
   ----------------------------------------------------------------------------
   Base de datos de practica, 100% ficticia. No contiene datos de ninguna
   empresa real.

   Ejecutar:
     sqlcmd -S .\SQLEXPRESS -E -b -f 65001 -i sql\001_esquema.sql
   ============================================================================ */

IF DB_ID(N'PanelFinanciero') IS NULL
BEGIN
    CREATE DATABASE PanelFinanciero;
END;
GO

USE PanelFinanciero;
GO

/* ----------------------------------------------------------------------------
   Cliente
   ---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Cliente', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cliente
    (
        idCliente     INT          IDENTITY(1, 1) NOT NULL,
        rutCliente    VARCHAR(12)  NOT NULL,
        nombreCliente VARCHAR(120) NOT NULL,
        segmento      VARCHAR(20)  NOT NULL,   -- PERSONA / PYME / EMPRESA
        ejecutivo     VARCHAR(80)  NOT NULL,
        email         VARCHAR(120) NOT NULL,
        flgPep        CHAR(1)      NOT NULL CONSTRAINT DF_Cliente_Pep DEFAULT ('N'),
        CONSTRAINT PK_Cliente PRIMARY KEY (idCliente),
        CONSTRAINT UQ_Cliente_Rut UNIQUE (rutCliente)
    );
END;
GO

/* ----------------------------------------------------------------------------
   Cuenta
   ---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Cuenta', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Cuenta
    (
        idCuenta      INT           IDENTITY(1, 1) NOT NULL,
        idCliente     INT           NOT NULL,
        numeroCuenta  VARCHAR(20)   NOT NULL,
        tipoCuenta    VARCHAR(30)   NOT NULL,   -- CORRIENTE / VISTA / INVERSION / AHORRO
        moneda        CHAR(3)       NOT NULL,   -- CLP / USD
        saldo         DECIMAL(18,2) NOT NULL,
        estado        VARCHAR(15)   NOT NULL,   -- ACTIVA / BLOQUEADA / CERRADA
        fechaApertura DATE          NOT NULL,
        CONSTRAINT PK_Cuenta PRIMARY KEY (idCuenta),
        CONSTRAINT UQ_Cuenta_Numero UNIQUE (numeroCuenta),
        CONSTRAINT FK_Cuenta_Cliente FOREIGN KEY (idCliente) REFERENCES dbo.Cliente (idCliente)
    );
END;
GO

/* ----------------------------------------------------------------------------
   Estado de propuesta
   ---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.TipoEstado', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.TipoEstado
    (
        idEstado INT         NOT NULL,
        codigo   VARCHAR(10) NOT NULL,
        nombre   VARCHAR(30) NOT NULL,
        orden    TINYINT     NOT NULL,
        CONSTRAINT PK_TipoEstado PRIMARY KEY (idEstado),
        CONSTRAINT UQ_TipoEstado_Codigo UNIQUE (codigo)
    );
END;
GO

/* ----------------------------------------------------------------------------
   Propuesta de inversion
   ---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Propuesta', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Propuesta
    (
        idPropuesta      INT           IDENTITY(1, 1) NOT NULL,
        idCuenta         INT           NOT NULL,
        idEstado         INT           NOT NULL,
        tipoProducto     VARCHAR(40)   NOT NULL,
        monto            DECIMAL(18,2) NOT NULL,
        plazoDias        INT           NOT NULL,
        tasaAnual        DECIMAL(6,3)  NOT NULL,
        observacion      VARCHAR(300)  NULL,
        asesor           VARCHAR(80)   NOT NULL,
        fechaSolicitud   DATETIME2(0)  NOT NULL,
        fechaResolucion  DATETIME2(0)  NULL,
        usuarioResolucion VARCHAR(40)  NULL,
        CONSTRAINT PK_Propuesta PRIMARY KEY (idPropuesta),
        CONSTRAINT FK_Propuesta_Cuenta FOREIGN KEY (idCuenta) REFERENCES dbo.Cuenta (idCuenta),
        CONSTRAINT FK_Propuesta_Estado FOREIGN KEY (idEstado) REFERENCES dbo.TipoEstado (idEstado)
    );

    CREATE INDEX IX_Propuesta_FechaEstado
        ON dbo.Propuesta (fechaSolicitud DESC, idEstado)
        INCLUDE (idCuenta, monto);
END;
GO

/* ----------------------------------------------------------------------------
   Movimiento de cuenta
   ---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.Movimiento', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Movimiento
    (
        idMovimiento BIGINT        IDENTITY(1, 1) NOT NULL,
        idCuenta     INT           NOT NULL,
        fecha        DATETIME2(0)  NOT NULL,
        tipo         CHAR(1)       NOT NULL,   -- C = credito, D = debito
        concepto     VARCHAR(80)   NOT NULL,
        monto        DECIMAL(18,2) NOT NULL,
        referencia   VARCHAR(30)   NOT NULL,
        CONSTRAINT PK_Movimiento PRIMARY KEY (idMovimiento),
        CONSTRAINT FK_Movimiento_Cuenta FOREIGN KEY (idCuenta) REFERENCES dbo.Cuenta (idCuenta),
        CONSTRAINT CK_Movimiento_Tipo CHECK (tipo IN ('C', 'D')),
        CONSTRAINT CK_Movimiento_Monto CHECK (monto > 0)
    );

    CREATE INDEX IX_Movimiento_Fecha ON dbo.Movimiento (fecha DESC, idCuenta);
END;
GO

/* ----------------------------------------------------------------------------
   Auditoria de acciones sobre propuestas
   ---------------------------------------------------------------------------- */
IF OBJECT_ID(N'dbo.AuditoriaPropuesta', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.AuditoriaPropuesta
    (
        idAuditoria    BIGINT       IDENTITY(1, 1) NOT NULL,
        idPropuesta    INT          NOT NULL,
        accion         VARCHAR(10)  NOT NULL,   -- APROBAR / RECHAZAR
        estadoAnterior VARCHAR(30)  NOT NULL,
        estadoNuevo    VARCHAR(30)  NOT NULL,
        usuario        VARCHAR(40)  NOT NULL,
        comentario     VARCHAR(300) NULL,
        fecha          DATETIME2(0) NOT NULL CONSTRAINT DF_Auditoria_Fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_AuditoriaPropuesta PRIMARY KEY (idAuditoria),
        CONSTRAINT FK_Auditoria_Propuesta FOREIGN KEY (idPropuesta) REFERENCES dbo.Propuesta (idPropuesta)
    );
END;
GO

/* ----------------------------------------------------------------------------
   Vista de lectura: propuesta + cuenta + cliente + estado.
   La API consulta esta vista para no repetir el JOIN en cada endpoint.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vwPropuestaDetalle
AS
SELECT
    p.idPropuesta,
    p.idCuenta,
    p.idEstado,
    e.codigo        AS codigoEstado,
    e.nombre        AS estado,
    c.idCliente,
    c.rutCliente,
    c.nombreCliente,
    c.segmento,
    c.ejecutivo,
    c.email         AS emailCliente,
    c.flgPep,
    cu.numeroCuenta,
    cu.tipoCuenta,
    cu.moneda,
    cu.saldo        AS saldoCuenta,
    cu.estado       AS estadoCuenta,
    p.tipoProducto,
    p.monto,
    /* Equivalente en CLP con tipo de cambio fijo solo para totales del demo. */
    CAST(CASE WHEN cu.moneda = 'USD' THEN p.monto * 950 ELSE p.monto END AS DECIMAL(18,2)) AS montoClp,
    p.plazoDias,
    p.tasaAnual,
    p.observacion,
    p.asesor,
    p.fechaSolicitud,
    p.fechaResolucion,
    p.usuarioResolucion
FROM dbo.Propuesta AS p
INNER JOIN dbo.Cuenta AS cu ON cu.idCuenta = p.idCuenta
INNER JOIN dbo.Cliente AS c ON c.idCliente = cu.idCliente
INNER JOIN dbo.TipoEstado AS e ON e.idEstado = p.idEstado;
GO

/* ----------------------------------------------------------------------------
   Vista de lectura: movimiento + cuenta + cliente.
   Igual que la vista de propuestas, evita repetir el JOIN en la API.
   ---------------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.vwOperacionDetalle
AS
SELECT
    m.idMovimiento,
    m.idCuenta,
    cu.numeroCuenta,
    cu.tipoCuenta,
    cu.moneda,
    cu.idCliente,
    c.rutCliente,
    c.nombreCliente,
    c.segmento,
    m.fecha,
    m.tipo,
    m.concepto,
    m.monto,
    /* Equivalente en CLP con tipo de cambio fijo solo para totales del demo. */
    CAST(CASE WHEN cu.moneda = 'USD' THEN m.monto * 950 ELSE m.monto END AS DECIMAL(18,2)) AS montoClp,
    m.referencia
FROM dbo.Movimiento AS m
INNER JOIN dbo.Cuenta AS cu ON cu.idCuenta = m.idCuenta
INNER JOIN dbo.Cliente AS c ON c.idCliente = cu.idCliente;
GO
