#!/bin/sh

frpc_enable=`nvram get frpc_enable`
frps_enable=`nvram get frps_enable`
frp_tag=`nvram get frp_tag`
http_username=`nvram get http_username`
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "

check_frp () 
{
	check_net
	result_net=$?
	if [ "$result_net" = "1" ] ;then
		if [ -z "`pidof frpc`" ] && [ "$frpc_enable" = "1" ];then
			frp_start
		fi
		if [ -z "`pidof frps`" ] && [ "$frps_enable" = "1" ];then
			frp_start
		fi
	fi
}

check_net() 
{
	/bin/ping -c 3 223.5.5.5 -w 5 >/dev/null 2>&1
	if [ "$?" == "0" ]; then
		return 1
	else
		return 2
		logger -t "【Frp】" "检测到互联网未能成功访问,稍后再尝试启动frp"
	fi
}

frp_renum=`nvram get frp_renum`

frp_restart () {
relock="/var/lock/frp_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set frp_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	frp_renum=${frp_renum:-"0"}
	frp_renum=`expr $frp_renum + 1`
	nvram set frp_renum="$frp_renum"
	if [ "$frp_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【Frp】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get frp_renum)" = "0" ] && break
   			#[ "$(nvram get frps_enable)" = "0" ] && [ "$(nvram get frpc_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set frp_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
frp_start
}

find_bin() {
frpc=`nvram get frpc_bin`
frps=`nvram get frps_bin`
 	
dirs="/etc/storage/bin
/tmp/frp
/usr/bin"

if [ -z "$frpc" ] ; then
  for dir in $dirs ; do
    if [ -f "$dir/frpc" ] ; then
        frpc="$dir/frpc"
        [ ! -x "$frpc" ] && chmod +x $frpc
        break
    fi
  done
  [ -z "$frpc" ] && frpc="/tmp/frp/frpc"
fi
if [ -z "$frps" ] ; then
  for dir in $dirs ; do
    if [ -f "$dir/frps" ] ; then
        frps="$dir/frps"
        [ ! -x "$frps" ] && chmod +x $frps
        break
    fi
  done
  [ -z "$frps" ] && frps="/tmp/frp/frps"
fi
}

get_ver() {
	find_bin
	if [ -f "$frpc" ] ; then
 		[ ! -x "$frpc" ] && chmod +x $frps
		frpc_ver="$($frpc --version)"
		if [ -z "$frpc_ver" ] ; then
			frpc_v=""
		else
			frpc_v="frpc-v${frpc_ver}"
		fi
	fi
	if [ -f "$frps" ] ; then
 		[ ! -x "$frps" ] && chmod +x $frps
		frpc_ver="$($frps --version)"
		if [ -z "$frps_ver" ] ; then
			frps_v=""
		else
			frps_v="frps-v${frps_ver}"
		fi
	fi
	nvram set frp_ver="$frpc_v  $frps_v"

}

get_tag() {
	curltest=`which curl`
	logger -t "【Frp】" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/fatedier/frp/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/fatedier/frp/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/fatedier/frp/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/fatedier/frp/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "【Frp】" "无法获取最新版本"
	nvram set frp_ver_n=$tag
	
}

frp_dl () 
{
	tag="$1"
	newtag="$(echo "$tag" | tr -d 'v' | tr -d ' ')"
	mkdir -p /tmp/frp
 	frpc_path=$(dirname "$frpc")
	[ ! -d "$frpc_path" ] && mkdir -p "$frpc_path"
 	frps_path=$(dirname "$frps")
	[ ! -d "$frps_path" ] && mkdir -p "$frps_path"
	logger -t "【Frp】" "开始下载 https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz"
	for proxy in $github_proxys ; do
 	length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 	length=`expr $length + 512000`
	length=`expr $length / 1048576`
 	frp_size0="$(check_disk_size $frpc_path)"
 	[ ! -z "$length" ] && logger -t "【Frp】" "frp_linux_mipsle.tar.gz压缩包大小 ${length}M， 程序路径可用空间 ${frp_size0}M "
        curl -Lko "/tmp/frp_linux_mipsle.tar.gz" "${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz" || wget --no-check-certificate -O "/tmp/frp_linux_mipsle.tar.gz" "${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz"
	if [ "$?" = 0 ] ; then
		tar -xz -C /tmp -f /tmp/frp_linux_mipsle.tar.gz
		frpc_size="$(du -k /tmp/frp_${newtag}_linux_mipsle/frpc | awk '{print int($1 / 1024)}')"
		frps_size="$(du -k /tmp/frp_${newtag}_linux_mipsle/frps | awk '{print int($1 / 1024)}')"
		frpc_path=$(dirname "$frpc")
		frps_path=$(dirname "$frps")
		if [ "$frpc_enable" = "1" ] ; then
			router_size="$(check_disk_size $frpc_path)"
   			chmod +x /tmp/frp_${newtag}_linux_mipsle/frpc
			if [ "$(($(/tmp/frp_${newtag}_linux_mipsle/frpc -h 2>&1 | wc -l)))" -gt 3 ] ; then
				logger -t "【Frp】" "frpc ${frpc_size}M 下载成功,${frpc_path}剩余可用${router_size}M安装到$frpc"
				cp "/tmp/frp_${newtag}_linux_mipsle/frpc" "$frpc"
				break
       			else
	   			logger -t "【Frp】" "frpc 下载不完整，请手动下载 ${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz 解压上传到  $frpc"
	  		fi
		fi
		if [ "$frps_enable" = "1" ] ; then
			router_size="$(check_disk_size $frps_path)"
   			chmod +x /tmp/frp_${newtag}_linux_mipsle/frps
			if [ "$(($(/tmp/frp_${newtag}_linux_mipsle/frps -h 2>&1 | wc -l)))" -gt 3 ] ; then
				logger -t "【Frp】" "frps ${frps_size}M 下载成功,${frps_path}剩余可用${router_size}M 安装到$frps"
				cp "/tmp/frp_${newtag}_linux_mipsle/frps" "$frps"
				break
       			else
	   			logger -t "【Frp】" "frps 下载不完整，请手动下载 ${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz 解压上传到  $frps"
	  		fi
		fi
		
		rm -rf /tmp/frp_${newtag}_linux_mipsle /tmp/frp_linux_mipsle.tar.gz
		
	else
		logger -t "【Frp】" "下载失败，请手动下载 ${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz 解压上传"
   	fi
	done
      
}

scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
frpc_keep() {
	logger -t "【Frp】" "frpc守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【frpc】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof frpc\`" ] && logger -t "进程守护" "frpc 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【frpc】|^$/d' /tmp/script/_opt_script_check #【frpc】
 	[ -s /tmp/frpc.log ] && [ "\$(stat -c %s /tmp/frpc.log)" -gt 681984 ] && echo "" > /tmp/frpc.log & #【frpc】
	OSC

	fi

}

frps_keep() {
	logger -t "【Frp】" "frps守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【frps】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof frps\`" ] && logger -t "进程守护" "frps 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【frps】|^$/d' /tmp/script/_opt_script_check #【frps】
 	[ -s /tmp/frps.log ] && [ "\$(stat -c %s /tmp/frps.log)" -gt 681984 ] && echo "" > /tmp/frps.log & #【frps】
	OSC

	fi

}

frp_start () 
{
  [ ! -z "$frp_tag" ] && frp_tag="$(echo $frp_tag | tr -d ' ')"
  get_tag
  get_ver
  [ ! -z "$tag" ] && newtag="$(echo "$tag" | tr -d 'v' | tr -d ' ')"
  if [ "$frpc_enable" = "1" ] ;then
  	sed -Ei '/【frpc】|^$/d' /tmp/script/_opt_script_check
	if [ ! -z "$newtag" ] && [ ! -z "$frpc_ver" ] ; then
  		if [ -z "$frp_tag" ] && [ "$frpc_ver" != "$newtag" ] ; then
  			rm -f $frpc
  		fi
  		if [ ! -z "$frp_tag" ] && [ "$frpc_ver" != "$frp_tag" ] ; then
  			rm -f $frpc
  		fi
  	fi
  
  	if [ ! -f "$frpc" ] || [[ "$($frpc -h 2>&1 | wc -l)" -lt 2 ]] ; then
  		if [ ! -z "$frp_tag" ] ; then
  			frp_dl $frp_tag
  		else
  			[ -z "$tag" ] && logger -t "【Frp】" "未获取到最新版本，暂用v0.61.0版本" && tag="v0.61.0"
  			frp_dl $tag
  		fi
  	fi
  	[ ! -f "$frpc" ] && logger -t "【Frp】" "没有$frpc 无法运行.." 
  fi
  
  if [ "$frps_enable" = "1" ] ;then
  	sed -Ei '/【frps】|^$/d' /tmp/script/_opt_script_check
	if [ ! -z "$newtag" ] && [ ! -z "$frps_ver" ] ; then
  		if [ -z "$frp_tag" ] && [ "$frps_ver" != "$newtag" ] ; then
  			rm -f $frps
  		fi
  		if [ ! -z "$frp_tag" ] && [ "$frps_ver" != "$frp_tag" ] ; then
  			rm -f $frps
  		fi
  	fi
  
  	if [ ! -f "$frps" ] || [[ "$($frps -h 2>&1 | wc -l)" -lt 2 ]] ; then
  		if [ ! -z "$frp_tag" ] ; then
  			frp_dl $frp_tag
  		else
  			[ -z "$tag" ] && logger -t "【Frp】" "未获取到最新版本，暂用v0.61.0版本" && tag="v0.61.0"
  			frp_dl $tag
  		fi
  	fi
  	[ ! -f "$frps" ] && logger -t "【Frp】" "没有$frps 无法运行.." 
  fi
  get_ver
  eval /etc/storage/frp_script.sh &
 if [ "$frps_enable" = "1" ] ; then
	sleep 4
	[ -z "`pidof frps`" ] && logger -t "【Frp】" "frps启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && frp_restart x
	[ ! -z "`pidof frps`" ] && logger -t "【Frp】" "请手动配置【外网 WAN - 端口转发 - 启用手动端口映射】来开启WAN访问"
fi
if [ "$frpc_enable" = "1" ] ; then
	[ "$frps_enable" = "1" ] && sleep 64
	sleep 4
	[ -z "`pidof frpc`" ] && logger -t "【Frp】" "frpc启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && frp_restart x
fi
if [ "$frps_enable" = "1" ] && [ ! -z "`pidof frps`" ] ; then
   mem=$(cat /proc/$(pidof frps)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   scpu="$(top -b -n1 | grep -E "$(pidof frps)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /frps/) break; else cpu=i}} END {print $cpu}')"
   logger -t "【Frp】" "frps启动成功" 
   logger -t "【Frp】" "内存占用 ${mem} CPU占用 ${scpu}%"
   frps_keep 
   frp_restart o
fi
if [ "$frpc_enable" = "1" ] && [ ! -z "`pidof frpc`" ] ; then
   mem=$(cat /proc/$(pidof frpc)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   ccpu="$(top -b -n1 | grep -E "$(pidof frpc)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /frpc/) break; else cpu=i}} END {print $cpu}')"
   logger -t "【Frp】" "frpc启动成功" 
   logger -t "【Frp】" "内存占用 ${mem} CPU占用 ${ccpu}%" 
   frpc_keep 
   frp_restart o
fi

}
      
frp_close () 
{
	scriptname=$(basename $0)
	if [ "$frpc_enable" = "0" ]; then
		sed -Ei '/【frpc】|^$/d' /tmp/script/_opt_script_check
		if [ ! -z "`pidof frpc`" ]; then
			killall frpc
			killall -9 frpc frp_script.sh
			[ -z "`pidof frpc`" ] && logger -t "【Frp】" "已停止 frpc"
	    	fi
	fi
	if [ "$frps_enable" = "0" ]; then
		sed -Ei '/【frps】|^$/d' /tmp/script/_opt_script_check
		if [ ! -z "`pidof frps`" ]; then
		killall frps
		killall -9 frps frp_script.sh
		[ -z "`pidof frps`" ] && logger -t "【Frp】" "已停止 frps"
	    fi
	fi
 	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
}


case $1 in
start)
	frp_start &
	;;
stop)
	frp_close
	;;
C)
	check_frp &
	;;
esac
