#!/bin/bash
set -e

ARCH=`arch`

function getTag() {
	git describe --tags |awk -F'-' '{print $1}'
}

function release() {
	DIR=/root/.local/bin
	mv $DIR/$1 $DIR/$1-$2-$ARCH
	xz $DIR/$1-$2-$ARCH
}

apt-get update
apt-get install -y xz-utils

cd /root
/root/stack.sh

# pandoc
git clone https://github.com/jgm/pandoc
cd pandoc
tag=`getTag`
sed -i 's/^resolver.*/resolver: lts-14.6/' stack.yaml
cat >> stack.yaml <<EOF
system-ghc: true
arch: $ARCH
EOF

stack install -v --flag 'pandoc:static'
release pandoc "$tag"

# pandoc-citeproc
cd ../
git clone https://github.com/jgm/pandoc-citeproc
cd pandoc-citeproc
tag=`getTag`
sed -i 's/^resolver.*/resolver: lts-14.6/' stack.yaml
cat >> stack.yaml <<EOF
system-ghc: true
arch: $ARCH
EOF

stack install -v --flag 'pandoc-citeproc:static'
release "pandoc-citeproc" "$tag"

# pandoc-crossref
cd ../
git clone https://github.com/lierdakil/pandoc-crossref
cd pandoc-crossref
tag=`getTag`
sed -i 's/^resolver.*/resolver: lts-14.6/' stack.yaml
cat >> stack.yaml <<EOF
system-ghc: true
arch: $ARCH
EOF

stack install -v
release "pandoc-crossref" "$tag"

exit $?
