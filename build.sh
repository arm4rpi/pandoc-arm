#!/bin/sh
set -e

ARCH=`arch`

sed -i '/edge/d' /etc/apk/repositories
apk update
apk add xz git aria2

cd /root
/root/stack.sh

RESOLVER="nightly-2018-12-17"
[ "$ARCH"x != "aarch64"x ] && RESOLVER="lts-13.11"

git clone https://github.com/jgm/pandoc
cd pandoc
sed -i "s/^resolver.*/resolver: $RESOLVER/" stack.yaml
cat >> stack.yaml <<EOF
system-ghc: true
arch: $ARCH
EOF

stack install -v --flag 'pandoc:static'

exit $?
