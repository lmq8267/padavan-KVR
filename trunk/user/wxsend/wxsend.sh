#!/bin/bash
#copyright by hiboy

wxsend_enable=`nvram get wxsend_enable`
[ -z $wxsend_enable ] && wxsend_enable=0 && nvram set wxsend_enable=0
wxsend_appid=`nvram get wxsend_appid`
wxsend_appsecret=`nvram get wxsend_appsecret`
wxsend_touser=`nvram get wxsend_touser`
wxsend_template_id=`nvram get wxsend_template_id`

wxsend_title=`nvram get wxsend_title`
[ -z "$wxsend_title" ] && wxsend_title=`nvram get computer_name` && nvram set wxsend_title="$wxsend_title"
[ -z "$wxsend_title" ] && wxsend_title="Padavan" && nvram set wxsend_title="$wxsend_title"

if [ "$wxsend_enable" != "0" ] ; then
wxsend_notify_1=`nvram get wxsend_notify_1`
wxsend_notify_2=`nvram get wxsend_notify_2`
wxsend_notify_3=`nvram get wxsend_notify_3`
wxsend_notify_4=`nvram get wxsend_notify_4`
fi
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
wxsend_close () {
sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check
killall wxsend_script.sh >/dev/null 2>&1
sleep 2
[ -z "$(ps -w | grep "wxsend_script.sh" | grep -v grep )" ] && logger -t "【微信推送】" "进程已关闭"
}

wx_keep() {
	logger -t "【微信推送】" "守护进程启动"
	if [ -s /tmp/script/_opt_script_check ]; then
	sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check
	cat >> "/tmp/script/_opt_script_check" <<-OSC
	[ -z "\`pidof wxsend_script.sh\`" ] && logger -t "进程守护" "微信推送 进程掉线" && eval "$scriptfilepath start &" && sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check #【微信推送】
	OSC

	fi

}

wxsend_start () {
[ "$wxsend_enable" = "1" ] || exit 1
sed -Ei '/【微信推送】|^$/d' /tmp/script/_opt_script_check
killall wxsend_script.sh >/dev/null 2>&1
curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	logger -t "【微信推送】" "找不到 curl ，请安装 curl 程序"
	exit 1
fi
[ -z "$wxsend_appid" ] || [ -z "$wxsend_appsecret" ] || [ -z "$wxsend_touser" ] || [ -z "$wxsend_template_id" ] && { logger -t "【微信推送】" "启动失败, 注意检查[测试号信息]里的参数是否完填写整！" && exit 1 ; }
logger -t "【微信推送】" "运行 /etc/storage/wxsend_script.sh"
/etc/storage/wxsend_script.sh &
sleep 3
[ ! -z "$(ps -w | grep "wxsend_script.sh" | grep -v grep )" ] && logger -t "【微信推送】" "启动成功" && wx_keep
[ -z "$(ps -w | grep "wxsend_script.sh" | grep -v grep )" ] && logger -t "【微信推送】" "启动失败, 注意检查/etc/storage/wxsend_script.sh脚本是否有语法错误和curl是否下载完整"
exit 0
}

initconfig () {

wx_script="/etc/storage/wxsend_script.sh"
if [ ! -f "$wx_script" ] || [ ! -s "$wx_script" ] ; then
	cat > "$wx_script" <<-\EEE
#!/bin/bash
# 此脚本路径：/etc/storage/wxsend_script.sh
# 可通过计划任务自定义微信推送启动时间

wxsend_enable=`nvram get wxsend_enable`
wxsend_enable=${wxsend_enable:-"0"}
wxsend_notify_1=`nvram get wxsend_notify_1`
wxsend_notify_2=`nvram get wxsend_notify_2`
wxsend_notify_3=`nvram get wxsend_notify_3`
wxsend_notify_4=`nvram get wxsend_notify_4`
mkdir -p /tmp/var
resub=1
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
# 获得外网地址
    arIpAddress() {
    curltest=`which curl`
    if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://ddns.oray.com/checkip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    else
        #curl -L --user-agent "$user_agent" -s "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
        #curl -L --user-agent "$user_agent" -s http://ddns.oray.com/checkip | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1
    fi
    }
    arIpAddress6 () {
    # IPv6地址获取
    # 因为一般ipv6没有nat ipv6的获得可以本机获得
    #ifconfig $(nvram get wan0_ifname_t) | awk '/Global/{print $3}' | awk -F/ '{print $1}'
    if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
        wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://[2606:4700:4700::1002]/cdn-cgi/trace" | awk -F= '/ip/{print $2}'
        #wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "https://ipv6.icanhazip.com"
    else
        curl -6 -L --user-agent "$user_agent" -s "https://[2606:4700:4700::1002]/cdn-cgi/trace" | awk -F= '/ip/{print $2}'
        #curl -6 -L --user-agent "$user_agent" -s "https://ipv6.icanhazip.com"
    fi
    }
# 读取最近外网地址
    lastIPAddress() {
        inter="/etc/storage/wxsend_lastIPAddress"
        touch $inter
        cat $inter
    }
    lastIPAddress6() {
        inter="/etc/storage/wxsend_lastIPAddress6"
        touch $inter
        cat $inter
    }

while [ "$wxsend_enable" = "1" ];
do
wxsend_enable=`nvram get wxsend_enable`
wxsend_enable=${wxsend_enable:-"0"}
wxsend_notify_1=`nvram get wxsend_notify_1`
wxsend_notify_2=`nvram get wxsend_notify_2`
wxsend_notify_3=`nvram get wxsend_notify_3`
wxsend_notify_4=`nvram get wxsend_notify_4`
curltest=`which curl`
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
if [ "$wxsend_notify_1" = "1" ] || [ "$wxsend_notify_1" = "3" ] ; then
    hostIP=$(arIpAddress)
    hostIP=`echo $hostIP | head -n1 | cut -d' ' -f1`
    if [ "$hostIP"x = "x"  ] ; then
        curltest=`which curl`
        if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
            [ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "ip.3322.net" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`wget -T 5 -t 3 --user-agent "$user_agent" --quiet --output-document=- "http://ddns.oray.com/checkip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
        else
            [ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s "http://members.3322.org/dyndns/getip" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s ip.3322.net | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s "http://myip.ipip.net" | grep "当前 IP" | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
            [ "$hostIP"x = "x"  ] && hostIP=`curl -L --user-agent "$user_agent" -s http://ddns.oray.com/checkip | grep -E -o '([0-9]+\.){3}[0-9]+' | head -n1 | cut -d' ' -f1`
        fi
    fi
    lastIP=$(lastIPAddress)
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
    sleep 60
        hostIP=$(arIpAddress)
        hostIP=`echo $hostIP | head -n1 | cut -d' ' -f1`
        lastIP=$(lastIPAddress)
    fi
    if [ "$lastIP" != "$hostIP" ] && [ ! -z "$hostIP" ] ; then
        logger -t "【互联网 IPv4 变动】" "目前 IPv4: ${hostIP}"
        logger -t "【互联网 IPv4 变动】" "上次 IPv4: ${lastIP}"
        wxsend.sh send_message "【""$wxsend_title""】互联网IP变动" "${hostIP}" &
        logger -t "【微信推送】" "互联网IPv4变动:${hostIP}"
        echo -n $hostIP > /etc/storage/wxsend_lastIPAddress
    fi
fi
if [ "$wxsend_notify_1" = "2" ] || [ "$wxsend_notify_1" = "3" ] ; then
    hostIP6=$(arIpAddress6)
    hostIP6=`echo $hostIP6 | head -n1 | cut -d' ' -f1`
    lastIP6=$(lastIPAddress6)
    if [ "$lastIP6" != "$hostIP6" ] && [ ! -z "$hostIP6" ] ; then
        logger -t "【互联网 IPv6 变动】" "目前 IPv6: ${hostIP6}"
        logger -t "【互联网 IPv6 变动】" "上次 IPv6: ${lastIP6}"
        wxsend.sh send_message "【""$wxsend_title""】互联网IP变动" "${hostIP6}" &
        logger -t "【微信推送】" "互联网IPv6变动:${hostIP6}"
        echo -n $hostIP6 > /etc/storage/wxsend_lastIPAddress6
    fi
fi
if [ "$wxsend_notify_2" = "1" ] ; then
    # 获取接入设备名称
    touch /tmp/var/wxsend_newhostname.txt
    echo "接入设备名称" > /tmp/var/wxsend_newhostname.txt
    cat /tmp/static_ip.inf | grep -v '^$' | awk -F "," '{ if ( $6 == 0 ) print "内网IP："$1"|ＭＡＣ："$2"|名称："$3}' >> /tmp/var/wxsend_newhostname.txt
    # 读取以往接入设备名称
    touch /etc/storage/wxsend_hostname.txt
    [ ! -s /etc/storage/wxsend_hostname.txt ] && echo "接入设备名称" > /etc/storage/wxsend_hostname.txt
    # 获取新接入设备名称
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/wxsend_hostname.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname相同行.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname相同行.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname不重复.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复.txt | grep -v '^$'`
        wxsend.sh send_message "【""$wxsend_title""】新设备加入" "${content}" &
        logger -t "【微信推送】" "新设备加入:${content}"
        cat /tmp/var/wxsend_newhostname不重复.txt | grep -v '^$' >> /etc/storage/wxsend_hostname.txt
    fi
fi
if [ "$wxsend_notify_3" = "1" ] ; then
    # 设备上、下线提醒
    # 获取接入设备名称
    touch /tmp/var/wxsend_newhostname.txt
    echo "接入设备名称" > /tmp/var/wxsend_newhostname.txt
    cat /tmp/static_ip.inf | grep -v '^$' | awk -F "," '{ if ( $6 == 0 ) print "内网IP："$1"|ＭＡＣ："$2"|名称："$3}' >> /tmp/var/wxsend_newhostname.txt
    # 读取以往上线设备名称
    touch /etc/storage/wxsend_hostname_上线.txt
    [ ! -s /etc/storage/wxsend_hostname_上线.txt ] && echo "接入设备名称" > /etc/storage/wxsend_hostname_上线.txt
    # 上线
    awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /etc/storage/wxsend_hostname_上线.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname相同行_上线.txt
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname相同行_上线.txt /tmp/var/wxsend_newhostname.txt > /tmp/var/wxsend_newhostname不重复_上线.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复_上线.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复_上线.txt | grep -v '^$'`
        wxsend.sh send_message "【""$wxsend_title""】设备【上线】ON" "${content}" &
        logger -t "【微信推送】" "设备【上线】:${content}"
        cat /tmp/var/wxsend_newhostname不重复_上线.txt | grep -v '^$' >> /etc/storage/wxsend_hostname_上线.txt
    fi
    # 下线
    awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/var/wxsend_newhostname.txt /etc/storage/wxsend_hostname_上线.txt > /tmp/var/wxsend_newhostname不重复_下线.txt
    if [ -s "/tmp/var/wxsend_newhostname不重复_下线.txt" ] ; then
        content=`cat /tmp/var/wxsend_newhostname不重复_下线.txt | grep -v '^$'`
        wxsend.sh send_message "【""$wxsend_title""】设备【下线】OFF" "${content}" &
        logger -t "【微信推送】" "设备【下线】:${content}"
        cat /tmp/var/wxsend_newhostname.txt | grep -v '^$' > /etc/storage/wxsend_hostname_上线.txt
    fi
fi
#if [ "$wxsend_notify_4" = "1" ] && [ "$resub" = "1" ] ; then
if [ "$wxsend_notify_4" = "1" ] ; then
   #########自定义提醒区域开始##############
   #推送命令格式：  wxsend.sh send_message "【""$wxsend_title""】【事件标题】" "内容1|内容2|内容3|内容4|内容5"
   #例如下方检测zerotier掉线后重新启动并推送
    #[ -z "`pidof zerotier-one`" ] && zerotier.sh restart && wxsend.sh send_message "【""$wxsend_title""】【zerotier】" "进程掉线，重新启动" 
    
    
    
    
    
    
    
   #########自定义提醒区域结束##############
   echo "~"
fi
    resub=`expr $resub + 1`
    [ "$resub" -gt 360 ] && resub=1
else
echo "Internet down 互联网断线"
resub=1
fi
#循环检测时间一分钟（60秒）
sleep 60
continue
done

EEE
	chmod 755 "$wx_script"
fi

}

initconfig

get_token () {
touch /tmp/wx_access_token
access_token="$(cat /tmp/wx_access_token)"
http_type="$(curl -L -s "https://api.weixin.qq.com/cgi-bin/get_api_domain_ip?access_token=$access_token")"
get_api_domain="$(echo $http_type | grep ip_list)"
if [ ! -z "$get_api_domain" ] ; then
echo "Access token 有效"
else
http_type="$(curl -L -s "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$wxsend_appid&secret=$wxsend_appsecret")"
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
new_time=$(date +%Y年%m月%d日\ %X)
# 删除首个参数
shift
content1=${1:-"$new_time"}
content2=${2:-"$new_time"}
content3=${3:-"$new_time"}
content4=${4:-"$new_time"}
content5=${5:-"$new_time"}
content6=${6:-"$new_time"}
content7=${7:-"$new_time"}

[ "$content7" == "$content6" ] && content7=""
[ "$content6" == "$content5" ] && content6=""
[ "$content5" == "$content4" ] && content5=""
[ "$content4" == "$content3" ] && content4=""
[ "$content3" == "$content2" ] && content3=""
[ "$content2" == "$content1" ] && content2=""
[ "$content1" == "" ] && content1="$new_time"

# 空格分割消息：最多 7 段字符
content_value="$(echo "$content1
$content2
$content3
$content4
$content5
$content6
$content7" | awk -F '|' 'BEGIN{h=0;}{ \
for(i=1;i<=NF;++i) { \
    ARGV[h]=$i; \
    ++h;
} \
}END{ \
  for(i=1;i<=7;++i) { \
    if(i==1){ \
      sum=sum "\"content\":{\"value\":\"" ARGV[i-1] "\"}";
    }else{ \
      sum=sum "\"content" i "\":{\"value\":\"" ARGV[i-1] "\"}";
    } \
    if(i<7){ \
      sum=sum ",";
    } \
  } \
  printf(sum); \
}')"


curl -L -s -H "Content-type: application/json;charset=UTF-8" -H "Accept: application/json" -H "Cache-Control: no-cache" -H "Pragma: no-cache" -X POST -d '{"touser":"'"$wxsend_touser"'","template_id":"'"$wxsend_template_id"'","data":{"title":{"value":"'" "'"},'"$content_value"'}}' "https://api.weixin.qq.com/cgi-bin/message/template/send?access_token=$access_token"

else
logger -t "【微信推送】" "获取 Access token 错误，请看看哪里问题？"
fi
}


wxsend_title="$wxsend_title"
wxsend_content="$(nvram get wxsend_content)"
# 在线发送wxsend推送
if [ ! -z "$wxsend_content" ] ; then
if [ ! -z "$wxsend_appid" ] && [ ! -z "$wxsend_appsecret" ] && [ ! -z "$wxsend_touser" ] && [ ! -z "$wxsend_template_id" ] ; then
	curltest=`which curl`
	if [ -z "$curltest" ] ; then
		logger -t "【微信推送】" "找不到 curl ，请安装 curl 程序"
		nvram set wxsend_content=""
		exit 1 
	else
		send_message "$wxsend_title" "【""$wxsend_title""】" "$wxsend_content"
		logger -t "【微信推送】" "消息内容: $wxsend_content"
		nvram set wxsend_content=""
	fi
else
logger -t "【微信推送】" "测试发送失败, 注意检查[测试号信息]是否填写完整!!!"
fi
fi

case $1 in
send_message)
	send_message " " "$2" "$3" "$4" "$5" "$6" "$7" "$8"
	;;
start)
	wxsend_start
	;;
stop)
	wxsend_close
	;;
restart)
	wxsend_close
	wxsend_start
	;;
del_hostname)
	touch /etc/storage/wxsend_hostname.txt
	logger -t "【微信推送】" "清空以往接入设备名称：/etc/storage/wxsend_hostname.txt"
	echo "接入设备名称" > /etc/storage/wxsend_hostname.txt
	;;
*)
	wxsend_close
	wxsend_start
	;;
esac

