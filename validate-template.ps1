# Template Validation Script
# This script validates that the modular monolith template is properly configured

param(
    [string]$ProjectName = "TestProject",
    [string]$OutputPath = "C:\temp\template-test"
)

Write-Host "🔍 Validating Modular Monolith Template..." -ForegroundColor Cyan

# Check if template files exist
$requiredFiles = @(
    "__ApplicationName__.sln",
    "src\__ApplicationName__.Api\__ApplicationName__.Api.csproj",
    "src\__ApplicationName__.Application\__ApplicationName__.Application.csproj",
    "src\__ApplicationName__.Domain\__ApplicationName__.Domain.csproj",
    "src\__ApplicationName__.Infrastructure\__ApplicationName__.Infrastructure.csproj",
    "src\Modules\Users\__ApplicationName__.Modules.Users.Api\__ApplicationName__.Modules.Users.Api.csproj",
    "Directory.Build.props",
    "docker-compose.yml",
    "README.md"
)

$templatePath = $PSScriptRoot
$missingFiles = @()

foreach ($file in $requiredFiles) {
    $fullPath = Join-Path $templatePath $file
    if (-not (Test-Path $fullPath)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing required files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
    exit 1
}

Write-Host "✅ All required template files found" -ForegroundColor Green

# Test project creation
Write-Host "🚀 Testing project creation..." -ForegroundColor Cyan

if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Recurse -Force
}

try {
    # Run the create-project script
    $createScript = Join-Path $templatePath "create-project.ps1"
    & $createScript -ProjectName $ProjectName -OutputPath $OutputPath

    if (-not (Test-Path $OutputPath)) {
        throw "Project creation failed - output directory not created"
    }

    Write-Host "✅ Project created successfully" -ForegroundColor Green

    # Test solution compilation
    Write-Host "🔨 Testing solution compilation..." -ForegroundColor Cyan
    
    Set-Location $OutputPath
    $buildResult = & dotnet build --verbosity quiet 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ Solution compiled successfully" -ForegroundColor Green

    # Test module creation
    Write-Host "📦 Testing module creation..." -ForegroundColor Cyan
    
    $moduleScript = Join-Path $templatePath "scripts\create-module.ps1"
    & $moduleScript -ModuleName "Products"
    
    if (-not (Test-Path "src\Modules\Products")) {
        throw "Module creation failed"
    }

    Write-Host "✅ Module creation successful" -ForegroundColor Green

    # Test build after module creation
    $buildResult = & dotnet build --verbosity quiet 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed after module creation:" -ForegroundColor Red
        Write-Host $buildResult -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ Solution compiled successfully after module addition" -ForegroundColor Green

} catch {
    Write-Host "❌ Validation failed: $_" -ForegroundColor Red
    exit 1
} finally {
    Set-Location $templatePath
}

Write-Host ""
Write-Host "🎉 Template validation completed successfully!" -ForegroundColor Green
Write-Host "   Project created at: $OutputPath" -ForegroundColor Cyan
Write-Host "   Use the following commands to get started:" -ForegroundColor Cyan
Write-Host "     cd `"$OutputPath`"" -ForegroundColor Yellow
Write-Host "     dotnet run --project src\$($ProjectName).Api" -ForegroundColor Yellow
Write-Host ""
