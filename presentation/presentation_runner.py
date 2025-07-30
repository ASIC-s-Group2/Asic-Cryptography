"""
ChaCha20 ASIC Presentation Runner
Quick access to all presentation materials
"""

import os
import sys
import subprocess
from pathlib import Path

def main():
    print("ChaCha20 ASIC Presentation")
    print("=" * 35)
    
    base_dir = Path(__file__).parent
    
    print("\nAvailable Materials:")
    print("1. View Images")
    print("2. Run Simulation") 
    print("3. Generate New Visuals")
    print("4. Open Documentation")
    print("5. Open Project Folder")
    print("6. List All Files")
    
    choice = input("\nSelect option (1-6): ")
    
    if choice == "1":
        images_dir = base_dir / "images"
        if images_dir.exists():
            print("\nGenerated Images:")
            for img in images_dir.glob("*.png"):
                print(f"  - {img.name}")
            if os.name == 'nt':  # Windows
                os.startfile(images_dir)
            else:
                subprocess.run(['open', images_dir])  # macOS
        else:
            print("Images folder not found")
    
    elif choice == "2":
        sim_dir = base_dir / "source_code" / "working_versions"
        if (sim_dir / "run_simulation.py").exists():
            os.chdir(sim_dir)
            subprocess.run([sys.executable, "run_simulation.py"])
        else:
            print("Simulation script not found")
    
    elif choice == "3":
        vis_dir = base_dir / "visualization"
        if vis_dir.exists():
            os.chdir(vis_dir)
            print("Generating 3D visualization...")
            subprocess.run([sys.executable, "chip_3d_generator_fixed.py"])
            print("Generating block diagrams...")
            subprocess.run([sys.executable, "block_diagram_generator_fixed.py"])
            
            # Move images
            images_dir = base_dir / "images"
            for img in vis_dir.glob("*.png"):
                img.rename(images_dir / img.name)
                print(f"Moved: {img.name}")
        else:
            print("Visualization scripts not found")
    
    elif choice == "4":
        doc_file = base_dir / "documentation" / "README.md"
        if doc_file.exists():
            if os.name == 'nt':  # Windows
                os.startfile(doc_file)
            else:
                subprocess.run(['open', doc_file])  # macOS
        else:
            print("Documentation not found")
    
    elif choice == "5":
        if os.name == 'nt':  # Windows
            os.startfile(base_dir)
        else:
            subprocess.run(['open', base_dir])  # macOS
    
    elif choice == "6":
        print("\nProject Structure:")
        for root, dirs, files in os.walk(base_dir):
            level = root.replace(str(base_dir), '').count(os.sep)
            indent = ' ' * 2 * level
            print(f"{indent}{os.path.basename(root)}/")
            subindent = ' ' * 2 * (level + 1)
            for file in files:
                print(f"{subindent}{file}")
    
    else:
        print("Invalid option")

if __name__ == "__main__":
    main()
