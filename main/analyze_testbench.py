#!/usr/bin/env python3
"""
Simple testbench runner and analyzer for ChaCha20 ASIC design
"""

import os
import subprocess
import sys

def check_files():
    """Check if all required files exist"""
    required_files = [
        'rtl/asic_top.v',
        'rtl/chacha20_core.v', 
        'rtl/qr.v',
        'rtl/MockTRNGHardened.v',
        'tb/tb_asic_top.sv'
    ]
    
    missing_files = []
    for file in required_files:
        if not os.path.exists(file):
            missing_files.append(file)
    
    if missing_files:
        print("❌ Missing files:")
        for file in missing_files:
            print(f"  - {file}")
        return False
    else:
        print("✅ All required files found")
        return True

def analyze_testbench():
    """Analyze the testbench for common issues"""
    print("\n📋 Analyzing testbench...")
    
    with open('tb/tb_asic_top.sv', 'r') as f:
        content = f.read()
    
    issues = []
    
    # Check for common simulation issues
    if 'initial begin' not in content:
        issues.append("No initial block found")
    
    if '$finish' not in content:
        issues.append("No $finish statement found")
        
    if 'wait(' in content:
        print("⚠️  Found wait() statements - these can cause simulation hangs if conditions aren't met")
    
    if 'fork' in content:
        print("ℹ️  Found fork/join blocks - parallel execution detected")
    
    if issues:
        print("❌ Potential issues:")
        for issue in issues:
            print(f"  - {issue}")
    else:
        print("✅ Basic testbench structure looks good")

def suggest_simulation_command():
    """Suggest simulation commands for different tools"""
    print("\n🔧 Suggested simulation commands:")
    print("\nFor Icarus Verilog:")
    print("  iverilog -g2012 -o sim rtl/*.v rtl/*.sv tb/tb_asic_top.sv")
    print("  vvp sim")
    
    print("\nFor ModelSim/QuestaSim:")
    print("  vlog -sv rtl/*.v tb/tb_asic_top.sv")
    print("  vsim -c tb_asic_top -do \"run -all; quit\"")
    
    print("\nFor Vivado:")
    print("  xvlog -sv rtl/*.v tb/tb_asic_top.sv")
    print("  xelab tb_asic_top")
    print("  xsim tb_asic_top -R")

def check_design_basics():
    """Check for basic design issues"""
    print("\n🔍 Checking design basics...")
    
    # Check asic_top module
    with open('rtl/asic_top.v', 'r') as f:
        asic_content = f.read()
    
    # Check chacha20_core module  
    with open('rtl/chacha20_core.v', 'r') as f:
        core_content = f.read()
    
    # Check for module instantiation match
    if 'ChaCha20 chacha_unit' in asic_content and 'module ChaCha20' in core_content:
        print("✅ ChaCha20 core instantiation looks correct")
    else:
        print("❌ ChaCha20 core instantiation may have issues")
    
    # Check for basic signals
    basic_signals = ['clk', 'rst_n', 'start', 'busy', 'done']
    missing_signals = []
    
    for signal in basic_signals:
        if signal not in asic_content:
            missing_signals.append(signal)
    
    if missing_signals:
        print(f"❌ Missing basic signals: {missing_signals}")
    else:
        print("✅ All basic control signals present")

def main():
    print("🚀 ChaCha20 ASIC Testbench Analyzer")
    print("=" * 40)
    
    # Change to main directory if not already there
    if os.path.exists('main'):
        os.chdir('main')
    
    # Run checks
    if not check_files():
        return 1
    
    analyze_testbench()
    check_design_basics()
    suggest_simulation_command()
    
    print("\n💡 Common simulation issues and solutions:")
    print("1. Clock not toggling - Check clock generation")
    print("2. Reset not released - Check reset sequence") 
    print("3. Infinite wait loops - Check wait conditions")
    print("4. Module not found - Check file includes/compilation order")
    print("5. Timing issues - Check setup/hold times")
    
    print("\n🎯 To run the actual simulation:")
    print("1. Install a Verilog simulator (Icarus, ModelSim, etc.)")
    print("2. Use the suggested commands above")
    print("3. Check the VCD output with GTKWave or similar")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
