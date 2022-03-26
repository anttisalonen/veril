## FPGA Configuration I/O Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Board Clock: 100 MHz
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {clk}];
create_clock -name clk -period 10.00 [get_ports {clk}];

# uart
set_property -dict {PACKAGE_PIN R12  IOSTANDARD LVCMOS33} [get_ports { out_uart_txd }];
set_property -dict {PACKAGE_PIN V12  IOSTANDARD LVCMOS33} [get_ports { in_uart_rxd }];

set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {in_rst}];