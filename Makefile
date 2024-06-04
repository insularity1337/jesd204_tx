clean:
	rm -rf ./regblock ./html ./prj *.jou *.log *vivado* .Xil/

regblock:
	peakrdl regblock ./rdl/jesd204b_reg.rdl -o ./regblock --cpuif apb4-flat

html:
	peakrdl html ./rdl/jesd204b_reg.rdl -o ./html

vivado_prj: clean regblock html
	vivado -mode tcl -journal ~/vivado.jou -log ~/.vivado.log -source ./scripts/prj_build.tcl

.DEFAULT_GOAL := vivado_prj