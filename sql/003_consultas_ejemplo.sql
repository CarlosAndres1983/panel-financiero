/* ============================================================================
   Panel Financiero - Consultas de ejemplo y ejercicios
   ----------------------------------------------------------------------------
   Ejecutar en SSMS / Azure Data Studio sobre la base PanelFinanciero, o:
     sqlcmd -S .\SQLEXPRESS -E -d PanelFinanciero -i sql\003_consultas_ejemplo.sql

   La vista dbo.vwPropuestaDetalle trae propuesta + cuenta + cliente + estado.
   La columna montoClp convierte USD a CLP con un tipo de cambio fijo de demo
   (1 USD = 950 CLP). En un sistema real el tipo de cambio se parametriza.
   ============================================================================ */

USE PanelFinanciero;
GO
SET NOCOUNT ON;

/* ----------------------------------------------------------------------------
   1) Resumen por estado: cantidad, monto y porcentaje sobre el total.
      Usa una funcion de ventana sobre una agregacion.
   ---------------------------------------------------------------------------- */
SELECT
    codigoEstado,
    estado,
    COUNT(*) AS cantidad,
    CAST(SUM(montoClp) AS DECIMAL(18, 0)) AS monto_clp,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5, 2)) AS pct_cantidad
FROM dbo.vwPropuestaDetalle
GROUP BY codigoEstado, estado
ORDER BY cantidad DESC;
GO

/* ----------------------------------------------------------------------------
   2) Top 10 clientes por monto propuesto.
   ---------------------------------------------------------------------------- */
SELECT TOP (10)
    nombreCliente,
    rutCliente,
    segmento,
    COUNT(*) AS propuestas,
    CAST(SUM(montoClp) AS DECIMAL(18, 0)) AS monto_total_clp,
    CAST(AVG(montoClp) AS DECIMAL(18, 0)) AS ticket_promedio_clp
FROM dbo.vwPropuestaDetalle
GROUP BY nombreCliente, rutCliente, segmento
ORDER BY monto_total_clp DESC;
GO

/* ----------------------------------------------------------------------------
   3) Bandeja pendiente por asesor, con antiguedad de la mas vieja.
   ---------------------------------------------------------------------------- */
SELECT
    asesor,
    COUNT(*) AS pendientes,
    CAST(SUM(montoClp) AS DECIMAL(18, 0)) AS monto_clp,
    MIN(fechaSolicitud) AS solicitud_mas_antigua,
    MAX(DATEDIFF(DAY, fechaSolicitud, GETDATE())) AS dias_maximos_esperando
FROM dbo.vwPropuestaDetalle
WHERE codigoEstado = 'PEND'
GROUP BY asesor
ORDER BY monto_clp DESC;
GO

/* ----------------------------------------------------------------------------
   4) Serie diaria de los ultimos 30 dias (incluye dias sin propuestas)
      y monto acumulado con SUM() OVER.
   ---------------------------------------------------------------------------- */
WITH dias AS (
    SELECT 0 AS n
    UNION ALL
    SELECT n + 1 FROM dias WHERE n < 29
),
serie AS (
    SELECT
        CAST(DATEADD(DAY, -d.n, CAST(GETDATE() AS DATE)) AS DATE) AS fecha,
        COUNT(v.idPropuesta) AS cantidad,
        CAST(ISNULL(SUM(v.montoClp), 0) AS DECIMAL(18, 2)) AS monto
    FROM dias AS d
    LEFT JOIN dbo.vwPropuestaDetalle AS v
        ON CAST(v.fechaSolicitud AS DATE) = DATEADD(DAY, -d.n, CAST(GETDATE() AS DATE))
    GROUP BY d.n
)
SELECT
    fecha,
    cantidad,
    monto,
    CAST(SUM(monto) OVER (ORDER BY fecha ROWS UNBOUNDED PRECEDING) AS DECIMAL(18, 2)) AS acumulado
FROM serie
ORDER BY fecha;
GO

/* ----------------------------------------------------------------------------
   5) Las 3 propuestas mas grandes de cada ejecutivo (ranking con ROW_NUMBER).
   ---------------------------------------------------------------------------- */
WITH ranking AS (
    SELECT
        idPropuesta,
        nombreCliente,
        ejecutivo,
        tipoProducto,
        montoClp,
        ROW_NUMBER() OVER (PARTITION BY ejecutivo ORDER BY montoClp DESC) AS posicion
    FROM dbo.vwPropuestaDetalle
    WHERE fechaSolicitud >= DATEADD(DAY, -30, GETDATE())
)
SELECT *
FROM ranking
WHERE posicion <= 3
ORDER BY ejecutivo, posicion;
GO

/* ----------------------------------------------------------------------------
   6) Mediana del monto por producto (PERCENTILE_CONT es una funcion de ventana).
   ---------------------------------------------------------------------------- */
SELECT DISTINCT
    tipoProducto,
    COUNT(*) OVER (PARTITION BY tipoProducto) AS propuestas,
    CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY montoClp)
        OVER (PARTITION BY tipoProducto) AS DECIMAL(18, 0)) AS mediana_clp
FROM dbo.vwPropuestaDetalle
ORDER BY tipoProducto;
GO

/* ----------------------------------------------------------------------------
   7) Movimientos netos por mes: creditos menos debitos.
   ---------------------------------------------------------------------------- */
SELECT
    FORMAT(fecha, 'yyyy-MM') AS mes,
    SUM(CASE WHEN tipo = 'C' THEN monto ELSE 0 END) AS creditos,
    SUM(CASE WHEN tipo = 'D' THEN monto ELSE 0 END) AS debitos,
    SUM(CASE WHEN tipo = 'C' THEN monto ELSE -monto END) AS neto
FROM dbo.Movimiento
GROUP BY FORMAT(fecha, 'yyyy-MM')
ORDER BY mes;
GO

/* ----------------------------------------------------------------------------
   8) Posibles duplicados: misma cuenta, producto y monto dentro de 7 dias.
      LAG() mira la fila anterior del mismo grupo.
   ---------------------------------------------------------------------------- */
WITH ordenado AS (
    SELECT
        idPropuesta,
        idCuenta,
        tipoProducto,
        monto,
        fechaSolicitud,
        LAG(fechaSolicitud) OVER (
            PARTITION BY idCuenta, tipoProducto, monto
            ORDER BY fechaSolicitud
        ) AS fecha_anterior
    FROM dbo.Propuesta
)
SELECT
    idPropuesta,
    idCuenta,
    tipoProducto,
    monto,
    fecha_anterior,
    fechaSolicitud,
    DATEDIFF(DAY, fecha_anterior, fechaSolicitud) AS dias_entre_ambas
FROM ordenado
WHERE fecha_anterior IS NOT NULL
  AND DATEDIFF(DAY, fecha_anterior, fechaSolicitud) <= 7
ORDER BY idCuenta, fechaSolicitud;
GO

/* ----------------------------------------------------------------------------
   9) Tiempo promedio de resolucion por estado (solo propuestas resueltas).
   ---------------------------------------------------------------------------- */
SELECT
    estado,
    COUNT(*) AS resueltas,
    CAST(AVG(DATEDIFF(HOUR, fechaSolicitud, fechaResolucion) * 1.0) AS DECIMAL(10, 2)) AS horas_promedio,
    MIN(fechaResolucion) AS primera_resolucion,
    MAX(fechaResolucion) AS ultima_resolucion
FROM dbo.vwPropuestaDetalle
WHERE fechaResolucion IS NOT NULL
GROUP BY estado
ORDER BY horas_promedio;
GO

/* ----------------------------------------------------------------------------
   10) Cuentas con saldo sobre el promedio y al menos una propuesta pendiente.
       Combina CTE, agregacion y HAVING.
   ---------------------------------------------------------------------------- */
WITH resumen AS (
    SELECT
        idCuenta,
        numeroCuenta,
        nombreCliente,
        moneda,
        saldoCuenta,
        SUM(CASE WHEN codigoEstado = 'PEND' THEN 1 ELSE 0 END) AS pendientes,
        CAST(SUM(montoClp) AS DECIMAL(18, 0)) AS monto_pendiente_clp
    FROM dbo.vwPropuestaDetalle
    GROUP BY idCuenta, numeroCuenta, nombreCliente, moneda, saldoCuenta
)
SELECT *
FROM resumen
WHERE pendientes > 0
  AND saldoCuenta > (SELECT AVG(saldo) FROM dbo.Cuenta)
ORDER BY saldoCuenta DESC;
GO

/* ----------------------------------------------------------------------------
   11) Ejercicio de rendimiento: compara lecturas logicas antes/despues de
       agregar un indice. Descomenta y revisa la pestaña Messages.

   SET STATISTICS IO ON;

   SELECT idPropuesta, monto FROM dbo.Propuesta
   WHERE fechaSolicitud >= DATEADD(DAY, -7, GETDATE())
     AND idEstado = 1;

   SET STATISTICS IO OFF;
   ---------------------------------------------------------------------------- */

/* ----------------------------------------------------------------------------
   12) Inventario de indices de las tablas del demo.
   ---------------------------------------------------------------------------- */
SELECT
    OBJECT_NAME(i.object_id) AS tabla,
    i.name AS indice,
    i.type_desc AS tipo,
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns AS ic
        INNER JOIN sys.columns AS c
            ON c.object_id = ic.object_id AND c.column_id = ic.column_id
        WHERE ic.object_id = i.object_id
          AND ic.index_id = i.index_id
          AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') AS columnas_clave
FROM sys.indexes AS i
WHERE i.object_id IN (
    OBJECT_ID('dbo.Propuesta'),
    OBJECT_ID('dbo.Movimiento'),
    OBJECT_ID('dbo.Cuenta')
)
AND i.name IS NOT NULL
ORDER BY tabla, indice;
GO
