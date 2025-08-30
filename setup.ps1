# Script simplificado para instalar template y crear proyectos
# Autor: Oscar Mauricio Benavidez Suarez - Celuweb

param(
    [string]$Action = "help",
    [string]$ProjectName = "AgentesComerciales",
    [string]$RootNamespace = "",
    [string]$OutputDirectory = "C:\Users\Mauricio\source\repos\Celuweb\AGENTES-COMERCIALES\Proyecto"
)

# Configuracion automatica
if ([string]::IsNullOrEmpty($RootNamespace)) {
    $RootNamespace = "Celuweb.$ProjectName"
}

function Show-Help {
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "  TEMPLATE MONOLITO MODULAR SETUP   " -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USO:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Instalar template:" -ForegroundColor White
    Write-Host "  .\setup.ps1 -Action install" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Crear proyecto:" -ForegroundColor White
    Write-Host "  .\setup.ps1 -Action create" -ForegroundColor Gray
    Write-Host "  .\setup.ps1 -Action create -ProjectName MiApp" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Todo en uno (RECOMENDADO):" -ForegroundColor White
    Write-Host "  .\create-project.ps1" -ForegroundColor Gray
    Write-Host "  .\create-project.ps1 -ProjectName MiApp" -ForegroundColor Gray
    Write-Host ""
}

function Install-Only {
    Write-Host "Instalando template..." -ForegroundColor Blue
    
    # Verificar .NET
    try {
        $dotnetVersion = dotnet --version
        Write-Host "OK - .NET SDK: $dotnetVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR - .NET SDK no encontrado" -ForegroundColor Red
        return $false
    }
    
    # Verificar template config
    $templateConfig = Join-Path $PSScriptRoot ".template.config\template.json"
    if (-not (Test-Path $templateConfig)) {
        Write-Host "ERROR - template.json no encontrado" -ForegroundColor Red
        return $false
    }
    
    # Desinstalar versiones anteriores
    dotnet new uninstall "Celuweb.ModularMonolith.Template" 2>$null
    dotnet new uninstall $PSScriptRoot 2>$null
    
    # Instalar
    $result = dotnet new install $PSScriptRoot 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK - Template instalado" -ForegroundColor Green
        return $true
    } else {
        Write-Host "ERROR - Fallo la instalacion" -ForegroundColor Red
        return $false
    }
}

function Create-Only {
    Write-Host "Creando proyecto: $ProjectName" -ForegroundColor Blue
    
    # Verificar que template esta instalado
    $templates = dotnet new list 2>&1
    $hasTemplate = $templates | Where-Object { $_ -match "modular-monolith" }
    
    if (-not $hasTemplate) {
        Write-Host "ERROR - Template no instalado. Ejecuta: .\setup.ps1 -Action install" -ForegroundColor Red
        return $false
    }
    
    # Crear directorio si no existe
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    }
    
    # Crear proyecto
    Push-Location $OutputDirectory
    $result = dotnet new modular-monolith -n $ProjectName --RootNamespace $RootNamespace --ApplicationName $ProjectName --force 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK - Proyecto creado en: $OutputDirectory\$ProjectName" -ForegroundColor Green
        Pop-Location
        return $true
    } else {
        Write-Host "ERROR - Fallo la creacion del proyecto" -ForegroundColor Red
        Pop-Location
        return $false
    }
}

# Ejecutar accion
switch ($Action.ToLower()) {
    "install" {
        if (Install-Only) {
            Write-Host ""
            Write-Host "Siguiente paso: .\setup.ps1 -Action create" -ForegroundColor Yellow
        }
    }
    "create" {
        if (Create-Only) {
            Write-Host ""
            Write-Host "Proyecto listo en: $OutputDirectory\$ProjectName" -ForegroundColor Green
        }
    }
    "help" {
        Show-Help
    }
    default {
        Show-Help
    }
}
