#!/bin/sh

vhusbd_enable=$(nvram get virtualhere_enable)
vhusbd_wan="$(nvram get virtualhere_wan)"
vhusbd_v6="$(nvram get virtualhere_v6)"
vhusbd_bin="$(nvram get virtualhere_bin)"
virtualhere_renum=`nvram get virtualhere_renum`
if [ ! -z "$vhusbd_bin" ] ; then
	binname=$(basename $vhusbd_bin)
else
	nvram get virtualhere_bin="/etc/storage/bin/virtualhere"
	vhusbd_bin="/etc/storage/bin/virtualhere"
	binname="virtualhere"
fi

logg() {
  echo -e "\033[36;33m$(date +'%Y-%m-%d %H:%M:%S'):\033[0m\033[35;1m $1 \033[0m"
  logger -t "【VirtualHere】" "$1"
}

vhusbd_restart () {
relock="/var/lock/virtualhere_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set virtualhere_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	virtualhere_renum=${virtualhere_renum:-"0"}
	virtualhere_renum=`expr $virtualhere_renum + 1`
	nvram set virtualhere_renum="$virtualhere_renum"
	if [ "$virtualhere_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logg "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get virtualhere_renum)" = "0" ] && break
   			#[ "$(nvram get virtualhere_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set virtualhere_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
start_vhusbd
}

scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
vhusbd_keep() {
	logg "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【VirtualHere】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof ${binname}\`" ] && logger -t "进程守护" "VirtualHere进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【VirtualHere】|^$/d' /tmp/script/_opt_script_check #【VirtualHere】
	OSC
	if [ "$vhusbd_wan" = "1" ]; then
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\$(iptables -L -n -v | grep '7575')" ] && logger -t "进程守护" "VirtualHere 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【VirtualHere】|^$/d' /tmp/script/_opt_script_check #【VirtualHere】
	OSC
	fi
	
	fi

}


start_vhusbd() {
	[ "$vhusbd_enable" = "0" ] && exit 1
	logg "正在启动$vhusbd_bin"
 	if [ -f "$vhusbd_bin" ] ; then
		[ ! -x "$vhusbd_bin" ] && chmod +x $vhusbd_bin
  	fi
 	if [ ! -f "$vhusbd_bin" ] || [[ "$($vhusbd_bin -h 2>&1 | wc -l)" -lt 2 ]] ; then
		logg "程序${vhusbd_bin}不存在或不完整 不支持此架构，请下载上传后重试！"
  		exit 1
  	fi
	sed -Ei '/【VirtualHere】|^$/d' /tmp/script/_opt_script_check
	vhusbd_ver=$($vhusbd_bin -h | grep "${binname}" | sed -n '1p' | awk '{print $NF}')
	nvram set vhusbd_ver="$vhusbd_ver"
	killall $binname >/dev/null 2>&1
	killall -9 $binname >/dev/null 2>&1
	sleep 2
	CMD=""
	[ "$vhusbd_v6" = "1" ] && CMD="-i"
	vhusbd_script="/etc/storage/virtualhere.ini"
	if [ ! -f "$vhusbd_script" ] || [ ! -s "$vhusbd_script" ] ; then
	cat > "$vhusbd_script" <<-\VVR
ServerName=$HOSTNAME$
AutoAttachToKernel=1

VVR
	
	fi
	vhusbdcmd="${vhusbd_bin} ${CMD} -b -c /etc/storage/virtualhere.ini"
	logg "运行${vhusbdcmd}"
	eval "$vhusbdcmd" &
	sleep 4
	if [ ! -z "`pidof ${binname}`" ] ; then
 		logg "运行成功！"
  		vhusbd_restart o
  		vhusbd_keep
  		if [ "$vhusbd_wan" = "1" ] ; then
  			iptables -t filter -I INPUT -p tcp --dport 7575 -j ACCEPT
  			ip6tables -t filter -I INPUT -p tcp --dport 7575 -j ACCEPT
  		fi
	else
		logg "运行失败, 注意检查${vhusbd_bin}是否完整, 7575 端口是否被占用,10 秒后自动尝试重新启动"
  		sleep 10
  		vhusbd_restart x
	fi
	return 0
}


stop_vhusbd() {
	logg  "正在关闭..."
	sed -Ei '/【VirtualHere】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	killall $binname >/dev/null 2>&1
	killall -9 $binname >/dev/null 2>&1
	sleep 2
	iptables -t filter -D INPUT -p tcp --dport 7575 -j ACCEPT 2>/dev/null
	ip6tables -t filter -D INPUT -p tcp --dport 7575 -j ACCEPT 2>/dev/null
	[ -z "`pidof ${binname}`" ] && logg "进程已关闭!"
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
}


case $1 in
start)
	start_vhusbd &
	;;
stop)
	stop_vhusbd
	;;
restart)
	stop_vhusbd
	start_vhusbd &
	;;
*)
	echo "check"
	#exit 0
	;;
esac
