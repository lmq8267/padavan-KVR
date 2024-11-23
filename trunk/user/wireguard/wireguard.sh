#!/bin/sh

tun_name="$(nvram get wireguard_tun)"
wg_mtu="$(nvram get wireguard_mtu)"
wg_enable="$(nvram get wireguard_enable)"
[ -z "$tun_name" ] && tun_name="wg0"
[ -z "$wg_mtu" ] && wg_mtu="1420"
tun_name="$(echo $tun_name | tr -d ' ')"
localip="$(nvram get wireguard_localip)"
localip6="$(nvram get wireguard_localip6)"
	
start_wg() {
	
	[ "$wg_enable" = "1" ] || exit 1
	if [ ! -s /etc/storage/wg0.conf ]; then
    		logger -t "【WIREGUARD】" "/etc/storage/wg0.conf 配置文件为空，退出运行."
    		exit 1
	fi
	logger -t 【WIREGUARD】" "正在启动wireguard"
	ifconfig ${tun_name} down
	ip link del dev ${tun_name}
 	logger -t 【WIREGUARD】" "创建虚拟网卡 ${tun_name}"
	ip link add dev ${tun_name} type wireguard
 	logger -t 【WIREGUARD】" "使用配置文件 /etc/storage/wg0.conf"
	wg setconf ${tun_name} /etc/storage/wg0.conf
	[ -z "$localip" ] || ip -4 addr add dev ${tun_name} ${localip}
	[ -z "$localip6" ] || ip -6 addr add dev ${tun_name} ${localip6}
	ip link set dev ${tun_name} mtu ${wg_mtu}
	#ip addr add $localip dev ${tun_name}
	iptables -I INPUT -i ${tun_name} -j ACCEPT
	#iptables -I FORWARD -i ${tun_name} -o ${tun_name} -j ACCEPT
	iptables -I FORWARD -i ${tun_name} -j ACCEPT
	iptables -t nat -I POSTROUTING -o ${tun_name} -j MASQUERADE
	ifconfig ${tun_name} up
 	if [ $? -eq 0 ]; then
		logger -t 【WIREGUARD】" "已启动"
   	fi
}


stop_wg() {
	ifconfig ${tun_name} down
	ip link del dev ${tun_name}
	iptables -D INPUT -i ${tun_name} -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i ${tun_name} -j ACCEPT 2>/dev/null
	iptables -t nat -D POSTROUTING -o ${tun_name} -j MASQUERADE 2>/dev/null
	logger -t "【WIREGUARD】" "正在关闭wireguard"
	}



case $1 in
start)
	start_wg
	;;
stop)
	stop_wg
	;;
*)
	echo "check"
	#exit 0
	;;
esac
