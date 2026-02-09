# Post-Process 3MF Files
# Updates the internal object name in 3MF files to match the filename.

param(
    [string]$TargetDir = ".\Generated_3mf"
)

# Ensure 7-Zip or internal zip is used (using .NET System.IO.Compression for speed)
Add-Type -AssemblyName System.IO.Compression.FileSystem

$files = Get-ChildItem -Path $TargetDir -Recurse -Filter "*.3mf"

foreach ($file in $files) {
    Write-Host "Processing $($file.Name)..." -NoNewline
    
    $tempDir = Join-Path $file.DirectoryName ("temp_" + $file.BaseName)
    $modelPath = Join-Path $tempDir "3D\3dmodel.model"
    
    try {
        # Extract
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
        [System.IO.Compression.ZipFile]::ExtractToDirectory($file.FullName, $tempDir)
        
        # Modify 3dmodel.model
        if (Test-Path $modelPath) {
            $xml = [xml](Get-Content $modelPath)
            $ns = @{ p = "http://schemas.microsoft.com/3dmanufacturing/production/2015/06" }
            
            # Find the object node. OpenSCAD usually creates one object.
            # We want to set the 'name' attribute on the <object> element.
            # Note: standard 3MF uses 'name' on <object>, usually under the build item or object definition.
            # Bambu Studio looks for <object name="..."> or <metadata name="Title">
            
            # Strategy: Update <metadata name="Title"> AND <object name="...">
            
            # 1. Update Title Metadata
            $titleNode = $xml.model.metadata | Where-Object { $_.name -eq "Title" }
            if ($titleNode) {
                $titleNode."#text" = $file.BaseName
            }
            else {
                $meta = $xml.CreateElement("metadata", "http://schemas.microsoft.com/3dmanufacturing/core/2015/02")
                $meta.SetAttribute("name", "Title")
                $meta.InnerText = $file.BaseName
                $xml.model.InsertBefore($meta, $xml.model.resources)
            }

            # 2. Update Object Name attribute
            $objects = $xml.model.resources.object
            foreach ($obj in $objects) {
                # Setup proper title case name with spaces for readability
                $cleanName = $file.BaseName -replace "_", " " 
                $obj.SetAttribute("name", $cleanName)
            }
            
            $xml.Save($modelPath)
            
            # Re-zip
            Remove-Item $file.FullName -Force
            [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $file.FullName)
            
            Write-Host " [OK]" -ForegroundColor Green
        }
        else {
            Write-Host " [SKIP - No Model]" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " [ERROR: $($_.Exception.Message)]" -ForegroundColor Red
    }
    finally {
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    }
}

Write-Host "Post-processing complete." -ForegroundColor Cyan
