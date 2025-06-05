#!/bin/bash

. scripts/emsdk-fetch.sh

cd ${ROOT}/src

if [ -d liblz4 ]
then
    echo ok
else
    wget -c https://github.com/lz4/lz4/releases/download/v1.9.4/lz4-1.9.4.tar.gz
    tar xfz lz4-1.9.4.tar.gz
    mv lz4-1.9.4 liblz4
fi

if [ -f $PREFIX/lib/liblz4.a ]
then
    echo "
        already built in $PREFIX/lib/liblz4.a
    "
else
    mkdir -p $ROOT/build/liblz4
    pushd $ROOT/build/liblz4
    emcmake cmake ../../src/liblz4/build/cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_INSTALL_PREFIX=$PREFIX \
     && emmake make install
    popd
fi



