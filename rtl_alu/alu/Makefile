SRC = rtl/alu.v tb/tb_alu.v
	
test:
	iverilog -g2012 -Wall -o sim.vvp $(SRC)
	vvp -n sim.vvp | tee sim.log
	grep -q "TEST PASSED" sim.log

lint:
	verilator --lint-only -Wall rtl/*.v

clean:
	rm -f sim.vvp sim.log *.vcd