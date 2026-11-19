#!/bin/sh
#from hiboy
export PATH='/etc/storage/bin:/tmp/frp:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
killall frpc frps
mkdir -p /tmp/frp
#启动frp功能后会运行以下脚本
#frp项目地址教程: https://github.com/fatedier/frp/blob/master/README_zh.md
#请自行修改 token 用于对客户端连接进行身份验证
# IP查询： http://119.29.29.29/d?dn=github.com


cat > "/tmp/frp/myfrpc.toml" <<-\EOF
# ==========客户端配置：==========
serverAddr = "frps.com" # 远端frp服务器ip或域名
serverPort = 7000
auth.token = "12345"

loginFailExit = false
#log_file = "/tmp/frps.log"
#log_level = info
#log_max_days = 2

[[proxies]]
name = "web"
type = "http"
localIP = "192.168.2.1"
localPort = 80
subdomain = "test"
#hostHeaderRewrite = "test.frps.com" #实际你内网访问的域名，可以供公网的域名不一致，如果一致可以不写
# ====================
EOF

# 兼容旧模板：frp 0.52+ 的 TOML 没有 [common] 段，字段名也是 serverPort。
# 旧配置残留的 [common] 会让 serverAddr 等字段失效，实际连 0.0.0.0:7000；
# server_port 在 v0.72.0 会报 unknown field（2026-11-19 实测）。
sed -i -e '/^[[:space:]]*\[common\]/d' -e 's/^server_port[[:space:]]*=/serverPort =/' "/tmp/frp/myfrpc.toml"

#请手动配置【外部网络 (WAN) - 端口转发 (UPnP)】开启 WAN 外网端口
cat > "/tmp/frp/myfrps.toml" <<-\EOF
# ==========服务端配置：==========
bindAddr = "0.0.0.0"
bindPort = 7000
auth.token = "12345"
# webServer.addr = "127.0.0.1"
# webServer.port = 7500
# Dashboard 控制面板用户名密码，默认都为 admin
# webServer.user = "admin"
# webServer.password = "admin"
vhostHTTPPort = 88
subDomainHost = "frps.com"
transport.maxPoolCount = 50
#log.to = "/tmp/frps.log"
#log.level = "info"
#log.maxDays = 2
# ====================
EOF

#启动：
frpc_enable=`nvram get frpc_enable`
frpc_enable=${frpc_enable:-"0"}
frps_enable=`nvram get frps_enable`
frps_enable=${frps_enable:-"0"}
if [ "$frps_enable" = "1" ] ; then
    frps -c /tmp/frp/myfrps.toml >/tmp/frps.log 2>&1 &
fi
if [ "$frpc_enable" = "1" ] ; then
    [ "$frps_enable" = "1" ] && sleep 30
    frpc -c /tmp/frp/myfrpc.toml >/tmp/frpc.log 2>&1 &
fi
 
