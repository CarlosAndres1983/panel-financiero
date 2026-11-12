using Microsoft.OpenApi;
using Panel.Api.Data;
using Panel.Api.Features.Dashboard;
using Panel.Api.Features.Operaciones;
using Panel.Api.Features.Propuestas;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<IDbConnectionFactory, SqlConnectionFactory>();
builder.Services.AddProblemDetails();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(opciones =>
{
    opciones.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Panel Financiero API",
        Version = "v1",
        Description = "API de práctica: propuestas de inversión, cuentas y movimientos. Datos ficticios."
    });
});

const string politicaCors = "angular-dev";
builder.Services.AddCors(opciones =>
{
    opciones.AddPolicy(politicaCors, politica => politica
        .WithOrigins("http://localhost:4200")
        .AllowAnyHeader()
        .AllowAnyMethod());
});

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors(politicaCors);

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(opciones =>
        opciones.SwaggerEndpoint("/swagger/v1/swagger.json", "Panel Financiero API v1"));
}

app.MapGet("/", () => Results.Redirect("/swagger"))
    .ExcludeFromDescription();

app.MapGet("/api/health", () => Results.Ok(new
    {
        estado = "ok",
        servicio = "panel-financiero-api",
        fecha = DateTimeOffset.Now
    }))
    .WithTags("Sistema")
    .WithSummary("Verifica que la API esté levantada");

app.MapDashboardEndpoints();
app.MapPropuestasEndpoints();
app.MapOperacionesEndpoints();

app.Run();
