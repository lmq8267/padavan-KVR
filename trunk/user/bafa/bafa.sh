#!/bin/sh

bafa_enable=$(nvram get bafa_enable)
bafa_topics="$(nvram get bafa_topics)"
bafa_token="$(nvram get bafa_token)"
bafa_qos="$(nvram get bafa_qos)"
bafa_host="$(nvram get bafa_host)"
bafa_port="$(nvram get bafa_port)"
bafa_show="$(nvram get bafa_show)"
bafa_bin="$(nvram get bafa_bin)"
bafa_renum=`nvram get bafa_renum`
if [ ! -z "$bafa_bin" ] ; then
	binname=$(basename $bafa_bin)
else
	binname="stdoutsubc"
fi

logg() {
  echo -e "\033[36;33m$(date +'%Y-%m-%d %H:%M:%S'):\033[0m\033[35;1m $1 \033[0m"
  echo "$(date +'%Y-%m-%d %H:%M:%S'): $1" >>/tmp/bafayun.log
  logger -t "【巴法云物联网】" "$1"
}

bafa_restart () {
relock="/var/lock/bafa_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set bafa_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	bafa_renum=${bafa_renum:-"0"}
	bafa_renum=`expr $bafa_renum + 1`
	nvram set bafa_renum="$bafa_renum"
	if [ "$bafa_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logg "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get bafa_renum)" = "0" ] && break
   			#[ "$(nvram get bafa_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set bafa_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
start_bafa
}

scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
bafa_keep() {
	logg "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【巴法云物联网】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof ${binname}\`" ] && logger -t "进程守护" "巴法云进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【巴法云物联网】|^$/d' /tmp/script/_opt_script_check #【巴法云物联网】
 	[ -s /tmp/bafayun.log ] && [ "\$(stat -c %s /tmp/bafayun.log)" -gt 1194304 ] && echo "" > /tmp/bafayun.log & #【巴法云物联网】
	OSC
	fi

}


start_bafa() {
	[ "$bafa_enable" = "0" ] && exit 1
	logg "正在启动$bafa_bin"
 	if [ -f "$bafa_bin" ] ; then
		[ ! -x "$bafa_bin" ] && chmod +x $bafa_bin
  		[[ "$($bafa_bin -h 2>&1 | wc -l)" -lt 2 ]] && logg "程序${binname}不完整！" && rm -rf $bafa_bin
  	fi
 	if [ ! -f "$bafa_bin" ] ; then
		logg "程序${binname}不存在，请下载上传后重试！"
  		exit 1
  	fi
	sed -Ei '/【巴法云物联网】|^$/d' /tmp/script/_opt_script_check
	killall $binname >/dev/null 2>&1
	CMD=""
	if [ -z "$bafa_topics" ] ; then
		logg "主题为空，无法运行，退出！"
		exit 1
	else
		CMD="$bafa_topics"
	fi
	if [ -z "$bafa_token" ] ; then
		logg "私钥为空，无法运行，退出！"
		exit 1
	else
		CMD="${CMD} --clientid $bafa_token"
	fi
	[ -z "$bafa_qos" ] || CMD="${CMD} --qos $bafa_qos"
	[ -z "$bafa_host" ] || CMD="${CMD} --host $bafa_host"
	[ -z "$bafa_port" ] || CMD="${CMD} --port $bafa_port"
	[ "$bafa_show" = "1" ] && CMD="${CMD} --showtopics on"
	bafa_script="/etc/storage/bafa_script.sh"
	if [ ! -f "$bafa_script" ] || [ ! -s "$bafa_script" ] ; then
	cat > "$bafa_script" <<-\EEE
#!/bin/bash
# 此脚本路径：/etc/storage/bafa_script.sh
# 巴法云消息执行脚本
bafa_token="$(nvram get bafa_token)"
bafa_show="$(nvram get bafa_show)"
if [ "$bafa_show" = "1" ] ; then
	#如果开启主题显示那么$1是主题名 $2才是内容 
	title=$(echo $1 | tr ' \n')
	content=$(echo $2 | tr ' \n')
else
	#没有开启主题显示那么$1就是内容 
	content=$(echo $1 | tr ' \n')
fi
logger -t "【巴法云物联网】" "收到指令：${title} ${content}"
###############################################
#将指令推送到微信 方便查看路由是否收到，不需要删掉这里面的代码  
send=$(curl "http://apis.bemfa.com/vb/wechat/v1/wechatWarn?uid=$bafa_token&device=$1&message=$2")
if [ "$(echo $send | grep -o 'success')" = "success" ] ; then
	echo "微信推送成功！【${title}】${content}"
else
	logger -t "【巴法云物联网】" "微信推送失败！状态码：${send}"
fi
##############################################
#现在你可以进行判断主题title 内容content 执行什么命令

EEE
	chmod 755 "$bafa_script"
fi
	bafacmd="${bafa_bin} ${CMD} --script /etc/storage/bafa_script.sh >/tmp/bafayun.log 2>&1"
	logg "运行${bafacmd}"
	eval "$bafacmd" &
	sleep 4
	if [ ! -z "`pidof ${binname}`" ] ; then
 		logg "运行成功！"
  		bafa_restart o
  		bafa_keep
	else
		logg "运行失败, 注意检查${bafa_bin}是否下载完整,10 秒后自动尝试重新启动"
  		sleep 10
  		bafa_restart x
	fi
	return 0
}


stop_bafa() {
	logg  "正在关闭..."
	sed -Ei '/【巴法云物联网】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	killall $binname >/dev/null 2>&1
	[ -z "`pidof ${binname}`" ] && logg "进程已关闭!"
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
}


case $1 in
start)
	start_bafa &
	;;
stop)
	stop_bafa
	;;
restart)
	stop_bafa
	start_bafa &
	;;
*)
	echo "check"
	#exit 0
	;;
esac
