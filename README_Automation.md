# OpenSCAD Automation Guide

This project uses **Python** and **OpenSCAD** to automate the generation of wargaming bases.

## Prerequisites

1.  **OpenSCAD**
    *   Download: [openscad.org](https://openscad.org/downloads.html)
    *   **Version requirement**: 2026.02.09 (Nightly) or newer for Manifold support.
    *   Default Path: `C:\Program Files\OpenSCAD (Nightly)\openscad.exe`
    *   *(If your path is different, update `generate_batches.py`)*

2.  **Python 3.6+**
    *   Required for running the build scripts.

## Usage

### 🚀 Generate All Batches
To generate all base sizes (Round, Square, Hex, Octagon, Oval) in both "Magnet" and "Bare" configurations:

```bash
cd batch_generator
python generate_batches.py
```

**What it does:**
1.  **Parallel Rendering**: Uses all CPU cores to render STLs with OpenSCAD.
2.  **Manifold Optimization**: Uses the `--enable=manifold` flag for high-speed rendering.
3.  **3MF Assembly**: Bundles the STLs into Bambu Studio project files (`.3mf`) with correct slicer settings.
4.  **Output**: Files are saved in the `generated files/` directory.

---

## ⚙️ Configuration (`batch_config.json`)

All batch generation settings are stored in `batch_config.json`. You can modify this file to:

-   **Change OpenSCAD Path**: Update `"openscad_path"` if your installation is different.
-   **Add New Base Sizes**: Add entries to `"base_sizes"` or `"oval_sizes"`.
-   **Tweak Magnet Logic**: Adjust `"scaling_thresholds"` to change when ribs/magnets are added based on area.
-   **Set CPU Cores**: Manually set `"cpu_cores"` (0 = Auto-detect).

Example `batch_config.json` snippet:
```json
{
    "base_sizes": [
        {"Dim": 120.0, "Name": "Giant_Base"}
    ],
    "scaling_thresholds": {
        "small": {"area": 800, "magnets": 1, "ribs": 3}
    }
}
```

---

## 🔧 Integration Details

The automation pipeline consists of:
1.  **`base_generator.scad`**: The core parametric design.
2.  **`generate_batches.py`**: The parallel process orchestrator.
3.  **`build_bambu_project.py`**: A helper module to construct valid `.3mf` files (bypassing the need for Bambu Studio to be installed).

For detailed parameter control, refer to [USER_CONTROLS.md](References/USER_CONTROLS.md).

---

## ⚠️ Legacy Automation (PowerShell)

The old PowerShell script is preserved as a fallback:

```powershell
.\generate_all_final_batches.ps1
```

**Note**: This script is single-threaded and significantly slower than the Python version. It is no longer actively maintained.

