COMMA_DET_SRC = ./src
QA_DIR = ./qa
IVERILOG_FLAGS = -g2012 -W all

comma_det_files := $(COMMA_DET_SRC)/comma_detect.sv
comma_tb_files := $(QA_DIR)/comma_detect_tb.sv

comma_test:
	iverilog $(IVERILOG_FLAGS) $(comma_tb_files) $(comma_det_files) -o comma.vvp

lmfc_test:
	clear; rm *.vcd *.vvp; iverilog $(IVERILOG_FLAGS) ./src/tx/tx_lmfc.sv ./qa/tx_lmfc_tb.sv -o lmfc.vvp; vvp lmfc.vvp; gtkwave lmfc.vcd

ila_test:
	clear; rm *.vcd *.vvp; iverilog $(IVERILOG_FLAGS) ./src/tx/tx_ila_gen.sv ./qa/tx_ila_gen_tb.sv -o ila.vvp; vvp ila.vvp; gtkwave ila.vcd

tx_test:
	clear; rm *.vcd *.vvp; iverilog $(IVERILOG_FLAGS) ./src/tx/tx_cu.sv ./src/tx/tx_ila_gen.sv ./src/tx/tx_lmfc.sv ./src/tx/tx_char_replace.sv ./src/tx/tx.sv ./qa/tx_tb.sv -o tx.vvp; vvp tx.vvp; gtkwave tx.vcd

.DEFAULT_GOAL := tx_test
