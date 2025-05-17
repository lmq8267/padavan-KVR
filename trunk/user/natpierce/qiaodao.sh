#!/bin/sh

#皎月连自动签到脚本，修改好你的帐号密码后设置定时任务执行即可。
#下方双引号内改为你的帐号
username="100000@qq.com"
#下方双引号内改为你的密码
password="abc10000"

# 设置颜色变量
cyan='\033[0;36m'     # 青色
purple='\033[0;35m'   # 紫色
reset='\033[0m'       # 重置颜色

# 登录帐号
login_resp=$(curl -Lks 'https://www.natpierce.cn/pc/login/login.html' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36' \
  -H 'x-requested-with: XMLHttpRequest' \
  -d "username=${username}&password=${password}" \
  -c /tmp/natpierce.cookies)

# 提取登录状态
login_code=$(echo "$login_resp" | sed -n 's/.*"code":\([0-9]\+\).*/\1/p')
login_msg=$(echo "$login_resp" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')

# 登录状态
if [ "$login_code" = "200" ] ; then
  printf "\n${purple}${login_msg}${reset}\n" 
else
  printf "\n${cyan}登陆错误：${reset}${purple}${login_msg}${reset}\n" 
  exit 1
fi

# 获取签到状态
sign_resp=$(curl -Lks 'https://www.natpierce.cn/pc/sign/index.html' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36' \
  -b /tmp/natpierce.cookies)

# 提取签到信息
info_block=$(echo "$sign_resp" | sed -n 's/.*<div class="d_hao">\([^<]*<br>[^<]*<br>[^<]*\)<\/div>.*/\1/p' | \
  sed 's/&nbsp;//g; s/<br>/\n/g')
username_line=$(echo "$info_block" | grep '用户名')
expire_line=$(echo "$info_block" | grep '服务到期时间')
next_line=$(echo "$info_block" | grep '下次可签到时间')

# 取冒号后的值
get_value() {
  echo "$1" | sed 's/.*：//'
}

# 打印签到信息
printf "\n${cyan}当前登录账户：${purple}%s${reset}\n" "$(get_value "$username_line")"
printf "${cyan}服务到期时间：${purple}%s${reset}\n" "$(get_value "$expire_line")"
printf "${cyan}下次签到时间：${purple}%s${reset}\n" "$(get_value "$next_line")"

# 进行签到
checkin_resp=$(curl -Lks 'https://www.natpierce.cn/pc/sign/qiandao_bf.html' \
  -X POST \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36' \
  -H 'x-requested-with: XMLHttpRequest' \
  -b /tmp/natpierce.cookies)

# 打印签到状态
checkin_code=$(echo "$heckin_resp" | sed -n 's/.*"code":\([0-9]\+\).*/\1/p')
checkin_msg=$(echo "$checkin_resp" | sed -n 's/.*"message":"\([^"]*\)".*/\1/p')
if [ "$checkin_code" = "200" ] ; then
  printf "\n${purple}${checkin_msg}${reset}\n\n"
else
  printf "\n${cyan}签到错误：${reset}${purple}${checkin_msg}${reset}\n\n" 
  exit 1
fi
