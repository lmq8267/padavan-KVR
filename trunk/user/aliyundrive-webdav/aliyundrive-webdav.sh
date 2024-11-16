#!/bin/sh

github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "

dl_ald() {
	[ ! -f /usr/bin/aliyundrive-webdav ] && aliyun=/etc/storage/bin/aliyundrive-webdav
	[ ! -f /usr/bin/aliyundrive-webdav ] && aliyun=/tmp/var/aliyundrive-webdav
	
	logger -t "【阿里云盘】" "找不到 /etc/storage/bin/aliyundrive-webdav ，下载 阿里云盘 程序"
	if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
      		tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
	 	[ -z "$tag" ] && tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=-  https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
    	else
      		tag="$( curl --connect-timeout 3 --user-agent "$user_agent"  https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest 2>&1 | grep 'tag_name' | cut -d\" -f4 )"
       	[ -z "$tag" ] && tag="$( curl -L --connect-timeout 3 --user-agent "$user_agent" -s  https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest  2>&1 | grep 'tag_name' | cut -d\" -f4 )"
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
	aliyun=/tmp/var/aliyundrive-webdav
    	logger -t "【阿里云盘】" "程序安装在内存，将会占用部分内存，请注意内存使用容量！"
	 chmod +x $aliyun
}

start_ald() {
   logger -t "【阿里云盘】" "正在启动..."
   mkdir -p /tmp/aliyundrive
   [ ! -f /usr/bin/aliyundrive-webdav ] && [ -f /etc/storage/bin/aliyundrive-webdav ] && aliyun="/etc/storage/bin/aliyundrive-webdav"
   [ ! -f "$aliyun" ] && [ -f /tmp/var/aliyundrive-webdav ] && aliyun=/tmp/var/aliyundrive-webdav
   [ ! -x "$aliyun" ] && chmod +x $aliyun
   if [ ! -f "$aliyun" ] || [ $(($($aliyun -h | wc -l))) -lt 3 ] ; then
  	dl_ald
   fi
   NAME=aliyundrive-webdav
   aliyun=$aliyun
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
	  ;;
    *)
      kill_ald ;;
  esac

}
kill_ald() {
        rm -rf /tmp/aliyundrive
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
