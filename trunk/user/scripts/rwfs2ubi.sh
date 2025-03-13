#!/bin/sh

if [ ! -x /sbin/ubiattach ] || \
	[ ! -x /sbin/ubiformat ] || \
	[ ! -x /sbin/ubimkvol ] || \
	[ ! -x /sbin/ubidetach ]; then
  echo "无法找到 UBI 工具的可执行文件！" >&2
  logger -t "rwfs2ubi.sh" "无法找到 UBI 配套程序 可执行文件！"
  exit 1
fi

rwfs="$(cat /proc/mtd |grep \"RWFS\")"

if [ -z "$rwfs" ]; then
	echo "RWFS 分区未找到！" >&2
	logger -t "rwfs2ubi.sh" "找不到 RWFS 分区！"
	exit 1
fi

rwfs_idx="$(echo $rwfs |cut -d':' -f1|cut -c4-5)"

mountpoint="$(mount |grep /dev/ubi${rwfs_idx})"
if [ -n "$mountpoint" ]; then
	echo "/dev/ubi${rwfs_idx} 已经挂载！" >&2
	logger -t "rwfs2ubi.sh" "/dev/ubi${rwfs_idx} 已经挂载！"
	exit 1
fi

ubidetach -p /dev/mtd${rwfs_idx} > /dev/null 2>&1

mtd_write erase /dev/mtd${rwfs_idx}

ubiformat /dev/mtd${rwfs_idx} -y -q

if [ $? != 0 ]; then
	echo "格式化 RWFS 分区 (/dev/mtd${rwfs_idx}) 为 UBIFS 失败！" >&2
	logger -t "rwfs2ubi.sh" "格式化 RWFS 分区(/dev/mtd${rwfs_idx}) 为 UBIFS 失败！"
	exit 1
fi

ubiattach -p /dev/mtd${rwfs_idx} -d ${rwfs_idx}

if [ $? != 0 ]; then
	echo "挂载 UBIFS (/dev/mtd${rwfs_idx}) 失败！" >&2
	logger -t "rwfs2ubi.sh" "连接 UBIFS (/dev/mtd${rwfs_idx})失败！"

	exit 1
fi

ubimkvol /dev/ubi${rwfs_idx} -m -N rwfs

if [ $? = 0 ]; then
	echo -e "创建 UBI 卷完成！\n\n"
	logger -t "rwfs2ubi.sh" "创建 UBI 卷完成！"
	nvram set mtd_rwfs_mount=1 && nvram commit
	echo "请重启您的路由器，以便自动挂载 RWFS 分区到 /media/mtd_rwfs"
	echo "如果您希望将 RWFS 自动挂载到 /opt，请在 /media/mtd_rwfs 中创建 opt 目录，然后重启路由器。"
	echo "如果您想在 /opt 中设置 Entware，请运行 nvram set optw_enable=2 && nvram commit 然后运行 opt-start.sh 以下载 Entware 安装程序。"
else
	echo "创建 UBI 卷失败！" >&2
	logger -t "rwfs2ubi.sh" "创建 UBI 卷失败！"
fi

ubidetach -p /dev/mtd${rwfs_idx}
