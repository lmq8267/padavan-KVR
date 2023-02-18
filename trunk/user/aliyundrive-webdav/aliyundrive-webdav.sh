#!/bin/sh

dl_ald() {
   SVC_PATH="/tmp/aliyundrive/aliyundrive-webdav"
   if [ ! -s "$SVC_PATH" ] ; then
    logger -t "【阿里云盘】" "找不到 $SVC_PATH ，下载 阿里云盘 程序"
    tag=$(curl -k --silent "https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 -s https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
    [ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/messense/aliyundrive-webdav/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
    [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 --silent https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
    if [ ! -z "$tag" ] ; then
    logger -t "【阿里云盘】" "自动下载最新版本 $tag"
    logger -t "【阿里云盘】" "下载最新版本 $tag程序较慢，耐心等待"
    wgetcurl.sh "/tmp/aliyundrive/aliyundrive.tar.gz" "https://github.com/messense/aliyundrive-webdav/releases/download/$tag/aliyundrive-webdav-$tag.mipsel-unknown-linux-musl.tar.gz"
    tar -xzvf /tmp/aliyundrive/aliyundrive.tar.gz -C /tmp/aliyundrive
    rm -rf /tmp/aliyundrive/aliyundrive.tar.gz
    fi
    if [ ! -s "$SVC_PATH" ] && [ -d "/tmp/aliyundrive" ] ; then
    logger -t "【阿里云盘】" "最新版本 $tag下载失败"
    static_ald="https://github.com/messense/aliyundrive-webdav/releases/download/v1.10.6/aliyundrive-webdav-v1.10.6.mipsel-unknown-linux-musl.tar.gz"
    logger -t "【阿里云盘】" "开始下载 $static_ald"
    wgetcurl.sh "/tmp/aliyundrive/aliyundrive.tar.gz" "$static_ald"
    tar -xzvf /tmp/aliyundrive/aliyundrive.tar.gz -C /tmp/aliyundrive
    rm -rf /tmp/aliyundrive/aliyundrive.tar.gz
    fi
    if [ ! -s "$SVC_PATH" ] && [ -d "/tmp/aliyundrive" ] ; then
    logger -t "【阿里云盘】" "最新版本获取失败！！！"
    logger -t "【阿里云盘】" "开始下载备用程序https://github.com/vb1980/Padavan-KVR/main/trunk/user/aliyundrive-webdav/aliyundrive-webdav"
    wgetcurl.sh "/tmp/aliyundrive/aliyundrive-webdav" "https://github.com/vb1980/Padavan-KVR/main/trunk/user/aliyundrive-webdav/aliyundrive-webdav"
    fi
      enable=$(nvram get aliyundrive_enable)
      if [ "$enable" = "0" ] ;then
       kill_ald
        fi
    if [ ! -f "/tmp/aliyundrive/aliyundrive-webdav" ]; then
    logger -t "【阿里云盘】" "阿里云盘下载失败,再次尝试下载"
    kill_ald
    start_ald
    else
    logger -t "【阿里云盘】" "阿里云盘下载成功。"
    logger -t "【阿里云盘】" "程序将安装在内存，将会占用部分内存，请注意内存使用容量！"
    
    fi
  fi
    
  chmod 777 /tmp/aliyundrive/aliyundrive-webdav
}

start_ald() {
   logger -t "【阿里云盘】" "正在启动..."
   mkdir -p /tmp/aliyundrive
   if [ ! -f "/tmp/aliyundrive/aliyundrive-webdav" ]; then
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
	  
      /tmp/aliyundrive/$NAME $extra_options --host $host --port $port --root $root  --refresh-token $refresh_token -S $read_buf_size --cache-size $cache_size --cache-ttl $cache_ttl --workdir /tmp/$NAME >/dev/null 2>&1 &
	  ;;
    *)
      kill_ald ;;
  esac

}
kill_ald() {
        rm -rf /tmp/aliyundrive
	aliyundrive_process=$(pidof aliyundrive-webdav)
	if [ -n "$aliyundrive_process" ]; then
		logger -t "【阿里云盘】" "关闭进程..."
		killall aliyundrive-webdav
		killall aliyundrive-webdav >/dev/null 2>&1
		kill -9 "$aliyundrive_process" >/dev/null 2>&1
		killall /tmp/aliyundrive/aliyundrive-webdav
		killall -9 aliyundrive-webdav
               
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
	start_ald
	;;
stop)
	stop_ald
	;;
*)
	check_ald
	;;
esac
