# OpenSCAD Base Generator - User Controls Reference

This document details every custom setting available in `base_generator.scad` and how to interact with them programmatically using PowerShell and Python.

## 1. Parameters Reference

All parameters can be set via the OpenSCAD Customizer GUI or passed via the command line using the `-D variable=value` flag.

### Base Configuration
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `base_size_preset` | String | `"40mm"` | Standard size preset. Options: "25mm", "32mm", "40mm", "50mm", etc. |
| `use_custom_size` | Bool | `false` | Enable to use `custom_size_mm` instead of the preset. |
| `custom_size_mm` | Float | `50.0` | Custom diameter/width in mm (ignored if `use_custom_size` is false). |
| `base_height_mm` | Float | `4.5` | Total height of the base. |
| `flare_angle` | Float | `15` | Angle of the side slope (degrees from vertical). |
| `min_outer_wall_mm` | Float | `2.0` | Minimum wall thickness between magnet pockets and the outer edge. |
| `bottom_chamfer_mm` | Float | `0.6` | Size of the 45° chamfer at the bottom edge. |

### Shape Details
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `base_type` | String | `"Round"` | Shape type. Options: `"Round"`, `"Polygon"`, `"Oval"`. |
| `poly_sides` | Int | `4` | Number of sides for Polygon bases. |
| `polygon_corner_radius_mm`| Float | `0.8` | Rounding radius for polygon corners. |
| `oval_preset` | String | `"90x52mm"`| Standard oval size preset. |
| `use_custom_oval` | Bool | `false` | Enable to use custom oval dimensions. |
| `custom_oval_length_mm` | Float | `90.0` | Oval length (major axis). |
| `custom_oval_width_mm` | Float | `52.0` | Oval width (minor axis). |
| `base_shape_index` | Int | `-1` | **Hidden CLI Override**. `0`=Round, `1`=Polygon, `2`=Oval. Useful for scripts where string parsing might be tricky. |

### Hollowing / Shelling
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `enable_shelling` | Bool | `true` | Hollow out the base to save material. |
| `shell_wall_thickness_mm` | Float | `2.0` | Thickness of the outer walls. |
| `shell_top_thickness_mm` | Float | `0.8` | Thickness of the top surface. |
| `reinforcement_layer_mm` | Float | `1.0` | Solid layer depth under the top surface for structural support. |
| `enable_ribs` | Bool | `true` | Enable structural ribs inside magnet pockets. |
| `rib_thickness_mm` | Float | `0.8` | Thickness of the ribs. |
| `ribs_per_pocket` | Int | `3` | Number of ribs per magnet pocket. |
| `auto_rib_height` | Bool | `true` | Automatically calculate rib height (75% of depth). |
| `rib_height_mm` | Float | `2.0` | Manual rib height (if auto is false). |
| `rib_length_mm` | Float | `0.0` | Manual rib length. `0` = auto-extend to wall. |
| `pillar_recess_mm` | Float | `0.5` | Recess depth for the magnet pillar structure from the bottom. |

### Magnet System
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `enable_magnet_pockets` | Bool | `true` | Master switch for magnet features. |
| `magnet_shape` | String | `"Round"` | Pocket shape. Options: `"Round"`, `"Square"`, `"Rectangular"`, `"None"`. |
| `magnet_dim_a_mm` | Float | `8.0` | Diameter (Round) or Side A (Square/Rect). |
| `magnet_dim_b_mm` | Float | `3.0` | Side B (Rectangular only). |
| `magnet_thick_mm` | Float | `2.0` | Depth of the magnet pocket. |
| `magnet_tolerance_mm` | Float | `0.1` | Extra clearance per side for fit. |
| `magnet_recess_mm` | Float | `0.2` | Depth the magnet sits *below* the bottom surface. |
| `magnet_count` | Int | `1` | Number of magnets (`1`, `2`, or `3+`). |
| `auto_magnet_placement` | Bool | `true` | Auto-calculate magnet positions based on base size. |
| `magnet_pair_distance_mm` | Float | `10.0` | Distance between centers (for 2 magnets) if auto is false. |
| `magnet_ring_radius_mm` | Float | `8.0` | Radius of magnet ring (for 3+ magnets) if auto is false. |

### Glue Retention
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `glue_channels_enabled` | Bool | `true` | Enable glue overflow channels in pockets. |
| `glue_channel_count` | Int | `4` | Number of channels per pocket. |
| `glue_channel_rotation_deg`| Float | `45` | Twist angle for helical channels. |
| `glue_channel_diameter_mm` | Float | `0.8` | Diameter of the channel groove. |

### Model Quality
| Variable | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `model_resolution` | Int | `100` | Smoothness ($fn). Higher is smoother but slower. Preview uses half this value. |

---

## 2. PowerShell Interaction
Use the call operator `&` to run the OpenSCAD executable. Passing string variables usually requires careful quoting.

### Basic Example
```powershell
$OpenSCAD = "C:\Program Files\OpenSCAD (Nightly)\openscad.exe"
$Output = "my_base.stl"

# Note: Strings inside -D must be quoted. In PowerShell, '"value"' works well.
& $OpenSCAD -o $Output `
    -D 'base_size_preset="50mm"' `
    -D 'magnet_count=2' `
    -D 'magnet_dim_a_mm=6.0' `
    base_generator.scad
```

### Advanced Batch Example
```powershell
$OpenSCAD = "C:\Program Files\OpenSCAD (Nightly)\openscad.exe"

$BatchSettings = @(
    @{ Name="Standard_32mm"; Size="32mm"; Magnets=1 },
    @{ Name="Hero_50mm"; Size="50mm"; Magnets=4 }
)

foreach ($Item in $BatchSettings) {
    Write-Host "Generating $($Item.Name)..."
    
    $ArgsList = @(
        "-o", "$($Item.Name).3mf",
        "-D", "base_size_preset=`"$($Item.Size)`"",     # Escaped inner quotes
        "-D", "magnet_count=$($Item.Magnets)",
        "--enable=manifold",                            # Enable fast rendering
        "base_generator.scad"
    )
    
    # Start-Process is cleaner for complex args than & operator
    Start-Process -FilePath $OpenSCAD -ArgumentList $ArgsList -Wait -NoNewWindow
}
```

---

## 3. Python Interaction
Use the `subprocess` module. This is generally preferred for complex automation pipelines.

### Basic Example
```python
import subprocess

openscad_bin = r"C:\Program Files\OpenSCAD (Nightly)\openscad.exe"
output_file = "python_generated_base.stl"

# Define overrides dictionary
overrides = {
    "base_type": '"Polygon"',   # Note the internal quotes for strings!
    "poly_sides": 6,
    "base_size_preset": '"60mm"',
    "magnet_count": 1
}

# Construct command args
cmd = [openscad_bin, "-o", output_file]

# Add Manifold flag for speed
cmd.append("--enable=manifold")

# Add overrides
for key, value in overrides.items():
    cmd.append("-D")
    cmd.append(f"{key}={value}")

cmd.append("base_generator.scad")

# Run
print(f"Running: {' '.join(cmd)}")
subprocess.run(cmd, check=True)
```

### Tips for Python
1.  **String Variables**: You must explicitly include quotes *inside* the string value for OpenSCAD string parameters.
    *   Correct: `'"Round"'` -> OpenSCAD sees `"Round"`
    *   Incorrect: `"Round"` -> OpenSCAD sees variable named `Round`
2.  **Booleans**: Python `True/False` must be converted to OpenSCAD `true/false` (lowercase string).
    *   `f"{key}={str(value).lower()}"`

