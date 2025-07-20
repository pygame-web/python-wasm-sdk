#!/bin/bash

. scripts/emsdk-fetch.sh

PKG=libxml2

if [ -f $PREFIX/lib/${PKG}.a ]
then
    echo "
        already built in $PREFIX/lib/${PKG}.a
    "
else
    pushd ${SDKROOT}/src

    if [ -d ${PKG} ]
    then
        echo using local ${PKG}
    else
        wget -c https://download.gnome.org/sources/libxml2/2.14/libxml2-2.14.5.tar.xz
        tar xf libxml2-2.14.5.tar.xz
        mv libxml2-2.14.5 ${PKG}
    fi

    mkdir -p $SDKROOT/build/${PKG}
    pushd $SDKROOT/build/${PKG}
        PYTHON=python3 emconfigure ${ROOT}/src/${PKG}/configure --prefix=$PREFIX \
         --with-http=no --with-python=no --with-threads=no \
         --enable-shared=no --enable-static=yes \
         --without-icu $@
        emmake make install
    popd
    popd
fi
