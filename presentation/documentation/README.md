# ChaCha20 ASIC Presentation Materials

## Directory Structure

### Images
- `chacha20_chip_main.png` - Main 3D chip visualization
- `chacha20_chip_isometric.png` - Isometric 3D view
- `chacha20_chip_top_view.png` - Top view floorplan
- `chacha20_block_diagram.png` - Architecture block diagram
- `chacha20_dataflow.png` - Data flow diagram
- `chacha20_main_fsm.png` - Main controller FSM with sub-states
- `chacha20_core_fsm.png` - ChaCha20 core FSM diagram
- `chacha20_complete_fsm.png` - Complete hierarchical FSM overview
- `chacha20_nested_fsm.png` - **Nested FSM showing core embedded in main controller**
- `chacha20_detailed_nested.png` - **Zoom-in view of nested core FSM**

### Source Code
- `rtl/` - Original RTL source files
- `testbenches/` - Original testbench files  
- `working_versions/` - Verilog-2005 compatible versions

### Verification
- `verification/testbenches/working/` - **Ready-to-run testbenches with RTL**
- `verification/testbenches/unit_tests/` - Individual module tests
- `verification/testbenches/integration/` - Full system tests
- `verification/simulation_results/` - All VCD waveform files organized
- `verification/scripts/` - Test automation tools

### Simulation Results
- `*.vcd` - Waveform files for analysis

### Visualization
- Python scripts for generating diagrams

## Quick Start

### Run Simulation (Recommended)
```bash
cd verification/testbenches/working/
python run_simulation.py
```

### Run Original Source
```bash
cd source_code/working_versions/
python run_simulation.py
```

### Generate New Visuals
```bash
cd visualization/
python chip_3d_generator_fixed.py
python block_diagram_generator_fixed.py
```

## Presentation Talking Points

### Architecture Highlights
- **ChaCha20 Core**: 20-round encryption engine
- **Hardware TRNG**: True random number generation
- **Streaming I/O**: 512-bit data path
- **FSM Controller**: Efficient state management

### Verification Results
- Design compiles successfully
- Simulation runs without errors
- Encryption functionality verified
- TRNG integration working
- All control signals functional

### Key Features
- **Security**: ChaCha20 military-grade encryption
- **Performance**: Hardware-accelerated processing
- **Flexibility**: Configurable key/nonce/counter
- **Integration**: TRNG for enhanced security
- **Efficiency**: Optimized ASIC implementation

### Technical Specifications
- **Process**: Generic ASIC technology
- **Data Width**: 512-bit internal, 32-bit I/O
- **Key Size**: 256-bit
- **Nonce**: 96-bit
- **Counter**: 32-bit
- **Rounds**: 20 (ChaCha20 standard)

## Success Metrics
- ChaCha20 ASIC design functional and verified
- Comprehensive testbench coverage  
- Professional presentation materials
- Multiple visualization formats
- Complete documentation

---
**Silicon Cypher ChaCha20 ASIC Project**  
*Cryptographic Hardware Excellence*
