using System.Data;
using Dapper;
using Panel.Api.Comun;
using Panel.Api.Data;

namespace Panel.Api.Features.Propuestas;

public static class PropuestasEndpoints
{
    public static IEndpointRouteBuilder MapPropuestasEndpoints(this IEndpointRouteBuilder app)
    {
        var grupo = app.MapGroup("/api/propuestas").WithTags("Propuestas");

        grupo.MapGet("", BuscarAsync)
            .WithName("BuscarPropuestas")
            .WithSummary("Consulta paginada de propuestas por fecha, estado y texto")
            .Produces<PaginaDto<PropuestaDto>>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest);

        grupo.MapGet("/estados", ListarEstadosAsync)
            .WithName("ListarEstados")
            .WithSummary("Estados disponibles para el filtro")
            .Produces<IReadOnlyList<EstadoPropuestaDto>>(StatusCodes.Status200OK);

        grupo.MapPost("/{id:int}/resolver", ResolverAsync)
            .WithName("ResolverPropuesta")
            .WithSummary("Aprueba o rechaza una propuesta pendiente (transaccion + auditoria)")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .ProducesProblem(StatusCodes.Status409Conflict);

        return app;
    }

    private static async Task<IResult> BuscarAsync(
        string? fechaDesde,
        string? fechaHasta,
        string? estado,
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

        var paginaActual = Math.Max(pagina ?? 1, 1);
        var tamanoPagina = Math.Clamp(tamano ?? 10, 1, 100);
        var estadoFiltro = string.IsNullOrWhiteSpace(estado) || estado.Equals("TODOS", StringComparison.OrdinalIgnoreCase)
            ? null
            : estado.Trim().ToUpperInvariant();
        var textoFiltro = string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();

        const string filtro = """
            FROM dbo.vwPropuestaDetalle AS v
            WHERE v.fechaSolicitud >= @desde
              AND v.fechaSolicitud < @hastaExclusivo
              AND (@estado IS NULL OR v.codigoEstado = @estado)
              AND (@texto IS NULL
                   OR v.nombreCliente LIKE '%' + @texto + '%'
                   OR v.rutCliente LIKE '%' + @texto + '%'
                   OR v.numeroCuenta LIKE '%' + @texto + '%'
                   OR v.tipoProducto LIKE '%' + @texto + '%')
            """;

        var sql = $"""
            SELECT COUNT(*) {filtro};

            SELECT *
            {filtro}
            ORDER BY v.fechaSolicitud DESC, v.idPropuesta DESC
            OFFSET @offset ROWS FETCH NEXT @tamano ROWS ONLY;
            """;

        var parametros = new
        {
            desde,
            hastaExclusivo = hasta.Date.AddDays(1),
            estado = estadoFiltro,
            texto = textoFiltro,
            offset = (paginaActual - 1) * tamanoPagina,
            tamano = tamanoPagina
        };

        using var conexion = bd.Crear();
        using var multi = await conexion.QueryMultipleAsync(
            new CommandDefinition(sql, parametros, cancellationToken: cancelacion));

        var total = await multi.ReadSingleAsync<int>();
        var items = (await multi.ReadAsync<PropuestaDto>()).AsList();

        return Results.Ok(new PaginaDto<PropuestaDto>
        {
            Items = items,
            Total = total,
            Pagina = paginaActual,
            Tamano = tamanoPagina,
            TotalPaginas = (int)Math.Ceiling(total / (double)tamanoPagina)
        });
    }

    private static async Task<IResult> ListarEstadosAsync(
        IDbConnectionFactory bd,
        CancellationToken cancelacion)
    {
        const string sql = """
            SELECT idEstado, codigo, nombre, orden
            FROM dbo.TipoEstado
            ORDER BY orden;
            """;

        using var conexion = bd.Crear();
        var estados = await conexion.QueryAsync<EstadoPropuestaDto>(
            new CommandDefinition(sql, cancellationToken: cancelacion));

        return Results.Ok(estados.AsList());
    }

    private static async Task<IResult> ResolverAsync(
        int id,
        ResolverPropuestaRequest request,
        IDbConnectionFactory bd,
        CancellationToken cancelacion)
    {
        var accion = (request.Accion ?? string.Empty).Trim().ToUpperInvariant();
        if (accion is not ("APROBAR" or "RECHAZAR"))
        {
            return Results.BadRequest(new { message = "La acción debe ser APROBAR o RECHAZAR." });
        }

        var usuario = (request.Usuario ?? string.Empty).Trim();
        if (usuario.Length is 0 or > 40)
        {
            return Results.BadRequest(new { message = "Debe indicar un usuario de hasta 40 caracteres." });
        }

        var comentario = string.IsNullOrWhiteSpace(request.Comentario)
            ? null
            : request.Comentario.Trim();

        if (comentario is { Length: > 300 })
        {
            return Results.BadRequest(new { message = "El comentario no puede superar los 300 caracteres." });
        }

        using var conexion = bd.Crear();
        conexion.Open();
        using var transaccion = conexion.BeginTransaction();

        try
        {
            // UPDLOCK: bloquea la fila hasta el commit. Si dos analistas aprueban
            // a la vez, el segundo espera y luego ve el estado ya cambiado.
            const string sqlActual = """
                SELECT p.idEstado, e.codigo, e.nombre
                FROM dbo.Propuesta AS p WITH (UPDLOCK, ROWLOCK)
                INNER JOIN dbo.TipoEstado AS e ON e.idEstado = p.idEstado
                WHERE p.idPropuesta = @id;
                """;

            var actual = await conexion.QuerySingleOrDefaultAsync<EstadoPropuestaDto>(
                new CommandDefinition(sqlActual, new { id }, transaccion, cancellationToken: cancelacion));

            if (actual is null)
            {
                transaccion.Rollback();
                return Results.NotFound(new { message = $"No existe la propuesta {id}." });
            }

            if (actual.Codigo is not ("PEND" or "REVI"))
            {
                transaccion.Rollback();
                return Results.Conflict(new
                {
                    message = $"La propuesta {id} ya está en estado '{actual.Nombre}' y no se puede resolver."
                });
            }

            var nuevoCodigo = accion == "APROBAR" ? "APRO" : "RECH";
            var nuevoEstado = await conexion.QuerySingleAsync<EstadoPropuestaDto>(
                new CommandDefinition(
                    "SELECT idEstado, codigo, nombre FROM dbo.TipoEstado WHERE codigo = @codigo;",
                    new { codigo = nuevoCodigo },
                    transaccion,
                    cancellationToken: cancelacion));

            const string sqlUpdate = """
                UPDATE dbo.Propuesta
                SET idEstado = @idEstado,
                    fechaResolucion = SYSDATETIME(),
                    usuarioResolucion = @usuario,
                    observacion = COALESCE(@comentario, observacion)
                WHERE idPropuesta = @id;
                """;

            await conexion.ExecuteAsync(new CommandDefinition(
                sqlUpdate,
                new { id, idEstado = nuevoEstado.IdEstado, usuario, comentario },
                transaccion,
                cancellationToken: cancelacion));

            const string sqlAuditoria = """
                INSERT dbo.AuditoriaPropuesta
                    (idPropuesta, accion, estadoAnterior, estadoNuevo, usuario, comentario)
                VALUES
                    (@id, @accion, @estadoAnterior, @estadoNuevo, @usuario, @comentario);
                """;

            await conexion.ExecuteAsync(new CommandDefinition(
                sqlAuditoria,
                new
                {
                    id,
                    accion,
                    estadoAnterior = actual.Nombre,
                    estadoNuevo = nuevoEstado.Nombre,
                    usuario,
                    comentario
                },
                transaccion,
                cancellationToken: cancelacion));

            transaccion.Commit();

            return Results.Ok(new
            {
                idPropuesta = id,
                codigoEstado = nuevoEstado.Codigo,
                estado = nuevoEstado.Nombre,
                usuario,
                comentario
            });
        }
        catch
        {
            if (transaccion.Connection is not null)
            {
                try { transaccion.Rollback(); } catch { /* la conexion ya se cerro */ }
            }

            throw;
        }
    }
}
