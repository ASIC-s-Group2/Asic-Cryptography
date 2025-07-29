## Clock signal
## .xdc because is the offical extention Vivado expects
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Enable button (e.g., center button)
set_property PACKAGE_PIN U18 [get_ports enable]
set_property IOSTANDARD LVCMOS33 [get_ports enable]

## Reset button (e.g., left button)
set_property PACKAGE_PIN W19 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## LEDs to show output
set_property PACKAGE_PIN U16 [get_ports {random_byte[0]}]
set_property PACKAGE_PIN E19 [get_ports {random_byte[1]}]
set_property PACKAGE_PIN U19 [get_ports {random_byte[2]}]
set_property PACKAGE_PIN V19 [get_ports {random_byte[3]}]
set_property PACKAGE_PIN W18 [get_ports {random_byte[4]}]
set_property PACKAGE_PIN U15 [get_ports {random_byte[5]}]
set_property PACKAGE_PIN V18 [get_ports {random_byte[6]}]
set_property PACKAGE_PIN M14 [get_ports {random_byte[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {random_byte[*]}]
