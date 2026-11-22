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
	@for d in $(SUBDIRS); do \
		$(MAKE) -C $$d lint || exit 1; \
	done

test:
	@for d in $(SUBDIRS); do \
		$(MAKE) -C $$d test || exit 1; \
	done

clean:
	@for d in $(SUBDIRS); do \
		$(MAKE) -C $$d clean || exit 1; \
	done
