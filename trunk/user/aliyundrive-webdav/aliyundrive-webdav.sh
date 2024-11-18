#!/bin/sh

user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "


find_bin() {
dirs="/etc/storage/bin
/tmp/var
/usr/bin"

aliyun=""
for dir in $dirs ; do
    if [ -f "$dir/aliyundrive-webdav" ] ; then
        aliyun="$dir/aliyundrive-webdav"
        break
    fi
done
[ -z "$aliyun" ] && aliyun="/tmp/var/aliyundrive-webdav"
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
 		for proxy in $github_proxys ; do
       		curl -Lkso "/tmp/aliyundrive/aliyundrive.tar.gz" "${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz" || wget --no-check-certificate -q -O "/tmp/aliyundrive/aliyundrive.tar.gz" "${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz"
			if [ "$?" = 0 ] ; then
				tar -xzvf /tmp/aliyundrive/aliyundrive.tar.gz -C /tmp/var
				rm -rf /tmp/aliyundrive/aliyundrive.tar.gz
				chmod +x /tmp/var/aliyundrive-webdav
				if [ $(($(/tmp/var/aliyundrive-webdav -h | wc -l))) -gt 3 ] ; then
					logger -t "【阿里云盘】" "/tmp/var/aliyundrive-webdav 下载成功"
					break
       			else
	   				logger -t "【阿里云盘】" "下载不完整，请手动下载 ${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz 上传到  /tmp/var/aliyundrive-webdav 或 /etc/storage/bin/aliyundrive-webdav"
					rm -f /tmp/var/aliyundrive-webdav
	  			fi
			else
				logger -t "【阿里云盘】" "下载失败，请手动下载 ${proxy}https://github.com/messense/aliyundrive-webdav/releases/download/${tag}/aliyundrive-webdav-${tag}.mipsel-unknown-linux-musl.tar.gz 解压上传到  /tmp/var/aliyundrive-webdav 或 /etc/storage/bin/aliyundrive-webdav"
   			fi
		done
	fi
	aliyun="/tmp/var/aliyundrive-webdav"
    	logger -t "【阿里云盘】" "程序安装在内存，将会占用部分内存，请注意内存使用容量！"
	 chmod +x $aliyun
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
   if [ ! -f "$aliyun" ] || [ $(($($aliyun -h | wc -l))) -lt 3 ] ; then
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
      [ ! -z "`pidof aliyundrive-webdav`" ] && logger -t "【阿里云盘】" "启动成功" && ald_keep
	  ;;
    *)
      kill_ald ;;
  esac

}
kill_ald() {
        rm -rf /tmp/aliyundrive
        sed -Ei '/【阿里云盘】|^$/d' /tmp/script/_opt_script_check
        scriptname=$(basename $0)
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
	aliyundrive_process=$(pidof aliyundrive-webdav)
	if [ -n "$aliyundrive_process" ]; then
		logger -t "【阿里云盘】" "关闭进程..."
		killall aliyundrive-webdav >/dev/null 2>&1
		kill -9 "$aliyundrive_process" >/dev/null 2>&1
               
	fi
}
stop_ald() {
	kill_ald
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
	stop_ald
	;;
*)
	check_ald &
	;;
esac
