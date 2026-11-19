THISDIR := $(shell pwd)

# frpc/frps 由 frp.sh 在运行时按 nvram 里的版本下载到 /tmp/frp 或 /etc/storage/bin，
# romfs 只安装脚本。原来构建期下载的 0.51.3 从未打包进固件，而且只支持 INI 配置，
# 与 frp_script.sh 生成的 TOML 不兼容，这里不再下载。
all:
	@echo "frp: frpc/frps are downloaded at runtime"

clean:
	@true

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/frp.sh /usr/bin/frp.sh
	$(ROMFSINST) /etc_ro/frp_script.sh
