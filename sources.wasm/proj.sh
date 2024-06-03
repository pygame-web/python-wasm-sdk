#!/bin/bash

. ${CONFIG:-config}


cd ${ROOT}/src

if [ -d libproj ]
then
    echo ok
else
    wget -c https://download.osgeo.org/proj/proj-9.4.0.tar.gz
    tar xvfz proj-9.4.0.tar.gz
    mv proj-9.4.0 libproj

    pushd libgeos
    # patch
    popd
fi


if [ -f $PREFIX/lib/libproj.a ]
then
    echo "
        already built in $PREFIX/lib/libproj.a
    "
else
    . ${SDKROOT}/scripts/emsdk-fetch.sh

    mkdir -p $ROOT/build/libproj
    pushd $ROOT/build/libproj
    emcmake cmake ../../src/libproj \
     -DCMAKE_INSTALL_PREFIX=$PREFIX -DENABLE_TIFF=NO -DENABLE_CURL=NO -DUSE_EXTERNAL_GTEST=NO -DBUILD_PROJSYNC=no
    emmake make -j $(nproc) install
    popd
fi




