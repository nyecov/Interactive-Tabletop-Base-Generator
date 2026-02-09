# Generate Round Base Magnet Test Batch
param(
    [string]$OpenScadPath = "C:\Program Files\OpenSCAD\openscad.exe"
)

# $ErrorActionPreference = "Stop" # Removed to prevent OpenSCAD logs from stopping the script

$BaseDir = Get-Location
$OutputDir = Join-Path $BaseDir "generated files\Magnet"
$TempStlDir = Join-Path $BaseDir "Temp_Round_Magnets"
$Final3mf = "RoundBase_with_magnet.3mf"
$InputScad = "base_generator.scad"
$Template3mf = "slicer_settings_reference.3mf"

# Create directories
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
if (-not (Test-Path $TempStlDir)) { New-Item -ItemType Directory -Path $TempStlDir -Force | Out-Null }

$baseSizes = @(
    @{ Dim = 25.4; Name = "1_inch" }, @{ Dim = 50.8; Name = "2_inch" }, @{ Dim = 76.2; Name = "3_inch" },
    @{ Dim = 25.0; Name = "25_mm" }, @{ Dim = 28.0; Name = "28_mm" }, @{ Dim = 32.0; Name = "32_mm" },
    @{ Dim = 40.0; Name = "40_mm" }, @{ Dim = 50.0; Name = "50_mm" }, @{ Dim = 60.0; Name = "60_mm" },
    @{ Dim = 65.0; Name = "65_mm" }, @{ Dim = 70.0; Name = "70_mm" }, @{ Dim = 80.0; Name = "80_mm" },
    @{ Dim = 100.0; Name = "100_mm" }, @{ Dim = 130.0; Name = "130_mm" }, @{ Dim = 160.0; Name = "160_mm" }
)

function Get-Scaling($Area) {
    if ($Area -lt 800) { return @{ MagCount = 1; Ribs = 2 } }
    if ($Area -lt 2500) { return @{ MagCount = 2; Ribs = 2 } }
    if ($Area -lt 6000) { return @{ MagCount = 4; Ribs = 3 } }
    return @{ MagCount = 7; Ribs = 3 }
}

Write-Host "`n[PHASE 1] Rendering STLs..." -ForegroundColor Cyan
$stlFiles = @()

foreach ($size in $baseSizes) {
    $area = [Math]::PI * [Math]::Pow($size.Dim / 2, 2)
    $scaling = Get-Scaling $area
    $outputStl = Join-Path $TempStlDir "$($size.Name)_round_base_magnet.stl"
    
    $params = @(
        "-Duse_custom_size=true", "-Dcustom_size_mm=$($size.Dim)",
        "-Dbase_shape_index=0", "-Denable_magnet_pockets=true",
        "-Dmagnet_count=$($scaling.MagCount)", "-Dribs_per_pocket=$($scaling.Ribs)",
        "-Dmagnet_dim_a_mm=8.0", "-Dmagnet_thick_mm=2.0", "-Dglue_channels_enabled=true",
        '-D$fn=80'
    )

    Write-Host "Rendering: $($size.Name)..."
    & $OpenScadPath -o $outputStl $params $InputScad 2>&1 | Out-Null
    
    if (Test-Path $outputStl) { 
        $stlFiles += $outputStl 
        Write-Host "Success: $($size.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "FAILED: $($size.Name)" -ForegroundColor Red
    }
}

Write-Host "`n[PHASE 2] Assembling 3MF Project..." -ForegroundColor Cyan
$outputPath = Join-Path $OutputDir $Final3mf

# Call the Python project builder
$stlList = $stlFiles -join " "
python build_bambu_project.py $stlList --template $Template3mf --output $outputPath

Write-Host "`nSUCCESS! Batch created at: $outputPath" -ForegroundColor Green

# Cleanup
# Remove-Item $TempStlDir -Recurse -Force
