# Script inteligente para crear modulos
# Detecta automaticamente el ApplicationName y RootNamespace del proyecto actual

param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleName
)

# Funcion para detectar el nombre de la aplicacion desde la solucion
function Get-ApplicationInfo {
    $slnFiles = Get-ChildItem -Filter "*.sln" | Select-Object -First 1
    
    if ($slnFiles) {
        $applicationName = [System.IO.Path]::GetFileNameWithoutExtension($slnFiles.Name)
        Write-Host "Detectado ApplicationName: $applicationName" -ForegroundColor Green
    } else {
        Write-Error "No se encontro archivo .sln en el directorio actual"
        exit 1
    }
    
    # Intentar detectar el RootNamespace desde un archivo .csproj
    $apiProject = Get-ChildItem -Path "src" -Filter "$applicationName.Api.csproj" -Recurse | Select-Object -First 1
    
    if ($apiProject) {
        $content = Get-Content $apiProject.FullName -Raw
        if ($content -match '<RootNamespace>([^<]+)</RootNamespace>') {
            $rootNamespace = $matches[1]
            Write-Host "Detectado RootNamespace: $rootNamespace" -ForegroundColor Green
        } elseif ($content -match '<AssemblyName>([^<]+)</AssemblyName>') {
            # Si no hay RootNamespace, buscar AssemblyName
            $assemblyName = $matches[1]
            # Extraer el namespace base del AssemblyName (sin .Api)
            $rootNamespace = $assemblyName -replace '\.Api$', ''
            Write-Host "Detectado RootNamespace desde AssemblyName: $rootNamespace" -ForegroundColor Green
        } else {
            # Si no hay nada, usar el nombre del proyecto como base
            $rootNamespace = $applicationName
            Write-Host "Usando RootNamespace por defecto: $rootNamespace" -ForegroundColor Yellow
        }
    } else {
        Write-Error "No se encontro el proyecto API principal"
        exit 1
    }
    
    return @{
        ApplicationName = $applicationName
        RootNamespace = $rootNamespace
    }
}

# Verificar que estamos en un directorio de proyecto valido
if (!(Test-Path "src") -or !(Test-Path "*.sln")) {
    Write-Error "ERROR: Este script debe ejecutarse desde la raiz de un proyecto creado con el template monolito modular"
    Write-Host "NOTA: Asegurate de estar en el directorio que contiene el archivo .sln y la carpeta src/" -ForegroundColor Yellow
    exit 1
}

Write-Host "Creando modulo: $ModuleName" -ForegroundColor Green

# Detectar informacion del proyecto
$projectInfo = Get-ApplicationInfo

# Ejecutar el script de creacion con los parametros detectados
$createScript = Join-Path $PSScriptRoot "create-module.ps1"
if (Test-Path $createScript) {
    & $createScript -ModuleName $ModuleName -RootNamespace $projectInfo.RootNamespace -ApplicationName $projectInfo.ApplicationName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Modulo creado exitosamente" -ForegroundColor Green
        
        # Preguntar si quiere configurar automaticamente
        $response = Read-Host "Quieres configurar el modulo automaticamente en Program.cs? (y/n)"
        if ($response -eq "y" -or $response -eq "Y" -or $response -eq "") {
            $configScript = Join-Path $PSScriptRoot "configure-module.ps1"
            if (Test-Path $configScript) {
                & $configScript -ModuleName $ModuleName -RootNamespace $projectInfo.RootNamespace -ApplicationName $projectInfo.ApplicationName
                Write-Host "Modulo configurado automaticamente" -ForegroundColor Green
            }
        }
        
        Write-Host "`nProximos pasos:" -ForegroundColor Yellow
        Write-Host "1. dotnet build" -ForegroundColor White
        Write-Host "2. dotnet run --project src/$($projectInfo.ApplicationName).Api" -ForegroundColor White
        Write-Host "3. Probar: curl http://localhost:5000/api/$ModuleName" -ForegroundColor White
    }
} else {
    Write-Error "No se encontro el script create-module.ps1"
}
