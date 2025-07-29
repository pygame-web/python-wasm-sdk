#!/bin/bash

. scripts/emsdk-fetch.sh

VERSION=1.5.7
PKG=zstd

cd ${ROOT}/src

if [ -d $PKG ]
then
    echo "using $PKG local copy"
else
    wget -c https://github.com/facebook/zstd/releases/download/v${VERSION}/${PKG}-${VERSION}.tar.gz
    tar xfz ${PKG}-${VERSION}.tar.gz
fi

if [ -f $PREFIX/lib/lib${PKG}.a ]
then
    echo "
        already built in $PREFIX/lib/lib${PKG}.a
    "
else
    mkdir -p $ROOT/build/${PKG}
    pushd $ROOT/build/${PKG}
    emcmake cmake ../../src/${PKG}-${VERSION}/build/cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX=$PREFIX \
     && emmake make install
    popd
fi



