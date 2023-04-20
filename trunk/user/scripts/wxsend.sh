#!/bin/bash
#copyright by hiboy
wxsend_appid=$(cat /etc/storage/post_wan_script.sh | grep "wx_appid=" | awk '{print $2}')
wxsend_appsecret=$(cat /etc/storage/post_wan_script.sh | grep "wx_appsecret=" | awk '{print $2}')
wxsend_touser=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_touser=" | awk '{print $2}')
wxsend_template_id=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_template_id=" | awk '{print $2}')
wxsend_notify_1=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_1=" | awk '{print $2}')
wxsend_notify_2=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_2=" | awk '{print $2}')
wxsend_notify_3=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_3=" | awk '{print $2}')
wxsend_notify_4=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_4=" | awk '{print $2}')
wxtime=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_time=" | awk '{print $2}')
[ -z "$wxtime" ] && wxtime=60
data="$(date "+%G-%m-%d_%H:%M:%S")"

get_token () {
touch /tmp/wx_access_token
access_token="$(cat /tmp/wx_access_token)"
http_type="$(curl -L -k "https://api.weixin.qq.com/cgi-bin/get_api_domain_ip?access_token=$access_token")"
get_api_domain="$(echo $http_type | grep ip_list)"
if [ ! -z "$get_api_domain" ] ; then
echo "Access token 有效"
else
http_type="$(curl -L -k "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$wxsend_appid&secret=$wxsend_appsecret")"
access_token="$(echo $http_type | grep -o "\"access_token\":\"[^\,\"\}]*" | awk -F 'access_token":"' '{print $2}')"
if [ ! -z "$access_token" ] ; then
expires_in="$(echo $http_type | grep -o "\"expires_in\":[^\,\"\}]*" | awk -F 'expires_in":' '{print $2}')"
logger -t "【微信推送】" "获取 Access token 成功，凭证有效时间，单位： $expires_in 秒"
echo -n "$access_token" > /tmp/wx_access_token
else
errcode="$(echo $http_type | grep -o "\"errcode\":[^\,\"\}]*" | awk -F ':' '{print $2}')"
if [ ! -z "$errcode" ] ; then
errmsg="$(echo $http_type | grep -o "\"errmsg\":\"[^\,\"\}]*" | awk -F 'errmsg":"' '{print $2}')"
logger -t "【微信推送】" "获取 Access token 返回错误码: $errcode"
logger -t "【微信推送】" "错误信息: $errmsg"
access_token=""
echo -n "" > /tmp/wx_access_token
fi
fi
fi
}

send_message () {
get_token
access_token="$(cat /tmp/wx_access_token)"
if [ ! -z "$access_token" ] ; then
curl -k -H "Content-type: application/json;charset=UTF-8" -H "Accept: application/json" -H "Cache-Control: no-cache" -H "Pragma: no-cache" -X POST -d '{"touser":"'"$wxsend_touser"'","template_id":"'"$wxsend_template_id"'","data":{"title":{"value":"'"$1 $data "'"},"content":{"value":"'"$2"'"}}}' "https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=$access_token"
logger -t "【微信推送】" "推送成功==$1 $2"
else
logger -t "【微信推送】" "推送失败，获取 Access token 错误，请看看哪里问题？"
fi
}

wxsend_restart () {
killall wxsendfile.sh
killall -9 wxsendfile.sh
[ -z "$(ps -w | grep "wxsendfile.sh" | grep -v grep )" ] && logger -t "【微信推送】" "重新启动"
initconfig
exit 0
}

wxsend_keep () {
logger -t "【微信推送】" "守护进程启动"
cronset '#微信推送守护进程' "*/1 * * * * test -z \"\$(pidof wxsendfile.sh)\" && wxsend.sh restart #微信推送进程"

}

cronset(){
	tmpcron=/tmp/cron_$USER
	croncmd -l > $tmpcron 
	sed -i "/$1/d" $tmpcron
	sed -i '/^$/d' $tmpcron
	echo "$2" >> $tmpcron
	croncmd $tmpcron
	rm -f $tmpcron
}
croncmd(){
	if [ -n "$(crontab -h 2>&1 | grep '\-l')" ];then
		crontab $1
	else
		crondir="/etc/storage/cron/crontabs"
		[ "$1" = "-l" ] && cat $crondir/$USER 2>/dev/null
		[ -f "$1" ] && cat $1 > $crondir/$USER
	fi
}

wxsend_close () {
cronset "微信推送守护进程"
killall wxsendfile.sh
killall -9 wxsendfile.sh
sleep 4
rm -rf /etc/storage/wxsendfile.sh
[ -z "$(ps -w | grep "wxsendfile.sh" | grep -v grep )" ] && logger -t "【微信推送】" "进程已关闭"
}

wxsend_start () {
killall wxsendfile.sh
killall -9 wxsendfile.sh
[ -z "$wxsend_appid" ] || [ -z "$wxsend_appsecret" ] || [ -z "$wxsend_touser" ] || [ -z "$wxsend_template_id" ] && { logger -t "【微信推送】" "启动失败, 注意检查微信推送id参数是否完填写整,10 秒后自动尝试重新启动" && sleep 10 && wxsend_restart ; }
logger -t "【微信推送】" "运行 /etc/storage/wxsendfile.sh"
/etc/storage/wxsendfile.sh &
sleep 3
[ ! -z "$(ps -w | grep "wxsendfile.sh" | grep -v grep )" ] && logger -t "【微信推送】" "启动成功" && wxsend_keep
[ -z "$(ps -w | grep "wxsendfile.sh" | grep -v grep )" ] && logger -t "【微信推送】" "启动失败, 注意检查wxsendfile.sh脚本,10 秒后尝试重新启动" && sleep 10 && wxsend_restart 
exit 0
}

initconfig () {

app_30="/etc/storage/wxsendfile.sh"
if [ ! -f "$app_30" ] || [ ! -s "$app_30" ] ; then
	cat > "$app_30" <<-\EEE
#!/bin/bash
# 自定义推送内容，修改最下方的
# 系统管理 - 服务 - 调度任务(Crontab)，可自定义开启\关闭时间
export PATH='/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
wxsend_notify_1=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_1=" | awk '{print $2}')
wxsend_notify_2=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_2=" | awk '{print $2}')
wxsend_notify_3=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_3=" | awk '{print $2}')
wxsend_notify_4=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_4=" | awk '{print $2}')
wxsend_notify_4=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_4=" | awk '{print $2}')
wxtime=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_time=" | awk '{print $2}')
mkdir -p /tmp/var
resub=1
resub=1
# 获得外网地址v4
    arIpAddress4() {
    curltest=`which curl`
    if [ -z "$curltest" ] || [ ! -s "/usr/bin/curl" ] ; then
	wget -qO- http://ipecho.net/plain | xargs echo
    else
	curl -4 -k https://ifconfig.co/ip
    fi
    }
# 读取最近外网地址v4
    lastIPAddress4() {
        [ ! -e "/etc/storage/wxsend_lastIPAddress4" ] && touch /etc/storage/wxsend_lastIPAddress4
        inter4="/etc/storage/wxsend_lastIPAddress4"
        cat $inter4
    }
 # 获得外网地址v6
    arIpAddress6() {
    curltest=`which curl`
    if [ -z "$curltest" ] || [ ! -s "/usr/bin/curl" ] ; then
        wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://ipv6.icanhazip.com"
    else
        curl -L -k --user-agent "$user_agent" -s "https://ipv6.icanhazip.com"
    fi
    }
# 读取最近外网地址v6
    lastIPAddress6() {
        [ ! -e "/etc/storage/wxsend_lastIPAddress6" ] && touch /etc/storage/wxsend_lastIPAddress6
        inter6="/etc/storage/wxsend_lastIPAddress6"
        cat $inter6
    }

while [ "1" = "1" ];
do
wxsend_notify_1=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_1=" | awk '{print $2}')
wxsend_notify_2=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_2=" | awk '{print $2}')
wxsend_notify_3=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_3=" | awk '{print $2}')
wxsend_notify_4=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_notify_4=" | awk '{print $2}')
wxtime=$(cat /etc/storage/post_wan_script.sh | grep "wxsend_time=" | awk '{print $2}')
[ -z "$wxtime" ] && wxtime=60
ping_text=`ping -4 223.5.5.5 -c 1 -w 2 -q`
ping_time=`echo $ping_text | awk -F '/' '{print $4}'| awk -F '.' '{print $1}'`
ping_loss=`echo $ping_text | awk -F ', ' '{print $3}' | awk '{print $1}'`
if [ ! -z "$ping_time" ] ; then
    echo "ping：$ping_time ms 丢包率：$ping_loss"
 else
    echo "ping：失效"
fi
if [ ! -z "$ping_time" ] ; then
echo "online"
if [ "$wxsend_notify_1" = "1" ] ; then
   #WAN口IP变动推送
    hostIP4=$(arIpAddress4)
    hostIP6=$(arIpAddress6)
    #hostIP=`echo $hostIP | head -n1 | cut -d' ' -f1`
    if [ "$hostIP4"x = "x"  ] ; then
        curltest=`which curl`
        if [ -z "$curltest" ] || [ ! -s "/usr/bin/curl" ] ; then
            [ "$hostIP4"x = "x"  ] && hostIP4=`wget -qO- http://ipecho.net/plain | xargs echo`
        else
            [ "$hostIP4"x = "x"  ] && hostIP4=`curl -4 -k https://ifconfig.co/ip`
        fi
    fi
    if [ "$hostIP6"x = "x"  ] ; then
        curltest=`which curl`
        if [ -z "$curltest" ] || [ ! -s "/usr/bin/curl" ] ; then
            [ "$hostIP6"x = "x"  ] && hostIP6=` wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://ipv6.icanhazip.com"`
        else
            [ "$hostIP6"x = "x"  ] && hostIP6=`curl -L -k --user-agent "$user_agent" -s "https://ipv6.icanhazip.com"`
        fi
    fi
    lastIP4=$(lastIPAddress4)
    lastIP6=$(lastIPAddress6)
    if [ "$lastIP4" != "$hostIP4" ] && [ ! -z "$hostIP4" ] ; then
    sleep 60
        hostIP4=$(arIpAddress4)
        #hostIP4=`echo $hostIP4 | head -n1 | cut -d' ' -f1`
        lastIP4=$(lastIPAddress4)
    fi
    if [ "$lastIP4" != "$hostIP4" ] && [ ! -z "$hostIP4" ] ; then
        /etc/storage/wxsend.sh send_message "【WAN口IPV4变动】" "目前 IP: ${hostIP4}  上次 IP: ${lastIP4}" &
        echo -n $hostIP4 > /etc/storage/wxsend_lastIPAddress4
    fi
    if [ "$lastIP6" != "$hostIP6" ] && [ ! -z "$hostIP6" ] ; then
    sleep 60
        hostIP6=$(arIpAddress6)
        #hostIP6=`echo $hostIP6 | head -n1 | cut -d' ' -f1`
        lastIP6=$(lastIPAddress6)
    fi
    if [ "$lastIP6" != "$hostIP6" ] && [ ! -z "$hostIP6" ] ; then
        /etc/storage/wxsend.sh send_message "【WAN口IPV6变动】" "目前 IP: ${hostIP6}  上次 IP: ${lastIP6}" &
        echo -n $hostIP6 > /etc/storage/wxsend_lastIPAddress6
    fi
fi
if [ "$wxsend_notify_2" = "1" ] ; then
    # 设备接入提醒
    # 获取接入设备名称
    touch /tmp/var/wxsend_newhostname.txt
    echo "接入设备名称" > /tmp/var/wxsend_newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/wxsend_newhostname.txt
    cat /tmp/static_ip.inf | grep -v "^$" | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/wxsend_newhostname.txt
    # 读取以往接入设备名称
    touch /etc/storage/wxsend_hostname.txt
    [ ! -s /etc/storage/wxsend_hostname.txt ] && echo "接入设备名称" > /etc/storage/wxsend_hostname.txt
    # 获取新接入设备名称
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/wxsend_hostname.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname相同行.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname相同行.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname不重复.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复.txt | grep -v "^$"`
         /etc/storage/wxsend.sh send_message "【新设备加入】" "${content}" &
         cat /tmp/var/wxsend_newhostname不重复.txt | grep -v "^$" >> /etc/storage/wxsend_hostname.txt
    fi
fi
if [ "$wxsend_notify_3" = "1" ] ; then
    # 设备上、下线提醒
    # 获取接入设备名称
    touch /tmp/var/wxsend_newhostname.txt
    echo "接入设备名称" > /tmp/var/wxsend_newhostname.txt
    #cat /tmp/syslog.log | grep 'Found new hostname' | awk '{print $7" "$8}' >> /tmp/var/wxsend_newhostname.txt
    cat /tmp/static_ip.inf | grep -v "^$" | awk -F "," '{ if ( $6 == 0 ) print "【内网IP："$1"，ＭＡＣ："$2"，名称："$3"】  "}' >> /tmp/var/wxsend_newhostname.txt
    # 读取以往上线设备名称
    touch /etc/storage/wxsend_hostname_上线.txt
    [ ! -s /etc/storage/wxsend_hostname_上线.txt ] && echo "接入设备名称" > /etc/storage/wxsend_hostname_上线.txt
    # 上线
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/wxsend_hostname_上线.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname相同行_上线.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname相同行_上线.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname不重复_上线.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复_上线.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复_上线.txt | grep -v "^$"`
        /etc/storage/wxsend.sh send_message "【设备上线】" "${content}" &
        cat /tmp/var/wxsend_newhostname不重复_上线.txt | grep -v "^$" >> /etc/storage/wxsend_hostname_上线.txt
    fi
    # 下线
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname.txt /etc/storage/wxsend_hostname_上线.txt > /tmp/var/wxsend_newhostname不重复_下线.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复_下线.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复_下线.txt | grep -v "^$"`
        /etc/storage/wxsend.sh send_message "【设备下线】" "${content}" &
        cat /tmp/var/wxsend_newhostname.txt | grep -v "^$" > /etc/storage/wxsend_hostname_上线.txt
    fi
fi
if [ "$wxsend_notify_4" = "1" ] ; then
    # 自定义提醒推送



        /etc/storage/wxsend.sh send_message "【自定义推送标题】" "自定义推送内容" &
        
fi

    resub=`expr $resub + 1`
    [ "$resub" -gt 360 ] && resub=1
else
echo "Internet down 互联网断线"
resub=1
fi
sleep $wxtime
continue
done

EEE
	chmod 755 "$app_30"
fi
wxsend_start
}

case $1 in
send_message)
	send_message "$2" "$3"
	;;
start)
	initconfig
	;;
restart)
	wxsend_restart
	;;
stop)
	wxsend_close
	;;
keep)
	wxsend_keep
	;;
*)
	initconfig
	;;
esac
