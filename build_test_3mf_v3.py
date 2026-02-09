#!/usr/bin/env python3
"""
Build a test 3MF with 3 objects on separate plates using a template 3MF.
Usage: python build_test_3mf_v3.py
"""
import zipfile
import os
import re
import json
import uuid
from pathlib import Path

# Configuration
STL_FILES = [
    "minimal_test.stl", "test_4.stl", "test_poly.stl",
    "minimal_test.stl", "test_4.stl", "test_poly.stl",
    "minimal_test.stl", "test_4.stl", "test_poly.stl",
    "minimal_test.stl", "test_4.stl", "test_poly.stl",
    "minimal_test.stl"
]
OUTPUT_FILE = "Test_13Objects_Surgical.3mf"
TEMPLATE_3MF = "custom_slicer_Settings_only.3mf"
PLATE_SPACING = 216

def get_sequential_uuid(index, type_prefix="00000000"):
    """Generate a sequential UUID like 00000001-..."""
    suffix = "61cb-4c03-9d28-80fed5dfa1dc"
    return f"{index:08d}-{suffix}"

def get_comp_uuid(index):
    suffix = "b206-40ff-9872-83e8017abed1"
    return f"{index:08d}-{suffix}"

def get_item_uuid(index):
    suffix = "b1ec-4553-aec9-835e5b724bb4"
    return f"{index:08d}-{suffix}"

def parse_ascii_stl(stl_path):
    """Parse ASCII STL and return vertices and triangles."""
    content = Path(stl_path).read_text()
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
        comp_uuid = get_comp_uuid(i + 1)
        
        resources.append(f'''  <object id="{wrapper_id}" p:UUID="{wrapper_uuid}" type="model">
   <components>
    <component p:path="{child_path}" objectid="{child_id}" p:UUID="{comp_uuid}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>
   </components>
  </object>''')
        
        build_items.append(f'  <item objectid="{wrapper_id}" p:UUID="{get_item_uuid(i + 1)}" transform="1 0 0 0 1 0 0 0 1 {x_offset} {y_offset} 2" printable="1"/>')
    
    build_uuid = str(uuid.uuid4())
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="Application">BambuStudio-02.05.00.66</metadata>
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <metadata name="Thumbnail_Middle">/Metadata/plate_1.png</metadata>
 <metadata name="Thumbnail_Small">/Metadata/plate_1_small.png</metadata>
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
      <metadata key="source_object_id" value="0"/>
      <metadata key="source_volume_id" value="0"/>
      <metadata key="source_offset_x" value="0"/>
      <metadata key="source_offset_y" value="0"/>
      <metadata key="source_offset_z" value="0"/>
    </part>
  </object>''')
        
        plate_entries.append(f'''  <plate>
    <metadata key="plater_id" value="{plate_id}"/>
    <metadata key="plater_name" value="{name}"/>
    <metadata key="locked" value="false"/>
    <metadata key="thumbnail_file" value="Metadata/plate_{plate_id}.png"/>
    <metadata key="thumbnail_no_light_file" value="Metadata/plate_no_light_{plate_id}.png"/>
    <metadata key="top_file" value="Metadata/top_{plate_id}.png"/>
    <metadata key="pick_file" value="Metadata/pick_{plate_id}.png"/>
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
</config>'''

def main():
    print(f"Surgical 3MF Build - Foundation: {TEMPLATE_3MF}")
    
    objects = []
    child_models = {}
    
    # 1. Parse STL files
    for i, stl_file in enumerate(STL_FILES):
        child_id = i * 2 + 1
        wrapper_id = i * 2 + 2
        name = Path(stl_file).stem
        print(f"  Adding: {name}")
        vertices, triangles = parse_ascii_stl(stl_file)
        child_models[f"3D/Objects/object_{i+1}.model"] = generate_child_model(child_id, vertices, triangles)
        objects.append({'child_id': child_id, 'wrapper_id': wrapper_id, 'child_path': f"/3D/Objects/object_{i+1}.model", 'name': name})

    # 2. Build ZIP
    with zipfile.ZipFile(OUTPUT_FILE, 'w', zipfile.ZIP_DEFLATED) as zf:
        # 2a. Copy from template
        with zipfile.ZipFile(TEMPLATE_3MF, 'r') as tz:
            for item in tz.infolist():
                if item.filename in ['3D/3dmodel.model', 'Metadata/model_settings.config', 'Metadata/filament_sequence.json']:
                    continue # We generate these
                
                # Copy other files
                content = tz.read(item.filename)
                zf.writestr(item.filename, content)
                
                # Copy thumbnails for each plate
                if 'Metadata/' in item.filename and '_1.png' in item.filename:
                    for p in range(2, len(objects) + 1):
                        new_name = item.filename.replace('_1.png', f'_{p}.png')
                        zf.writestr(new_name, content)
        
        # 2b. Add generated files
        zf.writestr('3D/3dmodel.model', generate_main_model(objects))
        zf.writestr('Metadata/model_settings.config', generate_model_settings(objects))
        
        # filament_sequence.json
        seq = {}
        for p in range(1, len(objects) + 1):
            seq[f"plate_{p}"] = {"sequence": []}
        zf.writestr('Metadata/filament_sequence.json', json.dumps(seq))
        
        # Relationships for models
        rels = []
        for i, obj in enumerate(objects):
            rels.append(f' <Relationship Target="{obj["child_path"]}" Id="rel-{i+1}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>')
        rels_xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
{chr(10).join(rels)}
</Relationships>'''
        zf.writestr('3D/_rels/3dmodel.model.rels', rels_xml)
        
        for path, content in child_models.items():
            zf.writestr(path, content)

    print(f"\nCreated: {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
