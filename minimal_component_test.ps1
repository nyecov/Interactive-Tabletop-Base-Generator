<#
.SYNOPSIS
    Creates a 3MF using component-based architecture (matching Bambu Studio structure)
#>

param(
    [string]$StlPath = "minimal_test.stl",
    [string]$OutputFilename = "Minimal_Component.3mf"
)

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$BaseDir = Get-Location
$TempDir = Join-Path $BaseDir "TempMinimal"
$ModelDir = Join-Path $TempDir "3D"
$ObjectsDir = Join-Path $ModelDir "Objects"
$RelsDir = Join-Path $TempDir "_rels"
$ModelRelsDir = Join-Path $ModelDir "_rels"

Write-Host "`n[COMPONENT-BASED 3MF ASSEMBLY]" -ForegroundColor Cyan

# Reset workspace
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $ObjectsDir -Force | Out-Null
New-Item -ItemType Directory -Path $RelsDir -Force | Out-Null
New-Item -ItemType Directory -Path $ModelRelsDir -Force | Out-Null

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

# --- Create child model file (3D/Objects/object_1.model) ---
$meshUuid = [guid]::NewGuid().ToString()

$verticesXml = ""
foreach ($v in $vertices) {
    $verticesXml += "     <vertex x=""$($v[0])"" y=""$($v[1])"" z=""$($v[2])""/>`n"
}

$trianglesXml = ""
foreach ($t in $triangles) {
    $trianglesXml += "     <triangle v1=""$($t[0])"" v2=""$($t[1])"" v3=""$($t[2])""/>`n"
}

$childModelXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
  <object id="1" p:UUID="$meshUuid" type="model">
   <mesh>
    <vertices>
$verticesXml    </vertices>
    <triangles>
$trianglesXml    </triangles>
   </mesh>
  </object>
 </resources>
</model>
"@

$ChildModelPath = Join-Path $ObjectsDir "object_1.model"
[System.IO.File]::WriteAllText($ChildModelPath, $childModelXml, $utf8NoBom)

# --- Create main model file (3D/3dmodel.model) - references the child ---
$objUuid = [guid]::NewGuid().ToString()
$compUuid = [guid]::NewGuid().ToString()
$buildUuid = [guid]::NewGuid().ToString()
$itemUuid = [guid]::NewGuid().ToString()

$mainModelXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
  <object id="2" p:UUID="$objUuid" type="model">
   <components>
    <component p:path="/3D/Objects/object_1.model" objectid="1" p:UUID="$compUuid" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>
   </components>
  </object>
 </resources>
 <build p:UUID="$buildUuid">
  <item objectid="2" p:UUID="$itemUuid" transform="1 0 0 0 1 0 0 0 1 90 90 2" printable="1"/>
 </build>
</model>
"@

$MainModelPath = Join-Path $ModelDir "3dmodel.model"
[System.IO.File]::WriteAllText($MainModelPath, $mainModelXml, $utf8NoBom)

# --- Create 3D/_rels/3dmodel.model.rels ---
$modelRelsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/Objects/object_1.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
"@
[System.IO.File]::WriteAllText("$ModelRelsDir\3dmodel.model.rels", $modelRelsXml, $utf8NoBom)

# --- Create [Content_Types].xml ---
$contentTypesXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
</Types>
"@
[System.IO.File]::WriteAllText("$TempDir\[Content_Types].xml", $contentTypesXml, $utf8NoBom)

# --- Create _rels/.rels ---
$relsXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>
"@
[System.IO.File]::WriteAllText("$RelsDir\.rels", $relsXml, $utf8NoBom)

# --- Package ---
$FinalOutput = Join-Path $BaseDir $OutputFilename
if (Test-Path $FinalOutput) { Remove-Item $FinalOutput -Force }

Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($TempDir, $FinalOutput)

Write-Host "`nSUCCESS! Created: $OutputFilename" -ForegroundColor Green
Write-Host "Structure:"
Write-Host "  [Content_Types].xml"
Write-Host "  _rels/.rels"
Write-Host "  3D/3dmodel.model (component wrapper)"
Write-Host "  3D/Objects/object_1.model (actual mesh)"
Write-Host "  3D/_rels/3dmodel.model.rels"

# Cleanup
Remove-Item $TempDir -Recurse -Force
