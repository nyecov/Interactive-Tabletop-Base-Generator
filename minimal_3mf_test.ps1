<#
.SYNOPSIS
    Creates a minimal 3MF from a single STL - no slicer settings, no plates.
#>

param(
    [string]$StlPath = "minimal_test.stl",
    [string]$OutputFilename = "Minimal_Test.3mf"
)

$ErrorActionPreference = "Stop"

$BaseDir = Get-Location
$TempDir = Join-Path $BaseDir "TempMinimal"
$ModelDir = Join-Path $TempDir "3D"
$RelsDir = Join-Path $TempDir "_rels"

Write-Host "`n[MINIMAL 3MF ASSEMBLY]" -ForegroundColor Cyan

# Reset workspace
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $ModelDir -Force | Out-Null
New-Item -ItemType Directory -Path $RelsDir -Force | Out-Null

# Parse STL
Write-Host "Parsing: $StlPath"
$content = Get-Content $StlPath -Raw
$vertices = @()
$triangles = @()
$vertexMap = @{}

$facetPattern = 'facet normal\s+[\d\.\-e+]+\s+[\d\.\-e+]+\s+[\d\.\-e+]+\s+outer loop\s+(vertex\s+([\d\.\-e+]+)\s+([\d\.\-e+]+)\s+([\d\.\-e+]+)\s+)(vertex\s+([\d\.\-e+]+)\s+([\d\.\-e+]+)\s+([\d\.\-e+]+)\s+)(vertex\s+([\d\.\-e+]+)\s+([\d\.\-e+]+)\s+([\d\.\-e+]+)\s+)endloop\s+endfacet'

$matches = [regex]::Matches($content, $facetPattern)

foreach ($match in $matches) {
    $v1 = @($match.Groups[2].Value, $match.Groups[3].Value, $match.Groups[4].Value)
    $v2 = @($match.Groups[6].Value, $match.Groups[7].Value, $match.Groups[8].Value)
    $v3 = @($match.Groups[10].Value, $match.Groups[11].Value, $match.Groups[12].Value)
    
    $indices = @()
    foreach ($v in @($v1, $v2, $v3)) {
        $key = "$($v[0]),$($v[1]),$($v[2])"
        if (-not $vertexMap.ContainsKey($key)) {
            $vertexMap[$key] = $vertices.Count
            $vertices += , @([float]$v[0], [float]$v[1], [float]$v[2])
        }
        $indices += $vertexMap[$key]
    }
    $triangles += , @($indices[0], $indices[1], $indices[2])
}

Write-Host "Parsed: $($vertices.Count) vertices, $($triangles.Count) triangles" -ForegroundColor Yellow

# Build minimal 3dmodel.model (single object, no components)
$uuid = [guid]::NewGuid().ToString()
$buildUuid = [guid]::NewGuid().ToString()

$verticesXml = ""
foreach ($v in $vertices) {
    $verticesXml += "     <vertex x=""$($v[0])"" y=""$($v[1])"" z=""$($v[2])""/>`n"
}

$trianglesXml = ""
foreach ($t in $triangles) {
    $trianglesXml += "     <triangle v1=""$($t[0])"" v2=""$($t[1])"" v3=""$($t[2])""/>`n"
}

$modelXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
 <resources>
  <object id="1" type="model">
   <mesh>
    <vertices>
$verticesXml    </vertices>
    <triangles>
$trianglesXml    </triangles>
   </mesh>
  </object>
 </resources>
 <build>
  <item objectid="1" transform="1 0 0 0 1 0 0 0 1 90 90 0"/>
 </build>
</model>
"@

$ModelPath = Join-Path $ModelDir "3dmodel.model"
[System.IO.File]::WriteAllText($ModelPath, $modelXml, [System.Text.Encoding]::UTF8)

# Create [Content_Types].xml
$contentTypesXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
</Types>
"@
[System.IO.File]::WriteAllText("$TempDir\[Content_Types].xml", $contentTypesXml, [System.Text.Encoding]::UTF8)

# Create _rels/.rels
$relsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
"@
[System.IO.File]::WriteAllText("$RelsDir\.rels", $relsXml, [System.Text.Encoding]::UTF8)

# Package
$FinalOutput = Join-Path $BaseDir $OutputFilename
if (Test-Path $FinalOutput) { Remove-Item $FinalOutput -Force }

Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($TempDir, $FinalOutput)

Write-Host "`nSUCCESS! Created: $OutputFilename" -ForegroundColor Green

# Cleanup
Remove-Item $TempDir -Recurse -Force
