#!/bin/sh
set -e

ARCH=`arch`

sed -i '/edge/d' /etc/apk/repositories
apk update
apk add xz git aria2

cd /root
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
