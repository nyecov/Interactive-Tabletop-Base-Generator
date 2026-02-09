# Master Batch Generation for All Base Types
param(
    [string]$OpenScadPath = "C:\Program Files\OpenSCAD (Nightly)\openscad.exe",
    [bool]$UseManifold = $true
)

# $ErrorActionPreference = "Stop" # OpenSCAD logs can trigger false positives

$BaseDir = Get-Location
$GeneratedDir = Join-Path $BaseDir "generated files"
$InputScad = "base_generator.scad"
$Template3mf = "slicer_settings_reference.3mf"

# Ensure root directories exist
foreach ($sub in @("Magnet", "Bare")) {
    $path = Join-Path $GeneratedDir $sub
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
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
    @{ Type = "Round"; Sides = 0; Index = 0; BaseName = "RoundBase" },
    @{ Type = "Polygon"; Sides = 4; Name = "square"; Index = 1; BaseName = "SquareBase" },
    @{ Type = "Polygon"; Sides = 6; Name = "hex"; Index = 1; BaseName = "HexBase" },
    @{ Type = "Polygon"; Sides = 8; Name = "oct"; Index = 1; BaseName = "OctBase" }
)

function Get-Scaling($Area) {
    if ($Area -lt 800) { return @{ MagCount = 1; Ribs = 2 } }
    if ($Area -lt 2500) { return @{ MagCount = 2; Ribs = 2 } }
    if ($Area -lt 6000) { return @{ MagCount = 4; Ribs = 3 } }
    return @{ MagCount = 7; Ribs = 3 }
}

# --- PROCESS ROUND & POLYGON ---
foreach ($shape in $shapes) {
    foreach ($withMagnet in @($true, $false)) {
        $category = if ($withMagnet) { "Magnet" } else { "Bare" }
        $suffix = if ($withMagnet) { "_with_magnet" } else { "" }
        $batchName = "$($shape.BaseName)$($suffix).3mf"
        $targetPath = Join-Path $GeneratedDir "$category\$batchName"
        
        # Check if already done (Skip round magnet as we did it)
        if (Test-Path $targetPath) {
            Write-Host "Skipping $batchName (Already exists)" -ForegroundColor Gray
            continue
        }

        Write-Host "`n[Processing Batch: $batchName]" -ForegroundColor Cyan
        $tempStlDir = Join-Path $BaseDir "Temp_$($shape.BaseName)_$category"
        if (-not (Test-Path $tempStlDir)) { New-Item -ItemType Directory -Path $tempStlDir -Force | Out-Null }
        
        $stlFiles = @()

        foreach ($size in $baseSizes) {
            # Area calculation
            $area = if ($shape.Sides -gt 0) { 
                $shape.Sides * [Math]::Pow($size.Dim / 2, 2) * [Math]::Tan([Math]::PI / $shape.Sides)
            }
            else { 
                [Math]::PI * [Math]::Pow($size.Dim / 2, 2) 
            }
            
            $scaling = Get-Scaling $area
            $stlPath = Join-Path $tempStlDir "$($size.Name)_$($shape.Type.ToLower())$($suffix).stl"
            
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

            Write-Host "  Rendering: $($size.Name)..."
            $manifoldFlag = if ($UseManifold) { "--enable=manifold" } else { "" }
            & $OpenScadPath $manifoldFlag -o $stlPath $params $InputScad 2>&1 | Out-Null
            if (Test-Path $stlPath) { $stlFiles += $stlPath }
        }

        Write-Host "  Assembling 3MF..." -ForegroundColor Yellow
        python build_bambu_project.py $tempStlDir\ --template $Template3mf --output $targetPath
        Remove-Item $tempStlDir -Recurse -Force | Out-Null
    }
}

# --- PROCESS OVALS ---
foreach ($withMagnet in @($true, $false)) {
    $category = if ($withMagnet) { "Magnet" } else { "Bare" }
    $suffix = if ($withMagnet) { "_with_magnet" } else { "" }
    $batchName = "OvalBase$($suffix).3mf"
    $targetPath = Join-Path $GeneratedDir "$category\$batchName"
    
    if (Test-Path $targetPath) {
        Write-Host "Skipping $batchName (Already exists)" -ForegroundColor Gray
        continue
    }

    Write-Host "`n[Processing Batch: $batchName]" -ForegroundColor Cyan
    $tempStlDir = Join-Path $BaseDir "Temp_Oval_$category"
    if (-not (Test-Path $tempStlDir)) { New-Item -ItemType Directory -Path $tempStlDir -Force | Out-Null }
    
    $stlFiles = @()

    foreach ($oval in $ovalSizes) {
        $area = [Math]::PI * ($oval.L / 2) * ($oval.W / 2)
        $scaling = Get-Scaling $area
        $stlPath = Join-Path $tempStlDir "$($oval.Name)_oval$($suffix).stl"
        
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

        Write-Host "  Rendering: $($oval.Name)..."
        $manifoldFlag = if ($UseManifold) { "--enable=manifold" } else { "" }
        & $OpenScadPath $manifoldFlag -o $stlPath $params $InputScad 2>&1 | Out-Null
        if (Test-Path $stlPath) { $stlFiles += $stlPath }
    }

    Write-Host "  Assembling 3MF..." -ForegroundColor Yellow
    python build_bambu_project.py $tempStlDir\ --template $Template3mf --output $targetPath
    Remove-Item $tempStlDir -Recurse -Force | Out-Null
}

Write-Host "`nCOMPLETE! All batches generated in 'generated files/'" -ForegroundColor Green
