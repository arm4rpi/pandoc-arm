#!/bin/bash

set -e

ARCH=`arch`
BINDIR=/root/bin

[ ! -d $BINDIR ] && mkdir $BINDIR

function getTag() {
	cabal info "$1" |grep "Versions available" -A1 |tail -n1 |awk -F',' '{print $NF}' |cut -f1 -d'(' |tr -d ' '
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

cabal update

cabal install pandoc --verbose=3 --flags="static embed_data_files -trypandoc" --bindir=$BINDIR -j1
cabal install pandoc-citeproc --verbose=3 --flags="static embed_data_files bibutils -unicode_collation -test_citeproc -debug" --bindir=$BINDIR -j1
cabal install pandoc-crossref --verbose=3 --flags="static" --bindir=$BINDIR -j1

tag=`getTag "pandoc"`
release "pandoc" "$tag"

tag=`getTag "pandoc-citeproc"`
release "pandoc-citeproc" "$tag"

tag=`getTag "pandoc-crossref"`
release "pandoc-crossref" "$tag"
