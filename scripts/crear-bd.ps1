# Crea (o recrea) la base de datos PanelFinanciero en SQL Server Express.
#
# Uso:
#   .\scripts\crear-bd.ps1
#   .\scripts\crear-bd.ps1 -Servidor ".\SQLEXPRESS" -OmitirDatos
#
# Requiere sqlcmd y permisos para crear bases de datos en la instancia local.

[CmdletBinding()]
param(
    [string]$Servidor = ".\SQLEXPRESS",
    [switch]$OmitirDatos
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    throw "No se encontro sqlcmd. Instala las herramientas de SQL Server o usa SSMS para ejecutar los scripts de sql\."
}

function Invoke-ScriptSql {
    param([string]$Archivo)

    if (-not (Test-Path $Archivo)) {
        throw "No existe el archivo $Archivo."
    }

    Write-Host ""
    Write-Host ">> Ejecutando $(Split-Path -Leaf $Archivo)" -ForegroundColor Cyan
    & sqlcmd -S $Servidor -E -b -f 65001 -i $Archivo

    if ($LASTEXITCODE -ne 0) {
        throw "Fallo la ejecucion de $Archivo. Revisa el mensaje anterior."
    }
}

Write-Host "Instancia: $Servidor" -ForegroundColor DarkGray
Invoke-ScriptSql (Join-Path $raiz "sql\001_esquema.sql")

if (-not $OmitirDatos) {
    Invoke-ScriptSql (Join-Path $raiz "sql\002_datos_prueba.sql")
}

Write-Host ""
Write-Host ">> Verificando datos" -ForegroundColor Cyan
& sqlcmd -S $Servidor -E -W -Q "SET NOCOUNT ON; USE PanelFinanciero; SELECT (SELECT COUNT(*) FROM dbo.Cliente) AS clientes, (SELECT COUNT(*) FROM dbo.Cuenta) AS cuentas, (SELECT COUNT(*) FROM dbo.Propuesta) AS propuestas, (SELECT COUNT(*) FROM dbo.Movimiento) AS movimientos;"

if ($LASTEXITCODE -ne 0) {
    throw "La base se creo pero la verificacion fallo."
}

Write-Host ""
Write-Host "Listo. Base PanelFinanciero creada en $Servidor." -ForegroundColor Green
Write-Host "Siguiente paso: .\scripts\levantar.ps1" -ForegroundColor Green
