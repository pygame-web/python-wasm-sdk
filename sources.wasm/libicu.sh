#!/bin/bash

. scripts/emsdk-fetch.sh


cd ${ROOT}/src

if [ -d icu ]
then
    echo ok
else
    wget -c https://github.com/unicode-org/icu/releases/download/release-75-1/icu4c-75_1-src.tgz
    tar xf icu4c-75_1-src.tgz
fi

if [ -f $PREFIX/lib/libicu.a ]
then
    echo "
        already built in $PREFIX/lib/libicu.a
    "
else

    mkdir -p $ROOT/build/libicu

    pushd $ROOT/build/libicu
        emconfigure ../../src/icu/source/configure --prefix=$PREFIX \
         --disable-shared --enable-static \
         --disable-samples --disable-tests --disable-tools \
         --disable-extras --disable-draft
    emmake make install
    popd
fi



