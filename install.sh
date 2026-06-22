#!/bin/bash

# 检查系统启动方式（BIOS/UEFI）
if [ -d /sys/firmware/efi ]; then
    IMG_URL="https://github.com/Toby1GO/install-routeros-shc/releases/download/Ros7.20.6/chr-7.20.6UEFI.img"
    echo "检测到 UEFI 启动方式，准备下载 UEFI 镜像包..."
else
    IMG_URL="https://github.com/Toby1GO/install-routeros-shc/releases/download/Ros7.20.6/chr-7.20.6.img"
    echo "检测到 BIOS 启动方式，准备下载 legacy 镜像包..."
fi

# 下载对应的镜像
wget "$IMG_URL" -O /tmp/chr.img

cd /tmp

# 检测磁盘设备
STORAGE=$(lsblk | grep disk | awk '{print $1}' | head -n 1)
echo "STORAGE is $STORAGE"

# 获取默认网卡
ETH=$(ip route show default | sed -n 's/.* dev \([^\ ]*\) .*/\1/p')
echo "ETH is $ETH"

# 获取IP地址
ADDRESS=$(ip addr show "$ETH" | grep global | awk '{print $2}' | head -n 1)
echo "ADDRESS is $ADDRESS"

# 获取网关
GATEWAY=$(ip route list | grep default | awk '{print $3}')
echo "GATEWAY is $GATEWAY"

# 挂载镜像文件到 /mnt
mount -o loop,offset=33571840 chr.img /mnt

# 创建可读写目录
mkdir -p /mnt/rw

# 生成 autorun.scr 内容（注意换成你实际变量名和接口）
cat > /mnt/rw/autorun.scr <<EOF
/ip address add address=$ADDRESS interface=ether1
/ip route add gateway=$GATEWAY
EOF

# 卸载镜像
umount /mnt

sleep 5

# 写入镜像到磁盘
dd if=chr.img of=/dev/"$STORAGE" bs=4M oflag=sync

echo "Ok, reboot"
echo 1 > /proc/sys/kernel/sysrq
echo b > /proc/sysrq-trigger