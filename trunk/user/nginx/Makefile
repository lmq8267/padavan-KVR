THISDIR=$(shell pwd)

PPPD_DIR=$(ROOTDIR)/user/nginx

CFLAGS  += -O2
CFLAGS  += -ffunction-sections -fdata-sections
LDFLAGS += -Wl,--gc-sections

SRC_VER = 1.27.4
SRC_NAME = nginx-$(SRC_VER)
SRC_FILE = $(SRC_NAME).tar.gz
SRC_URL := http://nginx.org/download/$(SRC_FILE)

all: download_test extra_test config_test
	$(MAKE) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O $(SRC_FILE) $(SRC_URL); \
		wget -t5 --timeout=20 --no-check-certificate -O pcre-8.45.zip https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.zip; \
		unzip -qq pcre-8.45.zip ; \
		wget -t5 --timeout=20 --no-check-certificate -O openssl-1.1.1t.tar.gz https://www.openssl.org/source/openssl-1.1.1t.tar.gz; \
		tar -xf openssl-1.1.1t.tar.gz; \
		wget -t5 --timeout=20 --no-check-certificate -O zlib-1.3.1.tar.gz http://www.zlib.net/zlib-1.3.1.tar.gz; \
		tar -xf zlib-1.3.1.tar.gz; \
	fi )

extra_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar xf $(SRC_FILE); \
		sed -i 's/if \/bin\/sh/if \(echo march \| grep march\) \|\| \/bin\/sh/' $(SRC_NAME)/auto/feature ; \
		sed -i "s/configure/configure --build=$(HOST_BUILD) --host=$(HOST_TARGET) --enable-utf8 --enable-unicode-properties/g" $(SRC_NAME)/auto/lib/pcre/make ; \
		sed -i "s|./config|./config CC=gcc AR=ar LD=ld RANLIB=ranlib|g" $(SRC_NAME)/auto/lib/openssl/make ; \
		sed -i 's/if \[ -x/if \(echo march \| grep march\)\; then ngx_size=4; elif \[ -x/' $(SRC_NAME)/auto/types/sizeof ; \
	fi )

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure && touch config_done; \
	fi )

configure:
	( cd $(SRC_NAME) ; \
	./configure \
	--with-compat \
	--with-pcre=$(THISDIR)/pcre-8.45 \
	--with-http_ssl_module \
	--with-openssl=$(THISDIR)/openssl-1.1.1t \
	--with-zlib=$(THISDIR)/zlib-1.3.1 \
	--prefix=/tmp/nginx \
	--conf-path=/etc/storage/nginx.conf \
	--pid-path=/var/run/nginx.pid \
	--error-log-path=/tmp/nginx/error.log \
	--http-log-path=/tmp/nginx/access.log \
	--with-http_realip_module \
	--with-http_sub_module \
	--with-http_auth_request_module \
	--with-http_gzip_static_module \
	--with-http_v2_module \
	--with-http_v3_module \
	--with-file-aio \
	--with-http_stub_status_module \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(STRIP) $(THISDIR)/$(SRC_NAME)/objs/nginx
	upx --lzma --best $(THISDIR)/$(SRC_NAME)/objs/nginx
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_NAME)/objs/nginx /usr/bin/nginx
