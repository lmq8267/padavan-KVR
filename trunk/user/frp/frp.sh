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
		logger -t "frp" "检测到互联网未能成功访问,稍后再尝试启动frp"
	fi
}

find_bin() {
dirs="/etc/storage/bin
/tmp/frp
/usr/bin"

frpc=""
for dir in $dirs ; do
    if [ -f "$dir/frpc" ] ; then
        frpc="$dir/frpc"
        [ ! -x "$frpc" ] && chmod +x $frpc
        break
    fi
done
[ -z "$frpc" ] && frpc="/tmp/frp/frpc"
frps=""
for dir in $dirs ; do
    if [ -f "$dir/frps" ] ; then
        frps="$dir/frps"
        [ ! -x "$frps" ] && chmod +x $frps
        break
    fi
done
[ -z "$frps" ] && frps="/tmp/frp/frps"
}

get_ver() {
	find_bin
	if [ -f "$frpc" ] ; then
		frpc_ver="$($frpc --version)"
		if [ -z "$frpc_ver" ] ; then
			frpc_v=""
		else
			frpc_v="frpc-v${frpc_ver}"
		fi
	fi
	if [ -f "$frps" ] ; then
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
	logger -t "frp" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/fatedier/frp/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/fatedier/frp/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/fatedier/frp/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/fatedier/frp/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "frp" "无法获取最新版本"
	nvram set frp_ver_n=$tag
	
}

frp_dl () 
{
	tag="$1"
	newtag="$(echo "$tag" | tr -d 'v' | tr -d ' ')"
	mkdir -p /tmp/frp
	logger -t "frp" "开始下载 https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz"
	for proxy in $github_proxys ; do
       curl -Lko "/tmp/frp_linux_mipsle.tar.gz" "${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz" || wget --no-check-certificate -O "/tmp/frp_linux_mipsle.tar.gz" "${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz"
	if [ "$?" = 0 ] ; then
		tar -xz -C /tmp -f /tmp/frp_linux_mipsle.tar.gz
		frpc_size="$(du -k /tmp/frp_${newtag}_linux_mipsle/frpc | awk '{print int($1 / 1024)}')"
		frps_size="$(du -k /tmp/frp_${newtag}_linux_mipsle/frps | awk '{print int($1 / 1024)}')"
		frpc_path=$(dirname "$frpc")
		frps_path=$(dirname "$frps")
		if [ "$frpc_enable" = "1" ] ; then
			router_size="$(check_disk_size $frpc_path)"
			if [ $(($(/tmp/frp_${newtag}_linux_mipsle/frpc -h | wc -l))) -gt 3 ] ; then
				logger -t "frp" "frpc ${frpc_size}M 下载成功,${frpc_path}剩余可用${router_size}M安装到$frpc"
				cp "/tmp/frp_${newtag}_linux_mipsle/frpc" "$frpc"
				break
       		else
	   			logger -t "frp" "frpc 下载不完整，请手动下载 ${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz 解压上传到  $frpc"
	  		fi
		fi
		if [ "$frps_enable" = "1" ] ; then
			router_size="$(check_disk_size $frps_path)"
			if [ $(($(/tmp/frp_${newtag}_linux_mipsle/frps -h | wc -l))) -gt 3 ] ; then
				logger -t "frp" "frps ${frps_size}M 下载成功,${frps_path}剩余可用${router_size}M 安装到$frps"
				cp "/tmp/frp_${newtag}_linux_mipsle/frps" "$frps"
				break
       		else
	   			logger -t "frp" "frps 下载不完整，请手动下载 ${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz 解压上传到  $frps"
	  		fi
		fi
		
		rm -rf /tmp/frp_${newtag}_linux_mipsle /tmp/frp_linux_mipsle.tar.gz
		
	else
		logger -t "frp" "下载失败，请手动下载 ${proxy}https://github.com/fatedier/frp/releases/download/${tag}/frp_${newtag}_linux_mipsle.tar.gz 解压上传"
   	fi
	done
      
}

scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
frpc_keep() {
	logger -t "frp" "frpc守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【frpc】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof frpc\`" ] && logger -t "进程守护" "frpc 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【frpc】|^$/d' /tmp/script/_opt_script_check #【frpc】
	OSC

	fi

}

frps_keep() {
	logger -t "frp" "frps守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【frps】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof frps\`" ] && logger -t "进程守护" "frps 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【frps】|^$/d' /tmp/script/_opt_script_check #【frps】
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
  			[ -z "$tag" ] && logger -t "frp" "未获取到最新版本，暂用v0.61.0版本" && tag="v0.61.0"
  			frp_dl $tag
  		fi
  	fi
  	[ ! -f "$frpc" ] && logger -t "frp" "没有$frpc 无法运行.." 
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
  			[ -z "$tag" ] && logger -t "frp" "未获取到最新版本，暂用v0.61.0版本" && tag="v0.61.0"
  			frp_dl $tag
  		fi
  	fi
  	[ ! -f "$frps" ] && logger -t "frp" "没有$frps 无法运行.." 
  fi
  get_ver
  /etc/storage/frp_script.sh
	sleep 3
	[ ! -z "`pidof frpc`" ] && logger -t "frp" "frpc启动成功" && frpc_keep
	[ ! -z "`pidof frps`" ] && logger -t "frp" "frps启动成功" && frps_keep
}
      
frp_close () 
{
	scriptname=$(basename $0)
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi

	if [ "$frpc_enable" = "0" ]; then
		sed -Ei '/【frpc】|^$/d' /tmp/script/_opt_script_check
		if [ ! -z "`pidof frpc`" ]; then
			killall frpc
			killall -9 frpc frp_script.sh
			[ -z "`pidof frpc`" ] && logger -t "frp" "已停止 frpc"
	    	fi
	fi
	if [ "$frps_enable" = "0" ]; then
		sed -Ei '/【frps】|^$/d' /tmp/script/_opt_script_check
		if [ ! -z "`pidof frps`" ]; then
		killall frps
		killall -9 frps frp_script.sh
		[ -z "`pidof frps`" ] && logger -t "frp" "已停止 frps"
	    fi
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
