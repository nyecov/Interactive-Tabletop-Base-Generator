#!/usr/bin/env python3
"""
Master Batch Generator for Wargaming Bases
Standardizes generation on Python + OpenSCAD.
Supports parallel processing for faster generation.
"""

import os
import sys
import math
import shutil
import subprocess
import concurrent.futures
import json
from pathlib import Path
import time

# Import local module
try:
    import build_bambu_project
except ImportError:
    print("Error: build_bambu_project.py not found in current directory.")
    sys.exit(1)

# Default to local config if present
CONFIG_FILE = "batch_config.json"
GENERATED_DIR = Path("../generated files")

def load_config():
    """Load configuration from JSON file."""
    if not os.path.exists(CONFIG_FILE):
        print(f"CRITICAL: Config file '{CONFIG_FILE}' not found!")
        sys.exit(1)
        
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def ensure_dir(path):
    path = Path(path)
    if not path.exists():
        path.mkdir(parents=True, exist_ok=True)
    return path

def get_scaling(area, thresholds):
    """Determine magnet count and ribs based on surface area and config thresholds."""
    if area < thresholds['small']['area']:
        return {'MagCount': thresholds['small']['magnets'], 'Ribs': thresholds['small']['ribs']}
    if area < thresholds['medium']['area']:
        return {'MagCount': thresholds['medium']['magnets'], 'Ribs': thresholds['medium']['ribs']}
    if area < thresholds['large']['area']:
        return {'MagCount': thresholds['large']['magnets'], 'Ribs': thresholds['large']['ribs']}
    return {'MagCount': thresholds['huge']['magnets'], 'Ribs': thresholds['huge']['ribs']}

def render_stl(args):
    """Worker function to process a single STL generation."""
    output_path, params, name, openscad_bin, input_scad = args
    
    if output_path.exists():
        return None  # Skip existing
        
    cmd = [openscad_bin, "--enable=manifold", "-o", str(output_path)]
    
    # Add parameters
    for key, value in params.items():
        cmd.append("-D")
        # Handle string quoting for OpenSCAD
        if isinstance(value, str):
            cmd.append(f'{key}="{value}"')
        elif isinstance(value, bool):
            cmd.append(f'{key}={str(value).lower()}')
        else:
            cmd.append(f'{key}={value}')
            
    cmd.append(input_scad)
    
    # print(f"Rendering {name}...")
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        return str(output_path)
    except subprocess.CalledProcessError as e:
        print(f"Error rendering {name}: {e.stderr.decode()}")
        return None

def process_batch(batch_name, category, items_config, base_dir, config):
    """Process a full batch of items (Round/Polygon/Oval)."""
    target_dir = GENERATED_DIR / category
    ensure_dir(target_dir)
    final_3mf = target_dir / batch_name
    
    template_3mf = config.get('template_3mf', "slicer_settings_reference.3mf")
    if not os.path.exists(template_3mf):
        print(f"Warning: Template '{template_3mf}' not found. 3MF generation might fail.")

    if final_3mf.exists():
        print(f"Skipping batch {batch_name} (Already exists)")
        return

    print(f"\n[Processing Batch: {batch_name}]")
    temp_dir = base_dir / f"Temp_{final_3mf.stem}"
    ensure_dir(temp_dir)
    
    tasks = []
    
    for item in items_config:
        stl_name = f"{item['Name']}.stl"
        stl_path = temp_dir / stl_name
        
        # Calculate params
        params = item['Params'].copy()
        params['$fn'] = 80
        
        tasks.append((stl_path, params, item['Name'], config['openscad_path'], "base_generator.scad"))

    # Parallel Execution
    generated_stls = []
    cpu_cores = config.get('cpu_cores', 0)
    if cpu_cores <= 0:
        cpu_cores = os.cpu_count() or 4
        
    with concurrent.futures.ThreadPoolExecutor(max_workers=cpu_cores) as executor:
        futures = {executor.submit(render_stl, task): task[2] for task in tasks}
        
        for future in concurrent.futures.as_completed(futures):
            name = futures[future]
            try:
                result = future.result()
                if result:
                    print(f"  + Rendered: {name}")
                    generated_stls.append(result)
                else: 
                    pass
            except Exception as exc:
                print(f"  ! Exception for {name}: {exc}")

    # Re-verify all expected files exist (including skipped ones)
    valid_stls = sorted([str(temp_dir / f"{item['Name']}.stl") 
                         for item in items_config 
                         if (temp_dir / f"{item['Name']}.stl").exists()])
    
    if valid_stls:
        print(f"  Assembling {len(valid_stls)} files into 3MF...")
        build_bambu_project.build_3mf(valid_stls, template_3mf, str(final_3mf))
        print("  Cleaning up temp files...")
        shutil.rmtree(temp_dir)
    else:
        print("  No files generated for this batch.")

def main():
    config = load_config()
    
    openscad_bin = config.get('openscad_path', '')
    if not os.path.exists(openscad_bin):
        print(f"CRITICAL: OpenSCAD executable not found at: {openscad_bin}")
        print("Please check batch_config.json")
        return

    cpu_cores = config.get('cpu_cores', 0) or os.cpu_count()
    print(f"Starting Batch Generation using {cpu_cores} threads...")
    base_dir = Path.cwd()
    ensure_dir(GENERATED_DIR)
    
    thresholds = config['scaling_thresholds']
    base_sizes = config['base_sizes']
    oval_sizes = config['oval_sizes']
    shapes = config['shapes']
    
    # 1. Process Round & Polygons
    for shape in shapes:
        for with_magnet in [True, False]:
            category = "Magnet" if with_magnet else "Bare"
            suffix = "_with_magnet" if with_magnet else ""
            batch_name = f"{shape['BaseName']}{suffix}.3mf"
            
            items_config = []
            for size in base_sizes:
                # Area Calc
                if shape['Sides'] > 0:
                    area = shape['Sides'] * math.pow(size['Dim']/2, 2) * math.tan(math.pi / shape['Sides'])
                else:
                    area = math.pi * math.pow(size['Dim']/2, 2)
                    
                scaling = get_scaling(area, thresholds)
                
                params = {
                    'use_custom_size': True,
                    'custom_size_mm': size['Dim'],
                    'base_shape_index': shape['Index'],
                    'enable_magnet_pockets': with_magnet
                }
                
                if shape['Sides'] > 0:
                    params['poly_sides'] = shape['Sides']
                    
                if with_magnet:
                    params.update({
                        'magnet_count': scaling['MagCount'],
                        'ribs_per_pocket': scaling['Ribs'],
                        'magnet_dim_a_mm': 8.0,
                        'magnet_thick_mm': 2.0,
                        'glue_channels_enabled': True
                    })
                
                shape_name_part = f"_{shape['Name']}" if 'Name' in shape else f"_{shape['Type'].lower()}"
                
                items_config.append({
                    'Name': f"{size['Name']}{shape_name_part}{suffix}",
                    'Params': params
                })
                
            process_batch(batch_name, category, items_config, base_dir, config)

    # 2. Process Ovals
    for with_magnet in [True, False]:
        category = "Magnet" if with_magnet else "Bare"
        suffix = "_with_magnet" if with_magnet else ""
        batch_name = f"OvalBase{suffix}.3mf"
        
        items_config = []
        for oval in oval_sizes:
            area = math.pi * (oval['L']/2) * (oval['W']/2)
            scaling = get_scaling(area, thresholds)
            
            params = {
                'base_shape_index': 2,
                'use_custom_oval': True,
                'custom_oval_length_mm': oval['L'],
                'custom_oval_width_mm': oval['W'],
                'enable_magnet_pockets': with_magnet
            }
            
            if with_magnet:
                params.update({
                    'magnet_count': scaling['MagCount'],
                    'ribs_per_pocket': scaling['Ribs'],
                    'magnet_dim_a_mm': 8.0,
                    'magnet_thick_mm': 2.0,
                    'glue_channels_enabled': True
                })
                
            items_config.append({
                'Name': f"{oval['Name']}_oval{suffix}",
                'Params': params
            })
            
        process_batch(batch_name, category, items_config, base_dir, config)

    print("\nCOMPLETE! All batches generated in 'generated files/'")

if __name__ == "__main__":
    t0 = time.time()
    main()
    print(f"Total time: {time.time()-t0:.2f}s")
