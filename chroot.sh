#!/bin/bash

set -e

BINDIR=/drone/src/bin
[ ! -d $BINDIR ] && mkdir $BINDIR

ARCH=aarch64
[ "$1"x == "arm"x ] && ARCH=arm

cp build.sh /ghc/rootfs
cd /ghc/rootfs

cp /etc/resolv.conf etc

cp /usr/bin/qemu-$ARCH-static usr/bin

mount -t devtmpfs devtmpfs dev
mount -t devpts devpts dev/pts
mount -t sysfs sysfs sys
mount -t tmpfs tmpfs tmp
mount -t proc proc proc

chroot . /build.sh

mv /ghc/rootfs/root/bin/* $BINDIR
