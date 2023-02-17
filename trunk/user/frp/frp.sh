#!/bin/sh
frpc_enable=`nvram get frpc_enable`
frps_enable=`nvram get frps_enable`
http_username=`nvram get http_username`

check_frp () 
{
	check_net
	result_net=$?
	if [ "$result_net" = "1" ] ;then
		if [ -z "`pidof frpc`" ] && [ "$frpc_enable" = "1" ];then
			frp_start
		fi
		if [ -z "`pidof frps`" ] && [ "$frps_enable" = "1" ];then
			frp_start
		fi
	fi
}

check_net() 
{
	/bin/ping -c 3 223.5.5.5 -w 5 >/dev/null 2>&1
	if [ "$?" == "0" ]; then
		return 1
	else
		return 2
		logger -t "frp" "检测到互联网未能成功访问,稍后再尝试启动frp"
	fi
}

frp_start () 
{
   cat /etc/storage/frp_script.sh|grep frp_ver=y >/dev/null
  if [ $? -eq 0 ] ; then
    frpnew_dl
    else
    frp_dl
    fi
}

frpnew_dl () 
{
   if [ "$frpc_enable" = "1" ] ;then
      logger -t "frp" "frpc正在启动..."
      if [ ! -f "/tmp/frpapp/frpc" ] ;then
        rm -rf /tmp/frpapp/frp_tmp
        mkdir -p /tmp/frpapp/frp_tmp
        logger -t "frp" "找不到 frpc 程序，自动下载最新版本"
        tag=$(curl -k --silent "https://api.github.com/repos/fatedier/frp/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        [ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
        [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 --silent https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
        [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 -s https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
          if [ ! -z "$tag" ] ; then
            logger -t "frp" "获取到最新版本 $tag ,下载较慢，耐心等待"
            tag="$(echo "$tag" | tr -d 'v' | tr -d ' ')"
            wgetcurl.sh "/tmp/frpapp/frp_tmp/frp_linux_mipsle.tar.gz" "https://github.com/fatedier/frp/releases/download/v""$tag""/frp_""$tag""_linux_mipsle.tar.gz"
            tar -xz -C  /tmp/frpapp/frp_tmp -f  /tmp/frpapp/frp_tmp/frp_linux_mipsle.tar.gz
            cp "/tmp/frpapp/frp_tmp/frp_""$tag""_linux_mipsle/frpc" /tmp/frpapp/frpc
            rm -rf /tmp/frpapp/frp_tmp
            chmod 777 /tmp/frpapp/frpc
            if [ ! -f "/tmp/frpapp/frpc" ] ;then
               logger -t "frp" "最新版本 v$tag 下载失败,再次尝试下载或版本选择frp_ver=n不使用新版"
               if [ "$frpc_enable" = "0" ] ;then
                   frp_close
               fi
               frp_close
               frp_start
               else
               logger -t "frp" "下载成功,程序将安装在内存，将会占用部分内存，请注意内存使用容量！"
            fi
         else
            logger -t "frp" "github最新版本获取失败！！！再次重试或版本选择frp_ver=n不使用新版"
            frp_start
         fi 
      fi  
   fi
   
  if [ "$frps_enable" = "1" ] ;then
        logger -t "frp" "frps正在启动..."
     if [ ! -f "/tmp/frpapp/frps" ] ;then
        rm -rf /tmp/frpapp/frp_tmp
        mkdir -p /tmp/frpapp/frp_tmp
        logger -t "frp" "找不到 frps 程序，自动下载最新版本"
        tag=$(curl -k --silent "https://api.github.com/repos/fatedier/frp/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        [ -z "$tag" ] && tag="$( curl -k -L --connect-timeout 20 --silent https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
        [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 --silent https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
        [ -z "$tag" ] && tag="$( curl -k --connect-timeout 20 -s https://api.github.com/repos/fatedier/frp/releases/latest | grep 'tag_name' | cut -d\" -f4 )"
          if [ ! -z "$tag" ] ; then 
            logger -t "frp" "获取到最新版本 $tag ,下载较慢，耐心等待"
            tag="$(echo "$tag" | tr -d 'v' | tr -d ' ')"
            wgetcurl.sh "/tmp/frpapp/frp_tmp/frp_linux_mipsle.tar.gz" "https://github.com/fatedier/frp/releases/download/v""$tag""/frp_""$tag""_linux_mipsle.tar.gz"
            tar -xz -C  /tmp/frpapp/frp_tmp -f  /tmp/frpapp/frp_tmp/frp_linux_mipsle.tar.gz
            cp "/tmp/frpapp/frp_tmp/frp_""$tag""_linux_mipsle/frps" /tmp/frpapp/frps
            rm -rf /tmp/frpapp/frp_tmp
            chmod 777 /tmp/frpapp/frps
            if [ ! -f "/tmp/frpapp/frps" ] ;then
               logger -t "frp" "最新版本 v$tag 下载失败,也可版本选择frp_ver=n不使用新版,再次尝试"
               if [ "$frps_enable" = "0" ] ;then
                   frp_close
               fi
               frp_close
               frp_start 
               else
               logger -t "frp" "下载成功,程序将安装在内存，将会占用部分内存，请注意内存使用容量！"
            fi
           else
            logger -t "frp" "github最新版本获取失败！！！也可版本选择frp_ver=n不使用新版,再次重试"
            frp_start
          fi
        fi
      fi
      
       /etc/storage/frp_script.sh
	sed -i '/frp/d' /etc/storage/cron/crontabs/$http_username
	cat >> /etc/storage/cron/crontabs/$http_username << EOF
*/1 * * * * /bin/sh /usr/bin/frp.sh C >/dev/null 2>&1
EOF
	[ ! -z "`pidof frpc`" ] && logger -t "frp" "frpc启动成功"
	[ ! -z "`pidof frps`" ] && logger -t "frp" "frps启动成功"
}
      
frp_dl () 
{
   if [ "$frpc_enable" = "1" ] ;then
      logger -t "frp" "frpc正在启动..."
      if [ ! -f "/tmp/frpapp/frpc" ] ;then
        rm -rf /tmp/frpapp/frp_tmp
        mkdir -p /tmp/frpapp/frp_tmp    
        logger -t "frp" "找不到 frpc 程序，下载frpc程序"
         wgetcurl.sh "/tmp/frpapp/frpc" "https://opt.cn2qq.com/opt-file/frpc" 
         if [ -f "/tmp/frpapp/frpc" ] ;then
            logger -t "frp" "程序将安装在内存，将会占用部分内存，请注意内存使用容量！"
            chmod 777 /tmp/frpapp/frpc
            else
            logger -t "frp" "下载失败,再次尝试下载"
                if [ "$frps_enable" = "0" ] ;then
                   frp_close
                fi
            frp_close
            frp_start 
         fi 
      fi
    fi
    
   if [ "$frps_enable" = "1" ] ;then
       logger -t "frp" "frps正在启动..."
       if [ ! -f "/tmp/frpapp/frps" ] ;then
       rm -rf /tmp/frpapp/frp_tmp
       mkdir -p /tmp/frpapp/frp_tmp
       logger -t "frp" "找不到 frps 程序，下载frps程序"
       wgetcurl.sh "/tmp/frpapp/frps" "https://opt.cn2qq.com/opt-file/frps" 
          if [ -f "/tmp/frpapp/frps" ] ;then
               logger -t "frp" "程序将安装在内存，将会占用部分内存，请注意内存使用容量！"
               chmod 777 /tmp/frpapp/frpcs
               else
                logger -t "frp" "下载失败,再次尝试下载"
                if [ "$frps_enable" = "0" ] ;then
                   frp_close
                fi
            frp_close
            frp_start
          fi 
       fi
  fi   
   
   /etc/storage/frp_script.sh
	sed -i '/frp/d' /etc/storage/cron/crontabs/$http_username
	cat >> /etc/storage/cron/crontabs/$http_username << EOF
*/1 * * * * /bin/sh /usr/bin/frp.sh C >/dev/null 2>&1
EOF
	[ ! -z "`pidof frpc`" ] && logger -t "frp" "frpc启动成功"
	[ ! -z "`pidof frps`" ] && logger -t "frp" "frps启动成功"
}

frp_close () 
{

	if [ "$frpc_enable" = "0" ]; then
		if [ ! -z "`pidof frpc`" ]; then
		killall frpc
		killall -9 frpc frp_script.sh
               rm -rf /tmp/frpapp/frpc
		[ -z "`pidof frpc`" ] && logger -t "frp" "已停止 frpc"
	    fi
	fi
	if [ "$frps_enable" = "0" ]; then
		if [ ! -z "`pidof frps`" ]; then
		killall frps
		killall -9 frps frp_script.sh
                rm -rf /tmp/frpapp/frps
		[ -z "`pidof frps`" ] && logger -t "frp" "已停止 frps"
	    fi
	fi
	if [ "$frpc_enable" = "0" ] && [ "$frps_enable" = "0" ]; then
	sed -i '/frp/d' /etc/storage/cron/crontabs/$http_username
    fi
}


case $1 in
start)
	frp_start
	;;
stop)
	frp_close
	;;
C)
	check_frp
	;;
esac
