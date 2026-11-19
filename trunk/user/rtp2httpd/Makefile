THISDIR := $(shell pwd)

all:

clean:

romfs:
	# rtp2httpd：GPL-2.0，源码 https://github.com/stackia/rtp2httpd
	$(ROMFSINST) -p +x $(THISDIR)/rtp2httpd /usr/bin/rtp2httpd
	$(ROMFSINST) -p +x $(THISDIR)/rtp2httpd.sh /usr/bin/rtp2httpd.sh
	$(ROMFSINST) $(THISDIR)/rtp2httpd.conf /etc_ro/rtp2httpd.conf
