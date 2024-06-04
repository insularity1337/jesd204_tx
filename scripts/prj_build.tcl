create_project -force jesd204b_tx ./prj -part xcku060-ffva1156-1-c

# tx gth + common
add_files {./ip/jesd204b_tx_phy/jesd204b_tx_phy.xci}

# core sources
add_files { \
  ./src/core/tx_char_replace.sv \
  ./src/core/tx_ila_gen.sv \
  ./src/core/tx_lmfc.sv
  ./src/core/tx_cu.sv \
  ./src/core/tx.sv \
  ./src/jesd204_tx_env.sv \
  ./src/jesd204_tx.sv
}

# bd
source ./scripts/ctrl_n_data_env.tcl

# regs
add_files { \
  ./regblock/jesd204b_reg_pkg.sv \
  ./regblock/jesd204b_reg.sv \
}

# wrapper
make_wrapper \
  -top \
  -files [get_files ./prj/jesd204b_tx.srcs/sources_1/bd/ctrl_n_data_env/ctrl_n_data_env.bd]

set_property used_in_simulation false \
  [get_files ./prj/jesd204b_tx.srcs/sources_1/bd/ctrl_n_data_env/ctrl_n_data_env.bd]

add_files \
  -norecurse \
  ./prj/jesd204b_tx.gen/sources_1/bd/ctrl_n_data_env/hdl/ctrl_n_data_env_wrapper.v

set_property used_in_simulation false \
  [get_files ./prj/jesd204b_tx.gen/sources_1/bd/ctrl_n_data_env/hdl/ctrl_n_data_env_wrapper.v]

add_files ./src/top.sv
set_property used_in_simulation false [get_files ./src/top.sv]

# constraints
add_files \
  -fileset constrs_1 \
  ./scripts/top.xdc

# simulation rx gth + common + xilinx core
add_files -fileset sim_1 {./ip/jesd204b_rx_phy/jesd204b_rx_phy.xci}
set_property used_in_synthesis false [get_files ./ip/jesd204b_rx_phy/jesd204b_rx_phy.xci]
set_property used_in_implementation false [get_files ./ip/jesd204b_rx_phy/jesd204b_rx_phy.xci]

add_files -fileset sim_1 {./ip/jesd204b_rx/jesd204b_rx.xci}
set_property used_in_synthesis false [get_files ./ip/jesd204b_rx/jesd204b_rx.xci]
set_property used_in_implementation false [get_files ./ip/jesd204b_rx/jesd204b_rx.xci]

# tb
add_files -fileset sim_1 { \
  ./qa/rx_env.sv \
  ./qa/tx_tb.sv \
}

start_gui