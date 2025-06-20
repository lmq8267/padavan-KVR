#!/bin/sh

et_enable=$(nvram get easytier_enable)
config_server="$(nvram get easytier_config_server)"
et_core="$(nvram get easytier_bin)"
et_log="$(nvram get easytier_log)"
et_ports="$(nvram get easytier_ports)"
et_tunname="$(nvram get easytier_tunname)"
et_hostname="$(nvram get easytier_hostname)"
et_web_enable="$(nvram get easytier_web_enable)"
et_web_db="$(nvram get easytier_web_db)"
et_web_port="$(nvram get easytier_web_port)"
et_web_protocol="$(nvram get easytier_web_protocol)"
et_web_api="$(nvram get easytier_web_api)"
et_web_log="$(nvram get easytier_web_log)"
et_html_port="$(nvram get easytier_html_port)"
et_web_bin="$(nvram get easytier_web_bin)"
et_api_host="$(nvram get easytier_api_host)"
et_uuid="$(nvram get easytier_uuid)"
[ -z "$et_web_port" ] && et_web_port=22020
[ -z "$et_web_api" ] && et_web_port=11211
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
easytier_renum=`nvram get easytier_renum`

logg() {
  echo -e "\033[36;33m$(date +'%Y-%m-%d %H:%M:%S'):\033[0m\033[35;1m $1 \033[0m"
  echo "$(date +'%Y-%m-%d %H:%M:%S'): $1" >>/tmp/natpierce.log
  logger -t "【EasyTier】" "$1"
}

et_restart () {
relock="/var/lock/easytier_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set easytier_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	easytier_renum=${easytier_renum:-"0"}
	easytier_renum=`expr $easytier_renum + 1`
	nvram set easytier_renum="$easytier_renum"
	if [ "$easytier_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logg "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get easytier_renum)" = "0" ] && break
   			#[ "$(nvram get easytier_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set easytier_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
start_et
}

get_tag() {
	curltest=`which curl`
	logg "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/lmq8267/EasyTier/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/lmq8267/EasyTier/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/lmq8267/EasyTier/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/lmq8267/EasyTier/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logg "无法获取最新版本"  
	nvram set easytier_ver_n=$tag
	if [ -f "$et_core" ] ; then
		chmod +x $et_core
		et_ver=$($et_core -V | awk '{print $2}' | tr -d ' ' | tr -d '\n')
		if [ -z "$et_ver" ] ; then
			nvram set easytier_ver=""
		else
			nvram set easytier_ver="v${et_ver}"
		fi
	fi
}

dowload_et() {
	tag="$1"
	bin_path=$(dirname "$et_core")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
	logg "开始下载 https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz"
	for proxy in $github_proxys ; do
 	length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 	length=`expr $length + 512000`
	length=`expr $length / 1048576`
 	et_size0="$(check_disk_size $bin_path)"
 	[ ! -z "$length" ] && logg "程序大小 ${length}M， 程序路径可用空间 ${et_size0}M "
        curl -Lko /tmp/easytier-mipsel-linux-muslsf.tar.gz "${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz" || wget --no-check-certificate -O /tmp/easytier-mipsel-linux-muslsf.tar.gz "${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz"
	if [ "$?" = 0 ] ; then
		tar -xzf /tmp/easytier-mipsel-linux-muslsf.tar.gz -O easytier-core > "$bin_path/easytier-core"
  		tar -xzf /tmp/easytier-mipsel-linux-muslsf.tar.gz -O easytier-cli > "$bin_path/easytier-cli"
		chmod +x $et_core
		if [[ "$($et_core -h 2>&1 | wc -l)" -gt 3 ]] ; then
			logg "$et_core 下载成功"
			et_ver=$($et_core -V | awk '{print $2}' | tr -d ' ' | tr -d '\n')
			if [ -z "$et_ver" ] ; then
				nvram set easytier_ver=""
			else
				nvram set easytier_ver="v${et_ver}"
			fi
   			rm -rf /tmp/easytier-mipsel-linux-muslsf.tar.gz
			break
       		else
	   		logg "下载不完整，请手动下载 ${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz 解压上传到  $et_core"
	   		rm -f $et_core
      			rm -rf /tmp/easytier-mipsel-linux-muslsf.tar.gz
	  	fi
	else
		log "下载失败，请手动下载 ${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz 上传到  $et_core"
   	fi
	done
}

dowload_web() {
	tag="$1"
	webbin_path=$(dirname "$et_web_bin")
	[ ! -d "$webbin_path" ] && mkdir -p "$webbin_path"
	logg "开始下载 https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz"
	for proxy in $github_proxys ; do
 	length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 	length=`expr $length + 512000`
	length=`expr $length / 1048576`
 	et_size0="$(check_disk_size $webbin_path)"
 	[ ! -z "$length" ] && logg "程序大小 ${length}M， 程序路径可用空间 ${et_size0}M "
        curl -Lko /tmp/easytier-mipsel-linux-muslsf.tar.gz "${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz" || wget --no-check-certificate -O /tmp/easytier-mipsel-linux-muslsf.tar.gz "${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz"
	if [ "$?" = 0 ] ; then
		tar -xzf /tmp/easytier-mipsel-linux-muslsf.tar.gz -O easytier-web > "$webbin_path/easytier-web"
		chmod +x $et_web_bin
		if [[ "$($et_web_bin -h 2>&1 | wc -l)" -gt 3 ]] ; then
			logg "$et_web_bin 下载成功"
   			rm -rf /tmp/easytier-mipsel-linux-muslsf.tar.gz
			break
       		else
	   		logg "下载不完整，请手动下载 ${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz 解压上传到  $et_web_bin"
	   		rm -f $et_web_bin
      			rm -rf /tmp/easytier-mipsel-linux-muslsf.tar.gz
	  	fi
	else
		log "下载失败，请手动下载 ${proxy}https://github.com/lmq8267/EasyTier/releases/download/${tag}/easytier-mipsel-linux-muslsf.tar.gz 上传到  $et_web_bin"
   	fi
	done
}

update_et() {
	get_tag
	[ -z "$tag" ] && logg "无法获取最新版本" && exit 1
	tag=$(echo $tag | tr -d 'v' | tr -d ' ' | tr -d '\n')
	et_ver=$(echo $et_ver | cut -d '-' -f1)
	if [ ! -z "$tag" ] && [ ! -z "$et_ver" ] ; then
		if [ "$tag"x != "$et_ver"x ] ; then
			logg "当前版本${et_ver} 最新版本${tag}"
			dowload_et $tag
		else
			logg "当前已是最新版本 ${tag} 无需更新！"
		fi
	fi
	exit 0
}
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
core_keep() {
	logg "Core守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【EasyTier_core】|^$/d' /tmp/script/_opt_script_check
	if [ -z "$et_tunname" ] ; then
		tunname="tun0"
	else
		tunname="${et_tunname}"
	fi
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof easytier-core\`" ] && logger -t "进程守护" "EasyTier_core 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【EasyTier_core】|^$/d' /tmp/script/_opt_script_check #【EasyTier_core】
	[ -z "\$(iptables -L -n -v | grep '$tunname')" ] && logger -t "进程守护" "EasyTier_core 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【EasyTier_core】|^$/d' /tmp/script/_opt_script_check #【EasyTier_core】
 	[ -s /tmp/easytier.log ] && [ "\$(stat -c %s /tmp/easytier.log)" -gt 4194304 ] && echo "" > /tmp/easytier.log & #【EasyTier_core】
	OSC
	if [ ! -z "$et_ports" ] ; then
		et_portss=$(echo $et_ports | tr -d '\r')
		for et_port in $et_portss ; do
			[ -z "$et_port" ] && continue
			cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\$(iptables -L -n -v | grep '$et_port')" ] && logger -t "进程守护" "EasyTier_core 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【EasyTier_core】|^$/d' /tmp/script/_opt_script_check #【EasyTier_core】
	OSC
		done	
	fi
	fi

}

web_keep() {
	logg "Web守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【EasyTier_web】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof easytier-web\`" ] && logger -t "进程守护" "EasyTier_web 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【EasyTier_web】|^$/d' /tmp/script/_opt_script_check #【EasyTier_web】
 	[ -z "\$(iptables -L -n -v | grep '$et_web_port')" ] && logger -t "进程守护" "EasyTier_web 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【EasyTier_web】|^$/d' /tmp/script/_opt_script_check #【EasyTier_web】
  	[ -z "\$(iptables -L -n -v | grep '$et_web_api')" ] && logger -t "进程守护" "EasyTier_web 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【EasyTier_web】|^$/d' /tmp/script/_opt_script_check #【EasyTier_web】
 	[ -s /tmp/easytier_web.log ] && [ "\$(stat -c %s /tmp/easytier_web.log)" -gt 4194304 ] && echo "" > /tmp/easytier_web.log & #【EasyTier_web】
	OSC
	
	if [ ! -z "$et_html_port" ] ; then
	cat >> "/tmp/script/_opt_script_check" <<-OSC
 	[ -z "\$(iptables -L -n -v | grep '$et_html_port')" ] && logger -t "进程守护" "EasyTier_web 防火墙规则失效" && eval "$scriptfilepath start &" && sed -Ei '/【EasyTier_web】|^$/d' /tmp/script/_opt_script_check #【EasyTier_web】
	OSC
	fi
	fi

}

et_rules() {
	if [ -z "$et_tunname" ] ; then
		tunname="tun0"
	else
		tunname="${et_tunname}"
	fi
	iptables -I INPUT -i ${tunname} -j ACCEPT
	iptables -I FORWARD -i ${tunname} -o ${tunname} -j ACCEPT
	iptables -I FORWARD -i ${tunname} -j ACCEPT
	iptables -t nat -I POSTROUTING -o ${tunname} -j MASQUERADE
	sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1
	if [ ! -z "$et_ports" ] ; then
		et_portss=$(echo $et_ports | tr -d '\r')
		for et_port in $et_portss ; do
			[ -z "$et_port" ] && continue
			iptables -I INPUT -p tcp --dport "$et_port" -j ACCEPT 
		 	ip6tables -I INPUT -p tcp --dport "$et_port" -j ACCEPT 
		 	iptables -I INPUT -p udp --dport "$et_port" -j ACCEPT
		 	ip6tables -I INPUT -p udp --dport "$et_port" -j ACCEPT 
		done	
	fi
	core_keep
}

start_core() {
	[ "$et_enable" = "0" ] && return 1
	logg "正在启动easytier-core"
  	if [ -z "$et_core" ] ; then
		et_core=/tmp/var/easytier-core
  		nvram set easytier_bin=$et_core
    	fi
	get_tag
 	if [ -f "$et_core" ] ; then
		[ ! -x "$et_core" ] && chmod +x $et_core
  		[[ "$($et_core -h 2>&1 | wc -l)" -lt 2 ]] && logg "程序${et_core}不完整！" && rm -rf $et_core
  	fi
 	if [ ! -f "$et_core" ] ; then
		logg "主程序${et_core}不存在，开始在线下载..."
  		[ -z "$tag" ] && tag="v2.3.2"
  		dowload_et $tag
  	fi
	sed -Ei '/【EasyTier_core】|^$/d' /tmp/script/_opt_script_check
	killall easytier-core >/dev/null 2>&1
	bin_path=$(dirname "$et_core")
	CMD=""
	if [ "$et_enable" = "1" ] ; then
		if [ -z "$config_server" ] ; then
			logg "Web服务器地址或用户名不能为空！程序退出！"
			exit 1
		fi
		[ -f /etc/storage/et_machine_id ] || touch /etc/storage/et_machine_id
		if [ ! -s /etc/storage/et_machine_id ]; then
			if [ -z "$et_uuid" ] ; then
				cat /proc/sys/kernel/random/uuid > /etc/storage/et_machine_id
				et_uuid="$(cat /etc/storage/et_machine_id | tr -d ' \n')"
				nvram set easytier_uuid="$et_uuid"
				nvram commit
				logg "/etc/storage/et_machine_id 为空，生成新的设备uuid $et_uuid"
			else
				echo "$et_uuid" > /etc/storage/et_machine_id
			fi
		fi
		core_uuid="$(cat /etc/storage/et_machine_id | tr -d ' \n')"
		#mkdir -p /var/lib/dbus
		#ln -sf /etc/storage/et_machine_id /var/lib/dbus/machine-id
		#[ -f "${bin_path}/et_machine_id" ] || ln -sf /etc/storage/et_machine_id ${bin_path}/et_machine_id
		[ "$et_log" = "1" ] && CMD="--console-log-level warn"
		[ "$et_log" = "2" ] && CMD="--console-log-level info"
		[ "$et_log" = "3" ] && CMD="--console-log-level debug"
		[ "$et_log" = "4" ] && CMD="--console-log-level trace"
		[ "$et_log" = "5" ] && CMD="--console-log-level error"
		[ -z "$core_uuid" ] || CMD=" --machine-id $core_uuid $CMD"
		[ ! -z "$et_hostname" ] && CMD="--hostname $et_hostname $CMD"
		CMD="-w $config_server $CMD"
	else
		[ "$et_log" = "1" ] && CMD="--console-log-level warn"
		[ "$et_log" = "2" ] && CMD="--console-log-level info"
		[ "$et_log" = "3" ] && CMD="--console-log-level debug"
		[ "$et_log" = "4" ] && CMD="--console-log-level trace"
		[ "$et_log" = "5" ] && CMD="--console-log-level error"
		CMD="-c /etc/storage/easytier.toml $CMD"
	fi
	etcmd="cd $bin_path ; ./easytier-core ${CMD} >/tmp/easytier.log 2>&1"
	echo "$etcmd" >/tmp/easytier.CMD 
	logg "运行${etcmd}"
	eval "$etcmd" &
	sleep 4
	if [ ! -z "`pidof easytier-core`" ] ; then
 		mem=$(cat /proc/$(pidof easytier-core)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   		etcpu="$(top -b -n1 | grep -E "$(pidof easytier-core)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /easytier-core/) break; else cpu=i}} END {print $cpu}')"
		logg "运行成功！"
  		logg "内存占用 ${mem} CPU占用 ${etcpu}%"
  		et_restart o
		echo `date +%s` > /tmp/easytier_time
		et_rules
	else
		logg "运行失败, 注意检查${et_core}是否下载完整,10 秒后自动尝试重新启动"
  		sleep 10
  		et_restart x
	fi
	return 0
}

start_web() {
	[ "$et_web_enable" = "0" ] && return 1
	logg "正在启动easytier-web"
  	if [ -z "$et_web_bin" ] ; then
		et_core=/tmp/var/easytier-web
  		nvram set easytier_web_bin=$et_web_bin
    	fi
     	
    	if [ -f "$et_web_bin" ] ; then
		[ ! -x "$et_web_bin" ] && chmod +x $et_web_bin
  		[[ "$($et_web_bin -h 2>&1 | wc -l)" -lt 2 ]] && logg "程序${et_web_bin}不完整！" && rm -rf $et_web_bin
  	fi
 	if [ ! -f "$et_web_bin" ] ; then
  		get_tag
		logg "程序${et_web_bin}不存在，开始在线下载..."
  		[ -z "$tag" ] && tag="v2.3.2"
  		dowload_web $tag
  	fi
	sed -Ei '/【EasyTier_web】|^$/d' /tmp/script/_opt_script_check
	webCMD=""
	if [ ! -z "$et_web_db" ] ; then 
 		wdb_path=$(dirname "$et_web_db")
   		mkdir -p $wdb_path
 		webCMD="-d $et_web_db" 
   	fi
	[ -z "$et_web_port" ] || webCMD="${webCMD} -c $et_web_port" 
	[ -z "$et_web_protocol" ] || webCMD="${webCMD} -p $et_web_protocol" 
	[ -z "$et_web_api" ] || webCMD="${webCMD} -a $et_web_api" 
	if [ -z "$et_html_port" ] ; then
		webCMD="${webCMD} --no-web" 
	else
		webCMD="${webCMD} -l $et_html_port" 
	fi
	[ -z "$et_api_host" ] || webCMD="${webCMD} --api-host $et_api_host"
  	[ "$et_web_log" = "1" ] && webCMD="${webCMD} --console-log-level warn"
	[ "$et_web_log" = "2" ] && webCMD="${webCMD} --console-log-level info"
	[ "$et_web_log" = "3" ] && webCMD="${webCMD} --console-log-level debug"
	[ "$et_web_log" = "4" ] && webCMD="${webCMD} --console-log-level trace"
	[ "$et_web_log" = "5" ] && webCMD="${webCMD} --console-log-level error"
	wbin_path=$(dirname "$et_web_bin")
	etwcmd="cd $wbin_path ; ./easytier-web ${webCMD} >/tmp/easytier_web.log 2>&1"
	logg "运行${etwcmd}"
	eval "$etwcmd" &
	sleep 4
	if [ ! -z "`pidof easytier-web`" ] ; then
 		wmem=$(cat /proc/$(pidof easytier-web)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   		etwcpu="$(top -b -n1 | grep -E "$(pidof easytier-web)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /easytier-web/) break; else cpu=i}} END {print $cpu}')"
		logg "运行成功！"
  		logg "内存占用 ${wmem} CPU占用 ${etwcpu}%"
  		et_restart o
  		web_keep
    		iptables -I INPUT -p tcp --dport "$et_web_port" -j ACCEPT 
		ip6tables -I INPUT -p tcp --dport "$et_web_port" -j ACCEPT
		iptables -I INPUT -p udp --dport "$et_web_port" -j ACCEPT 
		ip6tables -I INPUT -p udp --dport "$et_web_port" -j ACCEPT
  		iptables -I INPUT -p tcp --dport "$et_web_api" -j ACCEPT
		ip6tables -I INPUT -p tcp --dport "$et_web_api" -j ACCEPT
		iptables -I INPUT -p udp --dport "$et_web_api" -j ACCEPT
		ip6tables -I INPUT -p udp --dport "$et_web_api" -j ACCEPT
		if [ ! -z "$et_html_port" ] ; then
			iptables -I INPUT -p tcp --dport "$et_html_port" -j ACCEPT 
			ip6tables -I INPUT -p tcp --dport "$et_html_port" -j ACCEPT
		fi
	else
		logg "运行失败, 注意检查${et_web_bin}是否下载完整,10 秒后自动尝试重新启动"
  		sleep 10
  		et_restart x
	fi
	return 0
	
}

start_et() {
	start_core
	start_web
}

stop_et() {
	logg  "正在关闭..."
	sed -Ei '/【EasyTier_core】|^$/d' /tmp/script/_opt_script_check
	sed -Ei '/【EasyTier_web】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	if [ -z "$et_tunname" ] ; then
		tunname="tun0"
	else
		tunname="${et_tunname}"
	fi
	killall easytier-core >/dev/null 2>&1
	killall easytier-web >/dev/null 2>&1
	if [ ! -z "$et_ports" ] ; then
		et_portss=$(echo $et_ports | tr -d '\r')
		for et_port in $et_portss ; do
			[ -z "$et_port" ] && continue
			iptables -D INPUT -p tcp --dport "$et_port" -j ACCEPT >/dev/null 2>&1
		 	ip6tables -D INPUT -p tcp --dport "$et_port" -j ACCEPT >/dev/null 2>&1
		 	iptables -D INPUT -p udp --dport "$et_port" -j ACCEPT >/dev/null 2>&1
		 	ip6tables -D INPUT -p udp --dport "$et_port" -j ACCEPT >/dev/null 2>&1
		done	
	fi
	iptables -D INPUT -i ${tunname} -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i ${tunname} -o ${tunname} -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i ${tunname} -j ACCEPT 2>/dev/null
	iptables -t nat -D POSTROUTING -o ${tunname} -j MASQUERADE 2>/dev/null
 	iptables -D INPUT -p tcp --dport "$et_web_port" -j ACCEPT >/dev/null 2>&1
	ip6tables -D INPUT -p tcp --dport "$et_web_port" -j ACCEPT >/dev/null 2>&1
	iptables -D INPUT -p udp --dport "$et_web_port" -j ACCEPT >/dev/null 2>&1
	ip6tables -D INPUT -p udp --dport "$et_web_port" -j ACCEPT >/dev/null 2>&1
  	iptables -D INPUT -p tcp --dport "$et_web_api" -j ACCEPT >/dev/null 2>&1
	ip6tables -D INPUT -p tcp --dport "$et_web_api" -j ACCEPT >/dev/null 2>&1
	iptables -D INPUT -p udp --dport "$et_web_api" -j ACCEPT >/dev/null 2>&1
	ip6tables -D INPUT -p udp --dport "$et_web_api" -j ACCEPT >/dev/null 2>&1
	if [ ! -z "$et_html_port" ] ; then
		iptables -D INPUT -p tcp --dport "$et_html_port" -j ACCEPT >/dev/null 2>&1
		ip6tables -D INPUT -p tcp --dport "$et_html_port" -j ACCEPT >/dev/null 2>&1
	fi
	[ -z "`pidof easytier-core`" ] && [ -z "`pidof easytier-web`" ] && logg "进程已关闭!"
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
}

et_error="错误：${et_core} 未运行，请运行成功后执行此操作！"
et_process=$(pidof easytier-core)
etpath=$(dirname "$et_core")
cmdfile="/tmp/easytier_cmd.log"

peer() {
	if [ ! -z "$et_process" ] ; then
		cd $etpath
  		[ ! -x "${etpath}/easytier-cli" ] && chmod +x ${etpath}/easytier-cli
		./easytier-cli peer >$cmdfile 2>&1
	else
		echo "$et_error" >$cmdfile 2>&1
	fi
	exit 1
}

connector() {
	if [ ! -z "$et_process" ] ; then
		cd $etpath
  		[ ! -x "${etpath}/easytier-cli" ] && chmod +x ${etpath}/easytier-cli
		./easytier-cli connector >$cmdfile 2>&1
	else
		echo "$et_error" >$cmdfile 2>&1
	fi
	exit 1
}

stun() {
	if [ ! -z "$et_process" ] ; then
		cd $etpath
  		[ ! -x "${etpath}/easytier-cli" ] && chmod +x ${etpath}/easytier-cli
		./easytier-cli stun >$cmdfile 2>&1
	else
		echo "$et_error" >$cmdfile 2>&1
	fi
	exit 1
}

route() {
	if [ ! -z "$et_process" ] ; then
		cd $etpath
  		[ ! -x "${etpath}/easytier-cli" ] && chmod +x ${etpath}/easytier-cli
		./easytier-cli route >$cmdfile 2>&1
	else
		echo "$et_error" >$cmdfile 2>&1
	fi
	exit 1
}

peer_center() {
	if [ ! -z "$et_process" ] ; then
		cd $etpath
  		[ ! -x "${etpath}/easytier-cli" ] && chmod +x ${etpath}/easytier-cli
		./easytier-cli peer-center >$cmdfile 2>&1
	else
		echo "$et_error" >$cmdfile 2>&1
	fi
	exit 1
}

vpn_portal() {
	if [ ! -z "$et_process" ] ; then
		cd $etpath
  		[ ! -x "${etpath}/easytier-cli" ] && chmod +x ${etpath}/easytier-cli
		./easytier-cli vpn-portal >$cmdfile 2>&1
	else
		echo "$et_error" >$cmdfile 2>&1
	fi
	exit 1
}

node() {
	if [ ! -z "$et_process" ] ; then
		cd $etpath
  		[ ! -x "${etpath}/easytier-cli" ] && chmod +x ${etpath}/easytier-cli
		./easytier-cli node >$cmdfile 2>&1
	else
		echo "$et_error" >$cmdfile 2>&1
	fi
	exit 1
}

proxy() {
	if [ ! -z "$et_process" ] ; then
		cd $etpath
  		[ ! -x "${etpath}/easytier-cli" ] && chmod +x ${etpath}/easytier-cli
		./easytier-cli proxy >$cmdfile 2>&1
	else
		echo "$et_error" >$cmdfile 2>&1
	fi
	exit 1
}

status() {
	if [ ! -z "$et_process" ] ; then
		etcpu="$(top -b -n1 | grep -E "$(pidof easytier-core)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /easytier-core/) break; else cpu=i}} END {print $cpu}')"
		echo -e "\t\t easytier-core 运行状态\n" >$cmdfile
		[ ! -z "$etcpu" ] && echo "CPU占用 ${etcpu}% " >>$cmdfile 2>&1
		etram="$(cat /proc/$(pidof easytier-core | awk '{print $NF}')/status|grep -w VmRSS|awk '{printf "%.2fMB\n", $2/1024}')"
		[ ! -z "$etram" ] && echo "内存占用 ${etram}" >>$cmdfile 2>&1
		ettime=$(cat /tmp/easytier_time) 
		if [ -n "$ettime" ] ; then
			time=$(( `date +%s`-ettime))
			day=$((time/86400))
			[ "$day" = "0" ] && day=''|| day=" $day天"
			time=`date -u -d @${time} +%H小时%M分%S秒`
		fi
		[ ! -z "$time" ] && echo "已运行 $time" >>$cmdfile 2>&1
		cmdtart=$(cat /tmp/easytier.CMD)
		[ ! -z "$cmdtart" ] && echo "启动参数  $cmdtart" >>$cmdfile 2>&1
		
	else
		echo "$et_error" >$cmdfile
	fi
	exit 1
}

case $1 in
start)
	start_et &
	;;
stop)
	stop_et
	;;
restart)
	stop_et
	start_et &
	;;
update)
	update_et &
	;;
peer)
	peer
	;;
connector)
	connector
	;;
stun)
	stun
	;;
route)
	route
	;;
peer-center)
	peer_center
	;;
vpn-portal)
	vpn_portal
	;;
node)
	node
	;;
proxy)
	proxy
	;;
status)
	status
	;;
*)
	echo "check"
	#exit 0
	;;
esac
