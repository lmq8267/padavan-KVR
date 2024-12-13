#!/bin/sh


scriptname=$(basename $0)
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
SN=$(ip addr show br0 | grep "link/ether" | awk '{print $2}')
uu_enable=`nvram get uu_enable`
[ -z "$uu_enable" ] && uu_enable=0 && nvram set uu_enable=0

logg  () {
  echo -e "\033[36;33m$(date +'%Y-%m-%d %H:%M:%S'):\033[0m\033[35;1m $1 \033[0m"
  logger -t "【网易UU游戏加速器】" "$1"
}

uu_keep() {
	logg "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【网易UU游戏加速器】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof uuplugin\`" ] && logger -t "进程守护" "UU加速器 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【网易UU游戏加速器】|^$/d' /tmp/script/_opt_script_check #【网易UU游戏加速器】
	OSC

	fi

}
uu_renum=`nvram get uu_renum`

uu_restart () {
relock="/var/lock/uu_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set uu_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	uu_renum=${uu_renum:-"0"}
	uu_renum=`expr $uu_renum + 1`
	nvram set uu_renum="$uu_renum"
	if [ "$uu_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logg "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get uu_renum)" = "0" ] && break
   			#[ "$(nvram get uu_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set uu_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
uu_start
}

uu_start () {
  [ "$uu_enable" != "1" ] && exit 1
  logg "开始启动"
  sed -Ei '/【网易UU游戏加速器】|^$/d' /tmp/script/_opt_script_check
  killall uuplugin >/dev/null 2>&1
  killall -9 uuplugin >/dev/null 2>&1
  UU_CONF="/tmp/uu/uu.conf"
  PROG="/tmp/uu/uuplugin"
  uurl="https://router.uu.163.com/api/plugin?type=merlin-mipsel"
  mkdir -p /tmp/uu
  if [ -s "$PROG" ] ; then
     chmod a+x $PROG
     #[ $(($($PROG -v | wc -l))) -lt 3 ]  && rm -rf $PROG 
  fi
if [ ! -s "$PROG" ] || [ ! -s "$UU_CONF" ] ; then
   logg "$PROG 程序未找到，开始下载"
    UU_url=$(curl -L -s -k -H "Accept:text/plain" "$uurl" | wget --header=Accept:text/plain -q --no-check-certificate -O - "$uurl" | curl -s -k -H "Accept:text/plain" "$uurl")
    [ -z "$UU_url" ] && UU_url="https://uu.gdl.netease.com/uuplugin/merlin-mipsel/v6.3.10/uu.tar.gz,2482ce645a208451b99301b717085afd"
    plugin_url=$(echo "$UU_url" | cut  -d ',' -f 1)
    plugin_md5=$(echo "$UU_url" | cut  -d ',' -f 2)
    logg "下载$plugin_url 到/tmp/uu.tar.gz"
    length=$(wget --no-check-certificate -T 5 -t 3 "$plugin_url" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
    length=`expr $length + 512000`
    length=`expr $length / 1048576`
    [ ! -z "$length" ] && logg "uu.tar.gz压缩包大小 ${length}M"
    curl -L -s -k "$plugin_url" -o /tmp/uu.tar.gz >/dev/null 2>&1 || wget -q --no-check-certificate "$plugin_url" -O /tmp/uu.tar.gz >/dev/null 2>&1 || curl -s -k "$plugin_url" -o /tmp/uu.tar.gz >/dev/null 2>&1 
    download_md5=$(md5sum /tmp/uu.tar.gz | awk '{print $1}')
    if [ "$download_md5" != "$plugin_md5" ];then
            logg "下载的/tmp/uu.tar.gz不完整！脚本退出运行"
            rm -rf /tmp/uu.tar.gz
          else
            logg "下载完成，开始解压到$PROG"
            tar zxf /tmp/uu.tar.gz -C /tmp/uu
            rm -rf /tmp/uu.tar.gz
          fi
fi
if [ -s "$PROG" ] ; then
     chmod a+x $PROG
     uuver=$($PROG -v | awk -F 'version:' '{print $2}' | tr -d ' \n')
     [ -z "$uuver" ] && rm -rf /tmp/uu && logg "下载的程序${PROG}不完整或不匹配mipesl架构" 
fi
logg "运行uuplugin-$uuver"
$PROG $UU_CONF >/dev/null 2>&1 &
sleep 6
if [ ! -z "`pidof uuplugin`" ] ; then
  mem=$(cat /proc/$(pidof uuplugin)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
  cpui="$(top -b -n1 | grep -E "$(pidof uuplugin)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /uuplugin/) break; else cpu=i}} END {print $cpu}')"
  logg "设备SN：$SN"
  logg "uuplugin-$uuver 启动成功" 
  uu_restart o
  logg "内存占用 ${mem} CPU占用 ${cpui}%"
  uu_keep
  nvram set uu_admin="https://router.uu.163.com/asus/pc/login?gwSn=${SN}&type=asuswrt-merlin&redirect=acce"
fi
[ -z "`pidof uuplugin`" ] && logg "启动失败, 注意检查${PROG}是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && uu_restart x

}

uu_close () {
  logg "关闭UU加速器..."
  sed -Ei '/【网易UU游戏加速器】|^$/d' /tmp/script/_opt_script_check
  scriptname=$(basename $0)
  killall uuplugin >/dev/null 2>&1
  killall -9 uuplugin >/dev/null 2>&1
  rm -rf /tmp/uu
  sleep 4
  [ -z "`pidof uuplugin`" ] && logg "进程已关闭!"
  if [ ! -z "$scriptname" ] ; then
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
  fi
}

case $1 in
start)
	uu_start &
	;;
restart)
	uu_start &
	;;
stop)
	uu_close
	;;
*)
	uu_start &
	;;
esac

