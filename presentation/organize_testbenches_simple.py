"""
ChaCha20 ASIC Testbench Organizer (Simple Version)
Organizes scattered testbench files without touching files already in folders
"""

import os
import shutil
from pathlib import Path

class SimpleTestbenchOrganizer:
    def __init__(self, base_path):
        self.base_path = Path(base_path)
        self.setup_directories()
        
    def setup_directories(self):
        """Create organized directory structure for testbenches"""
        dirs = [
            "verification",
            "verification/testbenches",
            "verification/testbenches/unit_tests",
            "verification/testbenches/integration", 
            "verification/testbenches/working",
            "verification/testbenches/legacy",
            "verification/simulation_results",
            "verification/simulation_results/unit",
            "verification/simulation_results/integration",
            "verification/scripts"
        ]
        
        for dir_path in dirs:
            full_path = self.base_path / dir_path
            full_path.mkdir(parents=True, exist_ok=True)
            print(f"Created: {dir_path}")
            
        self.create_simple_readme()
    
    def create_simple_readme(self):
        """Create simple README without emojis"""
        readme_content = """# ChaCha20 ASIC Verification Suite

## Directory Structure

### testbenches/
Contains all testbench files organized by category:

#### unit_tests/
- qr_tb.v - Quarter Round module testbench
- chacha20_core_tb.sv - ChaCha20 core standalone test
- chacha20_core_rfc_tb.sv - RFC compliance test
- trng_unit_tb.sv - TRNG module verification

#### integration/
- tb_asic_top.sv - Full ASIC top-level testbench (SystemVerilog)
- tb_asic_top_fixed.sv - Modified SystemVerilog version

#### working/
- tb_working.v - PROVEN WORKING Verilog-2005 compatible testbench
- tb_full_v2005.v - Full system test (Verilog-2005)
- run_simulation.py - Automated test runner

#### legacy/
- Original testbenches for reference
- Deprecated test files

### simulation_results/
VCD waveform files and simulation logs

### scripts/
Automation and utility scripts

## Quick Start

### Run Working Testbench
```bash
cd verification/testbenches/working/
python run_simulation.py
```

## Test Status

WORKING TESTS:
- tb_working.v - Complete system verification
- qr_tb.v - Quarter round functionality

COMPATIBILITY ISSUES:
- SystemVerilog testbenches require newer simulators
- Use Verilog-2005 versions for Icarus Verilog

---
ChaCha20 ASIC Verification Suite
Comprehensive Hardware Verification
"""
        
        readme_path = self.base_path / "verification" / "README.md"
        with open(readme_path, "w", encoding='utf-8') as f:
            f.write(readme_content)
        print(f"Created verification README: {readme_path}")
    
    def find_scattered_files(self):
        """Find testbench files that are scattered in root directories"""
        scattered_files = []
        
        # Look for files in main project root and main/ directory
        search_paths = [
            self.base_path.parent,  # Main project root
            self.base_path.parent / "main"  # main/ directory
        ]
        
        # File patterns to look for
        patterns = ["*tb*.v", "*tb*.sv", "*test*.v", "*test*.sv"]
        
        for search_path in search_paths:
            if search_path.exists():
                for pattern in patterns:
                    # Only get files directly in the directory (not in subdirectories)
                    for file_path in search_path.glob(pattern):
                        if file_path.is_file():
                            # Skip if already in a folder structure
                            if not any(folder in str(file_path) for folder in ['tb/', 'testbench/', 'verification/']):
                                scattered_files.append(file_path)
        
        return scattered_files
    
    def organize_scattered_testbenches(self):
        """Organize only the scattered testbench files"""
        print("\nOrganizing scattered testbench files...")
        
        scattered_files = self.find_scattered_files()
        
        if not scattered_files:
            print("No scattered testbench files found!")
            return
        
        # File classification rules
        file_mappings = {
            # Unit tests (specific modules)
            "qr_tb.v": "verification/testbenches/unit_tests/",
            "chacha20_core_tb.sv": "verification/testbenches/unit_tests/",
            "chacha20_core_rfc_tb.sv": "verification/testbenches/unit_tests/",
            "trng_unit_tb.sv": "verification/testbenches/unit_tests/",
            
            # Integration tests (full system)
            "tb_asic_top.sv": "verification/testbenches/integration/",
            "tb_asic_top_fixed.sv": "verification/testbenches/integration/",
            
            # Working tests (proven to work)
            "tb_working.v": "verification/testbenches/working/",
            "tb_full_v2005.v": "verification/testbenches/working/",
            
            # Legacy/other
            "simple_test.sv": "verification/testbenches/legacy/",
            "compile_check.sv": "verification/testbenches/legacy/"
        }
        
        # Organize each scattered file
        for file_path in scattered_files:
            filename = file_path.name
            print(f"Found scattered file: {filename}")
            
            # Determine destination
            if filename in file_mappings:
                dest_dir = file_mappings[filename]
            else:
                # Default classification based on name patterns
                if "core" in filename.lower():
                    dest_dir = "verification/testbenches/unit_tests/"
                elif "asic" in filename.lower() or "top" in filename.lower():
                    dest_dir = "verification/testbenches/integration/"
                elif "working" in filename.lower() or "v2005" in filename.lower():
                    dest_dir = "verification/testbenches/working/"
                else:
                    dest_dir = "verification/testbenches/legacy/"
            
            # Copy the file
            dest_path = self.base_path / dest_dir / filename
            
            if not dest_path.exists():
                shutil.copy2(file_path, dest_path)
                print(f"Moved: {filename} -> {dest_dir}")
            else:
                print(f"Exists: {filename} (skipped)")
    
    def organize_scattered_results(self):
        """Organize scattered VCD and result files"""
        print("\nOrganizing scattered simulation results...")
        
        # Look for VCD files in root directories
        search_paths = [
            self.base_path.parent,  # Main project root
            self.base_path.parent / "main"  # main/ directory
        ]
        
        vcd_files = []
        for search_path in search_paths:
            if search_path.exists():
                # Only get VCD files directly in the directory
                for vcd_file in search_path.glob("*.vcd"):
                    if vcd_file.is_file():
                        # Skip if already organized
                        if "verification" not in str(vcd_file):
                            vcd_files.append(vcd_file)
        
        for vcd_file in vcd_files:
            filename = vcd_file.name
            print(f"Found scattered VCD: {filename}")
            
            # Classify VCD files
            if any(word in filename.lower() for word in ["working", "full", "asic", "top"]):
                dest_dir = "verification/simulation_results/integration/"
            else:
                dest_dir = "verification/simulation_results/unit/"
            
            dest_path = self.base_path / dest_dir / filename
            
            if not dest_path.exists():
                shutil.copy2(vcd_file, dest_path)
                print(f"Moved VCD: {filename} -> {dest_dir}")
            else:
                print(f"VCD exists: {filename} (skipped)")
    
    def copy_working_simulation_script(self):
        """Copy the working simulation script if found"""
        print("\nLooking for simulation scripts...")
        
        # Look for run_simulation.py in main directories
        search_paths = [
            self.base_path.parent / "main",
            self.base_path.parent
        ]
        
        for search_path in search_paths:
            script_path = search_path / "run_simulation.py"
            if script_path.exists():
                dest_path = self.base_path / "verification/testbenches/working/run_simulation.py"
                if not dest_path.exists():
                    shutil.copy2(script_path, dest_path)
                    print(f"Copied: run_simulation.py -> verification/testbenches/working/")
                break
    
    def generate_summary(self):
        """Generate organization summary"""
        print("\nOrganization Summary:")
        print("=" * 40)
        
        # Count organized files
        verification_path = self.base_path / "verification"
        
        testbench_count = len(list(verification_path.glob("testbenches/**/*.v"))) + \
                         len(list(verification_path.glob("testbenches/**/*.sv")))
        
        vcd_count = len(list(verification_path.glob("simulation_results/**/*.vcd")))
        
        script_count = len(list(verification_path.glob("**/*.py")))
        
        print(f"Organized {testbench_count} testbench files")
        print(f"Organized {vcd_count} simulation result files")
        print(f"Found {script_count} script files")
        
        print(f"\nQuick start:")
        print(f"   cd verification/testbenches/working/")
        print(f"   python run_simulation.py")
        
        print(f"\nStructure created in: {verification_path}")

def main():
    print("ChaCha20 ASIC Testbench Organizer (Simple)")
    print("=" * 45)
    
    base_path = Path(__file__).parent
    organizer = SimpleTestbenchOrganizer(base_path)
    
    organizer.organize_scattered_testbenches()
    organizer.organize_scattered_results()
    organizer.copy_working_simulation_script()
    organizer.generate_summary()
    
    print("\nTestbench organization complete!")

if __name__ == "__main__":
    main()
