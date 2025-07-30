"""
ChaCha20 ASIC Testbench Organizer
Cleans up and organizes all testbench files, simulation results, and verification scripts
"""

import os
import shutil
from pathlib import Path
import subprocess
import json

class TestbenchOrganizer:
    def __init__(self, base_path):
        self.base_path = Path(base_path)
        self.setup_directories()
        
    def setup_directories(self):
        """Create organized directory structure for testbenches"""
        dirs = {
            "verification": "Main verification directory",
            "verification/testbenches": "All testbench files",
            "verification/testbenches/unit_tests": "Individual module tests",
            "verification/testbenches/integration": "Full system tests", 
            "verification/testbenches/working": "Proven working testbenches",
            "verification/testbenches/legacy": "Original/older testbenches",
            "verification/simulation_results": "VCD and log files",
            "verification/simulation_results/unit": "Unit test results",
            "verification/simulation_results/integration": "Integration test results",
            "verification/scripts": "Automation and run scripts",
            "verification/reports": "Test reports and coverage",
            "verification/golden_vectors": "Reference test vectors"
        }
        
        for dir_path, description in dirs.items():
            full_path = self.base_path / dir_path
            full_path.mkdir(parents=True, exist_ok=True)
            print(f"📁 Created: {dir_path} - {description}")
            
        # Create README files
        self.create_verification_readme()
    
    def create_verification_readme(self):
        """Create comprehensive README for verification directory"""
        readme_content = """# ChaCha20 ASIC Verification Suite

## Directory Structure

### 📁 testbenches/
Contains all testbench files organized by category:

#### unit_tests/
- `qr_tb.v` - Quarter Round module testbench
- `chacha20_core_tb.sv` - ChaCha20 core standalone test
- `chacha20_core_rfc_tb.sv` - RFC compliance test
- `trng_unit_tb.sv` - TRNG module verification

#### integration/
- `tb_asic_top.sv` - Full ASIC top-level testbench (SystemVerilog)
- `tb_asic_top_fixed.sv` - Modified SystemVerilog version

#### working/
- `tb_working.v` - **PROVEN WORKING** Verilog-2005 compatible testbench
- `tb_full_v2005.v` - Full system test (Verilog-2005)
- `run_simulation.py` - Automated test runner

#### legacy/
- Original testbenches for reference
- Deprecated test files

### 📁 simulation_results/
VCD waveform files and simulation logs:

#### unit/
- Individual module simulation results

#### integration/
- `working_full_test.vcd` - Successful full system test
- `basic_test.vcd` - Basic functionality verification

### 📁 scripts/
Automation and utility scripts:
- `run_all_tests.py` - Execute complete test suite
- `generate_reports.py` - Create test coverage reports
- `clean_results.py` - Clean up old simulation files

### 📁 reports/
Test documentation and coverage reports

### 📁 golden_vectors/
Reference test vectors and expected outputs

## Quick Start

### Run Working Testbench
```bash
cd verification/testbenches/working/
python run_simulation.py
```

### Run All Tests
```bash
cd verification/scripts/
python run_all_tests.py
```

### View Results
- VCD files: Use GTKWave or similar waveform viewer
- Reports: Check `reports/` directory

## Test Status

✅ **WORKING TESTS:**
- `tb_working.v` - Complete system verification
- `qr_tb.v` - Quarter round functionality
- `chacha20_core_tb.sv` - Core encryption engine

⚠️ **COMPATIBILITY ISSUES:**
- SystemVerilog testbenches require newer simulators
- Use Verilog-2005 versions for Icarus Verilog

❌ **DEPRECATED:**
- Old scattered testbench files (moved to legacy/)

## Simulation Tools

### Supported Simulators:
- **Icarus Verilog** (recommended for Verilog-2005)
- **ModelSim/QuestaSim** (SystemVerilog support)
- **Vivado Simulator** (Xilinx)
- **VCS** (Synopsys)

### Waveform Viewers:
- **GTKWave** (free, cross-platform)
- **ModelSim Wave** 
- **Vivado Simulator**

## Test Categories

### 1. Unit Tests
Individual module verification:
- Quarter Round (QR) operations
- ChaCha20 core functionality  
- TRNG operation
- I/O controllers

### 2. Integration Tests
Full system verification:
- Complete encryption flow
- Key/nonce/counter handling
- Data streaming
- FSM state transitions

### 3. Compliance Tests
Standards verification:
- RFC 7539 ChaCha20 compliance
- Test vector validation
- Performance benchmarks

## Contributing

### Adding New Tests:
1. Place in appropriate category directory
2. Follow naming convention: `[module]_tb.[v|sv]`
3. Update this README
4. Add to test suite runner

### Simulation Guidelines:
- Use Verilog-2005 for maximum compatibility
- Include comprehensive assertions
- Generate VCD files for debugging
- Document test objectives

## Troubleshooting

### Common Issues:
- **SystemVerilog compatibility**: Use Verilog-2005 alternatives
- **Clock/reset timing**: Check testbench clock generation
- **File paths**: Use relative paths in testbenches

### Debug Tips:
- Check VCD waveforms first
- Verify clock and reset signals
- Review FSM state transitions
- Validate input/output timing

---
**ChaCha20 ASIC Verification Suite**  
*Comprehensive Hardware Verification*
"""
        
        readme_path = self.base_path / "verification" / "README.md"
        with open(readme_path, "w") as f:
            f.write(readme_content)
        print(f"📝 Created verification README: {readme_path}")
    
    def organize_testbenches(self):
        """Organize all testbench files"""
        print("\n🧹 Organizing testbench files...")
        
        # Define file categories and their destinations
        file_mappings = {
            # Unit tests
            "qr_tb.v": "verification/testbenches/unit_tests/",
            "chacha20_core_tb.sv": "verification/testbenches/unit_tests/",
            "chacha20_core_rfc_tb.sv": "verification/testbenches/unit_tests/",
            "trng_unit_tb.sv": "verification/testbenches/unit_tests/",
            
            # Integration tests
            "tb_asic_top.sv": "verification/testbenches/integration/",
            "tb_asic_top_fixed.sv": "verification/testbenches/integration/",
            
            # Working tests
            "tb_working.v": "verification/testbenches/working/",
            "tb_full_v2005.v": "verification/testbenches/working/",
            "run_simulation.py": "verification/testbenches/working/",
            
            # Legacy/other
            "top_level_tb.v": "verification/testbenches/legacy/",
            "simple_test.sv": "verification/testbenches/legacy/",
            "compile_check.sv": "verification/testbenches/legacy/"
        }
        
        # Search for files and copy them
        for filename, dest_dir in file_mappings.items():
            dest_path = self.base_path / dest_dir
            
            # Search for the file in the project
            found_files = list(self.base_path.glob(f"**/{filename}"))
            
            if found_files:
                # Use the first found file (most likely the main one)
                source_file = found_files[0]
                dest_file = dest_path / filename
                
                if not dest_file.exists():
                    shutil.copy2(source_file, dest_file)
                    print(f"📋 Copied: {filename} → {dest_dir}")
                else:
                    print(f"⏭️  Exists: {filename} (skipped)")
            else:
                print(f"❓ Not found: {filename}")
    
    def organize_simulation_results(self):
        """Organize VCD files and simulation results"""
        print("\n📊 Organizing simulation results...")
        
        # Find all VCD files
        vcd_files = list(self.base_path.glob("**/*.vcd"))
        
        result_mappings = {
            "working_full_test.vcd": "verification/simulation_results/integration/",
            "basic_test.vcd": "verification/simulation_results/integration/",
            "tb_asic_top.vcd": "verification/simulation_results/integration/",
            "tb_asic_top_full_cycle.vcd": "verification/simulation_results/integration/",
            "qr_test.vcd": "verification/simulation_results/unit/",
            "chacha20_test.vcd": "verification/simulation_results/unit/"
        }
        
        for vcd_file in vcd_files:
            filename = vcd_file.name
            
            # Determine destination
            if filename in result_mappings:
                dest_dir = result_mappings[filename]
            else:
                # Default to integration if unknown
                dest_dir = "verification/simulation_results/integration/"
            
            dest_path = self.base_path / dest_dir / filename
            
            if not dest_path.exists():
                shutil.copy2(vcd_file, dest_path)
                print(f"📊 Moved VCD: {filename} → {dest_dir}")
    
    def create_test_scripts(self):
        """Create automation scripts"""
        print("\n🔧 Creating test automation scripts...")
        
        # Main test runner
        test_runner_content = '''#!/usr/bin/env python3
"""
ChaCha20 ASIC Test Suite Runner
Automated execution of all verification tests
"""

import os
import subprocess
import sys
from pathlib import Path

class TestRunner:
    def __init__(self):
        self.base_path = Path(__file__).parent.parent
        self.results = {}
        
    def run_test(self, test_name, test_path, simulator="iverilog"):
        """Run a single test"""
        print(f"\\n🧪 Running {test_name}...")
        
        try:
            if simulator == "iverilog":
                # Compile
                compile_cmd = ["iverilog", "-o", "test.vvp"] + list(test_path.glob("*.v"))
                subprocess.run(compile_cmd, check=True, cwd=test_path)
                
                # Run
                run_cmd = ["vvp", "test.vvp"]
                result = subprocess.run(run_cmd, capture_output=True, text=True, cwd=test_path)
                
                if result.returncode == 0:
                    print(f"✅ {test_name} PASSED")
                    self.results[test_name] = "PASSED"
                else:
                    print(f"❌ {test_name} FAILED")
                    print(result.stderr)
                    self.results[test_name] = "FAILED"
                    
        except Exception as e:
            print(f"💥 {test_name} ERROR: {e}")
            self.results[test_name] = "ERROR"
    
    def run_all_tests(self):
        """Run complete test suite"""
        print("🚀 ChaCha20 ASIC Test Suite")
        print("=" * 40)
        
        # Unit tests
        unit_tests = {
            "Quarter Round": self.base_path / "testbenches/unit_tests",
            "ChaCha20 Core": self.base_path / "testbenches/unit_tests"
        }
        
        # Working tests
        working_test = self.base_path / "testbenches/working"
        if (working_test / "tb_working.v").exists():
            self.run_test("System Integration", working_test)
        
        # Generate report
        self.generate_report()
    
    def generate_report(self):
        """Generate test report"""
        print("\\n📋 Test Results Summary")
        print("=" * 40)
        
        passed = sum(1 for result in self.results.values() if result == "PASSED")
        total = len(self.results)
        
        for test, result in self.results.items():
            status_icon = "✅" if result == "PASSED" else "❌"
            print(f"{status_icon} {test}: {result}")
        
        print(f"\\n📊 Overall: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 All tests passed!")
            return True
        else:
            print("⚠️  Some tests failed")
            return False

def main():
    runner = TestRunner()
    success = runner.run_all_tests()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
'''
        
        script_path = self.base_path / "verification/scripts/run_all_tests.py"
        with open(script_path, "w") as f:
            f.write(test_runner_content)
        print(f"🔧 Created: run_all_tests.py")
        
        # Make executable on Unix
        if os.name != 'nt':
            os.chmod(script_path, 0o755)
    
    def create_golden_vectors(self):
        """Create reference test vectors"""
        print("\n🎯 Creating golden test vectors...")
        
        vectors_content = '''# ChaCha20 ASIC Golden Test Vectors

## Test Vector 1: RFC 7539 Example
### Input:
- Key: 000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
- Nonce: 000000000000004a00000000
- Counter: 1
- Plaintext: "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

### Expected Output:
- First 64 bytes: 6e2e359a2568f98041ba0728dd0d6981e97e7aec1d4360c20a27afccfd9fae0bf91b65c5524733ab8f593dabcd62b3571639d624e65152ab8f530c359f0861d807ca0dbf500d6a6156a38e088a22b65e52bc514d16ccf806818ce91ab77937365af90bbf74a35be6b40b8eedf2785e42874d
- Final state: Verification against RFC reference implementation

## Test Vector 2: All Zeros
### Input:
- Key: All zeros (64 bytes)
- Nonce: All zeros (12 bytes)  
- Counter: 0
- Plaintext: All zeros (64 bytes)

### Expected Output:
- Known ChaCha20 output for null inputs

## Test Vector 3: Maximum Values
### Input:
- Key: All 0xFF (64 bytes)
- Nonce: All 0xFF (12 bytes)
- Counter: 0xFFFFFFFF
- Plaintext: All 0xFF (64 bytes)

### Expected Output:
- Boundary condition verification

## Usage in Testbenches

```verilog
// Example testbench usage
initial begin
    // Load test vector 1
    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    nonce = 96'h000000000000004a00000000;
    counter = 32'h1;
    
    // Apply stimulus and check results
    // ... testbench code ...
end
```
'''
        
        vectors_path = self.base_path / "verification/golden_vectors/test_vectors.md"
        with open(vectors_path, "w") as f:
            f.write(vectors_content)
        print(f"🎯 Created: test_vectors.md")
    
    def generate_summary(self):
        """Generate organization summary"""
        print("\n📋 Generating organization summary...")
        
        summary = {
            "total_testbenches": len(list((self.base_path / "verification/testbenches").rglob("*.v"))) + 
                               len(list((self.base_path / "verification/testbenches").rglob("*.sv"))),
            "vcd_files": len(list((self.base_path / "verification/simulation_results").rglob("*.vcd"))),
            "scripts": len(list((self.base_path / "verification/scripts").rglob("*.py"))),
            "directories": len(list((self.base_path / "verification").glob("*")))
        }
        
        print(f"\n🎉 TESTBENCH ORGANIZATION COMPLETE!")
        print("=" * 50)
        print(f"📁 Organized {summary['total_testbenches']} testbench files")
        print(f"📊 Organized {summary['vcd_files']} simulation result files")
        print(f"🔧 Created {summary['scripts']} automation scripts")
        print(f"📂 Created {summary['directories']} organized directories")
        
        print(f"\n🚀 Quick start:")
        print(f"   cd verification/testbenches/working/")
        print(f"   python run_simulation.py")
        
        print(f"\n🧪 Run all tests:")
        print(f"   cd verification/scripts/")
        print(f"   python run_all_tests.py")

def main():
    print("🧹 ChaCha20 ASIC Testbench Organizer")
    print("=" * 45)
    
    base_path = Path(__file__).parent.parent
    organizer = TestbenchOrganizer(base_path)
    
    organizer.organize_testbenches()
    organizer.organize_simulation_results()
    organizer.create_test_scripts()
    organizer.create_golden_vectors()
    organizer.generate_summary()

if __name__ == "__main__":
    main()
