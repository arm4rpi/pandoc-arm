#!/bin/bash


cd /root/rootfs

cp /etc/resolv.conf etc
apt-get install -y qemu-user-static
cp /usr/bin/qemu-aarch64-static usr/bin

mount -t devtmpfs devtmpfs dev
mount -t devpts devpts dev/pts
mount -t sysfs sysfs sys
mount -t tmpfs tmpfs tmp
mount -t proc proc proc

chroot . ./init.sh
