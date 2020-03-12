#!/bin/bash
 
set -e

ARCH=`arch`
PKG=`basename $0`
CABALDIR="/home/runner/.cabal"
BIN="pandoc"
PANDOCLIB="no"
RTS="+RTS -M7G -A64m -RTS"

apt-get update
apt-get install -y cabal-install pkg-config build-essential zlib1g-dev curl aria2 git file binutils

CODE=`curl -s http://ip-api.com/json |tr ',' '\n' |grep "countryCode" |awk -F'"' '{print $4}'`
cabal user-config init
if [ "$CODE"x == "CN"x ];then
	CABALDIR="/root/.cabal"
	sed -i -r 's/hackage.haskell.org\//mirrors.tuna.tsinghua.edu.cn\/hackage/g' $CABALDIR/config
	sed -i -r 's/hackage.haskell.org/mirrors.tuna.tsinghua.edu.cn/g' $CABALDIR/config
fi
echo "# Run cabal v2-update"
cabal v2-update

echo "# Run mkdir package.db"
mkdir -p /home/runner/.cabal/store/ghc-8.6.5/package.db

function libpandoc() {
	echo "# Run cabal v2-install dry run $PKG"
	lib=`cabal v2-install --dry-run $PKG |grep "(lib)" |grep -E "pandoc-[1-9]" |awk '{print $2}'`
	echo "# Run download pandoc lib"
	# ubuntu 19.10 armv7l will exit code 60 with SSL certificate problem: unable to get local issuer certificate
	curl -k -s -L "https://github.com/arm4rpi/pandoc-arm/releases/download/v0.1/$ARCH-lib-$lib.tar.gz" -o $ARCH-lib-$lib.tar.gz
	echo "# Run check mime"
	MIME=`file -b --mime-type $ARCH-lib-$lib.tar.gz`
	echo $MIME
	if [ "$MIME"x == "application/gzip"x ];then
		echo "lib pandoc found"
		tar zxf $ARCH-lib-$lib.tar.gz
		PANDOCLIB="yes"
	else
		echo "lib pandoc not exists"
		echo "$PKG" |grep -E "pandoc-[1-9]" && echo "build pandoc lib" || exit 1
	fi
}

echo "# Run libpandoc"
libpandoc
# download deps
curl -k "https://raw.githubusercontent.com/arm4rpi/pandoc-deps/master/deps.txt" -o deps.txt
for id in `cat deps.txt |grep -vE "#|^$"`;do
	echo "# Run Download dep $ARCH-$id.tar.gz"
	aria2c -x 16 "https://github.com/arm4rpi/pandoc-deps/releases/download/v0.1/$ARCH-$id.tar.gz"
	tar zxf $ARCH-$id.tar.gz
done
ghc-pkg recache -v -f $CABALDIR/store/ghc-8.6.5/package.db/

echo "# Run cabal v2-install $PKG"
echo $PKG |grep "citeproc" && BIN="pandoc-citeproc" && cabal v2-install $PKG --flags="static embed_data_files bibutils" -v -j1
echo $PKG |grep "crossref" && BIN="pandoc-crossref" && cabal v2-install $PKG -v -j1
echo $PKG |grep -E "pandoc-[1-9]" && cabal v2-install $PKG --flags="static embed_data_files" -v -j1

echo "# Run ls $CABALDIR/store/ghc-8.6.5 |grep $PKG"
ls $CABALDIR/store/ghc-8.6.5 |grep "$PKG"

echo "# Run ls $CABALDIR/bin"
ls -l $CABALDIR/bin

echo "# Copy binary"
find $CABALDIR/store/ghc-8.6.5/$PKG-* -type f -name "$BIN" -exec cp {} $PKG-$ARCH \;
echo "# Run strip $PKG-$ARCH"
strip $PKG-$ARCH

echo "# Run tar $PKG $ARCH"
tar zcvf $ARCH-$PKG.tar.gz $PKG-$ARCH

if [ "$BIN"x == "pandoc"x ] && [ "$PANDOCLIB"x == "no"x ];then
	tar cvf $ARCH-lib-$PKG.tar $CABALDIR/store/ghc-8.6.5/$PKG-*
	tar rvf $ARCH-lib-$PKG.tar $CABALDIR/store/ghc-8.6.5/package.db/$PKG-*
	gzip $ARCH-lib-$PKG.tar
fi
