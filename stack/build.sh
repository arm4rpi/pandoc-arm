#!/bin/bash

set -e

ARCH=`arch`
RESOLVER="nightly-2018-12-17"
COMPILER="ghc-8.6.2"

# stack did not no armhf or armv7l
[ "$ARCH"x != "aarch64"x ] && ARCH="arm" && RESOLVER="lts-13.11" && COMPILER="ghc-8.6.3"

function getTag() {
	git describe --tags |awk -F'-' '{print $1}'
}

function release() {
	DIR=/root/.local/bin
	mv $DIR/$1 $DIR/$1-$2-$ARCH
	xz $DIR/$1-$2-$ARCH
}

cd /root
CODE=`curl -s http://ip-api.com/json |tr ',' '\n' |grep "countryCode" |awk -F'"' '{print $4}'`

if [ "$CODE"x == "CN"x ];then
	[ ! -d /root/.stack ] && mkdir /root/.stack
	cat >> /root/.stack/config.yaml <<EOF
package-indices:
  - download-prefix: http://mirrors.tuna.tsinghua.edu.cn/hackage/
    hackage-security:
        keyids:
        - 0a5c7ea47cd1b15f01f5f51a33adda7e655bc0f0b0615baa8e271f4c3351e21d
        - 1ea9ba32c526d1cc91ab5e5bd364ec5e9e8cb67179a471872f6e26f0ae773d42
        - 280b10153a522681163658cb49f632cde3f38d768b736ddbc901d99a1a772833
        - 2a96b1889dc221c17296fcc2bb34b908ca9734376f0f361660200935916ef201
        - 2c6c3627bd6c982990239487f1abd02e08a02e6cf16edb105a8012d444d870c3
        - 51f0161b906011b52c6613376b1ae937670da69322113a246a09f807c62f6921
        - 772e9f4c7db33d251d5c6e357199c819e569d130857dc225549b40845ff0890d
        - aa315286e6ad281ad61182235533c41e806e5a787e0b6d1e7eef3f09d137d2e9
        - fe331502606802feac15e514d9b9ea83fee8b6ffef71335479a2e68d84adc6b0
        key-threshold: 3 # number of keys required

        # ignore expiration date, see https://github.com/commercialhaskell/stack/pull/4614
        ignore-expiry: no
EOF
fi

<<COMMENT
Error: While constructing the build plan, the following exceptions were encountered:
In the dependencies for pandoc-2.9.2(+static):
cmark-gfm-0.1.6 from stack configuration does not match >=0.2 && <0.3 (latest matching version
is 0.2.1)
hslua-module-system must match >=0.2 && <0.3, but the stack configuration has no specified
version (latest matching version is 0.2.1)
ipynb must match >=0.1 && <0.2, but the stack configuration has no specified version (latest
matching version is 0.1)
hslua-1.0.1 from stack configuration does not match >=1.0.3 && <1.2 (latest matching version
is 1.0.3.2)
needed due to pandoc-2.9.2 -> hslua-module-system-0.2.1
needed since pandoc is a build target.
Some different approaches to resolving this:
* Recommended action: try adding the following to your extra-deps in /root/pandoc/stack.yaml:
- cmark-gfm-0.2.1@sha256:f49c10f6f1f8f41cb5d47e69ad6593dc45d2b28a083bbe22926d9f5bebf479b5,5191
- hslua-module-system-0.2.1@sha256:7c498e51df885be5fd9abe9b762372ff4f125002824d8e11a7d5832154a7a1c3,2216
- ipynb-0.1@sha256:5b5240a9793781da557f82891d49cea63d71c8c5d3500fa3eac9fd702046b520,1926
COMMENT

# pandoc
git clone https://github.com/jgm/pandoc
cd pandoc

sed -i 's/extra-deps:/extra-deps:\n- cmark-gfm-0.2.1@sha256:f49c10f6f1f8f41cb5d47e69ad6593dc45d2b28a083bbe22926d9f5bebf479b5,5191\n- hslua-module-system-0.2.1@sha256:7c498e51df885be5fd9abe9b762372ff4f125002824d8e11a7d5832154a7a1c3,2216\n- ipynb-0.1@sha256:5b5240a9793781da557f82891d49cea63d71c8c5d3500fa3eac9fd702046b520,1926\n- hslua-1.0.3.2@sha256:8db3f80f52e8382c3ec6801742a13649cc2bf82cf55b6ac288a47512a6cc3b33,9685/g' stack.yaml

tag=`getTag`
sed -i "s/^resolver.*/resolver: $RESOLVER/" stack.yaml
cat >> stack.yaml <<EOF
arch: $ARCH
EOF

stack install -v --cabal-verbose --flag 'pandoc:static' -j1
release pandoc "$tag"

# pandoc-citeproc
cd ../
git clone https://github.com/jgm/pandoc-citeproc
cd pandoc-citeproc
tag=`getTag`
sed -i "s/^resolver.*/resolver: $RESOLVER/" stack.yaml
cat >> stack.yaml <<EOF
arch: $ARCH
EOF

stack install -v --cabal-verbose --flag 'pandoc-citeproc:static' -j1
release "pandoc-citeproc" "$tag"

# pandoc-crossref
cd ../
git clone https://github.com/lierdakil/pandoc-crossref
cd pandoc-crossref
tag=`getTag`
sed -i "s/^resolver.*/resolver: $RESOLVER/" stack.yaml
cat >> stack.yaml <<EOF
arch: $ARCH
EOF

stack install -v --cabal-verbose -j1
release "pandoc-crossref" "$tag"

