#!/bin/sh
#chongshengB 2020
caddy_enable=`nvram get caddy_enable`
caddy_wan=`nvram get caddy_wan`
caddy_file=`nvram get caddy_file`
caddy_storage=`nvram get caddy_storage`
caddy_dir=`nvram get caddy_dir`
http_username=`nvram get http_username`
caddyf_wan_port=`nvram get caddyf_wan_port`
caddyw_wan_port=`nvram get caddyw_wan_port`
caddy_wip6=`nvram get caddy_wip6`
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)

caddy_dl() {

       if [ ! -f "$caddy_dir/caddy/caddy_filebrowser" ]; then
		logger -t "【caddy】" "找不到caddy_filebrowser文件，下载caddy_filebrowser程序"
		for proxy in $github_proxys ; do
		curl -L -k -o "$caddy_dir/caddy/caddy_filebrowser" --connect-timeout 10 --retry 3 "${proxy}https://github.com/lmq8267/padavan-KVR/raw/refs/heads/main/trunk/user/caddy/caddy_filebrowser" || wget --no-check-certificate -O "$caddy_dir/caddy/caddy_filebrowser" "${proxy}https://github.com/lmq8267/padavan-KVR/raw/refs/heads/main/trunk/user/caddy/caddy_filebrowser"
		if [ "$?" = 0 ] ; then
			chmod +x $caddy_dir/caddy/caddy_filebrowser
			if [ $(($($caddy_dir/caddy/caddy_filebrowser -h | wc -l))) -gt 3 ] ; then
				logger -t "【caddy】" "$caddy_dir/caddy/caddy_filebrowser 下载成功"
				break
       		else
	   			logger -t "【caddy】" "下载不完整，删除...请手动下载 ${proxy}https://github.com/lmq8267/padavan-KVR/raw/refs/heads/main/trunk/user/caddy/caddy_filebrowser 上传到  $caddy_dir/caddy/caddy_filebrowser"
				rm -f $caddy_dir/caddy/caddy_filebrowser
	  		fi
		else
			logger -t "【caddy】" "下载失败${proxy}https://github.com/lmq8267/padavan-KVR/raw/refs/heads/main/trunk/user/caddy/caddy_filebrowser"
   		fi
		
		done
	fi		
}

caddy_keep() {
	logger -t "【caddy】" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof caddy_filebrowser\`" ] && logger -t "进程守护" "caddy 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check #【caddy】
	OSC

	fi

}

caddy_start() {
	if [ "$caddy_enable" = "1" ] ;then
	       logger -t "【caddy】" "正在启动..."
	       sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
		mkdir -p $caddy_dir/caddy
	fi
	caddybin="/usr/bin/caddy_filebrowser"
	if [ ! -f "$caddybin" ] && [ ! -f "$caddy_dir/caddy/caddy_filebrowser" ] ; then
			caddy_dl
	fi
	/etc/storage/caddy_script.sh
	if [ "$caddy_wan" = "1" ] ; then
			if [ "$caddy_file" = "0" ] || [ "$caddy_file" = "2" ]; then
				fport=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$caddyf_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
				if [ "$fport" = 0 ] ; then
					logger -t "【caddy】" "WAN放行 $caddyf_wan_port tcp端口"
					iptables -t filter -I INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
					if [ "$caddy_wip6" = 1 ]; then
						ip6tables -t filter -I INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
					fi
				fi
			fi
			if [ "$caddy_file" = "1" ] || [ "$caddy_file" = "2" ]; then
				wport=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$caddyw_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
				if [ "$wport" = 0 ] ; then
					logger -t "【caddy】" "WAN放行 $caddyw_wan_port tcp端口"
					iptables -t filter -I INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
					if [ "$caddy_wip6" = 1 ]; then
						ip6tables -t filter -I INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
					fi
				fi
			fi
		fi
		[ ! -z "`pidof caddy_filebrowser`" ] && logger -t "【caddy】" "文件管理服务已启动" && caddy_keep
	
}

caddy_close() {
	scriptname=$(basename $0)
	sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	iptables -t filter -D INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT >/dev/null 2>&1
	iptables -t filter -D INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT >/dev/null 2>&1
	if [ "$wipv6" = 1 ]; then
		ip6tables -t filter -D INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT >/dev/null 2>&1
		ip6tables -t filter -D INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT >/dev/null 2>&1
	fi
	if [ ! -z "`pidof caddy_filebrowser`" ]; then
	        killall caddy_filebrowser
		killall -9 caddy_filebrowser
                #rm -rf "$caddy_dir/caddy/caddy_filebrowser"
		[ -z "`pidof caddy_filebrowser`" ] && logger -t "【caddy】" "已关闭文件管理服务."
	fi

}

case $1 in
start)
caddy_start &
;;
stop)
caddy_close
;;
esac
