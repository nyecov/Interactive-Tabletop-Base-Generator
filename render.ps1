# OpenSCAD Automated Rendering Script
# This script renders base_generator.scad to STL and 3MF formats

param(
    [string]$OutputName = "output",
    [ValidateSet("stl", "3mf", "both")]
    [string]$Format = "both",
    [string[]]$Parameters = @(),
    [string]$OpenScadPath = "C:\Program Files\OpenSCAD\openscad.exe"
)

# Check if OpenSCAD exists
if (-not (Test-Path $OpenScadPath)) {
    Write-Host "ERROR: OpenSCAD not found at: $OpenScadPath" -ForegroundColor Red
    Write-Host "Please install OpenSCAD or specify the correct path with -OpenScadPath" -ForegroundColor Yellow
    exit 1
}

# Define input file
$InputFile = "base_generator.scad"

if (-not (Test-Path $InputFile)) {
    Write-Host "ERROR: $InputFile not found in current directory" -ForegroundColor Red
    exit 1
}

Write-Host "Starting render..." -ForegroundColor Green

# Render STL
if ($Format -eq "stl" -or $Format -eq "both") {
    $stlOutput = "$OutputName.stl"
    Write-Host "Rendering STL: $stlOutput" -ForegroundColor Cyan
    & $OpenScadPath -o $stlOutput @Parameters $InputFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ STL rendered successfully: $stlOutput" -ForegroundColor Green
    }
    else {
        Write-Host "✗ STL rendering failed" -ForegroundColor Red
    }
}

# Render 3MF
if ($Format -eq "3mf" -or $Format -eq "both") {
    $3mfOutput = "$OutputName.3mf"
    Write-Host "Rendering 3MF: $3mfOutput" -ForegroundColor Cyan
    & $OpenScadPath -o $3mfOutput @Parameters $InputFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 3MF rendered successfully: $3mfOutput" -ForegroundColor Green
    }
    else {
        Write-Host "✗ 3MF rendering failed" -ForegroundColor Red
    }
}

Write-Host "`nRender complete!" -ForegroundColor Green
