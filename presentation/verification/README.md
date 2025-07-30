# ChaCha20 ASIC Verification Suite

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
