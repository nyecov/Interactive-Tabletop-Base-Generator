# Generate All Base Combinations (Expanded)
# Creates Round, Polygon (4,6,8), and Oval bases with/without magnets

param(
    [string]$OpenScadPath = "C:\Program Files\OpenSCAD\openscad.exe"
)

if (-not (Test-Path $OpenScadPath)) {
    Write-Host "ERROR: OpenSCAD not found at: $OpenScadPath" -ForegroundColor Red
    exit 1
}

$InputFile = "base_generator.scad"
$BaseOutputDir = "Generated_3mf"
$MagnetDir = Join-Path $BaseOutputDir "Magnet"
$NoMagnetDir = Join-Path $BaseOutputDir "No_Magnet"

# Create directories
@($MagnetDir, $NoMagnetDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ | Out-Null }
}

# Define base sizes for Round/Polygon
$baseSizes = @(
    @{ Dim = 25.4; Name = "1_inch" }, @{ Dim = 50.8; Name = "2_inch" }, @{ Dim = 76.2; Name = "3_inch" },
    @{ Dim = 25.0; Name = "25_mm" }, @{ Dim = 28.0; Name = "28_mm" }, @{ Dim = 32.0; Name = "32_mm" },
    @{ Dim = 40.0; Name = "40_mm" }, @{ Dim = 50.0; Name = "50_mm" }, @{ Dim = 60.0; Name = "60_mm" },
    @{ Dim = 65.0; Name = "65_mm" }, @{ Dim = 70.0; Name = "70_mm" }, @{ Dim = 80.0; Name = "80_mm" },
    @{ Dim = 100.0; Name = "100_mm" }, @{ Dim = 130.0; Name = "130_mm" }, @{ Dim = 160.0; Name = "160_mm" }
)

# Define oval presets
$ovalSizes = @(
    @{ L = 60; W = 35; Name = "60x35_mm" }, @{ L = 75; W = 42; Name = "75x42_mm" },
    @{ L = 90; W = 52; Name = "90x52_mm" }, @{ L = 105; W = 70; Name = "105x70_mm" },
    @{ L = 120; W = 92; Name = "120x92_mm" }, @{ L = 150; W = 95; Name = "150x95_mm" },
    @{ L = 170; W = 105; Name = "170x105_mm" }
)

$shapes = @(
    @{ Type = "Round"; Sides = 0; Index = 0 },
    @{ Type = "Polygon"; Sides = 4; Name = "square"; Index = 1 },
    @{ Type = "Polygon"; Sides = 6; Name = "hex"; Index = 1 },
    @{ Type = "Polygon"; Sides = 8; Name = "oct"; Index = 1 }
)

function Get-Scaling($Area) {
    if ($Area -lt 800) { return @{ MagCount = 1; Ribs = 2 } }
    if ($Area -lt 2500) { return @{ MagCount = 2; Ribs = 2 } }
    if ($Area -lt 6000) { return @{ MagCount = 4; Ribs = 3 } }
    return @{ MagCount = 7; Ribs = 3 }
}

$startTime = Get-Date
$successes = 0
$total = ($baseSizes.Count * $shapes.Count * 2) + ($ovalSizes.Count * 2)
$current = 0

# 1. Generate Round and Polygons
foreach ($size in $baseSizes) {
    foreach ($shape in $shapes) {
        # Area = n * a^2 * tan(180/n) for polygon, PI * r^2 for round
        $area = if ($shape.Sides -gt 0) { 
            $shape.Sides * [Math]::Pow($size.Dim / 2, 2) * [Math]::Tan([Math]::PI / $shape.Sides)
        }
        else { 
            [Math]::PI * [Math]::Pow($size.Dim / 2, 2) 
        }
        
        $scaling = Get-Scaling $area
        $shapeName = if ($shape.Name) { $shape.Name } else { $shape.Type.ToLower() }
        
        foreach ($withMagnet in @($true, $false)) {
            $current++
            $dir = if ($withMagnet) { $MagnetDir } else { $NoMagnetDir }
            $suffix = if ($withMagnet) { "_magnet" } else { "_no-mag" }
            $outputFile = Join-Path $dir "$($size.Name)_$($shapeName)_base$($suffix).3mf"
            
            $params = @(
                "-Duse_custom_size=true", "-Dcustom_size_mm=$($size.Dim)",
                "-Dbase_shape_index=$($shape.Index)", "-Denable_magnet_pockets=$($withMagnet.ToString().ToLower())",
                '-D$fn=80'
            )
            if ($shape.Sides -gt 0) { $params += "-Dpoly_sides=$($shape.Sides)" }
            if ($withMagnet) {
                $params += "-Dmagnet_count=$($scaling.MagCount)", "-Dribs_per_pocket=$($scaling.Ribs)"
                $params += "-Dmagnet_dim_a_mm=8.0", "-Dmagnet_thick_mm=2.0", "-Dglue_channels_enabled=true"
            }

            Write-Host "[$current/$total] Rendering: $outputFile" -ForegroundColor Cyan
            & $OpenScadPath -o $outputFile $params $InputFile *>&1 | Out-Null
            if ((Test-Path $outputFile) -and (Get-Item $outputFile).Length -gt 0) { $successes++ }
        }
    }
}

# 2. Generate Ovals
foreach ($oval in $ovalSizes) {
    $area = [Math]::PI * ($oval.L / 2) * ($oval.W / 2)
    $scaling = Get-Scaling $area
    
    foreach ($withMagnet in @($true, $false)) {
        $current++
        $dir = if ($withMagnet) { $MagnetDir } else { $NoMagnetDir }
        $suffix = if ($withMagnet) { "_magnet" } else { "_no-mag" }
        $outputFile = Join-Path $dir "$($oval.Name)_oval_base$($suffix).3mf"
        
        $params = @(
            "-Dbase_shape_index=2", "-Duse_custom_oval=true",
            "-Dcustom_oval_length_mm=$($oval.L)", "-Dcustom_oval_width_mm=$($oval.W)",
            "-Denable_magnet_pockets=$($withMagnet.ToString().ToLower())",
            '-D$fn=80'
        )
        if ($withMagnet) {
            $params += "-Dmagnet_count=$($scaling.MagCount)", "-Dribs_per_pocket=$($scaling.Ribs)"
            $params += "-Dmagnet_dim_a_mm=8.0", "-Dmagnet_thick_mm=2.0", "-Dglue_channels_enabled=true"
        }

        if (Test-Path $outputFile) {
            Write-Host "[$current/$total] Skipping (exists): $outputFile" -ForegroundColor Gray
            $successes++
            continue
        }
        Write-Host "[$current/$total] Rendering: $outputFile" -ForegroundColor Cyan
        & $OpenScadPath -o $outputFile $params $InputFile *>&1 | Out-Null
        if ((Test-Path $outputFile) -and (Get-Item $outputFile).Length -gt 0) { $successes++ }
    }
}

$duration = (Get-Date) - $startTime
Write-Host "`nComplete! Successful: $successes/$total in $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor Green

# --- PROJECT ASSEMBLY ---
Write-Host "`n[PROJECT ASSEMBLY] Compiling all bases into a single 3MF..." -ForegroundColor Cyan
powershell -ExecutionPolicy Bypass -File ".\assemble_project_3mf.ps1" -SourceFolder $OutputDir -OutputFilename "Interactive_Tabletop_Bases.3mf"
