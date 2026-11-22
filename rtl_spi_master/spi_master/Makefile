.PHONY: lint test clean

SRCS := rtl/spi_master.v tb/tb_spi_master.v

lint:
	verilator --lint-only -Wall rtl/*.v

test:
	iverilog -g2012 -Wall -o sim.vvp $(SRCS)
	vvp -n sim.vvp > sim.log 2>&1 && cat sim.log && grep -q "TEST PASSED" sim.log

clean:
	rm -f sim.vvp sim.log *.vcd