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

get_tag() {
	curltest=`which curl`
	logger -t "Tailscaled" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/lmq8267/tailscale/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/tailscale/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/tailscale/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/tailscale/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "Tailscaled" "无法获取最新版本"
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
	logger -t "Tailscaled" "开始下载 https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full 到 $tailscaled"
	for proxy in $github_proxys ; do
       curl -Lkso "$tailscaled" "${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full" || wget --no-check-certificate -q -O "$tailscaled" "${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full"
	if [ "$?" = 0 ] ; then
		chmod +x $tailscaled
		if [ $(($($tailscaled -h | wc -l))) -gt 3 ] ; then
			logger -t "Tailscaled" "$tailscaled 下载成功"
			ts_ver=$($tailscaled -version | sed -n 1p | awk -F '-' '{print $1}')
			if [ -z "$ts_ver" ] ; then
				nvram set tailscale_ver=""
			else
				nvram set tailscale_ver=$ts_ver
			fi
			break
       	else
	   		logger -t "Tailscaled" "下载不完整，请手动下载 ${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full 上传到  $tailscaled"
			rm -f $tailscaled
	  	fi
	else
		logger -t "Tailscaled" "下载失败，请手动下载 ${proxy}https://github.com/lmq8267/tailscale/releases/download/${tag}/tailscaled_full 上传到  $tailscaled"
   	fi
	done
}

update_ts() {
	get_tag
	[ -z "$tag" ] && logger -t "Tailscaled" "无法获取最新版本" && exit 1
	if [ ! -z "$tag" ] && [ ! -z "$ts_ver" ] ; then
		if [ "$tag"x != "$ts_ver"x ] ; then
			logger -t "Tailscaled" "当前版本${ts_ver} 最新版本${tag}"
			dowload_ts $tag
		else
			logger -t "Tailscaled" "当前已是最新版本 ${tag} 无需更新！"
		fi
	fi
	exit 0
}

get_info() {
	$tailscale status >/tmp/tailscale.status 2>&1
	if [ -z "$(cat /tmp/tailscale.status | grep  'Logged' | grep  'out')" ] ; then
		echo "$(cat /tmp/tailscale.status)" >>/tmp/tailscale.log 
		ts_IP="$($tailscale ip | sed -n 1p)"
		if echo "$ts_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
			ts_info="$($tailscale whois $ts_IP)"
			device_name=$(echo "$(cat /tmp/tailscale.login)" | awk -F 'Name: ' 'NR==2 {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
			device_id=$(echo "$(cat /tmp/tailscale.login)" | awk -F 'ID: ' 'NR==3 {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
			user_name=$(echo "$(cat /tmp/tailscale.login)" | awk -F 'Name: ' 'NR==6 {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
			user_id=$(echo "$(cat /tmp/tailscale.login)" | awk -F 'ID: ' 'NR==7 {print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')
			logger -t "Tailscaled" "设备名称: $device_name 设备IP: $ts_IP 设备ID: $device_id"
			logger -t "Tailscaled" "绑定账户: $user_name  账户ID： $user_id"
			nvram set tailscale_info="绑定账户: $user_name  设备IP: $ts_IP  设备ID: $device_id"
		fi
	fi
}

ts_keep() {
	logger -t "Tailscaled" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof tailscaled\`" ] && logger -t "进程守护" "tailscaled 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check #【Tailscaled】
	[ -z "\$(iptables -L -n -v | grep 'tailscale0')" ] && logger -t "进程守护" "tailscaled 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check #【Tailscaled】
	[ -s /tmp/tailscale.log ] && [ "\$(stat -c %s /tmp/tailscale.log)" -gt 681984 ] && echo "" > /tmp/tailscale.log & #【Tailscaled】
	OSC

	fi
	get_info
}

get_login() {
	t=1
	$tailscale status >/tmp/tailscale.status 2>&1
	if [ ! -z "$(cat /tmp/tailscale.status | grep  'Logged' | grep  'out')" ] ; then
		$tailscale login >/tmp/tailscale.login 2>&1 &
		while [ "$t" -lt 3 ] ; do
			sleep 2
			login_url=$(cat /tmp/tailscale.login | awk -F 'Log in at: ' '{print $2}')
			if [ ! -z "$login_url" ]; then
        			logger -t "Tailscaled" "初次安装或配置文件为空，请先绑定设备 $login_url"
        			nvram set tailscale_login="$login_url"
        			break
        		fi
			t=`expr $t + 1`
		done
		[ ! -z "`pidof tailscale`" ] && killall tailscale >/dev/null 2>&1
	fi

}

start_ts() {
	[ "$ts_enable" = "0" ] && exit 1
	if [ "$ts_enable" = "3" ] ; then
		logger -t "Tailscaled" "正在清除配置文件/etc/storage/tailscale/* ..."
		rm -rf /etc/storage/tailscale/*
		nvram set tailscale_enable=0
		nvram set tailscale_login=""
		nvram set tailscale_info=""
		logger -t "Tailscaled" "清除配置完成"
		exit 0
	fi 
	logger -t "Tailscaled" "正在启动tailscaled"
	sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check
	get_tag
 	if [ ! -f "$tailscaled" ] ; then
		logger -t "Tailscaled" "主程序${tailscaled}不存在，开始在线下载..."
  		[ -z "$tag" ] && tag="1.76.6"
  		dowload_ts $tag
  	fi
  	[ ! -f "$tailscaled" ] && exit 1
	kill_ts
	[ ! -x "$tailscaled" ] && chmod +x $tailscaled
	path=$(dirname "$tailscaled")
	tailscale="${path}/tailscale"
	if [ ! -L "$tailscale" ] || [ "$(ls -l $tailscale | awk '{print $NF}')" != "$tailscaled" ] ; then
		ln -sf "$tailscaled" "$tailscale"
	fi
	[ $(($($tailscaled -h | wc -l))) -lt 3 ] && logger -t "Tailscaled" "程序${tailscaled}不完整，无法运行！" && exit 1
	$tailscaled --cleanup >/tmp/tailscale.log
	tdCMD="$tailscaled --state=/etc/storage/tailscale/tailscale.state --socket=/var/run/tailscaled.sock"
	logger -t "Tailscaled" "运行主程序 $tdCMD"
	eval "$tdCMD >>/tmp/tailscale.log 2>&1" &
	sleep 4
	if [ ! -z "`pidof tailscaled`" ] ; then
		logger -t "Tailscaled" "主程序运行成功！"
		iptables -C INPUT -i tailscale0 -j ACCEPT
		if [ "$?" != 0 ] ; then
			iptables -I INPUT -i tailscale0 -j ACCEPT
		fi
	else
		logger -t "Tailscaled" "运行主程序失败，请检查"
		exit 1
	fi
	CMD=""
	get_login
	if [ "$ts_enable" = "1" ] ; then
		[ "$ts_dns" = "1" ] || CMD="up --accept-dns=false"
		[ "$ts_route" = "1" ] && CMD="${CMD} --accept-routes"
		[ -z "$ts_routes" ] || ts_routes="$(echo $ts_routes | tr -d ' ')"
		[ -z "$ts_routes" ] || CMD="${CMD} --advertise-routes=${ts_routes}"
		[ "$ts_exit" = "1" ] && CMD="${CMD} --advertise-exit-node"
		[ -z "$ts_exitip" ] || ts_exitip="$(echo $ts_exitip | tr -d ' ')"
		[ -z "$ts_exitip" ] || CMD="${CMD} --exit-node=${ts_exitip}"
		[ -z "$ts_server" ] || ts_server="$(echo $ts_server | tr -d ' ')"
		[ -z "$ts_server" ] || CMD="${CMD} --login-server=${ts_server}"
		[ "$ts_ssh" = "1" ] && CMD="${CMD} --ssh"
		[ "$ts_shields" = "1" ] && CMD="${CMD} --shields-up"
		[ -z "$ts_host" ] || ts_host="$(echo $ts_host | tr -d ' ')"
		[ -z "$ts_host" ] || CMD="${CMD} --hostname=${ts_host}"
		[ -z "$ts_key" ] || ts_key="$(echo $ts_key | tr -d ' ')"
		[ -z "$ts_key" ] || CMD="${CMD} --auth-key=${ts_key}"
		[ -z "$t2_CMD" ] || CMD="${CMD} ${t2_CMD}"
		CMD="${tailscale} ${CMD}"
	fi
	if [ "$ts_enable" = "2" ] ; then
		if [ ! -z "$t_CMD" ] ; then
			
			CMD="${tailscale} ${t_CMD}"
		else
			logger -t "Tailscaled" "自定义启动参数为空，设置为默认参数:  up"
			CMD="${tailscale} up"
			nvram get tailscale_cmd="up"
		fi
	fi
	logger -t "Tailscaled" "运行子程序 ${CMD}"
	eval "$cmd >>/tmp/tailscale.log 2>&1" &
	sleep 4
	if [ ! -z "`pidof tailscale`" ] ; then
		logger -t "Tailscaled" "子程序运行成功！"
	else
		logger -t "Tailscaled" "子程序运行失败！"
	fi
	ts_keep
	exit 0
}
kill_ts() {
	tsd_process=$(pidof tailscaled)
	ts_process=$(pidof tailscaled)
	rm -rf /tmp/tailscale.log
	if [ -n "$ts_process" ] || [ -n "$tsd_process" ]; then
		logger -t "Tailscaled" "有进程在运行，结束中..."
		[ -f "$tailscaled" ] && $tailscaled --cleanup >/tmp/tailscale.log
		killall tailscaled >/dev/null 2>&1
		killall tailscale >/dev/null 2>&1
	fi
}
stop_ts() {
	logger -t "Tailscale" "正在关闭tailscaled..."
	sed -Ei '/【Tailscaled】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	kill_ts
	[ ! -z "`pidof tailscaled`" ] && logger -t "Tailscale" "tailscaled关闭成功!"
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
