<#
.SYNOPSIS
    Assembles STL files into a single multi-plate Bambu Studio 3MF project.
    This approach bypasses OpenSCAD's 3MF export and generates Bambu-compatible model files.
#>

param(
    [string]$SourceFolder = "Generated_stl",
    [string]$OutputFilename = "Interactive_Tabletop_Bases.3mf"
)

$ErrorActionPreference = "Stop"

# --- Constants & Paths ---
$BaseDir = Get-Location
$TempDir = Join-Path $BaseDir "TempAssemble"
$AssetsDir = Join-Path $BaseDir "Assets\Bambu_Settings"
$ModelDir = Join-Path $TempDir "3D"
$ObjectsDir = Join-Path $ModelDir "Objects"
$MetadataDir = Join-Path $TempDir "Metadata"
$RelsDir = Join-Path $TempDir "_rels"

$BedWidth = 180
$Gap = 36
$OffsetStep = $BedWidth + $Gap

# --- UI Header ---
Write-Host "`n[3MF PROJECT ASSEMBLY - STL MODE]" -ForegroundColor Cyan
Write-Host "Scanning: $SourceFolder"

# --- Reset Temp Workspace ---
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $ObjectsDir -Force | Out-Null
New-Item -ItemType Directory -Path $MetadataDir -Force | Out-Null
New-Item -ItemType Directory -Path $RelsDir -Force | Out-Null

# --- Function: Convert ASCII STL to 3MF model XML ---
function Convert-STLTo3MF {
    param(
        [string]$StlPath,
        [int]$ObjectId,
        [string]$OutputPath
    )
    
    $content = Get-Content $StlPath -Raw
    $vertices = @()
    $triangles = @()
    $vertexMap = @{}
    
    # Parse ASCII STL
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
    
    Write-Host "  Parsed: $($vertices.Count) vertices, $($triangles.Count) triangles"
    
    # Generate 3MF model XML (matching Bambu Studio format)
    $uuid = [guid]::NewGuid().ToString()
    $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
  <object id="$ObjectId" p:UUID="$uuid" type="model">
   <mesh>
    <vertices>
"@
    
    foreach ($v in $vertices) {
        $xml += "     <vertex x=""$($v[0])"" y=""$($v[1])"" z=""$($v[2])""/>`n"
    }
    
    $xml += @"
    </vertices>
    <triangles>
"@
    
    foreach ($t in $triangles) {
        $xml += "     <triangle v1=""$($t[0])"" v2=""$($t[1])"" v3=""$($t[2])""/>`n"
    }
    
    $xml += @"
    </triangles>
   </mesh>
  </object>
 </resources>
</model>
"@
    
    [System.IO.File]::WriteAllText($OutputPath, $xml, [System.Text.Encoding]::UTF8)
}

# --- Gather All STL Files ---
$Bases = Get-ChildItem -Path $SourceFolder -Recurse -Filter "*.stl"
Write-Host "Found $($Bases.Count) STL files." -ForegroundColor Yellow

if ($Bases.Count -eq 0) {
    Write-Host "ERROR: No STL files found in $SourceFolder" -ForegroundColor Red
    exit 1
}

# --- XML Initialization ---
$ModelXmlPath = Join-Path $ModelDir "3dmodel.model"
$ConfigXmlPath = Join-Path $MetadataDir "model_settings.config"

$ModelHeader = @"
<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="Application">BambuStudio-02.05.00.66</metadata>
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <metadata name="CreationDate">$(Get-Date -Format "yyyy-MM-dd")</metadata>
 <resources>
"@

$ConfigHeader = @"
<?xml version="1.0" encoding="UTF-8"?>
<config>
"@

$ModelEntries = ""
$BuildItems = ""
$ConfigModules = ""
$PlateEntries = ""
$AssembleItems = ""

$Idx = 1
foreach ($Base in $Bases) {
    $Name = $Base.BaseName
    Write-Host "Processing [$Idx/$($Bases.Count)]: $Name"
    
    # Component IDs (odds for child objects, evens for wrapper objects)
    $ObjId = $Idx * 2       
    $PartId = $ObjId - 1    
    $PlateId = $Idx
    $UUID_Obj = [guid]::NewGuid().ToString()
    $UUID_Part = [guid]::NewGuid().ToString()
    $UUID_Item = [guid]::NewGuid().ToString()
    
    # Convert STL to 3MF model
    $MeshDest = Join-Path $ObjectsDir "base_$Idx.model"
    Convert-STLTo3MF -StlPath $Base.FullName -ObjectId $PartId -OutputPath $MeshDest
    
    # Build XML Fragments
    $LocalX = 90
    $GlobalX = 90 + (($Idx - 1) * $OffsetStep)
    
    # model.model entries
    $ModelEntries += "  <object id=""$ObjId"" p:UUID=""$UUID_Obj"" type=""model"">`n"
    $ModelEntries += "   <components>`n"
    $ModelEntries += "    <component p:path=""/3D/Objects/base_$Idx.model"" objectid=""$PartId"" p:UUID=""$UUID_Part"" transform=""1 0 0 0 1 0 0 0 1 0 0 0""/>`n"
    $ModelEntries += "   </components>`n"
    $ModelEntries += "  </object>`n"
    
    $BuildItems += "  <item objectid=""$ObjId"" p:UUID=""$UUID_Item"" transform=""1 0 0 0 1 0 0 0 1 $GlobalX 90 2"" printable=""1""/>`n"
    
    # model_settings.config entries
    $ConfigModules += "  <object id=""$ObjId"">`n"
    $ConfigModules += "    <metadata key=""name"" value=""$Name""/>`n"
    $ConfigModules += "    <metadata key=""extruder"" value=""1""/>`n"
    $ConfigModules += "    <part id=""$PartId"" subtype=""normal_part"">`n"
    $ConfigModules += "      <metadata key=""name"" value=""$Name""/>`n"
    $ConfigModules += "    </part>`n"
    $ConfigModules += "  </object>`n"
    
    $PlateEntries += "  <plate>`n"
    $PlateEntries += "    <metadata key=""plater_id"" value=""$PlateId""/>`n"
    $PlateEntries += "    <metadata key=""plater_name"" value=""$Name""/>`n"
    $PlateEntries += "    <model_instance>`n"
    $PlateEntries += "      <metadata key=""object_id"" value=""$ObjId""/>`n"
    $PlateEntries += "      <metadata key=""instance_id"" value=""0""/>`n"
    $PlateEntries += "    </model_instance>`n"
    $PlateEntries += "  </plate>`n"
    
    $AssembleItems += "   <assemble_item object_id=""$ObjId"" instance_id=""0"" transform=""1 0 0 0 1 0 0 0 1 $LocalX 90 2"" offset=""0 0 0"" />`n"
    
    $Idx++
}

# --- Finalize Main Model XML ---
$FinalModel = $ModelHeader + "`n" + $ModelEntries + " </resources>`n <build p:UUID=""$([guid]::NewGuid().ToString())"">`n" + $BuildItems + " </build>`n</model>"
$FinalConfig = $ConfigHeader + "`n" + $ConfigModules + $PlateEntries + "  <assemble>`n" + $AssembleItems + "  </assemble>`n</config>"

[System.IO.File]::WriteAllText($ModelXmlPath, $FinalModel, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($ConfigXmlPath, $FinalConfig, [System.Text.Encoding]::UTF8)

# --- Generate 3D/_rels/3dmodel.model.rels ---
$ModelRelsDir = Join-Path $ModelDir "_rels"
New-Item -ItemType Directory -Path $ModelRelsDir -Force | Out-Null

$RelsHeader = @"
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
"@
$RelsEntries = ""
for ($i = 1; $i -lt $Idx; $i++) {
    $RelsEntries += " <Relationship Target=""/3D/Objects/base_$i.model"" Id=""rel-$i"" Type=""http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel""/>`n"
}
$FinalRels = $RelsHeader + "`n" + $RelsEntries + "</Relationships>"

$ModelRelsPath = Join-Path $ModelRelsDir "3dmodel.model.rels"
[System.IO.File]::WriteAllText($ModelRelsPath, $FinalRels, [System.Text.Encoding]::UTF8)

# --- Copy Boilers & Settings ---
Copy-Item -LiteralPath "$AssetsDir\[Content_Types].xml" -Destination "$TempDir\[Content_Types].xml" -Force
Copy-Item "$AssetsDir\_rels\.rels" -Destination $RelsDir -Force
Copy-Item "$AssetsDir\project_settings.config" -Destination $MetadataDir -Force
Copy-Item "$AssetsDir\slice_info.config" -Destination $MetadataDir -Force

# --- Packaging ---
$FinalOutput = Join-Path $BaseDir $OutputFilename
if (Test-Path $FinalOutput) { Remove-Item $FinalOutput -Force }

Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($TempDir, $FinalOutput)

Write-Host "`nSUCCESS! All bases assembled into: $OutputFilename" -ForegroundColor Green
Write-Host "Total Plates: $($Bases.Count)" -ForegroundColor Cyan

# Cleanup
Remove-Item $TempDir -Recurse -Force
