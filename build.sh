#!/bin/bash
 
set -e

ARCH=`arch`
PKG=`basename $0`
CABALDIR="/home/runner/.cabal"
BIN="pandoc"
RELEASE="https://github.com/arm4rpi/pandoc-arm/releases/download/v0.1"
LIB="no"
VERSION="2.9.2"
GHC="$CABALDIR/store/ghc-8.6.5"

echo "$PKG" |grep "citeproc" && BIN="pandoc-citeproc"
echo "$PKG" |grep "crossref" && BIN="pandoc-crossref"

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

function _binary() {
	echo "# Copy binary"
	find $GHC/$PKG-* -type f -name "$BIN" -exec cp {} $PKG-$ARCH \;
	echo "# Run strip $PKG-$ARCH"
	strip $PKG-$ARCH

	echo "# Run tar $PKG $ARCH"
	tar zcvf $ARCH-$PKG.tar.gz $PKG-$ARCH
}

function _lib() {
	echo "# Run download $1"
	# ubuntu 19.10 armv7l will exit code 60 with SSL certificate problem: unable to get local issuer certificate
	libfile=$ARCH-$1.tar.gz
	curl -k -s -L "$RELEASE/$libfile" -o $libfile
	echo "# Run check mime"
	MIME=`file -b --mime-type $libfile`
	echo $MIME
	if [ "$MIME"x == "application/gzip"x ];then
		echo "$libfile found"
		tar zxf $libfile
		LIB="yes"
		ghc-pkg recache -v -f $GHC/package.db/
	else
		rm -f $libfile
		echo "$libfile not exists"
	fi
}


function pandoc() {
	# pandoc deps
	_lib pandoc-deps-$VERSION
	DEP=""
	if [ "$LIB"x == "no"x ];then
		DEP="--dependencies-only"
	fi
	
	sed "s/^constraints: /cabal v2-install -v $DEP $PKG --constraint '/;s/^ \+/--constraint '/;s/,\$/' \\\\/;\$s/\$/'/" cabal.project.freeze > dep.sh
	source ./dep.sh

	if [ "$DEP"x != ""x ];then
		tar zcvf $ARCH-pandoc-deps-$VERSION.tar.gz $GHC
	else
		tar zcvf $ARCH-libpandoc-$VERSION.tar.gz $GHC
		_binary
	fi
}

function citeproc() {
	# libpandoc
	_lib libpandoc-$VERSION
	if [ "$LIB"x == "no"x ];then
		echo "libpandoc not ready"
		exit 1
	fi
	source ./install.sh
	_binary
}

cabal unpack pandoc pandoc-citeproc pandoc-crossref
sed "s/^constraints: /cabal v2-install -v $PKG --constraint '/;s/^ \+/--constraint '/;s/,\$/' \\\\/;\$s/\$/'/" cabal.project.freeze > install.sh
echo "# Run cabal v2-install $PKG"
[ "$BIN"x == "pandoc"x ] && pandoc || citeproc
