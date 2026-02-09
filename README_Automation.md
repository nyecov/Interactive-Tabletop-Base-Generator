# OpenSCAD Automation Guide

This directory contains scripts to automate the rendering of OpenSCAD files without opening the GUI.

## Prerequisites

1. **Install OpenSCAD** (if not already installed):
   - Download from: https://openscad.org/downloads.html
   - Default installation path: `C:\Program Files\OpenSCAD\openscad.exe`

2. **Verify Installation**:
   ```powershell
   & "C:\Program Files\OpenSCAD\openscad.exe" --version
   ```

## Usage

### 1. Simple Rendering (`render.ps1`)

Renders the current `base_generator.scad` with its current parameter settings.

**Basic usage:**
```powershell
.\render.ps1
```

**Options:**
```powershell
# Render to a specific output name
.\render.ps1 -OutputName "my_base"

# Render only STL
.\render.ps1 -Format stl

# Render only 3MF
.\render.ps1 -Format 3mf

# Custom OpenSCAD path
.\render.ps1 -OpenScadPath "D:\Programs\OpenSCAD\openscad.exe"
```

### 2. Batch Preset Rendering (`render_presets.ps1`)

Renders multiple predefined configurations automatically.

**Usage:**
```powershell
.\render_presets.ps1
```

This will generate:
- `1inch_round_base.3mf`
- `1inch_round_base_with_magnet.3mf`
- `2inch_round_base.3mf`
- `2inch_round_base_with_magnets.3mf`
- `40mm_round_base.3mf`

**Customize presets:**
Edit `render_presets.ps1` and modify the `$presets` array to add your own configurations.

### 3. Command-Line Parameter Overrides

You can override any parameter directly from the command line:

```powershell
& "C:\Program Files\OpenSCAD\openscad.exe" `
  -o "custom_base.3mf" `
  -D base_size_preset='"40mm"' `
  -D base_height_mm=5.0 `
  -D enable_magnet_pockets=true `
  -D magnet_count=3 `
  base_generator.scad
```

**Important:** String parameters need double quotes escaped: `'"value"'`

## Advanced Options

### Render Quality

OpenSCAD uses `$fn` for resolution. You can override it:

```powershell
openscad -o output.stl -D '$fn=200' base_generator.scad
```

### Camera View (for PNG exports)

```powershell
openscad -o preview.png --camera=0,0,0,55,0,25,500 base_generator.scad
```

### Automatic Rendering on File Change

Create a file watcher (requires additional setup):

```powershell
# Install file watcher (one-time)
Install-Module -Name FileSystemWatcher

# Watch for changes
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "."
$watcher.Filter = "base_generator.scad"
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite

Register-ObjectEvent $watcher Changed -Action {
    Write-Host "File changed, re-rendering..."
    .\render.ps1
}
```

## Troubleshooting

### Script Execution Policy Error

If you get an execution policy error:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### OpenSCAD Not Found

If OpenSCAD is installed in a non-standard location, specify the path:

```powershell
.\render.ps1 -OpenScadPath "D:\YourPath\openscad.exe"
```

### Long Render Times

For complex models:
1. Reduce `$fn` value during testing
2. Use STL format (faster than 3MF)
3. Disable shelling/hollowing temporarily

## Integration with Build Systems

### Task Scheduler (Windows)

Create a scheduled task to render daily:

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-File C:\Users\Furiosa\SCAD\render.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName "Daily Base Render" -Action $action -Trigger $trigger
```

### Git Hook (Pre-commit)

Automatically render when committing:

Create `.git/hooks/pre-commit`:
```bash
#!/bin/sh
powershell.exe -File render.ps1
git add *.stl *.3mf
```

## Additional Resources

- [OpenSCAD User Manual](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual)
- [OpenSCAD Cheat Sheet](https://openscad.org/cheatsheet/)
- [Command-Line Options](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Using_OpenSCAD_in_a_command_line_environment)
