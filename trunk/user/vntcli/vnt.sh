#!/bin/sh

vntcli_enable=$(nvram get vntcli_enable)
VNTCLI="$(nvram get vntcli_bin)"
vntcli_token="$(nvram get vntcli_token)"
vntcli_ip="$(nvram get vntcli_ip)"
vntcli_localadd="$(nvram get vntcli_localadd)"
vntcli_serip="$(nvram get vntcli_serip)"
vntcli_model="$(nvram get vntcli_model)"
vntcli_key="$(nvram get vntcli_key)"
vntcli_log="$(nvram get vntcli_log)"
vntcli_proxy="$(nvram get vntcli_proxy)"
vntcli_first="$(nvram get vntcli_first)"
vntcli_wg="$(nvram get vntcli_wg)"
vntcli_finger="$(nvram get vntcli_finger)"
vntcli_serverw="$(nvram get vntcli_serverw)"
vntcli_desname="$(nvram get vntcli_desname)"
vntcli_id="$(nvram get vntcli_id)"
vntcli_tunname="$(nvram get vntcli_tunname)"
vntcli_mtu="$(nvram get vntcli_mtu)"
vntcli_dns="$(nvram get vntcli_dns)"
vntcli_stun="$(nvram get vntcli_stun)"
vntcli_port="$(nvram get vntcli_port)"
vntcli_punch="$(nvram get vntcli_punch)"
vntcli_comp="$(nvram get vntcli_comp)"
vntcli_relay="$(nvram get vntcli_relay)"
vntcli_wan="$(nvram get vntcli_wan)"

[ -z "$VNTCLI" ] && VNTCLI=/tmp/var/vnt-cli && nvram set vntcli_bin=$VNTCLI
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
if [ ! -z "$vntcli_port" ] ; then
	if [ ! -z "$(echo $vntcli_port | grep ',' )" ] ; then
		vnt_tcp_port="${vntcli_port%%,*}"
	else
		vnt_tcp_port="$vntcli_port"
	fi
fi

get_tag() {
	curltest=`which curl`
	logger -t "VNT客户端" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "VNT客户端" "无法获取最新版本"  
	nvram set vntcli_ver_n=$tag
	if [ -f "$VNTCLI" ] ; then
		chmod +x $VNTCLI
		vntcli_ver=$($VNTCLI -h | grep 'version:' | awk -F 'version:' '{print $2}' | tr -d ' ' | tr -d '\n')
		if [ -z "$vntcli_ver" ] ; then
			nvram set vntcli_ver=""
		else
			nvram set vntcli_ver="v${vntcli_ver}"
		fi
	fi
}

dowload_vntcli() {
	tag="$1"
	bin_path=$(dirname "$VNTCLI")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
	logger -t "VNT客户端" "开始下载 https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_mipsel-unknown-linux-musl 到 $VNTCLI"
	for proxy in $github_proxys ; do
       curl -Lkso "$VNTCLI" "${proxy}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_mipsel-unknown-linux-musl" || wget --no-check-certificate -q -O "$VNTCLI" "${proxy}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_mipsel-unknown-linux-musl"
	if [ "$?" = 0 ] ; then
		chmod +x $VNTCLI
		if [ $(($($VNTCLI -h | wc -l))) -gt 3 ] ; then
			logger -t "VNT客户端" "$VNTCLI 下载成功"
			vntcli_ver=$($VNTCLI -h | grep 'version:' | awk -F 'version:' '{print $2}' | tr -d ' ' | tr -d '\n')
			if [ -z "$vntcli_ver" ] ; then
				nvram set vntcli_ver=""
			else
				nvram set vntcli_ver="v${vntcli_ver}"
			fi
			break
       	else
	   		logger -t "VNT客户端" "下载不完整，请手动下载 ${proxy}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_mipsel-unknown-linux-musl 上传到  $VNTCLI"
	   		rm -f $VNTCLI
	  	fi
	else
		logger -t "VNT客户端" "下载失败，请手动下载 ${proxy}https://github.com/lmq8267/vnt-cli/releases/download/${tag}/vnt-cli_mipsel-unknown-linux-musl 上传到  $VNTCLI"
   	fi
	done
}

update_vntcli() {
	get_tag
	[ -z "$tag" ] && logger -t "VNT客户端" "无法获取最新版本" && exit 1
	tag=$(echo $tag | tr -d 'v' | tr -d ' ' | tr -d '\n')
	if [ ! -z "$tag" ] && [ ! -z "$vntcli_ver" ] ; then
		if [ "$tag"x != "$vntcli_ver"x ] ; then
			logger -t "VNT客户端" "当前版本${vntcli_ver} 最新版本${tag}"
			dowload_vntcli $tag
		else
			logger -t "VNT客户端" "当前已是最新版本 ${tag} 无需更新！"
		fi
	fi
	exit 0
}

vnt_rules() {
	if [ -z "$vntcli_tunname" ] ; then
		tunname="vnt-tun"
	else
		tunname="${vntcli_tunname}"
	fi
	iptables -I INPUT -i ${tunname} -j ACCEPT
	iptables -I FORWARD -i ${tunname} -o ${tunname} -j ACCEPT
	iptables -I FORWARD -i ${tunname} -j ACCEPT
	iptables -t nat -I POSTROUTING -o ${tunname} -j MASQUERADE
	[ "$vntcli_proxy" = "1" ] && sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
	if [ ! -z "$vnt_tcp_port" ] ; then
		 iptables -I INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT
		 ip6tables -I INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT
	fi
}

start_vntcli() {
	[ "$vntcli_enable" = "0" ] && exit 1
	logger -t "VNT客户端" "正在启动vnt-cli"
	get_tag
 	if [ ! -f "$VNTCLI" ] ; then
		logger -t "VNT客户端" "主程序${VNTCLI}不存在，开始在线下载..."
  		[ ! -d /etc/storage/bin ] && mkdir -p /etc/storage/bin
  		[ -z "$tag" ] && tag="1.2.15"
  		dowload_vntcli $tag
  	fi
  	[ ! -f "$VNTCLI" ] && exit 1
	chmod +x $VNTCLI
	[ $(($($VNTCLI -h | wc -l))) -lt 3 ] && logger -t "VNT客户端" "程序${VNTCLI}不完整，无法运行！" && exit 1
	killall vnt-cli >/dev/null 2>&1
	
	if [ "$vntcli_log" = "1" ] ; then
		path=$(dirname "$VNTCLI")
		log_path="${path}/log"
		if [ ! -f "${log_path}/log4rs.yaml" ] ; then
			mkdir -p ${log_path}
cat > "${log_path}/log4rs.yaml"<<EOF
refresh_rate: 30 seconds
appenders:
  rolling_file:
    kind: rolling_file
    path: /tmp/vnt-cli.log
    append: true
    encoder:
      pattern: "{d(%Y-%m-%d %H:%M:%S vnt-cli:)} [{f}:{L}] {h({l})} {M}:{m}{n}"
    policy:
      kind: compound
      trigger:
        kind: size
        limit: 1 mb
      roller:
        kind: fixed_window
        pattern: /tmp/vnt-cli.{}.log
        base: 1
        count: 2

root:
  level: info
  appenders:
    - rolling_file
EOF
		fi
		[ ! -L /tmp/vnt-cli.1.log ] && ln -sf /tmp/vnt-cli.log /tmp/vnt-cli.1.log
		[ ! -L /tmp/vnt-cli.2.log ] && ln -sf /tmp/vnt-cli.log /tmp/vnt-cli.2.log
		sed -i 's|limit: 10 mb|limit: 1 mb|g' ${log_path}/log4rs.yaml
		sed -i 's|count: 5|count: 2|g' ${log_path}/log4rs.yaml
		logyaml=$(cat ${log_path}/log4rs.yaml | grep path: | awk -F'path: ' '{print $2}')
		logyaml2=$(cat ${log_path}/log4rs.yaml | grep pattern: | awk -F'pattern: ' '{print $2}')
		if [ "$logyaml" != "/tmp/vnt-cli.log" ] ; then
			sed -i "s|${logyaml}|/tmp/vnt-cli.log|g" ${log_path}/log4rs.yaml
			sed -i "s|${logyaml2}|/tmp/vnt-cli.{}.log|g" ${log_path}/log4rs.yaml
		fi
	else
		[ -f "${log_path}/log4rs.yaml" ] && rm -f ${log_path}/log4rs.yaml
	fi
	CMD=""
	if [ "$vntcli_enable" = "1" ] ; then
	if [ -z "$vntcli_token" ] ; then
		logger -t "VNT客户端" "Token为必填项，不能为空！程序退出！"
		exit 1
	fi
	[ -z "$vntcli_token" ] || CMD="-k $vntcli_token"
	[ -z "$vntcli_ip" ] || CMD="${CMD} --ip ${vntcli_ip}"
	if [ ! -z "$vntcli_localadd" ] ; then
		for localadd in $vntcli_localadd ; do
			[ -z "$localadd" ] && continue
			CMD="${CMD} -o ${localadd}"
		done	
	fi
	routenum=`nvram get vntcli_routenum_x`
	for r in $(seq 1 $routenum)
	do
		i=`expr $r - 1`
		vnt_route=`nvram get vntcli_route_x$i`
		vnt_ip=`nvram get vntcli_ip_x$i`
		vnt_peer="${vnt_route},${vnt_ip}"
		vnt_peer="$(echo $vnt_peer | tr -d ' ')"
		CMD="${CMD} -i ${vnt_peer}"
	done
	[ -z "$vntcli_serip" ] || CMD="${CMD} -s ${vntcli_serip}"
	[ "$vntcli_model" = "1" ] && CMD="${CMD} --model xor"
	[ "$vntcli_model" = "2" ] && CMD="${CMD} --model aes_ecb"
	[ "$vntcli_model" = "3" ] && CMD="${CMD} --model chacha20"
	[ "$vntcli_model" = "4" ] && CMD="${CMD} --model chacha20_poly1305"
	[ "$vntcli_model" = "5" ] && CMD="${CMD} --model sm4_cbc"
	[ "$vntcli_model" = "6" ] && CMD="${CMD} --model aes_cbc"
	[ "$vntcli_model" = "7" ] && CMD="${CMD} --model aes_gcm"
	[ -z "$vntcli_key" ] || CMD="${CMD} -w ${vntcli_key}"
	[ "$vntcli_proxy" = "1" ] && CMD="${CMD} --no-proxy"
	[ "$vntcli_first" = "1" ] && CMD="${CMD} --first-latency"
	[ "$vntcli_wg" = "1" ] && CMD="${CMD}  --allow-wg"
	[ "$vntcli_finger" = "1" ] && CMD="${CMD} --finger"
	[ "$vntcli_serverw" = "1" ] && CMD="${CMD} -W"
	[ -z "$vntcli_desname" ] || CMD="${CMD} -n ${vntcli_desname}"
	if [ -z "$vntcli_id" ] ; then
		if [ ! -z "$vntcli_ip" ] ; then
			vntcli_id="$vntcli_ip"
			nvram set vntcli_id="$vntcli_ip"
			CMD="${CMD} -d ${$vntcli_id}"
		fi
	else
		CMD="${CMD} -d ${$vntcli_id}"
	fi
	[ -z "$vntcli_tunname" ] || CMD="${CMD} --nic ${vntcli_tunname}"
	[ -z "$vntcli_mtu" ] || CMD="${CMD} -u ${vntcli_mtu}"
	
	if [ ! -z "$vntcli_dns" ] ; then
		for dns in $vntcli_dns ; do
			[ -z "$dns" ] && continue
			CMD="${CMD} --dns ${dns}"
		done	
	fi
	if [ ! -z "$vntcli_stun" ] ; then
		for stun in $vntcli_stun ; do
			[ -z "$stun" ] && continue
			CMD="${CMD} -e ${stun}"
		done	
	fi
	[ -z "$vntcli_port" ] || CMD="${CMD} --ports ${vntcli_port}"
	[ -z "$vntcli_wan" ] || CMD="${CMD} --local-dev ${vntcli_wan}"
	[ "$vntcli_punch" = "0" ] || CMD="${CMD} --punch ${vntcli_punch}"
	[ "$vntcli_comp" = "0" ] || CMD="${CMD} --compressor ${vntcli_comp}"
	[ "$vntcli_relay" = "0" ] || CMD="${CMD} --use-channel ${vntcli_relay}"
	mappnum=`nvram get vntcli_mappnum_x`
	for m in $(seq 1 $mappnum)
	do
		p=`expr $m - 1`
		vnt_mappnet=`nvram get vntcli_mappnet_x$p`
		vnt_mappport=`nvram get vntcli_mappport_x$p`
		vnt_mappip=`nvram get vntcli_mappip_x$p`
		vnt_mapeerport=`nvram get vntcli_mapeerport_x$p`
		vnt_mapping="${vnt_mappnet}:0.0.0.0:${vnt_mappport}-${vnt_mappip}:${vnt_mapeerport}"
		vnt_mapping="$(echo $vnt_mapping | tr -d ' ')"
		CMD="${CMD} --mapping ${vnt_mapping}"
	done
	vntclicmd="cd $vntpath ; ./vnt-cli ${CMD} --disable-stats >/tmp/vnt-cli.log 2>&1"
	fi
	if [ "$vntcli_enable" = "2" ] ; then
		if [ -z "$(grep '^token: ' /etc/storage/vnt.conf | awk -F 'token:' '{print $2}')" ] ; then
			logger -t "VNT客户端" "Token为必填项，不能为空！程序退出！"
			exit 1
		fi
		vntclicmd="cd $vntpath ; ./vnt-cli -f /etc/storage/vnt.conf >/tmp/vnt-cli.log 2>&1"
	
	fi
	echo "$vntclicmd" >/tmp/vnt-cli.CMD 
	logger -t "VNT客户端" "运行${vntclicmd}"
	eval "$vntclicmd" &
	sleep 4
	if [ ! -z "`pidof vnt-cli`" ] ; then
		logger -t "VNT客户端" "运行成功！"
		echo `date +%s` > /tmp/vntcli_time
		vnt_rules
	else
		logger -t "VNT客户端" "运行失败！"
	fi
	
	exit 0
}


stop_vnt() {
	logger -t "VNT客户端" "正在关闭vnt-cli..."
	scriptname=$(basename $0)
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	$VNTCLI --stop >>/tmp/vnt-cli.log
	killall vnt-cli >/dev/null 2>&1
	if [ ! -z "$vnt_tcp_port" ] ; then
		 iptables -D INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT 2>/dev/null
		 ip6tables -D INPUT -p tcp --dport $vnt_tcp_port -j ACCEPT 2>/dev/null
	fi
	iptables -D INPUT -i ${tunname} -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i ${tunname} -o ${tunname} -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i ${tunname} -j ACCEPT 2>/dev/null
	iptables -t nat -D POSTROUTING -o ${tunname} -j MASQUERADE 2>/dev/null
	[ ! -z "`pidof vnt-cli`" ] && logger -t "VNT客户端" "进程已关闭!"
}

vnt_error="错误：${VNTCLI} 未运行，请运行成功后执行此操作！"
vnt_process=$(pidof vnt-cli)
vntpath=$(dirname "$VNTCLI")
cmdfile="/tmp/vnt-cli.cmd"

vnt_info() {
	if [ -n "$vnt_process" ] ; then
		cd $vntpath
		./vnt-cli --info >$cmdfile
	else
		echo "$vnt_error" >$cmdfile
	fi
	exit 1
}

vnt_all() {
	if [ -n "$vnt_process" ] ; then
		cd $vntpath
		./vnt-cli --all >$cmdfile
	else
		echo "$vnt_error" >$cmdfile
	fi
	exit 1
}

vnt_list() {
	if [ -n "$vnt_process" ] ; then
		cd $vntpath
		./vnt-cli --list >$cmdfile
	else
		echo "$vnt_error" >$cmdfile
	fi
	exit 1
}

vnt_route() {
	if [ -n "$vnt_process" ] ; then
		cd $vntpath
		./vnt-cli --route >$cmdfile
	else
		echo "$vnt_error" >$cmdfile
	fi
	exit 1
}

vnt_status() {
	if [ -n "$vnt_process" ] ; then
		vntcpu="$(top -b -n1 | grep -E "$(pidof vnt-cli)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /vnt-cli/) break; else cpu=i}} END {print $cpu}')"
		echo -e "\t\t vnt-cli 运行状态\n" >$cmdfile
		[ ! -z "$vntcpu" ] && echo "CPU占用 ${vntcpu}% " >>$cmdfile
		vntram="$(cat /proc/$(pidof vnt-cli | awk '{print $NF}')/status|grep -w VmRSS|awk '{printf "%.2fMB\n", $2/1024}')"
		[ ! -z "$vntram" ] && echo "内存占用 ${vntram}" >>$cmdfile
		vnttime=$(cat /tmp/vntcli_time) 
		if [ -n "$vnttime" ] ; then
			time=$(( `date +%s`-vnttime))
			day=$((time/86400))
			[ "$day" = "0" ] && day=''|| day=" $day天"
			time=`date -u -d @${time} +%H小时%M分%S秒`
		fi
		[ ! -z "$time" ] && echo "已运行 $time" >>$cmdfile
		cmdtart=$(cat /tmp/vnt-cli.CMD)
		[ ! -z "$cmdtart" ] && echo "启动参数  $cmdtart" >>/tmp/upload/vnt_cmd.log 2>&1
		
	else
		echo "$vnt_error" >$cmdfile
	fi
	exit 1
}

case $1 in
start)
	start_vntcli &
	;;
stop)
	stop_vnt
	;;
restart)
	stop_vnt
	start_vntcli &
	;;
update)
	update_vntcli &
	;;
vntinfo)
	vnt_info
	;;
vntall)
	vnt_all
	;;
vntlist)
	vnt_list
	;;
vntroute)
	vnt_route
	;;
vntstatus)
	vnt_status
	;;
*)
	echo "check"
	#exit 0
	;;
esac
