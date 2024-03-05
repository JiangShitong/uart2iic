create_clock -period 10.000 [get_ports clk]
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports clk]

set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS33} [get_ports rst_n]
set_property -dict {PACKAGE_PIN D11} [get_ports RXD]
set_property -dict {PACKAGE_PIN C14} [get_ports TXD]
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports i2c_sda]
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports i2c_scl]