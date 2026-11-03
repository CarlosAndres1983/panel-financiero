# Detiene la API y el frontend de este proyecto.
#
# Uso:
#   .\scripts\detener.ps1
#
# Solo busca procesos escuchando en los puertos 5080 (API) y 4200 (Angular).

[CmdletBinding()]
param()

$ErrorActionPreference = "SilentlyContinue"

$puertos = @(5080, 4200)
$encontrados = $false

foreach ($puerto in $puertos) {
    $conexiones = Get-NetTCPConnection -LocalPort $puerto -State Listen

    foreach ($conexion in $conexiones) {
        $proceso = Get-Process -Id $conexion.OwningProcess

        if ($null -eq $proceso) {
            continue
        }

        $encontrados = $true
        Write-Host "Deteniendo $($proceso.ProcessName) (PID $($proceso.Id)) en el puerto $puerto..." -ForegroundColor Yellow
        Stop-Process -Id $proceso.Id -Force
    }
}

if ($encontrados) {
    Write-Host "Servicios detenidos." -ForegroundColor Green
}
else {
    Write-Host "No hay servicios escuchando en los puertos 5080 ni 4200." -ForegroundColor DarkGray
}
