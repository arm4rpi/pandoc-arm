#!/bin/sh
set -e

ARCH=`arch`

apk update
apk add git aria2 make libc-dev pcre-dev libc6-compat ncurses5-libs gmp-dev llvm zlib-dev gcc perl g++


# numactl-dev need edge source. but others may conflict with edge. so delete it after install numactl-dev
cat >/etc/apk/repositories<<EOF
http://dl-cdn.alpinelinux.org/alpine/edge/main
http://dl-cdn.alpinelinux.org/alpine/edge/community
EOF

apk add numactl-dev
ln -s /usr/lib/libncurses.so.5 /usr/lib/libtinfo.so.5

sed -i '/edge/d' /etc/apk/repositories


cd /root
aria2c -x 16 https://github.com/commercialhaskell/ghc/releases/download/ghc-8.6.2-release/ghc-8.6.2-aarch64-deb8-linux.tar.xz
tar Jxvf ghc-8.6.2-aarch64-deb8-linux.tar.xz
cd ghc-8.6.2
./configure
make install

/root/stack.sh

git clone github.com/jgm/pandoc
cd pandoc
sed 's/^resolver.*/resolver: nightly-2018-12-17/' stack.yaml -i
cat >> stack.yaml <<EOF
system-ghc: true
arch: $ARCH
EOF

stack install -v --flag 'pandoc:static'

exit $?
