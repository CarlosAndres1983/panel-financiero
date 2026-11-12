using Dapper;
using Panel.Api.Comun;
using Panel.Api.Data;

namespace Panel.Api.Features.Operaciones;

public static class OperacionesEndpoints
{
    public static IEndpointRouteBuilder MapOperacionesEndpoints(this IEndpointRouteBuilder app)
    {
        var grupo = app.MapGroup("/api/operaciones").WithTags("Operaciones");

        grupo.MapGet("", BuscarAsync)
            .WithName("BuscarOperaciones")
            .WithSummary("Consulta paginada de movimientos por fecha, tipo y texto")
            .Produces<PaginaOperacionesDto>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest);

        return app;
    }

    private static async Task<IResult> BuscarAsync(
        string? fechaDesde,
        string? fechaHasta,
        string? tipo,
        string? texto,
        int? pagina,
        int? tamano,
        IDbConnectionFactory bd,
        CancellationToken cancelacion)
    {
        var hasta = DateTime.Today;
        var desde = hasta.AddDays(-30);

        if (!string.IsNullOrWhiteSpace(fechaDesde) && !Fechas.TryParse(fechaDesde, out desde))
        {
            return Results.BadRequest(new { message = "La fecha desde no es válida (formato yyyy-MM-dd)." });
        }

        if (!string.IsNullOrWhiteSpace(fechaHasta) && !Fechas.TryParse(fechaHasta, out hasta))
        {
            return Results.BadRequest(new { message = "La fecha hasta no es válida (formato yyyy-MM-dd)." });
        }

        if (desde > hasta)
        {
            return Results.BadRequest(new { message = "La fecha desde no puede ser mayor que la fecha hasta." });
        }

        var tipoFiltro = string.IsNullOrWhiteSpace(tipo) || tipo.Equals("TODOS", StringComparison.OrdinalIgnoreCase)
            ? null
            : tipo.Trim().ToUpperInvariant();

        if (tipoFiltro is not (null or "C" or "D"))
        {
            return Results.BadRequest(new { message = "El tipo debe ser C (crédito) o D (débito)." });
        }

        var paginaActual = Math.Max(pagina ?? 1, 1);
        var tamanoPagina = Math.Clamp(tamano ?? 10, 1, 100);
        var textoFiltro = string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();

        const string filtro = """
            FROM dbo.vwOperacionDetalle AS o
            WHERE o.fecha >= @desde
              AND o.fecha < @hastaExclusivo
              AND (@tipo IS NULL OR o.tipo = @tipo)
              AND (@texto IS NULL
                   OR o.nombreCliente LIKE '%' + @texto + '%'
                   OR o.rutCliente LIKE '%' + @texto + '%'
                   OR o.numeroCuenta LIKE '%' + @texto + '%'
                   OR o.concepto LIKE '%' + @texto + '%'
                   OR o.referencia LIKE '%' + @texto + '%')
            """;

        var sql = $"""
            SELECT
                CAST(ISNULL(SUM(CASE WHEN o.tipo = 'C' THEN 1 ELSE 0 END), 0) AS INT) AS creditos,
                CAST(ISNULL(SUM(CASE WHEN o.tipo = 'D' THEN 1 ELSE 0 END), 0) AS INT) AS debitos,
                CAST(ISNULL(SUM(CASE WHEN o.tipo = 'C' THEN o.montoClp ELSE 0 END), 0) AS DECIMAL(18,2)) AS montoCreditosClp,
                CAST(ISNULL(SUM(CASE WHEN o.tipo = 'D' THEN o.montoClp ELSE 0 END), 0) AS DECIMAL(18,2)) AS montoDebitosClp,
                CAST(ISNULL(SUM(CASE WHEN o.tipo = 'C' THEN o.montoClp ELSE -o.montoClp END), 0) AS DECIMAL(18,2)) AS netoClp
            {filtro};

            SELECT *
            {filtro}
            ORDER BY o.fecha DESC, o.idMovimiento DESC
            OFFSET @offset ROWS FETCH NEXT @tamano ROWS ONLY;
            """;

        var parametros = new
        {
            desde,
            hastaExclusivo = hasta.Date.AddDays(1),
            tipo = tipoFiltro,
            texto = textoFiltro,
            offset = (paginaActual - 1) * tamanoPagina,
            tamano = tamanoPagina
        };

        using var conexion = bd.Crear();
        using var multi = await conexion.QueryMultipleAsync(
            new CommandDefinition(sql, parametros, cancellationToken: cancelacion));

        var resumen = await multi.ReadSingleAsync<ResumenOperacionesDto>();
        var items = (await multi.ReadAsync<OperacionDto>()).AsList();
        var total = resumen.Creditos + resumen.Debitos;

        return Results.Ok(new PaginaOperacionesDto
        {
            Items = items,
            Total = total,
            Pagina = paginaActual,
            Tamano = tamanoPagina,
            TotalPaginas = (int)Math.Ceiling(total / (double)tamanoPagina),
            Resumen = resumen
        });
    }
}
