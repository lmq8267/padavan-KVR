#!/bin/sh

output="$1"
url1="$2"
url2="$3"
check_n="$4"
check_lines="$5"

wget_err=""
curl_err=""

[ -z "$url1" ] && return
[ -z "$url2" ] && url2="$url1"
[ -z "$output" ] && return
rm -f "$output"
[ ! -d "/tmp/wait/check" ] && mkdir -p /tmp/wait/check

download_wait () {
{ sleep $check_time ; [ -f /tmp/wait/check/$check_time ] && eval $(ps -w | grep "max-redirs" | grep "$check_time" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}') ;  [ -f /tmp/wait/check/$check_time ] && eval $(ps -w | grep "wget\|-T" | grep "$check_time" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}') ; } &
}

download_k_wait () {
eval $(ps -w | grep "sleep $check_time" | grep -v $$ | grep -v grep | awk '{print "kill "$1";";}')
}

download_curl () {
rm -f "$output"
curl_path=$*
echo $check_time > /tmp/wait/check/$check_time
{ check="`$curl_path --max-redirs $check_time --user-agent "$user_agent" -L -s -w "%{http_code}" -o $output`" ; echo "$check" > /tmp/wait/check/$check_time ; } &
download_k_wait
download_wait
check="$(cat /tmp/wait/check/$check_time)"
while [ "$check" = "$check_time" ];
do
sleep 1
check="$(cat /tmp/wait/check/$check_time)"
done
[ "$check" != "200" ] && { curl_err="$check 错误！" ; rm -f "$output" ; }
}

download_wget () {
rm -f "$output"
wget_path=$*
echo $check_time > /tmp/wait/check/$check_time
{ $wget_path --user-agent "$user_agent" -O $output -T "$check_time" -t 10 ; [ "$?" == "0" ] && check=200 || check=404 ; echo "$check" > /tmp/wait/check/$check_time ; } &
download_k_wait
download_wait
check="$(cat /tmp/wait/check/$check_time)"
while [ "$check" = "$check_time" ];
do
sleep 1
check="$(cat /tmp/wait/check/$check_time)"
done
[ "$check" != "200" ] && { wget_err="$check 错误！" ; rm -f "$output" ; }
}

if [ ! -s "$output" ] ; then
line_path=`dirname $output`
mkdir -p $line_path
if [ "$check_n" != "N" ] ; then
if hash check_disk_size 2>/dev/null ; then
avail=`check_disk_size $line_path`
if [ "$?" == "0" ] ; then
echo "【$line_path】可用容量: $avail M" 
logger -t "【下载】" "$line_path可用容量: $avail M" 
else
avail=0
logger -t "【下载】" "错误！提取可用容量失败:【$line_path】" 
fi
[ -z "$avail" ] && avail=0
if [ "$avail" != "0" ] ; then
echo "【$line_path】可用容量: $avail M" 
logger -t "【下载】" "$line_path可用容量: $avail M" 
fi
length=0
touch /tmp/check_avail_error.txt
if [ -z "$(grep "$url1" /tmp/check_avail_error.txt)" ] ; then
if [ -z "$(echo "$url1" | grep "^/")" ] ; then
length_wget=$(wget  -T 5 -t 3 "$url1" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
else
length_wget=$(ls -l "$url1" | awk '{print $5}')
fi
[ -z "$length_wget" ] && echo "$url1" >> /tmp/check_avail_error.txt
if [ -z "$length_wget" ] && [ -z "$(grep "$url2" /tmp/check_avail_error.txt)" ] ; then
if [ -z "$(echo "$url2" | grep "^/")" ] ; then
length_wget=$(wget  -T 5 -t 3 "$url2" -O /dev/null --spider --server-response 2>&1 | grep "[Cc]ontent-[Ll]ength" | grep -Eo '[0-9]+' | tail -n 1)
else
length_wget=$(ls -l "$url2" | awk '{print $5}')
fi
[ -z "$length_wget" ] && echo "$url2" >> /tmp/check_avail_error.txt
fi
[ ! -z "$length_wget" ] && length=$(echo $length_wget)
fi
[ -z "$length" ] && length=0
if [ "$length" != "0" ] && [ "$avail" != "0" ] ; then
length=`expr $length + 512000`
length=`expr $length / 1048576`
echo "【$url1】文件大小: $length M "
logger -t "【下载】" "$url1文件大小: $length M" 
if [ "$length" -gt "$avail" ] ; then
logger -t "【下载】" "错误！剩余空间不足:【文件大小: $length M】>【可用容量: $avail M】"
logger -t "【下载】" "跳过 下载【 $output 】"
return 1
fi
fi
fi
fi
mkdir -p /tmp/wait/check
check_time="1"$(tr -cd 0-9 </dev/urandom | head -c 3)
if [ -z "$(echo "$url1" | grep "^/")" ] ; then
if [ -s "/usr/bin/curl" ] && [ ! -s "$output" ] ; then
download_curl /usr/bin/curl $url1
fi
if [ -s "/usr/sbin/curl" ] && [ ! -s "$output" ] ; then
download_curl /usr/sbin/curl --capath /etc/ssl/certs $url1
fi
if [ -s "/usr/bin/wget" ] && [ ! -s "$output" ] ; then
download_wget /usr/bin/wget $url1
fi
if [ -s "/usr/bin/wget" ] && [ ! -s "$output" ] ; then
download_wget /usr/bin/wget $url1
fi
else
cp -f "$url1" "$output"
fi
if [ ! -s "$output" ] ; then
logger -t "【下载】" "下载失败:【$output】 URL:【$url1】"
logger -t "【下载】" "重新下载:【$output】 URL:【$url2】"
if [ -z "$(echo "$url2" | grep "^/")" ] ; then
if [ -s "/usr/bin/curl" ] && [ ! -s "$output" ] ; then
download_curl /usr/bin/curl $url2
fi
if [ -s "/usr/sbin/curl" ] && [ ! -s "$output" ] ; then
download_curl /usr/sbin/curl --capath /etc/ssl/certs $url2
fi
if [ -s "/usr/bin/wget" ] && [ ! -s "$output" ] ; then
download_wget /usr/bin/wget $url2
fi
if [ -s "/usr/bin/wget" ] && [ ! -s "$output" ] ; then
download_wget /usr/bin/wget $url2
fi
else
cp -f "$url2" "$output"
fi
fi
download_k_wait
rm -f /tmp/wait/check/$check_time
if [ ! -s "$output" ] ; then
logger -t "【下载】" "下载失败:【$output】 URL:【$url2】"
[ ! -z "$curl_err" ] && logger -t "【下载】" "curl_err ：$check错误！"
[ ! -z "$wget_err" ] && logger -t "【下载】" "wget_err ：$check错误！"
fi
fi
[ -f "$output" ] && chmod 777 "$output"
