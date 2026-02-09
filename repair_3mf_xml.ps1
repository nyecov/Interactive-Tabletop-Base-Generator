# Repair 3MF XML
# Adds missing 'requiredextensions="p"' attribute to <model> tag.

param(
    [string]$TargetDir = ".\Generated_3mf"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

$files = Get-ChildItem -Path $TargetDir -Recurse -Filter "*.3mf"

foreach ($file in $files) {
    Write-Host "Repairing $($file.Name)..." -NoNewline
    
    $tempDir = Join-Path $file.DirectoryName ("temp_repair_" + $file.BaseName)
    $modelPath = Join-Path $tempDir "3D\3dmodel.model"
    
    try {
        # Extract
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($file.FullName, $tempDir)
        
        if (Test-Path $modelPath) {
            # Read as text to avoid XML parser stripping attributes again
            $content = Get-Content $modelPath -Raw
            
            # Regex replacement to add attribute if it's missing
            if ($content -notmatch 'requiredextensions="p"') {
                # Find the end of the <model tag (before the closing >)
                # We assume <model ... > is the first tag.
                # Regex looks for <model followed by attributes, ending with >
                
                $content = $content -replace '(<model[^>]*)(>)', '$1 requiredextensions="p"$2'
                
                Set-Content -Path $modelPath -Value $content -NoNewline
                
                # Re-zip
                Remove-Item $file.FullName -Force
                [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $file.FullName)
                
                Write-Host " [REPAIRED]" -ForegroundColor Green
            }
            else {
                Write-Host " [SKIP - Already OK]" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host " [ERROR: $($_.Exception.Message)]" -ForegroundColor Red
    }
    finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }
}
