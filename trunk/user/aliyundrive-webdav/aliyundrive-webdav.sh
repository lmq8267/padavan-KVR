#!/bin/sh

user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "
ald_renum=`nvram get ald_renum`

ald_restart () {
relock="/var/lock/aliyundrive_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set ald_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	ald_renum=${ald_renum:-"0"}
	ald_renum=`expr $ald_renum + 1`
	nvram set ald_renum="$ald_renum"
	if [ "$ald_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【阿里云盘】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get ald_renum)" = "0" ] && break
   			#[ "$(nvram get aliyundrive_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set ald_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
start_ald
}

find_bin() {
aliyun="$(nvram get ald_bin)"
dirs="/etc/storage/bin
/tmp/var
/usr/bin"

if [ -z "$aliyun" ] ; then
  for dir in $dirs ; do
    if [ -f "$dir/aliyundrive-webdav" ] ; then
        aliyun="$dir/aliyundrive-webdav"
        break
    fi
  done
  [ -z "$aliyun" ] && aliyun="/tmp/var/aliyundrive-webdav"
fi
}


dl_ald() {
	logger -t "【阿里云盘】" "找不到 aliyundrive-webdav ，下载 阿里云盘 程序"
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --output-document=-  https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget --no-check-certificate -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl -k --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -Lk --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
        fi
        [ -z "$tag" ] && tag="v2.3.3"
	if [ ! -z "$tag" ] ; then
		logger -t "【阿里云盘】" "下载 $tag 下载较慢，耐心等待"
  		ali_path=$(dirname "$aliyun")
		[ ! -d "$ali_path" ] && mkdir -p "$ali_path"
 		for proxy in $github_proxys ; do
   		length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 		length=`expr $length + 512000`
		length=`expr $length / 1048576`
 		ald_size0="$(check_disk_size $aliyun)"
 		[ ! -z "$length" ] && logger -t "【阿里云盘】" "压缩包大小 ${length}M， 程序路径可用空间 ${ald_size0}M "
       		curl -Lko "/tmp/aliyundrive/aliyundrive.tar.gz" "${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz" || wget --no-check-certificate -O "/tmp/aliyundrive/aliyundrive.tar.gz" "${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz"
			if [ "$?" = 0 ] ; then
				tar -xzvf /tmp/aliyundrive/aliyundrive.tar.gz -C $ali_path
				rm -rf /tmp/aliyundrive/aliyundrive.tar.gz
				chmod +x $aliyun
				if [[ "$($aliyun -h 2>&1 | wc -l)" -gt 3 ]] ; then
					logger -t "【阿里云盘】" "/tmp/var/aliyundrive-webdav 下载成功"
					break
       				else
	   				logger -t "【阿里云盘】" "下载不完整，请手动下载 ${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz 上传到  $aliyun"
					#rm -f /tmp/var/aliyundrive-webdav
	  			fi
			else
				logger -t "【阿里云盘】" "下载失败，请手动下载 ${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz 解压上传到  $aliyun"
   			fi
		done
	fi
}

scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)

ald_keep() {
	logger -t "【阿里云盘】" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【阿里云盘】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof aliyundrive-webdav\`" ] && logger -t "进程守护" "阿里云盘 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【阿里云盘】|^$/d' /tmp/script/_opt_script_check #【阿里云盘】
	OSC

	fi

}

start_ald() {
   logger -t "【阿里云盘】" "正在启动..."
   sed -Ei '/【阿里云盘】|^$/d' /tmp/script/_opt_script_check
   mkdir -p /tmp/aliyundrive
   find_bin
   [ ! -x "$aliyun" ] && chmod +x $aliyun
   [[ "$($aliyun -h 2>&1 | wc -l)" -lt 2 ]] && rm $aliyun
   if [ ! -f "$aliyun" ] || [[ "$($aliyun -h 2>&1 | wc -l)" -lt 2 ]] ; then
  	dl_ald
   fi
   NAME=aliyundrive-webdav
   enable=$(nvram get aliyundrive_enable)
   case "$enable" in
    1|on|true|yes|enabled)
      refresh_token=$(nvram get ald_refresh_token)
      auth_user=$(nvram get ald_auth_user)
      auth_password=$(nvram get ald_auth_password)
      read_buf_size=$(nvram get ald_read_buffer_size)
      cache_size=$(nvram get ald_cache_size)
      cache_ttl=$(nvram get ald_cache_ttl)
      host=$(nvram get ald_host)
      port=$(nvram get ald_port)
      root=$(nvram get ald_root)
      domain_id=$(nvram get ald_domain_id)

      extra_options="-I"

      if [ "$domain_id" = "99999" ]; then
        extra_options="$extra_options --domain-id $domain_id"
      else
        case "$(nvram get ald_no_trash)" in
          1|on|true|yes|enabled)
            extra_options="$extra_options --no-trash"
            ;;
          *) ;;
        esac

        case "$(nvram get ald_read_only)" in
          1|on|true|yes|enabled)
            extra_options="$extra_options --read-only"
            ;;
          *) ;;
        esac
      fi
	  
      $aliyun $extra_options --host $host --port $port --root $root  --refresh-token $refresh_token -S $read_buf_size --cache-size $cache_size --cache-ttl $cache_ttl --workdir /tmp/$NAME >/dev/null 2>&1 &
      
      sleep 3
      if [ ! -z "`pidof aliyundrive-webdav`" ] ; then 
      	mem=$(cat /proc/$(pidof aliyundrive-webdav)/status | grep -w VmRSS | awk '{printf "%.1f MB", $2/1024}')
   	cpui="$(top -b -n1 | grep -E "$(pidof aliyundrive-webdav)" 2>/dev/null| grep -v grep | awk '{for (i=1;i<=NF;i++) {if ($i ~ /aliyundrive-webdav/) break; else cpu=i}} END {print $cpu}')"
	logger -t "【阿里云盘】" "启动成功" 
        logger -t "【阿里云盘】" "内存占用 ${mem} CPU占用 ${vntcpui}%"
	ald_restart o
        ald_keep
      else
      	logger -t "【阿里云盘】" "启动失败, 注意检查${aliyun}是否下载完整,10 秒后自动尝试重新启动" 
        sleep 10
	ald_restart x
      fi
	  ;;
    *)
      kill_ald ;;
  esac

}
kill_ald() {
        rm -rf /tmp/aliyundrive
        sed -Ei '/【阿里云盘】|^$/d' /tmp/script/_opt_script_check
        scriptname=$(basename $0)
	if [ ! -z "`pidof aliyundrive-webdav`" ]; then
		logger -t "【阿里云盘】" "关闭进程..."
		killall aliyundrive-webdav >/dev/null 2>&1
		kill -9 "$aliyundrive_process" >/dev/null 2>&1
               
	fi
 	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
}



check_ald() {
	ald_enable=$(nvram get aliyundrive_enable)
	if [ "$ald_enable" = "1" ] ;then
	start_ald 
	fi
	}


case $1 in
start)
	start_ald &
	;;
stop)
	kill_ald
	logger -t "【阿里云盘】" "已关闭"
	;;
*)
	check_ald &
	;;
esac
