#!/usr/bin/env python3
"""
Build a Bambu Studio 3MF project from a list of STL files using a template.
Handles dynamic multi-plate layouts (up to 36 plates) and custom slicer settings.
"""
import zipfile
import os
import re
import json
import uuid
import argparse
from pathlib import Path

# Constants for Bambu Studio / A1 Mini
PLATE_SPACING = 216
MAX_PLATES = 36

def parse_ascii_stl(stl_path):
    """Parse ASCII STL and return vertices and triangles."""
    content = Path(stl_path).read_text(errors='ignore')
    vertices = []
    triangles = []
    vertex_map = {}
    
    # Simple regex for facet/vertex parsing
    pattern = r'vertex\s+([\d.\-e+]+)\s+([\d.\-e+]+)\s+([\d.\-e+]+)'
    found_vertices = re.findall(pattern, content, re.IGNORECASE)
    
    for i in range(0, len(found_vertices), 3):
        v1, v2, v3 = found_vertices[i], found_vertices[i+1], found_vertices[i+2]
        indices = []
        for v in [v1, v2, v3]:
            key = f"{v[0]},{v[1]},{v[2]}"
            if key not in vertex_map:
                vertex_map[key] = len(vertices)
                vertices.append(v)
            indices.append(vertex_map[key])
        triangles.append(indices)
    
    return vertices, triangles

def get_sequential_uuid(index):
    """Generate a sequential UUID like 00000001-..."""
    suffix = "61cb-4c03-9d28-80fed5dfa1dc" # Fixed suffix for consistency
    return f"{index:08d}-{suffix}"

def generate_child_model(obj_id, vertices, triangles):
    mesh_uuid = str(uuid.uuid4())
    vertices_xml = "\n".join(f'     <vertex x="{v[0]}" y="{v[1]}" z="{v[2]}"/>' for v in vertices)
    triangles_xml = "\n".join(f'     <triangle v1="{t[0]}" v2="{t[1]}" v3="{t[2]}"/>' for t in triangles)
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
  <object id="{obj_id}" p:UUID="{mesh_uuid}" type="model">
   <mesh>
    <vertices>
{vertices_xml}
    </vertices>
    <triangles>
{triangles_xml}
    </triangles>
   </mesh>
  </object>
 </resources>
</model>'''

def generate_main_model(objects):
    resources = []
    build_items = []
    
    n = len(objects)
    # Dynamic grid logic: C = ceil(sqrt(n))
    cols = int(n**0.5 + 0.999) if n > 0 else 1
    
    for i, obj in enumerate(objects):
        wrapper_id = obj['wrapper_id']
        child_id = obj['child_id']
        child_path = obj['child_path']
        
        row = i // cols
        col = i % cols
        x_offset = 90 + (col * PLATE_SPACING)
        y_offset = 90 - (row * PLATE_SPACING)
        
        wrapper_uuid = get_sequential_uuid(i + 1)
        comp_uuid = f"{i+1:08d}-b206-40ff-9872-83e8017abed1"
        item_uuid = f"{i+1:08d}-b1ec-4553-aec9-835e5b724bb4"
        
        resources.append(f'''  <object id="{wrapper_id}" p:UUID="{wrapper_uuid}" type="model">
   <components>
    <component p:path="{child_path}" objectid="{child_id}" p:UUID="{comp_uuid}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>
   </components>
  </object>''')
        
        build_items.append(f'  <item objectid="{wrapper_id}" p:UUID="{item_uuid}" transform="1 0 0 0 1 0 0 0 1 {x_offset} {y_offset} 2" printable="1"/>')
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="Application">BambuStudio-02.05.00.66</metadata>
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
{chr(10).join(resources)}
 </resources>
 <build p:UUID="{uuid.uuid4()}">
{chr(10).join(build_items)}
 </build>
</model>'''

def generate_model_settings(objects):
    object_entries = []
    plate_entries = []
    assemble_items = []
    
    n = len(objects)
    cols = int(n**0.5 + 0.999) if n > 0 else 1
    
    for i, obj in enumerate(objects):
        wrapper_id = obj['wrapper_id']
        child_id = obj['child_id']
        name = obj['name']
        plate_id = i + 1
        
        object_entries.append(f'''  <object id="{wrapper_id}">
    <metadata key="name" value="{name}"/>
    <metadata key="extruder" value="1"/>
    <part id="{child_id}" subtype="normal_part">
      <metadata key="name" value="{name}"/>
      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>
      <metadata key="source_file" value="{name}.stl"/>
      <metadata key="source_offset_z" value="0"/>
    </part>
  </object>''')
        
        plate_entries.append(f'''  <plate>
    <metadata key="plater_id" value="{plate_id}"/>
    <metadata key="plater_name" value="{name}"/>
    <model_instance>
      <metadata key="object_id" value="{wrapper_id}"/>
      <metadata key="instance_id" value="0"/>
      <metadata key="identify_id" value="{100 + i}"/>
    </model_instance>
  </plate>''')
        
        row = i // cols
        col = i % cols
        x_offset = 90 + (col * PLATE_SPACING)
        y_offset = 90 - (row * PLATE_SPACING)
        
        assemble_items.append(f'   <assemble_item object_id="{wrapper_id}" instance_id="0" transform="1 0 0 0 1 0 0 0 1 {x_offset} {y_offset} 2" offset="0 0 0" />')
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<config>
{chr(10).join(object_entries)}
{chr(10).join(plate_entries)}
  <assemble>
{chr(10).join(assemble_items)}
  </assemble>
</config>'''.replace('&', '&amp;')

def build_3mf(stl_files, template_path, output_path):
    print(f"Building Bambu Project: {output_path}")
    print(f"Using template: {template_path}")
    
    objects = []
    child_models = {}
    
    # 1. Parse STL files
    for i, stl_file in enumerate(stl_files):
        if i >= MAX_PLATES:
            print(f"Warning: Reached maximum of {MAX_PLATES} plates. Skipping remaining files.")
            break
            
        child_id = i * 2 + 1
        wrapper_id = i * 2 + 2
        name = Path(stl_file).stem
        print(f"  [{i+1}/{len(stl_files)}] Processing: {name}")
        vertices, triangles = parse_ascii_stl(stl_file)
        child_path = f"3D/Objects/object_{i+1}.model"
        child_models[child_path] = generate_child_model(child_id, vertices, triangles)
        objects.append({
            'child_id': child_id, 
            'wrapper_id': wrapper_id, 
            'child_path': f"/{child_path}", 
            'name': name
        })

    # 2. Build ZIP
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        # 2a. Content Types
        content_types = '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
 <Default Extension="png" ContentType="image/png"/>
 <Default Extension="gcode" ContentType="text/x.gcode"/>
 <Default Extension="json" ContentType="application/json"/>
</Types>'''
        zf.writestr('[Content_Types].xml', content_types)
        
        # 2b. Root .rels
        root_rels = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>'''
        zf.writestr('_rels/.rels', root_rels)
        
        # 2c. Copy from template
        with zipfile.ZipFile(template_path, 'r') as tz:
            for item in tz.infolist():
                # Skip core files we generate ourselves
                if item.filename in ['3D/3dmodel.model', 'Metadata/model_settings.config', 'Metadata/filament_sequence.json', '[Content_Types].xml', '_rels/.rels']:
                    continue
                # Skip thumbnails as requested
                if 'Metadata/' in item.filename and item.filename.endswith('.png'):
                    continue
                
                content = tz.read(item.filename)
                zf.writestr(item.filename, content)
        
        # 2d. Add generated files
        zf.writestr('3D/3dmodel.model', generate_main_model(objects))
        zf.writestr('Metadata/model_settings.config', generate_model_settings(objects))
        
        # filament_sequence.json
        seq = {f"plate_{p}": {"sequence": []} for p in range(1, len(objects) + 1)}
        zf.writestr('Metadata/filament_sequence.json', json.dumps(seq))
        
        # Relationships for models
        rels = [f' <Relationship Target="{obj["child_path"]}" Id="rel-{i+1}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>' for i, obj in enumerate(objects)]
        rels_xml = f'<?xml version="1.0" encoding="UTF-8"?>\n<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n' + "\n".join(rels) + '\n</Relationships>'
        zf.writestr('3D/_rels/3dmodel.model.rels', rels_xml)
        
        for path, content in child_models.items():
            zf.writestr(path, content)

    print(f"\nDone! Project created at: {output_path}")

def main():
    parser = argparse.ArgumentParser(description="Assemble 3MF Bambu Project with custom settings.")
    parser.add_argument("input", nargs="+", help="One or more STL files or a directory containing STLs.")
    parser.add_argument("--template", default="custom_slicer_Settings_only.3mf", help="Template 3MF for settings.")
    parser.add_argument("--output", default="Bambu_Project.3mf", help="Output filename.")
    
    args = parser.parse_args()
    
    # Collect files
    stl_files = []
    for item in args.input:
        p = Path(item)
        if p.is_dir():
            stl_files.extend(sorted([str(f) for f in p.glob("*.stl")]))
        elif p.suffix.lower() == ".stl":
            stl_files.append(str(p))
            
    if not stl_files:
        print("No STL files found.")
        return

    build_3mf(stl_files, args.template, args.output)

if __name__ == "__main__":
    main()
