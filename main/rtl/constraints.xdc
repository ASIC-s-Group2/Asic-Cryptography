## Clock signal
## .xdc because is the offical extention Vivado expects
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Enable button (e.g., center button)
set_property PACKAGE_PIN U18 [get_ports ready]
set_property IOSTANDARD LVCMOS33 [get_ports ready]

## Reset button (e.g., left button)
set_property PACKAGE_PIN W19 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## LEDs to show output
# Connect random_number to LEDs or GPIO (example for 8 LEDs)
set_property PACKAGE_PIN T14 [get_ports {random_number[0]}]
set_property PACKAGE_PIN T15 [get_ports {random_number[1]}]
set_property PACKAGE_PIN T16 [get_ports {random_number[2]}]
set_property PACKAGE_PIN T17 [get_ports {random_number[3]}]
set_property PACKAGE_PIN U14 [get_ports {random_number[4]}]
set_property PACKAGE_PIN U15 [get_ports {random_number[5]}]
set_property PACKAGE_PIN U16 [get_ports {random_number[6]}]
set_property PACKAGE_PIN U17 [get_ports {random_number[7]}]
# ... Add more pins up to [31] if desired
