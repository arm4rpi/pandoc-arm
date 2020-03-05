#!/bin/bash

set -e

CUR=$(cd `dirname $0`;pwd)
BINDIR=$CUR/bin
[ ! -d $BINDIR ] && mkdir -p $BINDIR

ARCH=aarch64
[ "$1"x == "arm"x ] && ARCH=arm

cp $CUR/build.sh /ghc/rootfs
cd /ghc/rootfs

cp /etc/resolv.conf etc

#uname -a |grep azure && r=0 || r=1
#if [ $r -eq 0 ];then
	apt-get update
	apt-get --reinstall install -y qemu-user-static
#fi

cp /usr/bin/qemu-$ARCH-static usr/bin

mount -t devtmpfs devtmpfs dev
mount -t devpts devpts dev/pts
mount -t sysfs sysfs sys
mount -t tmpfs tmpfs tmp
mount -t proc proc proc

chroot . /build.sh

mv /ghc/rootfs/root/bin/* $BINDIR
