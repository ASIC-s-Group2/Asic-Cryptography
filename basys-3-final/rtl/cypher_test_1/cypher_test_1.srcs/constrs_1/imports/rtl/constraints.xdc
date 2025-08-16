## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Buttons
set_property PACKAGE_PIN U18 [get_ports ready]    ;# Center button (enable)
set_property PACKAGE_PIN W19 [get_ports rst_n]    ;# Left button (reset)
set_property IOSTANDARD LVCMOS33 [get_ports {ready rst_n}]

## LEDs LD0-LD15 (random_number[0] to [15])
set_property PACKAGE_PIN L1  [get_ports {random_number[0]}]
set_property PACKAGE_PIN P1  [get_ports {random_number[1]}]
set_property PACKAGE_PIN N3  [get_ports {random_number[2]}]
set_property PACKAGE_PIN P3  [get_ports {random_number[3]}]
set_property PACKAGE_PIN U3  [get_ports {random_number[4]}]
set_property PACKAGE_PIN W3  [get_ports {random_number[5]}]
set_property PACKAGE_PIN V3  [get_ports {random_number[6]}]
set_property PACKAGE_PIN V13 [get_ports {random_number[7]}]

set_property PACKAGE_PIN U19 [get_ports {random_number[8]}]
set_property PACKAGE_PIN V14 [get_ports {random_number[9]}]
set_property PACKAGE_PIN V2  [get_ports {random_number[10]}]
set_property PACKAGE_PIN V17 [get_ports {random_number[11]}]
set_property PACKAGE_PIN V16 [get_ports {random_number[12]}]
set_property PACKAGE_PIN T17 [get_ports {random_number[13]}]
set_property PACKAGE_PIN T18 [get_ports {random_number[14]}]
set_property PACKAGE_PIN U17 [get_ports {random_number[15]}]

## PMOD JA (random_number[16] to [23])
set_property PACKAGE_PIN J1 [get_ports {random_number[16]}]
set_property PACKAGE_PIN L2 [get_ports {random_number[17]}]
set_property PACKAGE_PIN J2 [get_ports {random_number[18]}]
set_property PACKAGE_PIN G2 [get_ports {random_number[19]}]
set_property PACKAGE_PIN H1 [get_ports {random_number[20]}]
set_property PACKAGE_PIN K2 [get_ports {random_number[21]}]
set_property PACKAGE_PIN H2 [get_ports {random_number[22]}]
set_property PACKAGE_PIN G3 [get_ports {random_number[23]}]

## PMOD JB (random_number[24] to [31])
set_property PACKAGE_PIN A14 [get_ports {random_number[24]}]
set_property PACKAGE_PIN A16 [get_ports {random_number[25]}]
set_property PACKAGE_PIN B15 [get_ports {random_number[26]}]
set_property PACKAGE_PIN B16 [get_ports {random_number[27]}]
set_property PACKAGE_PIN A15 [get_ports {random_number[28]}]
set_property PACKAGE_PIN A17 [get_ports {random_number[29]}]
set_property PACKAGE_PIN C15 [get_ports {random_number[30]}]
set_property PACKAGE_PIN C16 [get_ports {random_number[31]}]

## IO Standard for all random_number ports
set_property IOSTANDARD LVCMOS33 [get_ports {random_number[*]}]

## Additional TRNG request input signal
set_property PACKAGE_PIN W16 [get_ports trng_request]
set_property IOSTANDARD LVCMOS33 [get_ports trng_request]

# vivado falsely flags the ring oscillator; manual override is needed
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets {ring_oscillator/chain[0]}]
