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

# Verificar si ya está configurado
$usingPattern = "using $RootNamespace.$ModuleName.Api.Extensions;"
$servicePattern = "builder\.Services\.Add${ModuleName}Module"
$appPattern = "app\.Use${ModuleName}Module"

if ($programContent -match $usingPattern -and $programContent -match $servicePattern) {
    Write-Host "El módulo $ModuleName ya está configurado en Program.cs" -ForegroundColor Yellow
    return
}

# Agregar using statement si no existe
if ($programContent -notmatch $usingPattern) {
    # Buscar la línea después de los usings existentes
    $lines = $programContent -split "`n"
    $usingIndex = -1
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^using " -and $lines[$i] -notmatch "using Microsoft\." -and $lines[$i] -notmatch "using System\.") {
            $usingIndex = $i
        }
    }
    
    if ($usingIndex -eq -1) {
        # Si no hay usings personalizados, agregar después del último using
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^using " -and $lines[$i] -match "using Microsoft\.") {
                $usingIndex = $i
            }
        }
    }
    
    if ($usingIndex -ne -1) {
        $lines = $lines[0..$usingIndex] + $usingPattern + $lines[($usingIndex + 1)..($lines.Count - 1)]
        $programContent = $lines -join "`n"
        Write-Host "Agregado using statement para $ModuleName" -ForegroundColor Green
    }
}

# Agregar configuración de servicios
if ($programContent -notmatch $servicePattern) {
    # Buscar la línea donde se configuran los servicios
    $serviceConfigPattern = "builder\.Services\.Add.*Module"
    if ($programContent -match $serviceConfigPattern) {
        # Agregar después de la última configuración de módulo
        $programContent = $programContent -replace "($serviceConfigPattern.*?;)", "`$1`n`n// Configurar módulo $ModuleName`nbuilder.Services.Add${ModuleName}Module(builder.Configuration);"
    } else {
        # Buscar después de AddControllers o similar
        $programContent = $programContent -replace "(builder\.Services\.AddControllers.*?;)", "`$1`n`n// Configurar módulo $ModuleName`nbuilder.Services.Add${ModuleName}Module(builder.Configuration);"
    }
    Write-Host "Agregada configuración de servicios para $ModuleName" -ForegroundColor Green
}

# Agregar configuración del pipeline si no existe
if ($programContent -notmatch $appPattern) {
    # Buscar después de app.UseRouting o similar
    $programContent = $programContent -replace "(app\.UseRouting.*?;)", "`$1`n`n// Configurar pipeline del módulo $ModuleName`napp.Use${ModuleName}Module();"
    Write-Host "Agregada configuración del pipeline para $ModuleName" -ForegroundColor Green
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
