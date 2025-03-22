#!/bin/sh
#nvram set ntp_ready=0

if [ ! -f /tmp/script/_opt_script_check ] ; then
	mkdir -p /tmp/script
	echo "#!/bin/bash" > /tmp/script/_opt_script_check
	echo "#进程守护脚本" >> /tmp/script/_opt_script_check
	chmod +x /tmp/script/_opt_script_check
fi
mkdir -p /tmp/dnsmasq.dom
logger -t "为防止dnsmasq启动失败，创建/tmp/dnsmasq.dom/"

#wifi中继脚本
if [ ! -x /etc/storage/sh_ezscript.sh ]; then
	cp /etc_ro/sh_ezscript.sh /etc/storage/sh_ezscript.sh
fi
if [ -x /etc/storage/ap_script.sh ]; then
	/etc/storage/ap_script.sh >/dev/null 2>&1 &
else
	cp /etc_ro/ap_script.sh /etc/storage/ap_script.sh
fi

if [ $(nvram get caddy_enable) = 1 ] ; then
logger -t "自动启动" "正在启动文件管理"
/usr/bin/caddy.sh start &
fi

logger -t "自动启动" "正在检查路由是否已连接互联网！"
count=0
while :
do
	ping -c 1 -W 1 -q 223.5.5.5 1>/dev/null 2>&1
	if [ "$?" == "0" ]; then
		break
	fi
	ping -c 1 -W 1 -q www.baidu.com 1>/dev/null 2>&1
	if [ "$?" == "0" ]; then
		break
	fi
	sleep 5
	ping -c 1 -W 1 -q 119.29.29.29 1>/dev/null 2>&1
	if [ "$?" == "0" ]; then
		break
	fi
	ping -c 1 -W 1 -q 8.8.8.8 1>/dev/null 2>&1
	if [ "$?" == "0" ]; then
		break
	fi
	sleep 5
	count=$((count+1))
	if [ $count -gt 18 ]; then
		break
	fi
done

if [ $(nvram get adbyby_enable) = 1 ] ; then
logger -t "自动启动" "正在启动adbyby plus+"
/usr/bin/adbyby.sh start &
fi

if [ $(nvram get sdns_enable) = 1 ] ; then
smartdns_conf="/etc/storage/smartdns_custom.conf"
dnsmasq_Conf="/etc/storage/dnsmasq/dnsmasq.conf"
smartdns_Ini="/etc/storage/smartdns_conf.ini"
sdns_port=$(nvram get sdns_port)
   if [ -f "$smartdns_conf" ] ; then
       sed -i '/去广告/d' $smartdns_conf
       sed -i '/adbyby/d' $smartdns_conf
       sed -i '/no-resolv/d' "$dnsmasq_Conf"
       sed -i '/server=127.0.0.1#'"$sdns_portd"'/d' "$dnsmasq_Conf"
       sed -i '/port=0/d' "$dnsmasq_Conf"
       rm  -f "$smartdns_Ini"
   fi
logger -t "自动启动" "正在启动 SmartDNS..."
/usr/bin/smartdns.sh start &
fi


if [ $(nvram get koolproxy_enable) = 1 ] ; then
logger -t "自动启动" "正在启动koolproxy"
/usr/bin/koolproxy.sh start &
fi

if [ $(nvram get aliddns_enable) = 1 ] ; then
logger -t "自动启动" "正在启动阿里ddns"
/usr/bin/aliddns.sh start &
fi

if [ $(nvram get cloudflare_enable) = 1 ] ; then
logger -t "自动启动" "正在启动CF-ddns"
/usr/bin/cloudflare.sh start &
fi

if [ $(nvram get vnts_enable) = 1 ] ; then
logger -t "自动启动" "正在启动VNT服务端"
/usr/bin/vnts.sh start &
fi

if [ $(nvram get vntcli_enable) = 1 ] ; then
logger -t "自动启动" "正在启动VNT客户端"
/usr/bin/vnt.sh start &
fi

if [ $(nvram get easytier_enable) = 1 ] || [ $(nvram get easytier_web_enable) = 1 ] ; then
logger -t "自动启动" "正在启动EasyTier"
/usr/bin/easytier.sh start &
fi

if [ $(nvram get wxsend_enable) = 1 ] ; then
logger -t "自动启动" "正在启动微信推送"
/usr/bin/wxsend.sh start &
fi

if [ $(nvram get ss_enable) = 1 ] ; then
logger -t "自动启动" "正在启动科学上网"
/usr/bin/shadowsocks.sh start &
fi

if [ $(nvram get adg_enable) = 1 ] ; then
logger -t "自动启动" "正在启动adguardhome"
/usr/bin/adguardhome.sh start &
fi

if [ $(nvram get wyy_enable) = 1 ] ; then
logger -t "自动启动" "正在启动音乐解锁"
/usr/bin/unblockmusic.sh start &
fi

if [ $(nvram get zerotier_enable) = 1 ] ; then
logger -t "自动启动" "正在启动zerotier"
/usr/bin/zerotier.sh start &
fi

if [ $(nvram get bafa_enable) = 1 ] ; then
logger -t "自动启动" "正在启动巴法云物联网"
/usr/bin/bafa.sh start &
fi

if [ $(nvram get nvpproxy_enable) = 1 ] ; then
logger -t "自动启动" "正在启动nvpproxy"
/usr/bin/nvpproxy.sh start &
fi

if [ $(nvram get ddnsto_enable) = 1 ] ; then
logger -t "自动启动" "正在启动ddnsto"
/usr/bin/ddnsto.sh start &
fi

if [ $(nvram get aliyundrive_enable) = 1 ] ; then
logger -t "自动启动" "正在启动阿里云盘"
/usr/bin/aliyundrive-webdav.sh start &
fi

if [ $(nvram get virtualhere_enable) = 1 ] ; then
logger -t "自动启动" "正在启动Virtualhere"
/usr/bin/virtualhere.sh start &
fi

if [ $(nvram get uu_enable) = 1 ] ; then
logger -t "自动启动" "正在启动网易UU游戏加速器"
/usr/bin/uuplugin.sh start &
fi

if [ $(nvram get lucky_enable) = 1 ] ; then
logger -t "自动启动" "正在启动lucky"
/usr/bin/lucky.sh start &
fi

if [ $(nvram get alist_enable) = 1 ] ; then
logger -t "自动启动" "正在启动alist"
/usr/bin/alist.sh start &
fi

if [ $(nvram get natpierce_enable) = 1 ] ; then
logger -t "自动启动" "正在启动皎月连"
/usr/bin/natpierce.sh start &
fi

if [ $(nvram get tailscale_enable) = 1 ] ; then
logger -t "自动启动" "正在启动tailscale"
/usr/bin/tailscale.sh start &
fi

if [ $(nvram get cloudflared_enable) = 1 ] ; then
logger -t "自动启动" "正在启动cloudflared"
/usr/bin/cloudflared.sh start &
fi

if [ $(nvram get wireguard_enable) = 1 ] ; then
logger -t "自动启动" "正在启动wireguard"
/usr/bin/wireguard.sh start &
fi
