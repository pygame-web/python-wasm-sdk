#!/bin/bash


. ${CONFIG:-config}

. scripts/emsdk-fetch.sh


if pushd ${ROOT}/src
then
    if [ -d bullet3 ]
    then
        echo -n
    else
        git clone --recursive --no-tags --depth 1 --single-branch --branch master https://github.com/bulletphysics/bullet3
    fi

    mkdir -p $ROOT/build/bullet3

    pushd $ROOT/build/bullet3
        emcmake cmake ../../src/bullet3 -DCMAKE_INSTALL_PREFIX=$PREFIX \
 -DBUILD_SHARED_LIBS=NO -DUSE_DOUBLE_PRECISION=NO \
     -DBUILD_EXTRAS=NO -DBUILD_CPU_DEMOS=NO -DBUILD_PYBULLET=NO -DBUILD_ENET=NO \
     -DBUILD_CLSOCKET=NO -DUSE_GRAPHICAL_BENCHMARK=NO \
     -DBUILD_OPENGL3_DEMOS=NO -DBUILD_BULLET2_DEMOS=NO -DBUILD_UNIT_TESTS=NO
    emmake make install
    popd

    popd
fi

