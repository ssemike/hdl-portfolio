.PHONY: test lint clean

SRC := rtl/counter.v tb/tb_counter.v

test:
	iverilog -g2012 -Wall -o sim.vvp $(SRC)
	vvp -n sim.vvp > sim.log 2>&1 && cat sim.log && grep -q "TEST PASSED" sim.log

lint:
	verilator --lint-only -Wall rtl/*.v

clean:
	rm -f sim.vvp sim.log *.vcd