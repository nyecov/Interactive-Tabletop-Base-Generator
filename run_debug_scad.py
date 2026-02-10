import subprocess
import os

OPENSCAD_BIN = r"C:\Program Files\OpenSCAD (Nightly)\openscad.exe"
SCAD_FILE = "debug_check.scad"
PARAMS = [
    "-D", "use_custom_size=true",
    "-D", "custom_size_mm=40.0",
    "-D", "enable_magnet_pockets=true",
    "-D", "magnet_count=2",
    "-D", "magnet_thick_mm=2.0",
    "-D", "magnet_dim_a_mm=8.0",
    "-D", "ribs_per_pocket=3",
    "-D", "glue_channels_enabled=true",
    "-o", "dummy.stl"
]

cmd = [OPENSCAD_BIN] + PARAMS + [SCAD_FILE]
print(f"Running: {cmd}")
try:
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    print("STDOUT:", result.stdout)
    print("STDERR:", result.stderr)
except subprocess.CalledProcessError as e:
    print("Error:", e)
    print("STDERR:", e.stderr)
