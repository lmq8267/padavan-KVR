#!/bin/sh

#文件服务器目录
caddy_browser_path=`nvram get caddy_storage`
#程序路径
caddy=`nvram get caddy_dir`
#程序选择
caddy_mode=`nvram get caddy_file`
#browser文件服务器端口
caddy_browser_port=`nvram get caddyf_wan_port`
#browser文件服务器用户名
caddy_fname=`nvram get caddy_Fname`
#browser文件服务器密码
caddy_fpassword=`nvram get caddy_Fpassword`

#webdav目录
caddy_webdav_path=`nvram get caddy_webdav`
#webdav端口
caddyw_wan_port=`nvram get caddyw_wan_port`
#webdav用户名
caddy_wname=`nvram get caddy_wname`
#webdav密码
caddy_wpassword=`nvram get caddy_wpassword`

#生成的配置文件路径
caddyfile="/tmp/caddy/Caddyfile"
rm -f $caddyfile

#旧版caddy_filebrowser配置
if [ "$caddy_mode" = "0" ] || [ "$caddy_mode" = "1" ] || [ "$caddy_mode" = "2" ] ; then
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
if [ "$caddy_mode" = "1" ] || [ "$caddy_mode" = "2" ] ; then
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
cat /tmp/cw /tmp/cf > $caddyfile
rm -f /tmp/cw
rm -f /tmp/cf

$caddy -conf $caddyfile &

fi

#新版caddy v2配置
if [ "$caddy_mode" = "3" ] || [ "$caddy_mode" = "4" ] || [ "$caddy_mode" = "5" ] ; then
if [ "$caddy_mode" = "3" ] || [ "$caddy_mode" = "5" ] ; then
cat <<-EOF >/tmp/cf

配置

EOF
fi

if [ "$caddy_mode" = "4" ] || [ "$caddy_mode" = "5" ] ; then
cat <<-EOF >/tmp/cw

配置

EOF
fi
cat /tmp/cw /tmp/cf > $caddyfile
rm -f /tmp/cw
rm -f /tmp/cf

$caddy run

fi

