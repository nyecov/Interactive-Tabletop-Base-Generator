# 3MF Validated Reference Files

## User-Created Reference Files

These files were manually created/validated by the user for 3MF assembly development.

---

### Slicer Settings Template
| File | Purpose |
|------|---------|
| `custom_slicer_Settings_only.3mf` | Reference for custom slicer settings (empty project) |

**Configured Settings:** Wall Loops=4, Shell Layers=5/5, Infill=15% Grid, Top=Concentric, Arachne, Brim=5mm

> **Important:** These settings are configured as **global settings in Bambu Studio**. Every 3MF opened will use these settings automatically. Therefore, **generated 3MF files only need valid geometry - no embedded settings required.**

---

### Mesh Source
| File | Purpose |
|------|---------|
| `minimal_test.stl` | Source STL for testing 3MF assembly |

---

### Working 3MF References (Bambu Studio Exports)

These files contain **meshes with example slicer settings** (structure reference only - settings may differ from your requirements).

| File | Structure | Use Case |
|------|-----------|----------|
| `Minimal_Test.3mf` | Single object, single plate | Simplest working reference |
| `Testing standard_single_object_single_plate.3mf` | Single object, single plate | Object+settings binding structure |
| `Testing standard_multi_object_single_plate.3mf` | Multiple objects, single plate | Multi-object on one plate |
| `Testing standard_multi_object_multi_plate.3mf` | Multiple objects, multiple plates | Full multi-plate project |

> **Note:** Use these to understand XML structure and object bindings, but take `project_settings.config` from `custom_slicer_Settings_only.3mf` for your actual settings.

---

## Key Technical Findings

| Issue | Solution |
|-------|----------|
| ZIP paths use backslashes | Use Python `zipfile` (auto forward slashes) |
| UTF-8 BOM causes parsing failure | Use `UTF8Encoding($false)` in PowerShell |
| Missing relationships file | Add `3D/_rels/3dmodel.model.rels` |
| Settings not binding | ❓ Unresolved - `model_settings.config` needs proper object references |

---

## Analysis Directories
- `Analysis_MinRef/` → Extracted `minimal_reference.3mf`
- `Analysis_CustomTemplate/` → Extracted `custom_slicer_Settings_only.3mf`
- `Analysis_SingleRef/` → Extracted single object reference
