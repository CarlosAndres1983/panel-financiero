namespace Panel.Api.Features.Operaciones;

/// <summary>
/// Una fila de la vista `vwOperacionDetalle`. Los nombres calzan con el SQL
/// y con `web/src/app/core/models/operacion.model.ts`.
/// </summary>
public sealed class OperacionDto
{
    public long IdMovimiento { get; init; }
    public int IdCuenta { get; init; }
    public string NumeroCuenta { get; init; } = string.Empty;
    public string TipoCuenta { get; init; } = string.Empty;
    public string Moneda { get; init; } = string.Empty;
    public int IdCliente { get; init; }
    public string RutCliente { get; init; } = string.Empty;
    public string NombreCliente { get; init; } = string.Empty;
    public string Segmento { get; init; } = string.Empty;
    public DateTime Fecha { get; init; }
    public string Tipo { get; init; } = string.Empty;
    public string Concepto { get; init; } = string.Empty;
    public decimal Monto { get; init; }
    public decimal MontoClp { get; init; }
    public string Referencia { get; init; } = string.Empty;
}

/// <summary>
/// Totales de todos los movimientos que cumplen el filtro, no solo de la
/// pagina visible. Por eso se calculan en SQL y no en Angular.
/// </summary>
public sealed class ResumenOperacionesDto
{
    public int Creditos { get; init; }
    public int Debitos { get; init; }
    public decimal MontoCreditosClp { get; init; }
    public decimal MontoDebitosClp { get; init; }
    public decimal NetoClp { get; init; }
}

public sealed class PaginaOperacionesDto
{
    public IReadOnlyList<OperacionDto> Items { get; init; } = [];
    public int Total { get; init; }
    public int Pagina { get; init; }
    public int Tamano { get; init; }
    public int TotalPaginas { get; init; }
    public ResumenOperacionesDto Resumen { get; init; } = new();
}
