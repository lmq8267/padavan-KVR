THISDIR = $(shell pwd)

# 目录里的 AdGuardHome 是 v0.106.3 旧版本，romfs 不安装；运行时由 adguardhome.sh 下载最新版。
# 按需求保留旧二进制，不做删除。
all:

clean:

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/adguardhome.sh /usr/bin/adguardhome.sh