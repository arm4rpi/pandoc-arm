#!/bin/bash
 
set -e

ARCH=`arch`
BINDIR=/root/bin

apt-get update
apt-get install -y cabal-install git curl aria2

[ ! -d $BINDIR ] && mkdir $BINDIR

function getTag() {
	cd $1
	TAG=`git describe --tags`
	cd ../
	echo $TAG
}

function release() {
	mv $BINDIR/$1 $BINDIR/$1-$2-$ARCH
	tar zcvf $BINDIR/$1-$2-$ARCH.tar.gz $BINDIR/$1-$2-$ARCH
}

CODE=`curl -s http://ip-api.com/json |tr ',' '\n' |grep "countryCode" |awk -F'"' '{print $4}'`

cabal user-config init

if [ "$CODE"x == "CN"x ];then
	sed -i -r 's/hackage.haskell.org\//mirrors.tuna.tsinghua.edu.cn\/hackage/g' /root/.cabal/config
	sed -i -r 's/hackage.haskell.org/mirrors.tuna.tsinghua.edu.cn/g' /root/.cabal/config
fi

cabal v2-update

# download deps
curl -k "https://raw.githubusercontent.com/arm4rpi/pandoc-deps/master/deps.txt" -o deps.txt
for id in `cat deps.txt |grep -vE "#|^$"`;do
	echo "$ARCH-$id.tar.gz"
	aria2c -x 16 "https://github.com/arm4rpi/pandoc-deps/releases/download/v0.1/$ARCH-$id.tar.gz"
	tar zxvf $ARCH-$id.tar.gz
done
mv home/runner/.cabal/* /home/runner/.cabal
ghc-pkg recache -v -f /home/runner/.cabal/store/ghc-8.6.5/package.db/

cabal v2-install pandoc-2.9.2 --flags="static embed_data_files" -v

ls /home/runner/.cabal/store
tar zcvf $ARCH-pandoc-2.9.2.tar.gz /home/runner/.cabal/store

<<COMMENT
cd /root
git clone https://github.com/jgm/pandoc
cd pandoc

# cabal v2-build --dependencies-only . pandoc-citeproc
cabal v2-build . pandoc-citeproc --flags="static embed_data_files bibutils -unicode_collation" --bindir=$BINDIR -v
find /root -name "pandoc"
find /root -name "pandoc-citeproc"
cd ../

git clone https://github.com/lierdakil/pandoc-crossref
cd pandoc-crossref
cabal v2-build . pandoc-crossref --flags="static" --bindir=$BINDIR
find /root -name "pandoc-crossref"
cd ../


tag=`getTag "pandoc"`
release "pandoc" "$tag"
release "pandoc-citeproc" "$tag"

tag=`getTag "pandoc-crossref"`
release "pandoc-crossref" "$tag"
COMMENT
