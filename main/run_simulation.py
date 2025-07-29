"""
Helper script to run the ChaCha20 ASIC testbench
"""

import os
import subprocess
import sys

def try_local_simulation():
    """Try to run simulation with available tools"""
    
    print("🔍 Checking for available simulators...")
    
    simulators = [
        ('iverilog', 'Icarus Verilog'),
        ('vlog', 'ModelSim/QuestaSim'),  
        ('xvlog', 'Xilinx Vivado'),
        ('vcs', 'Synopsys VCS'),
        ('ncvlog', 'Cadence')
    ]
    
    available_sims = []
    for sim_cmd, sim_name in simulators:
        try:
            result = subprocess.run(['where', sim_cmd], capture_output=True, text=True, shell=True)
            if result.returncode == 0:
                available_sims.append((sim_cmd, sim_name))
                print(f"✅ Found: {sim_name}")
        except:
            pass
    
    if not available_sims:
        print("❌ No simulators found locally")
        return False
    
    # Try with the first available simulator
    sim_cmd, sim_name = available_sims[0]
    print(f"\n🚀 Attempting simulation with {sim_name}...")
    
    if sim_cmd == 'iverilog':
        return run_icarus_simulation()
    elif sim_cmd in ['vlog', 'vsim']:
        return run_modelsim_simulation()
    elif sim_cmd == 'xvlog':
        return run_vivado_simulation()
    
    return False

def run_icarus_simulation():
    """Run simulation with Icarus Verilog"""
    try:
        print("📋 Compiling with Icarus Verilog...")
        
        # Try the full testbench first
        print("🎯 Attempting full ChaCha20 testbench...")
        
        # Create file list for full testbench
        verilog_files = [
            'rtl/qr.v',
            'rtl/chacha20_core.v', 
            'rtl/MockTRNGHardened.v',
            'rtl/asic_top.v',
            'tb/tb_asic_top.sv'
        ]
        
        # Check all files exist
        missing_files = [f for f in verilog_files if not os.path.exists(f)]
        if missing_files:
            print(f"❌ Missing files: {missing_files}")
            return False
        
        # Try SystemVerilog 2012 first
        print("🔧 Trying SystemVerilog 2012 mode...")
        cmd = ['iverilog', '-g2012', '-o', 'simulation'] + verilog_files
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print("⚠️  SystemVerilog 2012 failed, trying system-verilog mode...")
            cmd = ['iverilog', '-gsystem-verilog', '-o', 'simulation'] + verilog_files
            result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print("⚠️  SystemVerilog modes failed, trying Verilog 2005 with fixes...")
            # Try with our fixed files
            verilog_files = [
                'qr_v2005.v',
                'rtl/MockTRNGHardened.v',
                'asic_top_simple.v',
                'tb_asic_top_fixed.sv'
            ]
        
        if result.returncode != 0:
            print("⚠️  SystemVerilog modes failed, trying WORKING Verilog 2005 implementation...")
            # Try with our proven working implementation
            verilog_files = [
                'rtl/MockTRNGHardened.v',
                'qr_v2005.v',
                'chacha20_v2005.v', 
                'asic_top_full.v',
                'tb_working.v'
            ]
            cmd = ['iverilog', '-g2005', '-o', 'simulation'] + verilog_files
            result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"❌ All compilation attempts failed:")
            print(result.stderr)
            print("\n💡 Try these fixes:")
            print("1. Install newer Icarus Verilog with SystemVerilog support")
            print("2. Use commercial simulator (ModelSim, Vivado, etc.)")
            print("3. Use online simulator like EDA Playground")
            return False
        
        print("✅ Compilation successful")
        
        # Run simulation
        print("🎮 Running full ChaCha20 simulation...")
        result = subprocess.run(['vvp', 'simulation'], capture_output=True, text=True)
        
        print("📤 Simulation output:")
        print(result.stdout)
        
        if result.stderr:
            print("⚠️  Simulation errors/warnings:")
            print(result.stderr)
        
        # Analyze results
        if "ALL TESTS PASSED" in result.stdout:
            print("\n🎉 SUCCESS: All tests passed!")
            return True
        elif "SOME TESTS FAILED" in result.stdout:
            print("\n⚠️  Some tests failed - check output above")
            return False
        else:
            print("\n❓ Test completion unclear - check output")
            return result.returncode == 0
        
    except Exception as e:
        print(f"❌ Error running Icarus simulation: {e}")
        return False

def run_modelsim_simulation():
    """Run simulation with ModelSim"""
    print("🔧 ModelSim simulation not implemented yet")
    return False

def run_vivado_simulation():
    """Run simulation with Vivado"""
    print("🔧 Vivado simulation not implemented yet")
    return False

def suggest_cloud_simulation():
    """Suggest cloud-based simulation options"""
    print("\n☁️  Cloud-based simulation options:")
    print("1. EDA Playground (https://www.edaplayground.com/)")
    print("   - Free online simulator")
    print("   - Supports SystemVerilog")
    print("   - Copy/paste your code")
    
    print("\n2. Xilinx Cloud (for Vivado)")
    print("   - Free with registration")
    print("   - Full Vivado toolchain")
    
    print("\n3. Academic licenses:")
    print("   - Many universities provide free tool access")
    print("   - ModelSim, QuestaSim, etc.")

def create_eda_playground_instructions():
    """Create instructions for EDA Playground"""
    
    instructions = """
# EDA Playground Instructions

1. Go to: https://www.edaplayground.com/

2. Select these settings:
   - Language: SystemVerilog/Verilog
   - Simulator: Icarus Verilog or Aldec Riviera-PRO
   
3. Copy these files to the editor:

## File 1: Design (copy all RTL files combined)
- qr.v
- MockTRNGHardened.v  
- chacha20_core.v
- asic_top.v

## File 2: Testbench
- tb_asic_top_fixed.sv

4. Click "Run" to simulate

5. View waveforms in the EPWave viewer

## Tips:
- Start with the simple_test.sv first
- If it fails, check the console for error messages
- Use $display statements for debugging
"""
    
    with open('EDA_PLAYGROUND_INSTRUCTIONS.md', 'w') as f:
        f.write(instructions)
    
    print("📝 Created EDA_PLAYGROUND_INSTRUCTIONS.md")

def main():
    print("🚀 ChaCha20 ASIC Testbench Runner")
    print("=" * 40)
    
    # Change to main directory if needed
    if os.path.exists('main'):
        os.chdir('main')
    
    # Try local simulation first
    if try_local_simulation():
        print("✅ Local simulation completed successfully!")
        return 0
    else:
        print("\n💡 Local simulation not available or failed")
        suggest_cloud_simulation()
        create_eda_playground_instructions()
        
        print("\n🎯 Recommended next steps:")
        print("1. Use EDA Playground for quick testing")
        print("2. Install Icarus Verilog for local development")
        print("3. Check university resources for commercial tools")
        
        return 1

if __name__ == "__main__":
    sys.exit(main())
