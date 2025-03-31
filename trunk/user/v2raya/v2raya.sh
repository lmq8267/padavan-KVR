#!/bin/sh

v2raya_enable="$(nvram get v2raya_enable)"
v2raya_address="$(nvram get v2raya_address)"
v2raya_config="$(nvram get v2raya_config)"
v2raya_confdir="$(nvram get v2raya_confdir)"
v2raya_assetsdir="$(nvram get v2raya_assetsdir)"
v2raya_transparent="$(nvram get v2raya_transparent)"
v2raya_core_hook="$(nvram get v2raya_core_hook)"
v2raya_plugin="$(nvram get v2raya_plugin)"
v2raya_ipv6="$(nvram get v2raya_ipv6)"
v2raya_log="$(nvram get v2raya_log)"
v2raya="$(nvram get v2raya_bin)"
v2raya_v2ray="$(nvram get v2raya_v2ray)"
v2raya_cmd="$(nvram get v2raya_cmd)"
v2raya_env="$(nvram get v2raya_env)"
if [ ! -z "$v2raya" ] ; then
	binname=$(basename $v2raya)
else
	nvram set v2raya_bin="/tmp/var/v2raya"
	v2raya="/tmp/var/v2raya"
	binname="v2raya"
fi
if [ ! -z "$v2raya_config" ] ; then 
	v2raya_config=/etc/storage/v2raya_config
	mkdir -p /etc/storage/v2raya_config
	nvram set v2raya_config=$v2raya_config
else
	[ ! -d "$v2raya_config" ] && mkdir -p $v2raya_config
fi
[ ! -z "$v2raya_confdir" ] && [ ! -d "$v2raya_confdir" ] && mkdir -p $v2raya_confdir
if [ ! -z "$v2raya_assetsdir" ] ; then 
	v2raya_assetsdir=/tmp/var
	mkdir -p /tmp/var
	nvram set v2raya_assetsdir=$v2raya_assetsdir
else
	[ ! -d "$v2raya_assetsdir" ] && mkdir -p $v2raya_assetsdir
fi
[ -z "$v2raya" ] && v2raya="/tmp/var/v2raya" && nvram set v2raya_bin=$v2raya
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
v2raya_renum=`nvram get v2raya_renum`

v2_restart () {
relock="/var/lock/v2raya_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set v2raya_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	v2raya_renum=${v2raya_renum:-"0"}
	v2raya_renum=`expr $v2raya_renum + 1`
	nvram set v2raya_renum="$v2raya_renum"
	if [ "$v2raya_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【V2RayA】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get v2raya_renum)" = "0" ] && break
   			#[ "$(nvram get v2raya_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set v2raya_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
start_v2
}

get_tag() {
	curltest=`which curl`
	logger -t "【V2RayA】" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/v2rayA/v2rayA/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/v2rayA/v2rayA/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/v2rayA/v2rayA/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/v2rayA/v2rayA/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "【V2RayA】" "无法获取最新版本"
	nvram set v2raya_ver_n=$tag
	if [ -f "$v2raya" ] ; then
		[ ! -x "$v2raya" ] && chmod +x $v2raya
		v2_ver=$($v2raya --version)
		if [ -z "$v2_ver" ] ; then
			nvram set v2raya_ver=""
		else
			nvram set v2raya_ver="v${v2_ver}"
		fi
	fi
}

dowload_v2() {
	tag="$1"
	bin_path=$(dirname "$v2raya")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
	url="https://github.com/v2rayA/v2rayA/releases/download/v${tag}/v2raya_linux_mips32le_${tag}"
	logger -t "【V2RayA】" "开始下载 ${url} "
	[ -z "$github_proxys" ] && logger -t "【V2RayA】" "加速镜像地址为空.."
	for proxy in $github_proxys ; do
 	length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}${url}" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 	length=`expr $length + 512000`
	length=`expr $length / 1048576`
 	v2_size0="$(check_disk_size $bin_path)"
 	[ ! -z "$length" ] && logger -t "【V2RayA】" "程序大小 ${length}M， 程序路径可用空间 ${v2_size0}M "
        curl -Lko "$v2raya" "${proxy}${url}" || wget --no-check-certificate -O "$v2raya" "${proxy}${url}"
	if [ "$?" = 0 ] ; then
		chmod +x $v2raya
		if [[ "$($v2raya -h 2>&1 | wc -l)" -gt 3 ]]  ; then
			logger -t "【V2RayA】" "解压成功"
			v2_ver=$($v2raya --version)
			if [ -z "$v2_ver" ] ; then
				nvram set v2raya_ver=""
			else
				nvram set v2raya_ver="v${v2_ver}"
			fi
			break
       		else
	   		logger -t "【V2RayA】" "下载不完整，请手动下载 ${proxy}${url} 上传到  $v2raya"
	  	fi
	else
		logger -t "【V2RayA】" "下载失败，请手动下载 ${proxy}${url} 上传到  $v2raya"
   	fi
	done
}

update_v2() {
	get_tag
	bin_path=$(dirname "$v2raya")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
	[ -z "$tag" ] && logger -t "【V2RayA】" "无法获取最新版本" && exit 1
	tag="$(echo $tag | tr -d 'v')"
	if [ ! -z "$tag" ] && [ ! -z "$v2_ver" ] ; then
		if [ "$tag"x != "$v2_ver"x ] ; then
			logger -t "【V2RayA】" "当前版本${v2_ver} 最新版本${tag}"
			dowload_v2 $tag
		else
			logger -t "【V2RayA】" "当前已是最新版本 ${tag} 无需更新！"
		fi
	fi
	exit 0
}

v2_keep() {
	logger -t "【V2RayA】" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【V2RayA】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof ${binname}\`" ] && logger -t "进程守护" "V2RayA 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【V2RayA】|^$/d' /tmp/script/_opt_script_check #【V2RayA】
	[ -s /tmp/v2raya.log ] && [ "\$(stat -c %s /tmp/v2raya.log)" -gt 681984 ] && echo "" > /tmp/v2raya.log & #【V2RayA】
	OSC

	fi

}

set_env() {
	if [ ! -z "$v2raya_env" ] ; then
		v2raya_env=$(echo $v2raya_env | tr -d '\r')
		for v2_env in $v2raya_env ; do
			[ -z "$v2_env" ] && continue
			export $v2_env
		done	
	fi
}

start_v2() {
	[ "$v2raya_enable" = "1" ] || exit 1
	logger -t "【V2RayA】" "正在启动v2raya"
	echo "正在启动v2raya" >/tmp/v2raya.log
	sed -Ei '/【V2RayA】|^$/d' /tmp/script/_opt_script_check
	get_tag
 	if [ -f "$v2raya" ] ; then
		[ ! -x "$v2raya" ] && chmod +x $v2raya
  		[[ "$($v2raya -h 2>&1 | wc -l)" -lt 2 ]] && logger -t "【V2RayA】" "程序${v2raya}不完整！" && rm -rf $v2raya
  	fi
 	if [ ! -f "$v2raya" ] ; then
		logger -t "【V2RayA】" "主程序${v2raya}不存在，开始在线下载..."
  		[ ! -d /etc/storage/bin ] && mkdir -p /etc/storage/bin
  		
  		[ -z "$tag" ] && tag="v2.2.6.7"
  		dowload_v2 $tag
  	fi
	killall $binname >/dev/null 2>&1
	killall -9 $binname >/dev/null 2>&1
	[ ! -x "$v2raya" ] && chmod +x $v2raya
	set_env
	CMD="${v2raya} --log-file /tmp/v2raya.log"
	[ -z "$v2raya_address" ] || CMD="${CMD} -a $v2raya_address"
	[ -z "$v2raya_config" ] || CMD="${CMD} -c $v2raya_config"
	[ -z "$v2raya_confdir" ] || CMD="${CMD} --v2ray-confdir $v2raya_confdir"
	[ -z "$v2raya_assetsdir" ] || CMD="${CMD} --v2ray-assetsdir $v2raya_assetsdir"
	[ -z "$v2raya_transparent" ] || CMD="${CMD} --transparent-hook $v2raya_transparent"
	[ -z "$v2raya_core_hook" ] || CMD="${CMD} --core-hook $v2raya_core_hook"
	[ -z "$v2raya_plugin" ] || CMD="${CMD} --plugin-manager $v2raya_plugin"
	[ "$v2raya_ipv6" != "auto" ] || CMD="${CMD} --ipv6-support $v2raya_ipv6"
	[ -z "$v2raya_log" ] || CMD="${CMD} --log-level $v2raya_log"
	[ -z "$v2raya_v2ray" ] || CMD="${CMD} -b $v2raya_v2ray"
	[ -z "$v2raya_cmd" ] || CMD="${CMD} $v2raya_cmd"
	logger -t "【V2RayA】" "运行${CMD}"
	eval "$CMD" &
	sleep 4
	if [ ! -z "`pidof ${binname}`"  ] ; then
 		mem=$(cat /proc/$(pidof v2raya)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   		cpui="$(top -b -n1 | grep -E "$(pidof v2raya)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /v2raya/) break; else cpu=i}} END {print $cpu}')"
		logger -t "【V2RayA】" "运行成功！"
 	 	logger -t "【V2RayA】" "内存占用 ${mem} CPU占用 ${cpui}%"
  		v2_restart o
		v2_keep
		lan_ip=`nvram get lan_ipaddr`
		if [ -z "$v2raya_address" ] ; then
			nvram set v2raya_web="http://${lan_ip}:2017"
			logger -t "【V2RayA】" "WEB访问地址：http://${lan_ip}:2017"
		else
			v2ip=$(echo "$v2raya_address" | cut -d':' -f1)
			v2port=$(echo "$v2raya_address" | cut -d':' -f2)
			if [ "$v2ip" = "127.0.0.1" ] || [ "$v2ip" = "0.0.0.0" ] ; then
    				nvram set v2raya_web="http://${lan_ip}:${v2port}"
    				logger -t "【V2RayA】" "WEB访问地址：http://${lan_ip}:${v2port}"
			else
    				nvram set v2raya_web="http://${v2ip}:${v2port}"
    				logger -t "【V2RayA】" "WEB访问地址：http://${v2ip}:${v2port}"
			fi
		fi
	else
		logger -t "【V2RayA】" "运行失败, 注意检查${v2raya}是否下载完整,10 秒后自动尝试重新启动"
  		sleep 10
    		v2_restart x
	fi
	exit 0
}

stop_v2() {
	logger -t "【V2RayA】" "正在关闭服务..."
	sed -Ei '/【V2RayA】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	killall $binname >/dev/null 2>&1
	killall -9 $binname >/dev/null 2>&1
	[ -z "`pidof ${binname}`" ] && logger -t "【V2RayA】" "v2raya关闭成功!"
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
}

case $1 in
start)
	start_v2 &
	;;
stop)
	stop_v2
	;;
restart)
	stop_v2
	start_v2 &
	;;
update)
	update_v2 &
	;;
reset)
	logger -t "【V2RayA】" "正在重置密码..."
	echo "正在重置密码..." >>/tmp/v2raya.log 
	set_env
	Rst=$(${v2raya} -c ${v2raya_config} --reset-password)
	Rst0=$(echo ${Rst} | grep -o 'Succeed')
	echo "${Rst}" >/tmp/v2raya_repo.log
	if [ "$Rst0" = "Succeed" ] ; then
		echo "重置密码成功，请重启插件后将生效"
    		logger -t "【V2RayA】" "重置密码成功，请重启插件后将生效"
    	else
    		echo "重置密码失败"
		logger -t "【V2RayA】" "重置密码失败 ${Rst}"
	fi
	;;
config)
	set_env
	${v2raya} -c ${v2raya_config} --report config >/tmp/v2raya_repo.log 2>&1 &
	;;
connection)
	set_env
	${v2raya} -c ${v2raya_config} --report connection >/tmp/v2raya_repo.log 2>&1 &
	;;
kernel)
	set_env
	${v2raya} -c ${v2raya_config} --report kernel >/tmp/v2raya_repo.log 2>&1 &
	;;
*)
	echo "check"
	#exit 0
	;;
esac
