param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleName,
    
    [Parameter(Mandatory=$false)]
    [string]$RootNamespace = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ApplicationName = ""
)

# Auto-detectar RootNamespace y ApplicationName si no se proporcionaron
if ([string]::IsNullOrEmpty($RootNamespace) -or [string]::IsNullOrEmpty($ApplicationName)) {
    Write-Host "Auto-detectando configuración del proyecto..." -ForegroundColor Yellow
    
    # Buscar archivo .sln
    $slnFiles = Get-ChildItem -Filter "*.sln" -File
    if ($slnFiles.Count -eq 0) {
        Write-Error "No se encontró archivo .sln en el directorio actual"
        exit 1
    }
    
    $slnFile = $slnFiles[0]
    $detectedAppName = [System.IO.Path]::GetFileNameWithoutExtension($slnFile.Name)
    
    # Buscar proyecto API principal
    $apiProjectPath = "src\$detectedAppName.Api\$detectedAppName.Api.csproj"
    if (Test-Path $apiProjectPath) {
        # Leer el archivo .csproj para obtener el RootNamespace
        $csprojContent = Get-Content $apiProjectPath -Raw
        $rootNamespaceMatch = [regex]::Match($csprojContent, '<RootNamespace>(.*?)</RootNamespace>')
        
        if ($rootNamespaceMatch.Success) {
            $detectedRootNamespace = $rootNamespaceMatch.Groups[1].Value
        } else {
            # Si no hay RootNamespace explícito, usar el nombre del proyecto
            $detectedRootNamespace = $detectedAppName
        }
        
        # Usar valores detectados si no se proporcionaron
        if ([string]::IsNullOrEmpty($RootNamespace)) {
            $RootNamespace = $detectedRootNamespace
        }
        if ([string]::IsNullOrEmpty($ApplicationName)) {
            $ApplicationName = $detectedAppName
        }
        
        Write-Host "✅ Configuración detectada:" -ForegroundColor Green
        Write-Host "   ApplicationName: $ApplicationName" -ForegroundColor Cyan
        Write-Host "   RootNamespace: $RootNamespace" -ForegroundColor Cyan
    } else {
        Write-Error "No se pudo detectar la configuración. Proporciona ApplicationName y RootNamespace manualmente."
        exit 1
    }
}

Write-Host "Configurando módulo: $ModuleName" -ForegroundColor Green

# Verificar que el módulo existe
$modulePath = "src/Modules/$ModuleName"
if (-not (Test-Path $modulePath)) {
    Write-Error "El módulo $ModuleName no existe en $modulePath"
    exit 1
}

# Archivo Program.cs
$programPath = "src/$ApplicationName.Api/Program.cs"
if (-not (Test-Path $programPath)) {
    Write-Error "No se encontró Program.cs en $programPath"
    exit 1
}

Write-Host "Configurando Program.cs..." -ForegroundColor Blue

# Leer el contenido actual
$programContent = Get-Content $programPath -Raw

# FUNCIONES MEJORADAS PARA DETECCIÓN Y AGREGADO

# Función para verificar si un módulo ya está configurado
function Test-ModuleConfigured {
    param([string]$content, [string]$moduleName, [string]$rootNamespace)
    
    $usingPattern = [regex]::Escape("using $rootNamespace.$moduleName.Api.Extensions;")
    $servicePattern = [regex]::Escape("builder.Services.Add${moduleName}Module(builder.Configuration);")
    $appPattern = [regex]::Escape("app.Use${moduleName}Module();")
    
    $hasUsing = $content -match $usingPattern
    $hasService = $content -match $servicePattern
    $hasApp = $content -match $appPattern
    
    return @{
        HasUsing = $hasUsing
        HasService = $hasService
        HasApp = $hasApp
        IsFullyConfigured = $hasUsing -and $hasService -and $hasApp
    }
}

# Función para agregar using statement de forma segura
function Add-UsingStatement {
    param([string]$content, [string]$moduleName, [string]$rootNamespace)
    
    $usingStatement = "using $rootNamespace.$moduleName.Api.Extensions;"
    
    # Verificar si ya existe
    if ($content -match [regex]::Escape($usingStatement)) {
        Write-Host "Using statement para $moduleName ya existe" -ForegroundColor Yellow
        return $content
    }
    
    # Dividir en líneas
    $lines = $content -split "`n"
    
    # Encontrar la posición correcta para insertar (después de los usings del proyecto)
    $insertIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        
        # Buscar después de los usings del proyecto (no de Microsoft/System)
        if ($line -match "^using " -and $line -notmatch "using Microsoft\." -and $line -notmatch "using System\." -and $line -notmatch "using Asp\." -and $line -notmatch "using Serilog" -and $line -notmatch "using Prometheus") {
            $insertIndex = $i
        }
    }
    
    # Si no encontramos usings del proyecto, buscar después del último using
    if ($insertIndex -eq -1) {
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            if ($line -match "^using ") {
                $insertIndex = $i
            }
        }
    }
    
    # Insertar el using statement
    if ($insertIndex -ne -1) {
        $lines = $lines[0..$insertIndex] + $usingStatement + $lines[($insertIndex + 1)..($lines.Count - 1)]
        Write-Host "Agregado using statement para $moduleName" -ForegroundColor Green
        return $lines -join "`n"
    }
    
    return $content
}

# Función para agregar configuración de servicios de forma segura
function Add-ServiceConfiguration {
    param([string]$content, [string]$moduleName)
    
    $serviceConfig = "builder.Services.Add${moduleName}Module(builder.Configuration);"
    
    # Verificar si ya existe
    if ($content -match [regex]::Escape($serviceConfig)) {
        Write-Host "Configuración de servicios para $moduleName ya existe" -ForegroundColor Yellow
        return $content
    }
    
    # Buscar la sección de módulos
    $moduleSectionPattern = "// Módulos"
    if ($content -match $moduleSectionPattern) {
        # Agregar después de la sección de módulos
        $content = $content -replace "($moduleSectionPattern.*?)(?=`n`n|$)", "`$1`n$serviceConfig"
        Write-Host "Agregada configuración de servicios para $moduleName" -ForegroundColor Green
    } else {
        # Si no hay sección de módulos, buscar después de AddSharedKernel
        $sharedKernelPattern = "builder\.Services\.AddSharedKernel\(builder\.Configuration\);"
        if ($content -match $sharedKernelPattern) {
            $content = $content -replace "($sharedKernelPattern)", "`$1`n$serviceConfig"
            Write-Host "Agregada configuración de servicios para $moduleName" -ForegroundColor Green
        } else {
            Write-Host "⚠️ No se pudo encontrar ubicación para agregar configuración de servicios" -ForegroundColor Yellow
        }
    }
    
    return $content
}

# Función para agregar configuración del pipeline de forma segura
function Add-PipelineConfiguration {
    param([string]$content, [string]$moduleName)
    
    $pipelineConfig = "app.Use${moduleName}Module();"
    
    # Verificar si ya existe
    if ($content -match [regex]::Escape($pipelineConfig)) {
        Write-Host "Configuración del pipeline para $moduleName ya existe" -ForegroundColor Yellow
        return $content
    }
    
    # Buscar la sección de endpoints de módulos
    $endpointsPattern = "// Endpoints de módulos"
    if ($content -match $endpointsPattern) {
        # Agregar después de la sección de endpoints
        $content = $content -replace "($endpointsPattern.*?)(?=`n`n|$)", "`$1`n$pipelineConfig"
        Write-Host "Agregada configuración del pipeline para $moduleName" -ForegroundColor Green
    } else {
        # Si no hay sección de endpoints, buscar después de MapControllers
        $mapControllersPattern = "app\.MapControllers\(\);"
        if ($content -match $mapControllersPattern) {
            $content = $content -replace "($mapControllersPattern)", "`$1`n`n// Endpoints de módulos`n$pipelineConfig"
            Write-Host "Agregada configuración del pipeline para $moduleName" -ForegroundColor Green
        } else {
            Write-Host "⚠️ No se pudo encontrar ubicación para agregar configuración del pipeline" -ForegroundColor Yellow
        }
    }
    
    return $content
}

# VERIFICAR SI EL MÓDULO YA ESTÁ CONFIGURADO
$moduleStatus = Test-ModuleConfigured $programContent $ModuleName $RootNamespace

if ($moduleStatus.IsFullyConfigured) {
    Write-Host "El módulo $ModuleName ya está completamente configurado en Program.cs" -ForegroundColor Yellow
    return
}

# AGREGAR CONFIGURACIONES FALTANTES
if (-not $moduleStatus.HasUsing) {
    $programContent = Add-UsingStatement $programContent $ModuleName $RootNamespace
}

if (-not $moduleStatus.HasService) {
    $programContent = Add-ServiceConfiguration $programContent $ModuleName
}

if (-not $moduleStatus.HasApp) {
    $programContent = Add-PipelineConfiguration $programContent $ModuleName
}

# Guardar el archivo actualizado
$programContent | Out-File -FilePath $programPath -Encoding UTF8

Write-Host "✅ Módulo $ModuleName configurado exitosamente en Program.cs" -ForegroundColor Green

# Crear archivo de migración inicial si no existe
$migrationPath = "src/Modules/$ModuleName/$ApplicationName.$ModuleName.Infrastructure/Migrations"
if (-not (Test-Path $migrationPath)) {
    Write-Host "Creando migración inicial para $ModuleName..." -ForegroundColor Blue
    
    try {
        $infrastructurePath = "src/Modules/$ModuleName/$ApplicationName.$ModuleName.Infrastructure"
        $startupPath = "src/$ApplicationName.Api"
        $contextName = "${ModuleName}DbContext"
        
        dotnet ef migrations add InitialCreate --project $infrastructurePath --startup-project $startupPath --context $contextName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Migración inicial creada para $ModuleName" -ForegroundColor Green
        } else {
            Write-Host "⚠️ No se pudo crear la migración inicial. Crea la migración manualmente:" -ForegroundColor Yellow
            Write-Host "dotnet ef migrations add InitialCreate --project $infrastructurePath --startup-project $startupPath --context $contextName" -ForegroundColor White
        }
    }
    catch {
        Write-Host "⚠️ Error al crear migración: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`nConfiguración completada para el módulo $ModuleName" -ForegroundColor Green
Write-Host "Próximos pasos:" -ForegroundColor Yellow
Write-Host "1. dotnet build" -ForegroundColor White
Write-Host "2. dotnet run --project src/$ApplicationName.Api" -ForegroundColor White
Write-Host "3. Probar: curl http://localhost:5000/api/$ModuleName" -ForegroundColor White
