set_property PACKAGE_PIN V26 [get_ports REFCLK_P]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports REFCLK_P]

set_property PACKAGE_PIN Y23  [get_ports DRPCLK]
set_property IOSTANDARD LVCMOS18 [get_ports DRPCLK]
set_property PACKAGE_PIN AA24 [get_ports CLK]
set_property IOSTANDARD LVCMOS18 [get_ports CLK]

set_property PACKAGE_PIN V29 [get_ports SYNC_n]
set_property IOSTANDARD LVCMOS18 [get_ports SYNC_n]
set_property PACKAGE_PIN W29 [get_ports SYSREF]
set_property IOSTANDARD LVCMOS18 [get_ports SYSREF]

create_clock \
  -name DRPCLK \
  -period 10.0 \
  -waveform {0.0 5.0} \
  [get_ports DRPCLK]

create_clock \
  -name CLK \
  -period 5.0 \
  -waveform {0.0 2.5} \
  [get_ports CLK]

create_clock \
  -name REFCLK \
  -period 5.0 \
  -waveform {0.0 2.5} \
  [get_ports REFCLK_P]

set_clock_groups \
  -asynchronous \
  -group {DRPCLK} \
  -group {CLK} \
  -group {REFCLK}