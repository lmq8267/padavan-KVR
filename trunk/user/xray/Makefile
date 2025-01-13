XRAY_VERSION := 1.8.24
XRAY_URL := https://codeload.github.com/XTLS/Xray-core/tar.gz/v$(XRAY_VERSION)
XRAY_DIR = xray-core/Xray-core-$(XRAY_VERSION)/main

THISDIR = $(shell pwd)

all: download build_extract build

download:
	( if [ ! -f $(THISDIR)/Xray-core-$(XRAY_VERSION).tar.gz ]; then \
	curl --create-dirs -L $(XRAY_URL) -o $(THISDIR)/Xray-core-$(XRAY_VERSION).tar.gz ; \
	fi )

build_extract:
	mkdir -p $(THISDIR)/xray-core
	mkdir -p $(THISDIR)/bin
	( if [ ! -d $(THISDIR)/xray-core/Xray-core-$(XRAY_VERSION) ]; then \
	rm -rf $(THISDIR)/xray-core/* ; \
	tar zxf $(THISDIR)/Xray-core-$(XRAY_VERSION).tar.gz -C $(THISDIR)/xray-core ; \
	fi )

build:
	( sed -i "s/go 1.21.4/go 1.23.4/g" $(THISDIR)/xray-core/Xray-core-$(XRAY_VERSION)/go.mod; \
	cd $(THISDIR)/$(XRAY_DIR); \
	GOOS=linux GOARCH=mipsle CGO_ENABLED=0 GOMIPS=softfloat go build -o $(THISDIR)/bin/xray -trimpath -ldflags "-s -w -buildid="; \
	upx --lzma --best $(THISDIR)/bin/xray; \
	)

clean:
	rm -rf $(THISDIR)/xray-core
	rm -rf $(THISDIR)/bin

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/bin/xray /usr/bin/xray
