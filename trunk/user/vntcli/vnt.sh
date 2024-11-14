#!/bin/sh

VNTS="$(nvram get vnts_bin)"
VNTCLI="$(nvram get vntcli_bin)"
[ -z "$VNTS" ] && VNTS=/etc/storage/bin/vnts && nvram set vnts_bin=$VNTS
[ -z "$VNTCLI" ] && VNTCLI=/etc/storage/bin/vnt-cli && nvram set vntcli_bin=$VNTCLI
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "


get_vntclitag() {
	curltest=`which curl`
	logger -t "VNT客户端" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		clitag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$clitag" ] && clitag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		clitag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$clitag" ] && clitag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/vnt-cli/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$clitag" ] && logger -t "VNT客户端" "无法获取最新版本" && nvram set vntcli_ver_n="" 
	nvram set vntcli_ver_n=$clitag
	if [ -f "$VNTCLI" ] ; then
		chmod +x $VNTCLI
		vntcli_ver=$($VNTCLI -h | grep 'version:' | awk -F 'version:' '{print $2}' | tr -d ' \n')
		[ -z "$vntcli_ver" ] && nvram set vntcli_ver=""
		nvram set vntcli_ver="v${vntcli_ver}"
	fi
}

get_vntstag() {
	curltest=`which curl`
	logger -t "VNT服务端" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		stag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/lmq8267/vnts/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && stag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/vnts/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		stag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/vnts/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && stag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/vnts/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$stag" ] && logger -t "VNT服务端" "无法获取最新版本" && nvram set vnts_ver_n="" 
	nvram set vnts_ver_n=$stag
	if [ -f "$VNTS" ] ; then
		chmod +x $VNTS
		vnts_ver=$($VNTS --version | awk -F 'version:' '{print $2}' | tr -d ' \n')
		[ -z "$vnts_ver" ] && nvram set vnts_ver=""
		nvram set vnts_ver="v${vnts_ver}"
	fi
}

dowload_vntcli() {
	clitag="$1"
	logger -t "VNT客户端" "开始下载 https://github.com/lmq8267/vnt-cli/releases/download/${clitag}/vnt-cli_mipsel-unknown-linux-musl 到 $VNTCLI"
	for proxy in $github_proxys ; do
       curl -Lkso "$VNTCLI" "${proxy}https://github.com/lmq8267/vnt-cli/releases/download/${clitag}/vnt-cli_mipsel-unknown-linux-musl" || wget --no-check-certificate -q -O "$VNTCLI" "${proxy}https://github.com/lmq8267/vnt-cli/releases/download/${clitag}/vnt-cli_mipsel-unknown-linux-musl"
	if [ "$?" = 0 ] ; then
		chmod +x $VNTCLI
		if [ $(($($VNTCLI -h | wc -l))) -gt 3 ] ; then
			logger -t "VNT客户端" "$VNTCLI 下载成功"
       	else
	   		logger -t "VNT客户端" "下载失败，请手动下载 https://github.com/lmq8267/vnt-cli/releases/download/${clitag}/vnt-cli_mipsel-unknown-linux-musl 上传到  $VNTCLI"
			exit 1
	  	fi
	else
		logger -t "VNT客户端" "下载失败，请手动下载 https://github.com/lmq8267/vnt-cli/releases/download/${clitag}/vnt-cli_mipsel-unknown-linux-musl 上传到  $VNTCLI"
		exit 1
   	fi
	done
}

dowload_vnts() {
	stag="$1"
	logger -t "VNT服务端" "开始下载 https://github.com/lmq8267/vnts/releases/download/${stag}/vnts_mipsel-unknown-linux-musl 到 $VNTS"
	for proxy in $github_proxys ; do
       curl -Lkso "$VNTCLI" "${proxy}https://github.com/lmq8267/vnts/releases/download/${stag}/vnts_mipsel-unknown-linux-musl" || wget --no-check-certificate -q -O "$VNTCLI" "${proxy}https://github.com/lmq8267/vnts/releases/download/${stag}/vnts_mipsel-unknown-linux-musl"
	if [ "$?" = 0 ] ; then
		chmod +x $VNTCLI
		if [ $(($($VNTCLI -h | wc -l))) -gt 3 ] ; then
			logger -t "VNT服务端" "$VNTS 下载成功"
       	else
	   		logger -t "VNT服务端" "下载失败，请手动下载 https://github.com/lmq8267/vnts/releases/download/${stag}/vnts_mipsel-unknown-linux-musl 上传到  $VNTS"
			exit 1
	  	fi
	else
		logger -t "VNT服务端" "下载失败，请手动下载 https://github.com/lmq8267/vnts/releases/download/${stag}/vnts_mipsel-unknown-linux-musl 上传到  $VNTS"
		exit 1
   	fi
	done
}

update_vntcli() {
	get_vntclitag
	[ -z "$clitag" ] && logger -t "VNT客户端" "无法获取最新版本" && nvram set vntcli_ver_n="" && exit 1
	clitag=$(echo $clitag | tr -d 'v \n')
	if [ ! -z "$clitag" ] && [ ! -z "$vntcli_ver" ] ; then
		if [ "$clitag"x != "$vntcli_ver"x ] ; then
			logger -t "VNT客户端" "当前版本${vntcli_ver} 最新版本${clitag}"
			dowload_vntcli $tag
		else
			logger -t "VNT客户端" "当前已是最新版本 ${clitag} 无需更新！"
		fi
	fi
	exit 0
}

update_vnts() {
	get_vntstag
	[ -z "$stag" ] && logger -t "VNT服务端" "无法获取最新版本" && nvram set vnts_ver_n="" && exit 1
	stag=$(echo $stag | tr -d 'v \n')
	if [ ! -z "$stag" ] && [ ! -z "$vnts_ver" ] ; then
		if [ "$stag"x != "$vnts_ver"x ] ; then
			logger -t "VNT服务端" "当前版本${vnts_ver} 最新版本${stag}"
			dowload_vntcli $tag
		else
			logger -t "VNT服务端" "当前已是最新版本 ${stag} 无需更新！"
		fi
	fi
	exit 0
}

start_vntcli() {
	vntcli_enable=$(nvram get vntcli_enable)
	[ "$vntcli_enable" = "1" ] || exit 1
	logger -t "VNT客户端" "正在启动vnt-cli"
	get_vntclitag
 	if [ ! -f "$VNTCLI" ] ; then
		logger -t "VNT客户端" "主程序${VNTCLI}不存在，开始在线下载..."
  		[ ! -d /etc/storage/bin ] && mkdir -p /etc/storage/bin
  		[ -z "$clitag" ] && clitag="1.2.15"
  		dowload_vntcli $clitag
  	fi
  	[ ! -f "$VNTCLI" ] && exit 1
	kill_cf
	chmod +x $VNTCLI
	[ $(($($VNTCLI -h | wc -l))) -gt 3 ] && logger -t "VNT客户端" "程序${VNTCLI}不完整，无法运行！" && exit 1
	vntclicmd="${VNTCLI} ${CMD}"
	logger -t "VNT客户端" "运行${vntclicmd}"
	eval "$vntclicmd" &
	sleep 4
	if [ ! -z "`pidof vnt-cli`" ] ; then
		logger -t "VNT客户端" "运行成功！"
	else
		logger -t "VNT客户端" "运行失败！"
	fi
	exit 0
}

start_vnts() {
	vnts_enable=$(nvram get vnts_enable)
	[ "$vnts_enable" = "1" ] || exit 1
	logger -t "VNT服务端" "正在启动vnts"
	get_vntstag
 	if [ ! -f "$VNTS" ] ; then
		logger -t "VNT服务端" "主程序${VNTS}不存在，开始在线下载..."
  		[ ! -d /etc/storage/bin ] && mkdir -p /etc/storage/bin
  		[ -z "$stag" ] && clitag="1.2.13"
  		dowload_vnts $stag
  	fi
  	[ ! -f "$VNTS" ] && exit 1
	kill_cf
	chmod +x $VNTS
	[ $(($($VNTS -h | wc -l))) -gt 3 ] && logger -t "VNT服务端" "程序${VNTS}不完整，无法运行！" && exit 1
	vntscmd="${VNTS} ${CMD}"
	logger -t "VNT服务端" "运行${vntscmd}"
	eval "$vntscmd" &
	sleep 4
	if [ ! -z "`pidof vnts`" ] ; then
		logger -t "VNT服务端" "运行成功！"
	else
		logger -t "VNT服务端" "运行失败！"
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
	kill_cf
	[ ! -z "`pidof cloudflared`" ] &&logger -t "cloudflared" "cloudflared关闭成功!"
}

case $1 in
start)
	start_cf
	;;
stop)
	stop_cf
	;;
update)
	update_cf
	;;
*)
	echo "check"
	#exit 0
	;;
esac
