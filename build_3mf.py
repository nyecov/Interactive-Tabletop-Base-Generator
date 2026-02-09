#!/usr/bin/env python3
"""
Build a 3MF archive with proper forward slash paths (OPC/3MF specification).
Usage: python build_3mf.py <source_dir> <output.3mf>
"""
import zipfile
import os
import sys

def build_3mf(source_dir, output_path):
    """Create a 3MF ZIP with forward slash paths."""
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                local_path = os.path.join(root, file)
                # Calculate archive path relative to source_dir
                rel_path = os.path.relpath(local_path, source_dir)
                # Convert to forward slashes (3MF/OPC requirement)
                archive_path = rel_path.replace('\\', '/')
                
                print(f"Adding: {archive_path}")
                zf.write(local_path, archive_path)
    
    print(f"\nCreated: {output_path}")
    
    # Verify the paths
    print("\n=== Verifying archive entries ===")
    with zipfile.ZipFile(output_path, 'r') as zf:
        for info in zf.infolist():
            print(f"  {info.filename}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        # Default: use Analysis_NoBOM as source
        source = "Analysis_NoBOM"
        output = "Minimal_Python.3mf"
    else:
        source = sys.argv[1]
        output = sys.argv[2]
    
    if not os.path.exists(source):
        print(f"Error: Source directory '{source}' not found")
        sys.exit(1)
    
    build_3mf(source, output)
