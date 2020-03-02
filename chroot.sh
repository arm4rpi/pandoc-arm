#!/bin/bash

set -e

cp build.sh /ghc/rootfs
cd /ghc/rootfs

cp /etc/resolv.conf etc

CODE=`curl -s http://ip-api.com/json |tr ',' '\n' |grep "countryCode" |awk -F'"' '{print $4}'`

if [ "$CODE"x == "CN"x ];then
	sed -i -r 's/deb.debian.org|security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list
fi

apt-get update
apt-get install -y qemu-user-static
cp /usr/bin/qemu-aarch64-static usr/bin

mount -t devtmpfs devtmpfs dev
mount -t devpts devpts dev/pts
mount -t sysfs sysfs sys
mount -t tmpfs tmpfs tmp
mount -t proc proc proc

chroot . /build.sh
