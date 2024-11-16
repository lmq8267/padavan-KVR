#!/bin/sh

github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
scriptname=$(basename $0)
if [ ! -z "$scriptname" ] ; then
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
fi
set -e -o pipefail
[ "$1" != "force" ] && [ "$(nvram get ss_update_gfwlist)" != "1" ] && exit 0
#GFWLIST_URL="$(nvram get gfwlist_url)"
logger -st "gfwlist" "开始更新gfwlist  https://github.com/YW5vbnltb3Vz/domain-list-community/blob/release/gfwlist.txt"
for proxy in $github_proxys ; do
curl -L -k -S -o /tmp/gfwlist_list_origin.conf --connect-timeout 15 --retry 5 "${proxy}https://github.com/YW5vbnltb3Vz/domain-list-community/raw/refs/heads/release/gfwlist.txt" || wget --no-check-certificate -q -O /tmp/gfwlist_list_origin.conf "${proxy}https://github.com/YW5vbnltb3Vz/domain-list-community/raw/refs/heads/release/gfwlist.txt"
if [ "$?" = 0 ] ; then
logger -st "gfwlist" "下载成功gfwlist.txt"
break
else
logger -st "gfwlist" "下载${proxy}https://github.com/YW5vbnltb3Vz/domain-list-community/raw/refs/heads/release/gfwlist.txt 失败"
fi
done
lua /etc_ro/ss/gfwupdate.lua
count=`awk '{print NR}' /tmp/gfwlist_list.conf|tail -n1`
if [ $count -gt 1000 ]; then
rm -f /etc/storage/gfwlist/gfwlist_listnew.conf
cp -r /tmp/gfwlist_list.conf /etc/storage/gfwlist/gfwlist_listnew.conf
mtd_storage.sh save >/dev/null 2>&1
mkdir -p /etc/storage/gfwlist/
logger -st "gfwlist" "Update done"
if [ $(nvram get ss_enable) = 1 ]; then
lua /etc_ro/ss/gfwcreate.lua
logger -st "SS" "重启ShadowSocksR Plus+..."
/usr/bin/shadowsocks.sh stop
/usr/bin/shadowsocks.sh start
fi
else
logger -st "gfwlist" "列表下载失败,请手动复制https://github.com/YW5vbnltb3Vz/domain-list-community/blob/release/gfwlist.txt文本内容到https://base64.us进行解码"
logger -st "gfwlist" "复制解码内容替换/etc/storage/gfwlist/gfwlist_listnew.conf"
fi
rm -f /tmp/gfwlist_list_origin.conf
rm -f /tmp/gfwlist_list.conf
