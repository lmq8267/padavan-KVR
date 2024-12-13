#!/bin/sh

export LANG=zh_CN.UTF-8

THIS_SCRIPT="sysinfo"
MOTD_DISABLE=""

SHOW_IP_PATTERN="^[ewr].*|^br.*|^lt.*|^umts.*"
# don't edit below here
display() {
    # $1=name $2=value $3=red_limit $4=minimal_show_limit $5=unit $6=after $7=acs/desc
    # battery red color is opposite, lower number
    if [ "$1" = "Battery" ]; then
        great="<"
    else
        great=">"
    fi
    if [ -n "$2" ] && [ "$(printf "%.0f" $2)" -ge "$4" ]; then
        printf "%-14s%s" "$1:"
        if awk "BEGIN{exit ! ($2 $great $3)}"; then
            echo -ne "\e[0;91m $2"
        else
            echo -ne "\e[0;92m $2"
        fi
        printf "%-1s%s\x1B[0m" "$5"
        printf "%-11s%s\t" "$6"
        return 1
    fi
}

get_cpu_usage() {
    local cpu_line1=$(head -n 1 /proc/stat)
    sleep 1
    local cpu_line2=$(head -n 1 /proc/stat)

    set -- $cpu_line1
    local user1=$2 nice1=$3 system1=$4 idle1=$5 iowait1=$6 irq1=$7 sirq1=$8 steal1=$9
    local busy1=$((user1 + nice1 + system1 + irq1 + sirq1 + steal1))
    local total1=$((busy1 + idle1 + iowait1))

    set -- $cpu_line2
    local user2=$2 nice2=$3 system2=$4 idle2=$5 iowait2=$6 irq2=$7 sirq2=$8 steal2=$9
    local busy2=$((user2 + nice2 + system2 + irq2 + sirq2 + steal2))
    local total2=$((busy2 + idle2 + iowait2))

    local busy_diff=$((busy2 - busy1))
    local total_diff=$((total2 - total1))
    cpu_usage=$((100 * busy_diff / total_diff))
    
    mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
}

storage_info() {
    # storage info
    RootInfo=$(df -h /etc)
    root_usage=$(echo "$RootInfo" | awk '/\// {print $(NF-1)}' | sed 's/%//g')
    root_total=$(echo "$RootInfo" | awk '/\// {print $(NF-4)}')
}

storage_info
critical_load=$(( 1 + $(grep -c processor /proc/cpuinfo) / 2 ))

uptime_str=$(uptime)
uptime_info=$(echo "$uptime_str" | sed -n 's/.*up \(.*\) load average:.*/\1/p')
days=0
hours=0
minutes=0

if echo "$uptime_info" | grep -q "day"; then
    days=$(echo "$uptime_info" | sed -n 's/\([0-9]*\) day.*/\1/p')
    uptime_info=$(echo "$uptime_info" | sed 's/^[0-9]* day[s]*, //')
fi

if echo "$uptime_info" | grep -q ":"; then
    hours=$(echo "$uptime_info" | cut -d':' -f1 | tr -d ' ')
    minutes=$(echo "$uptime_info" | cut -d':' -f2 | tr -d ' '| tr -d ',')
elif echo "$uptime_info" | grep -q "min"; then
    minutes=$(echo "$uptime_info" | sed -n 's/\([0-9]*\) min.*/\1/p')
fi

if [ "$days" -gt 0 ]; then
    time="${days}天 ${hours}小时 ${minutes}分钟"
elif [ "$hours" -gt 0 ]; then
    time="${hours}小时 ${minutes}分钟"
else
    time="${minutes}分钟"
fi
# memory and swap
mem_info=$(LC_ALL=C free -w 2>/dev/null | grep "^Mem" || LC_ALL=C free | grep "^Mem")
memory_usage=$(echo "$mem_info" | awk '{printf("%.0f",(($2-($4+$6))/$2) * 100)}')
memory_total=$(echo "$mem_info" | awk '{printf("%d",$2/1024)}')
#swap_info=$(LC_ALL=C free -m | grep "^Swap")
#swap_usage=$( (echo "$swap_info" | awk '/Swap/ { printf("%3.0f", $3/$2*100) }' 2>/dev/null || echo 0) | tr -c -d '[:digit:]')
#swap_total=$(echo "$swap_info" | awk '{print $(2)}')
get_cpu_usage
echo ""
display "CPU 负载" "$cpu_usage" "70" "0" " %" 
printf "运行时间:  \x1B[92m%s\x1B[0m\t\t" " $time"
echo "" # fixed newline

display "内存已用" "$memory_usage" "70" "0" " %" " of ${memory_total}MB"

printf "IP  地址:  \x1B[92m%s\x1B[0m" "WAN:$(nvram get wan_ipaddr)  LAN:$(nvram get lan_ipaddr)"
echo ""

display "闪存已用" "$root_usage" "90" "1" " %" " of $root_total"

printf "系统版本: \x1B[92m%s\x1B[0m\t" " $(nvram get firmver_sub)"

echo ""
echo ""
