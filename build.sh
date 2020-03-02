#!/bin/sh
set -e

ARCH=`arch`

sed -i '/edge/d' /etc/apk/repositories
apk update
apk add xz git aria2

cd /root
/root/stack.sh

RESOLVER="nightly-2018-12-17"
[ "$ARCH"x != "aarch64"x ] && RESOLVER="lts-13.11"

git clone https://github.com/jgm/pandoc
cd pandoc
sed -i "s/^resolver.*/resolver: $RESOLVER/" stack.yaml
cat >> stack.yaml <<EOF
system-ghc: true
arch: $ARCH
EOF

<<COMMENT
Error: While constructing the build plan, the following exceptions were encountered:
In the dependencies for pandoc-2.9.2(+static):
cmark-gfm-0.1.6 from stack configuration does not match >=0.2 && <0.3 (latest matching version
is 0.2.1)
hslua-module-system must match >=0.2 && <0.3, but the stack configuration has no specified
version (latest matching version is 0.2.1)
ipynb must match >=0.1 && <0.2, but the stack configuration has no specified version (latest
matching version is 0.1)
needed since pandoc is a build target.
Some different approaches to resolving this:
* Recommended action: try adding the following to your extra-deps in /root/pandoc/stack.yaml:
- cmark-gfm-0.2.1@sha256:f49c10f6f1f8f41cb5d47e69ad6593dc45d2b28a083bbe22926d9f5bebf479b5,5191
- hslua-module-system-0.2.1@sha256:7c498e51df885be5fd9abe9b762372ff4f125002824d8e11a7d5832154a7a1c3,2216
- ipynb-0.1@sha256:5b5240a9793781da557f82891d49cea63d71c8c5d3500fa3eac9fd702046b520,1926
COMMENT

sed -i 's/extra-deps:/extra-deps:\n- cmark-gfm-0.2.1@sha256:f49c10f6f1f8f41cb5d47e69ad6593dc45d2b28a083bbe22926d9f5bebf479b5,5191\n- hslua-module-system-0.2.1@sha256:7c498e51df885be5fd9abe9b762372ff4f125002824d8e11a7d5832154a7a1c3,2216\n- ipynb-0.1@sha256:5b5240a9793781da557f82891d49cea63d71c8c5d3500fa3eac9fd702046b520,1926/g' stack.yaml

stack install -v --flag 'pandoc:static'

exit $?
