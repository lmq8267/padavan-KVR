#!/bin/sh

#文件服务器目录
caddy_browser_path=`nvram get caddy_storage`
#程序路径
caddy=`nvram get caddy_dir`
#程序选择
caddy_mode=`nvram get caddy_file`
#browser文件服务器端口
caddy_browser_port=`nvram get caddyf_wan_port`
[ -z "$caddy_browser_port" ] && caddy_browser_port="12101" && nvram set caddyf_wan_port=$caddy_browser_port
#browser文件服务器用户名
caddy_fname=`nvram get caddy_Fname`
#browser文件服务器密码
caddy_fpassword=`nvram get caddy_Fpassword`

#webdav目录
caddy_webdav_path=`nvram get caddy_webdav`
#webdav端口
caddyw_wan_port=`nvram get caddyw_wan_port`
[ -z "$caddyw_wan_port" ] && caddyw_wan_port="12102" && nvram set caddyw_wan_port=$caddyw_wan_port
#webdav用户名
caddy_wname=`nvram get caddy_wname`
#webdav密码
caddy_wpassword=`nvram get caddy_wpassword`

#生成的配置文件路径
caddyfile="/tmp/Caddyfile"
file_path=$(dirname "$caddyfile")
[ ! -d "$file_path" ] && mkdir -p "$file_path"

#旧版caddy_filebrowser配置
if [ "$caddy_mode" = "0" ] || [ "$caddy_mode" = "1" ] || [ "$caddy_mode" = "2" ] ; then
#配置browser文件服务器
logger -t "【caddy】" "创建caddy_filebrowser的browser文件服务器配置..."
if [ "$caddy_mode" = "0" ] || [ "$caddy_mode" = "2" ] ; then
cat <<-EOF >/tmp/cf
:$caddyf_wan_port {
 root $caddy_browser_path
 timeouts none
 gzip
 filebrowser / $caddy_browser_path {
  database /etc/storage/caddy_filebrowser.db
 }
}
EOF
fi
#配置webdav
if [ "$caddy_mode" = "1" ] || [ "$caddy_mode" = "2" ] ; then
logger -t "【caddy】" "创建caddy_filebrowser的WebDav配置..."
cat <<-EOF >/tmp/cw
:$caddyw_wan_port {
root $caddy_webdav_path
timeouts none
browse
gzip
filebrowser /document $caddy_webdav_path {
  database /etc/storage/caddy_filebrowser.db
}
basicauth / $caddy_wname $caddy_wpassword
webdav /disk {
    scope $caddy_webdav_path
    allow $caddy_webdav_path 
}
}
EOF
fi
logger -t "【caddy】" "生成配置文件${caddyfile}"
cat /tmp/cw /tmp/cf > $caddyfile
rm -f /tmp/cw
rm -f /tmp/cf
logger -t "【caddy】" "运行${caddy} -conf ${caddyfile}"
$caddy -conf $caddyfile >/tmp/caddy.log 2>&1 &

fi

#新版caddy v2配置
if [ "$caddy_mode" = "3" ] || [ "$caddy_mode" = "4" ] || [ "$caddy_mode" = "5" ] ; then
#配置browser文件服务器
if [ "$caddy_mode" = "3" ] || [ "$caddy_mode" = "5" ] ; then
logger -t "【caddy】" "创建caddy的browser文件服务器配置..."
if [ ! -z "$caddy_fname" ] && [ ! -z "$caddy_fpassword" ] ; then
	      filepassword="$($caddy hash-password --plaintext $caddy_fpassword)"
	      filebasicauth="basicauth {
$caddy_fname $filepassword
}"
fi
cat <<-EOF >/tmp/cf

:$caddy_browser_port {
$filebasicauth
 root * $caddy_browser_path
 file_server browse
 
header {
                Content-Type "charset=utf-8"
        }
}

EOF
fi
#配置webdav
if [ "$caddy_mode" = "4" ] || [ "$caddy_mode" = "5" ] ; then
logger -t "【caddy】" "创建caddy的WebDav配置..."
orderweb="order webdav before file_server # 启动 webdav 模块"
if [ ! -z "$caddy_wname" ] && [ ! -z "$caddy_wpassword" ] ; then
	      davpassword="$($caddy hash-password --plaintext $caddy_wpassword)"
	      davbasicauth="basicauth {
$caddy_wname $davpassword
}"
fi
cat <<-EOF >/tmp/cw

:$caddyw_wan_port {
$davbasicauth
webdav * {
#挂载webdav需要添加/dav后缀
prefix /dav
root $caddy_webdav_path
  }
}

EOF
fi
cat <<-EOF >/tmp/fw

{ # 全局配置
order cgi before respond # 启动 cgi 模块
$orderweb
admin off # 关闭 API 端口
}

EOF
logger -t "【caddy】" "生成配置文件${caddyfile}..."
cat /tmp/fw /tmp/cw /tmp/cf > $caddyfile
rm -f /tmp/fw
rm -f /tmp/cw
rm -f /tmp/cf
#整理配置文件
$caddy fmt --overwrite $caddyfile
#判断配置文件是否正确，通过系统日志查看 错误会提示哪里有问题
logger -t "【caddy】" "检测配置文件格式是否正确..."
$caddy validate --config $caddyfile --adapter caddyfile 2>&1 | while IFS= read -r line; do
    logger -t "【caddy】" "$line"
done

#启动
logger -t "【caddy】" "运行${caddy} run --config ${caddyfile} --adapter caddyfile"
$caddy run --config $caddyfile --adapter caddyfile >/tmp/caddy.log 2>&1 &

fi

