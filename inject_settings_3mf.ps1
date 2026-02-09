# Inject Bambu Studio Settings into 3MF Files
# Copies project_settings.config and slice_info.config into the 3MF Metadata folder.

param(
    [string]$TargetDir = ".\Generated_3mf",
    [string]$SourceConfigDir = ".\Assets\Bambu_Settings"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$files = Get-ChildItem -Path $TargetDir -Recurse -Filter "*.3mf"

foreach ($file in $files) {
    Write-Host "Injecting settings into $($file.Name)..." -NoNewline
    
    $tempDir = Join-Path $file.DirectoryName ("temp_inject_" + $file.BaseName)
    
    try {
        # Extract
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($file.FullName, $tempDir)
        
        # Ensure Metadata folder exists
        $metaDir = Join-Path $tempDir "Metadata"
        if (-not (Test-Path $metaDir)) { New-Item -ItemType Directory -Path $metaDir | Out-Null }
        
        # Copy Config Files
        Copy-Item (Join-Path $SourceConfigDir "project_settings.config") -Destination $metaDir -Force
        Copy-Item (Join-Path $SourceConfigDir "slice_info.config") -Destination $metaDir -Force
        
        # Check if [Content_Types].xml needs update (Bambu seems to rely on file presence, but good to check)
        # For now, we trust Bambu's implicit discovery.
        
        # Re-zip
        Remove-Item $file.FullName -Force
        [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $file.FullName)
        
        Write-Host " [OK]" -ForegroundColor Green
    }
    catch {
        Write-Host " [ERROR: $($_.Exception.Message)]" -ForegroundColor Red
    }
    finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }
}

Write-Host "Settings injection complete." -ForegroundColor Cyan
