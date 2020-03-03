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

cp /usr/bin/qemu-$ARCH-static usr/bin

mount -t devtmpfs devtmpfs dev
mount -t devpts devpts dev/pts
mount -t sysfs sysfs sys
mount -t tmpfs tmpfs tmp
mount -t proc proc proc

# check container
ls /ghc/rootfs
dpkg -l |grep qemu
ls /ghc/rootfs/usr/bin |grep qemu

chroot . /build.sh

mv /ghc/rootfs/root/bin/* $BINDIR
