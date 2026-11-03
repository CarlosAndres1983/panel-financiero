using System.Data;
using Microsoft.Data.SqlClient;

namespace Panel.Api.Data;

/// <summary>
/// Fabrica de conexiones. Se registra como singleton y cada endpoint abre una
/// conexion nueva: ADO.NET las reutiliza desde el pool, no hay que "guardarlas".
/// </summary>
public interface IDbConnectionFactory
{
    IDbConnection Crear();
}

public sealed class SqlConnectionFactory(IConfiguration configuracion) : IDbConnectionFactory
{
    private readonly string _cadena =
        configuracion.GetConnectionString("Panel")
        ?? throw new InvalidOperationException(
            "Falta la cadena de conexión 'Panel' en appsettings.json.");

    public IDbConnection Crear() => new SqlConnection(_cadena);
}
