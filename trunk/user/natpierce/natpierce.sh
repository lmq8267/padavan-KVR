#!/bin/sh


scriptname=$(basename $0)
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
natpierce_port=`nvram get natpierce_port`
natpierce=`nvram get natpierce_bin`
jyl_url=`nvram get natpierce_url`
[ -z "$jyl_url" ] && jyl_url="https://natpierce.oss-cn-beijing.aliyuncs.com/linux/natpierce-mipsel-v1.03.tar.gz"
jyl_conf="/etc/storage/jyl/config"
[ -z "$natpierce" ] && natpierce="/tmp/jyl/natpierce"
[ ! -d "/etc/storage/jyl" ] && mkdir -p /etc/storage/jyl
[ ! -d "/tmp/jyl" ] && mkdir -p /tmp/jyl
natpierce_enable=`nvram get natpierce_enable`
[ -z "$natpierce_enable" ] && natpierce_enable=0 && nvram set natpierce_enable=0

logg() {
  echo -e "\033[36;33m$(date +'%Y-%m-%d %H:%M:%S'):\033[0m\033[35;1m $1 \033[0m"
  echo "$(date +'%Y-%m-%d %H:%M:%S'): $1" >>/tmp/natpierce.log
  logger -t "【皎月连】" "$1"
}
natpierce_renum=`nvram get natpierce_renum`

jyl_restart () {
relock="/var/lock/natpierce_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set natpierce_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	natpierce_renum=${natpierce_renum:-"0"}
	natpierce_renum=`expr $natpierce_renum + 1`
	nvram setnatpierce_renum="$natpierce_renum"
	if [ "$natpierce_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logg "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get natpierce_renum)" = "0" ] && break
   			#[ "$(nvram get natpierce_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set natpierce_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
jyl_start
}

jyl_keep() {
	logg "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【皎月连】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof natpierce\`" ] && logger -t "进程守护" "皎月连 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【皎月连】|^$/d' /tmp/script/_opt_script_check #【皎月连】
 	[ -z "\$(iptables -L -n -v | grep 'natpierce')" ] && logger -t "进程守护" "皎月连 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【皎月连】|^$/d' /tmp/script/_opt_script_check #【皎月连】
	OSC

	fi

}

jyl_start () {
  [ "$natpierce_enable" != "1" ] && exit 1
  logg "开始启动"
  sed -Ei '/【皎月连】|^$/d' /tmp/script/_opt_script_check
  [ -z "`pidof natpierce`" ] || kill -9 $(pidof natpierce) >/dev/null 2>&1
  path=$(dirname "$natpierce")
  if [ ! -f "$natpierce" ] ; then
  	logg "未找到 $natpierce 开始在线下载 $jyl_url"
   	bin_path=$(dirname "$natpierce")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
  	curl -Lko "/tmp/natpierce.tar.gz" "$jyl_url" || wget --no-check-certificate -O "/tmp/natpierce.tar.gz" "$jyl_url"
  	if [ "$?" = 0 ] ; then
  		router_size="$(check_disk_size $path)"
  		tar -xzf /tmp/natpierce.tar.gz -C /tmp/jyl
  		jyl_size="$(du -k /tmp/jyl/natpierce | awk '{print int($1 / 1024)}')"
  		logg "${path} 目录可用剩余${router_size}M 程序大小 ${jyl_size}M ,注意可用空间足够，若安装失败请修改路径为内存/tmp/jyl/natpierce"
		chmod +x /tmp/jyl/natpierce
		logg "下载成功"
		cp -rf /tmp/jyl/natpierce "$natpierce"
		break
	else
		logg "下载失败，请手动下载 $jyl_url 解压上传到  $natpierce"
   	fi
  fi
  [ ! -x "$natpierce" ] && chmod +x "$natpierce"
  if [ ! -f "$natpierce" ] ; then
  	logg "下载失败 无法启动请检查"
  fi
  CMD=""
  [ -z "$natpierce_port" ] || CMD="-p $natpierce_port"
  if [ ! -f "$jyl_conf" ] || [ ! -s "$jyl_conf" ] ; then
  	rm -f $jyl_conf
  	logg "未发现配置文件，新安装设备，开始生成配置文件..."
  	eval "${natpierce} ${CMD} >>/tmp/natpierce.log 2>&1" &
  	sleep 4
  	
  	[ -z "`pidof natpierce`" ] || kill -9 $(pidof natpierce) >/dev/null 2>&1
  	if [ ! -f "${path}/config" ] || [ ! -s "${path}/config" ] ; then
  		logg "生成失败"
  	else
  		logg "生成成功！保存到闪存 $jyl_conf"
  		cp -f ${path}/config $jyl_conf
  	fi
  fi
  if [ -f "$jyl_conf" ] && [ -s "$jyl_conf" ] ; then
  	ln -sf "$jyl_conf" "${path}/config"
  fi
  logg "运行 ${natpierce} ${CMD}"
  [ -z "`pidof natpierce`" ] || kill -9 $(pidof natpierce) >/dev/null 2>&1
  eval "${natpierce} ${CMD} >>/tmp/natpierce.log 2>&1" &
  sleep 6
  if [ ! -z "`pidof natpierce`" ] ; then
  	lan_ip=`nvram get lan_ipaddr`
  	if [ -z "$natpierce_port" ] ; then
  		web_port="33272"
  	else
  		web_port="$natpierce_port"
  	fi
   	mem=$(cat /proc/$(pidof natpierce)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   	cpui="$(top -b -n1 | grep -E "$(pidof natpierce)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /natpierce/) break; else cpu=i}} END {print $cpu}')"
  	logg "启动成功" 
   	logg "内存占用 ${mem} CPU占用 ${cpui}%"
   	jyl_restart o
  	nvram set natpierce_login="http://${lan_ip}:${web_port}"
  	iptables -I INPUT -i natpierce -j ACCEPT
	iptables -I FORWARD -i natpierce -o natpierce -j ACCEPT
	iptables -I FORWARD -i natpierce -j ACCEPT
	iptables -t nat -I POSTROUTING -o natpierce -j MASQUERADE
  	jyl_keep
  fi
  [ -z "`pidof natpierce`" ] && logg "启动失败,10 秒后自动尝试重新启动" && sleep 10 && jyl_restart x
  exit 0
}

jyl_close () {
  logg "关闭皎月连..."
  sed -Ei '/【皎月连】|^$/d' /tmp/script/_opt_script_check
  scriptname=$(basename $0)
  [ -z "`pidof natpierce`" ] || kill -9 $(pidof natpierce) >/dev/null 2>&1
  iptables -D INPUT -i natpierce -j ACCEPT 2>/dev/null
  iptables -D FORWARD -i natpierce -o natpierce -j ACCEPT 2>/dev/null
  iptables -D FORWARD -i natpierce -j ACCEPT 2>/dev/null
  iptables -t nat -D POSTROUTING -o natpierce -j MASQUERADE 2>/dev/null
  sleep 4
  [ -z "`pidof natpierce`" ] && logg "进程已关闭!" && nvram set natpierce_login=""
  if [ ! -z "$scriptname" ] ; then
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
  fi
}

case $1 in
start)
	jyl_start &
	;;
restart)
	jyl_start &
	;;
stop)
	jyl_close
	;;
*)
	jyl_start &
	;;
esac

