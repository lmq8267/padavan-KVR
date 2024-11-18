#!/bin/sh

PROG="$(nvram get cloudflared_bin)"
[ -z "$PROG" ] && PROG=/tmp/cloudflared && nvram set cloudflared_bin=$PROG
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
CMD="$(nvram get cloudflared_cmd)"
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)

get_cftag() {
	curltest=`which curl`
	logger -t "cloudflared" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/lmq8267/cloudflared/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/cloudflared/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/cloudflared/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/cloudflared/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "cloudflared" "无法获取最新版本"
	nvram set cloudflared_ver_n=$tag
	if [ -f "$PROG" ] ; then
		chmod +x $PROG
		cf_ver=$($PROG --version |  awk '{print $3}' | sed -n '1p')
		if [ -z "$cf_ver" ] ; then
			nvram set cloudflared_ver=""
		else
			nvram set cloudflared_ver=$cf_ver
		fi
	fi
}

dowload_cf() {
	tag="$1"
	logger -t "cloudflared" "开始下载 https://github.com/lmq8267/cloudflared/releases/download/${tag}/cloudflared 到 $PROG"
	for proxy in $github_proxys ; do
       curl -Lkso "$PROG" "${proxy}https://github.com/lmq8267/cloudflared/releases/download/${tag}/cloudflared" || wget --no-check-certificate -q -O "$PROG" "${proxy}https://github.com/lmq8267/cloudflared/releases/download/${tag}/cloudflared"
	if [ "$?" = 0 ] ; then
		chmod +x $PROG
		if [ $(($($PROG -h | wc -l))) -gt 3 ] ; then
			logger -t "cloudflared" "$PROG 下载成功"
			cf_ver=$($PROG --version |  awk '{print $3}' | sed -n '1p')
			if [ -z "$cf_ver" ] ; then
				nvram set cloudflared_ver=""
			else
				nvram set cloudflared_ver=$cf_ver
			fi
			break
       	else
	   		logger -t "cloudflared" "下载不完整，请手动下载 ${proxy}https://github.com/lmq8267/cloudflared/releases/download/${tag}/cloudflared 上传到  $PROG"
			rm -f $PROG
	  	fi
	else
		logger -t "cloudflared" "下载失败，请手动下载 ${proxy}https://github.com/lmq8267/cloudflared/releases/download/${tag}/cloudflared 上传到  $PROG"
   	fi
	done
}

update_cf() {
	get_cftag
	[ -z "$tag" ] && logger -t "cloudflared" "无法获取最新版本" && exit 1
	if [ ! -z "$tag" ] && [ ! -z "$cf_ver" ] ; then
		if [ "$tag"x != "$cf_ver"x ] ; then
			logger -t "cloudflared" "当前版本${cf_ver} 最新版本${tag}"
			dowload_cf $tag
		else
			logger -t "cloudflared" "当前已是最新版本 ${tag} 无需更新！"
		fi
	fi
	exit 0
}

cf_keep() {
	logger -t "cloudflared" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【cloudflared】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof cloudflared\`" ] && logger -t "进程守护" "cloudflared 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【cloudflared】|^$/d' /tmp/script/_opt_script_check #【cloudflared】
	OSC

	fi

}

start_cf() {
	cf_enable=$(nvram get cloudflared_enable)
	[ "$cf_enable" = "1" ] || exit 1
	logger -t "cloudflared" "正在启动cloudflared"
	sed -Ei '/【cloudflared】|^$/d' /tmp/script/_opt_script_check
	get_cftag
 	if [ ! -f "$PROG" ] ; then
		logger -t "cloudflared" "主程序${PROG}不存在，开始在线下载..."
  		[ ! -d /etc/storage/bin ] && mkdir -p /etc/storage/bin
  		[ -z "$tag" ] && tag="2024.11.0"
  		dowload_cf $tag
  	fi
  	[ ! -f "$PROG" ] && exit 1
	kill_cf
	chmod +x $PROG
	[ $(($($PROG -h | wc -l))) -gt 3 ] && logger -t "cloudflared" "程序${PROG}不完整，无法运行！" && exit 1
	cmd="${PROG} ${CMD}"
	logger -t "cloudflared" "运行${cmd}"
	eval "$cmd" &
	sleep 4
	if [ ! -z "`pidof cloudflared`" ] ; then
		logger -t "cloudflared" "运行成功！"
		cf_keep
	else
		logger -t "cloudflared" "运行失败！"
	fi
	exit 0
}
kill_cf() {
	cloudflared_process=$(pidof cloudflared)
	rm -rf /tmp/cloudflared.log
	if [ -n "$cloudflared_process" ]; then
		logger -t "cloudflared" "有进程 $cloudflared_proces 在运行，结束中..."
		killall cloudflared >/dev/null 2>&1
	fi
}
stop_cf() {
	logger -t "cloudflared" "正在关闭cloudflared..."
	sed -Ei '/【cloudflared】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	kill_cf
	[ ! -z "`pidof cloudflared`" ] && logger -t "cloudflared" "cloudflared关闭成功!"
}

case $1 in
start)
	start_cf &
	;;
stop)
	stop_cf
	;;
restart)
	stop_cf
	start_cf &
	;;
update)
	update_cf &
	;;
*)
	echo "check"
	#exit 0
	;;
esac
