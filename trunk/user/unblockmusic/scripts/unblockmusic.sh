#!/bin/sh

check_host() {
  local host=$1
  if echo $host | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
		hostip=$host
	elif [ "$host" != "${host#*:[0-9a-fA-F]}" ]; then
		hostip=$host
	else
		hostip=$(ping $host -W 1 -s 1 -c 1 | grep PING | cut -d'(' -f 2 | cut -d')' -f1)
		if echo $hostip | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
			hostip=$hostip
		else
			hostip="127.0.0.1"
		fi
	fi
	echo -e $hostip
}

ip_rule()
{
num=`nvram get wyy_staticnum_x`
	if [ $num -ne 0 ]; then
	for i in $(seq 1 $num)
	do
		j=`expr $i - 1`
		ip=`nvram get wyy_ip_x$j`
		mode=`nvram get wyy_ip_road_x$j`
		case "$mode" in
		http)
			ipset -! add music_http $ip
			;;
		https)
			ipset -! add music_https $ip
			;;
		disable)
			ipset -! add music_http $ip
			ipset -! add music_https $ip
			;;
		esac
	done
	fi
}

ENABLE=$(nvram get wyy_enable)
TYPE=$(nvram get wyy_musicapptype)
APPTYPE=$(nvram get wyy_apptype)
FLAC=$(nvram get wyy_flac)

CLOUD=$(nvram get wyy_cloudserver)
if [ "$CLOUD" = "coustom" ];then
CLOUD=$(nvram get wyy_coustom_server)
fi
cloudadd=$(echo "$CLOUD" | awk -F ':' '{print $1}')
cloudhttp=$(echo "$CLOUD" | awk -F ':' '{print $2}')
cloudhttps=$(echo "$CLOUD" | awk -F ':' '{print $3}')

cloudip=$(check_host $cloudadd)

ipt_n="iptables -t nat"

add_rule()
{
  ipset -! -N music hash:ip
  ipset -! -N music_http hash:ip
  ipset -! -N music_https hash:ip
	$ipt_n -N CLOUD_MUSIC
	$ipt_n -A CLOUD_MUSIC -d 0.0.0.0/8 -j RETURN
	$ipt_n -A CLOUD_MUSIC -d 10.0.0.0/8 -j RETURN
	$ipt_n -A CLOUD_MUSIC -d 127.0.0.0/8 -j RETURN
	$ipt_n -A CLOUD_MUSIC -d 169.254.0.0/16 -j RETURN
	$ipt_n -A CLOUD_MUSIC -d 172.16.0.0/12 -j RETURN
	$ipt_n -A CLOUD_MUSIC -d 192.168.0.0/16 -j RETURN
	$ipt_n -A CLOUD_MUSIC -d 224.0.0.0/4 -j RETURN
	$ipt_n -A CLOUD_MUSIC -d 240.0.0.0/4 -j RETURN
	if [ "$APPTYPE" != "cloud" ]; then
    $ipt_n -A CLOUD_MUSIC -p tcp -m set ! --match-set music_http src --dport 80 -j REDIRECT --to-ports 5200
    $ipt_n -A CLOUD_MUSIC -p tcp -m set ! --match-set music_https src --dport 443 -j REDIRECT --to-ports 5201
  else
    $ipt_n -A CLOUD_MUSIC -p tcp -m set ! --match-set music_http src --dport 80 -j DNAT --to $cloudip:$cloudhttp
    $ipt_n -A CLOUD_MUSIC -p tcp -m set ! --match-set music_https src --dport 443 -j DNAT --to $cloudip:$cloudhttps
	fi
	$ipt_n -I PREROUTING -p tcp -m set --match-set music dst -j CLOUD_MUSIC
	iptables -I OUTPUT -d 223.252.199.10 -j DROP
	
	ip_rule
}

del_rule(){
	$ipt_n -D PREROUTING -p tcp -m set --match-set music dst -j CLOUD_MUSIC 2>/dev/null
	$ipt_n -F CLOUD_MUSIC  2>/dev/null
	$ipt_n -X CLOUD_MUSIC  2>/dev/null
	iptables -D OUTPUT -d 223.252.199.10 -j DROP 2>/dev/null
	
	ipset -X music_http 2>/dev/null
	ipset -X music_https 2>/dev/null
	
	rm -rf /tmp/dnsmasq.music
	sed -i '/dnsmasq.music/d' /etc/storage/dnsmasq/dnsmasq.conf
	/sbin/restart_dhcpd
}

set_firewall(){
	rm -f /tmp/dnsmasq.music/dnsmasq-163.conf
	mkdir -p /tmp/dnsmasq.music
  	cat <<-EOF > "/tmp/dnsmasq.music/dnsmasq-163.conf"
ipset=/.music.163.com/music
ipset=/interface.music.163.com/music
ipset=/interface3.music.163.com/music
ipset=/apm.music.163.com/music
ipset=/apm3.music.163.com/music
ipset=/clientlog.music.163.com/music
ipset=/clientlog3.music.163.com/music
	EOF
sed -i '/dnsmasq.music/d' /etc/storage/dnsmasq/dnsmasq.conf
cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
conf-dir=/tmp/dnsmasq.music
EOF
add_rule
/sbin/restart_dhcpd
}

find_bin() {
dirs="/etc/storage/bin
/tmp/var
/usr/bin"

UnblockNeteaseMusic=""
for dir in $dirs ; do
    if [ -f "$dir/UnblockNeteaseMusic" ] ; then
        UnblockNeteaseMusic="$dir/UnblockNeteaseMusic"
        break
    fi
done
[ -z "$UnblockNeteaseMusic" ] && UnblockNeteaseMusic="/tmp/var/UnblockNeteaseMusic"
}

github_proxys="$(nvram get github_proxy)"
[ -z "$github_proxys" ] && github_proxys=" "

dl_wyy() {
	if [ ! -f "/usr/bin/UnblockNeteaseMusic" ]; then
		logger -t "【音乐解锁】" "没有主程序，开始下载程序"
		
		for proxy in $github_proxys ; do
  		length=$(wget --no-check-certificate -T 5 -t 3 "${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/unblockmusic/UnblockNeteaseMusic" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
 		length=`expr $length + 512000`
		length=`expr $length / 1048576`
 		[ ! -z "$length" ] && logger -t "【音乐解锁】" "程序大小 ${length}M"
		curl -L -k -o "/tmp/UnblockNeteaseMusic" --connect-timeout 10 --retry 3 "${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/unblockmusic/UnblockNeteaseMusic" || wget --no-check-certificate -O "/tmp/UnblockNeteaseMusic" "${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/unblockmusic/UnblockNeteaseMusic"
		if [ "$?" = 0 ] ; then
			chmod +x /tmp/UnblockNeteaseMusic
			if [ "$(($(/tmp/UnblockNeteaseMusic -h 2>&1 | wc -l)))" -gt 3 ] ; then
				logger -t "【音乐解锁】" "/tmp/UnblockNeteaseMusic 下载成功"
				break
       			else
	   			logger -t "【音乐解锁】" "下载不完整，删除...请手动下载 ${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/unblockmusic/UnblockNeteaseMusic 上传到  /tmp/UnblockNeteaseMusic"
				rm -f /tmp/UnblockNeteaseMusic
	  		fi
		else
			logger -t "【音乐解锁】" "下载失败${proxy}https://github.com/lmq8267/padavan-KVR/blob/main/trunk/user/unblockmusic/UnblockNeteaseMusic"
   		fi
		
		done
	fi


}
wyy_renum=`nvram get wyy_renum`

wyy_restart () {
relock="/var/lock/wyy_restart.lock"
if [ "$1" = "o" ] ; then
	nvram set wyy_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	wyy_renum=${wyy_renum:-"0"}
	wyy_renum=`expr $wyy_renum + 1`
	nvram set wyy_renum="$wyy_renum"
	if [ "$wyy_renum" -gt "3" ] ; then
		I=19
		echo $I > $relock
		logger -t "【音乐解锁】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动"
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(nvram get wyy_renum)" = "0" ] && break
   			#[ "$(nvram get wyy_enable)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		nvram set wyy_renum="1"
	fi
	[ -f $relock ] && rm -f $relock
fi
wyy_start
}
wyy_start()
{
	[ $ENABLE -eq "0" ] && exit 0
 	logger -t "【音乐解锁】" "开始启动"
	if [ "$TYPE" = "default" ]; then
		musictype=" "
	else
		musictype="-o $TYPE"
	fi
	if [ "$APPTYPE" == "go" ]; then
	if [ $FLAC -eq 1 ]; then
      ENABLE_FLAC="-b "
    fi
    find_bin
    if [ -f "$UnblockNeteaseMusic" ] ; then
       [ ! -x "$UnblockNeteaseMusic" ] && chmod +x $UnblockNeteaseMusic
       if [[ "$($UnblockNeteaseMusic -h 2>&1 | wc -l)" -lt 3 ]] ; then
         rm -f $UnblockNeteaseMusic
       fi
    fi
    if [ ! -f "$UnblockNeteaseMusic" ] ; then
    	dl_wyy
    fi 
    $UnblockNeteaseMusic $ENABLE_FLAC -p 5200 -sp 5201 -m 0 -c /etc_ro/UnblockNeteaseMusicGo/server.crt -k /etc_ro/UnblockNeteaseMusicGo/server.key -m 0 -e >/dev/null 2>&1 &
    logger -t "【音乐解锁】" "启动 Golang Version (http:5200, https:5201)"    
  else
    kill -9 $(busybox ps -w | grep 'sleep 60m' | grep -v grep | awk '{print $1}') >/dev/null 2>&1
    /usr/bin/UnblockNeteaseMusicCloud >/dev/null 2>&1 &
     logger -t "【音乐解锁】" "启动 Cloud Version - Server: $cloudip (http:$cloudhttp, https:$cloudhttps)"
	fi
sleep 4
  if [ ! -z "`pidof UnblockNeteaseMusic`" ] || [ ! -z "`pidof UnblockNeteaseMusicCloud`" ] ; then
	logger -t "【音乐解锁】" "运行成功！"
  	wyy_restart o
else
	logger -t "【音乐解锁】" "运行失败, 注意检查${UnblockNeteaseMusic}是否下载完整,10 秒后自动尝试重新启动"
  	sleep 10
  	wyy_restart x
fi	
	set_firewall
	
  if [ "$APPTYPE" != "cloud" ]; then
    /usr/bin/logcheck.sh >/dev/null 2>&1 &
  fi
}

wyy_close()
{	
	scriptname=$(basename $0)
	kill -9 $(busybox ps -w | grep UnblockNeteaseMusic | grep -v grep | awk '{print $1}') >/dev/null 2>&1
	kill -9 $(busybox ps -w | grep logcheck.sh | grep -v grep | awk '{print $1}') >/dev/null 2>&1
	
	del_rule
	logger -t "【音乐解锁】" "已关闭"
	if [ ! -z "$scriptname" ] ; then
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
		eval $(ps -w | grep "$scriptname" | grep -v $$ | grep -v grep | awk '{print "kill -9 "$1";";}')
	fi
}

case $1 in
start)
	wyy_start
	;;
stop)
	wyy_close
	;;
restart)
	wyy_close
	wyy_start
	;;
*)
	echo "check"
	#exit 0
	;;
esac
