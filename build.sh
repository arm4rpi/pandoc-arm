#!/bin/bash
 
set -e

ARCH=`arch`
PKG=`basename $0`
CABALDIR="/home/runner/.cabal"

apt-get update
apt-get install -y cabal-install pkg-config build-essential zlib1g-dev curl aria2 git 1>/dev/null

CODE=`curl -s http://ip-api.com/json |tr ',' '\n' |grep "countryCode" |awk -F'"' '{print $4}'`
cabal user-config init
if [ "$CODE"x == "CN"x ];then
	CABALDIR="/root/.cabal"
	sed -i -r 's/hackage.haskell.org\//mirrors.tuna.tsinghua.edu.cn\/hackage/g' $CABALDIR/config
	sed -i -r 's/hackage.haskell.org/mirrors.tuna.tsinghua.edu.cn/g' $CABALDIR/config
fi
cabal v2-update

function libpandoc() {
	lib=`cabal v2-install --dry-run $PKG |grep "(lib)" |grep -E "pandoc-[1-9]" |awk '{print $2}'`
	curl -s -L "https://github.com/arm4rpi/pandoc-deps/releases/download/v0.1/$ARCH-lib-$lib.tar.gz" -o $ARCH-lib-$lib.tar.gz
	MIME=`file -b --mime-type $ARCH-lib-$lib.tar.gz`
	echo $MIME
	if [ "$MIME"x == "application/x-gzip"x ];then
		echo "lib pandoc found"
		tar zxvf $ARCH-lib-$lib.tar.gz 1>/dev/null
	else
		echo "lib pandoc not exists"
		echo "$PKG" |grep -E "pandoc-[1-9]" && echo "build pandoc lib" || exit 1
	fi
}


libpandoc
# download deps
curl -k "https://raw.githubusercontent.com/arm4rpi/pandoc-deps/master/deps.txt" -o deps.txt
for id in `cat deps.txt |grep -vE "#|^$"`;do
	echo "$ARCH-$id.tar.gz"
	aria2c -x 16 "https://github.com/arm4rpi/pandoc-deps/releases/download/v0.1/$ARCH-$id.tar.gz"
	tar zxvf $ARCH-$id.tar.gz 1>/dev/null
done
ghc-pkg recache -v -f $CABALDIR/store/ghc-8.6.5/package.db/

echo $PKG |grep "citeproc" && cabal v2-install $PKG -v --flags="static embed_data_files bibutils"
echo $PKG |grep "crossref" && cabal v2-install $PKG -v
echo $PKG |grep -E "pandoc-[1-9]" && cabal v2-install $PKG -v --flags="static embed_data_files"

echo "ls $CABALDIR/store/ghc-8.6.5"
ls $CABALDIR/store/ghc-8.6.5

echo "ls $CABALDIR/bin"
ls $CABALDIR/bin

tar zcvf $ARCH-$PKG.tar.gz $CABALDIR/bin
echo $PKG |grep -E "pandoc-[1-9]" && tar zcvf $ARCH-lib-$PKG.tar.gz $CABALDIR/store/ghc-8.6.5/$PKG-*
