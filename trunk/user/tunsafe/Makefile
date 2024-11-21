SRC_NAME := TunSafe-85a871c
THISDIR := $(shell pwd)

all:
	

clean:
	( if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) clean ; \
	fi )

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/tunsafe /usr/bin/tunsafe

