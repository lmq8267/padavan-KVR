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

caddy_dl() {
       caddybin="/usr/bin/caddy_filebrowser"
       if [ ! -f "$caddy_dir/caddy/caddy_filebrowser" ]; then
			logger -t "【caddy】" "找不到caddy_filebrowser文件，下载caddy_filebrowser程序"
			curl -L -k -s -o $caddy_dir/caddy/caddy_filebrowser --connect-timeout 10 --retry 3 https://cdn.jsdelivr.net/gh/chongshengB/rt-n56u/trunk/user/caddy/caddy_filebrowser
			fi
			if [ ! -f "$caddy_dir/caddy/caddy_filebrowser" ]; then
			logger -t "【caddy】" "caddy_filebrowser二进制文件下载失败，可能是地址失效或者网络异常,开始下载备用程序"
			logger -t "【caddy】" "下载备用程序较慢，耐心等待"
			wgetcurl.sh "$caddy_dir/caddy/caddy_file.tar.gz" "https://github.com/lmq8267/567/releases/download/caddy_file/caddy_file.tar.gz"
			tar -xzvf $caddy_dir/caddy/caddy_file.tar.gz -C /tmp/caddy
			rm -rf $caddy_dir/caddy/caddy_file.tar.gz
			fi
			  if [ "$caddy_enable" = "0" ] ;then
			  caddy_close
			   fi
		        if [ ! -f "$caddy_dir/caddy/caddy_filebrowser" ]; then
			logger -t "【caddy】" "caddy_filebrowser二文件下载失败，再次尝试下载"
			caddy_close
			caddy_start
			else
			logger -t "【caddy】" "caddy_filebrowser程序下载成功"
			chmod -R 777 $caddy_dir/caddy/caddy_filebrowser
			fi
			
}

caddy_start() {
	if [ "$caddy_enable" = "1" ] ;then
	       logger -t "【caddy】" "正在启动..."
		mkdir -p $caddy_dir/caddy
		fi
		caddybin="/usr/bin/caddy_filebrowser"
		if [ ! -f "$caddybin" ]; then
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
		logger -t "【caddy】" "文件管理服务已启动"
	
}

caddy_close() {
	iptables -t filter -D INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
	iptables -t filter -D INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
	if [ "$wipv6" = 1 ]; then
		ip6tables -t filter -D INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
		ip6tables -t filter -D INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
	fi
	if [ ! -z "`pidof caddy_filebrowser`" ]; then
	        killall caddy_filebrowser
		killall -9 caddy_filebrowser
                rm -rf "$caddy_dir/caddy/caddy_filebrowser"
		[ -z "`pidof caddy_filebrowser`" ] && logger -t "【caddy】" "已关闭文件管理服务."
	fi
	if [ "$caddy_enable" = "0" ] ;then
	killall caddy_filebrowser
	killall -9 caddy_filebrowser
	rm -rf "$caddy_dir/caddy/caddy_filebrowser"
	[ -z "`pidof caddy_filebrowser`" ] && logger -t "【caddy】" "已关闭文件管理服务."
	killall caddy.sh
	fi

}

case $1 in
start)
caddy_start
;;
stop)
caddy_close
;;
esac
