#!/bin/bash

# set -e

ARCH=`arch`
BINDIR=/root/bin

apt-get update
apt-get install -y cabal-install git curl

[ ! -d $BINDIR ] && mkdir $BINDIR

function getTag() {
	cd $1
	TAG=`git describe --tags`
	cd ../
	echo $TAG
}

function release() {
	mv $BINDIR/$1 $BINDIR/$1-$2-$ARCH
	xz $BINDIR/$1-$2-$ARCH
}

cd /root
CODE=`curl -s http://ip-api.com/json |tr ',' '\n' |grep "countryCode" |awk -F'"' '{print $4}'`

cabal user-config init

if [ "$CODE"x == "CN"x ];then
	sed -i -r 's/hackage.haskell.org\//mirrors.tuna.tsinghua.edu.cn\/hackage/g' /root/.cabal/config
	sed -i -r 's/hackage.haskell.org/mirrors.tuna.tsinghua.edu.cn/g' /root/.cabal/config
fi

git clone https://github.com/jgm/pandoc
cabal v2-update
cd pandoc

cabal v2-build --dependencies-only . pandoc-citeproc

for id in `seq 1 1000`;do
cabal v2-install . pandoc-citeproc --flags="static embed_data_files bibutils -unicode_collation -test_citeproc -debug" --bindir=$BINDIR
if [ $? -eq 0 ];then
	break;
fi
done
cd ../

git clone https://github.com/lierdakil/pandoc-crossref
cd pandoc-crossref
#cabal v2-build --dependencies-only . pandoc-crossref

for id in `seq 1 1000`;do
cabal v2-install . pandoc-crossref --verbose=3 --flags="static" --bindir=$BINDIR
if [ $? -eq 0 ];then
	break;
fi
done
cd ../


tag=`getTag "pandoc"`
release "pandoc" "$tag"
release "pandoc-citeproc" "$tag"

tag=`getTag "pandoc-crossref"`
release "pandoc-crossref" "$tag"
