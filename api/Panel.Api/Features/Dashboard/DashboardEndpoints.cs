using Dapper;
using Panel.Api.Data;
using Panel.Api.Features.Propuestas;

namespace Panel.Api.Features.Dashboard;

public sealed class DashboardDto
{
    public decimal SaldoTotal { get; init; }
    public int CuentasActivas { get; init; }
    public int PropuestasPendientes { get; init; }
    public decimal MontoPendiente { get; init; }
    public int MovimientosHoy { get; init; }
    public decimal MontoMovimientosHoy { get; init; }
    public IReadOnlyList<SerieDiaDto> Serie { get; init; } = [];
    public IReadOnlyList<EstadoResumenDto> PorEstado { get; init; } = [];
    public IReadOnlyList<PropuestaDto> Ultimas { get; init; } = [];
}

public sealed class SerieDiaDto
{
    public DateTime Fecha { get; init; }
    public int Cantidad { get; init; }
    public decimal Monto { get; init; }
}

public sealed class EstadoResumenDto
{
    public string Codigo { get; init; } = string.Empty;
    public string Estado { get; init; } = string.Empty;
    public int Cantidad { get; init; }
    public decimal Monto { get; init; }
}

public static class DashboardEndpoints
{
    public static IEndpointRouteBuilder MapDashboardEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapGet("/api/dashboard", ObtenerAsync)
            .WithTags("Dashboard")
            .WithName("ObtenerDashboard")
            .WithSummary("KPIs, serie de 7 dias, distribucion por estado y ultimas propuestas")
            .Produces<DashboardDto>(StatusCodes.Status200OK);

        return app;
    }

    private static async Task<IResult> ObtenerAsync(
        IDbConnectionFactory bd,
        CancellationToken cancelacion)
    {
        const string resumenSql = """
            SELECT
                CAST(ISNULL((SELECT SUM(CASE WHEN moneda = 'USD' THEN saldo * 950 ELSE saldo END)
                             FROM dbo.Cuenta
                             WHERE estado = 'ACTIVA'), 0) AS DECIMAL(18,2)) AS saldoTotal,
                (SELECT COUNT(*) FROM dbo.Cuenta WHERE estado = 'ACTIVA') AS cuentasActivas,
                (SELECT COUNT(*)
                 FROM dbo.Propuesta AS p
                 INNER JOIN dbo.TipoEstado AS e ON e.idEstado = p.idEstado
                 WHERE e.codigo = 'PEND') AS propuestasPendientes,
                CAST(ISNULL((SELECT SUM(montoClp)
                             FROM dbo.vwPropuestaDetalle
                             WHERE codigoEstado = 'PEND'), 0) AS DECIMAL(18,2)) AS montoPendiente,
                (SELECT COUNT(*)
                 FROM dbo.Movimiento
                 WHERE fecha >= CAST(GETDATE() AS DATE)) AS movimientosHoy,
                CAST(ISNULL((SELECT SUM(CASE WHEN c.moneda = 'USD' THEN m.monto * 950 ELSE m.monto END)
                             FROM dbo.Movimiento AS m
                             INNER JOIN dbo.Cuenta AS c ON c.idCuenta = m.idCuenta
                             WHERE m.fecha >= CAST(GETDATE() AS DATE)), 0) AS DECIMAL(18,2)) AS montoMovimientosHoy;
            """;

        const string serieSql = """
            WITH dias AS (
                SELECT 0 AS n
                UNION ALL
                SELECT n + 1 FROM dias WHERE n < 6
            )
            SELECT
                CAST(DATEADD(DAY, -d.n, CAST(GETDATE() AS DATE)) AS DATETIME2(0)) AS fecha,
                COUNT(v.idPropuesta) AS cantidad,
                CAST(ISNULL(SUM(v.montoClp), 0) AS DECIMAL(18,2)) AS monto
            FROM dias AS d
            LEFT JOIN dbo.vwPropuestaDetalle AS v
                ON CAST(v.fechaSolicitud AS DATE) = DATEADD(DAY, -d.n, CAST(GETDATE() AS DATE))
            GROUP BY d.n
            ORDER BY d.n DESC;
            """;

        const string porEstadoSql = """
            SELECT
                e.codigo,
                e.nombre AS estado,
                COUNT(v.idPropuesta) AS cantidad,
                CAST(ISNULL(SUM(v.montoClp), 0) AS DECIMAL(18,2)) AS monto
            FROM dbo.TipoEstado AS e
            LEFT JOIN dbo.vwPropuestaDetalle AS v ON v.codigoEstado = e.codigo
            GROUP BY e.codigo, e.nombre, e.orden
            ORDER BY e.orden;
            """;

        const string ultimasSql = """
            SELECT TOP (6) *
            FROM dbo.vwPropuestaDetalle
            ORDER BY fechaSolicitud DESC, idPropuesta DESC;
            """;

        using var conexion = bd.Crear();
        using var multi = await conexion.QueryMultipleAsync(
            new CommandDefinition(
                $"{resumenSql}\n{serieSql}\n{porEstadoSql}\n{ultimasSql}",
                cancellationToken: cancelacion));

        var resumen = await multi.ReadSingleAsync<DashboardDto>();
        var serie = (await multi.ReadAsync<SerieDiaDto>()).AsList();
        var porEstado = (await multi.ReadAsync<EstadoResumenDto>()).AsList();
        var ultimas = (await multi.ReadAsync<PropuestaDto>()).AsList();

        return Results.Ok(new DashboardDto
        {
            SaldoTotal = resumen.SaldoTotal,
            CuentasActivas = resumen.CuentasActivas,
            PropuestasPendientes = resumen.PropuestasPendientes,
            MontoPendiente = resumen.MontoPendiente,
            MovimientosHoy = resumen.MovimientosHoy,
            MontoMovimientosHoy = resumen.MontoMovimientosHoy,
            Serie = serie,
            PorEstado = porEstado,
            Ultimas = ultimas
        });
    }
}
