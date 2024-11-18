#!/bin/sh

scriptname=$(basename $0)
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
lucky_enable=`nvram get lucky_enable`
lucky_cmd=`nvram get lucky_cmd`
[ -z "$lucky_cmd" ] && lucky_cmd="/etc/storage/lucky"
[ -z "$lucky_enable" ] && lucky_enable=0 && nvram set lucky_enable=0

logg  () {
  echo -e "\033[36;33m$(date +'%Y-%m-%d %H:%M:%S'):\033[0m\033[35;1m $1 \033[0m"
  echo "$(date +'%Y-%m-%d %H:%M:%S')：$1" >>/tmp/lucky.log
  logger -t "【lucky】" "$1"
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
        [ ! -x "$PROG" ] && chmod +x $PROG
        lk_ver=$($PROG -info | awk -F'"Version":"' '{print $2}' | awk -F'"' '{print $1}')
	if [ -z "$lk_ver" ] ; then
		nvram set lucky_ver=""
	else
		nvram set lucky_ver=$lk_ver
	fi
        break
    fi
done
[ -z "$PROG" ] && PROG="/tmp/lucky"
}

lucky_dl() {
	tag="$1"
	new_tag="$(echo $tag | tr -d 'v' | tr -d ' ')"
	logg "开始下载 https://github.com/gdy666/lucky/releases/download/${tag}/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz"
	for proxy in $github_proxys ; do
       curl -Lkso "/tmp/lucky.tar.gz" "${proxy}https://github.com/gdy666/lucky/releases/download/${tag}/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz" || wget --no-check-certificate -q -O "/tmp/lucky.tar.gz" "${proxy}https://github.com/gdy666/lucky/releases/download/${tag}/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz"
	if [ "$?" = 0 ] ; then
		tar -xzf /tmp/lucky.tar.gz -C /tmp/var
		chmod +x /tmp/var/lucky
		if [ $(($(/tmp/var/lucky -h | wc -l))) -gt 3 ] ; then
			logg "下载成功"
			lk_ver=$(/tmp/var/lucky -info | awk -F'"Version":"' '{print $2}' | awk -F'"' '{print $1}')
			if [ -z "$lk_ver" ] ; then
				nvram set lucky_ver=""
			else
				nvram set lucky_ver=$lk_ver
			fi
			cp /tmp/var/lucky $PROG
			rm -rf /tmp/lucky.tar.gz /tmp/var/lucky
			break
       	else
	   		logg "下载不完整，请手动下载 ${proxy}https://github.com/gdy666/lucky/releases/download/${tag}/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz 解压上传到  $PROG"
	  	fi
	else
		logg "下载失败，请手动下载 ${proxy}https://github.com/gdy666/lucky/releases/download/${tag}/lucky_${new_tag}_Linux_mipsle_softfloat.tar.gz 解压上传到  $PROG"
   	fi
	done
}

lk_keep() {
	logg "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【lucky】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof lucky\`" ] && logger -t "进程守护" "lucky 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【lucky】|^$/d' /tmp/script/_opt_script_check #【lucky】
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
  find_bin 
  get_tag
  [ ! -d /etc/storage/lucky ] && mkdir -p /etc/storage/lucky
  if [ ! -f "$PROG" ] || [ $(($($PROG -v | wc -l))) -lt 3 ] ; then
     logg "未找到程序$PROG 或 文件不完整不匹配，开始在线下载..."
     [ -z "$tag" ] && tag="v2.13.4" && logg "未获取到最新版本，暂用$atg"
     lucky_dl $tag
  fi

cmd="${PROG} -cd ${lucky_cmd}"
logg "运行${cmd}"
eval "$cmd >/tmp/lucky.log 2>&1" &
sleep 6
if [ ! -z "`pidof lucky`" ] ; then
  logg "lucky启动成功" 
  get_web
  lk_keep
fi
[ -z "`pidof lucky`" ] && logg "lucky启动失败!" 

}

lucky_close () {
logg "关闭lucky..."
scriptname=$(basename $0)
sed -Ei '/【lucky】|^$/d' /tmp/script/_opt_script_check
if [ ! -z "$scriptname" ] ; then
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
	eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
fi
  killall lucky >/dev/null 2>&1
  killall -9 lucky >/dev/null 2>&1
  rm -rf /tmp/lucky.log
  sleep 4
  [ -z "`pidof lucky`" ] && logg "进程已关闭!"
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
	find_bin
	newuser="$1"
	[ -z "$newuser" ] && newuser="666"
	status="$(${PROG} -setconf -key AdminAccount -value ${newuser} -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		echo "用户名已修改为 ${newuser} 重新启动程序生效."
	else
		echo "$status"
	fi
	;;
resetpass)
	find_bin
	newpass="$1"
	[ -z "$newpass" ] && newpass="666"
	status="$(${PROG} -setconf -key AdminPassword -value ${newpass} -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		echo "密码已修改为 ${newpass} 重新启动程序生效."
	else
		echo "$status"
	fi
	;;
resetport)
	find_bin
	newport="$1"
	[ -z "$newport" ] && newport="16601"
	status="$(${PROG} -setconf -key AdminWebListenPort -value ${newport} -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		echo "http访问端口已修改为 ${newport} "
	else
		echo "$status"
	fi
	get_web
	;;
resetsafe)
	find_bin
	newsafe="$1"
	status="$(${PROG} -setconf -key SetSafeURL -value ${newsafe} -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		echo "安全入口已修改为 ${newsafe} "
	else
		echo "$status"
	fi
	get_web
	;;
internettrue)
	find_bin
	status="$(${PROG} -setconf -key AllowInternetaccess -value true -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		echo "已启用外网访问！"
	else
		echo "$status"
	fi
	;;
internetfalse)
	find_bin
	status="$(${PROG} -setconf -key AllowInternetaccess -value false -cd ${lucky_cmd})"
	if [ "$status" = "SetConfigure success" ] ; then
		echo "已禁用外网访问！"
	else
		echo "$status"
	fi
	;;
*)
	lucky_start &
	;;
esac

