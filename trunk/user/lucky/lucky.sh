#!/bin/sh

scriptname=$(basename $0)
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
lucky_enable=`nvram get lucky_enable`
lucky_daji=`nvram get lucky_daji`
lucky_cmd=`nvram get lucky_cmd`
PROG=`nvram get lucky_bin`
lucky_tag=`nvram get lucky_tag`
[ -z "$lucky_cmd" ] && lucky_cmd="/etc/storage/lucky"
[ -z "$lucky_enable" ] && lucky_enable=0 && nvram set lucky_enable=0
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
logg  () {
  echo -e "\033[36;33m$(date +'%Y-%m-%d %H:%M:%S'):\033[0m\033[35;1m $1 \033[0m"
  echo "$(date +'%Y-%m-%d %H:%M:%S')：$1" >>/tmp/lucky.log
  logger -t "【lucky】" "$1"
}
lucky_renum=`nvram get lucky_renum`

lucky_restart () {
relock="/var/lock/lucky_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set lucky_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	lucky_renum=${lucky_renum:-"0"}
	lucky_renum=`expr $lucky_renum + 1`
	nvram set lucky_renum="$lucky_renum"
	if [ "$lucky_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logg "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get lucky_renum)" = "0" ] && break
   			#[ "$(nvram get lucky_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set lucky_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
lucky_start
}

get_tag() {
	curltest=`which curl`
	logg "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/gdy666/lucky/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/gdy666/lucky/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/gdy666/lucky/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/gdy666/lucky/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logg "无法获取最新版本"
	nvram set lucky_ver_n=$tag
	
}

find_bin() {
dirs="/etc/storage/bin
/etc/storage/lucky
/tmp
/usr/bin"

PROG=""
for dir in $dirs ; do
    if [ -f "$dir/lucky" ] ; then
        PROG="$dir/lucky"
	nvram set lucky_bin="$PROG"
 	[ ! -x "$PROG" ] && chmod +x $PROG
        break
    fi
done
[ -z "$PROG" ] && PROG="/tmp/lucky" && nvram set lucky_bin="$PROG"
}

lucky_dl() {
	tag="$1"
	new_tag="$(echo $tag | tr -d 'v' | tr -d ' ')"
 	if [ "$lucky_daji" = "1" ] ; then
 		lk_url="https://6.66666.host:66/release/${tag}/${new_tag}_万吉/lucky_${new_tag}_Linux_mipsle_softfloat_wanji.tar.gz"
   		lk_url1="http://release.ilucky.net:66/release/${tag}/${new_tag}_wanji/lucky_${new_tag}_Linux_mipsle_softfloat_wanji.tar.gz"
   		lk_url2="https://6.666666.host:66/release/${tag}/${new_tag}_万吉/lucky_${new_tag}_Linux_mipsle_softfloat_wanji.tar.gz"
   	else
    		lk_url="https://6.66666.host:66/release/${tag}/${new_tag}_lucky/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz"
      		lk_url1="http://release.ilucky.net:66/release/${tag}/${new_tag}_lucky/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz"
      		lk_url2="https://6.666666.host:66/release/${tag}/${new_tag}_lucky/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz"
  	fi
	logg "开始下载 ${lk_url}"
 	bin_path=$(dirname "$PROG")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
	for proxy in $github_proxys ; do
 	length=$(wget --no-check-certificate -T 5 -t 3 "${lk_url}" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 	length=`expr $length + 512000`
	length=`expr $length / 1048576`
 	lucky_size0="$(check_disk_size $bin_path)"
 	[ ! -z "$length" ] && logg "程序大小 ${length}M， 程序路径可用空间 ${lucky_size0}M "
        curl -Lko "/tmp/lucky.tar.gz" "${lk_url}" || wget --no-check-certificate -O "/tmp/lucky.tar.gz" "${lk_url}" || curl -Lko "/tmp/lucky.tar.gz" "${lk_url1}" || wget --no-check-certificate -O "/tmp/lucky.tar.gz" "${lk_url1}" || curl -Lko "/tmp/lucky.tar.gz" "${lk_url2}" || wget --no-check-certificate -O "/tmp/lucky.tar.gz" "${lk_url2}" || curl -Lko "/tmp/lucky.tar.gz" "${proxy}https://github.com/gdy666/lucky/releases/download/${tag}/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz" || wget --no-check-certificate -O "/tmp/lucky.tar.gz" "${proxy}https://github.com/gdy666/lucky/releases/download/${tag}/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz"
	if [ "$?" = 0 ] ; then
		tar -xzf /tmp/lucky.tar.gz -C /tmp/var
		
		if [ $? -eq 0 ]; then
			chmod +x /tmp/var/lucky
   			if [ "$(($(/tmp/var/lucky -h 2>&1 | wc -l)))" -gt 3 ] ; then
				logg "下载成功"
				lk_ver=$(/tmp/var/lucky -info | awk -F'"Version":"' '{print $2}' | awk -F'"' '{print $1}')
				if [ -z "$lk_ver" ] ; then
					nvram set lucky_ver=""
				else
					nvram set lucky_ver=$lk_ver
				fi
				cp -f /tmp/var/lucky $PROG
				rm -rf /tmp/lucky.tar.gz
				break
       			else
	   			logg "下载不完整，请手动下载 ${lk_url} 解压上传到  $PROG"
	   			rm -f /tmp/lucky.tar.gz
	  		fi
       		else
	   		logg "下载不完整，请手动下载 ${lk_url} 解压上传到  $PROG"
	  	fi
	else
		logg "下载失败，请手动下载 ${lk_url} 解压上传到  $PROG"
   	fi
	done
}

lk_keep() {
	logg "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【lucky】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof lucky\`" ] && logger -t "进程守护" "lucky 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【lucky】|^$/d' /tmp/script/_opt_script_check #【lucky】
	[ -s /tmp/lucky.log ] && [ "\$(stat -c %s /tmp/lucky.log)" -gt 681984 ] && echo "" > /tmp/lucky.log & #【lucky】
	OSC

	fi

}

get_web() {
	output="$($PROG -baseConfInfo -cd $lucky_cmd)"
	lucky_port=$(echo "$output" | awk -F'"AdminWebListenPort":' '{print $2}' | awk -F',' '{print $1}')
	safeURL=$(echo "$output" | awk -F'"SafeURL":"' '{print $2}' | awk -F'"' '{print $1}')
	lan_ip=`nvram get lan_ipaddr`
	if [ ! -z "$lucky_port" ] && [ ! -z "$lan_ip" ] ; then
		nvram set lucky_login="http://${lan_ip}:${lucky_port}${safeURL}"
  	fi
}

lucky_start () {
  [ "$lucky_enable" != "1" ] && exit 1
  logg "开始启动"
  sed -Ei '/【lucky】|^$/d' /tmp/script/_opt_script_check
  killall lucky >/dev/null 2>&1
  killall -9 lucky >/dev/null 2>&1
  LUCKY_CONF="/etc/storage/lucky.conf"
  [ -z "$PROG" ] && find_bin 
  get_tag
  [ ! -d /etc/storage/lucky ] && mkdir -p /etc/storage/lucky
  if [ -f "$PROG" ] ; then
	[ ! -x "$PROG" ] && chmod +x $PROG
  	[[ "$($PROG -h 2>&1 | wc -l)" -lt 2 ]] && logg "程序${PROG}不完整！" && rm -rf $PROG
  fi
  if [ ! -f "$PROG" ] ; then
     logg "未找到程序$PROG ，开始在线下载..."
     if [ -z "$lucky_tag" ] ; then
     	[ -z "$tag" ] && tag="v2.15.7" && logg "未获取到最新版本，暂用$tag"
	lucky_dl $tag
     else
        logg "下载指定版本 $lucky_tag "
	lucky_dl $lucky_tag
     fi
  fi
[ ! -x "$PROG" ] && chmod +x $PROG
lk_ver=$($PROG -info | awk -F'"Version":"' '{print $2}' | awk -F'"' '{print $1}')
if [ -z "$lk_ver" ] ; then
	nvram set lucky_ver=""
else
	nvram set lucky_ver=$lk_ver
fi
cmd="${PROG} -cd ${lucky_cmd}"
logg "运行${cmd}"
eval "$cmd >/tmp/lucky.log 2>&1" &
sleep 6
if [ ! -z "`pidof lucky`" ] ; then
  mem=$(cat /proc/$(pidof lucky)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
  cpui="$(top -b -n1 | grep -E "$(pidof lucky)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /lucky/) break; else cpu=i}} END {print $cpu}')"
  logg "lucky ${lk_ver}启动成功" 
  logg "内存占用 ${mem} CPU占用 ${cpui}%"
  lucky_restart o
  get_web
  lk_keep
fi
[ -z "`pidof lucky`" ] && logg "lucky启动失败, 注意检查${PROG}是否下载完整,10 秒后自动尝试重新启动" && sleep 10 && lucky_restart x
exit 0
}

lucky_close () {
logg "关闭lucky..."
scriptname=$(basename $0)
sed -Ei '/【lucky】|^$/d' /tmp/script/_opt_script_check
  killall lucky >/dev/null 2>&1
  killall -9 lucky >/dev/null 2>&1
  rm -rf /tmp/lucky.log
  sleep 4
  [ -z "`pidof lucky`" ] && logg "进程已关闭!" && nvram set lucky_login=""
  if [ ! -z "$scriptname" ] ; then
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
fi
}

case $1 in
start)
	lucky_start &
	;;
restart)
	lucky_start &
	;;
stop)
	lucky_close
	;;
resetuser)
	[ -z "$PROG" ] && find_bin
	newuser="$2"
	[ -z "$newuser" ] && newuser="666"
	status="$(${PROG} -setconf -key AdminAccount -value ${newuser} -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		logg "用户名已修改为 ${newuser} 请重新启动程序."
	else
		logg "$status"
	fi
	;;
resetpass)
	[ -z "$PROG" ] && find_bin
	newpass="$2"
	[ -z "$newpass" ] && newpass="666"
	status="$(${PROG} -setconf -key AdminPassword -value ${newpass} -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		logg "密码已修改为 ${newpass} 请重新启动程序."
	else
		logg "$status"
	fi
	;;
resetport)
	[ -z "$PROG" ] && find_bin
	newport="$2"
	[ -z "$newport" ] && newport="16601"
	status="$(${PROG} -setconf -key AdminWebListenPort -value ${newport} -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		logg "http访问端口已修改为 ${newport} 请重新启动程序."
	else
		logg "$status"
	fi
	;;
resetsafe)
	[ -z "$PROG" ] && find_bin
	newsafe="$2"
	status="$(${PROG} -setconf -key SetSafeURL -value ${newsafe} -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		logg "安全入口已修改为 ${newsafe} 请重新启动程序."
	else
		logg "$status"
	fi
	;;
internettrue)
	[ -z "$PROG" ] && find_bin
	status="$(${PROG} -setconf -key AllowInternetaccess -value true -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		logg "已启用外网访问！请重新启动程序."
	else
		logg "$status"
	fi
	;;
internetfalse)
	[ -z "$PROG" ] && find_bin
	status="$(${PROG} -setconf -key AllowInternetaccess -value false -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		logg "已禁用外网访问！请重新启动程序."
	else
		logg "$status"
	fi
	;;
*)
	lucky_start &
	;;
esac

