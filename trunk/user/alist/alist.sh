#!/bin/sh

export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
alist_enable="$(nvram get alist_enable)"
site_url="$(nvram get alist_site_url)"
cdn="$(nvram get alist_cdn)"
expires="$(nvram get alist_expires)"
sqlite="$(nvram get alist_sqlite)"
sqlite_host="$(nvram get alist_sqlite_host)"
sqlite_port="$(nvram get alist_sqlite_port)"
sqlite_user="$(nvram get alist_sqlite_user)"
sqlite_pass="$(nvram get alist_sqlite_pass)"
sqlite_name="$(nvram get alist_sqlite_name)"
sqlite_tab="$(nvram get alist_sqlite_tab)"
db_file="$(nvram get alist_db_file)"
alist_addr="$(nvram get alist_address)"
alist_port="$(nvram get alist_port)"
alist_sport="$(nvram get alist_sport)"
alist_https="$(nvram get alist_https)"
alist_cert="$(nvram get alist_cert)"
alist_key="$(nvram get alist_key)"
alist_temp="$(nvram get alist_temp)"
alist_bleve="$(nvram get alist_bleve)"
log_enable="$(nvram get alist_log_enable)"
log_size="$(nvram get alist_log_size)"
log_name="$(nvram get alist_log_name)"
log_compress="$(nvram get alist_log_compress)"
delayed="$(nvram get alist_delayed)"
connections="$(nvram get alist_connections)"
alist_s3="$(nvram get alist_s3)"
s3_port="$(nvram get alist_s3_port)"
s3_ssl="$(nvram get alist_s3_ssl)"
alist="$(nvram get alist_bin)"
alist_upx="$(nvram get alist_upx)"
repo="AlistGo/alist"
[ "$alist_upx" = "1" ] && repo="lmq8267/alist"
[ -z "$alist" ] && alist="/tmp/alist/alist" && nvram set alist_bin=$alist
[ ! -d /tmp/alist ] && mkdir -p /tmp/alist
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)

get_tag() {
	curltest=`which curl`
	logger -t "Alist" "开始获取最新版本..."
    	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/${repo}/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/${repo}/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/${repo}/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/${repo}/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
	[ -z "$tag" ] && logger -t "Alist" "无法获取最新版本"
	nvram set alist_ver_n=$tag
	if [ -f "$alist" ] ; then
		[ ! -x "$alist" ] && chmod +x $alist
		al_ver=$($alist version | grep -Ew "^Version" | awk '{print $2}')
		if [ -z "$al_ver" ] ; then
			nvram set alist_ver=""
		else
			nvram set alist_ver=$al_ver
		fi
	fi
}

dowload_al() {
	tag="$1"
	bin_path=$(dirname "$alist")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
	if [ "$alist_upx" = "1" ] ; then
		url="https://github.com/lmq8267/alist/releases/download/${tag}/alist.tar.gz"
	else
		url="https://github.com/AlistGo/alist/releases/download/${tag}/alist-linux-musl-mipsle.tar.gz"
	fi
	logger -t "Alist" "开始下载 ${url} "
	for proxy in $github_proxys ; do
       curl -Lkso "/tmp/alist.tar.gz" "${proxy}${url}" || wget --no-check-certificate -q -O "/tmp/alist.tar.gz" "${proxy}${url}"
	if [ "$?" = 0 ] ; then
		logger -t "Alist" "开始解压..."
		tar -xzf /tmp/alist.tar.gz -C /tmp
		chmod +x /tmp/alist
		if [ $(($(/tmp/alist -h | wc -l))) -gt 3 ] ; then
			logger -t "Alist" "解压成功"
			cp -rf /tmp/alist $alist
			al_ver=$($alist version | grep -Ew "^Version" | awk '{print $2}')
			if [ -z "$al_ver" ] ; then
				nvram set alist_ver=""
			else
				nvram set alist_ver=$al_ver
			fi
			rm -rf /tmp/alist.tar.gz
			break
       	else
	   		logger -t "Alist" "下载不完整，请手动下载 ${proxy}${url} 解压上传到  $PROG"
			rm -f $PROG
	  	fi
	else
		logger -t "Alist" "下载失败，请手动下载 ${proxy}${url} 解压上传到  $PROG"
   	fi
	done
}

update_al() {
	get_tag
	bin_path=$(dirname "$alist")
	[ ! -d "$bin_path" ] && mkdir -p "$bin_path"
	[ -z "$tag" ] && logger -t "Alist" "无法获取最新版本" && exit 1
	if [ ! -z "$tag" ] && [ ! -z "$al_ver" ] ; then
		if [ "$tag"x != "$al_ver"x ] ; then
			logger -t "Alist" "当前版本${al_ver} 最新版本${tag}"
			dowload_al $tag
		else
			logger -t "Alist" "当前已是最新版本 ${tag} 无需更新！"
		fi
	fi
	exit 0
}

al_keep() {
	logger -t "Alist" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【Alist】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof alist\`" ] && logger -t "进程守护" "alist 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【Alist】|^$/d' /tmp/script/_opt_script_check #【Alist】
	[ -s /tmp/alist.log ] && [ "\$(stat -c %s /tmp/alist.log)" -gt 681984 ] && echo "" > /tmp/alist.log & #【Alist】
	OSC

	fi

}

set_json() {
	
	if [ "$alist_https" = "1" ] ; then
		alist_https="true"
	else
		alist_https="false"
	fi
	if [ "$log_enable" = "1" ] ; then
		log_enable="true"
	else
		log_enable="false"
	fi
	if [ "$log_compress" = "1" ] ; then
		log_compress="true"
	else
		log_compress="false"
	fi	
	if [ "$alist_s3" = "1" ] ; then
		alist_s3="true"
	else
		alist_s3="false"
	fi
	if [ "$s3_ssl" = "1" ] ; then
		s3_ssl="true"
	else
		s3_ssl="false"
	fi
	if [ -z "$alist_temp" ] ; then
		alist_temp="/tmp/alist/temp"
		nvram set alist_temp="$alist_temp"
	fi
	if [ -z "$alist_bleve" ] ; then
		alist_bleve="/etc/storage/alist/bleve"
		nvram set alist_bleve="$alist_bleve"
	fi
	if [ -z "$log_name" ] ; then
		log_name="/tmp/alist.log"
		nvram set alist_log_name="$log_name"
	fi
	
	[ -z "$expires" ] && expires=0 && nvram set alist_expires=0
	[ -z "$sqlite_port" ] && sqlite_port=0 && nvram set alist_sqlite_port=0
	[ -z "$alist_port" ] && alist_port="5244" && nvram set alist_port="5244"
	[ -z "$alist_sport" ] && alist_sport="-1" && nvram set alist_sport="-1"
	[ -z "$log_size" ] && log_size=1 && nvram set alist_log_size=1
	[ -z "$delayed" ] && delayed=0 && nvram set alist_delayed=0
	[ -z "$connections" ] && connections=0 && nvram set alist_connections=0
	[ -z "$s3_port" ] && s3_port="5246" && nvram set alist_s3_port="5246"
jq --arg site_url0 "$site_url" \
   --arg cdn0 "$cdn" \
   --argjson expires0 "$expires" \
   --arg sqlite0 "$sqlite" \
   --arg sqlite_host0 "$sqlite_host" \
   --argjson sqlite_port0 "$sqlite_port" \
   --arg sqlite_user0 "$sqlite_user" \
   --arg sqlite_pass0 "$sqlite_pass" \
   --arg sqlite_name0 "$sqlite_name" \
   --arg sqlite_tab0 "$sqlite_tab" \
   --arg db_file0 "$db_file" \
   --arg alist_addr0 "$alist_addr" \
   --argjson alist_port0 "$alist_port" \
   --argjson alist_sport0 "$alist_sport" \
   --argjson alist_https0 "$alist_https" \
   --arg alist_cert0 "$alist_cert" \
   --arg alist_key0 "$alist_key" \
   --arg alist_temp0 "$alist_temp" \
   --arg alist_bleve0 "$alist_bleve" \
   --argjson log_enable0 "$log_enable0" \
   --argjson log_size0 "$log_size" \
   --arg log_name0 "$log_name" \
   --argjson log_compress0 "$log_compress" \
   --argjson delayed0 "$delayed" \
   --argjson connections0 "$connections" \
   --argjson alist_s30 "$alist_s3" \
   --argjson s3_port0 "$s3_port" \
   --argjson s3_ssl0 "$s3_ssl" \
   '.site_url = $site_url0 |
    .cdn = $cdn0 |
    .token_expires_in = $expires0 |
    .database.type = $sqlite0 |
    .database.host = $sqlite_host0 |
    .database.port = $sqlite_port0 |
    .database.user = $sqlite_user0 |
    .database.password = $sqlite_pass0 |
    .database.name = $sqlite_name0 |
    .database.db_file = $db_file0 |
    .database.table_prefix = $sqlite_tab0 |
    .scheme.address = $alist_addr0 |
    .scheme.http_port = $alist_port0 |
    .scheme.https_port = $alist_sport0 |
    .scheme.force_https = $alist_https0 |
    .scheme.cert_file = $alist_cert0 |
    .scheme.key_file = $alist_key0 |
    .temp_dir = $alist_temp0 |
    .bleve_dir = $alist_bleve0 |
    .log.enable = $log_enable0 |
    .log.name = $log_name0 |
    .log.max_size = $log_size0 |
    .log.max_backups = 1 |
    .log.max_age = 1 |
    .log.compress = $log_compress0 |
    .delayed_start = $delayed0 |
    .max_connections = $connections0 |
    .s3.enable = $alist_s30 |
    .s3.port = $s3_port0 |
    .s3.ssl = $s3_ssl0' \
   "$json" > /tmp/alist.config.json

	if [ "$(cat $json | tr -d ' ' | tr -d '\n')" != "$(cat /tmp/alist.config.json | tr -d ' ' | tr -d '\n')" ] ; then
		logger -t "Alist" "参数变动，写入配置文件 $json "
		echo -e "###旧配置：\n $(cat $json)\n" >>/tmp/alist.log
		echo -e "###新配置：\n $(cat /tmp/alist.config.json)\n" >>/tmp/alist.log
		cp -f /tmp/alist.config.json $json
	fi
}

start_al() {
	[ "$alist_enable" = "1" ] || exit 1
	logger -t "Alist" "正在启动alist"
	echo "正在启动alist" >/tmp/alist.log
	sed -Ei '/【Alist】|^$/d' /tmp/script/_opt_script_check
	get_tag
	
 	if [ ! -f "$alist" ] ; then
		logger -t "Alist" "主程序${alist}不存在，开始在线下载..."
  		[ ! -d /etc/storage/bin ] && mkdir -p /etc/storage/bin
  		[ -z "$tag" ] && tag="v3.39.4"
  		dowload_al $tag
  	fi
  	[ ! -f "$alist" ] && exit 1
	kill_al
	[ ! -x "$alist" ] && chmod +x $alist
	[ $(($($alist -h | wc -l))) -lt 3 ] && logger -t "Alist" "程序${alist}不完整，无法运行！" && exit 1
	jq_test="$(which jq)"
	[ -z "$jq_test" ] && logger -t "Alist" "缺少依赖程序 jq ，请下载 https://opt.cn2qq.com/opt-file/jq 后上传到/etc/storage/bin/jq 再运行." && exit 1
	if [ -z "$db_file" ] ; then
		db_file="/etc/storage/alist/data.db"
		nvram set alist_db_file="$db_file"
	fi
	db_path=$(dirname "$db_file")
	[ ! -d "$db_path" ] && mkdir -p "$db_path"
	json="${db_path}/config.json"
	"$alist" admin >/tmp/var/admin.account 2>&1
	user=$(cat /tmp/var/admin.account | grep "username" | awk -F 'username:' '{print $2}' | tr -d " ")
    	pass=$(cat /tmp/var/admin.account | grep "password is" | awk -F 'password is:' '{print $2}' | tr -d " ")
    	[ ! -z "$pass" ] && logger -t "Alist" "检测到首次安装，初始用户名： ${user}  初始密码： ${pass}  请登录后台及时修改"
    	[ ! -d /etc/storage/alist ] && mkdir -p /etc/storage/alist
    	set_json
	cmd="${alist} server --data ${db_path}"
	logger -t "Alist" "运行${cmd}"
	eval "$cmd >>/tmp/alist.log 2>&1" &
	sleep 4
	if [ ! -z "`pidof alist`" ] ; then
		logger -t "Alist" "运行成功！"
		al_keep
	else
		logger -t "Alist" "运行失败！"
	fi
	exit 0
}
kill_al() {
	al_process=$(pidof alist)
	rm -rf /tmp/alist.log
	if [ -n "$al_process" ]; then
		logger -t "Alist" "有进程 $al_proces 在运行，结束中..."
		killall alist >/dev/null 2>&1
	fi
}
stop_al() {
	logger -t "Alist" "正在关闭服务..."
	sed -Ei '/【Alist】|^$/d' /tmp/script/_opt_script_check
	scriptname=$(basename $0)
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	kill_al
	[ ! -z "`pidof alist`" ] && logger -t "Alist" "alist关闭成功!"
}

case $1 in
start)
	start_al &
	;;
stop)
	stop_al
	;;
restart)
	stop_al
	start_al &
	;;
update)
	update_al &
	;;
admin)
	db_path=$(dirname "$db_file")
	logger -t "Alist" "正在重置密码..."
	echo "正在重置密码..." >>/tmp/alist.log
	$alist admin set admin --data ${db_path} >/tmp/var/admin.account 2>&1
	user=$(cat /tmp/var/admin.account | grep "username" | awk -F 'username:' '{print $2}' | tr -d " " )
    	pass=$(cat /tmp/var/admin.account | grep "password" | awk -F 'password:' '{print $2}' | tr -d " ")
    	echo "新账号： ${user} 新密码： ${pass}" >>/tmp/alist.log
    	logger -t "Alist" "新账号： ${user} 新密码： ${pass} "
	echo "新账号： ${user} 新密码： ${pass}"
	;;
*)
	echo "check"
	#exit 0
	;;
esac
