#!/bin/bash

# name: Clone Pandoc
git clone https://github.com/jgm/pandoc
cd pandoc
TAG=`git describe --tags`
ARCH=`uname -m`

# name: Install recent cabal/ghc
sudo add-apt-repository ppa:hvr/ghc
sudo apt-get update
sudo apt-get install ghc-8.6.5 cabal-install-2.4 xz-utils

# name: Install dependencies
export PATH=/opt/cabal/bin:/opt/ghc/bin:$PATH
cabal v2-update
cabal v2-build --dependencies-only . pandoc-citeproc

# name: Build
cabal v2-install -v . pandoc-citeproc
strip $HOME/.cabal/bin/pandoc
strip $HOME/.cabal/bin/pandoc-citeproc

# name: Install artifact
mv $HOME/.cabal/bin/pandoc $HOME/.cabal/bin/pandoc-${TAG}-${ARCH}
mv $HOME/.cabal/bin/pandoc-citeproc $HOME/.cabal/bin/pandoc-citeproc-${TAG}-${ARCH}
xz $HOME/.cabal/bin/*
