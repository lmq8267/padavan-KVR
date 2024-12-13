#!/bin/sh

ts_enable=$(nvram get tailscale_enable)
ts_dns=$(nvram get tailscale_dns)
ts_route=$(nvram get tailscale_route)
ts_routes="$(nvram get tailscale_routes)"
ts_exit=$(nvram get tailscale_exit)
ts_exitip="$(nvram get tailscale_exitip)"
ts_server="$(nvram get tailscale_server)"
ts_ssh=$(nvram get tailscale_ssh)
ts_shields="$(nvram get tailscale_shields)"
ts_host="$(nvram get tailscale_host)"
ts_key=$(nvram get tailscale_key)
ts_reset="$(nvram get tailscale_reset)"
tailscaled="$(nvram get tailscale_bin)"
[ -z "$tailscaled" ] && tailscaled=/tmp/tailscaled && nvram set tailscale_bin=$tailscaled
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
t_CMD="$(nvram get tailscale_cmd)"
t2_CMD="$(nvram get tailscale_cmd2)"
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
[ ! -d /etc/storage/tailscale ] && mkdir -p /etc/storage/tailscale
tailscale_renum=`nvram get tailscale_renum`

ts_restart () {
relock="/var/lock/tailscale_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set tailscale_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	tailscale_renum=${tailscale_renum:-"0"}
	tailscale_renum=`expr $tailscale_renum + 1`
	nvram set tailscale_renum="$tailscale_renum"
	if [ "$tailscale_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【Tailscale】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get tailscale_renum)" = "0" ] && break
   			#[ "$(nvram get tailscale_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set tailscale_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
start_ts
}

get_tag() {
	curltest=`which curl`
	logger -t "【Tailscale】" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/lmq8267/tailscale/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/tailscale/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/tailscale/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/tailscale/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "【Tailscale】" "无法获取最新版本"
	nvram set tailscale_ver_n=$tag
	if [ -f "$tailscaled" ] ; then
		chmod +x $tailscaled
		ts_ver=$($tailscaled -version | sed -n 1p | awk -F '-' '{print $1}')
		if [ -z "$ts_ver" ] ; then
			nvram set tailscale_ver=""
		else
			nvram set tailscale_ver=$ts_ver
		fi
	fi
}

dowload_ts() {
	tag="$1"
	bin_path=$(dirname "$tailscaled")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
	logger -t "【Tailscale】" "开始下载 https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full 到 $tailscaled"
	for proxy in $github_proxys ; do
 	length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 	length=`expr $length + 512000`
	length=`expr $length / 1048576`
 	tailscaled_size0="$(check_disk_size $tailscaled)"
 	[ ! -z "$length" ] && logger -t "【Tailscale】" "程序大小 ${length}M， 程序路径可用空间 ${tailscaled_size0}M "
        curl -Lko "$tailscaled" "${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full" || wget --no-check-certificate -O "$tailscaled" "${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full"
	if [ "$?" = 0 ] ; then
		chmod +x $tailscaled
  		if [[ "$($tailscaled -h 2>&1 | wc -l)" -gt 3 ]] ; then
			logger -t "【Tailscale】" "$tailscaled 下载成功"
			ts_ver=$($tailscaled -version | sed -n 1p | awk -F '-' '{print $1}')
			if [ -z "$ts_ver" ] ; then
				nvram set tailscale_ver=""
			else
				nvram set tailscale_ver=$ts_ver
			fi
			break
       		else
	   		logger -t "【Tailscale】" "下载不完整，请手动下载 ${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full 上传到  $tailscaled"
	   		rm -f $tailscaled
	  	fi
	else
		logger -t "【Tailscale】" "下载失败，请手动下载 ${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full 上传到  $tailscaled"
   	fi
	done
}

update_ts() {
	get_tag
	[ -z "$tag" ] && logger -t "【Tailscale】" "无法获取最新版本" && exit 1
	if [ ! -z "$tag" ] && [ ! -z "$ts_ver" ] ; then
		if [ "$tag"x != "$ts_ver"x ] ; then
			logger -t "【Tailscale】" "当前版本${ts_ver} 最新版本${tag}"
			dowload_ts $tag
		else
			logger -t "【Tailscale】" "当前已是最新版本 ${tag} 无需更新！"
		fi
	fi
	exit 0
}

get_info() {
	nvram set tailscale_info=""
	$tailscale status >/tmp/tailscale.status 2>&1
	if [ -z "$(cat /tmp/tailscale.status | grep  'Logged' | grep  'out')" ] ; then
		echo "$(cat /tmp/tailscale.status)" >>/tmp/tailscale.log 
		ts_IP="$($tailscale ip | sed -n 1p)"
		if echo "$ts_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
			ts_info="$($tailscale whois $ts_IP)"
			device_name=$(echo "$ts_info" | awk -F 'Name: ' 'NR==2 {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
			device_id=$(echo "$ts_info" | awk -F 'ID: ' 'NR==3 {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
			user_name=$(echo "$ts_info" | awk -F 'Name: ' 'NR==6 {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
			user_id=$(echo "$ts_info" | awk -F 'ID: ' 'NR==7 {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
			
			[ ! -z "$user_name" ] && adminuser="绑定账户: $user_name "
			[ ! -z "$ts_IP" ] && adminip=" 设备IP: $ts_IP "
			[ ! -z "$device_id" ] && adminid=" 设备ID: $device_id "
			logger -t "【Tailscale】" "设备名称: $device_name 设备IP: $ts_IP 设备ID: $device_id"
			logger -t "【Tailscale】" "绑定账户: $user_name  账户ID： $user_id"
			nvram set tailscale_info="${adminuser}${adminip}${adminid}"
		fi
	fi
}

get_login() {
	$tailscale status >/tmp/tailscale.status 2>&1
	nvram set tailscale_login=""
	if [ ! -z "$(cat /tmp/tailscale.status | grep  'Logged' | grep  'out')" ] ; then
		logger -t "【Tailscale】" "初次安装或密钥文件为空，开始获取设备绑定地址..."
		login_url=$(cat /tmp/tailscale.status | awk -F 'Log in at: ' '{print $2}')
		logger -t "【Tailscale】" "设备绑定地址: $login_url"
		nvram set tailscale_login="$login_url"
		logger -t "【Tailscale】" "绑定设备后请勿立即重启，防止密钥文件/etc/storage/tailscale/lib/tailscaled.state重启丢失"
		[ -z "$login_url" ] && logger -t "【Tailscale】" "无法获取设备绑定地址，请打开SSH手动运行 $tailscale login 获取设备绑定地址"
	else
		get_info
	fi

}

ts_keep() {
	logger -t "【Tailscale】" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof tailscaled\`" ] && logger -t "进程守护" "tailscaled 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check #【Tailscaled】
	[ -z "\$(iptables -L -n -v | grep 'tailscale0')" ] && logger -t "进程守护" "tailscaled 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check #【Tailscaled】
	[ -s /tmp/tailscale.log ] && [ "\$(stat -c %s /tmp/tailscale.log)" -gt 681984 ] && echo "" > /tmp/tailscale.log & #【Tailscaled】
	OSC

	fi
	get_login
}

start_ts() {
	[ "$ts_enable" = "0" ] && exit 1
	if [ "$ts_enable" = "3" ] ; then
		logger -t "【Tailscale】" "正在清除配置文件/etc/storage/tailscale/* ..."
		kill_ts
		rm -rf /etc/storage/tailscale/*
		nvram set tailscale_enable=0
		nvram set tailscale_login=""
		nvram set tailscale_info=""
		logger -t "【Tailscale】" "清除配置完成"
		exit 0
	fi 
	logger -t "Tailscale" "正在启动tailscale"
	sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check
	get_tag
 	if [ -f "$tailscaled" ] ; then
		[ ! -x "$tailscaled" ] && chmod +x $tailscaled
  		[[ "$($tailscaled -h 2>&1 | wc -l)" -lt 2 ]] && logger -t "【Tailscale】" "程序${tailscaled}不完整！" && rm -rf $tailscaled
  	fi
 	if [ ! -f "$tailscaled" ] ; then
		logger -t "【Tailscale】" "主程序${tailscaled}不存在，开始在线下载..."
  		[ -z "$tag" ] && tag="1.78.1"
  		dowload_ts $tag
  	fi
	kill_ts
	[ ! -x "$tailscaled" ] && chmod +x $tailscaled
	path=$(dirname "$tailscaled")
	tailscale="${path}/tailscale"
	if [ ! -L "$tailscale" ] || [ "$(ls -l $tailscale | awk '{print $NF}')" != "$tailscaled" ] ; then
		ln -sf "$tailscaled" "$tailscale"
	fi
	#[ $(($($tailscaled -h | wc -l))) -lt 3 ] && logger -t "【Tailscale】" "程序${tailscaled}不完整，无法运行！" 
	$tailscaled --cleanup >/tmp/tailscale.log
	tdCMD="$tailscaled --state=/etc/storage/tailscale/lib/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock"
	logger -t "【Tailscale】" "运行主程序 $tdCMD"
	eval "$tdCMD >>/tmp/tailscale.log 2>&1" &
	sleep 4
	if [ ! -z "`pidof tailscaled`" ] ; then
 		mem=$(cat /proc/$(pidof tailscaled)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   		tdcpu="$(top -b -n1 | grep -E "$(pidof tailscaled)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /tailscaled/) break; else cpu=i}} END {print $cpu}')"
		logger -t "【Tailscale】" "主程序运行成功！"
  		logger -t "【Tailscale】" "主程序:内存占用 ${mem} CPU占用 ${tdcpu}%"
  		ts_restart o
		iptables -C INPUT -i tailscale0 -j ACCEPT
		if [ "$?" != 0 ] ; then
			iptables -I INPUT -i tailscale0 -j ACCEPT
		fi
	else
		logger -t "【Tailscale】" "运行主程序失败, 注意检查${tailscaled}是否下载完整,10 秒后自动尝试重新启动"
  		sleep 10
		ts_restart x
	fi
	CMD=""
	if [ "$ts_enable" = "1" ] ; then
		CMD="up"
		[ "$ts_dns" = "1" ] || CMD="${CMD} --accept-dns=false"
		[ "$ts_route" = "1" ] && CMD="${CMD} --accept-routes"
		[ -z "$ts_routes" ] || ts_routes="$(echo $ts_routes | tr -d ' ')"
		[ -z "$ts_routes" ] || CMD="${CMD} --advertise-routes=${ts_routes}"
		[ "$ts_exit" = "1" ] && CMD="${CMD} --advertise-exit-node"
		[ -z "$ts_exitip" ] || ts_exitip="$(echo $ts_exitip | tr -d ' ')"
		[ -z "$ts_exitip" ] || CMD="${CMD} --exit-node=${ts_exitip} --exit-node-allow-lan-access"
		[ -z "$ts_server" ] || ts_server="$(echo $ts_server | tr -d ' ')"
		[ -z "$ts_server" ] || CMD="${CMD} --login-server=${ts_server}"
		[ "$ts_ssh" = "1" ] && CMD="${CMD} --ssh"
		[ "$ts_shields" = "1" ] && CMD="${CMD} --shields-up"
		[ -z "$ts_host" ] || ts_host="$(echo $ts_host | tr -d ' ')"
		[ -z "$ts_host" ] || CMD="${CMD} --hostname=${ts_host}"
		[ -z "$ts_key" ] || ts_key="$(echo $ts_key | tr -d ' ')"
		[ -z "$ts_key" ] || CMD="${CMD} --auth-key=${ts_key}"
		[ -z "$t2_CMD" ] || CMD="${CMD} ${t2_CMD}"
  		[ "$ts_reset" = "1" ] && CMD="${CMD} --reset"
		CMD="${tailscale} ${CMD}"
	fi
	if [ "$ts_enable" = "2" ] ; then
		if [ ! -z "$t_CMD" ] ; then
			
			CMD="${tailscale} ${t_CMD}"
		else
			logger -t "【Tailscale】" "自定义启动参数为空，设置为默认参数:  up"
			CMD="${tailscale} up"
			nvram set tailscale_cmd="up"
		fi
	fi
	logger -t "【Tailscale】" "运行子程序 ${CMD}"
	eval "$CMD >>/tmp/tailscale.log 2>&1" &
	sleep 5
	if [ ! -z "`pidof tailscale`" ] ; then
 		mem=$(cat /proc/$(pidof tailscale)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   		tscpu="$(top -b -n1 | grep -E "$(pidof tailscale)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /tailscale/) break; else cpu=i}} END {print $cpu}')"
		logger -t "【Tailscale】" "子程序运行成功！"
  		logger -t "【Tailscale】" "子程序:内存占用 ${mem} CPU占用 ${tscpu}%"
    		ts_restart o
	else
		logger -t "【Tailscale】" "子程序运行失败, 注意检查${VNTCLI}是否下载完整,10 秒后自动尝试重新启动"
  		sleep 10
  		ts_restart x
	fi
	ts_keep
	exit 0
}
kill_ts() {
	tsd_process=$(pidof tailscaled)
	ts_process=$(pidof tailscaled)
	rm -rf /tmp/tailscale.log
	if [ ! -z "$ts_process" ] || [ ! -z "$tsd_process" ]; then
		logger -t "【Tailscale】" "有进程在运行，结束中..."
		[ -f "$tailscaled" ] && $tailscaled --cleanup >/tmp/tailscale.log
		killall tailscaled >/dev/null 2>&1
		killall tailscale >/dev/null 2>&1
	fi
}
stop_ts() {
	logger -t "【Tailscale】" "正在关闭tailscale..."
	sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	kill_ts
	[ -z "`pidof tailscaled`" ] && logger -t "【Tailscale】" "tailscale关闭成功!"
 	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
}

case $1 in
start)
	start_ts &
	;;
stop)
	stop_ts
	;;
restart)
	stop_ts
	start_ts &
	;;
update)
	update_ts &
	;;
*)
	echo "check"
	#exit 0
	;;
esac
