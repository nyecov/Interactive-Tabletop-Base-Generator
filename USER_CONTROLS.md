# Wargaming Base Generator - User Controls

This document details the various controls available in the OpenSCAD Customizer for the Wargaming Miniature Base Generator.

## 1. Base Configuration
These settings define the primary dimensions and overall look of the base.

| Control | Purpose |
| :--- | :--- |
| **Base Size Preset** | Select from standard tabletop sizes (e.g., 25mm, 40mm, 1 inch). Defaults to "40mm". |
| **Use Custom Size** | Toggle this to ignore presets and use the manual `Custom Size mm` value. |
| **Custom Size mm** | Specify a custom diameter or flat-to-flat width (for polygons). |
| **Base Height mm** | The total height of the base. Note: The script will automatically increase this if it's too thin for your magnet settings. |
| **Flare Angle** | The slope of the side walls. 0° is vertical. |
| **Min Outer Wall mm** | The minimum thickness of the wall between the magnets and the edge of the base. |
| **Bottom Chamfer mm** | Adds a 45° bevel to the bottom edge for easier removal from the print bed. |

---

## 2. Shape Details
Define the base's geometric shape.

| Control | Purpose |
| :--- | :--- |
| **Base Type** | Choose between **Round**, **Polygon**, or **Oval**. |
| **Poly Sides** | *Visible when Polygon is selected.* Set the number of sides (e.g., 3 for Triangle, 6 for Hexagon). |
| **Polygon Corner Radius mm** | Rounds the sharp corners of polygon bases. |
| **Oval Preset** | *Visible when Oval is selected.* Choose common oval sizes (e.g., 90x52mm). |
| **Use Custom Oval** | Toggle to manually set oval length/width. |
| **Custom Oval Length/Width mm** | Manually set dimensions for the oval's major and minor axes. |

---

## 3. Hollowing / Shelling
Optimize material usage by hollowing the base.

| Control | Purpose |
| :--- | :--- |
| **Enable Shelling** | Toggles the hollow interior. If enabled, the base is rendered upside down for easier printing. |
| **Shell Wall Thickness mm** | Thickness of the outer vertical walls. |
| **Shell Top Thickness mm** | Thickness of the top surface of the base. |
| **Reinforcement Layer mm** | Adds a solid layer under the top shell for extra durability (0 to disable). |
| **Enable Ribs** | Adds structural reinforcement ribs that connect the magnet pockets to the outer walls. |
| **Ribs Per Pocket** | The number of support ribs generated for each magnet pocket. |
| **Auto Rib Height** | Automatically sets ribs to 75% of the pocket depth for optimal support. |
| **Pillar Recess mm** | Offsets the magnet pillars from the bottom edge to ensure they sit flush within the shell cavity. Default set to **0.5mm**. |

---

## 4. Magnet System
Configure the placement and size of magnet pockets.

| Control | Purpose |
| :--- | :--- |
| **Enable Magnet Pockets** | Master toggle for all magnet features. |
| **Magnet Shape** | Choose **Round**, **Square**, or **Rectangular** pockets. Default is **Round**. |
| **Magnet Dim A/B** | Set the dimensions of the magnet. Diameter for Round, width/length for others. Default Diameter is **8.0mm**. |
| **Magnet Thick mm** | The depth of the magnet itself. Default is **2.0mm**. |
| **Magnet Tolerance mm** | Extra clearance added to the pocket for a perfect fit. |
| **Magnet Recess mm** | How deep the magnet sits from the bottom surface (prevents surface dragging). |
| **Magnet Count** | Number of magnets. 1 is centered. 2 is an axis pair. 3+ creates a ring. |
| **Auto Magnet Placement** | Automatically calculates the best distance for magnets based on base size. |

---

## 5. Glue Retention
Helps secure magnets by adding small grooves to hold glue.

| Control | Purpose |
| :--- | :--- |
| **Enable Glue Channels** | Adds helical (round) or slanted (square) grooves to the pocket walls. Now **Enabled by default**. |
| **Glue Channel Count** | Number of grooves per pocket. |
| **Channel Rotation Deg** | The "twist" or slant of the grooves. |
| **Channel Diameter mm** | The cross-section size of the glue channel. |

---

## 6. Model Quality
Control the detail and smoothness of the generated model.

| Control | Purpose |
| :--- | :--- |
| **Model Resolution** | Sets the `$fn` value. Higher values result in smoother curves but longer render times. |
