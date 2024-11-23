#!/bin/sh
#20200426 chongshengB
#20210410 xumng123
#20240831 fightround
PROG="$(nvram get zerotier_bin)"
[ -z "$PROG" ] && PROG=/etc/storage/bin/zerotier-one
PROGCLI=/etc/storage/bin/zerotier-cli
PROGIDT=/etc/storage/bin/zerotier-idtool
config_path="/etc/storage/zerotier-one"
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)

start_instance() {
	port="$(nvram get zerotier_port)"
	args="$(nvram get zerotier_args)"
	nwid="$(nvram get zerotier_id)"
	moonid="$(nvram get zerotier_moonid)"
	secret="$(nvram get zerotier_secret)"
	mkdir -p $config_path/networks.d
	mkdir -p $config_path/moons.d
	if [ -n "$port" ]; then
		args="$args -p$port"
	fi
	if [ ! -s "$config_path/identity.secret" ] || [ -z "$secret" ]; then
		logger -t "【zerotier】" "密匙为空,正在生成密匙,请稍后..."
		sf="$config_path/identity.secret"
		pf="$config_path/identity.public"
		$PROGIDT generate "$sf" "$pf"  >/dev/null
		[ $? -ne 0 ] && return 1
		secret="$(cat $sf)"
		#rm "$sf"
		nvram set zerotier_secret="$secret"
		nvram commit
	else
		logger -t "【zerotier】" "找到密匙,正在写入文件,请稍后..."
		echo "$secret" >$config_path/identity.secret
		$PROGIDT getpublic $config_path/identity.secret >$config_path/identity.public
		#rm -f $config_path/identity.public
	fi
	logger -t "【zerotier】" "启动 $PROG $args $config_path"
	$PROG $args $config_path >/dev/null 2>&1 &

	while [ ! -f $config_path/zerotier-one.port ]; do
		sleep 1
	done
	if [ -n "$moonid" ]; then
		$PROGCLI orbit $moonid $moonid
		logger -t "【zerotier】" "加入moon: $moonid 成功!"
	fi
	if [ -n "$nwid" ]; then
		$PROGCLI join $nwid
		logger -t "【zerotier】" "加入网络: $nwid 成功!"
		rules

	fi
}

zt_keep() {
	logger -t "【zerotier】" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【zerotier】|^$/d' /tmp/script/_opt_script_check
	zt0=$(ifconfig | grep zt | awk '{print $1}')
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof zerotier-one\`" ] && logger -t "进程守护" "zerotier-one 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【zerotier】|^$/d' /tmp/script/_opt_script_check #【zerotier】
	[ -z "\$(iptables -L -n -v | grep '$zt0')" ] && logger -t "进程守护" "zerotier-one 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【zerotier】|^$/d' /tmp/script/_opt_script_check #【zerotier】
	OSC

	fi


}

rules() {
	while [ "$(ifconfig | grep zt | awk '{print $1}')" = "" ]; do
		sleep 1
	done
	nat_enable=$(nvram get zerotier_nat)
	zt0=$(ifconfig | grep zt | awk '{print $1}')
	del_rules
 	logger -t "【zerotier】" "添加${zt0}防火墙规则中..."
	iptables -I INPUT -i $zt0 -j ACCEPT
	iptables -I FORWARD -i $zt0 -o $zt0 -j ACCEPT
	iptables -I FORWARD -i $zt0 -j ACCEPT
	if [ $nat_enable -eq 1 ]; then
		iptables -t nat -I POSTROUTING -o $zt0 -j MASQUERADE
		while [ "$(ip route | grep -E "dev\s+$zt0\s+proto\s+kernel"| awk '{print $1}')" = "" ]; do
		    sleep 1
		done
		ip_segment=$(ip route | grep -E "dev\s+$zt0\s+proto\s+kernel"| awk '{print $1}')
                logger -t "zerotier" "将 $zt0 网段 $ip_segment 添加进NAT规则中..."
		iptables -t nat -I POSTROUTING -s $ip_segment -j MASQUERADE
		zero_route "add"
	fi
	logger -t "【zerotier】" "zerotier-one ${zt_ver}启动成功! zerotier接口: $zt0 "
 	count=0
        while [ $count -lt 5 ]
        do
       ztstatus=$($PROGCLI info | awk '{print $5}')
       if [ "$ztstatus" = "OFFLINE" ]; then
	        sleep 2
        elif [ "$ztstatus" = "ONLINE" ]; then
        	ztid=$($PROGCLI info | awk '{print $3}')
        	nvram set zerotierdev_id=$ztid
        	nvram set zerotier_status="${ztstatus} 在线"
        	break
        fi
        count=$(expr $count + 1)
        done
	if [ "$($PROGCLI info | awk '{print $5}')" = "OFFLINE" ] ; then
	  logger -t "【zerotier】" "当前zerotier未上线，可能你的网络无法链接到zerotier官方服务器！"
	  nvram set zerotier_status="OFFLINE 离线"
          exit 1
        fi
        zt_keep
}

del_rules() {
	zt0=$(ifconfig | grep zt | awk '{print $1}')
	ip_segment=$(ip route | grep -E "dev\s+$zt0\s+proto\s+kernel"| awk '{print $1}')
	logger -t "【zerotier】" "删除${zt0}防火墙规则中..."
	iptables -D INPUT -i $zt0 -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i $zt0 -o $zt0 -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i $zt0 -j ACCEPT 2>/dev/null
	iptables -t nat -D POSTROUTING -o $zt0 -j MASQUERADE 2>/dev/null
	iptables -t nat -D POSTROUTING -s $ip_segment -j MASQUERADE 2>/dev/null
}

zero_route(){
	rulesnum=`nvram get zero_staticnum_x`
	for i in $(seq 1 $rulesnum)
	do
		j=`expr $i - 1`
		route_enable=`nvram get zero_enable_x$j`
		zero_ip=`nvram get zero_ip_x$j`
		zero_route=`nvram get zero_route_x$j`
		if [ "$1" = "add" ]; then
			if [ $route_enable -ne 0 ]; then
				ip route add $zero_ip via $zero_route dev $zt0
				echo "$zt0"
			fi
		else
			ip route del $zero_ip via $zero_route dev $zt0
		fi
	done
}

get_zttag() {
	curltest=`which curl`
	logger -t "【zerotier】" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/lmq8267/ZeroTierOne/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/ZeroTierOne/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/ZeroTierOne/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/ZeroTierOne/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "【zerotier】" "无法获取最新版本" && nvram set zerotier_ver_n="" 
	nvram set zerotier_ver_n=$tag
	if [ -f "$PROG" ] ; then
		chmod +x $PROG
		zt_ver=$($PROG -version | sed -n '1p')
		if [ -z "$zt_ver" ] ; then 
			nvram set zerotier_ver=""
		else
			nvram set zerotier_ver=$zt_ver
		fi
		[ ! -L "$PROGCLI" ] && ln -sf $PROG $PROGCLI
		ztstatus=$($PROGCLI info | awk '{print $5}')
		ztid=$($PROGCLI info | awk '{print $3}')
		nvram set zerotierdev_id=$ztid
		if [ "$ztstatus" = "ONLINE" ]; then
			nvram set zerotier_status="${ztstatus} 在线"
		else
			nvram set zerotier_status="OFFLINE 离线"
		fi
	fi
}

dowload_zero() {
	tag="$1"
	logger -t "【zerotier】" "开始下载 https://github.com/lmq8267/ZeroTierOne/releases/download/${tag}/zerotier-one 到 $PROG"
	for proxy in $github_proxys ; do
       curl -Lko "$PROG" "${proxy}https://github.com/lmq8267/ZeroTierOne/releases/download/${tag}/zerotier-one" || wget --no-check-certificate -O "$PROG" "${proxy}https://github.com/lmq8267/ZeroTierOne/releases/download/${tag}/zerotier-one" || curl -Lkso "$PROG" "https://fastly.jsdelivr.net/gh/lmq8267/ZeroTierOne@master/install/${tag}/zerotier-one" || wget --no-check-certificate -q -O "$PROG" "https://fastly.jsdelivr.net/gh/lmq8267/ZeroTierOne@master/install/${tag}/zerotier-one"
	if [ "$?" = 0 ] ; then
		chmod +x $PROG
		if [ $(($($PROG -h | wc -l))) -gt 3 ] ; then
			logger -t "【zerotier】" "$PROG 下载成功"
			zt_ver=$($PROG -version | sed -n '1p')
			if [ -z "$zt_ver" ] ; then 
				nvram set zerotier_ver=""
			else
				nvram set zerotier_ver=$zt_ver
			fi
			break
       	else
	   		logger -t "【zerotier】" "下载不完整，请手动下载 ${proxy}https://github.com/lmq8267/ZeroTierOne/releases/download/${tag}/zerotier-one 上传到  $PROG"
			rm -f $PROG
	  	fi
	else
		logger -t "【zerotier】" "下载失败，请手动下载 ${proxy}https://github.com/lmq8267/ZeroTierOne/releases/download/${tag}/zerotier-one 上传到  $PROG"
   	fi
	done
}

update_zero() {
	get_zttag
	[ -z "$tag" ] && logger -t "【zerotier】" "无法获取最新版本" && nvram set zerotier_ver_n="" && exit 1
	if [ ! -z "$tag" ] && [ ! -z "$zt_ver" ] ; then
		if [ "$tag"x != "$zt_ver"x ] ; then
			logger -t "【zerotier】" "当前版本${zt_ver} 最新版本${tag}"
			dowload_zero $tag
		else
			logger -t "【zerotier】" "当前已是最新版本 ${tag} 无需更新！"
		fi
	fi
	exit 0
}

start_zero() {
	zt_enable=$(nvram get zerotier_enable)
	[ "$zt_enable" = "1" ] || exit 1
	logger -t "【zerotier】" "正在启动zerotier"
	sed -Ei '/【zerotier】|^$/d' /tmp/script/_opt_script_check
	get_zttag
 	if [ ! -f "$PROG" ] ; then
		logger -t "【zerotier】" "主程序${PROG}不存在，开始在线下载..."
  		[ ! -d /etc/storage/bin ] && mkdir -p /etc/storage/bin
  		[ -z "$tag" ] && tag="1.14.2"
  		dowload_zero $tag
  	fi
  	[ ! -f "$PROG" ] && exit 1
   	if [ ! -L "$PROGCLI" ] || [ "$(ls -l $PROGCLI | awk '{print $NF}')" != "$PROG" ] ; then
		ln -sf $PROG $PROGCLI
	fi
 	if [ ! -L "$PROGIDT" ] || [ "$(ls -l $PROGIDT | awk '{print $NF}')" != "$PROG" ] ; then
		ln -sf $PROG $PROGIDT
	fi
	kill_z
	start_instance 'zerotier'

}
kill_z() {
	zerotier_process=$(pidof zerotier-one)
	if [ ! -z "$zerotier_process" ]; then
		#logger -t "【zerotier】" "有进程 $zerotier_proces 在运行，结束中..."
		killall zerotier-one >/dev/null 2>&1
		kill -9 "$zerotier_process" >/dev/null 2>&1
	fi
}
stop_zero() {
    	logger -t "【zerotier】" "正在关闭zerotier..."
    	sed -Ei '/【zerotier】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	del_rules
	zero_route "del"
	kill_z
	#rm -rf $config_path
	logger -t "【zerotier】" "zerotier关闭成功!"
}

case $1 in
start)
	start_zero &
	;;
stop)
	stop_zero
	;;
update)
	update_zero &
	;;
*)
	echo "check"
	#exit 0
	;;
esac
