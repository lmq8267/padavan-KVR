#!/bin/sh
# stackia/rtp2httpd 启动脚本，复用 msd_lite/udpxy 的端口与 IPTV 页面
# 源码：https://github.com/stackia/rtp2httpd  (GPL-2.0)
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'

rtp2httpd_enable="$(nvram get rtp2httpd_enable)"
rtp2httpd_dl="$(nvram get rtp2httpd_dl)"
rtp2httpd_workers="$(nvram get rtp2httpd_workers)"
rtp2httpd_port="$(nvram get udpxy_enable_x)"
rtp2httpd_conf="/etc/storage/rtp2httpd.conf"
rtp2httpd_dir="/tmp/rtp2httpd"
rtp2httpd_bin="$rtp2httpd_dir/rtp2httpd"
rtp2httpd_builtin="/usr/bin/rtp2httpd"
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

[ -z "$rtp2httpd_dl" ] && rtp2httpd_dl=1
[ -z "$rtp2httpd_workers" ] && rtp2httpd_workers=1 && nvram set rtp2httpd_workers=1
[ -z "$rtp2httpd_port" ] && rtp2httpd_port=5140
# 与 msd_lite 保持一致：端口小于 1024 视为未配置，直接退出，避免占用随机端口
if [ "$rtp2httpd_port" -lt 1024 ] 2>/dev/null ; then
	logger -t "【rtp2httpd】" "端口 ${rtp2httpd_port} 无效，请设置 1024~65535"
	exit 1
fi

rtp2httpd_get_tag() {
	curltest="$(which curl)"
	if [ -z "$curltest" ] || [ ! -s "$(which curl)" ] ; then
		tag="$(wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=- https://api.github.com/repos/stackia/rtp2httpd/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4)"
		[ -z "$tag" ] && tag="$(wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- https://api.github.com/repos/stackia/rtp2httpd/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4)"
	else
		tag="$(curl -k --connect-timeout 3 --user-agent "$user_agent" https://api.github.com/repos/stackia/rtp2httpd/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4)"
		[ -z "$tag" ] && tag="$(curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s https://api.github.com/repos/stackia/rtp2httpd/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4)"
	fi
	[ -z "$tag" ] && logger -t "【rtp2httpd】" "无法获取最新版本，使用 v3.17.2" && tag="v3.17.2"
	nvram set rtp2httpd_ver_n="$tag"
}

rtp2httpd_version() {
	"$1" --help 2>/dev/null | awk '/^Version/{print $2; exit}'
}

rtp2httpd_download() {
	rtp2httpd_get_tag
	newver="${tag#v}"
	url="https://github.com/stackia/rtp2httpd/releases/download/${tag}/rtp2httpd-${newver}-mipsel"
	logger -t "【rtp2httpd】" "开始下载 ${url}"
	mkdir -p "$rtp2httpd_dir"
	for proxy in $github_proxys ; do
		rm -f "$rtp2httpd_dir/rtp2httpd.new"
		curl -Lko "$rtp2httpd_dir/rtp2httpd.new" --connect-timeout 10 --retry 2 "${proxy}${url}" || \
			wget --no-check-certificate -O "$rtp2httpd_dir/rtp2httpd.new" "${proxy}${url}"
		if [ -s "$rtp2httpd_dir/rtp2httpd.new" ] ; then
			chmod +x "$rtp2httpd_dir/rtp2httpd.new"
			if [ -n "$(rtp2httpd_version "$rtp2httpd_dir/rtp2httpd.new")" ] ; then
				mv -f "$rtp2httpd_dir/rtp2httpd.new" "$rtp2httpd_bin"
				logger -t "【rtp2httpd】" "下载成功 $(rtp2httpd_version "$rtp2httpd_bin")"
				return 0
			fi
		fi
		logger -t "【rtp2httpd】" "下载失败或文件不完整 ${proxy}${url}"
	done
	rm -f "$rtp2httpd_dir/rtp2httpd.new"
	return 1
}

rtp2httpd_stop() {
	# 停止时同步清除守护规则，避免服务关闭后又被守护进程拉起
	sed -Ei '/【rtp2httpd】|^$/d' /tmp/script/_opt_script_check 2>/dev/null
	killall rtp2httpd >/dev/null 2>&1
	sleep 1
	killall -9 rtp2httpd >/dev/null 2>&1
}

rtp2httpd_keep() {
	logger -t "【rtp2httpd】" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ] ; then
	sed -Ei '/【rtp2httpd】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof rtp2httpd\`" ] && logger -t "进程守护" "rtp2httpd 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【rtp2httpd】|^$/d' /tmp/script/_opt_script_check #【rtp2httpd】
	OSC
	fi
}

rtp2httpd_start() {
	[ "$rtp2httpd_enable" = "1" ] || exit 1
	mkdir -p "$rtp2httpd_dir"
	if [ ! -f "$rtp2httpd_conf" ] ; then
		cp -f /etc_ro/rtp2httpd.conf "$rtp2httpd_conf"
		logger -t "【rtp2httpd】" "已创建默认配置 $rtp2httpd_conf"
	fi
	if [ "$rtp2httpd_dl" = "1" ] ; then
		rtp2httpd_get_tag
		cur_ver=""
		[ -x "$rtp2httpd_bin" ] && cur_ver="$(rtp2httpd_version "$rtp2httpd_bin")"
		if [ -z "$cur_ver" ] || [ "v$cur_ver" != "$tag" ] ; then
			rtp2httpd_download || logger -t "【rtp2httpd】" "在线下载失败，回退内置版本"
		fi
	fi
	bin="$rtp2httpd_builtin"
	if [ "$rtp2httpd_dl" = "1" ] && [ -x "$rtp2httpd_bin" ] ; then
		bin="$rtp2httpd_bin"
	fi
	[ ! -x "$bin" ] && logger -t "【rtp2httpd】" "找不到可执行程序 $bin" && exit 1
	cur_ver="$(rtp2httpd_version "$bin")"
	[ -n "$cur_ver" ] && nvram set rtp2httpd_ver="$cur_ver"
	nvram set msd_lite_enable="0"
	rtp2httpd_stop
	logger -t "【rtp2httpd】" "启动 $bin -c $rtp2httpd_conf -l 0.0.0.0:$rtp2httpd_port -w $rtp2httpd_workers"
	# 守护进程触发的重启不带接口参数，此时按系统默认路由选择上游
	rtp_args=""
	[ -n "$1" ] && rtp_args="-i $1 -r $1"
	"$bin" -c "$rtp2httpd_conf" -l "0.0.0.0:$rtp2httpd_port" $rtp_args -w "$rtp2httpd_workers" >/tmp/rtp2httpd.log 2>&1 &
	sleep 3
	if [ -n "$(pidof rtp2httpd)" ] ; then
		logger -t "【rtp2httpd】" "启动成功，版本 ${cur_ver:-未知}"
	else
		logger -t "【rtp2httpd】" "启动失败，请查看 /tmp/rtp2httpd.log"
	fi
	rtp2httpd_keep
}

case "$1" in
start)
	rtp2httpd_start "$2" &
	;;
stop)
	rtp2httpd_stop
	;;
update)
	rtp2httpd_get_tag
	rm -f "$rtp2httpd_bin"
	rtp2httpd_download && logger -t "【rtp2httpd】" "更新完成，请重启服务"
	;;
*)
	echo "check"
	;;
esac
