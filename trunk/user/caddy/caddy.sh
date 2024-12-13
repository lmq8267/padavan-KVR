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
caddy_renum=`nvram get caddy_renum`

caddy_restart () {
relock="/var/lock/caddy_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set caddy_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	caddy_renum=${caddy_renum:-"0"}
	caddy_renum=`expr $caddy_renum + 1`
	nvram set caddy_renum="$caddy_renum"
	if [ "$caddy_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【caddy】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get caddy_renum)" = "0" ] && break
   			#[ "$(nvram get caddy_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set caddy_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
caddy_start
}

caddy_dl() {
	bin_path=$(dirname "$caddy_dir")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
       if [ ! -f "$caddy_dir" ] || [[ "$($caddy_dir -h 2>&1 | wc -l)" -lt 2 ]] ; then
		logger -t "【caddy】" "找不到caddy_filebrowser文件，下载caddy_filebrowser程序"
		for proxy in $github_proxys ; do
  		length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/caddy/caddy_filebrowser" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 		length=`expr $length + 512000`
		length=`expr $length / 1048576`
 		caddy_size0="$(check_disk_size $caddy_dir)"
 		[ ! -z "$length" ] && logger -t "【caddy】" "程序大小 ${length}M， 程序路径可用空间 ${caddy_size0}M "
		curl -L -k -o "$caddy_dir" --connect-timeout 10 --retry 3 "${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/caddy/caddy_filebrowser" || wget --no-check-certificate -O "$caddy_dir" "${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/caddy/caddy_filebrowser"
		if [ "$?" = 0 ] ; then
			chmod +x $caddy_dir
			if [[ "$($caddy_dir -h 2>&1 | wc -l)" -gt 3 ]] ; then
				logger -t "【caddy】" "$caddy_dir 下载成功"
				break
       			else
	   			logger -t "【caddy】" "下载不完整，删除...请手动下载 ${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/caddy/caddy_filebrowser 上传到  $caddy_dir"
				rm -f $caddy_dir
	  		fi
		else
			logger -t "【caddy】" "下载失败${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/caddy/caddy_filebrowser"
   		fi
		
		done
	fi		
}

caddy_dl2() {
	bin_path=$(dirname "$caddy_dir")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
       if [ ! -f "$caddy_dir" ] || [[ "$($caddy_dir -h 2>&1 | wc -l)" -lt 2 ]] ; then
		logger -t "【caddy】" "找不到caddy文件，下载最新版本caddy程序"
  		curltest=`which curl`
    		user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
      		if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/lmq8267/caddy/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/caddy/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    		else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/caddy/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       		[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/caddy/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        	fi
		[ -z "$tag" ] && logger -t "【caddy】" "无法获取最新版本,使用 v2.8.4" && tag="v2.8.4"
		for proxy in $github_proxys ; do
  		length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/lmq8267/caddy/releases/download/${tag}/caddy-mipsel-upx" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 		length=`expr $length + 512000`
		length=`expr $length / 1048576`
 		caddy_size0="$(check_disk_size $caddy_dir)"
 		[ ! -z "$length" ] && logger -t "【caddy】" "程序大小 ${length}M， 程序路径可用空间 ${caddy_size0}M "
		curl -L -k -o "$caddy_dir" --connect-timeout 10 --retry 3 "${proxy}https://github.com/lmq8267/caddy/releases/download/${tag}/caddy-mipsel-upx" || wget --no-check-certificate -O "$caddy_dir" "${proxy}https://github.com/lmq8267/caddy/releases/download/${tag}/caddy-mipsel-upx"
		if [ "$?" = 0 ] ; then
			chmod +x $caddy_dir
			if [[ "$($caddy_dir -h 2>&1 | wc -l)" -gt 3 ]] ; then
				logger -t "【caddy】" "$caddy_dir 下载成功"
				break
       			else
	   			logger -t "【caddy】" "下载不完整，删除...请手动下载 ${proxy}https://github.com/lmq8267/caddy/releases/download/${tag}/caddy-mipsel-upx 上传到  $caddy_dir"
				rm -f $caddy_dir
	  		fi
		else
			logger -t "【caddy】" "下载失败${proxy}https://github.com/lmq8267/caddy/releases/download/${tag}/caddy-mipsel-upx"
   		fi
		
		done
	fi		
}

caddy_keep() {
	logger -t "【caddy】" "守护进程启动"
 	binname=$(basename $caddy_dir)
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof $binname\`" ] && logger -t "进程守护" "caddy 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check #【caddy】
 	[ -s /tmp/caddy.log ] && [ "\$(stat -c %s /tmp/caddy.log)" -gt 681984 ] && echo "" > /tmp/caddy.log & #【caddy】
	OSC

	fi

}

caddy_start() {
	scriptname=$(basename $0)
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	if [ "$caddy_enable" = "1" ] ;then
	       logger -t "【caddy】" "正在启动..."
	       sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
	else
 		exit 1
	fi
	[ -z "$caddy_dir" ] && caddy_dir=/tmp/var/caddy_filebrowser
 	if [ -f "$caddy_dir" ] ; then
		[ ! -x "$caddy_dir" ] && chmod +x $caddy_dir
  		[[ "$($caddy_dir -h 2>&1 | wc -l)" -lt 2 ]] && logger -t "【caddy】" "程序${caddy_dir}不完整！" && rm -rf $caddy_dir
  	fi
	if [ ! -f "$caddy_dir" ] ; then
 		if [ "$caddy_file" = "0" ] || [ "$caddy_file" = "1" ] || [ "$caddy_file" = "2" ] ; then
			caddy_dl
   		fi
     		if [ "$caddy_file" = "3" ] || [ "$caddy_file" = "4" ] || [ "$caddy_file" = "5" ] ; then
			caddy_dl2
   		fi
	fi
 	killall $(basename $caddy_dir) >/dev/null 2>&1
	/etc/storage/caddy_script.sh
			if [ "$caddy_file" = "0" ] || [ "$caddy_file" = "2" ] || [ "$caddy_file" = "3" ] || [ "$caddy_file" = "5" ] ; then
				fport=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$caddyf_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
				if [ "$fport" = 0 ] && [ "$caddy_wan" = "1" ] ; then
					logger -t "【caddy】" "WAN放行文件服务器 $caddyf_wan_port IPV4-tcp端口"
					iptables -t filter -I INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
				fi
    				if [ "$fport" = 0 ] && [ "$caddy_wip6" = "1" ] ; then
					logger -t "【caddy】" "WAN放行文件服务器 $caddyf_wan_port IPV6-tcp端口"
					ip6tables -t filter -I INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT
				fi
			fi
			if [ "$caddy_file" = "1" ] || [ "$caddy_file" = "2" ] || [ "$caddy_file" = "4" ] || [ "$caddy_file" = "5" ] ; then
				wport=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$caddyw_wan_port | cut -d " " -f 1 | sort -nr | wc -l)
				if [ "$wport" = 0 ] && [ "`nvram get caddy_dwan`" = "1" ] ; then
					logger -t "【caddy】" "WAN放行WebDav $caddyw_wan_port IPV4-tcp端口"
					iptables -t filter -I INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
				fi
    				if [ "$wport" = 0 ] && [ "`nvram get caddy_dwip6`" = "1" ] ; then
					logger -t "【caddy】" "WAN放行WebDav $caddyw_wan_port IPV6-tcp端口"
					ip6tables -t filter -I INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT
				fi
			fi
   	sleep 4
	if [ ! -z "`pidof caddy_filebrowser`" ] || [ ! -z "`pidof caddy`" ] ; then
 		mem=$(cat /proc/$(pidof `basename $caddy_dir`)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   		cpui="$(top -b -n1 | grep -E "$(pidof `basename $caddy_dir`)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /'"$(basename $caddy_dir)"'/) break; else cpu=i}} END {print $cpu}')"
		logger -t "【caddy】" "文件管理服务已启动" 
  		logger -t "【caddy】" "内存占用 ${mem} CPU占用 ${cpui}%"
   		caddy_restart o
   		caddy_keep
   	else
		logger -t "【caddy】" "运行失败, 注意检查${caddy_dir}是否下载完整,10 秒后自动尝试重新启动"
  		sleep 10
  		caddy_restart x
    	fi
	
}

caddy_close() {
	scriptname=$(basename $0)
	sed -Ei '/【caddy】|^$/d' /tmp/script/_opt_script_check
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	[ ! -z "$caddyf_wan_port" ] && iptables -t filter -D INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT >/dev/null 2>&1
	[ ! -z "$caddyw_wan_port" ] && iptables -t filter -D INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT >/dev/null 2>&1
	[ ! -z "$caddyw_wan_port" ] && ip6tables -t filter -D INPUT -p tcp --dport $caddyw_wan_port -j ACCEPT >/dev/null 2>&1
	[ ! -z "$caddyf_wan_port" ] && ip6tables -t filter -D INPUT -p tcp --dport $caddyf_wan_port -j ACCEPT >/dev/null 2>&1
	if [ ! -z "`pidof caddy_filebrowser`" ] || [ ! -z "`pidof caddy`" ] ; then
	        killall caddy_filebrowser >/dev/null 2>&1
		killall -9 caddy_filebrowser >/dev/null 2>&1
  		killall caddy >/dev/null 2>&1
		killall -9 caddy >/dev/null 2>&1
                #rm -rf "$caddy_dir/caddy/caddy_filebrowser"
		[ -z "`pidof caddy_filebrowser`" ] && [ -z "`pidof caddy`" ] && logger -t "【caddy】" "已关闭文件管理服务."
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
