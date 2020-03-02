#!/bin/sh
set -e

ARCH=`arch`

apt-get update

cd /root
/root/stack.sh

git clone https://github.com/jgm/pandoc
cd pandoc
cat >> stack.yaml <<EOF
system-ghc: true
arch: $ARCH
EOF


stack install -v --flag 'pandoc:static'

exit $?
