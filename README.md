# Interactive Tabletop Bases (ITB)

**Professional 3D-printable miniature bases for wargaming and tabletop games.**

ITB is a parametric OpenSCAD script that generates customizable, magnet-ready bases for miniatures. Designed for hobbyists who want perfect-fit bases with advanced features like hollowing, reinforcement ribs, and glue retention channels.

---

## ✨ Features

- **🎯 Multiple Base Shapes**: Round, Polygon (3-20 sides), and Oval bases
- **📏 Imperial & Metric Presets**: 1", 2", 3", 25mm, 32mm, 40mm, 60mm, and more
- **🧲 Smart Magnet System**: Auto-placement for 1-12 magnets (Round, Square, Rectangular)
- **🏗️ Advanced Hollowing**: Adjustable shell thickness with structural reinforcement layer
- **💪 Reinforcement Ribs**: Customizable radial supports for magnet pockets
- **🎨 Glue Retention**: Helical channels for better magnet adhesion
- **⚡ Performance-Optimized**: Native sweeps and resolution capping for fast rendering
- **🛡️ Fail-Proof Design**: 24+ safety assertions prevent invalid configurations

---

## 🚀 Quick Start

### Prerequisites
- [OpenSCAD](https://openscad.org/downloads.html) (2021.01 or newer recommended)

### Usage
1. Download `base_generator.scad`
2. Open it in OpenSCAD
3. Adjust parameters in the **Customizer** panel (Window → Customizer)
4. Press **F5** to preview, **F6** to render
5. Export as STL: File → Export → Export as STL

---

## 📐 Parameter Guide

### Base Configuration
- **Base Size Preset**: Choose from standard wargaming sizes (25mm-160mm, 1"-3")
- **Base Height**: Thickness of the base (auto-adjusts for magnet depth)
- **Flare Angle**: Side slope (0° = straight, 15° = gentle taper)
- **Bottom Chamfer**: 45° bevel on the bottom edge for print quality

### Shape Details
- **Base Type**: Round, Polygon, or Oval
- **Polygon Sides**: 3-20 sides for custom shapes
- **Corner Rounding**: Soften polygon corners (0 = sharp)

### Magnet System
- **Magnet Shape**: Round, Square, or Rectangular
- **Magnet Count**: 1-12 magnets with auto-placement
- **Tolerance**: Clearance for easy magnet insertion (default: 0.1mm)

### Shelling & Reinforcement
- **Enable Shelling**: Hollow out the base to save material
- **Shell Wall/Top Thickness**: Adjustable structural walls
- **Reinforcement Layer**: Extra structural layer under top surface
- **Ribs Per Pocket**: Radial supports extending from magnets to outer walls

---

## 🎓 Examples

### 40mm Round Base (Standard)
- Base: 40mm Round
- Height: 4mm
- Magnet: 6mm Round x 2.7mm
- Shelling: Enabled (2mm walls, 0.8mm top)

### 60mm Hexagonal Base
- Base: 60mm Polygon (6 sides)
- Flare: 15°
- Magnets: 3x 6mm Round (auto-ring placement)
- Ribs: 2 per pocket

### 90x52mm Oval Cavalry Base
- Base: 90x52mm Oval
- Height: 5mm
- Magnets: 2x 6mm Round (axis placement)
- Glue Channels: Enabled (helical)

---

## 🔧 Technical Details

### Architecture
- **Layered Construction**: Two-stage additive geometry (Chamfer + Flare) ensures perfect vertex alignment for all polygon types
- **Dynamic Height**: Auto-corrects base thickness to accommodate shell + magnet + recesses
- **Keepout Zones**: Preserves magnet pocket integrity during hollowing

### Performance
- **Native Extrusion**: Glue channels use `linear_extrude(twist=...)` for 10-50x faster rendering
- **Resolution Capping**: Small features capped at `$fn=12` to prevent polygon explosion
- **Efficient CSG**: Additive layering is optimized for OpenSCAD's boolean engine

---

## 📦 Project Structure

```
ITB/
├── base_generator.scad      # Main OpenSCAD script
├── OpenSCAD_Cheatsheet.md   # Quick reference for OpenSCAD syntax
├── 2inch round base.stl     # Example STL output
└── README.md                # This file
```

---

## 🤝 Contributing

This project is designed for the wargaming and 3D printing community. If you have suggestions, improvements, or find bugs, feel free to open an issue or submit a pull request!

---

## 📄 License

This project is released under the **MIT License**. You are free to use, modify, and distribute this script for personal or commercial projects.

---

## 🙏 Acknowledgments

Built with precision for the tabletop gaming community. Optimized for FDM and resin printers.

**Happy Printing!** 🎲🖨️
