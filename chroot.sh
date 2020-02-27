#!/bin/bash

cd /root/rootfs
mount -t devtmpfs devtmpfs dev
mount -t devpts devpts dev/pts
mount -t sysfs sysfs sys
mount -t tmpfs tmpfs tmp
mount -t proc proc proc

df -h

chroot . ./init.sh
