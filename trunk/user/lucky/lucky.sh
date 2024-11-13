#!/bin/sh

scriptname=$(basename $0)
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
lucky_enable=`nvram get lucky_enable`
lucky_cmd=`nvram get lucky_cmd`
[ -z "$lucky_enable" ] && lucky_enable=0 && nvram set lucky_enable=0

logg  () {
  echo -e "\033[36;33m$(date +'%Y-%m-%d %H:%M:%S'):\033[0m\033[35;1m $1 \033[0m"
  logger -t "【lucky】" "$1"
}


lucky_start () {
  [ "$lucky_enable" != "1" ] && exit 1
  logg "开始启动"
  killall lucky >/dev/null 2>&1
  killall -9 lucky >/dev/null 2>&1
  LUCKY_CONF="/etc/storage/lucky.conf"
  PROG="/etc/storage/lucky/lucky" 
  [ ! -d /etc/storage/lucky ] && mkdir -p /etc/storage/lucky
  if [ -s "$PROG" ] ; then
     chmod a+x $PROG
     [ $(($($PROG -v | wc -l))) -lt 3 ]  && logg "程序${PROG}不完整或不匹配mipsel架构，请检查重新上传，脚本退出" && exit 1
  fi
if [ ! -s "$PROG" ] ; then
   logg "$PROG 程序未找到，请下载上传"
   exit 1
fi
if [ -s "$PROG" ] ; then
     chmod a+x $PROG
     [ $(($($PROG -v | wc -l))) -lt 3 ] && logg "下载的程序${PROG}不完整或不匹配mipsel架构，脚本退出" && exit 1
fi
cmd="${PROG} ${lucky_cmd}"
logg "运行${cmd}"
eval "$cmd >/tmp/lucky.log" &
sleep 6
if [ ! -z "`pidof lucky`" ] ; then
  lucky_port=$(cat /tmp/lucky.log | awk -F 'http://:' '{print $2}' | sed 's/[^0-9]//g' | tr -d '\n')
  lan_ip=`nvram get lan_ipaddr`
  logg "lucky启动成功" 
  if [ ! -z "$lucky_port" ] && [ ! -z "$lan_ip" ] ; then
	nvram set lucky_login="http://${lan_ip}:${lucky_port}"
  fi
fi
[ -z "`pidof lucky`" ] && logg "lucky启动失败!" 

}

lucky_close () {
logg "关闭lucky..."
  killall lucky >/dev/null 2>&1
  killall -9 lucky >/dev/null 2>&1
  rm -rf /tmp/lucky.log
  sleep 4
  [ -z "`pidof lucky`" ] && logg "进程已关闭!"
}

case $1 in
start)
	lucky_start
	;;
restart)
	lucky_start
	;;
stop)
	lucky_close
	;;
*)
	lucky_start
	;;
esac

