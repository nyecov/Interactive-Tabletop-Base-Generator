# Batch Generation / Automation Guide

This guide details how to use the Python-based automation system to generate 3D printable wargaming bases.
The system is designed to generate bases for two specific use cases: **Steel Rubber Sheets** and **Magnetic Sheets**, with optimized magnet counts for each.

## 🚀 Quick Start

1.  **Open Terminal** (PowerShell or Command Prompt).
2.  Navigate to the `batch_generator` directory:
    ```powershell
    cd "C:\Users\Furiosa\SCAD\batch_generator"
    ```
3.  Run the generation script:
    ```powershell
    python generate_batches.py
    ```

**What happens next?**
- The script reads settings from `batch_config.json`.
- It launches multiple OpenSCAD processes in parallel (using all CPU cores).
- It generates `.stl` files for every base size and magnet configuration.
- It assembles these STLs into **Bambu Studio 3MF** project files.
- **Output Location**: `../generated files/` (e.g., `C:\Users\Furiosa\SCAD\generated files`)

---

## 📂 Output Structure

The generated files are organized by **Sheet Type** and **Magnet Size**:

```text
generated files/
├── Bare/                       # Bases without magnet holes
│   ├── RoundBase.3mf
│   └── ...
├── Magnet_SteelRubber/         # Optimized for Steel Rubber Sheets
│   ├── Magnet_5x2mm/
│   │   ├── HexBase_Mag_5x2_SteelRubber.3mf
│   │   └── ...
│   ├── Magnet_6x2mm/
│   └── ...
└── Magnet_MagneticSheet/       # Optimized for Magnetic Sheets (More magnets)
    ├── Magnet_5x2mm/
    │   ├── OvalBase_Mag_5x2_MagneticSheet.3mf
    │   └── ...
    └── ...
```

---

## ⚙️ Configuration (`batch_config.json`)

All settings are stored in `batch_config.json` in the `batch_generator` folder.

### 1. General Settings
- **`openscad_path`**: Path to your OpenSCAD executable.
  - *Default*: `C:\Program Files\OpenSCAD (Nightly)\openscad.exe`
- **`cpu_cores`**: Number of threads to use. Set to `0` to auto-detect (uses all cores).

### 2. Rib Scaling
Controls how internal reinforcement ribs are generated based on the base's surface area.
```json
"rib_scaling": [
    {"area": 490, "ribs": 2, "thickness": 0.8},
    {"area": 2000, "ribs": 3, "thickness": 0.8},
    ...
]
```
- **`area`**: If base area > this value, use these settings.
- **`ribs`**: Number of ribs per magnet pocket.
- **`thickness`**: Thickness of the ribs (must be a multiple of nozzle size, e.g., 0.4mm).

### 3. Magnet Matrices
Defines the exact number of magnets for each base size, specific to the sheet type.

```json
"magnet_matrices": {
    "steel_rubber": {
        "name": "Steel Rubber Sheet",
        "file_suffix": "_SteelRubber",
        "rules": [
             { "Base": "25_mm_Round", "Counts": [1, 1, ...]},
             ...
        ]
    }
}
```
- **`rules`**: A list mapping Base Names to magnet counts.
- **`Counts`**: An array corresponding to the `magnet_sizes` list (e.g., index 0 = 5x2mm, index 1 = 6x2mm).
- **`0`**: Indicates a configuration should be skipped (e.g., magnet too big for base).

---

## 🛠️ Troubleshooting

**"FileNotFoundError: [Errno 2] No such file or directory..."**
- This usually means the script failed to create the output directory before saving.
- **Fix**: Ensure you have write permissions to the `generated files/` folder. The script has been updated to fix this, so ensure you are running the latest version.

**"Can't open input file 'base_generator.scad'!"**
- The script cannot find the OpenSCAD source file.
- **Fix**: Ensure `base_generator.scad` is in the same folder as `generate_batches.py` (or correctly referenced in the script).

**"Magnets overlap or are too close together!"**
- This is an OpenSCAD assertion error.
- **Cause**: You are trying to fit too many magnets into a small base (e.g., 12 magnets in a 25mm base).
- **Fix**: Update the `magnet_matrices` in `batch_config.json` to set the count to `0` for that specific size/magnet combo.

---

## 📝 Editing the Script

- **Script**: `batch_generator/generate_batches.py`
- **Logic**:
    1.  Loads config.
    2.  Iterates through `shapes` (Round, Square, Hex, Octagon) and `oval_sizes`.
    3.  Iterates through `magnet_matrices` (Steel Rubber, Magnetic Sheet).
    4.  Calculates parameters (Area, Ribs).
    5.  Renders STLs in parallel.
    6.  Zips STLs into `.3mf` files.

If you need to add a new shape, add it to the `shapes` list in `batch_config.json` first.
