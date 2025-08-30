# Script UNICO para instalar template y crear proyectos
# Autor: Oscar Mauricio Benavidez Suarez - Celuweb

param(
    [string]$ProjectName = "AgentesComerciales",
    [string]$RootNamespace = "",
    [string]$OutputDirectory = "C:\Users\Mauricio\source\repos\Celuweb\AGENTES-COMERCIALES\Proyecto"
)

# Configuracion automatica del namespace si no se proporciona
if ([string]::IsNullOrEmpty($RootNamespace)) {
    $RootNamespace = "Celuweb.$ProjectName"
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  CREADOR DE PROYECTO MONOLITICO     " -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proyecto: $ProjectName" -ForegroundColor White
Write-Host "Namespace: $RootNamespace" -ForegroundColor White
Write-Host "Destino: $OutputDirectory" -ForegroundColor White
Write-Host ""

# Verificar .NET
Write-Host "Verificando .NET SDK..." -ForegroundColor Blue
try {
    $dotnetVersion = dotnet --version
    Write-Host "OK - .NET SDK: $dotnetVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERROR - .NET SDK no encontrado" -ForegroundColor Red
    Write-Host "Instala .NET desde: https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    exit 1
}

# Verificar archivo de configuracion del template
$templateConfig = Join-Path $PSScriptRoot ".template.config\template.json"
if (-not (Test-Path $templateConfig)) {
    Write-Host "ERROR - No se encontro template.json en: $templateConfig" -ForegroundColor Red
    Write-Host "Ejecuta este script desde el directorio del template" -ForegroundColor Yellow
    exit 1
}
Write-Host "OK - Configuracion del template encontrada" -ForegroundColor Green

# Crear directorio de destino si no existe
if (-not (Test-Path $OutputDirectory)) {
    Write-Host "Creando directorio: $OutputDirectory" -ForegroundColor Blue
    try {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        Write-Host "OK - Directorio creado" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR - No se pudo crear el directorio: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Paso 1: Desinstalar versiones anteriores
Write-Host "Removiendo versiones anteriores del template..." -ForegroundColor Blue
dotnet new uninstall "Celuweb.ModularMonolith.Template" 2>$null
dotnet new uninstall $PSScriptRoot 2>$null
Write-Host "OK - Versiones anteriores removidas" -ForegroundColor Green

# Paso 2: Instalar template
Write-Host "Instalando template..." -ForegroundColor Blue
$installResult = dotnet new install $PSScriptRoot 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Template instalado exitosamente" -ForegroundColor Green
} else {
    Write-Host "ERROR - Fallo al instalar template:" -ForegroundColor Red
    $installResult | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

# Verificar que el template esta disponible
Write-Host "Verificando template..." -ForegroundColor Blue
$templates = dotnet new list 2>&1
$modularTemplate = $templates | Where-Object { $_ -match "modular-monolith|Celuweb" }

if ($modularTemplate) {
    Write-Host "OK - Template verificado y disponible" -ForegroundColor Green
} else {
    Write-Host "WARNING - Template instalado pero no aparece en la lista" -ForegroundColor Yellow
}

# Paso 3: Crear proyecto
Write-Host "Creando proyecto..." -ForegroundColor Blue
Push-Location $OutputDirectory

$createResult = dotnet new modular-monolith -n $ProjectName --RootNamespace $RootNamespace --ApplicationName $ProjectName --force 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - Proyecto creado exitosamente" -ForegroundColor Green
    
    # Verificar que el directorio del proyecto existe
    $projectPath = Join-Path $OutputDirectory $ProjectName
    if (Test-Path $projectPath) {
        Write-Host ""
        Write-Host "=================================" -ForegroundColor Green
        Write-Host "     PROYECTO CREADO CON EXITO   " -ForegroundColor Green
        Write-Host "=================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Ubicacion: $projectPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Proximos pasos:" -ForegroundColor Yellow
        Write-Host "1. cd $projectPath" -ForegroundColor White
        Write-Host "2. docker-compose up -d" -ForegroundColor White
        Write-Host "3. Abrir: http://localhost:5000/swagger" -ForegroundColor White
        Write-Host ""
        Write-Host "Para crear modulos:" -ForegroundColor Yellow
        Write-Host "   .\scripts\create-module.ps1 -ModuleName Products" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "WARNING - Proyecto creado pero directorio no encontrado" -ForegroundColor Yellow
    }
} else {
    Write-Host "ERROR - Fallo al crear proyecto:" -ForegroundColor Red
    $createResult | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Pop-Location
    exit 1
}

Pop-Location