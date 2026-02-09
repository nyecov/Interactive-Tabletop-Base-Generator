<#
.SYNOPSIS
    Creates a 3MF with forward slash paths (OPC/3MF specification requirement)
#>
Add-Type -AssemblyName System.IO.Compression.FileSystem

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$BaseDir = Get-Location
$output = Join-Path $BaseDir "Minimal_ForwardSlash.3mf"

if (Test-Path $output) { Remove-Item $output -Force }

# Create new ZIP archive
$fileStream = [System.IO.File]::Create($output)
$zip = New-Object System.IO.Compression.ZipArchive($fileStream, [System.IO.Compression.ZipArchiveMode]::Create)

# Files to add with forward-slash paths
$filesToAdd = @(
    @{ ZipPath = "[Content_Types].xml"; LocalPath = "Analysis_NoBOM\[Content_Types].xml" }
    @{ ZipPath = "_rels/.rels"; LocalPath = "Analysis_NoBOM\_rels\.rels" }
    @{ ZipPath = "3D/3dmodel.model"; LocalPath = "Analysis_NoBOM\3D\3dmodel.model" }
    @{ ZipPath = "3D/_rels/3dmodel.model.rels"; LocalPath = "Analysis_NoBOM\3D\_rels\3dmodel.model.rels" }
    @{ ZipPath = "3D/Objects/object_1.model"; LocalPath = "Analysis_NoBOM\3D\Objects\object_1.model" }
)

foreach ($file in $filesToAdd) {
    $content = Get-Content -LiteralPath $file.LocalPath -Raw
    $entry = $zip.CreateEntry($file.ZipPath)
    $stream = $entry.Open()
    $bytes = $utf8NoBom.GetBytes($content)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Close()
    Write-Host "Added: $($file.ZipPath)"
}

$zip.Dispose()
$fileStream.Dispose()

# Verify
Write-Host "`n=== VERIFYING CREATED ENTRIES ===" -ForegroundColor Green
$verify = [System.IO.Compression.ZipFile]::OpenRead($output)
$verify.Entries | ForEach-Object { Write-Host $_.FullName }
$verify.Dispose()
Write-Host "`nDone! Created: $output"
