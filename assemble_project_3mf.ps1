<#
.SYNOPSIS
    Assembles individual base meshes into a single multi-plate Bambu Studio 3MF project.
#>

param(
    [string]$SourceFolder = "Generated_3mf",
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
Write-Host "`n[3MF PROJECT ASSEMBLY]" -ForegroundColor Cyan
Write-Host "Scanning: $SourceFolder"

# --- Reset Temp Workspace ---
if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
New-Item -ItemType Directory -Path $ObjectsDir -Force | Out-Null
New-Item -ItemType Directory -Path $MetadataDir -Force | Out-Null
New-Item -ItemType Directory -Path $RelsDir -Force | Out-Null

# --- Gather All 3MF Files ---
# Note: We extract the individual .model files from the already rendered 3MFs to save time.
$Bases = Get-ChildItem -Path $SourceFolder -Recurse -Filter "*.3mf"
Write-Host "Found $($Bases.Count) unique bases." -ForegroundColor Yellow

# --- XML Initialization ---
$ModelXmlPath = Join-Path $ModelDir "3dmodel.model"
$ConfigXmlPath = Join-Path $MetadataDir "model_settings.config"

$ModelHeader = @"
<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="Application">BambuStudio-02.05.00.66</metadata>
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
    
    # 1. Component IDs
    $ObjId = $Idx * 2       # Slicer typically uses evens for components
    $PartId = $ObjId - 1    # and odds for parts
    $PlateId = $Idx
    $UUID_Obj = [guid]::NewGuid().ToString()
    $UUID_Part = [guid]::NewGuid().ToString()
    $UUID_Item = [guid]::NewGuid().ToString()
    
    # 2. Extract Mesh
    $ZipPath = Join-Path $BaseDir "temp_extract.zip"
    Copy-Item $Base.FullName -Destination $ZipPath -Force
    
    $ExtractPath = Join-Path $BaseDir "temp_mesh"
    if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force
    
    $MeshSource = Join-Path $ExtractPath "3D/3dmodel.model"
    $MeshDest = Join-Path $ObjectsDir "base_$Idx.model"
    
    # 2.1 Patch Child Model (add requiredextensions="p" if missing)
    $Content = Get-Content $MeshSource -Raw
    if ($Content -notmatch 'requiredextensions="p"') {
        $Content = $Content -replace '<model ', '<model requiredextensions="p" '
    }
    # Standardize namespaces for Bambu Studio
    if ($Content -notmatch 'xmlns:BambuStudio') {
        $Content = $Content -replace '<model ', '<model xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
    }
    # 2.2 Add BambuStudio:3mfVersion metadata (required for child model parsing)
    if ($Content -notmatch 'BambuStudio:3mfVersion') {
        $Content = $Content -replace '<resources>', "<metadata name=""BambuStudio:3mfVersion"">1</metadata>`n <resources>"
    }
    # 2.3 Rewrite object ID to match what the main manifest expects (PartId = 1, 3, 5, ...)
    # OpenSCAD always exports id="1", but Bambu Studio requires unique IDs per child model
    $Content = $Content -replace '<object id="1"', "<object id=""$PartId"""
    
    Set-Content -Path $MeshDest -Value $Content -Encoding UTF8
    
    Remove-Item $ZipPath -Force
    Remove-Item $ExtractPath -Recurse -Force
    
    # 3. Build XML Fragments
    $LocalX = 90
    $GlobalX = 90 + (($Idx - 1) * $OffsetStep)
    
    # model.model entries - reference the PartId in the child model
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

# --- Finalize XMLs ---
$FinalModel = $ModelHeader + "`n" + $ModelEntries + " </resources>`n <build p:UUID=""$([guid]::NewGuid().ToString())"">`n" + $BuildItems + " </build>`n</model>"
# Inject Bambu Studio metadata if not present
if ($FinalModel -notmatch "BambuStudio:3mfVersion") {
    $FinalModel = $FinalModel -replace '<metadata name="CreationDate">', "<metadata name=""BambuStudio:3mfVersion"">1</metadata>`n <metadata name=""CreationDate"">"
}

$FinalConfig = $ConfigHeader + "`n" + $ConfigModules + $PlateEntries + "  <assemble>`n" + $AssembleItems + "  </assemble>`n</config>"

[System.IO.File]::WriteAllText($ModelXmlPath, $FinalModel, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($ConfigXmlPath, $FinalConfig, [System.Text.Encoding]::UTF8)

# --- Generate 3D/_rels/3dmodel.model.rels (Critical for child model resolution) ---
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

# Use ZipFile to preserve structure. 3MF is just a renamed ZIP.
Add-Type -AssemblyName "System.IO.Compression.FileSystem"
[System.IO.Compression.ZipFile]::CreateFromDirectory($TempDir, $FinalOutput)

Write-Host "`nSUCCESS! All bases assembled into: $OutputFilename" -ForegroundColor Green
Write-Host "Total Plates: $($Bases.Count)" -ForegroundColor Cyan

# Cleanup
Remove-Item $TempDir -Recurse -Force
