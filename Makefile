SUBDIRS := \
	rtl_alu/alu \
	rtl_counter/counter
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
