#!/bin/bash

. ${CONFIG:-config}



if [ -d src/libproj ]
then
    echo ok
else
    pushd ${ROOT}/src
        wget -c https://download.osgeo.org/proj/proj-9.4.0.tar.gz
        tar xvfz proj-9.4.0.tar.gz
        mv proj-9.4.0 libproj
        pushd libproj
            # patch
        popd
    popd
fi


if [ -f $PREFIX/lib/libproj.a ]
then
    echo "
        $PREFIX/lib/libproj.a already built
    "
else
    . scripts/emsdk-fetch.sh

    mkdir -p $ROOT/build/libproj

    pushd $ROOT/build/libproj
        EMCC_CFLAGS="-sDISABLE_EXCEPTION_CATCHING=1" emcmake cmake  -DCMAKE_POSITION_INDEPENDENT_CODE=True \
         -DCMAKE_INSTALL_PREFIX=$PREFIX -DENABLE_TIFF=NO -DENABLE_CURL=NO -DUSE_EXTERNAL_GTEST=NO -DBUILD_PROJSYNC=no \
         ../../src/libproj
        EMCC_CFLAGS="-sDISABLE_EXCEPTION_CATCHING=1" emmake make -j $(nproc) install
    popd

    if [ -f $PREFIX/lib/libproj.a ]
    then
        echo -n
    else
        echo "

    failed to build PROJ

"
        exit 47
    fi
fi




