#!/bin/sh

scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
# /etc/storage 空间很小且是唯一的固化分区，程序放内存，配置只放 /etc/storage/adg.sh
ADG_DIR="/tmp/AdGuardHome"
ADG_WORK_DIR="$ADG_DIR/data"
ADG_DL_PERMANENT=0
change_dns() {
if [ "$(nvram get adg_redirect)" = 1 ]; then
  conf="/etc/storage/dnsmasq/dnsmasq.conf"
  [ ! -f "$conf" ] && return 0
  sed -i '/^server=127.0.0.1#5335$/d' "$conf"
  if ! grep -q '^no-resolv' "$conf" ; then
    echo "no-resolv" >> "$conf"
    touch /etc/storage/adg_dns_no_resolv
  fi
  echo "server=127.0.0.1#5335" >> "$conf"
  /sbin/restart_dhcpd
  logger -t "【AdGuardHome】" "添加DNS转发到5335端口"
fi
}

del_dns() {
  conf="/etc/storage/dnsmasq/dnsmasq.conf"
  [ ! -f "$conf" ] && return 0
  sed -i '/^server=127.0.0.1#5335$/d' "$conf"
  if [ -f /etc/storage/adg_dns_no_resolv ] ; then
    sed -i '/^no-resolv$/d' "$conf"
    rm -f /etc/storage/adg_dns_no_resolv
  fi
  /sbin/restart_dhcpd
}

set_iptable() {
    if [ "$(nvram get adg_redirect)" = 2 ]; then
  IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
  for IP in $IPS
  do
    iptables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
    iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
  done

  IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
  for IP in $IPS
  do
    ip6tables -t nat -A PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
    ip6tables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
  done
    logger -t "【AdGuardHome】" "重定向53端口"
    fi
}

clear_iptable() {
  OLD_PORT="5335"
  IPS="`ifconfig | grep "inet addr" | grep -v ":127" | grep "Bcast" | awk '{print $2}' | awk -F : '{print $2}'`"
  for IP in $IPS
  do
    iptables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
    iptables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
  done

  IPS="`ifconfig | grep "inet6 addr" | grep -v " fe80::" | grep -v " ::1" | grep "Global" | awk '{print $3}'`"
  for IP in $IPS
  do
    ip6tables -t nat -D PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
    ip6tables -t nat -D PREROUTING -p tcp -d $IP --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
  done

}

getconfig() {
adg_file="/etc/storage/adg.sh"
if [ ! -f "$adg_file" ] || [ ! -s "$adg_file" ] ; then
  cat > "$adg_file" <<-\EEE
# 默认账号 admin / admin，首次登录后请在 AdGuardHome 网页里修改密码
schema_version: 34
http:
  address: 0.0.0.0:3030
users:
  - name: admin
    password: $2a$10$SOZ9rtSF.CaPkhadSAVVv.mXSsyjVsubj53vY7idbJHV.2vDruThG
language: zh-cn
dns:
  bind_hosts:
    - 0.0.0.0
  port: 5335
  ratelimit: 0
  upstream_dns:
    - tcp://1.0.0.1
  bootstrap_dns:
    - tcp://1.0.0.1
  upstream_mode: parallel
tls:
  enabled: false

EEE
  chmod 600 "$adg_file"
fi
}
adg_renum=`nvram get adg_renum`

adg_restart () {
relock="/var/lock/AdGuardHome_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set adg_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	adg_renum=${adg_renum:-"0"}
	adg_renum=`expr $adg_renum + 1`
	nvram set adg_renum="$adg_renum"
	if [ "$adg_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【AdGuardHome】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get adg_renum)" = "0" ] && break
   			#[ "$(nvram get adg_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set adg_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
# 后台重新启动，避免失败重试时递归调用 start_adg 叠加调用栈
start_adg &
}

find_bin() {
SVC_PATH="$(nvram get adg_bin)"

dirs="/etc/storage/bin
/tmp/AdGuardHome
/usr/bin"

if [ -z "$SVC_PATH" ] ; then
  for dir in $dirs ; do
    if [ -f "$dir/AdGuardHome" ] ; then
        SVC_PATH="$dir/AdGuardHome"
        [ ! -x "$SVC_PATH" ] && chmod +x $SVC_PATH
        break
    fi
  done
  [ -z "$SVC_PATH" ] && SVC_PATH="$ADG_DIR/AdGuardHome"
fi
}

get_tag() {
	user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'

	curltest=`which curl`
	logger -t "【AdGuardHome】" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "【AdGuardHome】" "无法获取最新版本" && tag="v0.107.80"

}
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "

dl_adg() {
	find_bin
	if [ ! -f "$SVC_PATH" ] ; then
		ADG_DL_PERMANENT=0
		logger -t "【AdGuardHome】" "找不到 $SVC_PATH ，下载 AdGuardHome 程序"
		get_tag
		adg_path=$(dirname "$SVC_PATH")
		mkdir -p "$adg_path"
		logger -t "【AdGuardHome】" "下载${tag}版本 下载较慢，耐心等待"
		for proxy in $github_proxys ; do
			length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/AdguardTeam/AdGuardHome/releases/download/${tag}/AdGuardHome_linux_mipsle_softfloat.tar.gz" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
			length=`expr ${length:-0} + 512000`
			length=`expr $length / 1048576`
			need=$((length * 4 + 10))
			[ "$need" -lt 55 ] && need=55
			adg_size0="$(check_disk_size $adg_path)"
			[ -n "$adg_size0" ] && logger -t "【AdGuardHome】" "程序大小 ${length}M， 程序路径可用空间 ${adg_size0}M "
			if [ -n "$adg_size0" ] && [ "$adg_size0" -lt "$need" ] ; then
				ADG_DL_PERMANENT=1
				logger -t "【AdGuardHome】" "空间不足，至少需要 ${need}M，跳过 ${proxy}"
				continue
			fi
			rm -f /tmp/AdGuardHome.tar.gz
			curl -Lkso "/tmp/AdGuardHome.tar.gz" "${proxy}https://github.com/AdguardTeam/AdGuardHome/releases/download/${tag}/AdGuardHome_linux_mipsle_softfloat.tar.gz" || wget --no-check-certificate -q -O "/tmp/AdGuardHome.tar.gz" "${proxy}https://github.com/AdguardTeam/AdGuardHome/releases/download/${tag}/AdGuardHome_linux_mipsle_softfloat.tar.gz"
			if [ "$?" = 0 ] ; then
				rm -rf /tmp/AdGuardHome_extract
				mkdir -p /tmp/AdGuardHome_extract
				tar -xzf /tmp/AdGuardHome.tar.gz -C /tmp/AdGuardHome_extract
				rm -f /tmp/AdGuardHome.tar.gz
				adg_newbin="$(find /tmp/AdGuardHome_extract -type f -name AdGuardHome | head -n 1)"
				if [ -n "$adg_newbin" ] && [ -f "$adg_newbin" ] ; then
					[ -d "$SVC_PATH" ] && rm -rf "$SVC_PATH"
					mv -f "$adg_newbin" "$SVC_PATH" 2>/dev/null || cp -f "$adg_newbin" "$SVC_PATH"
					chmod +x "$SVC_PATH"
				fi
				rm -rf /tmp/AdGuardHome_extract
				if [ -f "$SVC_PATH" ] && [[ "$($SVC_PATH -h 2>&1 | wc -l)" -gt 3 ]] ; then
					logger -t "【AdGuardHome】" "$SVC_PATH 下载成功"
					break
				else
					logger -t "【AdGuardHome】" "下载不完整"
					rm -f "$SVC_PATH"
				fi
			else
				rm -f /tmp/AdGuardHome.tar.gz
				logger -t "【AdGuardHome】" "下载失败，请手动下载 ${proxy}https://github.com/AdguardTeam/AdGuardHome/releases/download/${tag}/AdGuardHome_linux_mipsle_softfloat.tar.gz 解压后把 AdGuardHome 放到 $SVC_PATH"
			fi
		done
	fi
}

adg_keep() {
	logger -t "【AdGuardHome】" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【AdGuardHome】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof AdGuardHome\`" ] && logger -t "进程守护" "AdGuardHome 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【AdGuardHome】|^$/d' /tmp/script/_opt_script_check #【AdGuardHome】
	OSC

	fi

}

start_adg() {
  mkdir -p "$ADG_DIR" "$ADG_WORK_DIR"
  logger -t "【AdGuardHome】" "正在启动..."
  sed -Ei '/【AdGuardHome】|^$/d' /tmp/script/_opt_script_check
  find_bin
  [ ! -x "$SVC_PATH" ] && chmod +x "$SVC_PATH"
  [[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 3 ]] && rm -rf "$SVC_PATH"
  if [ ! -f "$SVC_PATH" ] || [[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 3 ]] ; then
  dl_adg
  fi
  if [ ! -f "$SVC_PATH" ] || [[ "$($SVC_PATH -h 2>&1 | wc -l)" -lt 3 ]] ; then
    del_dns
    clear_iptable
    if [ "$ADG_DL_PERMANENT" = "1" ] ; then
      logger -t "【AdGuardHome】" "空间不足，停止启动"
      return 1
    fi
    logger -t "【AdGuardHome】" "程序下载失败，10 秒后重试"
    sleep 10
    adg_restart x
    return 0
  fi
  adgenable=$(nvram get adg_enable)
  if [ "$adgenable" = "1" ] ;then
  if [ -n "`pidof AdGuardHome`" ] ; then
    logger -t "【AdGuardHome】" "已经在运行，跳过重复启动"
    adg_keep
    return 0
  fi
  getconfig
  [ -f "$adg_file" ] && chmod 600 "$adg_file"
  clear_iptable
  change_dns
  set_iptable
  logger -t "【AdGuardHome】" "运行 $SVC_PATH"
  [ ! -x "$SVC_PATH" ] && chmod +x "$SVC_PATH"
  eval "$SVC_PATH -c $adg_file -w $ADG_WORK_DIR -v" &
  i=0
  while [ $i -lt 15 ]; do
    [ -n "`pidof AdGuardHome`" ] && break
    sleep 1
    i=$((i+1))
  done
  	if [ ! -z "`pidof AdGuardHome`" ] ; then
 		mem=$(cat /proc/$(pidof AdGuardHome)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   		cpui="$(top -b -n1 | grep -E "$(pidof AdGuardHome)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /AdGuardHome/) break; else cpu=i}} END {print $cpu}')"
		logger -t "【AdGuardHome】" "运行成功！"
  		logger -t "【AdGuardHome】" "内存占用 ${mem} CPU占用 ${cpui}%"
  		adg_ver="$($SVC_PATH --version 2>/dev/null | sed -n 's/.*version[[:space:]]*//p' | head -n 1)"
  		[ -n "$adg_ver" ] && [ "$(nvram get adg_ver)" != "$adg_ver" ] && nvram set adg_ver="$adg_ver"
  		adg_restart o
	else
		logger -t "【AdGuardHome】" "运行失败, 注意检查 $SVC_PATH 是否下载完整,10 秒后自动尝试重新启动"
  		sleep 10
  		adg_restart x
	fi
 adg_keep
  fi
  
}

stop_adg() {
scriptname=$(basename $0)
sed -Ei '/【AdGuardHome】|^$/d' /tmp/script/_opt_script_check
killall AdGuardHome 2>/dev/null
sleep 1
killall -9 AdGuardHome 2>/dev/null
# 只清理运行数据，保留 /tmp 里的二进制，停止/启动服务时不用重新下载
rm -rf "$ADG_WORK_DIR"
del_dns
clear_iptable
logger -t "【AdGuardHome】" "关闭AdGuardHome"
if [ ! -z "$scriptname" ] ; then
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
fi
}

case $1 in
start)
  start_adg &
  ;;
stop)
  stop_adg
  ;;
*)
  echo "check"
  ;;
esac
