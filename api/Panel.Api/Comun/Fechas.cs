using System.Globalization;

namespace Panel.Api.Comun;

public static class Fechas
{
    private static readonly string[] Formatos = ["yyyy-MM-dd", "dd-MM-yyyy"];

    /// <summary>
    /// Acepta `yyyy-MM-dd` (lo que manda un input date) y `dd-MM-yyyy`
    /// (formato habitual en Chile) para poder probar desde Swagger.
    /// </summary>
    public static bool TryParse(string? valor, out DateTime fecha) =>
        DateTime.TryParseExact(
            valor,
            Formatos,
            CultureInfo.InvariantCulture,
            DateTimeStyles.None,
            out fecha);
}
