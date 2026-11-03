namespace Panel.Api.Features.Propuestas;

/// <summary>
/// Fila del monitor. Los nombres calzan con la vista SQL y con
/// `web/src/app/core/models/propuesta.model.ts`.
/// </summary>
public sealed class PropuestaDto
{
    public int IdPropuesta { get; init; }
    public int IdCuenta { get; init; }
    public string NumeroCuenta { get; init; } = string.Empty;
    public int IdCliente { get; init; }
    public string RutCliente { get; init; } = string.Empty;
    public string NombreCliente { get; init; } = string.Empty;
    public string Segmento { get; init; } = string.Empty;
    public string Ejecutivo { get; init; } = string.Empty;
    public string? FlgPep { get; init; }
    public string TipoCuenta { get; init; } = string.Empty;
    public string Moneda { get; init; } = string.Empty;
    public decimal SaldoCuenta { get; init; }
    public string EstadoCuenta { get; init; } = string.Empty;

    public int IdEstado { get; init; }
    public string CodigoEstado { get; init; } = string.Empty;
    public string Estado { get; init; } = string.Empty;

    public string TipoProducto { get; init; } = string.Empty;
    public decimal Monto { get; init; }
    public int PlazoDias { get; init; }
    public decimal TasaAnual { get; init; }
    public string? Observacion { get; init; }
    public string Asesor { get; init; } = string.Empty;

    public DateTime FechaSolicitud { get; init; }
    public DateTime? FechaResolucion { get; init; }
    public string? UsuarioResolucion { get; init; }
}

public sealed class EstadoPropuestaDto
{
    public int IdEstado { get; init; }
    public string Codigo { get; init; } = string.Empty;
    public string Nombre { get; init; } = string.Empty;
    public int Orden { get; init; }
}

public sealed class PaginaDto<T>
{
    public required IReadOnlyList<T> Items { get; init; }
    public int Total { get; init; }
    public int Pagina { get; init; }
    public int Tamano { get; init; }
    public int TotalPaginas { get; init; }
}

public sealed class ResolverPropuestaRequest
{
    public string? Accion { get; init; }
    public string? Usuario { get; init; }
    public string? Comentario { get; init; }
}
