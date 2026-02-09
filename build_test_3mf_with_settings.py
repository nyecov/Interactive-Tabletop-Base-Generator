#!/usr/bin/env python3
"""
Build a test 3MF with 3 objects and inject custom slicer settings.
Usage: python build_test_3mf_with_settings.py
"""
import zipfile
import os
import re
import json
from pathlib import Path

# Configuration
STL_FILES = ["minimal_test.stl", "test_4.stl", "test_poly.stl"]
OUTPUT_FILE = "Test_3Objects_CustomSettings.3mf"
CUSTOM_TEMPLATE = "custom_slicer_Settings_only.3mf"

def parse_ascii_stl(stl_path):
    """Parse ASCII STL and return vertices and triangles."""
    content = Path(stl_path).read_text()
    vertices = []
    triangles = []
    vertex_map = {}
    
    # Regex for facet/vertex parsing
    pattern = r'facet normal\s+[\d.\-e+]+\s+[\d.\-e+]+\s+[\d.\-e+]+\s+outer loop\s+vertex\s+([\d.\-e+]+)\s+([\d.\-e+]+)\s+([\d.\-e+]+)\s+vertex\s+([\d.\-e+]+)\s+([\d.\-e+]+)\s+([\d.\-e+]+)\s+vertex\s+([\d.\-e+]+)\s+([\d.\-e+]+)\s+([\d.\-e+]+)\s+endloop\s+endfacet'
    
    for match in re.finditer(pattern, content, re.IGNORECASE):
        v1 = (match.group(1), match.group(2), match.group(3))
        v2 = (match.group(4), match.group(5), match.group(6))
        v3 = (match.group(7), match.group(8), match.group(9))
        
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
    """Generate XML for a child model file."""
    import uuid
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
    """Generate the main 3dmodel.model with components and build items."""
    import uuid
    
    resources = []
    build_items = []
    
    for i, obj in enumerate(objects):
        wrapper_id = obj['wrapper_id']
        child_id = obj['child_id']
        child_path = obj['child_path']
        name = obj['name']
        x_offset = 90 + (i * 216)  # Plates spaced 216mm apart
        
        wrapper_uuid = str(uuid.uuid4())
        comp_uuid = str(uuid.uuid4())
        item_uuid = str(uuid.uuid4())
        
        resources.append(f'''  <object id="{wrapper_id}" p:UUID="{wrapper_uuid}" type="model">
   <components>
    <component p:path="{child_path}" objectid="{child_id}" p:UUID="{comp_uuid}" transform="1 0 0 0 1 0 0 0 1 0 0 0"/>
   </components>
  </object>''')
        
        build_items.append(f'  <item objectid="{wrapper_id}" p:UUID="{item_uuid}" transform="1 0 0 0 1 0 0 0 1 {x_offset} 90 2" printable="1"/>')
    
    build_uuid = str(uuid.uuid4())
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02" xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" requiredextensions="p">
 <metadata name="BambuStudio:3mfVersion">1</metadata>
 <resources>
{chr(10).join(resources)}
 </resources>
 <build p:UUID="{build_uuid}">
{chr(10).join(build_items)}
 </build>
</model>'''

def generate_model_settings(objects):
    """Generate model_settings.config with multi-plate support."""
    object_entries = []
    plate_entries = []
    assemble_items = []
    
    for i, obj in enumerate(objects):
        wrapper_id = obj['wrapper_id']
        child_id = obj['child_id']
        name = obj['name']
        plate_id = i + 1
        
        # Object metadata and part binding
        object_entries.append(f'''  <object id="{wrapper_id}">
    <metadata key="name" value="{name}"/>
    <metadata key="extruder" value="1"/>
    <part id="{child_id}" subtype="normal_part">
      <metadata key="name" value="{name}"/>
      <metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>
      <metadata key="source_file" value=""/>
      <metadata key="source_object_id" value="0"/>
      <metadata key="source_volume_id" value="0"/>
      <metadata key="source_offset_x" value="0"/>
      <metadata key="source_offset_y" value="0"/>
      <metadata key="source_offset_z" value="2"/>
    </part>
  </object>''')
        
        # Plate entry linking object to a specific plate
        plate_entries.append(f'''  <plate>
    <metadata key="plater_id" value="{plate_id}"/>
    <metadata key="plater_name" value="{name}"/>
    <metadata key="locked" value="false"/>
    <metadata key="filament_map_mode" value="Auto For Flush"/>
    <metadata key="thumbnail_file" value="Metadata/plate_1.png"/>
    <metadata key="thumbnail_no_light_file" value="Metadata/plate_no_light_1.png"/>
    <metadata key="top_file" value="Metadata/top_1.png"/>
    <metadata key="pick_file" value="Metadata/pick_1.png"/>
    <model_instance>
      <metadata key="object_id" value="{wrapper_id}"/>
      <metadata key="instance_id" value="0"/>
      <metadata key="identify_id" value="{100 + i}"/>
    </model_instance>
  </plate>''')
        
        # Local plate coordinates (always 90, 90 on the plate itself)
        assemble_items.append(f'   <assemble_item object_id="{wrapper_id}" instance_id="0" transform="1 0 0 0 1 0 0 0 1 90 90 2" offset="0 0 0"/>')
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<config>
{chr(10).join(object_entries)}
{chr(10).join(plate_entries)}
  <assemble>
{chr(10).join(assemble_items)}
  </assemble>
</config>'''

def generate_relationships(objects):
    """Generate 3D/_rels/3dmodel.model.rels"""
    rels = []
    for i, obj in enumerate(objects):
        rels.append(f' <Relationship Target="{obj["child_path"]}" Id="rel-{i+1}" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>')
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
{chr(10).join(rels)}
</Relationships>'''

def main():
    print(f"Building test 3MF with {len(STL_FILES)} objects...")
    
    # Extract project_settings.config from custom template
    print(f"Extracting settings from: {CUSTOM_TEMPLATE}")
    with zipfile.ZipFile(CUSTOM_TEMPLATE, 'r') as zf:
        project_settings = zf.read('Metadata/project_settings.config')
    
    # Parse STL files and prepare objects
    objects = []
    child_models = {}
    
    for i, stl_file in enumerate(STL_FILES):
        child_id = i * 2 + 1  # 1, 3, 5
        wrapper_id = i * 2 + 2  # 2, 4, 6
        child_path = f"/3D/Objects/object_{i+1}.model"
        name = Path(stl_file).stem
        
        print(f"  Parsing: {stl_file} (object {wrapper_id})")
        vertices, triangles = parse_ascii_stl(stl_file)
        print(f"    -> {len(vertices)} vertices, {len(triangles)} triangles")
        
        child_models[f"3D/Objects/object_{i+1}.model"] = generate_child_model(child_id, vertices, triangles)
        
        objects.append({
            'child_id': child_id,
            'wrapper_id': wrapper_id,
            'child_path': child_path,
            'name': name
        })
    
    # Generate XML files
    main_model = generate_main_model(objects)
    model_settings = generate_model_settings(objects)
    relationships = generate_relationships(objects)
    
    # Content types (No .config entry, like working reference)
    content_types = '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
 <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
 <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
 <Default Extension="png" ContentType="image/png"/>
 <Default Extension="gcode" ContentType="text/x.gcode"/>
 <Default Extension="json" ContentType="application/json"/>
</Types>'''
    
    # Root rels
    root_rels = '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
 <Relationship Target="/3D/3dmodel.model" Id="rel-1" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>'''
    
    # Build ZIP
    print(f"\nCreating: {OUTPUT_FILE}")
    with zipfile.ZipFile(OUTPUT_FILE, 'w', zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('[Content_Types].xml', content_types)
        zf.writestr('_rels/.rels', root_rels)
        zf.writestr('3D/3dmodel.model', main_model)
        zf.writestr('3D/_rels/3dmodel.model.rels', relationships)
        
        for path, content in child_models.items():
            zf.writestr(path, content)
        
        # Inject custom slicer settings and metadata
        print("Injecting metadata files from template...")
        with zipfile.ZipFile(CUSTOM_TEMPLATE, 'r') as template_zf:
            for item in template_zf.infolist():
                if item.filename.startswith('Metadata/') and item.filename != 'Metadata/model_settings.config':
                    zf.writestr(item.filename, template_zf.read(item.filename))
        
        zf.writestr('Metadata/model_settings.config', model_settings)
    
    # Verify
    print("\n=== Archive entries ===")
    with zipfile.ZipFile(OUTPUT_FILE, 'r') as zf:
        for info in zf.infolist():
            print(f"  {info.filename}")
    
    print(f"\n✅ Done! Created: {OUTPUT_FILE}")
    print("   - 3 objects on separate plates")
    print("   - Custom slicer settings injected")

if __name__ == "__main__":
    main()
