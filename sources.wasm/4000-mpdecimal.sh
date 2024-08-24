#!/bin/bash

. ${CONFIG:-config}

PKG=mpdecimal


if [ -d src/${PKG} ]
then
    echo ok
else
    pushd src
        wget -c https://www.bytereef.org/software/${PKG}/releases/${PKG}-4.0.0.tar.gz
        tar xfz ${PKG}-4.0.0.tar.gz

        mv ${PKG}-4.0.0 ${PKG}

        pushd ${PKG}
            # patch
        popd

    popd
fi



if [ -f $PREFIX/lib/lib${PKG}.a ]
then
    echo "
        ${PKG} already built at $PREFIX/lib/lib${PKG}.a
    "
else
    . scripts/emsdk-fetch.sh

    mkdir -p $ROOT/build/${PKG}
    pushd $ROOT/build/${PKG}
# --with-pic
    emconfigure ${ROOT}/src/${PKG}/configure --prefix=$PREFIX --enable-static --disable-shared --program-suffix=.cjs
    emmake make install
    #cp -r $PREFIX/include/libmpdec $SYSROOT/include/
    #cp -r $PREFIX/lib/libmpdec* $SYSROOT/lib/
    popd
fi



