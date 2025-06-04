SRC_NAME := N2N-2.8.x-pthread
THISDIR := $(shell pwd)

all:
	

clean:
	( if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) clean ; \
	fi )

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/edge /usr/bin/edge
	$(ROMFSINST) -p +x $(THISDIR)/n2n-benchmark /usr/bin/n2n-benchmark
	$(ROMFSINST) -p +x $(THISDIR)/supernode /usr/bin/supernode

