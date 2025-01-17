#!/bin/sh
nvram_ttyd_port="$(nvram get ttyd_port)"
[ -z "$nvram_ttyd_port" ] && nvram set ttyd_port=7681 && nvram commit
port=${nvram_ttyd_port:-"7681"}
ttyd_cmd="$(nvram get ttyd_cmd)"
[ -z "$ttyd_cmd" ] && nvram set ttyd_cmd="-i br0 login" && nvram commit

func_start(){
	logger -t "【TTYD】" "运行ttyd：start-stop-daemon -S -b -x ttyd -- -p ${port} ${ttyd_cmd}"
	start-stop-daemon -S -b -x ttyd -- -p "$port" $ttyd_cmd
}

func_stop(){
	logger -t "【TTYD】" "关闭ttyd"
	killall -q ttyd
}

case "$1" in
start)
        func_start
        ;;
stop)
        func_stop
        ;;
restart)
        func_stop
        func_start
        ;;
*)
        echo "Usage: $0 { start | stop | restart }"
        exit 1
        ;;
esac
