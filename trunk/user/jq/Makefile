SRC_NAME = jq-1.7.1
SRC_URL = https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-1.7.1.tar.gz
THISDIR = $(shell pwd)

all:


download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL); \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar -xf $(SRC_NAME).tar.gz; \
	fi )
	
config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure && touch config_done; \
	fi )

configure:
	( cd $(SRC_NAME) ; \
	autoreconf -ivf ; \
	export CFLAGS="$(CFLAGS) -O2 -pthread -fstack-protector-all" ; \
	./configure \
        --disable-maintainer-mode \
        	--disable-docs \
        	--disable-valgrind \
        	--with-oniguruma=builtin \
        	--enable-static \
            	--enable-all-static \
		--prefix=/usr \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) ; \
	)

compress:
	( if [ -f $(SRC_NAME)/jq ]; then \
		$(STRIP) $(SRC_NAME)/jq ; \
		upx --lzma --best $(SRC_NAME)/jq ; \
		echo "jq compressed successfully" ; \
	else \
		echo "jq not found, skipping compression" ; \
	fi )

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/jq /usr/bin/jq
