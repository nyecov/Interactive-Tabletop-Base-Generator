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
GENERATED_DIR = Path("../generated files").resolve()

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
        try:
            path.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            print(f"Error creating directory {path}: {e}")
    return path

def get_rib_specs(area, rib_scaling):
    """Determine rib count and thickness based on area."""
    # Default to smallest
    specs = {'Ribs': rib_scaling[0]['ribs'], 'Thick': rib_scaling[0]['thickness']}
    
    for rule in rib_scaling:
        if area >= rule['area']:
            specs = {'Ribs': rule['ribs'], 'Thick': rule['thickness']}
        else:
            break
            
    return specs

def get_magnet_count(base_name, area, matrix_rules):
    """
    Find magnet count. 
    1. Try exact name match.
    2. If not found, find rule with closest Area.
    """
    # 1. Exact Name Match
    for rule in matrix_rules:
        if rule.get('Base') == base_name:
            return rule['Counts']
    
    # 2. Area Fallback
    closest_rule = None
    min_diff = float('inf')
    
    for rule in matrix_rules:
        if 'Area' in rule:
            diff = abs(rule['Area'] - area)
            if diff < min_diff:
                min_diff = diff
                closest_rule = rule
    
    if closest_rule:
        # print(f"    (Fallback: {base_name} (Area {int(area)}) -> using {closest_rule['Base']} (Area {closest_rule['Area']}))")
        return closest_rule['Counts']

    return None

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

def process_batch(batch_name, category_path, items_config, base_dir, config):
    """Process a full batch of items."""
    target_dir = GENERATED_DIR / category_path
    ensure_dir(target_dir)
    final_3mf = target_dir / batch_name
    
    template_3mf = config.get('template_3mf', "slicer_settings_reference.3mf")
    if not os.path.exists(template_3mf):
        print(f"Warning: Template '{template_3mf}' not found. 3MF generation might fail.")

    if final_3mf.exists():
        print(f"Skipping batch {batch_name} (Already exists)")
        return

    print(f"\n[Processing Batch: {batch_name}]")
    temp_dir = base_dir / f"Temp_{final_3mf.stem}_{int(time.time())}" # Unique temp dir
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
        if temp_dir.exists():
            shutil.rmtree(temp_dir)

def generate_params(base_size, shape, is_oval=False):
    """Generate common SCAD parameters for a base."""
    params = {
        'use_custom_size': True,
        'enable_magnet_pockets': False # Default
    }

    if is_oval:
         params.update({
             'base_shape_index': 2,
             'use_custom_oval': True,
             'custom_oval_length_mm': base_size['L'],
             'custom_oval_width_mm': base_size['W']
         })
         area = math.pi * (base_size['L']/2) * (base_size['W']/2)
         base_key_name = f"{base_size['Name']}" 
    else:
        params['custom_size_mm'] = base_size['Dim']
        params['base_shape_index'] = shape['Index']
        if shape['Sides'] > 0:
            params['poly_sides'] = shape['Sides']
            area = shape['Sides'] * math.pow(base_size['Dim']/2, 2) * math.tan(math.pi / shape['Sides'])
        else:
            area = math.pi * math.pow(base_size['Dim']/2, 2)
        
        # Consistent naming for lookup keys
        if shape['Type'] == 'Round':
            base_key_name = f"{base_size['Name']}_Round"
        else:
             base_key_name = f"{base_size['Name']}_{shape['Name']}"

    return params, area, base_key_name

def main():
    config = load_config()
    
    openscad_bin = config.get('openscad_path', '')
    if not os.path.exists(openscad_bin):
        print(f"CRITICAL: OpenSCAD executable not found at: {openscad_bin}")
        return

    cpu_cores = config.get('cpu_cores', 0) or os.cpu_count()
    print(f"Starting Matrix Batch Generation using {cpu_cores} threads...")
    base_dir = Path.cwd()
    ensure_dir(GENERATED_DIR)
    
    magnet_matrices = config['magnet_matrices']
    rib_scaling = config['rib_scaling']
    base_sizes = config['base_sizes']
    oval_sizes = config['oval_sizes']
    shapes = config['shapes']

    # --- 1. GENERATE BARE BASES (No Magnets) ---
    print("\n--- Generating Bare Bases ---")
    for shape in shapes:
        category = "Bare"
        batch_name = f"{shape['BaseName']}.3mf"
        items_config = []
        
        for size in base_sizes:
            params, _, _ = generate_params(size, shape)
            params['enable_magnet_pockets'] = False
            
            shape_name_part = f"_{shape['Name']}" if 'Name' in shape else f"_{shape['Type'].lower()}"
            items_config.append({
                'Name': f"{size['Name']}{shape_name_part}",
                'Params': params
            })
        process_batch(batch_name, category, items_config, base_dir, config)

    # Bare Ovals
    batch_name = "OvalBase.3mf"
    items_config = []
    for oval in oval_sizes:
        params, _, _ = generate_params(oval, None, is_oval=True)
        params['enable_magnet_pockets'] = False
        items_config.append({
            'Name': f"{oval['Name']}_oval",
            'Params': params
        })
    process_batch(batch_name, "Bare", items_config, base_dir, config)


    # --- 2. GENERATE MAGNET MATRICES ---
    for sheet_key, sheet_data in magnet_matrices.items():
        sheet_name = sheet_data['name']
        folder_root = sheet_data['folder']
        magnet_sizes = sheet_data['magnet_sizes']
        rules = sheet_data['rules']
        file_suffix = sheet_data.get('file_suffix', '')

        print(f"\n--- Generating Matrix: {sheet_name} ---")

        # Iterate through each magnet size column (index 0 to N)
        for mag_idx, mag_dim in enumerate(magnet_sizes):
            mag_w = mag_dim['w']
            mag_h = mag_dim['h']
            folder_name = f"Magnet_{mag_w}x{mag_h}mm"
            full_category_path = f"{folder_root}/{folder_name}"
            
            # --- Round & Polygons ---
            for shape in shapes:
                batch_name = f"{shape['BaseName']}_Mag_{mag_w}x{mag_h}{file_suffix}.3mf"
                items_config = []
                
                for size in base_sizes:
                    params, area, key_name = generate_params(size, shape)
                    
                    # 1. Get Magnet Count from Matrix
                    counts = get_magnet_count(key_name, area, rules)
                    
                    # If base not found in matrix or count for this size is 0, SKIP
                    if not counts or mag_idx >= len(counts) or counts[mag_idx] == 0:
                        continue 
                    
                    magnet_count = counts[mag_idx]
                    
                    # 2. Get Rib Specs
                    rib_specs = get_rib_specs(area, rib_scaling)
                    
                    params.update({
                        'enable_magnet_pockets': True,
                        'magnet_count': magnet_count,
                        'ribs_per_pocket': rib_specs['Ribs'],
                        'rib_thickness_mm': rib_specs['Thick'],
                        'magnet_dim_a_mm': float(mag_w),
                        'magnet_thick_mm': float(mag_h),
                        'glue_channels_enabled': True
                    })
                    
                    shape_name_part = f"_{shape['Name']}" if 'Name' in shape else f"_{shape['Type'].lower()}"
                    items_config.append({
                        'Name': f"{size['Name']}{shape_name_part}_Mag{mag_w}x{mag_h}",
                        'Params': params
                    })
                
                if items_config:
                    process_batch(batch_name, full_category_path, items_config, base_dir, config)

            # --- Ovals ---
            batch_name = f"OvalBase_Mag_{mag_w}x{mag_h}{file_suffix}.3mf"
            items_config = []
            
            for oval in oval_sizes:
                params, area, _ = generate_params(oval, None, is_oval=True)
                key_name = f"{oval['Name']}_oval" # Explicitly match config "60x35_mm_oval"

                counts = get_magnet_count(key_name, area, rules)
                if not counts or mag_idx >= len(counts) or counts[mag_idx] == 0:
                    continue

                magnet_count = counts[mag_idx]
                rib_specs = get_rib_specs(area, rib_scaling)

                params.update({
                    'enable_magnet_pockets': True,
                    'magnet_count': magnet_count,
                    'ribs_per_pocket': rib_specs['Ribs'],
                    'rib_thickness_mm': rib_specs['Thick'],
                    'magnet_dim_a_mm': float(mag_w),
                    'magnet_thick_mm': float(mag_h),
                    'glue_channels_enabled': True
                })

                items_config.append({
                    'Name': f"{oval['Name']}_oval_Mag{mag_w}x{mag_h}",
                    'Params': params
                })
            
            if items_config:
                process_batch(batch_name, full_category_path, items_config, base_dir, config)

    print("\nCOMPLETE! All batches generated in 'generated files/'")

if __name__ == "__main__":
    t0 = time.time()
    main()
    print(f"Total time: {time.time()-t0:.2f}s")
