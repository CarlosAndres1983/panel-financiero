# Levanta la API (.NET) y el frontend (Angular) en dos ventanas separadas.
#
# Uso:
#   .\scripts\levantar.ps1
#   .\scripts\levantar.ps1 -SinNavegador
#
# La API queda en http://localhost:5080/swagger
# La web queda en http://localhost:4200

[CmdletBinding()]
param(
    [switch]$SinNavegador
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "No se encontro dotnet. Instala el SDK de .NET 9."
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "No se encontro npm. Instala Node.js 20 o superior."
}

Write-Host "Iniciando API en una ventana nueva..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "dotnet run --urls http://localhost:5080"
) -WorkingDirectory (Join-Path $raiz "api\Panel.Api")

Write-Host "Iniciando Angular en una ventana nueva..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "npm start"
) -WorkingDirectory (Join-Path $raiz "web")

Write-Host ""
Write-Host "Esperando que la API responda..." -ForegroundColor DarkGray

$apiLista = $false
for ($intento = 1; $intento -le 30; $intento++) {
    try {
        Invoke-RestMethod -Uri "http://localhost:5080/api/health" -TimeoutSec 2 | Out-Null
        $apiLista = $true
        break
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

if ($apiLista) {
    Write-Host "API lista: http://localhost:5080/swagger" -ForegroundColor Green
}
else {
    Write-Host "La API no respondio. Revisa la ventana de la API (puede faltar la base de datos)." -ForegroundColor Yellow
}

Write-Host "Esperando que Angular compile..." -ForegroundColor DarkGray
$webLista = $false
for ($intento = 1; $intento -le 30; $intento++) {
    try {
        Invoke-WebRequest -Uri "http://localhost:4200" -TimeoutSec 2 -UseBasicParsing | Out-Null
        $webLista = $true
        break
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $webLista) {
    Write-Host "La web aun no responde. Revisa la ventana de Angular." -ForegroundColor Yellow
}

if (-not $SinNavegador -and $webLista) {
    Start-Process "http://localhost:4200"
}

Write-Host "Web: http://localhost:4200" -ForegroundColor Green
Write-Host "Para detener todo, cierra las dos ventanas nuevas o presiona Ctrl+C en cada una." -ForegroundColor DarkGray
