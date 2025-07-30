## Basys 3 Default Pin Assignments (constraint file)
## For XC7A35T FPGA (CPG236 package),
# Clock and Reset (Push‑buttons)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property PACKAGE_PIN V17 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

# Push-buttons
set_property PACKAGE_PIN U18 [get_ports btnC]    # Center button
set_property IOSTANDARD LVCMOS33 [get_ports btnC]
set_property PACKAGE_PIN T18 [get_ports btnU]    # Up
set_property PACKAGE_PIN R18 [get_ports btnD]    # Down
set_property PACKAGE_PIN V16 [get_ports btnL]    # Left
set_property PACKAGE_PIN V17 [get_ports btnR]    # Right
# USER SWITCHES
set_property PACKAGE_PIN U16 [get_ports sw[0]]
set_property PACKAGE_PIN E18 [get_ports sw[1]]
set_property PACKAGE_PIN R17 [get_ports sw[2]]
set_property PACKAGE_PIN T17 [get_ports sw[3]]
set_property IOSTANDARD LVCMOS33 [get_ports sw[*]]

# LEDs
set_property PACKAGE_PIN U16 [get_ports led[0]]
set_property PACKAGE_PIN E19 [get_ports led[1]]
set_property PACKAGE_PIN U19 [get_ports led[2]]
set_property PACKAGE_PIN V19 [get_ports led[3]]
set_property PACKAGE_PIN W18 [get_ports led[4]]
set_property PACKAGE_PIN V18 [get_ports led[5]]
set_property PACKAGE_PIN V17 [get_ports led[6]]
set_property PACKAGE_PIN V16 [get_ports led[7]]
set_property IOSTANDARD LVCMOS33 [get_ports led[*]]

# USB-UART (connected to FT2232 HQ)
set_property PACKAGE_PIN E12 [get_ports uart_tx]  # To PC
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property PACKAGE_PIN D12 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

# PMOD connectors (JA, JB, JC, JD)
# Pmod JA: pins JX2-JY1 etc. Example:
set_property PACKAGE_PIN D02 [get_ports pmod_ja[0]]
set_property IOSTANDARD LVCMOS33 [get_ports pmod_ja[*]]
# Similarly define pmod_jb[*], pmod_jc[*], pmod_jd[*]...

# PMOD connector specifics:
set_property PACKAGE_PIN C02 [get_ports {pmod_ja[1]}]; ...
# (Repeat for all 4 PMOD Jx connectors pins; refer to board manual for detailed mapping)

# HDMI out (if populated, omit if not used)
# set_property PACKAGE_PIN G17 [get_ports hdmi_cec]; # etc.

# PWR and Vaux sensors (unused logic if no measurement)

## Note:
# - Adjust pin names (`btnC`, `sw[0]`, `led[0]`, etc.) to match your module’s port names.
# - All IOSTANDARDs set to LVCMOS33 (same as Digilent spec).
# - The PMOD pin mapping must correspond to Pmod connector letter and index; refer to Basys 3 reference manual for mapping table.