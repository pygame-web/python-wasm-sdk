#!/bin/bash

. ${CONFIG:-config}

PKG=libxslt

if [ -d src/${PKG} ]
then
    echo ok
else
    pushd src
        wget -c https://github.com/sailfishos-mirror/${PKG}/archive/refs/tags/v1.1.42.tar.gz -O${PKG}-v1.1.42.tar.gz
        tar xfz ${PKG}-v1.1.42.tar.gz
        mv ${PKG}-1.1.42 ${PKG}
        pushd ${PKG}
            autoreconf -ivf
        popd
    popd
fi



if [ -f $PREFIX/lib/${PKG}.a ]
then
    echo "
        ${PKG} already built at $PREFIX/lib/${PKG}.a + sysroot
    "
else
    . scripts/emsdk-fetch.sh

    mkdir -p $ROOT/build/${PKG}
    pushd $ROOT/build/${PKG}

    emconfigure ${ROOT}/src/${PKG}/configure --prefix=$PREFIX  --with-libxml-prefix=$PREFIX \
     --without-python --without-crypto --without-debug --without-debugger --without-profiler \
     --without-plugins --with-pic --enable-static --disable-shared --program-suffix=.cjs
    emmake make install
    cp -r $PREFIX/include/${PKG}* $SYSROOT/include/
    cp -r $PREFIX/lib/${PKG}* $SYSROOT/lib/
    popd
fi



