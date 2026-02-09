# Batch Rendering Script - Generate multiple presets automatically
# This script renders common base configurations

param(
    [string]$OpenScadPath = "C:\Program Files\OpenSCAD\openscad.exe"
)

# Check if OpenSCAD exists
if (-not (Test-Path $OpenScadPath)) {
    Write-Host "ERROR: OpenSCAD not found at: $OpenScadPath" -ForegroundColor Red
    Write-Host "Please install OpenSCAD or specify the correct path with -OpenScadPath" -ForegroundColor Yellow
    exit 1
}

$InputFile = "base_generator.scad"

# Define presets as hashtables with parameter overrides
$presets = @(
    @{
        Name   = "1inch_round_base"
        Params = @{
            base_size_preset      = '"1 inch"'
            base_type             = '"Round"'
            enable_magnet_pockets = 'false'
        }
    },
    @{
        Name   = "1inch_round_base_with_magnet"
        Params = @{
            base_size_preset      = '"1 inch"'
            base_type             = '"Round"'
            enable_magnet_pockets = 'true'
            magnet_count          = '1'
        }
    },
    @{
        Name   = "2inch_round_base"
        Params = @{
            base_size_preset      = '"2 inch"'
            base_type             = '"Round"'
            enable_magnet_pockets = 'false'
        }
    },
    @{
        Name   = "2inch_round_base_with_magnets"
        Params = @{
            base_size_preset      = '"2 inch"'
            base_type             = '"Round"'
            enable_magnet_pockets = 'true'
            magnet_count          = '3'
        }
    },
    @{
        Name   = "40mm_round_base"
        Params = @{
            base_size_preset      = '"40mm"'
            base_type             = '"Round"'
            enable_magnet_pockets = 'true'
            magnet_count          = '1'
        }
    }
)

Write-Host "Batch rendering $($presets.Count) presets..." -ForegroundColor Green
Write-Host "=" * 60

foreach ($preset in $presets) {
    Write-Host "`nRendering: $($preset.Name)" -ForegroundColor Cyan
    
    # Build parameter override string
    $paramString = ""
    foreach ($key in $preset.Params.Keys) {
        $value = $preset.Params[$key]
        $paramString += " -D $key=$value"
    }
    
    # Render to 3MF
    $outputFile = "$($preset.Name).3mf"
    $command = "& `"$OpenScadPath`" -o `"$outputFile`" $paramString `"$InputFile`""
    
    Write-Host "  Executing: openscad -o $outputFile $paramString $InputFile" -ForegroundColor DarkGray
    Invoke-Expression $command
    
    if ($LASTEXITCODE -eq 0) {
        $fileSize = (Get-Item $outputFile).Length
        $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
        Write-Host "  ✓ Success: $outputFile ($fileSizeKB KB)" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Failed: $outputFile" -ForegroundColor Red
    }
}

Write-Host "`n" + "=" * 60
Write-Host "Batch rendering complete!" -ForegroundColor Green
