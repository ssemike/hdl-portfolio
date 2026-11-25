SUBDIRS := \
	rtl_alu/alu \
	rtl_counter/counter\
	rtl_tick_gen/tick_gen\
	rtl_debouncer/debouncer\
	rtl_spi_master/spi_master\
	rtl_uart_tx/uart_tx\
	rtl_uart_rx/uart_rx\
	rtl_pwm/pwm\
	rtl_i2c_master/i2c_master\
	
.PHONY: lint test clean

lint:
	@fail=0; for d in $(SUBDIRS); do \
		$(MAKE) -C $$d lint || { echo "LINT FAILED: $$d"; fail=1; }; \
	done; exit $$fail

test:
	@fail=0; for d in $(SUBDIRS); do \
		$(MAKE) -C $$d test || { echo "TEST FAILED: $$d"; fail=1; }; \
	done; exit $$fail

clean:
	@for d in $(SUBDIRS); do \
		$(MAKE) -C $$d clean || exit 1; \
	done
