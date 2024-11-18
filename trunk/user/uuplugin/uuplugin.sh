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
     [ $(($($PROG -v | wc -l))) -lt 3 ]  && rm -rf $PROG 
  fi
if [ ! -s "$PROG" ] || [ ! -s "$UU_CONF" ] ; then
   logg "$PROG 程序未找到，开始下载"
    UU_url=$(curl -L -s -k -H "Accept:text/plain" "$uurl" | wget --header=Accept:text/plain -q --no-check-certificate -O - "$uurl" | curl -s -k -H "Accept:text/plain" "$uurl")
    [ -z "$UU_url" ] && UU_url="https://uu.gdl.netease.com/uuplugin/merlin-mipsel/v6.3.10/uu.tar.gz,2482ce645a208451b99301b717085afd"
    plugin_url=$(echo "$UU_url" | cut  -d ',' -f 1)
    plugin_md5=$(echo "$UU_url" | cut  -d ',' -f 2)
    logg "下载$plugin_url 到/tmp/uu.tar.gz"
    curl -L -s -k "$plugin_url" -o /tmp/uu.tar.gz >/dev/null 2>&1 || wget -q --no-check-certificate "$plugin_url" -O /tmp/uu.tar.gz >/dev/null 2>&1 || curl -s -k "$plugin_url" -o /tmp/uu.tar.gz >/dev/null 2>&1 
    download_md5=$(md5sum /tmp/uu.tar.gz | awk '{print $1}')
    if [ "$download_md5" != "$plugin_md5" ];then
            logg "下载的/tmp/uu.tar.gz不完整！脚本退出运行"
            rm -rf /tmp/uu.tar.gz
            exit 1
          else
            logg "下载完成，开始解压到$PROG"
            tar zxf /tmp/uu.tar.gz -C /tmp/uu
            rm -rf /tmp/uu.tar.gz
          fi
fi
if [ -s "$PROG" ] ; then
     chmod a+x $PROG
     uuver=$($PROG -v | awk -F 'version:' '{print $2}' | tr -d ' \n')
     [ -z "$uuver" ] && rm -rf /tmp/uu && logg "下载的程序${PROG}不完整或不匹配mipesl架构，脚本退出" && exit 1
fi
logg "运行uuplugin-$uuver"
$PROG $UU_CONF >/dev/null 2>&1 &
sleep 6
if [ ! -z "`pidof uuplugin`" ] ; then
  logg "设备SN：$SN"
  logg "uuplugin-$uuver 启动成功" 
  uu_keep
  nvram set uu_admin="https://router.uu.163.com/asus/pc/login?gwSn=${SN}&type=asuswrt-merlin&redirect=acce"
fi
[ -z "`pidof uuplugin`" ] && logg "uuplugin启动失败!" 

}

uu_close () {
  logg "关闭UU加速器..."
  sed -Ei '/【网易UU游戏加速器】|^$/d' /tmp/script/_opt_script_check
  scriptname=$(basename $0)
  if [ ! -z "$scriptname" ] ; then
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
  fi
  killall uuplugin >/dev/null 2>&1
  killall -9 uuplugin >/dev/null 2>&1
  rm -rf /tmp/uu
  sleep 4
  [ -z "`pidof uuplugin`" ] && logg "进程已关闭!"
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

