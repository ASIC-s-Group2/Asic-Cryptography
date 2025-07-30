
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
